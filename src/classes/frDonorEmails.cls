public class frDonorEmails {
    private frDonor d;

    public frDonorEmails(frDonor d) {
        this.d = d;
    }

    public void parseEmails(Map<String, Object> request, String contactId) {
        try {
            System.debug('Creating new event');
            Event ev = new Event();
            ev.fr_Email_ID__c = String.valueOf(request.get('emailId'));
            System.debug('Email ID' + ev.fr_Email_ID__c);
            ev.ActivityDateTime = DateTime.newInstance((Long)request.get('sentDate')).dateGMT();
            ev.WhoId = contactId;
            ev.Subject = 'Funraise Email - ' + String.valueOf(request.get('subject'));
            ev.DurationInMinutes = 1;
            Database.upsert(ev, Event.Fields.fr_Email_ID__c, true);
        } catch (DMLException e) {
        	insert new Error__c(Error__c = e.getMessage());
        }
    }

    public static String create(Map<String, Object> request) {
        String frId = String.valueOf(request.get('id'));
        System.debug('Looking for donor');

        // Try to find a donor that's already been integrated, use their funraise ID
        frDonor donor = frDonor.findByFunraiseId(frId);

        // If we don't a donor we will not add the emails
        if (donor != null) {
            System.debug('Donor found');
            frDonorEmails donorEmails = new frDonorEmails(donor);
            donorEmails.parseEmails(request, donor.getContactId());

            return donor.getContactId();
        }
        return null;
    }
}
