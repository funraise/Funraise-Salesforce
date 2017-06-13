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
 * AUTHOR: Jason M. Swenski
 */

public class frDonation extends frModel {
    public static List<frMapping__c> mappings {
        get {
            if(mappings == null) {
                mappings = [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c FROM frMapping__c WHERE Type__c = :TYPE ORDER BY CreatedDate];
            }
            return mappings;
        }
        set;
    }

    public override List<frMapping__c> getMappings() {
        return mappings;
    }
    public static final String TYPE = 'Donation';
    protected override SObject getObject() {
        return o;
    }

    private String opportunityId;
    private String donorId;
    private String sfDonorId;
    private Opportunity o;

    public frDonation() {
        this.o = new Opportunity();
    }

    public Opportunity getOpportunity() {
        o.fr_Donor__c = getSfDonorId();
        return o;
    }

    public override void populateFromRequest(Map<String, Object> request) {
        super.populateFromRequest(request);
        this.setDonorId(String.valueOf(request.get('donorId')));
        String status = String.valueOf(request.get('status'));
        if(String.isBlank(o.StageName)) {
            o.StageName = (status == 'Failed') ? 'Closed Lost' : 'Closed Won';    
        }
    }

    public static frDonation create(Map<String, Object> request) {
        frDonation donation = new frDonation();
        donation.populateFromRequest(request);
        return donation;
    }

    public Boolean save() {
        Boolean isSuccess = false;
        try {
            Opportunity opp = getOpportunity();
            Database.upsert(opp,Opportunity.Fields.fr_Id__c,true);
            setOpportunityId(opp.Id);
            isSuccess = true;
        } catch (Exception ex) {
            handleException(ex);
            isSuccess = false;
        }
        flushLogs();
        return isSuccess;
    }

    public String getDonorId() {
        return this.donorId;
    }

    public void setDonorId(String donorId) {
        this.donorId = donorId;
    }

    public String getOpportunityId() {
        return opportunityId;
    }

    public void setOpportunityId(String opportunityId) {
        this.opportunityId = opportunityId;
    }

     public String getSfDonorId() {
        return sfDonorId;
    }

    public void setSfDonorId(String sfDonorId) {
        this.sfDonorId = sfDonorId;
    }
}