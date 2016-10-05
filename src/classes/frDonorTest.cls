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
 * AUTHOR: Alex Molina
 */
@isTest
public class frDonorTest {
    static testMethod void toContact_insert() {
        Test.startTest();
        frDonor donor = new frDonor();
        donor.setId('123456');
        donor.setEmail('bruce@wayne.example.com');
        donor.setFirstName('Bruce');
        donor.setLastName('Wayne');
        donor.setAddress1('1007 Mountain Drive');
        donor.setAddress2('Suite A');
        donor.setCity('Gotham');
        donor.setState('NJ');
        donor.setPostalCode('12345');
        donor.setCountry('United States');

        donor.save();
        Test.stopTest();

        Contact newContact = [
            SELECT Id,Email,FirstName,LastName,MailingStreet,MailingCity,
                MailingState,MailingPostalCode,MailingCountry,fr_Funraise_ID__c 
            FROM Contact WHERE Id = :donor.getContactId()
        ];

        System.assertEquals(donor.getId(), newContact.fr_Funraise_ID__c, 
            'The donor id was not set to the contact fr_Funraise_ID__c field as expected');
        System.assertEquals(donor.getEmail(), newContact.Email, 
            'The donor email was not set to the contact Email field as expected');
        System.assertEquals(donor.getFirstName(), newContact.FirstName, 
            'The donor first name was not set to the contact first name field as expected');
        System.assertEquals(donor.getLastName(), newContact.LastName, 
            'The donor last name was not set to the contact last name field as expected');
        System.assertEquals(donor.getAddress1(), newContact.MailingStreet, 
            'The donor address 1 was not set to the contact mailing street field as expected');
        System.assertEquals('Suite A', donor.getAddress2(), 
            'The donor address 2 was not set to the value that was passed as expected');
        System.assertEquals(donor.getCity(), newContact.MailingCity, 
            'The city was not set to the contact mailing city field as expected');
        System.assertEquals(donor.getState(), newContact.MailingState, 
            'The donor state was not set to the contact mailing state field as expected');
        System.assertEquals(donor.getPostalCode(), newContact.MailingPostalCode, 
            'The donor postal code was not set to the contact mailing postal code field as expected');
        System.assertEquals(donor.getCountry(), newContact.MailingCountry, 
            'The donor country was not set to the contact mailing country field as expected');
    }

    static testMethod void toContact_upsert() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_Funraise_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor donor = new frDonor();
        donor.setId('123456');
        donor.setEmail('bruce@wayne.example.com');
        donor.setFirstName('Bruce');
        donor.setLastName('Wayne');
        donor.setAddress1('1007 Mountain Drive');
        donor.setAddress2('Suite A');
        donor.setCity('Gotham');
        donor.setState('NJ');
        donor.setPostalCode('12345');
        donor.setCountry('United States');
        donor.setContactId(testContact.Id);

        donor.save();
        Test.stopTest();

        Contact newContact = [
            SELECT Id,Email,FirstName,LastName,MailingStreet,MailingCity,
                MailingState,MailingPostalCode,MailingCountry,fr_Funraise_ID__c 
            FROM Contact WHERE Id = :donor.getContactId()
        ];

        System.assertEquals(donor.getId(), newContact.fr_Funraise_ID__c, 
            'The donor id was not set to the contact fr_Funraise_ID__c field as expected'); 
    }

    static testMethod void fromContact_test() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_Funraise_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor donor = new frDonor(testContact);
        Test.stopTest();

        System.assertEquals(testContact.fr_Funraise_ID__c, donor.getId(), 
            'The donor id was not pulled from the contact fr_Funraise_ID__c field as expected');
        System.assertEquals(testContact.Email, donor.getEmail(), 
            'The donor email was not pulled from the contact Email field as expected');
        System.assertEquals(testContact.FirstName, donor.getFirstName(), 
            'The donor first name was not pulled from the contact first name field as expected');
        System.assertEquals(testContact.LastName, donor.getLastName(), 
            'The donor last name was not pulled from the contact last name field as expected');
        System.assertEquals(testContact.MailingStreet, donor.getAddress1(), 
            'The donor address 1 was not pulled from the contact mailing street field as expected');
        System.assertEquals(testContact.MailingCity, donor.getCity(), 
            'The city was not pulled from the contact mailing city field as expected');
        System.assertEquals(testContact.MailingState, donor.getState(), 
            'The donor state was not pulled from the contact mailing state field as expected');
        System.assertEquals(testContact.MailingPostalCode, donor.getPostalCode(), 
            'The donor postal code was not pulled from the contact mailing postal code field as expected');
        System.assertEquals(testContact.MailingCountry, donor.getCountry(), 
            'The donor country was not pulled from the contact mailing country field as expected');
    }

    static testMethod void findByFunraiseId_exists() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_Funraise_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor donor = frDonor.findByFunraiseId(testContact.fr_Funraise_ID__c);
        Test.stopTest();

        System.assertNotEquals(null, donor, 
            'The donor was not retrieved using the fr_Funraise_ID__c field as expected');
        System.assertEquals(testContact.Id, donor.getContactId(),
            'The donor did not populate the existing contact id as expected');
    }

    static testMethod void findByFunraiseId_doesNotExist() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_Funraise_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor donor = frDonor.findByFunraiseId('654321');
        Test.stopTest();

        System.assertEquals(null, donor, 
            'The donor was retrieved when it did not match the fr_Funraise_ID__c field');
    }

    static testMethod void findExisting_funraiseId() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_Funraise_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor existingDonor = new frDonor();
        existingDonor.setId(testContact.fr_Funraise_ID__c);
        frDonor donor = frDonor.findExisting(existingDonor);
        Test.stopTest();

        System.assertNotEquals(null, donor, 
            'The donor was not retrieved using the fr_Funraise_ID__c field as expected');
        System.assertEquals(testContact.Id, donor.getContactId(),
            'The donor did not populate the existing contact id as expected');
    }

    static testMethod void findExisting_email() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_Funraise_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor existingDonor = new frDonor();
        existingDonor.setEmail(testContact.Email);
        frDonor donor = frDonor.findExisting(existingDonor);
        Test.stopTest();

        System.assertNotEquals(null, donor, 
            'The donor was not retrieved using the email field as expected');
        System.assertEquals(testContact.Id, donor.getContactId(),
            'The donor did not populate the existing contact id as expected');
    }


    static testMethod void findExisting_address() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_Funraise_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor existingDonor = new frDonor();
        existingDonor.setAddress1(testContact.MailingStreet);
        existingDonor.setCity(testContact.MailingCity);
        existingDonor.setState(testContact.MailingState);
        existingDonor.setPostalCode(testContact.MailingPostalCode);
        existingDonor.setCountry(testContact.MailingCountry);
        existingDonor.setFirstName(testContact.FirstName);
        existingDonor.setLastName(testContact.LastName);
        frDonor donor = frDonor.findExisting(existingDonor);
        Test.stopTest();

        System.assertNotEquals(null, donor, 
            'The donor was not retrieved using the address fields as expected');
        System.assertEquals(testContact.Id, donor.getContactId(),
            'The donor did not populate the existing contact id as expected');
    }

    static testMethod void findExisting_noMatch() {

        Test.startTest();
        frDonor existingDonor = new frDonor();
        existingDonor.setId('123456');
        existingDonor.setEmail('bruce@wayne.example.com');
        existingDonor.setFirstName('Bruce');
        existingDonor.setLastName('Wayne');
        existingDonor.setAddress1('1007 Mountain Drive');
        existingDonor.setAddress2('Suite A');
        existingDonor.setCity('Gotham');
        existingDonor.setState('NJ');
        existingDonor.setPostalCode('12345');
        existingDonor.setCountry('United States');
        frDonor donor = frDonor.findExisting(existingDonor);
        Test.stopTest();

        System.assert(String.isBlank(donor.getContactId()),
            'The donor was retrieved mapped to an existing contact when it should not have');
    }
}