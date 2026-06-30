public class frInboundSupporterSync {
    public static final String SETTINGS_NAME = 'Default';
    public static final Integer MAX_CALLOUTS_PER_JOB = 25;
    public static Boolean disabled = false;

    public class WorkItem {
        public String funraiseId;
        public String requestBody;

        public WorkItem(String funraiseId, String requestBody) {
            this.funraiseId = funraiseId;
            this.requestBody = requestBody;
        }
    }

    public static void handleContacts(List<Contact> newRecords, Map<Id, Contact> oldMap) {
        if (disabled || frUtil.hasNPCobjects() || !isConfigured(getSettings())) {
            return;
        }

        Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields('Contact');
        List<WorkItem> workItems = new List<WorkItem>();
        for (Contact contact : newRecords) {
            WorkItem workItem = buildContactWorkItem(contact, oldMap.get(contact.Id), fields);
            if (workItem != null) {
                workItems.add(workItem);
            }
        }

        enqueue(workItems);
    }

    public static void handleAccounts(List<Account> newRecords, Map<Id, Account> oldMap) {
        if (disabled || !frUtil.hasNPCobjects() || !isConfigured(getSettings())) {
            return;
        }

        Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields('Account');
        List<WorkItem> workItems = new List<WorkItem>();
        for (Account account : newRecords) {
            WorkItem workItem = buildAccountWorkItem(account, oldMap.get(account.Id), fields);
            if (workItem != null) {
                workItems.add(workItem);
            }
        }

        enqueue(workItems);
    }

    public static frInboundSettings__c getSettings() {
        return frInboundSettings__c.getInstance(SETTINGS_NAME);
    }

    public static Boolean isConfigured(frInboundSettings__c settings) {
        return settings != null
            && settings.Enabled__c == true
            && String.isNotBlank(settings.Named_Credential__c)
            && String.isNotBlank(settings.Organization_UUID__c)
            && String.isNotBlank(settings.Secret__c);
    }

    private static WorkItem buildContactWorkItem(Contact contact, Contact oldContact, Map<String, Schema.SObjectField> fields) {
        if (!hasField(fields, 'fr_id__c')) {
            return null;
        }

        String funraiseId = stringValue(getFieldValue(contact, fields, 'fr_id__c'));
        if (String.isBlank(funraiseId)) {
            return null;
        }

        Map<String, Object> body = new Map<String, Object>();
        addChangedField(body, contact, oldContact, fields, 'email', 'email');
        addChangedField(body, contact, oldContact, fields, 'phone', 'phone');
        addChangedField(body, contact, oldContact, fields, 'firstname', 'firstName');
        addChangedField(body, contact, oldContact, fields, 'lastname', 'lastName');
        addChangedField(body, contact, oldContact, fields, 'mailingstreet', 'address1');
        addChangedField(body, contact, oldContact, fields, 'mailingcity', 'city');
        addChangedField(body, contact, oldContact, fields, 'mailingstate', 'state');
        addChangedField(body, contact, oldContact, fields, 'mailingpostalcode', 'postalCode');
        addChangedField(body, contact, oldContact, fields, 'mailingcountry', 'country');

        if (body.isEmpty()) {
            return null;
        }
        return new WorkItem(funraiseId, JSON.serialize(body));
    }

    private static WorkItem buildAccountWorkItem(Account account, Account oldAccount, Map<String, Schema.SObjectField> fields) {
        if (hasField(fields, 'ispersonaccount')) {
            Boolean isPersonAccount = (Boolean)getFieldValue(account, fields, 'ispersonaccount');
            if (isPersonAccount != true) {
                return null;
            }
        }

        if (!hasField(fields, 'fr_id__c')) {
            return null;
        }

        String funraiseId = stringValue(getFieldValue(account, fields, 'fr_id__c'));
        if (String.isBlank(funraiseId)) {
            return null;
        }

        Map<String, Object> body = new Map<String, Object>();
        addChangedField(body, account, oldAccount, fields, 'personemail', 'email');
        addChangedField(body, account, oldAccount, fields, 'phone', 'phone');
        addChangedField(body, account, oldAccount, fields, 'firstname', 'firstName');
        addChangedField(body, account, oldAccount, fields, 'lastname', 'lastName');
        addChangedField(body, account, oldAccount, fields, 'personmailingstreet', 'address1');
        addChangedField(body, account, oldAccount, fields, 'personmailingcity', 'city');
        addChangedField(body, account, oldAccount, fields, 'personmailingstate', 'state');
        addChangedField(body, account, oldAccount, fields, 'personmailingpostalcode', 'postalCode');
        addChangedField(body, account, oldAccount, fields, 'personmailingcountry', 'country');

        if (body.isEmpty()) {
            return null;
        }
        return new WorkItem(funraiseId, JSON.serialize(body));
    }

    private static void addChangedField(
        Map<String, Object> body,
        SObject currentRecord,
        SObject oldRecord,
        Map<String, Schema.SObjectField> fields,
        String salesforceField,
        String funraiseField
    ) {
        if (!hasField(fields, salesforceField)) {
            return;
        }

        Object currentValue = getFieldValue(currentRecord, fields, salesforceField);
        Object oldValue = oldRecord == null ? null : getFieldValue(oldRecord, fields, salesforceField);
        if (!valuesEqual(currentValue, oldValue)) {
            body.put(funraiseField, currentValue);
        }
    }

    private static Boolean valuesEqual(Object currentValue, Object oldValue) {
        if (currentValue == null && oldValue == null) {
            return true;
        }
        if (currentValue == null || oldValue == null) {
            return false;
        }
        return String.valueOf(currentValue) == String.valueOf(oldValue);
    }

    private static void enqueue(List<WorkItem> workItems) {
        if (workItems.isEmpty()) {
            return;
        }

        Integer availableJobs = Limits.getLimitQueueableJobs() - Limits.getQueueableJobs();
        Integer enqueuedJobs = 0;
        Integer index = 0;
        while (index < workItems.size() && enqueuedJobs < availableJobs) {
            Integer endIndex = Math.min(index + MAX_CALLOUTS_PER_JOB, workItems.size());
            List<WorkItem> chunk = new List<WorkItem>();
            for (Integer chunkIndex = index; chunkIndex < endIndex; chunkIndex++) {
                chunk.add(workItems.get(chunkIndex));
            }
            System.enqueueJob(new frInboundSupporterSyncJob(chunk));
            enqueuedJobs++;
            index += MAX_CALLOUTS_PER_JOB;
        }

        if (index < workItems.size()) {
            frUtil.logError(
                frUtil.Entity.SUPPORTER,
                workItems.get(index).funraiseId,
                'Salesforce supporter update sync skipped '
                    + String.valueOf(workItems.size() - index)
                    + ' record(s) because the Queueable job limit was reached'
            );
        }
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Boolean hasField(Map<String, Schema.SObjectField> fields, String fieldName) {
        return fields.containsKey(fieldName.toLowerCase());
    }

    private static Object getFieldValue(SObject record, Map<String, Schema.SObjectField> fields, String fieldName) {
        Schema.SObjectField field = fields.get(fieldName.toLowerCase());
        return field == null ? null : record.get(field.getDescribe().getName());
    }
}
