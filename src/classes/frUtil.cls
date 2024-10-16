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

    public static Boolean hasPersonAccountsEnabled() {
        try {
            return Account.SObjectType.getDescribe().fields.getMap().containsKey('IsPersonAccount');
        } catch (TypeException te) {
            return false;
        }
    }

    public static Boolean hasNPCobjects() {
        try {
            return Schema.getGlobalDescribe().containsKey('gifttransaction');
        } catch (TypeException te) {
            return false;
        }
    }
    
    public static void logRelationshipError(Entity errObject, String recordId, Entity missingRelationship, String relationshipId) {
        logRelationshipError(errObject, recordId, missingRelationship, relationshipId, null);
    }
    
    public static void logRelationshipError(Entity errObject, String recordId, Entity missingRelationship, String relationshipId, String optionalError) {
        String relationshipObject = getObjectFromEnum(missingRelationship);
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
		String funraiseObject = getObjectFromEnum(errObject);
        try {
            insert new Error__c(
                Error__c = frUtil.truncateToFieldLength(Error__c.Error__c.getDescribe(), error),
                Funraise_Object__c = funraiseObject,
                Funraise_Object_Id__c = recordId
            );    
        } catch (Exception ex) {
            //the only reason this may fail is SF storage limits
            System.debug('Failed to create Funraise Error__c log.  Error dump:');
            System.debug(String.format('Error: {0}, Object: {1}, Object Id: {2}', new List<String>{error, funraiseObject, recordId}));
        }
        
    }
    
    private static String getObjectFromEnum(Entity frObject) {
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
        } else if (frObject == Entity.QUESTION) {
            funraiseObject = 'Question';
        } else if (frObject == Entity.ANSWER) {
            funraiseObject = 'Question Answer';
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
        PLEDGE,
        QUESTION,
        ANSWER
    }
    
}