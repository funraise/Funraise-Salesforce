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
* AUTHOR: Alex Molina
*/
@isTest
public class frDonorTest {
    static testMethod void syncEntity_test() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        createMapping('donor_cretime', 'BirthDate');
        
        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonorController.syncEntity();
        Test.stopTest();
        
        String frId = String.valueOf(getTestRequest().get('id'));
        Integer newContact = [SELECT COUNT() FROM Contact WHERE fr_Id__c = :frId];
        System.assertEquals(1, newContact, 'The funraise donor id was not populated to the contact field');
    }
    
    //If the contact's last name field is blank, we'll assume its because there's no last name in funraise
    //likely meaning it's an institution contact, so we should put the institution name in the last name field
    static testMethod void syncEntity_contactLastNameFallback() {
        createMapping('firstName', 'FirstName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        createMapping('donor_cretime', 'BirthDate');
        
        Map<String, Object> request = getTestRequest();
        request.put('lastName', null);
        request.put('institutionName', 'Test Inst Name');
        
        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonorController.syncEntity();
        Test.stopTest();
        
        String frId = String.valueOf(getTestRequest().get('id'));
        Contact newContact = [SELECT Id, fr_ID__c, LastName FROM Contact WHERE fr_Id__c = :frId];
        System.assertEquals(String.valueOf(request.get('institutionName')), newContact.LastName, 'We expected a fallback so that the contact would still get created');
    }
    
    //Sync to an existing contact that once the mappings are applied, LastName is empty so Salesforce will throw an exception
    //confirm our fallback works as expected to prevent that exception
    static testMethod void syncEntity_contactLastNameFallback_existing() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        createMapping('donor_cretime', 'BirthDate');
        
        Contact existingSupporter = getTestContact();
        
        Map<String, Object> request = getTestRequest();
        request.put('id', existingSupporter.fr_Id__c);
        request.put('lastName', null);
        request.put('institutionName', 'Test Inst Name');

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonorController.syncEntity();
        Test.stopTest();
        
        String frId = existingSupporter.fr_Id__c;
        Contact newContact = [SELECT Id, fr_ID__c, LastName FROM Contact WHERE fr_Id__c = :frId];
        System.assertEquals(String.valueOf(request.get('institutionName')), newContact.LastName, 'We expected a fallback so that the contact would still get created');
    }
    
    static testMethod void syncEntity_existing_match_funraise_id() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        
        Contact existing = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'testExisting@example.com', fr_ID__c = '856');
        Contact noMatch = new Contact(LastName = 'nomatch', FirstName = 'nomatch', Email = 'nomatch@example.com', fr_ID__c = '111');
        insert new List<Contact>{existing, noMatch};
            
        Integer countBeforeSync = [SELECT COUNT() FROM Contact];
        
        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonorController.syncEntity();
        Test.stopTest();
        
        String frId = String.valueOf(getTestRequest().get('id'));
		Contact syncedContact = [SELECT Id, fr_ID__c, Email FROM Contact WHERE fr_Id__c = :frId];
        System.assertEquals(existing.Id, syncedContact.Id, 'The existing contact should have been used');
        Integer countAfterSync = [SELECT COUNT() FROM Contact];
        System.assertEquals(countBeforeSync, countAfterSync, 'No additional contacts should have been created');
    }
    
    static testMethod void syncEntity_existing_match_email() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        
        Contact existing = new Contact(LastName = 'Test', FirstName = 'Existing', Email = 'alextest02221503@example.com');
        Contact noMatch = new Contact(LastName = 'nomatch', FirstName = 'nomatch', Email = 'nomatch@example.com', fr_ID__c = '111');
        insert new List<Contact>{existing, noMatch};
            
        Integer countBeforeSync = [SELECT COUNT() FROM Contact];

        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonorController.syncEntity();        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        
        String frId = String.valueOf(getTestRequest().get('id'));
        Contact syncedContact = [SELECT Id, fr_ID__c FROM Contact WHERE fr_Id__c = :frId];
        System.assertEquals(existing.Id, syncedContact.Id, 'The existing contact should have been used');
        Integer countAfterSync = [SELECT COUNT() FROM Contact];
        System.assertEquals(countBeforeSync, countAfterSync, 'No additional contacts should have been created');
    }
    
    static testMethod void syncEntity_existing_match_address() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        Contact existing = new Contact(LastName = 'test02221503', FirstName = 'alex', Email = 'testExisting@example.com',
                                       MailingStreet = '1234 S Street st',
                                       MailingCity = 'Test City',
                                       MailingState = 'AZ',
                                       MailingPostalCode = '85008',
                                       MailingCountry = 'United States'
                                      );
        
        Contact noMatch = new Contact(LastName = 'nomatch', FirstName = 'nomatch', Email = 'nomatch@example.com', fr_ID__c = '111');
        insert new List<Contact>{existing, noMatch};
            
        Integer countBeforeSync = [SELECT COUNT() FROM Contact];
        
        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonorController.syncEntity();
        Test.stopTest();
        
        String frId = String.valueOf(getTestRequest().get('id'));
        Contact syncedContact = [SELECT Id, fr_ID__c FROM Contact WHERE fr_Id__c = :frId];
        System.assertEquals(existing.Id, syncedContact.Id, 'The existing contact should have been used');
        Integer countAfterSync = [SELECT COUNT() FROM Contact];
        System.assertEquals(countBeforeSync, countAfterSync, 'No additional contacts should have been created');
    }
    
    static testMethod void syncEntity_badMappings() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email');
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        
        //bad mapping for date
        createMapping('institutionCategory', 'BirthDate');
        
        frTestUtil.createTestPost(getTestRequest());
        Test.startTest();
        frWSDonorController.syncEntity();
        Test.stopTest();
        
        List<Error__c> errors = [SELECT Error__c FROM Error__c];
        String errorsStr = '';
        for(Error__c error : errors) {
            errorsStr += error.Error__c + '\n';
        }
        System.assertEquals(1, errors.size(), 'Only 1 bad mapping errors were expected (Date field): Errors:' + errorsStr);
        
        
        //but even with bad field mappings the record should still come over correctly
        String frId = String.valueOf(getTestRequest().get('id'));
        Integer newContacts = [SELECT COUNT() FROM Contact WHERE fr_Id__c = :frId];
        System.assertEquals(1, newContacts, 'The funraise donor id was not populated to the contact field');
    }
    
    static testMethod void syncEntity_conflictResolution_noOverwrite() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email', frModel.MAPPING_NO_OVERWRITE);
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        
        Contact existing = getTestContact(true);
        Map<String, Object> request = getTestRequest();
        request.put('id', existing.fr_Id__c);
        request.put('email', 'example.email.overwrite@example.com');

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonorController.syncEntity();        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        
        Contact syncedContact = [SELECT Id, fr_ID__c, Email FROM Contact WHERE fr_Id__c = :existing.fr_Id__c];
        System.assertEquals(existing.Id, syncedContact.Id, 'The existing contact should have been used');
        System.assertEquals(syncedContact.Email, existing.Email, 'The email should not have changed since the NO_OVERWRITE conflict resolution was used');
    }
    
    static testMethod void syncEntity_conflictResolution_overwriteNonNull() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email', frModel.MAPPING_OVERWRITE_NON_NULL);
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry', frModel.MAPPING_OVERWRITE_NON_NULL);
        
        String newEmail = 'example.email.overwrite@example.com';
        
        Contact existing = getTestContact(true);
        Map<String, Object> request = getTestRequest();
        request.put('id', existing.fr_Id__c);
        request.put('email', newEmail); //should overwrite existing value
        request.put('country', null);  //should not overwrite existing value

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonorController.syncEntity();        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        
        Contact syncedContact = [SELECT Id, fr_ID__c, Email, MailingCountry FROM Contact WHERE fr_Id__c = :existing.fr_Id__c];
        System.assertEquals(existing.Id, syncedContact.Id, 'The existing contact should have been used');
        System.assertEquals(syncedContact.Email, newEmail, 'The email should have changed since the OVERWRITE_NON_NULL conflict resolution was used and the incoming value was non null');
        System.assertEquals(syncedContact.MailingCountry, existing.MailingCountry, 'The country should NOT have changed since the OVERWRITE_NON_NULL conflict resolution was used and the incoming value was null');
    }
    
    static testMethod void syncEntity_conflictResolution_overwriteMoreRecent_isMoreRecent() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email', frModel.MAPPING_OVERWRITE_RECENT);
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        
        String newEmail = 'example.email.overwrite@example.com';
        
        Contact existing = getTestContact(true);
        Map<String, Object> request = getTestRequest();
        request.put('id', existing.fr_Id__c);
        request.put('email', newEmail); //should overwrite existing value
        request.put('updtime', DateTime.now().addDays(1).getTime()); //one day in the future, so it should always be more recent

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonorController.syncEntity();        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        
        Contact syncedContact = [SELECT Id, fr_ID__c, Email, MailingCountry FROM Contact WHERE fr_Id__c = :existing.fr_Id__c];
        System.assertEquals(existing.Id, syncedContact.Id, 'The existing contact should have been used');
        System.assertEquals(syncedContact.Email, newEmail, 'The email should have changed since the OVERWRITE_RECENT conflict resolution was used and the updtime was more recent than Salesforce');
    }
    
    static testMethod void syncEntity_conflictResolution_overwriteMoreRecent_isNotMoreRecent() {
        createMapping('firstName', 'FirstName');
        createMapping('lastName', 'LastName');
        createMapping('email', 'email', frModel.MAPPING_OVERWRITE_RECENT);
        createMapping('address1', 'MailingStreet');
        createMapping('city', 'MailingCity');
        createMapping('state', 'MailingState');
        createMapping('postalCode', 'MailingPostalCode');
        createMapping('country', 'MailingCountry');
        
        String newEmail = 'example.email.overwrite@example.com';
        
        Contact existing = getTestContact(true);
        Map<String, Object> request = getTestRequest();
        request.put('id', existing.fr_Id__c);
        request.put('email', newEmail); //should overwrite existing value
        request.put('updtime', DateTime.now().addDays(-50).getTime()); //in the past, so it should not be more recent than Salesforce

        frTestUtil.createTestPost(request);
        Test.startTest();
        frWSDonorController.syncEntity();        
        Test.stopTest();
        frTestUtil.assertNoErrors();
        
        Contact syncedContact = [SELECT Id, fr_ID__c, Email, MailingCountry FROM Contact WHERE fr_Id__c = :existing.fr_Id__c];
        System.assertEquals(existing.Id, syncedContact.Id, 'The existing contact should have been used');
        System.assertEquals(syncedContact.Email, existing.Email, 'The email should not have changed since the OVERWRITE_RECENT conflict resolution was used and the updtime was more recent than Salesforce');
    }
    
    private static void createMapping(String frField, String sfField) {
        createMapping(frField, sfField, null);
    }
    
    private static void createMapping(String frField, String sfField, String conflictResolution) {
        insert new frMapping__c(Type__c = frDonor.TYPE, Name = frField+sfField, 
                                fr_Name__c = frField, sf_Name__c = sfField, Conflict_Resolution__c = conflictResolution);
    }

    public static Contact getTestContact(Boolean save) {
        Contact contact = new Contact(
            FirstName = 'Bruce', LastName = 'Wayne', Email = 'bruce@wayne.example.com',
            MailingStreet = '1007 Mountain Drive', MailingCity = 'Gotham', MailingState = 'NJ', 
            MailingPostalCode = '12345', MailingCountry = 'United States', fr_ID__c = '123456'
        );
        if(save) {
            insert contact;
        }
        return contact;
    }
    
    public static Contact getTestContact() {
        return getTestContact(true);
    }
    
    public static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('id', 856);
        request.put('organizationId', 'ae8d412b-db97-49dc-8c8c-5bfe0f41fc6d');
        request.put('email', 'alextest02221503@example.com');
        request.put('firstName', 'alex');
        request.put('lastName', 'test02221503');
        request.put('name', 'alex test02221503');
        request.put('institutionName', null);
        request.put('institutionCategory', 'Individual');
        request.put('address1', '1234 S Street st');
        request.put('address2', null);
        request.put('city', 'Test City');
        request.put('state', 'AZ');
        request.put('postalCode', '85008');
        request.put('country', 'United States');
        request.put('notes', null);
        request.put('age', 67);
        request.put('gender', 'F');
        request.put('p2gScore', '3|6 - Average');
        request.put('netWorth', '$100MM-$500MM');
        request.put('income', '$10MM-$25MM');
        request.put('giftCapacity', '$300K-$500K');
        request.put('annualDonations', '$10K-$25K');
        request.put('realEstate', '$5MM-$10MM');
        request.put('photoUrl', null);
        request.put('linkedinUrl', null);
        request.put('facebookUrl', null);
        request.put('twitterUrl', null);
        request.put('employerName', null);
        request.put('jobTitle', null);
        request.put('homeowner', null);
        request.put('maritalStatus', null);
        request.put('influencerScore', null);
        request.put('education', null);
        request.put('donorType', 'RECURRING');
        request.put('totalDonationAmount', 30);
        request.put('totalDonationCount', 3);
        request.put('lastDonationDate', 1493077510493L);
        request.put('firstDonationDate', 1487801043934L);
        request.put('totalSoftCreditAmount', null);
        request.put('totalSoftCreditCount', null);
        request.put('fundraiserDonationAmount', null);
        request.put('fundraiserDonationCount', null);
        request.put('fundraiser', false);
        request.put('donor_tags', 'FeedingPoor EatingFood');
        request.put('donor_cretime', 1487801043597L);
        request.put('updtime', 1658702180337L);
        return request;
    }
}