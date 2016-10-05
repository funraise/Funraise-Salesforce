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

public with sharing class frDonor {

    public frDonor() {}

    public frDonor(Contact c) {
        this.contactId = c.Id;
        this.id = c.fr_Funraise_ID__c;
        this.email = c.Email;
        this.firstName = c.FirstName;
        this.lastName = c.LastName;
        this.address1 = c.MailingStreet;
        this.city = c.MailingCity;
        this.state = c.MailingState;
        this.postalCode = c.MailingPostalCode;
        this.country = c.MailingCountry;
    }

    public Contact toContact() {
        return new Contact(Id=this.contactId,
                           Email=this.email,
                           FirstName=this.firstName,
                           LastName=this.lastName,
                           MailingStreet=this.address1,
                           MailingCity = this.city,
                           MailingState = this.state,
                           MailingPostalCode = this.postalCode,
                           MailingCountry = this.country,
                           fr_Funraise_ID__c = this.id);
    }

    private static final List<String> fields = new List<String>{'Id','Email','FirstName','LastName',
                                                               'MailingStreet','MailingCity','MailingState',
                                                               'MailingPostalCode','MailingCountry','fr_Funraise_ID__c'};


    public static frDonor findByFunraiseId(String frId) {
        List<Contact> contacts = (List<Contact>)Database.query('select ' +String.join(fields, ',')+ ' from Contact where fr_Funraise_ID__c = :frId');
        if(contacts.size() > 0) {
            return new frDonor(contacts[0]);
        }
        return null;
    }

    public static frDonor findExisting(frDonor donor) {

        String frId = donor.getId();
        //try to find a donor that's already been integrated, use their funraise ID
        List<Contact> contacts = (List<Contact>)Database.query('select Id from Contact where fr_Funraise_ID__c = :frId');

        if(contacts.size() > 0) {
            donor.setContactId(contacts[0].Id);
            return donor;
        }

        String email = donor.getEmail();
        //next try email, dont try to match on blank emails
        if(!String.isBlank(email)) {
            contacts = (List<Contact>)Database.query('select Id from Contact where Email = :email order by CreatedDate desc limit 1');
            if(contacts.size() > 0) {
                donor.setContactId(contacts[0].Id);
                return donor;
            }
        }

        String address1 = donor.getAddress1();
        String city = donor.getCity();
        String state = donor.getState();
        String postalCode = donor.getPostalCode();
        String country = donor.getCountry();
        String firstName = donor.getFirstName();
        String lastName = donor.getLastName();

        //try to match by address, in case we sync an offline donation over with no email.
        String byAddress = 'select Id from Contact where MailingStreet = :address1' +
                           ' and MailingCity = :city' +
                           ' and MailingState = :state' +
                           ' and MailingPostalCode = :postalCode' +
                           ' and MailingCountry = :country' +
                           ' and FirstName = :firstName' +
                           ' and LastName = :lastName' +
                           ' order by CreatedDate desc limit 1';

        contacts = (List<Contact>)Database.query(byAddress);
        if(contacts.size() > 0) {
            donor.setContactId(contacts[0].Id);
            return donor;
        }

        //give back the original if we found no existing ones.
        return donor;
    }

    public void save() {
        Contact c = toContact();
        if(String.isBlank(contactId)) {
            Database.upsert(c,Contact.Fields.fr_Funraise_ID__c,true);
        }
        else {
            upsert c;
        }
        this.setContactId(c.Id);
    }

    public String getContactId() {
        return this.contactId;
    }

    public void setContactId(String contactId) {
        this.contactId = contactId;
    }

    public String getId() {
        return this.id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getEmail() {
        return this.email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFirstName() {
        return this.firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return this.lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getAddress1() {
        return this.address1;
    }

    public void setAddress1(String address1) {
        this.address1 = address1;
    }

    public String getAddress2() {
        return this.address2;
    }

    public void setAddress2(String address2) {
        this.address2 = address2;
    }

    public String getCity() {
        return this.city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getState() {
        return this.state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public String getPostalCode() {
        return this.postalCode;
    }

    public void setPostalCode(String postalCode) {
        this.postalCode = postalCode;
    }

    public String getCountry() {
        return this.country;
    }

    public void setCountry(String country) {
        this.country = country;
    }


    private String contactId;
    private String id;
    private String email;
    private String firstName;
    private String lastName;
    private String address1;
    private String address2;
    private String city;
    private String state;
    private String postalCode;
    private String country;
}