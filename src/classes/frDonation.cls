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

public with sharing class frDonation {

    public Opportunity toOpportunity() {
        return new Opportunity(
            Amount=this.amount,
            Name=this.name,
            CloseDate=DateTime.newInstance(cretime).date(),
            IsPrivate=anonymous,
            StageName=(status == 'Failed') ? 'Closed Lost' : 'Closed Won',
            Probability=(status == 'Failed') ? 0 : 100,
            fr_Funraise_Donor__c = sfDonorId,
            fr_Funraise_ID__c = id
        );
    }

    public void save() {
        Opportunity o = this.toOpportunity();
        Database.upsert(o,Opportunity.Fields.fr_Funraise_ID__c,true);
        this.setOpportunityId(o.Id);
    }

    public String getDonorId() {
        return this.donorId;
    }

    public void setDonorId(String donorId) {
        this.donorId = donorId;
    }

    public Decimal getAmount() {
        return amount;
    }

    public void setAmount(Decimal amount) {
        this.amount = amount;
    }

    public Long getCretime() {
        return cretime;
    }

    public void setCretime(Long cretime) {
        this.cretime = cretime;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Boolean getAnonymous() {
        return anonymous;
    }

    public void setAnonymous(Boolean anonymous) {
        this.anonymous = anonymous;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
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


    public String opportunityId;
    public Decimal amount;
    public Long cretime;
    public String name;
    public Boolean anonymous;
    public String status;
    public String donorId;
    public String sfDonorId;
    public String id;
}