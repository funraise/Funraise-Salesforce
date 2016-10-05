/*
 *
 *  Copyright (c) 2016, Funraise Inc
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
 * CREATED: 2016 Funraise Inc - https://funraise.io
 * AUTHOR: Alex Molina
 */
@isTest
public class frDonationTest {
    static testMethod void toOpportunity_test() {
        Contact testContact = new Contact(FirstName = 'Bruce', LastName = 'Wayne', 
            Email = 'bruce.wayne@wayne.example.com');
        insert testContact;

        Long currentMillis = Datetime.now().getTime();

        Test.startTest();
        frDonation donation = new frDonation();
        donation.setDonorId('15642');
        donation.setAmount(20);
        donation.setCretime(currentMillis);
        donation.setName('Bruce Wayne - Funraise 2010-06-01 00:00:00-07');
        donation.setAnonymous(false);
        donation.setStatus('Complete');
        donation.setId('20642');
        donation.setSfDonorId(testContact.Id);
        donation.save();
        Test.stopTest();

        Opportunity newOpportunity = [
            SELECT Name, Amount, CloseDate, IsPrivate, StageName, 
                Probability, fr_Funraise_Donor__c, fr_Funraise_ID__c
            FROM Opportunity WHERE Id = :donation.getOpportunityId()
        ];

        System.assertEquals(donation.getSfDonorId(), newOpportunity.fr_Funraise_Donor__c, 
            'The sf donor id was not set to the opportunity fr_Funraise_Donor__c field as expected');
        System.assertEquals(donation.getAmount(), newOpportunity.Amount, 
            'The donation amount was not set to the opportunity Amount field as expected'); 
        System.assertEquals(Datetime.newInstance(donation.getCretime()).date(), newOpportunity.CloseDate, 
            'The donation cretime was not set to the opportunity CloseDate field as expected'); 
        System.assertEquals(donation.getAnonymous(), newOpportunity.IsPrivate, 
            'The donation anonymous flag was not set to the opportunity IsPrivate field as expected');  
        System.assertEquals('Closed Won', newOpportunity.StageName, 
            'The donation being completed was not set to the opportunity StageName field as expected'); 
        System.assertEquals('15642', donation.getDonorId(), 
            'The donation\'s donor Id was not set to the value that was passed in as expected');
        System.assertEquals('Complete', donation.getStatus(), 
            'The donation\'s status was not set to the value that was passed in as expected');
        System.assertEquals(donation.getName(), newOpportunity.Name, 
            'The donation\'s name was not set to the opportunity Name field as expected');  
        System.assertEquals(donation.getId(), newOpportunity.fr_Funraise_ID__c, 
            'The donation\'s Id was not set to the opportunity fr_Funraise_ID__c field as expected');   

    }
}