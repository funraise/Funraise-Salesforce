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
public class frPledge extends frModel implements frSyncable {

    public frPledge(Sync_Attempt__c syncRecord) {
        super(syncRecord);
    }

    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = getRequestBody();
        if (Boolean.valueOf(request.get('deleted'))) {
            result = deletePledge(request);
        } else {
            result = create(request);
        }
        return result;
    }

    protected override Set<SObjectField> getFields() {
        return new Set<Schema.SObjectField> {
                Pledge__c.Name,
                Pledge__c.End_Date__c,
                Pledge__c.Start_Date__c,
                Pledge__c.Pledge_Amount__c,
                Pledge__c.Received_Amount__c,
                Pledge__c.fr_Id__c,
                Pledge__c.Campaign_Page__c,
                Pledge__c.Pledge_Subscription__c
        };
    }

    protected override Set<SObjectType> getObjects() {
        return new Set<Schema.SObjectType> {
                Pledge__c.SObjectType
        };
    }

    protected override frUtil.Entity getFrType() {
        return frUtil.Entity.PLEDGE;
    }

    protected override String getFunraiseId() {
        return String.valueOf(getRequestBody().get('commitmentId'));
    }

    private Boolean create(Map<String, Object> request) {
        Boolean result = false;
        String commitmentId = getFunraiseId();
        String pledgeAmount = String.valueOf(request.get('amount'));
        String pledgeTotalAmount = String.valueOf(request.get('totalDonationAmount'));

        Pledge__c pledge = new Pledge__c(
                Name = frUtil.truncateToFieldLength(Pledge__c.Name.getDescribe(), 'Commitment - ' + String.valueOf(request.get('name'))),
                Pledge_Amount__c = String.isNotBlank(pledgeAmount) ? Decimal.valueOf(pledgeAmount) : null,
                Received_Amount__c = String.isNotBlank(pledgeTotalAmount) ? Decimal.valueOf(pledgeTotalAmount) : 0,
                fr_Id__c = commitmentId,
                End_Date__c = convertFromLocalDate((List<Object>) request.get('collectDate'))
        );

        SObject supporter = null;
        String funraiseSupporterId = String.valueOf(request.get('supporterId'));
        if(String.isNotBlank(funraiseSupporterId)) {
            List<SObject> supporters;
            if (frUtil.hasNPCobjects()) {
                supporters = [SELECT Id FROM Account WHERE fr_Id__c = :funraiseSupporterId];
            } else {
                supporters = [SELECT Id, AccountId FROM Contact WHERE fr_Id__c = :funraiseSupporterId];
            }
            if(supporters.isEmpty() && createLogRecord) {
                frUtil.logRelationshipError(getFrType(), commitmentId, frUtil.Entity.SUPPORTER, funraiseSupporterId);
            } else if (!supporters.isEmpty()) {
                supporter = supporters.get(0);
            }
        }

        if(frUtil.hasNPCobjects()) {
            pledge.put('Supporter_PA__c', supporter?.Id);
        } else {
            pledge.Supporter__c = supporter?.Id;
        }

        //connect campaign
        String campaignId = String.valueOf(request.get('goalId'));
        if (String.isNotBlank(campaignId)) {
            List<Campaign> campaigns = [SELECT Id FROM Campaign WHERE fr_ID__c = :campaignId];
            if (campaigns.size() > 0) {
                pledge.put('Campaign_Page__c', campaigns[0].Id);
            } else {
                frUtil.logRelationshipError(getFrType(), commitmentId, frUtil.Entity.CAMPAIGN, campaignId);
            }
        }

        try {
            Database.upsert(pledge, Pledge__c.fr_Id__c, true);
            result = true;
        } catch (DMLException ex) {
            if(createLogRecord) {
                frUtil.logException(getFrType(), commitmentId, ex);
            }
        }

        return result;
    }

    private Boolean deletePledge(Map<String, Object> request) {
        Boolean result = false;
        String commitmentId = getFunraiseId();
        try {
            List<Pledge__c> pledges = [SELECT Id, fr_ID__c FROM Pledge__c WHERE fr_ID__c = :commitmentId];
            if(pledges.size() == 0) {
                return true;
            }
            Pledge__c pledgeToDelete = pledges.get(0);
            delete pledgeToDelete;
            result = true;
        } catch (DMLException e) {
            if(createLogRecord) {
                frUtil.logException(getFrType(), commitmentId, e);
            }
        }
        return result;
    }

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

    public static Pledge__c findActiveAcc(Id accountId, Date closeDate) {
        List<Pledge__c> possiblePledges = [SELECT Id FROM Pledge__c 
                                         WHERE Supporter_PA__c = :accountId 
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

    public static Pledge__c create(SObject gc, Decimal pledgeAmount) {
        Id relatedId = (Id) gc.get('Id');
        Id donorId = (Id) gc.get('DonorId');
        SObject acc = Database.query('SELECT PersonContactId FROM Account WHERE Id = :donorId');
        Pledge__c pledge = new Pledge__c(
            Name = frUtil.truncateToFieldLength(Pledge__c.Name.getDescribe(), 'Subscription Pledge - ' + (String) gc.get('Name')),
            Supporter__c =(id) acc.get('PersonContactId'),
            Supporter_PA__c = (id) gc.get('DonorId'),
            Pledge_Amount__c = pledgeAmount,
            Pledge_Subscription__c = relatedId,
            Pledge_Subscription_uq__c = relatedId
        );
        try {
            Database.upsert(pledge, Pledge__c.Pledge_Subscription_uq__c , true);
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.PLEDGE, (String) gc.get('fr_Id__c'), ex);
        }
        
        return pledge;
    }

    public static Pledge__c create(SObject gt) {
        Id relatedId = (Id) gt.get('Id');
        Id donorId = (Id) gt.get('DonorId');
        SObject acc = Database.query('SELECT PersonContactId FROM Account WHERE Id = :donorId');
        Map<String,Object> gtMap = gt.getPopulatedFieldsAsMap();
        Pledge__c pledge = new Pledge__c(
            Name = frUtil.truncateToFieldLength(Pledge__c.Name.getDescribe(), gtMap.get('Name') == null ? '' : gtMap.get('Name')+' Pledge'),
            Supporter__c =(id) acc.get('PersonContactId'),
            Supporter_PA__c = (id) gt.get('DonorId'),
            Pledge_Amount__c = (Decimal) (gtMap.get('OriginalAmount') ?? 0.0),
            Pledge_Donation_uq__c = relatedId
        );
        pledge.put('Pledge_Gift_Transaction__c', relatedId);
        try {
            Database.upsert(pledge);
            gt.put('Funraise_GT_Pledge__c', pledge.Id);
            update gt;
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.PLEDGE, (String) gt.get('fr_Id__c'), ex);
        }
        
        return pledge;
    }
}