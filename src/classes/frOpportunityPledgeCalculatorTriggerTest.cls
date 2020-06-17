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
 * PURPOSE:  A test class for frOpportunityPledgeCalculator
 *
 *
 *
 * CREATED: 2020 Funraise Inc - https://funraise.io
 * AUTHOR: Alex Molina
 */
@IsTest
public class frOpportunityPledgeCalculatorTriggerTest {
    static testMethod void newOpp_withPledge() {  
        Contact supporter = frDonorTest.getTestContact();
        insert supporter;
        Pledge__c pledge = createPledge(supporter);
        insert pledge;
        
        Opportunity opp = createClosedOpportunity(supporter, pledge, 100);
        
        Test.startTest();
        insert opp;
        Test.stopTest();
        
        pledge = [SELECT Id, Received_Amount__c FROM Pledge__c WHERE Id = :pledge.Id];
        System.assertEquals(opp.Amount, pledge.Received_Amount__c, 'The pledge received amount should have been the opp amount');
    }
    
    static testMethod void existingOpp_withNewPledge() {  
        Contact supporter = frDonorTest.getTestContact();
        insert supporter;
        Pledge__c pledge = createPledge(supporter);
        insert pledge;
        
        Opportunity opp = createClosedOpportunity(supporter, null, 100);
        insert opp;
            
        Test.startTest();
        Decimal pledgeAmountBefore = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :pledge.Id].Received_Amount__c;
        opp.Funraise_Pledge__c = pledge.Id;
        update opp;
        Decimal pledgeAmountAfter = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :pledge.Id].Received_Amount__c;
        Test.stopTest();
        
        System.assertEquals(null, pledgeAmountBefore, 'The pledge received amount should have been null since there were no opps associated');
        System.assertEquals(opp.Amount, pledgeAmountAfter, 'The pledge received amount should have been the amount of the opp that was updated to reference it');
    }
    
    static testMethod void existingOpp_withNewAndOldPledge() {  
        Contact supporter = frDonorTest.getTestContact();
        insert supporter;
        Pledge__c oldPledge = createPledge(supporter);
        Pledge__c newPledge = createPledge(supporter);
        insert new List<Pledge__c>{newPledge, oldPledge};
        
        Opportunity opp = createClosedOpportunity(supporter, oldPledge, 100);
        insert opp;
            
        Test.startTest();
        Decimal oldPledgeAmountBefore = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :oldPledge.Id].Received_Amount__c;
        Decimal newPledgeAmountBefore = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :newPledge.Id].Received_Amount__c;
        opp.Funraise_Pledge__c = newPledge.Id;
        update opp;
        Decimal oppOriginalAmount = opp.Amount;
        opp.Amount = opp.Amount + 1;
        update opp;
        Decimal oldPledgeAmountAfter = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :oldPledge.Id].Received_Amount__c;
        Decimal newPledgeAmountAfter = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :newPledge.Id].Received_Amount__c;
        Test.stopTest();
        
        System.assertEquals(oppOriginalAmount, oldPledgeAmountBefore, 'The old pledge received amount should have been the amount of the opp that was originally to reference it');
        System.assertEquals(null, newPledgeAmountBefore, 'The pledge received amount should have been null since there were no opps associated');
        System.assertEquals(0, oldPledgeAmountAfter, 'The old pledge received amount should have been 0 since no opportunites are referencing it now');
        System.assertEquals(opp.Amount, newPledgeAmountAfter, 'The new pledge received amount should have been the amount of the opp that was updated to reference it');
    }
    
    static testMethod void existingOpp_delete() {  
        Contact supporter = frDonorTest.getTestContact();
        insert supporter;
        Pledge__c pledge = createPledge(supporter);
        insert pledge;
        
        Opportunity opp = createClosedOpportunity(supporter, pledge, 100);
        insert opp;
            
        Test.startTest();
        Decimal pledgeAmountBefore = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :pledge.Id].Received_Amount__c;
        delete opp;
        Decimal pledgeAmountAfter = [SELECT Received_Amount__c FROM Pledge__c WHERE Id = :pledge.Id].Received_Amount__c;
        Test.stopTest();
        
        System.assertEquals(opp.Amount, pledgeAmountBefore, 'The pledge received amount should have been the opp amount that is associated');
        System.assertEquals(0, pledgeAmountAfter, 'The pledge received amount should have been 0 since the only oppo fulfilling it was deleted');
    }
    
    static Opportunity createClosedOpportunity(Contact supporter, Pledge__c pledge, Decimal amount) {
		Opportunity opp = frDonationTest.getTestOpp();
        OpportunityStage closedWonOppStage = [SELECT Id, ApiName FROM 
                                              OpportunityStage WHERE IsWon = true AND IsClosed = true
                                              AND IsActive = true];
        opp.StageName = closedWonOppStage.ApiName;
        opp.fr_Donor__c = supporter.Id;
        opp.Funraise_Pledge__c = pledge != null ? pledge.Id : null;
        opp.Amount = amount;
        return opp;
    }
    
    static Pledge__c createPledge(Contact supporter) {
        return new Pledge__c(
        	Name = 'Unit Test Pledge',
            Supporter__c = supporter.Id,
            Pledge_Amount__c = 100
        );
    }
}