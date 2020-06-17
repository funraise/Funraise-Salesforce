public class frUtil {
    private static String FUNRAISE_ID_FIELD = 'fr_Id__c';
    public static String truncateToFieldLength(DescribeFieldResult describe, String value) { 
        return String.isNotBlank(value) && value.length() > describe.getLength() ? value.substring(0, describe.getLength()) : value;
    }
    
    public static Boolean hasNPSP(){
        try {
            return UserInfo.isCurrentUserLicensed('npsp');
        } catch (TypeException te) {
            return false;
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
                value = truncateToFieldLength(field.getDescribe(), (String)value);
            }
            record.put(field, value);
        } catch (Exception ex) {
            insert new Error__c(Error__c = 'Field mapping exception. Object type: '+ record.getSObjectType().getDescribe().getName()
                +' Record Id: '+record.Id+' - Funraise Id: '+ funraiseId + ' - Field: '+field.getDescribe().getName()+' - Value: '+value
                +' Exception: '+ex
            );
        }
    }
    
    public static void logRelationshipError(Entity errObject, String recordId, Entity missingRelationship, String relationshipId) {
        logRelationshipError(errObject, recordId, missingRelationship, relationshipId, null);
    }
    
    public static void logRelationshipError(Entity errObject, String recordId, Entity missingRelationship, String relationshipId, String optionalError) {
        String relationshipObject = getErrorObjectFromEnum(missingRelationship);
        String error = 'Failed to find related record ' + 
                 relationshipObject + ' with Funraise Id: ' + relationshipId;
        if(optionalError != null) {
            error += '. ' + optionalError;
        }
        logError(errObject, recordId, error);
    }
    
    private static Set<StatusCode> duplicateValueStatusCodes = 
        new Set<StatusCode>{StatusCode.DUPLICATE_EXTERNAL_ID, StatusCode.DUPLICATE_VALUE};
            
    public static void logException(Entity errObject, String recordId, Exception ex) {
        if(ex instanceof DMLException) {
            DMLException dmlEx = (DMLException)ex;
            //If it's the race condition on fr_Id__c duplicate value, then ignore it.  Else, log it
            for(Integer i = 0; i < dmlEx.getNumDml(); i++) {
                if(!(dmlEx.getDmlMessage(i).containsIgnoreCase(FUNRAISE_ID_FIELD) && duplicateValueStatusCodes.contains(dmlEx.getDmlType(i)))) {
                    logError(errObject, recordId, 'Operation failed. Exception: '+ex.getMessage());
                }
            }
            
        } else {
            logError(errObject, recordId, 'Operation failed. Exception: '+ex.getMessage());            
        }
    }
    
    public static void logError(Entity errObject, String recordId, String error) {
		String funraiseObject = getErrorObjectFromEnum(errObject);
        insert new Error__c(
        	Error__c = error,
            Funraise_Object__c = funraiseObject,
            Funraise_Object_Id__c = recordId
        );
    }
    
    private static String getErrorObjectFromEnum(Entity frObject) {
        String funraiseObject = null;
        if(frObject == Entity.DONATION) {
            funraiseObject = 'Transaction';
        } else if (frObject == Entity.SUPPORTER) {
            funraiseObject = 'Supporter';
        } else if (frObject == Entity.EVENT) {
            funraiseObject = 'Fundraising Event';
        } else if (frObject == Entity.REGISTRATION) {
            funraiseObject = 'Fundraising Event Registration';
        } else if (frObject == Entity.SUBSCRIPTION) {
            funraiseObject = 'Subscription';
        } else if (frObject == Entity.CAMPAIGN) {
            funraiseObject = 'Campaign';
        } else if (frObject == Entity.EMAIL) {
            funraiseObject = 'Email';
        } else if (frObject == Entity.TASK) {
            funraiseObject = 'Task/Interaction';
        } else if (frObject == Entity.PLEDGE) {
            funraiseObject = 'Pledge';
        }
        return funraiseObject;
    }
    
    public enum Entity {
        DONATION,
        SUPPORTER,
        EVENT,
        REGISTRATION,
        SUBSCRIPTION,
        CAMPAIGN,
        EMAIL,
        TASK,
        PLEDGE
    }
    
}