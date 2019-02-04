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

    public frDonor(Contact c) {
        this.contactId = c.Id;
        this.id = c.fr_ID__c;
        this.c = c;
    }

    public frDonor(String frId) {
        this.id = frId;
        this.c = new Contact(fr_ID__c = frId);
    }

    public static frDonor findByFunraiseId(String frId) {
        List<Contact> contacts = (List<Contact>)Database.query('select Id, fr_ID__c from Contact where fr_ID__c = :frId');
        if(contacts.size() > 0) {
            return new frDonor(contacts[0]);
        }
        return null;
    }

    public static frDonor create(Map<String, Object> request) {
        Contact existingContact = null;
        String frId = String.valueOf(request.get('id'));
        //try to find a donor that's already been integrated, use their funraise ID
        List<Contact> contacts = (List<Contact>)Database.query('select Id, fr_ID__c from Contact where fr_ID__c = :frId');
        if(contacts.size() > 0) {
            existingContact = contacts.get(0);
        }

        if(existingContact == null) {
            String email = String.valueOf(request.get('email'));
            //next try email, dont try to match on blank emails
            if(!String.isBlank(email)) {
                contacts = (List<Contact>)Database.query('select Id, fr_ID__c from Contact where Email = :email order by CreatedDate desc limit 1');
                if(contacts.size() > 0) {
                    existingContact = contacts.get(0);
                }
            }
        }

        if(existingContact == null) {
            String address1 = String.valueOf(request.get('address1'));
            String city = String.valueOf(request.get('city'));
            String state = String.valueOf(request.get('state'));
            String postalCode = String.valueOf(request.get('postalCode'));
            String country = String.valueOf(request.get('country'));
            String firstName = String.valueOf(request.get('firstName'));
            String lastName = String.valueOf(request.get('lastName'));

            //try to match by address, in case we sync an offline donation over with no email.
            String byAddress = 'select Id, fr_ID__c from Contact where MailingStreet = :address1' +
                               ' and MailingCity = :city' +
                               ' and MailingState = :state' +
                               ' and MailingPostalCode = :postalCode' +
                               ' and MailingCountry = :country' +
                               ' and FirstName = :firstName' +
                               ' and LastName = :lastName' +
                               ' order by CreatedDate desc limit 1';

            contacts = (List<Contact>)Database.query(byAddress);
            if(contacts.size() > 0) {
                existingContact = contacts.get(0);
            }
        }

        frDonor donor;
        if(existingContact == null) {
            donor = new frDonor(frId);
        } else {
            existingContact.fr_ID__c = frId;
            donor = new frDonor(existingContact);
        }
        donor.populateFromRequest(request);

        return donor;
    }

    public void addTags(List<Object> tags) {
        if(tags == null || tags.isEmpty()){
            return;
        }

        Contact c = getContact();

        List<ContactTag> contactTags = new List<ContactTag>();

        for(Object tag : tags){
            String name = String.valueOf(tag);
            ContactTag contactTag = new ContactTag();
            contactTag.ItemId = c.Id;
            contactTag.Name = mapTag(name);
            contactTag.Type = 'Personal';
            contactTags.add(contactTag);
        }

        Database.upsert(contactTags);
    }

    public Boolean save() {
        Boolean isSuccess = false;
        try {
            Contact c = getContact();
            if(String.isBlank(c.Id) && String.isNotBlank(c.fr_ID__c)) {
                Database.upsert(c,Contact.Fields.fr_ID__c,true);
            }
            else {
                upsert c;
            }
            this.setContactId(c.Id);
            isSuccess = true;
        } catch (Exception ex) {
            handleException(ex);
            isSuccess = false;
        }
        flushLogs();
        return isSuccess;
    }

    public String getContactId() {
        return this.contactId;
    }

    public void setContactId(String contactId) {
        System.debug('Setting contact id: ' + contactId);
        if(this.c == null) {
            this.c = new Contact(Id = contactId);
        }
        this.contactId = contactId;
    }

    public Contact getContact() {
        if(String.isNotBlank(getContactId())) {
            c.Id = getContactId();
        }
        return c;
    }
}
