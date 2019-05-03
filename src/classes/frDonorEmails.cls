public class frDonorEmails {
    
    public static void parseEmails(Map<String, Object> request, String contactId) {
        try {
            EmailMessage email = new EmailMessage();
            email.Status = '3';
            email.FromAddress = String.valueOf(request.get('fromAddress'));
            email.FromName = String.valueOf(request.get('fromName'));
            email.toIds = new String[]{contactId};
            email.subject = 'Funraise Email - ' + String.valueOf(request.get('subject'));
            email.MessageDate = DateTime.newInstance((Long)request.get('sentDate')).dateGMT();
            email.fr_Email_ID__c = String.valueOf(request.get('id'));
            insert email;
            
            EmailMessageRelation emr = new EmailMessageRelation();
            emr.EmailMessageId = email.Id;
            emr.RelationId = contactId;
            emr.RelationType = 'ToAddress';
            insert emr;
        } catch (DMLException e) {
            insert new Error__c(Error__c =
            'Failed to insert funraise email for donor id ' + contactId +
            '. Exception: ' + e.getMessage() + ' -- ' + request.get('sentDate'));
        }
    }

    public static String create(Map<String, Object> request) {
        String frId = String.valueOf(request.get('donorId'));
        
        // Try to find a donor that's already been integrated, use their funraise ID
        frDonor donor = frDonor.findByFunraiseId(frId);
        
        // If we don't a donor we will not add the emails
        if (donor != null) {
            frDonorEmails.parseEmails(request, donor.getContactId());
    
            return donor.getContactId();
        }
        return null;
    } 
}