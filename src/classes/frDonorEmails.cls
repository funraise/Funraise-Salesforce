public class frDonorEmails {
    
    public static String parseEmails(Map<String, Object> request, String funraiseId, String contactId) {
        try {
            EmailMessage email = new EmailMessage();
            email.Status = '3';
            email.FromAddress = String.valueOf(request.get('fromAddress'));
            email.FromName = String.valueOf(request.get('fromName'));
            email.toIds = new String[]{contactId};
            email.subject = 'Funraise Email - ' + String.valueOf(request.get('subject'));
            email.MessageDate = DateTime.newInstance((Long)request.get('sentDate')).dateGMT();
            email.fr_Email_ID__c = funraiseId;
            Database.upsert(email, EmailMessage.Fields.fr_Email_ID__c, true);
            
            EmailMessageRelation emr = new EmailMessageRelation();
            emr.EmailMessageId = email.Id;
            emr.RelationId = contactId;
            emr.RelationType = 'ToAddress';
            insert emr;
            return email.Id;
        } catch (DMLException ex) {
            frUtil.logException(frUtil.Entity.EMAIL, funraiseId, ex);
        }
        return null;
    }

    public static String create(Map<String, Object> request) {
        String funraiseId = String.valueOf(request.get('id'));
        String supporterFunraiseId = String.valueOf(request.get('donorId'));        
        if (String.isNotBlank(supporterFunraiseId)) {
            List<Contact> contacts = [SELECT Id FROM Contact WHERE fr_ID__c = :supporterFunraiseId];
            if (contacts.size() > 0) {
                return frDonorEmails.parseEmails(request, funraiseId, contacts.get(0).Id);
            } else {
                frUtil.logRelationshipError(frUtil.Entity.EMAIL, funraiseId, 
                                            frUtil.Entity.SUPPORTER, supporterFunraiseId);
            }
        }
        return null;
    } 
}