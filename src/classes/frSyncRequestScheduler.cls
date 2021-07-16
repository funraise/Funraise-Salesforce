global class frSyncRequestScheduler implements Schedulable {
    public static final String SCHEDULED_JOB_NAME_1 = 'Funraise Sync 1';
    public static final String SCHEDULED_JOB_NAME_2 = 'Funraise Sync 2';
    public static final String SCHEDULED_JOB_NAME_3 = 'Funraise Sync 3';
    public static final String SCHEDULED_JOB_NAME_4 = 'Funraise Sync 4';
    public static final Set<String> ALL_JOBS = new Set<String>{SCHEDULED_JOB_NAME_1, SCHEDULED_JOB_NAME_2, SCHEDULED_JOB_NAME_3, SCHEDULED_JOB_NAME_4};
    global void execute(SchedulableContext sc){
        Database.executeBatch(new frSyncRequestHandler(), 50);
    }
}