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
* PURPOSE: Test class for migration class used for post-package-install execution
*
*
* CREATED: 2020 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/
@isTest
public class frDataMigrationTest {
    @isTest
    static void testRegistrationLookupMigration() {
        Fundraising_Event__c testEvent = frFundraisingEventTest.getTestEvent();
        insert testEvent;
        
        Contact testSupporter = frDonorTest.getTestContact();
        insert testSupporter;
        
        Fundraising_Event_Registration__c registration = new Fundraising_Event_Registration__c(
            Attended__c = false,
            Fundraising_Event__c = testEvent.Id,
            fr_Id__c = '1234',
            Guest_Of__c = testSupporter.Id,
            Supporter__c = testSupporter.Id,
            Ticket_Name__c = 'Test Ticket'
        );
        insert registration;
        
        Test.startTest();
        new frDataMigration().onInstall(null);
        Test.stopTest();
        
        Fundraising_Event_Registration__c requeryRegistration = [SELECT Id, Registrant__c FROM Fundraising_Event_Registration__c
                                                                WHERE Id = :registration.Id];
        System.assertEquals(registration.Supporter__c, requeryRegistration.Registrant__c, 'The contact id from the master-detail relationship was not copied properly to the lookup field');
        
    }
}