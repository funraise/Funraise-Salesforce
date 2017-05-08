public class frSetupController {
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

	public List<SelectOption> donationSFOptions {get; set;}
	public List<SelectOption> donationFROptions {get; set;}
	public List<frMapping__c> donationMappings {get; set;}

	public List<SelectOption> donorSFOptions {get; set;}
	public List<SelectOption> donorFROptions {get; set;}
	public List<frMapping__c> donorMappings {get; set;}
	
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

		Map<String, Schema.SObjectField> oppFields = Opportunity.sObjectType.getDescribe().fields.getMap();
		for(String fieldName : oppFields.keySet()) {
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
			Schema.DescribeFieldResult describe = contactFields.get(fieldName).getDescribe();
			if(describe.isUpdateable()) {
				donorSFOptions.add(new SelectOption(fieldName, describe.getLabel()));
			}
		}
		donorSFOptions.sort();
		for(frField__mdt field : [SELECT DeveloperName, MasterLabel FROM frField__mdt WHERE Type__c = :DONOR_TYPE ORDER BY MasterLabel]) {
			donorFROptions.add(new SelectOption(field.DeveloperName, field.MasterLabel));
		}

		donationMappings = frDonation.mappings;
		donorMappings = frDonor.mappings;
	}

	public void addMapping() {
		String type = ApexPages.currentPage().getParameters().get('type');
		if(String.isBlank(type)) {
			return;
		}
		if(DONATION_TYPE.equals(type)) {			
			donationMappings.add(new frMapping__c(Type__c = DONATION_TYPE));
		} else {
			donorMappings.add(new frMapping__c(Type__c = DONOR_TYPE));
		}
	}

	public void removeMapping() {
		String type = ApexPages.currentPage().getParameters().get('type');
		String recordId = ApexPages.currentPage().getParameters().get('id');
		if(String.isBlank(type) || String.isBlank(recordId)) {
			return;
		}

		List<frMapping__c> mappings = DONATION_TYPE.equals(type) ? donationMappings : donorMappings;
		for(frMapping__c mapping : mappings) {
			if(recordId.equals(mapping.id)) {
				delete mapping;
				return;
			}
		}
	}

	public void save() {
		List<frMapping__c> upsertList = new List<frMapping__c>();
		List<frMapping__c> allMappings = new List<frMapping__c>(donationMappings);
		allMappings.addAll(donorMappings);
		for(frMapping__c mapping : allMappings) {
			if(String.isNotBlank(mapping.fr_Name__c) && String.isNotBlank(mapping.sf_Name__c)) {
				mapping.Name = mapping.fr_Name__c + ' -> ' + mapping.sf_Name__c;
				upsertList.add(mapping);
			}
		}
		upsert upsertList;
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

}