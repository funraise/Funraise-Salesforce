public abstract class frModel {
    public static String TAG_TYPE = 'Tag';

    public static List<frMapping__c> tagMappings {
        get {
            if(tagMappings == null) {
                tagMappings = [SELECT fr_Name__c, sf_Name__c, Type__c FROM frMapping__c WHERE Type__c = :TAG_TYPE ORDER BY CreatedDate];
            }
            return tagMappings;
        }
        set;
    }

	protected abstract SObject getObject();
    public abstract List<frMapping__c> getMappings();

    public virtual void populateFromRequest(Map<String, Object> request) {
    	Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields(getObject().getSObjectType().getDescribe().getName());

        Map<String, frMapping__c> frNameToSfName = new Map<String, frMapping__c>();
        List<frMapping__c> constantMappings = new List<frMapping__c>();
        for(frMapping__c mapping : getMappings()) {
            if(mapping.Is_Constant__c) {
                constantMappings.add(mapping);
            } else {
                frNameToSfName.put(mapping.fr_Name__c, mapping);
            }
        }

        for(String fieldName : frNameToSfName.keySet()) {
            if(request.containsKey(fieldName)) {
                frMapping__c mapping = frNameToSfName.get(fieldName);
                write(getObject(), fields, mapping.sf_Name__c, request.get(fieldName));
            }
        }
        for(frMapping__c constantMapping : constantMappings) {
            write(getObject(), fields, constantMapping.sf_Name__c, constantMapping.Constant_Value__c);
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
                record.put(field, DateTime.newInstance((Long)value).dateGMT());
            }
            catch (Exception e) {
                write(record, field, value);
            }
        } else if(field.getDescribe().getType() == Schema.DisplayType.Double) {
            try {
                record.put(field, Double.valueOf(value));
            }
            catch (Exception e) {
                write(record, field, value);
            }
        } else if(field.getDescribe().getType() == Schema.DisplayType.Integer) {
            try {
                record.put(field, Integer.valueOf(value));
            }
            catch (Exception e) {
                write(record, field, value);
            }
        } else if(field.getDescribe().getType() == Schema.DisplayType.Percent) {
            try {
                record.put(field, Decimal.valueOf(String.valueOf(value)));
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
            insert new Error__c(Error__c = 'Field mapping exception. Object type: '+ record.getSObjectType().getDescribe().getName()
                +' Record Id: '+record.Id+' - Field: '+field.getDescribe().getName()+' - Value: '+value
                +' Exception: '+ex
            );
        }
    }

    public static void handleException(Exception ex) {
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

    public static String mapTag(String frTagName){
        for(frMapping__c m : tagMappings){
            if(frTagName == m.fr_Name__c){
                return m.sf_Name__c;
            }
        }

        return frTagName;
    }
}
