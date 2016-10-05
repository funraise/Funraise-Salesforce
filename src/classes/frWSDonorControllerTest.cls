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
public class frWSDonorControllerTest {
    static testMethod void syncEntity_test() {  

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

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = 'https://XXXX.salesforce.com/services/apexrest/funraise/v1/donor';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(donor));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();

        frWSDonorController.syncEntity();

        Test.stopTest();

        MockResponse response = (MockResponse) JSON.deserialize(res.responseBody.toString(), MockResponse.class);

        
        Id contactId = response.id;
        System.assert(String.isNotBlank(contactId), 
            'There was not an contact Id in the response as expected');
        Contact newContact = [SELECT Id, fr_Funraise_ID__c FROM Contact WHERE Id = :contactId];
        System.assertEquals(donor.getId(), newContact.fr_Funraise_ID__c, 
            'The funraise donor id was not populated to the contact field');
    }

    public class MockResponse {
        String id;
    }
}