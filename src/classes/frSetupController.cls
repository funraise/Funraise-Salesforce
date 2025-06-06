public with sharing class frSetupController {
	public static String DONATION_TYPE {
		get {
			return frDonation.TYPE;
		}
		private set;
	}
	public static String GIFT_COMMITMENT_TYPE {
		get {
			return 'Commitment';
		}
		private set;
	}
	public static String DONOR_TYPE {
		get {
			return frDonor.TYPE;
		}
		private set;
	}
    
    public static Set<String> RESTRICTED_DONOR_FIELDS {
        get {
            if(RESTRICTED_DONOR_FIELDS == null) {
                RESTRICTED_DONOR_FIELDS = new Set<String>{
                    'funraise__fr_ID__c'
                };
            }
            return RESTRICTED_DONOR_FIELDS;
        }
        private set;
    }
    
    public static Set<String> RESTRICTED_DONATION_FIELDS {
        get {
            if(RESTRICTED_DONATION_FIELDS == null) {
                RESTRICTED_DONATION_FIELDS = new Set<String>{
                    'funraise__fr_ID__c', 
                    'funraise__fr_Donor__c'
                };
            }
            return RESTRICTED_DONATION_FIELDS;
        }
        private set;
    }
    
    public static String MAPPING_OVERWRITE {
        get {
            return frModel.MAPPING_OVERWRITE;
        }
        private set;
    }
    public static String MAPPING_NO_OVERWRITE {
        get {
            return frModel.MAPPING_NO_OVERWRITE;
        }
        private set;
    }
    public static String MAPPING_OVERWRITE_NON_NULL {
        get {
            return frModel.MAPPING_OVERWRITE_NON_NULL;
        }
        private set;
    }
    public static String MAPPING_OVERWRITE_RECENT  {
        get {
            return frModel.MAPPING_OVERWRITE_RECENT;
        }
        private set;
    }

	public List<SelectOption> donationSFOptions {get; set;}
	public List<SelectOption> donationFROptions {get; set;}
	public List<frMapping__c> donationMappings {get; set;}

	public List<SelectOption> donorSFOptions {get; set;}
	public List<SelectOption> donorFROptions {get; set;}
	public List<frMapping__c> donorMappings {get; set;}

	public List<SelectOption> giftCommitmentSFOptions {get; set;}
	public List<SelectOption> giftCommitmentFROptions {get; set;}
	public List<frMapping__c> giftCommitmentMappings {get; set;}

	public Boolean personAccountsEnabled { get; set; }
	public Boolean isNonProfitOrg { get; set; }
	
	public frSetupController() {
		SelectOption noneOption = new SelectOption('', '--None--');
		donationSFOptions = new List<SelectOption>();
		donationSFOptions.add(noneOption);
		donationFROptions = new List<SelectOption>();
		donationFROptions.add(noneOption);
		donorSFOptions = new List<SelectOption>();
		donorSFOptions.add(noneOption);
		donorFROptions = new List<SelectOption>();
		donorFROptions.add(noneOption);
		giftCommitmentSFOptions = new List<SelectOption>();
		giftCommitmentSFOptions.add(noneOption);
		giftCommitmentFROptions = new List<SelectOption>();
		giftCommitmentFROptions.add(noneOption);
		personAccountsEnabled = false;
		isNonProfitOrg = false;

		//Check for personaccount field on account
        SObjectType accountType = Account.SObjectType;
        if (frUtil.hasNPCobjects()) {
            personAccountsEnabled = true;
			Map<String, Schema.SObjectField> personAccountFields = Account.sObjectType.getDescribe().fields.getMap();
			for(String fieldName : personAccountFields.keySet()) {
				Schema.DescribeFieldResult describe = personAccountFields.get(fieldName).getDescribe();
				if(describe.isUpdateable()) {
					donorSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
				}
			}
			donorSFOptions.sort();
        }
		//Check for GiftTransaction to see if its a NPC Org
		if (frUtil.hasNPCobjects()) {
			isNonProfitOrg = true;
			Map<String, Schema.SObjectField> giftTransactionFields = Schema.getGlobalDescribe().get('gifttransaction').getDescribe().fields.getMap();
			for(String fieldName : giftTransactionFields.keySet()) {
				Schema.DescribeFieldResult describe = giftTransactionFields.get(fieldName).getDescribe();
				if(describe.isUpdateable()) {
					donationSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
				}
			}
			donationSFOptions.sort();

			// gift commitments
			Map<String, Schema.SObjectField> GiftCommitmentFields = Schema.getGlobalDescribe().get('giftcommitment').getDescribe().fields.getMap();
			for(String fieldName : GiftCommitmentFields.keySet()) {
				Schema.DescribeFieldResult describe = GiftCommitmentFields.get(fieldName).getDescribe();
				if(describe.isUpdateable()) {
					giftCommitmentSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
				}
			}
			giftCommitmentSFOptions.sort();

			for(frField__mdt field : [SELECT DeveloperName, MasterLabel FROM frField__mdt WHERE Type__c = :GIFT_COMMITMENT_TYPE ORDER BY MasterLabel]) {
				giftCommitmentFROptions.add(new SelectOption(field.DeveloperName.removeEnd('_GC'), field.MasterLabel));
			}
		}

		if (!frUtil.hasNPCobjects()) {
			Map<String, Schema.SObjectField> oppFields = Opportunity.sObjectType.getDescribe().fields.getMap();
			for(String fieldName : oppFields.keySet()) {
				if(RESTRICTED_DONATION_FIELDS.contains(fieldName)) continue; //skip any fields that are part of the managed package
				Schema.DescribeFieldResult describe = oppFields.get(fieldName).getDescribe();
				if(describe.isUpdateable()) {
					donationSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
				}
			}
			donationSFOptions.sort();
		}
		for(frField__mdt field : [SELECT DeveloperName, MasterLabel FROM frField__mdt WHERE Type__c = 'Donation' ORDER BY MasterLabel]) {
			donationFROptions.add(new SelectOption(field.DeveloperName, field.MasterLabel));
		}

		if (!frUtil.hasNPCobjects()) {
			Map<String, Schema.SObjectField> contactFields = Contact.sObjectType.getDescribe().fields.getMap();
			for(String fieldName : contactFields.keySet()) {
				if(RESTRICTED_DONOR_FIELDS.contains(fieldName)) continue; //skip any fields that are part of the managed package
				Schema.DescribeFieldResult describe = contactFields.get(fieldName).getDescribe();
				if(describe.isUpdateable()) {
					donorSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
				}
			}
			donorSFOptions.sort();
		}
		
		for(frField__mdt field : [SELECT DeveloperName, MasterLabel FROM frField__mdt WHERE Type__c = 'Donor' ORDER BY MasterLabel]) {
			donorFROptions.add(new SelectOption(field.DeveloperName, field.MasterLabel));
		}
        
		donationMappings = frDonation.mappings;
		donorMappings = frDonor.mappings;
		giftCommitmentMappings = [SELECT fr_Name__c, sf_Name__c, Is_Constant__c, Constant_Value__c, Conflict_Resolution__c, Type__c FROM frMapping__c WHERE Type__c = :GIFT_COMMITMENT_TYPE ORDER BY CreatedDate];
	}

	public void addMapping() {
		String type = ApexPages.currentPage().getParameters().get('type');
		if(String.isBlank(type)) {
			return;
		}
		if(GIFT_COMMITMENT_TYPE.equals(type)) {			
			giftCommitmentMappings.add(new frMapping__c(Type__c = GIFT_COMMITMENT_TYPE));
		}
		else if(DONATION_TYPE.equals(type)) {
			donationMappings.add(new frMapping__c(Type__c = DONATION_TYPE));
		}
		else {
			donorMappings.add(new frMapping__c(Type__c = DONOR_TYPE));
        }
	}

	public void removeMapping() {
		if(!frMapping__c.sObjectType.getDescribe().isDeletable()) {
			addError('You do not have permission to delete mappings');
		}

		String type = ApexPages.currentPage().getParameters().get('type');
		String recordId = ApexPages.currentPage().getParameters().get('id');
		if(String.isBlank(type) || String.isBlank(recordId)) {
			return;
		}

		List<frMapping__c> mappings = DONATION_TYPE.equals(type) ? donationMappings : donorMappings;
		if (GIFT_COMMITMENT_TYPE.equals(type)) {
			mappings = giftCommitmentMappings;
		}
		for(Integer i = 0; i < mappings.size(); i++) {
			frMapping__c mapping = mappings.get(i);
			if(recordId.equals(mapping.id)) {
				mappings.remove(i);
				delete mapping;
				addConfirm('Mapping removed');
				return;
			}
		}
	}
    
	public void save() {
        if (!Schema.sObjectType.frMapping__c.fields.Name.isUpdateable() ||
           !Schema.sObjectType.frMapping__c.fields.Name.isCreateable()) {
            return;
        }
        
		Integer customSettingNameLength = frMapping__c.Name.getDescribe().getLength();
		List<frMapping__c> upsertList = new List<frMapping__c>();
		List<frMapping__c> allMappings = new List<frMapping__c>(donationMappings);
		allMappings.addAll(donorMappings);
		allMappings.addAll(giftCommitmentMappings);
		for(frMapping__c mapping : allMappings) {
			if(String.isNotBlank(mapping.sf_Name__c)) {
				if(mapping.Type__c == DONATION_TYPE) mapping.Name = 'o.' + mapping.sf_Name__c;
				if(mapping.Type__c == DONOR_TYPE) mapping.Name = 'c.' + mapping.sf_Name__c;
				if(mapping.Type__c == GIFT_COMMITMENT_TYPE) mapping.Name = 's.' + mapping.sf_Name__c;
				if(mapping.Name.length() > customSettingNameLength) {
					mapping.Name = mapping.Name.subString(0, customSettingNameLength);
				}
				upsertList.add(mapping);
			}
		}

		Schema.DescribeSObjectResult describe = frMapping__c.sObjectType.getDescribe();
		if(upsertList.size() > 0 && describe.isCreateable() && describe.isUpdateable()) {
			upsert upsertList;
			addConfirm('Mappings saved successfully');
		}
	}

	public PageReference cancel() {
		PageReference redirect = Page.frSetup;
        redirect.setRedirect(true);
		return redirect;
	}

	private static void addConfirm(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
	}

	private static void addError(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));	
	}

	public void defaults() {
		if(!checkCD()) {
			return;
		}
		delete [SELECT Id FROM frMapping__c LIMIT 10000];
		List<frMapping__c> defaults;
		if(!frUtil.hasNPCobjects()) {
			defaults = getDonorDefaults();
			defaults.addAll(getDonationDefaults());
		} 
		else {
			defaults = getGiftTransactionDefaults();
			defaults.addAll(getPersonAccountDefaults());
		}
		insert defaults;
		addConfirm('All Defaults Applied');
		donationMappings = frDonation.mappings;
		donorMappings = frDonor.mappings;
	}

	public void donorDefaults() {
		if(!checkCD()) {
			return;
		}
		delete [SELECT Id FROM frMapping__c WHERE Type__c = :DONOR_TYPE];
		List<frMapping__c> defaults = getDonorDefaults();
		insert defaults;
		addConfirm('Donor Defaults Applied');
		donorMappings = frDonor.mappings;
	}

	public void donationDefaults() {
		if(!checkCD()) {
			return;
		}
		delete [SELECT Id FROM frMapping__c WHERE Type__c = :DONATION_TYPE];
		List<frMapping__c> defaults = getDonationDefaults();
		insert defaults;
		addConfirm('Donation Defaults Applied');
		donationMappings = frDonation.mappings;
	}

	private Boolean checkCD() {
		Schema.DescribeSObjectResult mappingDescribe = frMapping__c.sObjectType.getDescribe();
		if(mappingDescribe.isCreateable() && mappingDescribe.isDeletable()) {
			return true;
		} else {
			addError('Mappings not saved.  You must have at least one mapping and permissions to use the mapping object');
			return false;
		}
	}

	@testVisible
	private static List<frMapping__c> getDonorDefaults() {
		return new List<frMapping__c>{
			new frMapping__c(Name = 'Email Default', fr_Name__c = 'email', sf_Name__c = 'email', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'First Name Default', fr_Name__c = 'firstName', sf_Name__c = 'firstname', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Last Name Default', fr_Name__c = 'lastName', sf_Name__c = 'lastname', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Address Default', fr_Name__c = 'address1', sf_Name__c = 'mailingstreet', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'City Default', fr_Name__c = 'city', sf_Name__c = 'mailingcity', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'State Default', fr_Name__c = 'state', sf_Name__c = 'mailingstate', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Postal Code Default', fr_Name__c = 'postalCode', sf_Name__c = 'mailingpostalcode', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Country Default', fr_Name__c = 'country', sf_Name__c = 'mailingcountry', Type__c = DONOR_TYPE)
		};
	}

	@testVisible
	private static List<frMapping__c> getDonationDefaults() {
		return new List<frMapping__c>{
			new frMapping__c(Name = 'Amount Default', fr_Name__c = 'amount', sf_Name__c = 'amount', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Donation Name Default', fr_Name__c = 'name', sf_Name__c = 'name', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Created Date Default', fr_Name__c = 'donation_cretime', sf_Name__c = 'closedate', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Probability Default', Is_Constant__c = true, Constant_Value__c = '100', sf_Name__c = 'probability', Type__c = DONATION_TYPE)
		};
	}

	@testVisible
	private static List<frMapping__c> getGiftTransactionDefaults() {
		return new List<frMapping__c>{
			new frMapping__c(Name = 'Donation Name Default', fr_Name__c = 'name', sf_Name__c = 'name', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Amount Default', fr_Name__c = 'amount', sf_Name__c = 'originalamount', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Payment Method Default', fr_Name__c = 'paymentMethodType', sf_Name__c = 'paymentmethod', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Acknowledgement Date Default', fr_Name__c = 'donation_cretime', sf_Name__c = 'acknowledgementdate', Type__c = DONATION_TYPE)
		};
	}

	@testVisible
	private static List<frMapping__c> getPersonAccountDefaults() {
		return new List<frMapping__c>{
			new frMapping__c(Name = 'Email Default', fr_Name__c = 'email', sf_Name__c = 'personEmail', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'First Name Default', fr_Name__c = 'firstName', sf_Name__c = 'firstname', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Last Name Default', fr_Name__c = 'lastName', sf_Name__c = 'lastname', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Address Default', fr_Name__c = 'address1', sf_Name__c = 'personmailingstreet', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'City Default', fr_Name__c = 'city', sf_Name__c = 'personmailingcity', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'State Default', fr_Name__c = 'state', sf_Name__c = 'personmailingstate', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Postal Code Default', fr_Name__c = 'postalCode', sf_Name__c = 'personmailingpostalcode', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Country Default', fr_Name__c = 'country', sf_Name__c = 'personmailingcountry', Type__c = DONOR_TYPE)
		};
	}
}