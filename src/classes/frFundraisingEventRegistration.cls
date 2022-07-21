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

public class frFundraisingEventRegistration extends frModel implements frSyncable {    
    
    public frFundraisingEventRegistration(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = getRequestBody();
        if (Boolean.valueOf(request.get('deleted'))) {
            result = deleteRegistration(getFunraiseId());
        } else {
            result = create(request);
        }
        return result;
    }
    
    private Boolean deleteRegistration(String funraiseId) {
        Boolean result = false;
        try {
            delete [SELECT id FROM Fundraising_Event_Registration__c WHERE fr_ID__c = :funraiseId];
            result = true;
        } catch (DMLException e) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, e);
        }
        return result;
    }
    
    private Boolean create(Map<String, Object> request) {
        Boolean result = false;
        String funraiseId = getFunraiseId();
        String funraiseEventId = String.valueOf(request.get('eventId'));
        List<Fundraising_Event__c> event = [SELECT Id from Fundraising_Event__c WHERE fr_Id__c = :funraiseEventId];
        if(event.isEmpty()) {
            if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                        frUtil.Entity.EVENT, funraiseEventId);
            return result;
        }
        
        String funraiseSupporterId = String.valueOf(request.get('supporterId'));
        List<Contact> supporter = new List<Contact>();
        if(String.isNotBlank(funraiseSupporterId)) {
            supporter = [SELECT Id from Contact WHERE fr_Id__c = :funraiseSupporterId];
            if(supporter.isEmpty()) {
                //if it wasn't found, log an error but continue
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.SUPPORTER, funraiseSupporterId,
                                            'Registration registrant');
            }
        }
        
        String funraiseGuestOfId = String.valueOf(request.get('guestOfId'));
        List<Contact> guestOf = new List<Contact>();
        if(String.isNotBlank(funraiseGuestOfId)) {
            guestOf = [SELECT Id from Contact WHERE fr_Id__c = :funraiseGuestOfId];
            if(guestOf.isEmpty()) {
                //if it wasn't found, log an error but continue
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.SUPPORTER, funraiseSupporterId,
                                            'Registration guest of');
                
            }
        }
        
        String funraiseTransactionId = String.valueOf(request.get('transactionId'));
        List<Opportunity> transactions = new List<Opportunity>();
        if(String.isNotBlank(funraiseTransactionId)) {
            transactions = [SELECT Id FROM Opportunity WHERE fr_Id__c = :funraiseTransactionId];
            if(transactions.isEmpty()) {
                //if it wasn't found, log an error but continue
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId, 
                                            frUtil.Entity.DONATION, funraiseTransactionId);                
            }
        }

    
        Fundraising_Event_Registration__c registration = new Fundraising_Event_Registration__c(
        	fr_ID__c = funraiseId,
            Name = frUtil.truncateToFieldLength(
                Fundraising_Event_Registration__c.Name.getDescribe(), 
                String.valueOf(request.get('name'))
            ), 
            Ticket_Name__c = frUtil.truncateToFieldLength(
                Fundraising_Event_Registration__c.Ticket_Name__c.getDescribe(), 
                String.valueOf(request.get('ticketName'))
            ),
            Attended__c = Boolean.valueOf(request.get('attended')),
            Fundraising_Event__c = event.get(0).Id,
            Registrant__c = supporter.isEmpty() ?  null : supporter.get(0).Id,
            Guest_Of__c = guestOf.isEmpty() ?  null : guestOf.get(0).Id,
            Transaction__c = transactions.isEmpty() ? null : transactions.get(0).Id,
            First_Name__c = frUtil.truncateToFieldLength(
                Fundraising_Event_Registration__c.First_Name__c.getDescribe(), 
                String.valueOf(request.get('firstName'))
            ),
            Last_Name__c = frUtil.truncateToFieldLength(
                Fundraising_Event_Registration__c.Last_Name__c.getDescribe(), 
                String.valueOf(request.get('lastName'))
            ),
            Phone__c = frUtil.truncateToFieldLength(
                Fundraising_Event_Registration__c.Phone__c.getDescribe(), 
                String.valueOf(request.get('phone'))
            ),
            Email__c = frUtil.truncateToFieldLength(
                Fundraising_Event_Registration__c.Email__c.getDescribe(), 
                String.valueOf(request.get('email'))
            )
        );
        frModel.write(
            registration, 
            Fundraising_Event_Registration__c.Ticket_Amount__c, 
            'Ticket_Amount__c',
            request.get('ticketAmount'),
            funraiseId
        );
        frModel.write(
            registration, 
            Fundraising_Event_Registration__c.Ticket_Tax_Deductible_Amount__c, 
            'Ticket_Tax_Deductible_Amount__c',
            request.get('ticketTaxDeductibleAmount'),
            funraiseId
        );
        
        try {
            Database.upsert(registration, Fundraising_Event_Registration__c.Field.fr_ID__c, true);
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
            	Fundraising_Event_Registration__c.fr_ID__c,
                Fundraising_Event_Registration__c.Name,
                Fundraising_Event_Registration__c.Ticket_Name__c,
                Fundraising_Event_Registration__c.Attended__c,
                Fundraising_Event_Registration__c.Fundraising_Event__c,
                Fundraising_Event_Registration__c.Registrant__c,
                Fundraising_Event_Registration__c.Guest_Of__c,
                Fundraising_Event_Registration__c.Transaction__c,
                Fundraising_Event_Registration__c.First_Name__c,
                Fundraising_Event_Registration__c.Last_Name__c,
                Fundraising_Event_Registration__c.Phone__c,
                Fundraising_Event_Registration__c.Email__c,
                Fundraising_Event_Registration__c.Ticket_Amount__c,
                Fundraising_Event_Registration__c.Ticket_Tax_Deductible_Amount__c
        };
    }
    
    protected override Set<Schema.SObjectType> getObjects() {
        return new Set<Schema.SObjectType> {
            Fundraising_Event_Registration__c.SObjectType
        };
    }
    
    protected override frUtil.Entity getFrType() {
        return frUtil.Entity.REGISTRATION;
    }
}