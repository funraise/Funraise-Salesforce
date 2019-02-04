public with sharing class frSetupController {
	public static String DONATION_TYPE {
		get {
			return frDonation.TYPE;
		}
		private set;
	}
	public static String DONOR_TYPE {
		get {
			return frDonor.TYPE;
		}
		private set;
	}
	public static String TAG_TYPE {
		get {
			return frModel.TAG_TYPE;
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

	public List<SelectOption> donationSFOptions {get; set;}
	public List<SelectOption> donationFROptions {get; set;}
	public List<frMapping__c> donationMappings {get; set;}

	public List<SelectOption> donorSFOptions {get; set;}
	public List<SelectOption> donorFROptions {get; set;}
	public List<frMapping__c> donorMappings {get; set;}

	public List<SelectOption> tagSFOptions {get; set;}
	public List<SelectOption> tagFROptions {get; set;}
	public List<frMapping__c> tagMappings {get; set;}

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
		tagSFOptions = new List<SelectOption>();
		tagSFOptions.add(noneOption);
		tagFROptions = new List<SelectOption>();
		tagFROptions.add(noneOption);

		Map<String, Schema.SObjectField> oppFields = Opportunity.sObjectType.getDescribe().fields.getMap();
		for(String fieldName : oppFields.keySet()) {
			if(RESTRICTED_DONATION_FIELDS.contains(fieldName)) continue; //skip any fields that are part of the managed package
			Schema.DescribeFieldResult describe = oppFields.get(fieldName).getDescribe();
			if(describe.isUpdateable()) {
				donationSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
			}
		}
		donationSFOptions.sort();
		for(frField__mdt field : [SELECT DeveloperName, MasterLabel FROM frField__mdt WHERE Type__c = :DONATION_TYPE ORDER BY MasterLabel]) {
			donationFROptions.add(new SelectOption(field.DeveloperName, field.MasterLabel));
		}


		Map<String, Schema.SObjectField> contactFields = Contact.sObjectType.getDescribe().fields.getMap();
		for(String fieldName : contactFields.keySet()) {
			if(RESTRICTED_DONOR_FIELDS.contains(fieldName)) continue; //skip any fields that are part of the managed package
			Schema.DescribeFieldResult describe = contactFields.get(fieldName).getDescribe();
			if(describe.isUpdateable()) {
				donorSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
			}
		}
		donorSFOptions.sort();
		for(frField__mdt field : [SELECT DeveloperName, MasterLabel FROM frField__mdt WHERE Type__c = :DONOR_TYPE ORDER BY MasterLabel]) {
			donorFROptions.add(new SelectOption(field.DeveloperName, field.MasterLabel));
		}

        for(ContactTag sfTag : [SELECT Name FROM ContactTag]){
            tagSFOptions.add(new SelectOption(sfTag.Name, sfTag.Name));
        }

		donationMappings = frDonation.mappings;
		donorMappings = frDonor.mappings;
        tagMappings = frModel.tagMappings;
	}

	public void addMapping() {
		String type = ApexPages.currentPage().getParameters().get('type');
		if(String.isBlank(type)) {
			return;
		}
		if(DONATION_TYPE.equals(type)) {
			donationMappings.add(new frMapping__c(Type__c = DONATION_TYPE));
		} else if(DONOR_TYPE.equals(type)){
			donorMappings.add(new frMapping__c(Type__c = DONOR_TYPE));
        } else {
            tagMappings.add(new frMapping__c(Type__c = TAG_TYPE));
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

		List<frMapping__c> mappings;
        if(DONATION_TYPE.equals(type)){
            mappings = donationMappings;
        } else if(DONOR_TYPE.equals(type)){
            mappings = donorMappings;
        } else {
            mappings = tagMappings;
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
        allMappings.addAll(tagMappings);
		for(frMapping__c mapping : allMappings) {
			if(String.isNotBlank(mapping.sf_Name__c)) {
                String prefix = '';

                if(DONATION_TYPE.equals(mapping.Type__c)){
                    prefix = 'o.';
                } else if(DONOR_TYPE.equals(mapping.Type__c)){
                    prefix = 'c.';
                } else if(TAG_TYPE.equals(mapping.Type__c)){
                    prefix = 't.';
                }

                mapping.Name = prefix + mapping.sf_Name__c;

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
		String retUrl = ApexPages.currentPage().getParameters().get('retURL');
		PageReference redirect = null;
		if(String.isNotBlank(retURL)) {
			try {
				redirect = new PageReference(retUrl);
			} catch (Exception ex) {/*swallow exception, url param was bad, not our problem*/}
		}
		if(redirect == null) {
			redirect = Page.frSetup;
			redirect.setRedirect(true);
		}
		return redirect;
	}

	private void addConfirm(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
	}

	private void addError(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
	}

	public void defaults() {
		if(!checkCD()) {
			return;
		}
		delete [SELECT Id FROM frMapping__c LIMIT 10000];
		List<frMapping__c> defaults = getDonorDefaults();
		defaults.addAll(getDonationDefaults());
		defaults.addAll(getTagDefaults());
		insert defaults;
		addConfirm('All Defaults Applied');
		donationMappings = frDonation.mappings;
		donorMappings = frDonor.mappings;
		tagMappings = frModel.tagMappings;
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

	public void tagDefaults() {
		if(!checkCD()) {
			return;
		}
		delete [SELECT Id FROM frMapping__c WHERE Type__c = :TAG_TYPE];
		List<frMapping__c> defaults = getTagDefaults();
		insert defaults;
		addConfirm('Tag Defaults Applied');
		tagMappings = frModel.tagMappings;
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
			new frMapping__c(Name = 'Country Default', fr_Name__c = 'country', sf_Name__c = 'mailingcountry', Type__c = DONOR_TYPE),
			new frMapping__c(Name = 'Fundraiser Default', fr_Name__c = 'fundraiser', sf_Name__c = 'funraise__is_fundraiser__c', Type__c = DONOR_TYPE)
		};
	}

	@testVisible
	private static List<frMapping__c> getDonationDefaults() {
		return new List<frMapping__c>{
			new frMapping__c(Name = 'Amount Default', fr_Name__c = 'amount', sf_Name__c = 'amount', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Donation Name Default', fr_Name__c = 'name', sf_Name__c = 'name', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Created Date Default', fr_Name__c = 'donation_cretime', sf_Name__c = 'closedate', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Stage Default', Is_Constant__c = true, Constant_Value__c = 'Closed Won', sf_Name__c = 'stagename', Type__c = DONATION_TYPE),
			new frMapping__c(Name = 'Probability Default', Is_Constant__c = true, Constant_Value__c = '100', sf_Name__c = 'probability', Type__c = DONATION_TYPE)
		};
	}

	@testVisible
	private static List<frMapping__c> getTagDefaults() {
		return new List<frMapping__c>{};
	}

}
