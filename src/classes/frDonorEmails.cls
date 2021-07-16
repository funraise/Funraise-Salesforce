public class frDonorEmails extends frModel implements frSyncable {
    public frDonorEmails(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = 
            (Map<String, Object>)JSON.deserializeUntyped(syncRecord.Request_Body__c);
        
        String funraiseId = String.valueOf(request.get('id'));
        String supporterFunraiseId = String.valueOf(request.get('donorId'));        
        if (String.isNotBlank(supporterFunraiseId)) {
            List<Contact> contacts = [SELECT Id FROM Contact WHERE fr_ID__c = :supporterFunraiseId];
            if (contacts.size() > 0) {
                try {
                    EmailMessage email = new EmailMessage();
                    email.Status = '3';
                    email.FromAddress = String.valueOf(request.get('fromAddress'));
                    email.FromName = String.valueOf(request.get('fromName'));
                    email.toIds = new String[]{contacts.get(0).Id};
                    email.subject = 'Funraise Email - ' + String.valueOf(request.get('subject'));
                    email.MessageDate = DateTime.newInstance((Long)request.get('sentDate')).dateGMT();
                    email.fr_Email_ID__c = funraiseId;
                    Database.upsert(email, EmailMessage.Fields.fr_Email_ID__c, true);
                    
                    EmailMessageRelation emr = new EmailMessageRelation();
                    emr.EmailMessageId = email.Id;
                    emr.RelationId = contacts.get(0).Id;
                    emr.RelationType = 'ToAddress';
                    insert emr;
					result = true;
                } catch (DMLException ex) {
                    if(createLogRecord) frUtil.logException(frUtil.Entity.EMAIL, funraiseId, ex);
                }
            } else {
                if(createLogRecord) frUtil.logRelationshipError(frUtil.Entity.EMAIL, funraiseId, 
                                            frUtil.Entity.SUPPORTER, supporterFunraiseId);
            }
        }
        
        return result;
    }
}