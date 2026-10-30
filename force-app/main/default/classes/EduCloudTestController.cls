/**
 * Created by Thaddaeus Dahlberg, Software Engineer, University of St. Thomas on 10/30/26.
 *
 * Controller for the EduCloudTest Visualforce page. The page proves (or disproves) that the
 * Education Cloud guest permission set grants a site guest user read access to AcademicTerm.
 *
 * The AcademicTerm query runs in USER_MODE so object permissions, field permissions, and sharing
 * are all enforced for the running user. Apex normally runs in system mode and would ignore the
 * permission set, which would make the test meaningless.
 */
public with sharing class EduCloudTestController {

    /** Academic terms the running user is allowed to read. */
    public List<AcademicTerm> academicTerms { get; private set; }

    /** Message from the failed query, or null when the query succeeded. */
    public String errorMessage { get; private set; }

    /** True when the running user has read access to the AcademicTerm object. */
    public Boolean objectAccessible { get; private set; }

    /** Number of AcademicTerm records that exist, counted in system mode for comparison. */
    public Integer totalTermCount { get; private set; }

    /** Type of the running user, for example Guest or Standard. */
    public String runningUserType { get; private set; }

    /** Name of the running user. */
    public String runningUserName { get; private set; }

    /**
     * Loads the academic terms visible to the running user.
     */
    public EduCloudTestController() {
        academicTerms = new List<AcademicTerm>();
        runningUserType = UserInfo.getUserType();
        runningUserName = UserInfo.getName();
        objectAccessible = Schema.sObjectType.AcademicTerm.isAccessible();
        totalTermCount = new SystemModeCounter().countAllTerms();
        loadAcademicTerms();
    }

    /**
     * Queries AcademicTerm as the running user and records any failure instead of throwing it.
     */
    private void loadAcademicTerms() {
        try {
            academicTerms = [
                SELECT Id, Name, Season, IsActive, StartDate, EndDate
                FROM AcademicTerm
                WITH USER_MODE
                ORDER BY StartDate
            ];
        } catch (QueryException queryException) {
            errorMessage = queryException.getMessage();
        }
    }

    /**
     * Counts every AcademicTerm in the org regardless of the running user's access. The count is
     * only a diagnostic, so an empty result with a non-zero count points at permissions or sharing
     * rather than missing data.
     */
    private without sharing class SystemModeCounter {

        /**
         * Counts all AcademicTerm records.
         *
         * @return Total number of AcademicTerm records in the org
         */
        public Integer countAllTerms() {
            return [SELECT COUNT() FROM AcademicTerm WITH SYSTEM_MODE];
        }
    }
}
