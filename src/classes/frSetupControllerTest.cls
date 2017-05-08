@IsTest
public class frSetupControllerTest {
	static testMethod void test_availableMappings() {
		//get the donor and donation custom metadata fields, assert that those are the same ones that controller provides
		Set<String> expectedDonorFieldNames = new Set<String>();
		Set<String> expectedDonationFieldNames = new Set<String>();
		for(frField__mdt field : [SELECT DeveloperName, Type__c FROM frField__mdt]) {
			if(frDonor.TYPE.equals(field.Type__c)) {
				expectedDonorFieldNames.add(field.DeveloperName);
			} else if(frDonation.TYPE.equals(field.Type__c)) {
				expectedDonationFieldNames.add(field.DeveloperName);
			}
		}

		Test.startTest();
		frSetupController controller = new frSetupController();
		Test.stopTest();

		assertValuesInList(expectedDonorFieldNames, controller.donorFROptions);
		assertValuesInList(expectedDonationFieldNames, controller.donationFROptions);
	}

	static testMethod void test_addMapping() {
		Test.startTest();
		frSetupController controller = new frSetupController();
		ApexPages.currentPage().getParameters().put('type', frSetupController.DONATION_TYPE);
		controller.addMapping();
		Integer actualDonationMappingCountAfterAdd = controller.donationMappings.size();
		frMapping__c donationMapping = controller.donationMappings.get(0);
		donationMapping.fr_Name__c = 'TestFRDonation';
		donationMapping.sf_Name__c = 'TestSFDonation';

		ApexPages.currentPage().getParameters().put('type', frSetupController.DONOR_TYPE);
		controller.addMapping();
		Integer actualDonorMappingCountAfterAdd = controller.donorMappings.size();
		frMapping__c donorMapping = controller.donorMappings.get(0);
		donorMapping.fr_Name__c = 'TestFRDonor';
		donorMapping.sf_Name__c = 'TestSFDonor';

		controller.save();
		Test.stopTest();

		System.assertEquals(1, actualDonationMappingCountAfterAdd, 'Only one mapping was added, so only one mapping should exist');
		System.assertEquals(1, actualDonorMappingCountAfterAdd, 'Only one mapping was added, so only one mapping should exist');
		System.assertEquals(2, [SELECT COUNT() FROM frMapping__c], 'Only one mapping was added, so only one mapping should exist');
		System.assertEquals(frSetupController.DONATION_TYPE, donationMapping.Type__c, 'The mapping added first should have a donation type');
		System.assertEquals(frSetupController.DONOR_TYPE, donorMapping.Type__c, 'The mapping added second should have a donor type');
	}

	static testMethod void test_removeMapping() {
		Test.startTest();
		frSetupController controller = new frSetupController();
		ApexPages.currentPage().getParameters().put('type', frSetupController.DONATION_TYPE);
		controller.addMapping();
		frMapping__c donationMapping = controller.donationMappings.get(0);
		donationMapping.fr_Name__c = 'TestFRDonation';
		donationMapping.sf_Name__c = 'TestSFDonation';
		controller.save();
		Integer countAfterSave = [SELECT COUNT() FROM frMapping__c];

		ApexPages.currentPage().getParameters().put('type', frSetupController.DONATION_TYPE);
		ApexPages.currentPage().getParameters().put('id', donationMapping.Id);
		controller.removeMapping();
		Integer countAfterRemove = [SELECT COUNT() FROM frMapping__c];
		Test.stopTest();

		System.assertEquals(1, countAfterSave, 'The record should have been saved without errors');
		System.assertEquals(0, countAfterRemove, 'The record should have been removed without errors');
	}

	static testMethod void test_cancel_validReturnUrl() {
		Test.startTest();
		frSetupController controller = new frSetupController();
		ApexPages.currentPage().getParameters().put('retURL', EncodingUtil.urlEncode('funraise.io', 'UTF-8'));

		//add some mappings but don't save them to ensure cancelling will not save changes
		ApexPages.currentPage().getParameters().put('type', frSetupController.DONATION_TYPE);
		controller.addMapping();
		frMapping__c donationMapping = controller.donationMappings.get(0);
		donationMapping.fr_Name__c = 'TestFRDonation';
		donationMapping.sf_Name__c = 'TestSFDonation';

		PageReference actualCancel = controller.cancel();
		Test.stopTest();

		System.assertEquals('funraise.io', actualCancel.getUrl());
		System.assertEquals(0, [SELECT COUNT() FROM frMapping__c]);
	}

	static testMethod void test_cancel_invalidReturnUrl() {
		Test.startTest();
		frSetupController controller = new frSetupController();

		//try with no url param
		PageReference actualCancelWithNoRetUrl = controller.cancel();

		Test.stopTest();

		PageReference expectedCancel = Page.frSetup;
		System.assertEquals(expectedCancel.getUrl(), actualCancelWithNoRetUrl.getUrl(), 'Cancel did not redirect as expected');
	}

	private static void assertValuesInList(Set<String> expectedValues, List<SelectOption> options) {
		Set<String> actualValues = new Set<String>();
		for(SelectOption option : options) {
			actualValues.add(option.getValue());
		}
		//remove empty string from controller values since we don't care about the --None-- option
		actualValues.remove('');
		System.assertEquals(expectedValues, actualValues, 'The fields in the metadata setting and the fields available in the controller do not match');
	}
}