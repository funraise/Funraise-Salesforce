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
* CREATED: 2020 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/

public class frAnswer extends frModel implements frSyncable {
    public frAnswer(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = getRequestBody();
    	if (Boolean.valueOf(request.get('deleted'))) {
            result = deleteAnswer(getFunraiseId());
        } else {
            result = create(request);
        }
        return result;
    }
    
    private Boolean deleteAnswer(String funraiseId) {
        Boolean result = false;
        try {
            delete [SELECT id FROM Answer__c WHERE fr_ID__c = :funraiseId];
            result = true;
        } catch (DMLException e) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, e);
        }
        return result;
    }
    
    private Boolean create(Map<String, Object> request) {
        Boolean result = false;
        String funraiseId = getFunraiseId();
        
        String questionId = String.valueOf(request.get('questionId'));
        List<Question__c> questions = [SELECT Id from Question__c WHERE fr_Id__c = :questionId];
        if(questions.isEmpty()) {
            if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                        frUtil.Entity.QUESTION, questionId);
            return result;
        }
        
        SObject supporter = null;
        String funraiseSupporterId = String.valueOf(request.get('supporterId'));
        if(String.isNotBlank(funraiseSupporterId)) {
            List<SObject> supporters;
            if(frUtil.hasNPCobjects()) supporters = Database.query('SELECT Id FROM Account WHERE fr_ID__c = :funraiseSupporterId');
            else supporters = [SELECT Id, AccountId FROM Contact WHERE fr_ID__c = :funraiseSupporterId];
            System.debug('supporters: ' + supporters);
            if(supporters.isEmpty()) {
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.SUPPORTER, funraiseSupporterId);
            } else {
                supporter = supporters.get(0);
            }
        }
        
        SObject trsact = null;
        String funraiseTransactionId = String.valueOf(request.get('donationId'));
        if(String.isNotBlank(funraiseTransactionId)) {
            List<SObject> transactions;
            if (frUtil.hasNPCobjects()) transactions = Database.query('SELECT Id, Name FROM GiftTransaction WHERE fr_ID__c = :funraiseTransactionId');
            else transactions = [SELECT Id from Opportunity WHERE fr_Id__c = :funraiseTransactionId];
            if(transactions.isEmpty()) {
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.DONATION, funraiseTransactionId);
            } else {
                trsact = transactions.get(0);
            }
        }
        
        Campaign page = null;
        String funraisePageGoalId = String.valueOf(request.get('pageGoalId'));
        if(String.isNotBlank(funraisePageGoalId)) {
            List<Campaign> pages = [SELECT Id from Campaign WHERE fr_Id__c = :funraisePageGoalId];
            if(pages.isEmpty()) {
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.CAMPAIGN, funraisePageGoalId);
            } else {
                page = pages.get(0);
            }
        }
        
        Fundraising_Event_Registration__c registration = null;
        String funraiseRegistrationId = String.valueOf(request.get('registrationId'));
        if(String.isNotBlank(funraiseRegistrationId)) {
            List<Fundraising_Event_Registration__c> registrations = [SELECT Id from Fundraising_Event_Registration__c WHERE fr_Id__c = :funraiseRegistrationId];
            if(registrations.isEmpty()) {
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.REGISTRATION, funraiseRegistrationId);
            } else {
                registration = registrations.get(0);
            }
        }
        
        Answer__c answer = new Answer__c(
            fr_Id__c = funraiseId,
            Answer__c = frUtil.truncateToFieldLength(
                Answer__c.Answer__c.getDescribe(), 
                String.valueOf(request.get('answer'))
            ),
            Question__c = questions.get(0).Id,
            Campaign_Page__c = page != null ? page.Id : null,
            Registration__c = registration != null ? registration.Id : null
        );
        

        if(frUtil.hasNPCobjects()) {
            answer.put('Supporter_PA__c', supporter?.Id);
            answer.put('Gift_Transaction_Id__c', trsact?.Id);
        } else {
            answer.Supporter__c = supporter?.Id;
            answer.Transaction__c = trsact?.Id;
        }
        
        try {
            Database.upsert(answer, Answer__c.Field.fr_ID__c, true);
            result = true;
        } catch (DMLException ex) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, ex);
        }   
        return result;
    }
    
    protected override Boolean requireObjectDeletePermission() {
        return true;
    }
    
    protected override Set<Schema.SObjectField> getFields() {
        return new Set<Schema.SObjectField> {
                    Answer__c.fr_Id__c,
                    Answer__c.Answer__c,
                    Answer__c.Question__c,
                    Answer__c.Supporter__c,
                    Answer__c.Transaction__c,
                    Answer__c.Campaign_Page__c,
                    Answer__c.Registration__c
        };
    }
    
    protected override Set<Schema.SObjectType> getObjects() {
        return new Set<Schema.SObjectType> {
            	Answer__c.SObjectType
        };
    }
    
    protected override frUtil.Entity getFrType() {
        return frUtil.Entity.ANSWER;
    }
}