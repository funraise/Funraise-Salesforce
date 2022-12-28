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
* PURPOSE:  A class for representing a Funraise pledge.  Used for creating & matching to pledges
*
*
*
* CREATED: 2020 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/
public with sharing class frPledge {
    public static Pledge__c findActive(Id contactId, Date closeDate) {
        List<Pledge__c> possiblePledges = [SELECT Id FROM Pledge__c 
                                         WHERE Supporter__c = :contactId 
                                         AND (Start_Date__c = null OR Start_Date__c <= :closeDate)
                                         AND (End_Date__c = null OR End_Date__c >= :closeDate)
                                         AND Percent_Complete__c < 100
                                         AND Pledge_Donation__c = null
                                         ORDER BY CreatedDate ASC LIMIT 1
                                        ];
        return possiblePledges.size() > 0 ? possiblePledges.get(0) : null;
    }
    
    public static Pledge__c create(Opportunity opp) {
        Pledge__c pledge = new Pledge__c(
            Name = frUtil.truncateToFieldLength(Pledge__c.Name.getDescribe(), opp.Name + ' Pledge'),
            Supporter__c = opp.fr_Donor__c,
            Pledge_Amount__c = opp.Amount,
            Pledge_Donation__c = opp.Id,
            Pledge_Donation_uq__c = opp.Id
        );

        try {
            Database.upsert(pledge, Pledge__c.Fields.Pledge_Donation_uq__c, true);
            opp.Funraise_Pledge__c = pledge.Id;
            update opp;
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.PLEDGE, opp.fr_Id__c, ex);
        }
        
        return pledge;
    }
    
    public static Pledge__c create(Subscription__c subscription, Decimal pledgeAmount) {
        Pledge__c pledge = new Pledge__c(
            Name = frUtil.truncateToFieldLength(Pledge__c.Name.getDescribe(), 'Subscription Pledge - ' + subscription.Name),
            Supporter__c = subscription.Supporter__c,
            Pledge_Amount__c = pledgeAmount,
            Pledge_Subscription__c = subscription.Id,
            Pledge_Subscription_uq__c = subscription.Id
        );
        try {
            Database.upsert(pledge, Pledge__c.Pledge_Subscription_uq__c , true);
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.PLEDGE, subscription.fr_Id__c, ex);
        }
        
        return pledge;
    }
}