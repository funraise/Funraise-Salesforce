public class frUtil {
    public static String truncateToFieldLength(DescribeFieldResult describe, String value) { 
        return String.isNotBlank(value) && value.length() > describe.getLength() ? value.substring(0, describe.getLength()) : value;
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
        if (fieldName.toLowerCase() == 'id') {
            if (value != null && ((String)value) != '') {
                record.put(field, Id.valueOf((String)value));
            }
        } else if (field.getDescribe().getType() == Schema.DisplayType.DateTime) {
            try {
                record.put(field, DateTime.newInstance((Long)value));
            }
            catch (Exception e) {
                write(record, field, value, funraiseId);
            }
        } else if (field.getDescribe().getType() == Schema.DisplayType.Date) {
            try {
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
                    record.put(field, DateTime.newInstance((Long)value).dateGMT());
                }
                
            } catch (Exception ex) {
                write(record, field, value, funraiseId);
            }
        } else if(field.getDescribe().getType() == Schema.DisplayType.Double) {
            try {
                record.put(field, Double.valueOf(value));
            }
            catch (Exception e) {
                write(record, field, value, funraiseId);
            }
        } else if(field.getDescribe().getType() == Schema.DisplayType.Integer) {
            try {
                record.put(field, Integer.valueOf(value));
            }
            catch (Exception e) {
                write(record, field, value, funraiseId);
            }
        } else if(field.getDescribe().getType() == Schema.DisplayType.Percent) {
            try {
                record.put(field, Decimal.valueOf(String.valueOf(value)));
            }
            catch (Exception e) {
                write(record, field, value, funraiseId);
            }
        } else {
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
    
}