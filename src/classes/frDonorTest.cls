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
    static testMethod void fromContact_test() {
        Contact testContact = getTestContact();
        insert testContact;

        Test.startTest();
        frDonor donor = new frDonor(testContact);
        Test.stopTest();

        System.assertEquals(testContact.fr_ID__c, donor.getContact().fr_ID__c, 
            'The donor id was not pulled from the contact fr_ID__c field as expected');
    }

    static testMethod void findByFunraiseId_exists() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor donor = frDonor.findByFunraiseId(testContact.fr_ID__c);
        Test.stopTest();

        System.assertNotEquals(null, donor, 
            'The donor was not retrieved using the fr_ID__c field as expected');
        System.assertEquals(testContact.Id, donor.getContactId(),
            'The donor did not populate the existing contact id as expected');
    }

    static testMethod void findByFunraiseId_doesNotExist() {
        Contact testContact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_ID__c = '123456'
        );
        insert testContact;

        Test.startTest();
        frDonor donor = frDonor.findByFunraiseId('654321');
        Test.stopTest();

        System.assertEquals(null, donor, 
            'The donor was retrieved when it did not match the fr_ID__c field');
    }
    
    public static Contact getTestContact() {
        return new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_ID__c = '123456'
        );
    }
}