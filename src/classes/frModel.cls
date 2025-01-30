public with sharing abstract class frModel {
    public static final String MAPPING_OVERWRITE = 'overwrite';
    public static final String MAPPING_NO_OVERWRITE = 'do_not_overwrite';
    public static final String MAPPING_OVERWRITE_NON_NULL = 'overwrite_non_null';
    public static final String MAPPING_OVERWRITE_RECENT = 'overwrite_more_recent';
    
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
    
    protected virtual String getSalesforceId() {
        return null;
    }
    
    protected virtual Boolean requireObjectDeletePermission() {
        return false;
    }
    
    protected virtual String getUpdtimeJsonKey() {
        return 'updtime';
    }
    
    private Datetime getUpdtime() {
        if(getRequestBody().containsKey(getUpdtimeJsonKey())) {
            return Datetime.newInstance((Long)getRequestBody().get(getUpdtimeJsonKey()));
        }
        return null;
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
        String sObjectName = record.getSObjectType().getDescribe().getName();
        Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields(sObjectName);
        //a single funraise field might flow into multiple salesforce fields
        Map<String, List<frMapping__c>> frFieldToMappings = new Map<String, List<frMapping__c>>();
        List<frMapping__c> constantMappings = new List<frMapping__c>();
        Set<String> fieldsToQueryFor = new Set<String>();
        Boolean needLastModifiedDate = false;
        for(frMapping__c mapping : getMappings()) {
            if(mapping.Is_Constant__c) {
                constantMappings.add(mapping);
            } else {
                List<frMapping__c> mappings;
                if(frFieldToMappings.containsKey(mapping.fr_Name__c)) {
                    mappings = frFieldToMappings.get(mapping.fr_Name__c);
                } else {
                    mappings = new List<frMapping__c>();
                }
                mappings.add(mapping);
                frFieldToMappings.put(mapping.fr_Name__c, mappings);
            }
            
            if(mapping.Conflict_Resolution__c == MAPPING_NO_OVERWRITE) {
                //We need to know the existing values of these fields
                //if null, we can sync the incoming data.  Otherwise, we don't overwrite
                fieldsToQueryFor.add(mapping.sf_Name__c);
            }
            if(!needLastModifiedDate && mapping.Conflict_Resolution__c == MAPPING_OVERWRITE_RECENT) {
                needLastModifiedDate = true;
            }
        }        
        if(needLastModifiedDate) {
            fieldsToQueryFor.add('LastModifiedDate');    
        }
        
        String funraiseId = getFunraiseId();
        String salesforceId = getSalesforceId();
        SObject queriedFieldsRecord = null;
        if(!fieldsToQueryFor.isEmpty()) {
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQueryFor), ',') 
                + ' FROM ' + sObjectName + ' WHERE ';
            if(getSalesforceId() != null) {
                query += 'Id = :salesforceId';
            } else {
                query += 'fr_Id__c = :funraiseId';
            }
            List<SObject> results = Database.query(query);
            if(results.size() > 0) {
                queriedFieldsRecord = results.get(0);
            }    
        }
        
        Boolean isMoreRecent = queriedFieldsRecord == null; //if we didn't get a queriedFieldsRecord returned, all fields from Funraise are more recent
        if(needLastModifiedDate && queriedFieldsRecord != null) {
            Datetime sfRecordUpdtime = (Datetime)queriedFieldsRecord.get('LastModifiedDate');
            isMoreRecent = getUpdtime() != null ? getUpdtime() > sfRecordUpdtime : false;
        }
        
        for(String fieldName : frFieldToMappings.keySet()) {
            if(request.containsKey(fieldName)) {
                for(frMapping__c mapping : frFieldToMappings.get(fieldName)) {
                    if(!fields.containsKey(mapping.sf_Name__c)) continue; //Make sure field is valid
                    Schema.SObjectField field = fields.get(mapping.sf_Name__c);
                    Object incomingValue = request.get(fieldName);
                    Boolean write = false;
                    if(String.isBlank(mapping.Conflict_Resolution__c) || mapping.Conflict_Resolution__c == MAPPING_OVERWRITE) {
                        write = true;      
                    } else if (mapping.Conflict_Resolution__c == MAPPING_OVERWRITE_NON_NULL && (incomingValue != null || (incomingValue instanceOf String && String.isNotBlank((String)incomingValue)))) {
                        write = true;
                    } else if (mapping.Conflict_Resolution__c == MAPPING_NO_OVERWRITE) {
                        Object existingValue = queriedFieldsRecord != null ? queriedFieldsRecord.get(field) : null;
                        write = existingValue == null;
                    } else if (mapping.Conflict_Resolution__c == MAPPING_OVERWRITE_RECENT && isMoreRecent) {
                        write = true;
                    } else if (String.isNotBlank(mapping.Conflict_Resolution__c) && !VALID_CONFLICT_RESOLUTIONS.contains(mapping.Conflict_Resolution__c)) {
                        insert new Error__c(Error__c = 'Field mapping exception. Unknown conflict resolution provided. Object type: '+ sObjectName +
                                            ' - Field: '+field.getDescribe().getName() + 'Conflict Resolution: '+ mapping.Conflict_Resolution__c);
                    }
                    if(write) {
                        write(record, field, mapping.sf_Name__c, incomingValue, funraiseId);    
                    }
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
                if(value != NULL) record.put(field, DateTime.newInstance((Long)value)); //Added null handling
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
            try {
                insert new Error__c(Error__c = 'Field mapping exception. Object type: '+ record.getSObjectType().getDescribe().getName()
                                +' Record Id: '+record.Id+' - Funraise Id: '+ funraiseId + ' - Field: '+field.getDescribe().getName()+' - Value: '+value
                                +' Exception: '+ex
                               );
            } catch (Exception exc) {
                insert new Error__c(Error__c =  'Exception: '+ex + ' - Failed To insert with detail: ' + exc);
            }
        }
    }
    
    public static DateTime convertFromLocalDateTime(List<Object> localDateTime) {
        return DateTime.newInstance(
            (Integer)localDateTime.get(0), //year
            (Integer)localDateTime.get(1), //month
            (Integer)localDateTime.get(2), //day
            (Integer)localDateTime.get(3), //hour
            (Integer)localDateTime.get(4), //minute
            0           //second
        );
    }
    
    public static Date convertFromLocalDate(List<Object> localDate) {
        return Date.newInstance(
            (Integer)localDate.get(0), //year
            (Integer)localDate.get(1), //month
            (Integer)localDate.get(2)  //day
        );
    }

    private static final Set<String> VALID_CONFLICT_RESOLUTIONS = new Set<String>{
        MAPPING_OVERWRITE, MAPPING_NO_OVERWRITE, MAPPING_OVERWRITE_NON_NULL, MAPPING_OVERWRITE_RECENT
    };
}