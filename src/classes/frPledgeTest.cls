@IsTest
public class frPledgeTest {

    @IsTest
    static void syncEntity_createPledge() {
        if (frUtil.hasNPCobjects()) {
            return;
        }

        Contact testSupporter = frDonorTest.getTestContact();
        String funraiseId = 'pl-25';
        Map<String, Object> request = getTestRequest();
        request.put('commitmentId', funraiseId);
        request.put('supporterId', testSupporter.fr_ID__c);

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSPledgeController.syncEntity();
        Test.stopTest();

        Pledge__c pledge = [
            SELECT Id, Name, fr_ID__c, Pledge_Amount__c, Received_Amount__c, End_Date__c, Supporter__c
            FROM Pledge__c
            WHERE fr_ID__c = :funraiseId
        ];
        System.assertEquals('Commitment - 000123', pledge.Name, 'The pledge should use the default name');
        System.assertEquals(Decimal.valueOf(String.valueOf(request.get('amount'))), pledge.Pledge_Amount__c, 'The pledge amount should match the request');
        System.assertEquals(Decimal.valueOf(String.valueOf(request.get('totalDonationAmount'))), pledge.Received_Amount__c, 'The pledge total should match the request');
        System.assertEquals(frModel.convertFromLocalDate((List<Object>) request.get('collectDate')), pledge.End_Date__c, 'The pledge end date should match the request');
        System.assertEquals(testSupporter.Id, pledge.Supporter__c, 'The pledge should be related to the matching supporter');
        frTestUtil.assertNoErrors();
    }

    @IsTest
    static void syncEntity_createPledge_withCampaign() {
        Campaign testCampaign = new Campaign(
            fr_ID__c = 'goal-10',
            Name = 'Test Campaign',
            ExpectedRevenue = 123,
            Description = 'Test',
            Status = 'Published'
        );
        insert testCampaign;

        Map<String, Object> request = getTestRequest();
        request.put('commitmentId', 'pl-campaign');
        request.put('goalId', testCampaign.fr_ID__c);

        if (frUtil.hasNPCobjects()) {
            Account testAccount = frDonorTest.getTestAccount(true);
            request.put('supporterId', testAccount.fr_ID__c);
        } else {
            Contact testSupporter = frDonorTest.getTestContact();
            request.put('supporterId', testSupporter.fr_ID__c);
        }

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSPledgeController.syncEntity();
        Test.stopTest();

        String funraiseId = String.valueOf(request.get('commitmentId'));
        Pledge__c pledge = [SELECT Id, Campaign_Page__c FROM Pledge__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(testCampaign.Id, pledge.Campaign_Page__c, 'The pledge should be associated with the matching campaign');
        frTestUtil.assertNoErrors();
    }

    @IsTest
    static void syncEntity_missingSupporter() {
        String funraiseId = 'pl-missing-supporter';
        Map<String, Object> request = getTestRequest();
        request.put('commitmentId', funraiseId);
        request.put('supporterId', 'missing-supporter-id');

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSPledgeController.syncEntity();
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Pledge__c WHERE fr_ID__c = :funraiseId], 'The pledge should not be created when the supporter does not exist');
        System.assertEquals(1, [SELECT COUNT() FROM Sync_Attempt__c], 'The sync should be retried later when the supporter is missing');
    }

    @IsTest
    static void syncEntity_missingCampaign() {
        Map<String, Object> request = getTestRequest();
        request.put('commitmentId', 'pl-missing-campaign');
        request.put('goalId', 'missing-goal-id');

        if (frUtil.hasNPCobjects()) {
            Account testAccount = frDonorTest.getTestAccount(true);
            request.put('supporterId', testAccount.fr_ID__c);
        } else {
            Contact testSupporter = frDonorTest.getTestContact();
            request.put('supporterId', testSupporter.fr_ID__c);
        }

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSPledgeController.syncEntity();
        Test.stopTest();

        String funraiseId = String.valueOf(request.get('commitmentId'));
        Pledge__c pledge = [SELECT Id, Campaign_Page__c FROM Pledge__c WHERE fr_ID__c = :funraiseId];
        System.assertEquals(null, pledge.Campaign_Page__c, 'The pledge should still be created when the campaign is missing');
        System.assertEquals(1, [SELECT COUNT() FROM Error__c], 'A relationship error should be recorded for the missing campaign');
        System.assertEquals(0, [SELECT COUNT() FROM Sync_Attempt__c], 'A missing campaign should not trigger a retry');
    }

    @IsTest
    static void syncEntity_deletePledge() {
        Pledge__c pledge;
        String funraiseId = 'pl-delete';

        if (frUtil.hasNPCobjects()) {
            Account testAccount = frDonorTest.getTestAccount(true);
            pledge = new Pledge__c(
                Name = 'Delete Me',
                fr_ID__c = funraiseId,
                Pledge_Amount__c = 100,
                Supporter__c = (Id) testAccount.get('PersonContactId'),
                Supporter_PA__c = testAccount.Id
            );
        } else {
            Contact testSupporter = frDonorTest.getTestContact();
            pledge = new Pledge__c(
                Name = 'Delete Me',
                Pledge_Amount__c = 100,
                fr_ID__c = funraiseId,
                Supporter__c = testSupporter.Id
            );
        }
        insert pledge;

        Map<String, Object> request = getTestRequest();
        request.put('commitmentId', funraiseId);
        request.put('deleted', true);

        frTestUtil.createTestPost(request);

        Test.startTest();
        frWSPledgeController.syncEntity();
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Pledge__c WHERE fr_ID__c = :funraiseId], 'The pledge should have been deleted');
        frTestUtil.assertNoErrors();
    }

    public static Map<String, Object> getTestRequest() {
        Map<String, Object> request = new Map<String, Object>();
        request.put('commitmentId', 'pl-1');
        request.put('supporterId', '123456');
        request.put('goalId', null);
        request.put('deleted', false);
        request.put('amount', 125.50);
        request.put('totalDonationAmount', 75.25);
        request.put('collectDate', new List<Object>{2026, 4, 15});
        request.put('name', '000123');
        return request;
    }
}