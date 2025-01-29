@isTest
public class frSetupControllerTest {
	static testMethod void test_availableMappings() {
		if (frUtil.hasNPCobjects()) return;

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

	static testMethod void test_availableMappings_NPC() {
		if (!frUtil.hasNPCobjects()) return;

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

	static testMethod void test_addMapping_constant() {
		Test.startTest();
		frSetupController controller = new frSetupController();
		ApexPages.currentPage().getParameters().put('type', frSetupController.DONATION_TYPE);
		controller.addMapping();
		Integer actualDonationMappingCountAfterAdd = controller.donationMappings.size();
		frMapping__c donationMapping = controller.donationMappings.get(0);
		donationMapping.sf_Name__c = 'TestSFDonation';
		donationMapping.Is_Constant__c = true;
		donationMapping.Constant_Value__c = 'Test Constant';
		controller.save();
		Test.stopTest();

		System.assertEquals(1, actualDonationMappingCountAfterAdd, 'Only one mapping was added, so only one mapping should exist');
		System.assertEquals(1, [SELECT COUNT() FROM frMapping__c WHERE Is_Constant__c = true AND Constant_Value__c = :donationMapping.Constant_Value__c], 'Only one mapping was added, so only one mapping should exist');
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

	static testMethod void test_cancel() {
		Test.startTest();
		frSetupController controller = new frSetupController();

		//add some mappings but don't save them to ensure cancelling will not save changes
		ApexPages.currentPage().getParameters().put('type', frSetupController.DONATION_TYPE);
		controller.addMapping();
		frMapping__c donationMapping = controller.donationMappings.get(0);
		donationMapping.fr_Name__c = 'TestFRDonation';
		donationMapping.sf_Name__c = 'TestSFDonation';
        PageReference actualCancelWithNoRetUrl = controller.cancel();

		Test.stopTest();

		PageReference expectedCancel = Page.frSetup;
		System.assertEquals(expectedCancel.getUrl(), actualCancelWithNoRetUrl.getUrl(), 'Cancel did not redirect as expected');
        System.assertEquals(0, [SELECT COUNT() FROM frMapping__c], 'No mappings should have been saved while cancelling');

	}

	static testMethod void test_defaults() {
		if (frUtil.hasNPCobjects()) return;

		insert new frMapping__c(Type__c = frDonation.TYPE, fr_Name__c = 'testfr', sf_Name__c = 'testsf', Name = 'Test Mapping');
		Integer beforeTestMappingCount = [SELECT COUNT() FROM frMapping__c];

		frSetupController controller = new frSetupController();
		Test.startTest();
		controller.defaults();
		Integer afterDefaultMappingCount = [SELECT COUNT() FROM frMapping__c WHERE fr_Name__c = 'testfr'];
		List<frMapping__c> actualDonorMappings = [SELECT Name FROM frMapping__c WHERE Type__c = :frDonor.TYPE];
		List<frMapping__c> actualDonationMappings = [SELECT Name FROM frMapping__c WHERE Type__c = :frDonation.TYPE];
		Test.stopTest();

		System.assertEquals(1, beforeTestMappingCount, 'There should have been 1 mapping record before the test started');
		System.assertEquals(0, afterDefaultMappingCount, 'There should have not been any mappings that had the test data value when using the defaults');
		assertMappingsEqual(frSetupController.getDonorDefaults(), actualDonorMappings);
		assertMappingsEqual(frSetupController.getDonationDefaults(), actualDonationMappings);
	}

	static testMethod void test_defaults_NPC() {
		if (!frUtil.hasNPCobjects()) return;

		insert new frMapping__c(Type__c = frDonation.TYPE, fr_Name__c = 'testfr', sf_Name__c = 'testsf', Name = 'Test Mapping');
		Integer beforeTestMappingCount = [SELECT COUNT() FROM frMapping__c];

		frSetupController controller = new frSetupController();
		Test.startTest();
		controller.defaults();
		Integer afterDefaultMappingCount = [SELECT COUNT() FROM frMapping__c WHERE fr_Name__c = 'testfr'];
		List<frMapping__c> actualDonorMappings = [SELECT Name FROM frMapping__c WHERE Type__c = :frDonor.TYPE];
		List<frMapping__c> actualDonationMappings = [SELECT Name FROM frMapping__c WHERE Type__c = :frDonation.TYPE];
		Test.stopTest();

		System.assertEquals(1, beforeTestMappingCount, 'There should have been 1 mapping record before the test started');
		System.assertEquals(0, afterDefaultMappingCount, 'There should have not been any mappings that had the test data value when using the defaults');
		assertMappingsEqual(frSetupController.getPersonAccountDefaults(), [SELECT Name FROM frMapping__c WHERE Type__c = :frDonor.TYPE]);
		assertMappingsEqual(frSetupController.getGiftTransactionDefaults(), [SELECT Name FROM frMapping__c WHERE Type__c = :frDonation.TYPE]);
	}

	static testMethod void test_defaults_donorOnly() {
		insert new frMapping__c(Type__c = frDonor.TYPE, fr_Name__c = 'testfr', sf_Name__c = 'testsf', Name = 'Test Mapping');
		Integer beforeTestMappingCount = [SELECT COUNT() FROM frMapping__c];

		frSetupController controller = new frSetupController();
		Test.startTest();
		controller.donorDefaults();
		Integer afterDefaultMappingCount = [SELECT COUNT() FROM frMapping__c WHERE fr_Name__c = 'testfr'];
		List<frMapping__c> actualDonorMappings = [SELECT Name FROM frMapping__c WHERE Type__c = :frDonor.TYPE];
		Test.stopTest();

		System.assertEquals(1, beforeTestMappingCount, 'There should have been 1 mapping record before the test started');
		System.assertEquals(0, afterDefaultMappingCount, 'There should have not been any mappings that had the test data value when using the defaults');
		assertMappingsEqual(frSetupController.getDonorDefaults(), actualDonorMappings);
	}

	static testMethod void test_defaults_donationOnly() {
		insert new frMapping__c(Type__c = frDonation.TYPE, fr_Name__c = 'testfr', sf_Name__c = 'testsf', Name = 'Test Mapping');
		Integer beforeTestMappingCount = [SELECT COUNT() FROM frMapping__c];

		frSetupController controller = new frSetupController();
		Test.startTest();
		controller.donationDefaults();
		Integer afterDefaultMappingCount = [SELECT COUNT() FROM frMapping__c WHERE fr_Name__c = 'testfr'];
		List<frMapping__c> actualDonationMappings = [SELECT Name FROM frMapping__c WHERE Type__c = :frDonation.TYPE];
		Test.stopTest();

		System.assertEquals(1, beforeTestMappingCount, 'There should have been 1 mapping record before the test started');
		System.assertEquals(0, afterDefaultMappingCount, 'There should have not been any mappings that had the test data value when using the defaults');
		assertMappingsEqual(frSetupController.getDonationDefaults(), actualDonationMappings);
	}

	private static void assertMappingsEqual(List<frMapping__c> expected, List<frMapping__c> actual) {
		Set<String> expectedMappingNames = new Set<String>();
		for(frMapping__c mapping : expected) {
			expectedMappingNames.add(mapping.Name);
		}
		Set<String> actualMappingNames = new Set<String>();
		for(frMapping__c mapping : actual) {
			actualMappingNames.add(mapping.Name);
		}
		System.assertEquals(expectedMappingNames, actualMappingNames, 'The mappings did not match their expected values');
	}

	private static void assertValuesInList(Set<String> expectedValues, List<SelectOption> options) {
		Set<String> actualValues = new Set<String>();
		for(SelectOption option : options) {
			actualValues.add(option.getValue());
		}
		//remove empty string from controller values since we don't care about the --None-- option
		actualValues.remove('');
		actualValues.remove('id');
		System.assertEquals(expectedValues, actualValues, 'The fields in the metadata setting and the fields available in the controller do not match');
	}
}