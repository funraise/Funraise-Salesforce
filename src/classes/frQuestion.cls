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

public class frQuestion {
    public static final Map<String, Schema.SObjectField> fields = 
        frSchemaUtil.getFields(Question__c.getSObjectType().getDescribe().getName());
    
    public frQuestion(Map<String, Object> request) {
        if (Boolean.valueOf(request.get('deleted'))) {
            deleteQuestion(String.valueOf(request.get('id')));
        } else {
            create(request);
        }
    }
    
    public void deleteQuestion(String funraiseId) {
        try {
            delete [SELECT id FROM Question__c WHERE fr_ID__c = :funraiseId];
        } catch (DMLException e) {
            frUtil.logException(frUtil.Entity.SUBSCRIPTION, funraiseId, e);
        }
    }
    
    public void create(Map<String, Object> request) {
        String funraiseId = String.valueOf(request.get('id'));
		Question__c question = new Question__c(
			fr_Id__c = funraiseId,
            Name__c = frUtil.truncateToFieldLength(
                Question__c.Name__c.getDescribe(), 
                String.valueOf(request.get('name'))
            ),
            Description__c = frUtil.truncateToFieldLength(
                Question__c.Description__c.getDescribe(), 
                String.valueOf(request.get('description'))
            ),
            Type__c = frUtil.truncateToFieldLength(
                Question__c.Type__c.getDescribe(), 
                String.valueOf(request.get('questionType'))
            )
        );
        
        try {
            Database.upsert(question, Question__c.Field.fr_ID__c, true);
        } catch (DMLException ex) {
            frUtil.logException(frUtil.Entity.QUESTION, funraiseId, ex);
            return;
        }
    } 
}