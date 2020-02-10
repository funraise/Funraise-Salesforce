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
* CREATED: 9-18-2018 Funraise Inc - https://funraise.io
* AUTHOR: Mark D. Dufresne
*/

@RestResource(urlMapping='/v1/task')
global with sharing class frWSTaskController {
    
    @HttpPost
    global static void syncEntity() {
        Map<String, Object> frTask = (Map<String, Object>)JSON.deserializeUntyped(
            RestContext.request.requestBody.toString()
        );
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        
        String frTaskId = String.valueOf(frTask.get('id'));
        String donorId = String.valueOf(frTask.get('donorId'));
        List<Contact> contacts = (List<Contact>)Database.query('select Id, fr_ID__c from Contact where fr_ID__c = :donorId');
        if(contacts.isEmpty()){
            frUtil.logRelationshipError(frUtil.Entity.TASK, frTaskId, 
                                        frUtil.Entity.SUPPORTER, donorId);
            return;
        }
        
        Contact contact = contacts.get(0);
        
        List<Task> existingSfTasks = (List<Task>)Database.query('select Id, fr_Task_ID__c from Task where fr_Task_ID__c = :frTaskId');
        
        Task sfTask;
        
        String frType = (String)frTask.get('taskType');
        
        if(existingSfTasks.isEmpty()){
            sfTask = new Task();
            sfTask.Priority = 'Normal';
        } else {
            sfTask = existingSfTasks.get(0);
        }
        
        Object isDeleted = frTask.get('deleted');
        if(isDeleted != null && Boolean.valueOf(isDeleted)){
            delete existingSfTasks;
            setResponse('', true);
            return;
        }
        
        sfTask.WhoId = contact.Id;
        
        String donationId = '';
        if(frTask.containsKey('donationId') && frTask.get('donationId') != null){
            donationId = String.valueOf(frTask.get('donationId'));
        }
        
        List<Opportunity> opportunities = new List<Opportunity>();
        if(donationId.length() > 0){
            opportunities = (List<Opportunity>)Database.query('select Id, fr_ID__c from Opportunity where fr_ID__c = :donationId');
        }
        
        if(!opportunities.isEmpty()){
            sfTask.WhatId = opportunities.get(0).Id;
        }
        
        sfTask.put('fr_Task_ID__c', frTaskId);
        
        if(frTask.containsKey('actionRequired')){
            String actionRequired = (String)frTask.get('actionRequired');
            if(actionRequired != null && actionRequired.trim().length() > 0){
                sfTask.Subject = actionRequired;
            }
        }
        
        if(sfTask.Subject == null || sfTask.Subject.length() == 0){
            sfTask.Subject = frType;
        }
        
        sfTask.Description = (String)frTask.get('description');
        sfTask.ActivityDate = DateTime.newInstance((Long)frTask.get('createdDate')).dateGMT();
        
        String frStatus = (String)frTask.get('status');
        if(frStatus == 'Complete' || frType == 'Interaction'){
            sfTask.Status = 'Completed';
            sfTask.ActivityDate = DateTime.newInstance((Long)frTask.get('completedDate')).dateGMT();
        } else if(frStatus == 'Pending' || frStatus == 'Canceled'){
            sfTask.Status = 'Not Started';
        }
        
        try {
            upsert sfTask Task.Fields.fr_Task_ID__c;
        } catch (DMLException ex) {
            frUtil.logException(frUtil.Entity.TASK, frTaskId, ex);
            setResponse(ex.getMessage(), false);
            return;
        }
        
        setResponse('', true);
    }
    
    private static void setResponse(String message, Boolean success){
        Map<String,Object> resp = new Map<String,Object>();
        resp.put('success', success);
        resp.put('message', message);
        
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
    }
}