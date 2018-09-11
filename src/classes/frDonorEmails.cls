public class frDonorEmails extends frModel {
    public static final String TYPE = 'DonorEmails';

    public static List<frMapping__c> mappings {
        get {
            if(mappings == null) {
                mappings = [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Type__c FROM frMapping__c WHERE Type__c = :TYPE ORDER BY CreatedDate];
            }
            return mappings;
        }
        set;
    }

    protected override SObject getObject() {
        return d.getContact();
    }

    public override List<frMapping__c> getMappings() {
        return mappings;
    }

    private frDonor d;

    public frDonorEmails(frDonor d) {
        this.d = d;
    }

    public void parseEmails(Map<String, Object> request, String contactId) {
        Map<String, Object> emails = (Map<String, Object>)request.get('emails');
        try {
            List<Event> eventList = new List<Event>();
            for (String s : emails.keySet()) {
                Map<String, Object> e = (Map<String, Object>)emails.get(s);
                Event ev = new Event();
                ev.fr_Email_ID__c = String.valueOf(e.get('emailId'));
                ev.ActivityDateTime = DateTime.newInstance((Long)e.get('sentDate')).dateGMT();
                ev.WhoId = contactId;
                ev.Subject = 'Funraise Email - ' + String.valueOf(e.get('subject'));
                ev.DurationInMinutes = 1;
                eventList.add(ev);
            }
            Database.upsert(eventList, Event.Fields.fr_Email_ID__c, true);
        } catch (DMLException e) {
            handleException(e);
        }
    }

    public static String create(Map<String, Object> request) {
        String frId = String.valueOf(request.get('id'));

        // Try to find a donor that's already been integrated, use their funraise ID
        frDonor donor = frDonor.findByFunraiseId(frId);

        // If we don't a donor we will not add the emails
        if (donor != null) {
            frDonorEmails donorEmails = new frDonorEmails(donor);
            donorEmails.parseEmails(request, donor.getContactId());

            return donor.getContactId();
        }
        return '-1';
    }
}
