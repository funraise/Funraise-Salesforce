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
    public static final String TYPE = 'Donor';
    
    public static List<frMapping__c> mappings {
        get {
            if(mappings == null) {
                mappings = [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Conflict_Resolution__c, Type__c FROM frMapping__c WHERE Type__c = :TYPE ORDER BY CreatedDate];
            }
            return mappings;
        }
        set;
    }
    
    public override List<frMapping__c> getMappings() {
        return mappings;
    }
    
    private Contact supporterContact;
    
    public frDonor(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }
    
    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = getRequestBody();
        supporterContact = null;
        String frId = getFunraiseId();
        //try to find a donor that's already been integrated, use their funraise ID
        List<Contact> contacts = (List<Contact>)Database.query('select Id, fr_ID__c, LastName from Contact where fr_ID__c = :frId');
        if(contacts != null && contacts.size() > 0) {
            supporterContact = contacts.get(0);
        }
        
        String firstName = String.valueOf(request.get('firstName'));
        String lastName = String.valueOf(request.get('lastName'));
        String email = String.valueOf(request.get('email'));
        if(supporterContact == null) {
            if(String.isNotBlank(email)) {
                //try to match on email + name, since not all orgs treat email as unique
                if(String.isNotBlank(firstName) && String.isNotBlank(lastName)) {
                    contacts = (List<Contact>)Database.query(
                        'select Id, fr_ID__c, LastName from Contact where '+
                        'Email = :email AND FirstName = :firstName AND LastName = :lastName '+
                        'limit 1'
                    );
                    supporterContact = applyMatch(contacts, frId);
                }
                
                //if name wasn't present or no match was found, try on email only
                if(supporterContact == null) {
                    contacts = (List<Contact>)Database.query('select Id, fr_ID__c, LastName from Contact where Email = :email limit 1');
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
            
            //name AND street address AND (cityAndState or postalCode) 
            //need to be populated for us to match
            Boolean namePresent = String.isNotBlank(firstName) && String.isNotBlank(lastName);
            Boolean cityAndState = String.isNotBlank(city) && String.isNotBlank(state);
            if(namePresent && String.isNotBlank(address1) && (cityAndState || String.isNotBlank(postalCode))) {
                String byAddress = 'select Id, fr_ID__c, LastName from Contact where MailingStreet = :address1' +
                    ' and FirstName = :firstName' +
                    ' and LastName = :lastName';
                if(cityAndState) {
                    byAddress += ' and MailingCity = :city' +
                    ' and MailingState = :state';
                }
                if(String.isNotBlank(postalCode)) {
                    byAddress += ' and MailingPostalCode = :postalCode';
                }
                byAddress += ' limit 1';
                
                contacts = (List<Contact>)Database.query(byAddress);
                supporterContact = applyMatch(contacts, frId);
            }
        }
        
        if(supporterContact == null) {
            supporterContact = new Contact(fr_Id__c = frId);
        }
        applyMappings(supporterContact, request);
        
        if(String.isBlank(supporterContact.LastName)) {
            //LastName is required.  If the mappings didn't populate it, try to populate with the institution name
            supporterContact.LastName = String.valueOf(request.get('institutionName'));
        }
        
        try {
            //if we try the upsert using an external id when the contact has an id, 
            //an exception is thrown
            if(supporterContact.Id != null) {
                Database.update(supporterContact, true);
            } else { 
                Database.upsert(supporterContact, Contact.Fields.fr_ID__c, true);
            }
            result = true;
        } catch (Exception ex) {
            if(createLogRecord) frUtil.logException(getFrType(), frId, ex);

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
    
    protected override String getSalesforceId() {
        return supporterContact != null ? supporterContact.Id : null;
        
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
        return usedFields;
    }
    
    protected override Set<Schema.SObjectType> getObjects() {
        return new Set<Schema.SObjectType> {
            	Contact.SObjectType
        };
    }
    
    protected override frUtil.Entity getFrType() {
        return frUtil.Entity.SUPPORTER;
    }
}