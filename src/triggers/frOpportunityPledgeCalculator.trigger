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
 * PURPOSE:  A trigger on opportunity to update pledges they are related to with a pledge total
 *
 *
 *
 * CREATED: 2020 Funraise Inc - https://funraise.io
 * AUTHOR: Alex Molina
 */
trigger frOpportunityPledgeCalculator on Opportunity (after insert, after update, after delete) {
    Set<Id> pledgeIds = new Set<Id>();
    if(Trigger.isInsert) {
    	for(Opportunity opp : Trigger.new) {
            if(opp.Funraise_Pledge__c != null) {
                pledgeIds.add(opp.Funraise_Pledge__c);
            }
        }
    } else if (Trigger.IsUpdate) {
        //only calculate if any of the values we care about changed here
        for(Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            if(opp.Funraise_Pledge__c != oldOpp.Funraise_Pledge__c) {
                if(opp.Funraise_Pledge__c != null) {
                    pledgeIds.add(opp.Funraise_Pledge__c);                    
                }
                if(oldOpp.Funraise_Pledge__c != null) {
                    pledgeIds.add(oldOpp.Funraise_Pledge__c);
                }
            } else if (opp.Funraise_Pledge__c != null && 
                       (opp.Amount != oldOpp.Amount || opp.StageName != oldOpp.StageName)) {
                pledgeIds.add(opp.Funraise_Pledge__c);
            }

        }
        
    } else if (Trigger.isDelete) {
        for(Opportunity opp : Trigger.old) {
            if(opp.Funraise_Pledge__c != null) {
                pledgeIds.add(opp.Funraise_Pledge__c);
            }
        }
        
    }

    if(pledgeIds.size() > 0) {
		List<OpportunityStage> closedWonOppStages = [SELECT Id, ApiName FROM OpportunityStage WHERE IsWon = true AND IsClosed = true];
        Set<String> closedWonOppStageApiNames = new Set<String>();
        for(OpportunityStage oppStage : closedWonOppStages) {
            closedWonOppStageApiNames.add(oppStage.ApiName);
        }
        
        AggregateResult[] pledgeAggregates = [SELECT funraise__Funraise_Pledge__c, SUM(amount)amt FROM Opportunity 
                                              WHERE amount != null 
                                              AND StageName IN :closedWonOppStageApiNames
                                              AND Funraise_Pledge__c IN :pledgeIds
                                              GROUP BY Funraise_Pledge__c];
		Map<Id, Decimal> pledgeIdToTotal = new Map<Id, Decimal>();
        for(AggregateResult aggRes : pledgeAggregates) {
        	pledgeIdToTotal.put(
                (Id)aggRes.get('funraise__Funraise_Pledge__c'),
                (Decimal)aggRes.get('amt')
            );
        }
        
        List<Pledge__c> pledgesToUpdate = new List<Pledge__c>();
        for(Id pledgeId : pledgeIds) {
            Pledge__c pledge = new Pledge__c(
            	Id = pledgeId,
                Received_Amount__c = pledgeIdToTotal.containsKey(pledgeId) ? pledgeIdToTotal.get(pledgeId) : 0
            );
            pledgesToUpdate.add(pledge);
        }
        update pledgesToUpdate;
    }
    
}