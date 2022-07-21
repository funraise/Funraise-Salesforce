/*
*
*  Copyright (c) 2020, Funraise Inc
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions are met:
*  1. Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the
*     documentation and/or other materials provided with the distribution.
*  3. All advertising materials mentioning features or use of this software
*     must display the following acknowledgement:
*     This product includes software developed by the <organization>.
*  4. Neither the name of the <organization> nor the
*     names of its contributors may be used to endorse or promote products
*     derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY FUNRAISE INC ''AS IS'' AND ANY
*  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
*  DISCLAIMED. IN NO EVENT SHALL FUNRAISE INC BE LIABLE FOR ANY
*  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
*  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
*  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*
*
* PURPOSE:
*
*
*
* CREATED: 2019 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/

public class frSubscription extends frModel implements frSyncable {
    public static final Map<String, Schema.SObjectField> fields = 
        frSchemaUtil.getFields(Subscription__c.getSObjectType().getDescribe().getName());
        
    public frSubscription(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = getRequestBody();
        if (Boolean.valueOf(request.get('deleted'))) {
            result = deleteSubscription(getFunraiseId());
        } else {
            result = create(request);
        }
        return result;
    }
    
    private Boolean deleteSubscription(String funraiseId) {
        Boolean result = false;
        try {
            delete [SELECT id FROM Subscription__c WHERE fr_ID__c = :funraiseId];
            result = true;
        } catch (DMLException e) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, e);
        }
        return result;
    }
    
    private Boolean create(Map<String, Object> request) {
        Boolean result = false;
        String funraiseId = getFunraiseId();
        String name = String.valueOf(request.get('name'));
        String funraiseSupporterId = String.valueOf(request.get('supporterId'));
        List<Contact> contacts = [SELECT Id from Contact WHERE fr_Id__c = :funraiseSupporterId];
        if(contacts.isEmpty()) {
            if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                        frUtil.Entity.SUPPORTER, funraiseSupporterId);
            return result;
        }
        
        Subscription__c subscription = new Subscription__c(
        	fr_ID__c = funraiseId,
            Name = frUtil.truncateToFieldLength(
                Subscription__c.Name.getDescribe(), 
                String.valueOf(request.get('name'))
            ), 
            Supporter__c = contacts.get(0).Id
        );
        
        String goalId = String.valueOf(request.get('campaignGoalId'));
        if (String.isNotBlank(goalId)) {
            List<Campaign> campaigns = [SELECT Id FROM Campaign WHERE fr_ID__c = :goalId];
            if (campaigns.size() > 0) {
                subscription.Campaign_Goal__c = campaigns.get(0).Id;
            } else {
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.CAMPAIGN, goalId);
            }
        }
        
		//transform other request fields into SF custom fields, these are not applicable
        request.remove('id');
        request.remove('name');
        request.remove('supporterId');
        request.remove('campaignGoalId');
        request.remove('deleted');
        String strPledgeAmount = String.valueOf(request.get('pledgeAmount'));
        Decimal pledgeAmount = String.isNotBlank(strPledgeAmount) ? Decimal.valueOf(strPledgeAmount) : null;
        request.remove('pledgeAmount');
        
        String regex = '([a-z])([A-Z]+)';
        String replacement = '$1_$2';
        for(String funraiseFieldName : request.keySet()) {
            String salesforceFieldName = funraiseFieldName.replaceAll(regex, replacement);
            salesforceFieldName =+ 'funraise__' + salesforceFieldName.capitalize() + '__c';
            Schema.SObjectField field = fields.get(salesforceFieldName);
            frModel.write(subscription, field, funraiseFieldName, request.get(funraiseFieldName), funraiseId);
        }
        
        try {
            Database.upsert(subscription, Subscription__c.Field.fr_ID__c, true);
            result = true;
        } catch (DMLException ex) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, ex);
            return result;
        }
        
        if(pledgeAmount != null) {
            frPledge.create(subscription, pledgeAmount);
        }
        return result;
    }
    
    protected override Boolean requireObjectDeletePermission() {
        return true;
    }
    
    protected override Set<Schema.SObjectField> getFields() {
        return new Set<Schema.SObjectField> {
            	Subscription__c.Name,
                Subscription__c.fr_ID__c,
                Subscription__c.Status__c,
                Subscription__c.Supporter__c,
                Subscription__c.Payment_Method_Expiration_Date__c,
                Subscription__c.Payment_Method_Type__c,
                Subscription__c.Payment_Method_Last_Four__c,
                Subscription__c.Form_Name__c,
                Subscription__c.Next_Payment_Date__c,
                Subscription__c.Frequency__c,
                Subscription__c.Amount__c,
                Subscription__c.Currency__c,
                Subscription__c.Campaign_Page_Name__c,
                Subscription__c.Allocation_Name__c,
                Subscription__c.Comment__c,
                Subscription__c.Note__c,
                Subscription__c.Dedication__c,
                Subscription__c.Dedication_Type__c,
                Subscription__c.Dedication_Name__c,
                Subscription__c.Dedication_Email__c,
                Subscription__c.Dedication_Message__c,
                Subscription__c.Company_Match__c,
                Subscription__c.Company_Match_Company_Name__c,
                Subscription__c.Company_Match_Employee_Email__c,
                Subscription__c.Operations_Tip__c,
                Subscription__c.Imported__c,
                Subscription__c.Campaign_Goal__c
    	};
    }
    
    protected override Set<Schema.SObjectType> getObjects() {
        return new Set<Schema.SObjectType> {
                Subscription__c.SObjectType
        };
    }
    
    protected override frUtil.Entity getFrType() {
        return frUtil.Entity.SUBSCRIPTION;
    }
}