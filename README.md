# Education Cloud Guest Permission Test

Tests whether the `EducationCloudGuestAccess` permission set lets a Visualforce site guest user read `AcademicTerm`.

## Result (scratch org, API 68.0, checked on two separate builds)

**The Education Cloud guest permission set does not grant a guest user read access to `AcademicTerm`. Visualforce is not the cause.**

| Check | Result |
|---|---|
| Guest with only page and class access | `AcademicTerm` not accessible (baseline) |
| Add `EducationCloudGuestAccess` | No change |
| Add the active-terms guest sharing rule | No change |
| `System.runAs(guest)` in Apex, no Visualforce | Same result. The guest reaches 0 of the 37 objects the guest license lists |
| Control: plain permission set granting `Account` read, queried from a Visualforce guest page | Works, so Visualforce does honor guest permission set grants |
| Internal user with `EducationCloudAccess` | `AcademicTerm` accessible, so the test method is valid |

What the data shows:

- `EducationCloudGuestAccess` stores **no** object, field, or user permissions. Its license (`EducationCloudGuestAccessPsl`) lists read on `AcademicTerm` and 36 other objects, but the guest does not get it.
- A guest cannot be given the grant another way. The Guest User License rejects the `AccessEducationCloud` and `UseEducationCloudComp` user permissions that `EducationCloudAccess` carries (`FIELD_INTEGRITY_EXCEPTION`).
- `AcademicTerm` is Private for external users, so a guest also needs the sharing rule. It is deployed and verified, but it cannot be exercised until the object itself is readable.

Not tested: an Aura or LWR site page. The `System.runAs` result is independent of the site type, which suggests the same outcome.

## What is in the project

| Piece | Where |
|---|---|
| Scratch org definition. `enableAcademicOperations` is what creates `AcademicTerm` | `orgs/dev.json` |
| Visualforce page that lists academic terms as the running user | `force-app/main/default/pages/EduCloudTest.page` |
| Controller. Queries with `WITH USER_MODE` so permissions are enforced, and also counts terms in system mode so "no access" can be told apart from "no data" | `EduCloudTestController.cls` |
| Controller tests | `EduCloudTestController_TEST.cls` |
| Permission set granting the page and controller only, no object access | `EduCloudTest_Page_Access` |
| Guest sharing rule for active terms | `unpackaged/config/academic_term_sharing` |
| Sample data: 3 active and 2 inactive terms in 2 academic years | `datasets/dev/dev.recipe.yml` |

## Build it

You need CumulusCI, the Salesforce CLI, and a Dev Hub that can create Education Cloud scratch orgs.

```bash
cci flow run dev_org --org dev
```

This creates the scratch org and runs `config_dev`, which:

1. Gives the admin `EducationCloudAccess`, so `AcademicTerm` is visible and the sample data can load.
2. Creates the `Visualforce Test` site.
3. Deploys the active-terms guest sharing rule. This must run after the site exists because it names the site's guest user.
4. Assigns `EduCloudTest_Page_Access` and `EducationCloudGuestAccess` to the site guest user.
5. Creates the network member groups and publishes the site.
6. Loads the sample academic terms.

## Run the test

Open the page as a guest, with no login:

```
https://<site domain>/EduCloudTest
```

Find the domain with `sf data query -o Visualforce-EDU-Cloud-obj-permission-test__dev -q "SELECT Domain.Domain FROM DomainSite"`.

The page prints the running user, whether `AcademicTerm` is readable, how many terms that user can see, and how many exist in the org. In a working setup a guest sees the 3 active terms and none of the 2 inactive ones. Today the page reports the object as not readable.

To run the Apex tests:

```bash
cci task run run_tests --org dev
```
