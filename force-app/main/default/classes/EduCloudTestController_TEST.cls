/**
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 10/30/26.
 *
 * Tests for EduCloudTestController. The running user needs Education Cloud access, which the
 * CumulusCI config_dev flow gives the admin through the assign_admin_permission_sets task.
 */
@IsTest
private class EduCloudTestController_TEST {

    @TestSetup
    private static void createTerms() {
        insert new List<AcademicTerm>{
            new AcademicTerm(Name = 'Test active term', IsActive = true, Season = 'Fall'),
            new AcademicTerm(Name = 'Test inactive term', IsActive = false, Season = 'Spring')
        };
    }

    /**
     * Builds a user whose profile has no Education Cloud access.
     *
     * @return Inserted user without access to AcademicTerm
     */
    private static User createUserWithoutAccess() {
        Profile minimumAccessProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User userWithoutAccess = new User(
            Alias = 'noedu',
            Email = 'noedu@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'No Education Access',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = minimumAccessProfile.Id,
            TimeZoneSidKey = 'America/Chicago',
            Username = 'noedu' + DateTime.now().getTime() + '@example.com'
        );
        insert userWithoutAccess;
        return userWithoutAccess;
    }

    @IsTest
    private static void listsAcademicTermsForUserWithAccess() {
        Test.startTest();
        EduCloudTestController controller = new EduCloudTestController();
        Test.stopTest();

        System.assertEquals(true, controller.objectAccessible, 'The running user should be able to read AcademicTerm');
        System.assertEquals(null, controller.errorMessage, 'The query should not fail');
        System.assertEquals(2, controller.academicTerms.size(), 'Both terms are readable by a user who owns them');
        System.assertEquals(2, controller.totalTermCount, 'The system mode count should match');
        System.assertEquals(UserInfo.getUserType(), controller.runningUserType, 'The user type should be reported');
    }

    @IsTest
    private static void reportsDeniedAccessInsteadOfThrowing() {
        User userWithoutAccess;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            userWithoutAccess = createUserWithoutAccess();
        }

        EduCloudTestController controller;
        Test.startTest();
        System.runAs(userWithoutAccess) {
            controller = new EduCloudTestController();
        }
        Test.stopTest();

        System.assertEquals(false, controller.objectAccessible, 'The user has no AcademicTerm access');
        System.assertNotEquals(null, controller.errorMessage, 'The denied query should be reported');
        System.assertEquals(0, controller.academicTerms.size(), 'No terms should be listed');
        System.assertEquals(2, controller.totalTermCount, 'The system mode count still sees the data, which separates permissions from missing data');
    }
}
