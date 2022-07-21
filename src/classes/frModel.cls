public with sharing abstract class frModel {
    protected Sync_Attempt__c syncRecord;
    protected Map<String, Object> requestBody;
    protected Boolean createLogRecord = false;
    
    public frModel(Sync_Attempt__c attempt) {
        this.syncRecord = attempt;
        createLogRecord = attempt.Attempts__c >= frSyncRequestHandler.MAX_ATTEMPTS;
    }
    
    protected Map<String, Object> getRequestBody() {
        if (requestBody == null) {
            requestBody = (Map<String, Object>)JSON.deserializeUntyped(syncRecord.Request_Body__c);
        }
        return requestBody;
    }
    
    protected virtual String getFunraiseId() {
        return String.valueOf(getRequestBody().get('id'));
    }
    
    protected virtual Boolean requireObjectDeletePermission() {
        return false;
    }
    
    protected abstract Set<Schema.SObjectField> getFields();
    protected abstract Set<Schema.SObjectType> getObjects();
    protected abstract frUtil.Entity getFrType();
    
    public boolean checkPermissions() {
        Boolean success = true;        
        String error = '';
        for(Schema.SObjectType objTypeRef : getObjects()) {
            DescribeSObjectResult objType = objTypeRef.getDescribe();
            if(!objType.isAccessible() || !objType.isUpdateable() ||  !objType.isCreateable() || (requireObjectDeletePermission() && !objType.isDeletable())) {
                success = false;
                error += 'Missing permission for object ' + objType.getLabel() + ' ('+ objType.getName()+')\n';
            }
        }
        for(Schema.SObjectField fieldRef : getFields()) {
            DescribeFieldResult field = fieldRef.getDescribe();
            if(!field.isAccessible() ||  !field.isCreateable()) {
                success = false;
                error += 'Missing permission for field ' + field.getLabel() + ' ('+ field.getName()+')\n';
            }
        }
        if(!success) {
            frUtil.logError(getFrType(), getFunraiseId(), error);
        }
        return success;
    }
    
    
    protected virtual List<frMapping__c> getMappings() {
        return new List<frMapping__c>();
    }
    
    protected void applyMappings(SObject record, Map<String, Object> request) {
    	Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields(record.getSObjectType().getDescribe().getName());
        String funraiseId = String.valueOf(request.get('id'));
        
        //a single funraise field might flow into multiple salesforce fields
        Map<String, List<frMapping__c>> frNameToSfName = new Map<String, List<frMapping__c>>();
        List<frMapping__c> constantMappings = new List<frMapping__c>();
        for(frMapping__c mapping : getMappings()) {
            if(mapping.Is_Constant__c) {
                constantMappings.add(mapping);
            } else {
                List<frMapping__c> mappings;
                if(frNameToSfName.containsKey(mapping.fr_Name__c)) {
                    mappings = frNameToSfName.get(mapping.fr_Name__c);
                } else {
                    mappings = new List<frMapping__c>();
                }
                mappings.add(mapping);
                frNameToSfName.put(mapping.fr_Name__c, mappings);
            }
        }

        for(String fieldName : frNameToSfName.keySet()) {
            if(request.containsKey(fieldName)) {
                for(frMapping__c mapping : frNameToSfName.get(fieldName)) {
                    Schema.SObjectField field = fields.get(mapping.sf_Name__c);
                    write(record, field, mapping.sf_Name__c, request.get(fieldName), funraiseId);                    
                }
            }
        }
        for(frMapping__c constantMapping : constantMappings) {
            Schema.SObjectField field = fields.get(constantMapping.sf_Name__c);
            write(record, field, constantMapping.sf_Name__c, constantMapping.Constant_Value__c, funraiseId);
        }

        record.put('fr_ID__c', funraiseId);
    }
    
    public static void write(SObject record, Schema.SObjectField field, String fieldName, Object value, String funraiseId) {
        try {
            if (fieldName.toLowerCase() == 'id') {
                if (value != null && ((String)value) != '') {
                    record.put(field, Id.valueOf((String)value));
                }
            } else if (field.getDescribe().getType() == Schema.DisplayType.DateTime) {
                record.put(field, DateTime.newInstance((Long)value));
            } else if (field.getDescribe().getType() == Schema.DisplayType.Date) {
                if(value instanceof List<Object>) {
                    List<Object> localDate = (List<Object>)value;
                    if(localDate.size() > 3) {
                        DateTime sfLocalDateTime = convertFromLocalDateTime(localDate);
                        record.put(field, sfLocalDateTime);                        
                    } else if (localDate.size() == 3) {
                        Date sfLocalDate = convertFromLocalDate(localDate);
                        record.put(field, sfLocalDate);                        
                    }
                    
                } else {
                    record.put(field, DateTime.newInstance((Long)value).date());
                }
            } else if(field.getDescribe().getType() == Schema.DisplayType.Double) {
                record.put(field, Double.valueOf(value));
            } else if(field.getDescribe().getType() == Schema.DisplayType.Integer) {
                record.put(field, Integer.valueOf(value));
            } else if(field.getDescribe().getType() == Schema.DisplayType.Percent) {
                record.put(field, Decimal.valueOf(String.valueOf(value)));
            } else if(field.getDescribe().getType() == Schema.DisplayType.Boolean) {
                record.put(field, Boolean.valueOf(String.valueOf(value)));
            } else {
                write(record, field, value, funraiseId);
            }
        }
        catch (Exception e) {
            write(record, field, value, funraiseId);
        }
    }
    
    private static void write(SObject record, Schema.SObjectField field, Object value, String funraiseId) {
        try {
            if(value instanceof String) {
                value = frUtil.truncateToFieldLength(field.getDescribe(), (String)value);
            }
            record.put(field, value);
        } catch (Exception ex) {
            insert new Error__c(Error__c = 'Field mapping exception. Object type: '+ record.getSObjectType().getDescribe().getName()
                +' Record Id: '+record.Id+' - Funraise Id: '+ funraiseId + ' - Field: '+field.getDescribe().getName()+' - Value: '+value
                +' Exception: '+ex
            );
        }
    }
    
    public static DateTime convertFromLocalDateTime(List<Object> localDateTime) {
        return DateTime.newInstance(
            (Integer)localDateTime.get(0), //year
            (Integer)localDateTime.get(1), //month
            (Integer)localDateTime.get(2), //day
            (Integer)localDateTime.get(3), //hour
            (Integer)localDateTime.get(4), //minute
            0 				  //second
        );
    }
    
    public static Date convertFromLocalDate(List<Object> localDate) {
        return Date.newInstance(
            (Integer)localDate.get(0), //year
            (Integer)localDate.get(1), //month
            (Integer)localDate.get(2)  //day
        );
    }
    
    public static void flushLogs() {
        if([SELECT COUNT() FROM Error__c LIMIT 250] > 200) {
            deleteLogs();
        }
    }

    @future
    private static void deleteLogs() {
        delete [SELECT Id FROM Error__c ORDER BY CreatedDate DESC LIMIT 10000 OFFSET 100];
    }
}