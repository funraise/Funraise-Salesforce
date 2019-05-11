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

public class frFundraisingEvent {    
    public frFundraisingEvent(Map<String, Object> request) {
        if (Boolean.valueOf(request.get('deleted'))) {
            deleteEvent(String.valueOf(request.get('id')));
        } else {
            create(request);
        }
    }
    
    public void deleteEvent(String funraiseId) {
        try {
            delete [SELECT id FROM Fundraising_Event__c WHERE fr_ID__c = :funraiseId];
        } catch (DMLException e) {
            insert new Error__c(Error__c =
                                'Failed to delete funraise event for event id ' + funraiseId +
                                '. Exception: ' + e.getMessage());
        }
    }
    
    public void create(Map<String, Object> request) {
        String funraiseId = String.valueOf(request.get('id'));
        Fundraising_Event__c event = new Fundraising_Event__c(
        	fr_ID__c = funraiseId,
            Name = truncateToFieldLength(Fundraising_Event__c.Name.getDescribe(), String.valueOf(request.get('name'))), 
            Description__c = truncateToFieldLength(Fundraising_Event__c.Description__c.getDescribe(), String.valueOf(request.get('description'))), 
            Start_Date__c = convertFromLocalDate((List<Object>)request.get('eventStartDate'), funraiseId),
            End_Date__c = convertFromLocalDate((List<Object>)request.get('eventEndDate'), funraiseId)
        );

        
        try {
            Database.upsert(event, Fundraising_Event__c.Field.fr_ID__c, true);
        } catch (DMLException e) {
            insert new Error__c(Error__c =
                                'Failed to insert funraise event for event id ' + funraiseId +
                                '. Exception: ' + e.getMessage());
            return;
        }
    }
    
    private static String truncateToFieldLength(DescribeFieldResult describe, String value) { 
        return String.isNotBlank(value) && value.length() > describe.getLength() ? 
        value.substring(0, describe.getLength()) 
        : value;
    }
    
    private static DateTime convertFromLocalDate(List<Object> localDate, String recordId) {
        if(localDate != null && localDate.size() == 5) {
            try {
                return DateTime.newInstance(
                    (Integer)localDate.get(0), //year
                    (Integer)localDate.get(1), //month
                    (Integer)localDate.get(2), //day
                    (Integer)localDate.get(3), //hour
                    (Integer)localDate.get(4), //minute
                    0 				  //second
                );
            } catch (Exception ex) {
                insert new Error__c(Error__c =
                                    'Could not parse event date.  Event created without this data. Event Id: ' + recordId +
                                    '. Exception: ' + ex.getMessage());
            }
        }
        return null;
    }
}