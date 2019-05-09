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
* AUTHOR: Jordan Speer
*/

public class frCampaign {
    
    public frCampaign(Map<String, Object> request) {
        if (Boolean.valueOf(request.get('deleted'))) {
            deleteCampaign(request);
        } else {
            create(request);
        }
    }
    
    public void deleteCampaign(Map<String, Object> request) {
        String goalId = String.valueOf(request.get('goalId'));
        try {
            Campaign campaign = Database.query('select Id, fr_ID__c, ParentId from Campaign where fr_ID__c = :goalId');
            String sfCampaignId = campaign.Id;
            List<Campaign> childCampaigns = Database.query('select Id, fr_ID__c, ParentId from Campaign where parentId = :sfCampaignId');
            if (childCampaigns.size() > 0) {
                String sfParentCampaignId = campaign.ParentId;
                Boolean updateChildren = sfParentCampaignId != '0' && sfParentCampaignId != null;
                for (Campaign childCampaign : childCampaigns) {
                    if (updateChildren) {
                        childCampaign.parentId = sfParentCampaignId;
                    } else {
                        delete childCampaign;
                    }
                }
                if (updateChildren) {
                    Database.update(childCampaigns, true);
                }
            }
            delete campaign;
            return;
        } catch (DMLException e) {
            insert new Error__c(Error__c =
                                'Failed to delete funraise campaign for campaign id ' + goalId +
                                '. Exception: ' + e.getMessage());
        }
    }
    
    public void create(Map<String, Object> request) {
        String goalId = String.valueOf(request.get('goalId'));
        
        Campaign newCampaign = new Campaign();
        newCampaign.Name = String.valueOf(request.get('name'));
        newCampaign.Description = String.valueOf(request.get('reason'));
        newCampaign.Status = String.valueOf(request.get('status'));
        newCampaign.ExpectedRevenue = Decimal.valueOf(String.valueOf(request.get('goalAmount')));
        newCampaign.fr_ID__c = goalId;
        
        String parentId = String.valueOf(request.get('parentGoalId'));
        if (parentId != null && parentId != '0') {
            Campaign parentCampaign = Database.query('select Id, fr_ID__c from Campaign where fr_ID__c = :parentId');
            if(parentCampaign != null) {
                newCampaign.ParentId = parentCampaign.Id;                
            }
        }
        try {
            Database.upsert(newCampaign, Campaign.Field.fr_ID__c, true);
        } catch (DMLException e) {
            insert new Error__c(Error__c =
                                'Failed to insert funraise campaign for campaign id ' + goalId +
                                '. Exception: ' + e.getMessage());
            return;
        }
        
        String supporterId = String.valueOf(request.get('supporterId'));
        if(String.isNotBlank(supporterId)) {
            frDonor donor = frDonor.findByFunraiseId(supporterId);
            if(donor != null) {
                Boolean campaignMemberExists = [SELECT COUNT() FROM CampaignMember 
                                                WHERE ContactId = :donor.getContactId() 
                                                AND CampaignId = :newCampaign.Id] > 0;
                CampaignMember fundraiserMember = new CampaignMember(
                    CampaignId = newCampaign.Id,
                    ContactId = donor.getContactId()
                );
                try {
                    insert fundraiserMember;
                } catch (DMLException e) {
                    insert new Error__c(Error__c =
                                        'Failed to insert funraise campaign member for campaign id ' + goalId +
                                        'supporter id: ' + supporterId + '. Exception: ' + e.getMessage());
                    return;
                }
                
            }
        }
    }
}