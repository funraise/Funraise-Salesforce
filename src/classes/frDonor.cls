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
* CREATED: 2016 Funraise Inc - https://funraise.io
* AUTHOR: Jason M. Swenski
*/

public class frDonor extends frModel {
    public static final String TYPE = 'Donor';
    
    public static List<frMapping__c> mappings {
        get {
            if(mappings == null) {
                mappings = [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Type__c FROM frMapping__c WHERE Type__c = :TYPE ORDER BY CreatedDate];
            }
            return mappings;
        }
        set;
    }
    
    public override List<frMapping__c> getMappings() {
        return mappings;
    }
    protected override SObject getObject() {
        return c;
    }
    
    private String contactId;
    private String id;
    private Contact c;
    
    public frDonor(Map<String, Object> request) {
        Contact supporterContact = null;
        String frId = String.valueOf(request.get('id'));
        //try to find a donor that's already been integrated, use their funraise ID
        List<Contact> contacts = (List<Contact>)Database.query('select Id, fr_ID__c, LastName from Contact where fr_ID__c = :frId FOR UPDATE');
        if(contacts != null && contacts.size() > 0) {
            supporterContact = contacts.get(0);
        }
        
        String firstName = String.valueOf(request.get('firstName'));
        String lastName = String.valueOf(request.get('lastName'));
        String email = String.valueOf(request.get('email'));
        if(supporterContact == null) {
            if(!String.isBlank(email)) {
                //try to match on email + name, since not all orgs treat email as unique
                if(!String.isBlank(firstName) && !String.isBlank(lastName)) {
                    contacts = (List<Contact>)Database.query(
                        'select Id, fr_ID__c, LastName from Contact where '+
                        'Email = :email AND FirstName = :firstName AND LastName = :lastName '+
                        'limit 1 FOR UPDATE'
                    );
                    supporterContact = applyMatch(contacts, frId);
                }
                
                //if name wasn't present or no match was found, try on email only
                if(supporterContact == null) {
                    contacts = (List<Contact>)Database.query('select Id, fr_ID__c, LastName from Contact where Email = :email limit 1 FOR UPDATE');
                    supporterContact = applyMatch(contacts, frId);                 
                }
                
            }
        }
        
        if(supporterContact == null) {
            String address1 = String.valueOf(request.get('address1'));
            String city = String.valueOf(request.get('city'));
            String state = String.valueOf(request.get('state'));
            String postalCode = String.valueOf(request.get('postalCode'));
            String country = String.valueOf(request.get('country'));
            
            //try to match by address, in case we sync an offline donation over with no email.
            String byAddress = 'select Id, fr_ID__c, LastName from Contact where MailingStreet = :address1' +
                ' and MailingCity = :city' +
                ' and MailingState = :state' +
                ' and MailingPostalCode = :postalCode' +
                ' and MailingCountry = :country' +
                ' and FirstName = :firstName' +
                ' and LastName = :lastName' +
                ' limit 1 FOR UPDATE';
            
            contacts = (List<Contact>)Database.query(byAddress);
            supporterContact = applyMatch(contacts, frId);
        }
        
        if(supporterContact == null) {
            supporterContact = new Contact();
        }
        setContact(supporterContact);
        populateFromRequest(request);
        
        if(String.isBlank(supporterContact.LastName)) {
            //LastName is required.  If the mappings didn't populate it, try to populate with the institution name
            supporterContact.LastName = String.valueOf(request.get('institutionName'));
        }
        
        try {
            Database.upsert(supporterContact, Contact.Fields.fr_ID__c, true);
        } catch (Exception ex) {
            frUtil.logException(frUtil.Entity.SUPPORTER, frId, ex);
        }
    }
    
    private Contact applyMatch(List<Contact> matchResults, String frId) {
        if(matchResults != null && matchResults.size() > 0) {
            Contact donor = matchResults.get(0);
            donor.fr_ID__c = frId;
            update donor;
            return donor;
        }
        return null;
    }
    
    private void setContact(Contact contact) {
        this.c = contact;
    }
    
    public Contact getContact() {
        return c;
    }
    
    public String getContactId() {
        return getContact() != null ? getContact().Id : null;
    }
}