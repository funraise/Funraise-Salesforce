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

public class frDonor extends frModel implements frSyncable{
    public static final String TYPE = frUtil.hasNPCobjects() ? 'Person Account' : 'Donor';
    
    public static List<frMapping__c> mappings {
        get {
            String objType = TYPE;
            if(mappings == null) {
                mappings = [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Conflict_Resolution__c, Type__c FROM frMapping__c WHERE Type__c = :objType ORDER BY CreatedDate];
            }
            return mappings;
        }
        set;
    }
    
    public override List<frMapping__c> getMappings() {
        return mappings;
    }
    
    private Contact supporterContact;
    private Account supporterAccount;
    
    public frDonor(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = getRequestBody();
        for (String key : request.keySet()) {
            System.debug('Key: ' + key + ', Value: ' + request.get(key));
        }
        String frId = getFunraiseId();
    
        SObject supporter = null; // Generic SObject for both Account and Contact
        String sObjectType; // To track whether we're dealing with Account or Contact
        
        Boolean isPersonAccount = frUtil.hasNPCobjects();
    
        // Check if Person Accounts are enabled and set the appropriate SObject type
        if (isPersonAccount) {
            sObjectType = 'Account';
        } else {
            sObjectType = 'Contact';
        }
    
        // Query based on fr_ID__c
        List<SObject> records = Database.query(
            'SELECT Id, fr_ID__c, LastName FROM ' + sObjectType + ' WHERE fr_ID__c = :frId'
        );
    
        if (records != null && !records.isEmpty()) {
            supporter = records.get(0);
        }
    
        String firstName = String.valueOf(request.get('firstName'));
        String lastName = String.valueOf(request.get('lastName'));
        String email = String.valueOf(request.get('email'));
    
        // Dynamic email field based on whether Person Accounts are enabled
        String emailField = isPersonAccount ? 'PersonEmail' : 'Email';
    
        // Match based on email and names
        if (supporter == null && String.isNotBlank(email)) {
            String query = 'SELECT Id, fr_ID__c, LastName FROM ' + sObjectType + ' WHERE ' + emailField + ' = :email';
            
            if (String.isNotBlank(firstName) && String.isNotBlank(lastName)) {
                query += ' AND FirstName = :firstName AND LastName = :lastName';
            }
            query += ' LIMIT 1';
    
            records = Database.query(query);
            if(isPersonAccount) {
                supporter = applyAccountMatch(records, frId);
            }
            else {
                supporter = applyMatch(records, frId);
            }
        }
        //match on just email
        if (supporter == null && String.isNotBlank(email)) {
            String query = 'SELECT Id, fr_ID__c, LastName FROM ' + sObjectType + ' WHERE ' + emailField + ' = :email';
    
            query += ' LIMIT 1';
    
            records = Database.query(query);
            if(isPersonAccount) {
                supporter = applyAccountMatch(records, frId);
            }
            else {
                supporter = applyMatch(records, frId);
            }
        }
    
        // If still not found, try matching based on address
        if (supporter == null) {
            String address1 = String.valueOf(request.get('address1'));
            String city = String.valueOf(request.get('city'));
            String state = String.valueOf(request.get('state'));
            String postalCode = String.valueOf(request.get('postalCode'));
    
            Boolean namePresent = String.isNotBlank(firstName) && String.isNotBlank(lastName);
            Boolean cityAndState = String.isNotBlank(city) && String.isNotBlank(state);
    
            String mailingStreetField = isPersonAccount ? 'PersonMailingStreet' : 'MailingStreet';
            String mailingCityField = isPersonAccount ? 'PersonMailingCity' : 'MailingCity';
            String mailingStateField = isPersonAccount ? 'PersonMailingState' : 'MailingState';
            String mailingPostalCodeField = isPersonAccount ? 'PersonMailingPostalCode' : 'MailingPostalCode';
    
            if (namePresent && String.isNotBlank(address1) && (cityAndState || String.isNotBlank(postalCode))) {
                String byAddress = 'SELECT Id, fr_ID__c, LastName FROM ' + sObjectType + 
                    ' WHERE ' + mailingStreetField + ' = :address1 AND FirstName = :firstName AND LastName = :lastName';
    
                if (cityAndState) {
                    byAddress += ' AND ' + mailingCityField + ' = :city AND ' + mailingStateField + ' = :state';
                }
                if (String.isNotBlank(postalCode)) {
                    byAddress += ' AND ' + mailingPostalCodeField + ' = :postalCode';
                }
                byAddress += ' LIMIT 1';
    
                records = Database.query(byAddress);
                supporter = applyMatch(records, frId);
            }
        }
    
        // If no match, create a new record
        if (supporter == null) {
            if(isPersonAccount) {
                supporter = new Account(fr_Id__c = frId);
            } 
            else {
                supporter = new Contact(fr_Id__c = frId);
            }
        }
    
        // Apply mappings
        applyMappings(supporter, request);
    
        if (String.isBlank((String)supporter.get('LastName'))) {
            supporter.put('LastName', String.valueOf(request.get('institutionName')));
        }
        Database.upsert(supporter, true);
        // Perform upsert operation
        try {
            if (supporter.Id != null) {
                Database.update(supporter, true);
            } else {
                Database.upsert(supporter, true);
            }
            result = true;
        } catch (Exception ex) {
            if (createLogRecord) {
                frUtil.logException(getFrType(), frId, ex);
            }
        }
    
        return result;
    }
    
    private Contact applyMatch(List<Contact> matchResults, String frId) {
        if(matchResults != null && matchResults.size() > 0) {
            Contact donor = matchResults.get(0);
            donor.fr_ID__c = frId;
            return donor;
        }
        return null;
    }

    private Account applyAccountMatch(List<Account> matchResults, String frId) {
        if(matchResults != null && matchResults.size() > 0) {
            Account donor = matchResults.get(0);
            donor.fr_ID__c = frId;
            return donor;
        }
        return null;
    }
    
    protected override String getSalesforceId() {
        if(frUtil.hasNPCobjects()) {
            return supporterAccount != null ? supporterAccount.Id : null; 
        }
        else {
            return supporterContact != null ? supporterContact.Id : null;
        }
    }

    protected override Set<Schema.SObjectField> getFields() {
        Map<String, Schema.SObjectField> fields = frSchemaUtil.getFields(Contact.sObjectType.getDescribe().getName());
        Set<Schema.SObjectField> usedFields = new Set<Schema.SObjectField>();
        for(frMapping__c mapping : getMappings()) {
            if(fields.containsKey(mapping.sf_Name__c)) {
                usedFields.add(fields.get(mapping.sf_Name__c));
            }
        }
        usedFields.add(Contact.fr_Id__c);
        usedFields.add(Contact.Email);
        usedFields.add(Contact.FirstName);
        usedFields.add(Contact.LastName);
        usedFields.add(Contact.MailingStreet);
        usedFields.add(Contact.MailingCity);
        usedFields.add(Contact.MailingState);
        usedFields.add(Contact.MailingPostalCode);
        usedFields.add(Contact.MailingCountry);
        if(frUtil.hasNPCobjects()) {
            usedFields = new Set<Schema.SObjectField>();
            fields = frSchemaUtil.getFields(Account.sObjectType.getDescribe().getName());
            for(frMapping__c mapping : getMappings()) {
                if(fields.containsKey(mapping.sf_Name__c)) {
                    usedFields.add(fields.get(mapping.sf_Name__c));
                }
            }
        }
        return usedFields;
    }
    
    protected override Set<Schema.SObjectType> getObjects() {
        if(!frUtil.hasNPCobjects()) {
            return new Set<Schema.SObjectType> {
                    Contact.SObjectType
            };
        }
        else {
            return new Set<Schema.SObjectType> {
                    Account.SObjectType
            };
        }
    }
    
    protected override frUtil.Entity getFrType() {
        return frUtil.Entity.SUPPORTER;
    }
}