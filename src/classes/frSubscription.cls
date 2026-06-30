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
* CREATED: 2019 Funraise Inc - https://funraise.io
* AUTHOR: Alex Molina
*/

public class frSubscription extends frModel implements frSyncable {
    public static final String NPSP_RECURRING_DONATION_TYPE = 'NPSP Recurring Donation';
    private static final String NPSP_RD_AMOUNT_FIELD_NAME = 'npe03__Amount__c';
    private static final String NPSP_RD_DATE_ESTABLISHED_FIELD_NAME = 'npe03__Date_Established__c';
    private static final String NPSP_RD_DAY_OF_MONTH_FIELD_NAME = 'npe03__Day_of_Month__c';
    private static final String NPSP_RD_INSTALLMENT_FREQUENCY_FIELD_NAME = 'npe03__InstallmentFrequency__c';
    private static final String NPSP_RD_INSTALLMENT_PERIOD_FIELD_NAME = 'npe03__Installment_Period__c';
    private static final String NPSP_RD_NEXT_PAYMENT_DATE_FIELD_NAME = 'npe03__Next_Payment_Date__c';
    private static final String NPSP_RD_OPEN_ENDED_STATUS_FIELD_NAME = 'npe03__Open_Ended_Status__c';
    private static final String NPSP_RD_PAYMENT_METHOD_FIELD_NAME = 'npe03__PaymentMethod__c';
    private static final String NPSP_RD_RECURRING_TYPE_FIELD_NAME = 'npe03__RecurringType__c';
    private static final String NPSP_RD_SCHEDULE_TYPE_FIELD_NAME = 'npe03__Schedule_Type__c';
    private static final String NPSP_RD_START_DATE_FIELD_NAME = 'npe03__StartDate__c';
    private static final String NPSP_RD_STATUS_FIELD_NAME = 'npe03__Status__c';

    public static final Map<String, Schema.SObjectField> fields =
        frSchemaUtil.getFields(Subscription__c.getSObjectType().getDescribe().getName());

    public frSubscription(Sync_Attempt__c syncRecord){
        super(syncRecord);
    }

    public Boolean sync() {
        Boolean result = false;
        Map<String, Object> request = getRequestBody();
        if (Boolean.valueOf(request.get('deleted'))) {
            result = deleteSubscription(getFunraiseId());
        } else {
            result = create(request);
        }
        return result;
    }

    private Boolean deleteSubscription(String funraiseId) {
        Boolean result = false;
        try {
            if(frUtil.hasNPCobjects()) {
                delete Database.query('SELECT Id FROM GiftCommitment WHERE fr_ID__c = :funraiseId');
                result = true;
            }
            else if(frUtil.usesNPSPRecurringDonations()) {
                String query = 'SELECT Id FROM ' + frUtil.NPSP_RECURRING_DONATION_OBJ_NAME
                    + ' WHERE ' + frUtil.NPSP_RECURRING_DONATION_ID_FIELD_NAME + ' = :funraiseId';
                delete Database.query(query);
                result = true;
            }
            else {
                delete [SELECT id FROM Subscription__c WHERE fr_ID__c = :funraiseId];
                result = true;
            }
        } catch (Exception e) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, e);
        }
        return result;
    }

    private Boolean create(Map<String, Object> request) {
        Boolean result = false;
        String funraiseId = getFunraiseId();
        String name = String.valueOf(request.get('name'));
        String funraiseSupporterId = String.valueOf(request.get('supporterId'));
        String goalId = String.valueOf(request.get('campaignGoalId'));
        String strPledgeAmount = String.valueOf(request.get('pledgeAmount'));
        Decimal pledgeAmount = String.isNotBlank(strPledgeAmount) ? Decimal.valueOf(strPledgeAmount) : null;
        List<Contact> contacts = [SELECT Id, AccountId from Contact WHERE fr_Id__c = :funraiseSupporterId];
        List<Account> accounts = new List<Account>();
        if (frUtil.hasNPCobjects()) {
            accounts = Database.query('SELECT Id, PersonContactId FROM Account WHERE fr_ID__c = :funraiseSupporterId');
        }
        if(contacts.isEmpty() && accounts.isEmpty()) {
            if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId,
                                        frUtil.Entity.SUPPORTER, funraiseSupporterId);
            return result;
        }
        Subscription__c subscription;
        if(frUtil.hasNPCobjects()) {
            SObject gc = null;
            List<SObject> gcList = Database.query('SELECT Id, Name FROM GiftCommitment WHERE fr_ID__c = :funraiseId');
            if(gcList.isEmpty()) {
                gc = Schema.getGlobalDescribe().get('giftcommitment').newSObject();
            }
            else {
                gc = gcList.get(0);
            }
            gc.put('fr_ID__c', funraiseId);
            gc.put('Name', frUtil.truncateToFieldLength(
                Schema.getGlobalDescribe().get('GiftCommitment').getDescribe().fields.getMap().get('Name').getDescribe(),
                String.valueOf(request.get('name'))
            ));
            gc.put('DonorId', accounts.get(0).Id);

            // campaign check for gc
            if (String.isNotBlank(goalId)) {
                List<Campaign> campaigns = [SELECT Id FROM Campaign WHERE fr_ID__c = :goalId];
                if (campaigns.size() > 0) {
                    gc.put('CampaignId', campaigns.get(0).Id);
                } else {
                    if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId,
                                                frUtil.Entity.CAMPAIGN, goalId);
                }
            }

            applyMappings(gc, request);
            try {
                Database.upsert(gc, true);
                result = true;
            } catch (DMLException ex) {
                if(createLogRecord) frUtil.logException(getFrType(), funraiseId, ex);
                return result;
            }

            if(pledgeAmount != null) {
                frPledge.create(gc, pledgeAmount);
            }
            return result;
        }
        else if(frUtil.usesNPSPRecurringDonations()) {
            if(contacts.isEmpty()) {
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId,
                                            frUtil.Entity.SUPPORTER, funraiseSupporterId);
                return result;
            }
            return createNPSPRecurringDonation(request, contacts.get(0));
        }
        else if(contacts.isEmpty()) {
            if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId,
                                        frUtil.Entity.SUPPORTER, funraiseSupporterId);
            return result;
        }
        else {
            subscription = new Subscription__c(
                fr_ID__c = funraiseId,
                Name = frUtil.truncateToFieldLength(
                    Subscription__c.Name.getDescribe(),
                    String.valueOf(request.get('name'))
                ),
                Supporter__c = contacts.get(0).Id
            );
        }

        if (String.isNotBlank(goalId)) {
            List<Campaign> campaigns = [SELECT Id FROM Campaign WHERE fr_ID__c = :goalId];
            if (campaigns.size() > 0) {
                subscription.Campaign_Goal__c = campaigns.get(0).Id;
            } else {
                if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId,
                                            frUtil.Entity.CAMPAIGN, goalId);
            }
        }

    //transform other request fields into SF custom fields, these are not applicable
        request.remove('id');
        request.remove('name');
        request.remove('supporterId');
        request.remove('campaignGoalId');
        request.remove('deleted');
        request.remove('pledgeAmount');

        String regex = '([a-z])([A-Z]+)';
        String replacement = '$1_$2';
        for(String funraiseFieldName : request.keySet()) {
            String salesforceFieldName = funraiseFieldName.replaceAll(regex, replacement);
            salesforceFieldName =+ 'funraise__' + salesforceFieldName.capitalize() + '__c';
            Schema.SObjectField field = fields.get(salesforceFieldName);
            frModel.write(subscription, field, funraiseFieldName, request.get(funraiseFieldName), funraiseId);
        }


        try {
            Database.upsert(subscription, Subscription__c.Field.fr_ID__c, true);
            result = true;
        } catch (DMLException ex) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, ex);
            return result;
        }

        if(pledgeAmount != null) {
            frPledge.create(subscription, pledgeAmount);
        }
        return result;
    }

    private Boolean createNPSPRecurringDonation(Map<String, Object> request, Contact contact) {
        Boolean result = false;
        String funraiseId = getFunraiseId();
        try {
            String goalId = String.valueOf(request.get('campaignGoalId'));
            String query = 'SELECT Id, Name FROM ' + frUtil.NPSP_RECURRING_DONATION_OBJ_NAME
                + ' WHERE ' + frUtil.NPSP_RECURRING_DONATION_ID_FIELD_NAME + ' = :funraiseId';
            List<SObject> records = Database.query(query);
            SObject recurringDonation = records.isEmpty()
                ? frUtil.getSObjectType(frUtil.NPSP_RECURRING_DONATION_OBJ_NAME).newSObject()
                : records.get(0);
            Map<String, Schema.SObjectField> npspFields = frUtil.getFields(frUtil.NPSP_RECURRING_DONATION_OBJ_NAME);

            putFieldIfExists(recurringDonation, npspFields, frUtil.NPSP_RECURRING_DONATION_ID_FIELD_NAME, funraiseId);
            putStringFieldIfExists(recurringDonation, npspFields, 'Name', String.valueOf(request.get('name')));
            putFieldIfExists(recurringDonation, npspFields, frUtil.NPSP_RECURRING_DONATION_CONTACT_FIELD_NAME, contact.Id);

            if (String.isNotBlank(goalId)) {
                List<Campaign> campaigns = [SELECT Id FROM Campaign WHERE fr_ID__c = :goalId];
                if (campaigns.size() > 0) {
                    putFieldIfExists(recurringDonation, npspFields, frUtil.NPSP_RECURRING_DONATION_CAMPAIGN_FIELD_NAME, campaigns.get(0).Id);
                } else {
                    if(createLogRecord) frUtil.logRelationshipError(getFrType(), funraiseId,
                                                frUtil.Entity.CAMPAIGN, goalId);
                }
            }

            applyNPSPRecurringDonationDefaults(recurringDonation, npspFields, request, funraiseId);
            applyMappings(recurringDonation, request, frUtil.NPSP_RECURRING_DONATION_ID_FIELD_NAME);
            Database.upsert(recurringDonation, true);
            result = true;
        } catch (Exception ex) {
            if(createLogRecord) frUtil.logException(getFrType(), funraiseId, ex);
        }
        return result;
    }

    private void applyNPSPRecurringDonationDefaults(
        SObject recurringDonation,
        Map<String, Schema.SObjectField> npspFields,
        Map<String, Object> request,
        String funraiseId
    ) {
        writeRequestFieldIfExists(recurringDonation, npspFields, NPSP_RD_AMOUNT_FIELD_NAME, request, 'amount', funraiseId);
        writeRequestFieldIfExists(recurringDonation, npspFields, NPSP_RD_DATE_ESTABLISHED_FIELD_NAME, request, 'nextPaymentDate', funraiseId);
        writeRequestFieldIfExists(recurringDonation, npspFields, NPSP_RD_NEXT_PAYMENT_DATE_FIELD_NAME, request, 'nextPaymentDate', funraiseId);
        writeRequestFieldIfExists(recurringDonation, npspFields, NPSP_RD_START_DATE_FIELD_NAME, request, 'nextPaymentDate', funraiseId);
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_PAYMENT_METHOD_FIELD_NAME, getNPSPPaymentMethod(request.get('paymentMethodType')));
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_STATUS_FIELD_NAME, getNPSPStatus(request.get('status')));
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_RECURRING_TYPE_FIELD_NAME, 'Open');
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_INSTALLMENT_PERIOD_FIELD_NAME, getNPSPInstallmentPeriod(request.get('frequency')));
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_INSTALLMENT_FREQUENCY_FIELD_NAME, 1);
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_SCHEDULE_TYPE_FIELD_NAME, 'Multiply By');
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_OPEN_ENDED_STATUS_FIELD_NAME, 'Open');
        putFieldIfExists(recurringDonation, npspFields, NPSP_RD_DAY_OF_MONTH_FIELD_NAME, getNPSPDayOfMonth(request.get('nextPaymentDate')));
    }

    protected override Boolean requireObjectDeletePermission() {
        return true;
    }

    protected override List<frMapping__c> getMappings() {
        if (frUtil.hasNPCobjects()) {
            return [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Conflict_Resolution__c, Type__c FROM frMapping__c WHERE Type__c = 'Commitment' ORDER BY CreatedDate];
        } else if(frUtil.usesNPSPRecurringDonations()) {
            return [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Conflict_Resolution__c, Type__c FROM frMapping__c WHERE Type__c = :NPSP_RECURRING_DONATION_TYPE ORDER BY CreatedDate];
        } else {
            return new List<frMapping__c>(); // Subscription does not use mappings in non-NPC environments
        }
    }

    protected override Set<Schema.SObjectField> getFields() {
        if(frUtil.hasNPCobjects()) {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('giftcommitment').getDescribe().fields.getMap();
            Set<Schema.SObjectField> usedFields = new Set<Schema.SObjectField>();
            for(frMapping__c mapping : getMappings()) {
                if(fieldMap.containsKey(mapping.sf_Name__c)) {
                    usedFields.add(fieldMap.get(mapping.sf_Name__c));
                }
            }
            return usedFields;
        }
        else if(frUtil.usesNPSPRecurringDonations()) {
            return getNPSPRecurringDonationFields();
        }
        else{
            return new Set<Schema.SObjectField> {
                    Subscription__c.Name,
                    Subscription__c.fr_ID__c,
                    Subscription__c.Status__c,
                    Subscription__c.Supporter__c,
                    Subscription__c.Payment_Method_Expiration_Date__c,
                    Subscription__c.Payment_Method_Type__c,
                    Subscription__c.Payment_Method_Last_Four__c,
                    Subscription__c.Form_Name__c,
                    Subscription__c.Next_Payment_Date__c,
                    Subscription__c.Frequency__c,
                    Subscription__c.Amount__c,
                    Subscription__c.Currency__c,
                    Subscription__c.Campaign_Page_Name__c,
                    Subscription__c.Allocation_Name__c,
                    Subscription__c.Comment__c,
                    Subscription__c.Note__c,
                    Subscription__c.Dedication__c,
                    Subscription__c.Dedication_Type__c,
                    Subscription__c.Dedication_Name__c,
                    Subscription__c.Dedication_Email__c,
                    Subscription__c.Dedication_Message__c,
                    Subscription__c.Company_Match__c,
                    Subscription__c.Company_Match_Company_Name__c,
                    Subscription__c.Company_Match_Employee_Email__c,
                    Subscription__c.Operations_Tip__c,
                    Subscription__c.Imported__c,
                    Subscription__c.Campaign_Goal__c
            };
        }
    }

    protected override Set<Schema.SObjectType> getObjects() {
        if(frUtil.hasNPCobjects()) {
            return new Set<Schema.SObjectType> {
                Schema.getGlobalDescribe().get('giftcommitment')
            };
        }
        else if(frUtil.usesNPSPRecurringDonations()) {
            return new Set<Schema.SObjectType> {
                frUtil.getSObjectType(frUtil.NPSP_RECURRING_DONATION_OBJ_NAME)
            };
        }
        else {
            return new Set<Schema.SObjectType> {
                Subscription__c.SObjectType
            };
        }
    }

    protected override frUtil.Entity getFrType() {
        return frUtil.Entity.SUBSCRIPTION;
    }

    private Set<Schema.SObjectField> getNPSPRecurringDonationFields() {
        Map<String, Schema.SObjectField> npspFields = frUtil.getFields(frUtil.NPSP_RECURRING_DONATION_OBJ_NAME);
        Set<Schema.SObjectField> usedFields = new Set<Schema.SObjectField>();
        for(String fieldName : new Set<String>{
            'Name',
            frUtil.NPSP_RECURRING_DONATION_ID_FIELD_NAME,
            frUtil.NPSP_RECURRING_DONATION_CONTACT_FIELD_NAME,
            frUtil.NPSP_RECURRING_DONATION_CAMPAIGN_FIELD_NAME,
            NPSP_RD_AMOUNT_FIELD_NAME,
            NPSP_RD_DATE_ESTABLISHED_FIELD_NAME,
            NPSP_RD_DAY_OF_MONTH_FIELD_NAME,
            NPSP_RD_INSTALLMENT_FREQUENCY_FIELD_NAME,
            NPSP_RD_INSTALLMENT_PERIOD_FIELD_NAME,
            NPSP_RD_NEXT_PAYMENT_DATE_FIELD_NAME,
            NPSP_RD_OPEN_ENDED_STATUS_FIELD_NAME,
            NPSP_RD_PAYMENT_METHOD_FIELD_NAME,
            NPSP_RD_RECURRING_TYPE_FIELD_NAME,
            NPSP_RD_SCHEDULE_TYPE_FIELD_NAME,
            NPSP_RD_START_DATE_FIELD_NAME,
            NPSP_RD_STATUS_FIELD_NAME
        }) {
            Schema.SObjectField field = npspFields.get(fieldName);
            if(field != null && field.getDescribe().isCreateable()) {
                usedFields.add(field);
            }
        }
        for(frMapping__c mapping : getMappings()) {
            Schema.SObjectField field = npspFields.get(mapping.sf_Name__c);
            if(field != null) {
                usedFields.add(field);
            }
        }
        return usedFields;
    }

    private static void writeRequestFieldIfExists(
        SObject record,
        Map<String, Schema.SObjectField> fieldMap,
        String fieldName,
        Map<String, Object> request,
        String requestFieldName,
        String funraiseId
    ) {
        Schema.SObjectField field = fieldMap.get(fieldName);
        if(field != null && field.getDescribe().isCreateable() && request.containsKey(requestFieldName) && request.get(requestFieldName) != null) {
            frModel.write(record, field, fieldName, request.get(requestFieldName), funraiseId);
        }
    }

    private static void putStringFieldIfExists(
        SObject record,
        Map<String, Schema.SObjectField> fieldMap,
        String fieldName,
        String value
    ) {
        Schema.SObjectField field = fieldMap.get(fieldName);
        if(field != null && field.getDescribe().isCreateable()) {
            record.put(field, frUtil.truncateToFieldLength(field.getDescribe(), value));
        }
    }

    private static void putFieldIfExists(
        SObject record,
        Map<String, Schema.SObjectField> fieldMap,
        String fieldName,
        Object value
    ) {
        Schema.SObjectField field = fieldMap.get(fieldName);
        if(field != null && field.getDescribe().isCreateable() && value != null) {
            record.put(field, value);
        }
    }

    @TestVisible
    private static String getNPSPInstallmentPeriod(Object frequency) {
        String value = frequency != null ? String.valueOf(frequency).toLowerCase() : '';
        if(value.contains('week')) {
            return 'Weekly';
        }
        if(value.contains('year') || value.contains('annual')) {
            return 'Yearly';
        }
        if(value.contains('quarter')) {
            return 'Quarterly';
        }
        return 'Monthly';
    }

    @TestVisible
    private static String getNPSPStatus(Object status) {
        String value = status != null ? String.valueOf(status).toLowerCase() : '';
        if(value.contains('pause')) {
            return 'Lapsed';
        }
        if(value.contains('lapse')) {
            return 'Lapsed';
        }
        if(value.contains('cancel') || value.contains('closed') || value.contains('inactive')) {
            return 'Closed';
        }
        return 'Active';
    }

    @TestVisible
    private static String getNPSPPaymentMethod(Object paymentMethod) {
        String value = paymentMethod != null ? String.valueOf(paymentMethod).toLowerCase() : '';
        if(String.isBlank(value)) {
            return null;
        }
        if(value.contains('ach') || value.contains('bank')) {
            return 'ACH';
        }
        if(value.contains('check')) {
            return 'Check';
        }
        return 'Credit Card';
    }

    @TestVisible
    private static String getNPSPDayOfMonth(Object localDate) {
        if(localDate instanceof List<Object>) {
            List<Object> values = (List<Object>) localDate;
            if(values.size() >= 3 && values.get(2) != null) {
                return String.valueOf(values.get(2));
            }
        }
        return '15';
    }
}
