public abstract class frModel {
	protected abstract SObject getObject();
    public abstract List<frMapping__c> getMappings();

    public virtual void populateFromRequest(Map<String, Object> request) {
    	Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields(getObject().getSObjectType().getDescribe().getName());
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
                    frUtil.write(getObject(), field, mapping.sf_Name__c, request.get(fieldName), funraiseId);                    
                }
            }
        }
        for(frMapping__c constantMapping : constantMappings) {
            Schema.SObjectField field = fields.get(constantMapping.sf_Name__c);
            frUtil.write(getObject(), field, constantMapping.sf_Name__c, constantMapping.Constant_Value__c, funraiseId);
        }

        getObject().put('fr_ID__c', funraiseId);
    }
    
    public static void flushLogs() {
        if([SELECT COUNT() FROM Error__c] > 200) {
            deleteLogs();
        }
    }

    @future
    private static void deleteLogs() {
        delete [SELECT Id FROM Error__c ORDER BY CreatedDate DESC LIMIT 10000 OFFSET 100];
    }
}