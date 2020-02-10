/*
*
*  Copyright (c) 2019, Funraise Inc
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

public class frFundraisingEventRegistration {    
    public frFundraisingEventRegistration(Map<String, Object> request) {
        if (Boolean.valueOf(request.get('deleted'))) {
            deleteRegistration(String.valueOf(request.get('id')));
        } else {
            create(request);
        }
    }
    
    public void deleteRegistration(String funraiseId) {
        try {
            delete [SELECT id FROM Fundraising_Event_Registration__c WHERE fr_ID__c = :funraiseId];
        } catch (DMLException e) {
            frUtil.logException(frUtil.Entity.REGISTRATION, funraiseId, e);
        }
    }
    
    public void create(Map<String, Object> request) {
        String funraiseId = String.valueOf(request.get('id'));
        String funraiseEventId = String.valueOf(request.get('eventId'));
        List<Fundraising_Event__c> event = [SELECT Id from Fundraising_Event__c WHERE fr_Id__c = :funraiseEventId];
        if(event.isEmpty()) {
            frUtil.logRelationshipError(frUtil.Entity.REGISTRATION, funraiseId, 
                                        frUtil.Entity.EVENT, funraiseEventId);
            return;
        }
        
        String funraiseSupporterId = String.valueOf(request.get('supporterId'));
        List<Contact> supporter = [SELECT Id from Contact WHERE fr_Id__c = :funraiseSupporterId];
        if(supporter.isEmpty()) {
            frUtil.logRelationshipError(frUtil.Entity.REGISTRATION, funraiseId, 
                                        frUtil.Entity.SUPPORTER, funraiseSupporterId,
                                       'Registration supporter, not guest of');
            return;
        }
        String funraiseGuestOfId = String.valueOf(request.get('guestOfId'));
        List<Contact> guestOf = [SELECT Id from Contact WHERE fr_Id__c = :funraiseGuestOfId];
        if(guestOf.isEmpty() && String.isNotBlank(funraiseGuestOfId)) {
            //if it wasn't found, log an error but continue
            frUtil.logRelationshipError(frUtil.Entity.REGISTRATION, funraiseId, 
                                        frUtil.Entity.SUPPORTER, funraiseSupporterId,
                                        'Registration guest of, not supporter');
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
            Supporter__c = supporter.get(0).Id,
            Guest_Of__c = guestOf.isEmpty() ?  null : guestOf.get(0).Id
        );
        
        try {
            Database.upsert(registration, Fundraising_Event_Registration__c.Field.fr_ID__c, true);
        } catch (DMLException ex) {
            frUtil.logException(frUtil.Entity.REGISTRATION, funraiseId, ex);
            return;
        }
    }
}