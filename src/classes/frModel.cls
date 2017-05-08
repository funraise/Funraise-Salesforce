public abstract class frModel {
	protected abstract SObject getObject();
    public abstract List<frMapping__c> getMappings();

    public virtual void populateFromRequest(Map<String, Object> request) {
    	Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields(getObject().getSObjectType().getDescribe().getName());

        Map<String, String> frNameToSfName = new Map<String, String>();
        for(frMapping__c mapping : getMappings()) {
            frNameToSfName.put(mapping.fr_Name__c, mapping.sf_Name__c);
        }

        for(String fieldName : request.keySet()) {
            if(frNameToSfName.containsKey(fieldName)) {                
                write(getObject(), fields, frNameToSfName.get(fieldName), request.get(fieldName));
            }
        }
        getObject().put('fr_ID__c', String.valueOf(request.get('id')));
    }

    private static void write(SObject record, Map<String, Schema.SObjectField> fields, String fieldName, Object value) {
        Schema.SObjectField field = fields.get(fieldName);
        if (fieldName.toLowerCase() == 'id') {
            if (value != null && ((String)value) != '') {
                record.put(field, Id.valueOf((String)value));
            }
        } else if (field.getDescribe().getType() == Schema.DisplayType.DateTime) {
            try {
                record.put(field, DateTime.newInstance((Long)value));
            }
            catch (Exception e) {
                write(record, field, value);
            }
        } else if (field.getDescribe().getType() == Schema.DisplayType.Date) {
            try {
                record.put(field, DateTime.newInstance((Long)value).date());
            }
            catch (Exception e) {
                write(record, field, value);
            }
        } else {
            write(record, field, value);
        }
    }
    private static void write(SObject record, Schema.SObjectField field, Object value) {
        try {
            record.put(field, value);
        } catch (Exception ex) {
            insert new Error__c(Error__c = 'Field mapping exception. Object type: '+ record.getSObjectType().getDescribe().getName()+' Record Id: '+record.Id+' - Field: '+field.getDescribe().getName()+' - Value: '+value);
        }
    }

    protected void handleException(Exception ex) {
        insert new Error__c(Error__c = ex.getMessage());
    }

    
    public static void flushLogs() {
        if([SELECT COUNT() FROM Error__c] > 100) {
            deleteLogs();
        }
    }

    @future
    private static void deleteLogs() {
        delete [SELECT Id FROM Error__c ORDER BY CreatedDate DESC LIMIT 10000 OFFSET 100];
    }

}