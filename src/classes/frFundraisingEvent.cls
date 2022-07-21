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

public class frFundraisingEvent extends frModel implements frSyncable {    
    
    public frFundraisingEvent(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = (Map<String, Object>)JSON.deserializeUntyped(syncRecord.Request_Body__c);
        if (Boolean.valueOf(request.get('deleted'))) {
            result = deleteEvent(String.valueOf(request.get('id')));
        } else {
            result = create(request);
        }
        return result;
    }
    
    private boolean deleteEvent(String funraiseId) {
        Boolean result = false;
        try {
            delete [SELECT id FROM Fundraising_Event__c WHERE fr_ID__c = :funraiseId];
            result = true;
        } catch (DMLException e) {
            if (createLogRecord) frUtil.logException(frUtil.Entity.EVENT, funraiseId, e);
        }
        return result;
    }
    
    private boolean create(Map<String, Object> request) {
        Boolean result = false;
        String funraiseId = String.valueOf(request.get('id'));
        Fundraising_Event__c event = new Fundraising_Event__c(
        	fr_ID__c = funraiseId,
            Name = frUtil.truncateToFieldLength(Fundraising_Event__c.Name.getDescribe(), String.valueOf(request.get('name'))), 
            Description__c = frUtil.truncateToFieldLength(Fundraising_Event__c.Description__c.getDescribe(), String.valueOf(request.get('description'))), 
            Start_Date__c = convertFromLocalDateTime((List<Object>)request.get('eventStartDate'), funraiseId),
            End_Date__c = convertFromLocalDateTime((List<Object>)request.get('eventEndDate'), funraiseId)
        );

        try {
            Database.upsert(event, Fundraising_Event__c.Field.fr_ID__c, true);
            result = true;
        } catch (DMLException e) {
            if (createLogRecord) frUtil.logException(frUtil.Entity.EVENT, funraiseId, e);
        }
        return result;
    }
    
    private static DateTime convertFromLocalDateTime(List<Object> localDate, String recordId) {
        if(localDate != null && localDate.size() == 5) {
            try {
                return frModel.convertFromLocalDateTime(localDate);
            } catch (Exception ex) {
                frUtil.logError(frUtil.Entity.EVENT, recordId, 'Could not parse event date.  Event created without this data');
            }
        }
        return null;
    }
}