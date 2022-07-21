public class frSyncRequestHandler implements Database.Batchable<SObject> {
    public static final Integer MAX_ATTEMPTS = 3;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id jobId = bc.getJobId();
		Id classId = [SELECT ApexClassId FROM AsyncApexJob WHERE id = :jobId][0].ApexClassId;
        Integer otherRunningJobs = [SELECT count() FROM AsyncApexJob WHERE 
                                      JobType = 'BatchApex'
                                      AND Id != :jobId 
                                      AND Status = 'Processing' 
                                      AND ApexClassId = :classId 
                                      ];
        if (otherRunningJobs > 0) {
            //return an empty query locator (with limit 0) to basically no-op
            return Database.getQueryLocator([SELECT Id FROM Sync_Attempt__c LIMIT 0]);
        } else {
            return Database.getQueryLocator([SELECT Id, Request_Body__c, Attempts__c, Type__c FROM Sync_Attempt__c ORDER BY CreatedDate]);
        }
    }
    
    public void execute (Database.BatchableContext bc, List<Sync_Attempt__c> syncs) {
        List<Sync_Attempt__c> toDelete = new List<Sync_Attempt__c>();
        List<Sync_Attempt__c> toUpdate = new List<Sync_Attempt__c>();
        try {
            for (Sync_Attempt__c attempt : syncs) {
                attempt.Attempts__c += 1;
                Boolean success = false;
                try {
                    success = sync(attempt);
                } finally {
                    if (success || attempt.Attempts__c > MAX_ATTEMPTS) {
                        toDelete.add(attempt);
                    } else {
                        toUpdate.add(attempt);
                    }
                }
            }  
        } finally {
            delete toDelete;
            update toUpdate; 
        }
    }
    
    public static Boolean sync(Sync_Attempt__c attempt) {
        Boolean result = false;
        frSyncable syncInstance = getSyncInstance(attempt);
        result = syncInstance.sync();
        return result;
    }
    
    private static frSyncable getSyncInstance(Sync_Attempt__c attempt) {
        frSyncable result = null;
        if(attempt.Type__c == frUtil.Entity.DONATION.name()) {
            result = new frDonation(attempt);
        } else if (attempt.Type__c == frUtil.Entity.SUPPORTER.name()) {
            result = new frDonor(attempt);
        } else if (attempt.Type__c == frUtil.Entity.EVENT.name()) {
            result = new frFundraisingEvent(attempt);
        } else if (attempt.Type__c == frUtil.Entity.REGISTRATION.name()) {
            result = new frFundraisingEventRegistration(attempt);
        } else if (attempt.Type__c == frUtil.Entity.SUBSCRIPTION.name()) {
            result = new frSubscription(attempt);
        } else if (attempt.Type__c == frUtil.Entity.CAMPAIGN.name()) {
            result = new frCampaign(attempt);
        } else if (attempt.Type__c == frUtil.Entity.EMAIL.name()) {
            result = new frDonorEmails(attempt);
        } else if (attempt.Type__c == frUtil.Entity.TASK.name()) {
            result = new frTask(attempt);
        } else if (attempt.Type__c == frUtil.Entity.QUESTION.name()) {
            result = new frQuestion(attempt);
        } else if (attempt.Type__c == frUtil.Entity.ANSWER.name()) {
            result = new frAnswer(attempt);
        } else {
            System.debug('Funraise was not able to find the correct object to attempt to resync, type:' + attempt.Type__c);
        }
        return result;
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
}