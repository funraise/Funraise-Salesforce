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
* CREATED: 2021 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/

public class frTask extends frModel implements frSyncable {   
    public frTask(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = 
            (Map<String, Object>)JSON.deserializeUntyped(syncRecord.Request_Body__c);
       
        String frTaskId = String.valueOf(request.get('id'));
        
        Boolean isDeleted = Boolean.valueOf(request.get('deleted'));
        if(isDeleted){
            delete [SELECT Id FROM Task WHERE fr_Task_ID__c = :frTaskId];
            result = true;
            return result;
        }
        
        String donorId = String.valueOf(request.get('donorId'));
        List<Contact> contacts = (List<Contact>)Database.query('select Id, fr_ID__c from Contact where fr_ID__c = :donorId');
        if(contacts.isEmpty()){
            if(createLogRecord) frUtil.logRelationshipError(frUtil.Entity.TASK, frTaskId, 
                                        frUtil.Entity.SUPPORTER, donorId);
            return result;
        }

        
        Task sfTask = new Task(fr_Task_Id__c = frTaskId, Priority = 'Normal', WhoId = contacts.get(0).Id);
        
        String donationId = String.valueOf(request.get('donationId'));
        if(donationId != null){ 
            List<Opportunity> opportunities = [SELECT Id, fr_Id__c FROM Opportunity WHERE fr_Id__c = :donationId];            
            if(!opportunities.isEmpty()){
                sfTask.WhatId = opportunities.get(0).Id;
            } else {
                if(createLogRecord) frUtil.logRelationshipError(frUtil.Entity.TASK, frTaskId, 
                                            frUtil.Entity.DONATION, donationId);
            }
        }

        String actionRequired = String.valueOf(request.get('actionRequired'));
        sfTask.Subject = actionRequired;
        
        String frType = String.valueOf(request.get('taskType'));
        if(String.isBlank(sfTask.Subject)) {
            sfTask.Subject = frType;
        }
        
        sfTask.Description = String.valueOf(request.get('description'));
        sfTask.ActivityDate = DateTime.newInstance((Long)request.get('createdDate')).dateGMT();
        
        String frStatus = String.valueOf(request.get('status'));
        if(frStatus == 'Complete' || frType == 'Interaction'){
            sfTask.Status = 'Completed';
            sfTask.ActivityDate = DateTime.newInstance((Long)request.get('completedDate')).dateGMT();
        } else if(frStatus == 'Pending' || frStatus == 'Canceled'){
            sfTask.Status = 'Not Started';
        }
        
        try {
            upsert sfTask Task.Fields.fr_Task_ID__c;
            result = true;
        } catch (DMLException ex) {
            if(createLogRecord) frUtil.logException(frUtil.Entity.TASK, frTaskId, ex);
        }
        return result;
    }
}