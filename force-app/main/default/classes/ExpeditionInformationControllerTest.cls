@isTest
private class ExpeditionInformationControllerTest {
    
    @testSetup
    static void setupTestData() {

        User testUser = new User(
            Username = 'testuserTurtlewave@example.com',
            Alias = 'testuser',
            Email = 'testuser@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Europe/Athens',
            LocaleSidKey = 'el_GR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test User'
        );
        insert testUser;

        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'User';
        testContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Marine_expedition_member').getRecordTypeId();
        testContact.User__c = testUser.Id;
        insert testContact;

        Expedition__c testExpedition = new Expedition__c(
            Name = 'Test Expedition',
            Status__c = 'Ongoing',
            Expedition_Start_Date__c = Date.today().addDays(-1),
            Expedition_End_Date__c = Date.today().addDays(1)
        );
        insert testExpedition;

        Expedition_Member__c testExpeditionMember = new Expedition_Member__c(
            Contact__c = testContact.Id,
            Expedition__c = testExpedition.Id
        );
        insert testExpeditionMember;

        Expedition_Action__c testExpeditionAction = new Expedition_Action__c(
            Expedition__c = testExpedition.Id,
            Title__c = 'Test Action',
            Action_Completed__c = false
        );
        insert testExpeditionAction;
    }
    
    @isTest
    static void testGetUserActiveExpedition() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserTurtlewave@example.com' LIMIT 1];

        Test.startTest();
        ExpeditionInformationController.ExpeditionWrapper result = ExpeditionInformationController.getUserActiveExpedition(testUser.Id);
        Test.stopTest();

        System.assertEquals('Test Expedition', result.expeditionName);
        System.assertEquals('Ongoing', result.expeditionStatus);
    }

    @isTest
    static void testUploadFile() {
        String base64String = EncodingUtil.base64Encode(Blob.valueOf('Test File Content'));
        String filename = 'TestFile.txt';
        String recordId = [SELECT Id FROM Expedition__c LIMIT 1].Id;

        Test.startTest();
        String contentLinkId = ExpeditionInformationController.uploadFile(base64String, filename, recordId);
        Test.stopTest();
        System.assertNotEquals(null, contentLinkId);
    }

    @isTest
    static void testCompleteExpedition() {
        Expedition__c testExpedition = [SELECT Id FROM Expedition__c LIMIT 1];
        
        Test.startTest();
        ExpeditionInformationController.completeExpedition(testExpedition.Id);
        Test.stopTest();

        Expedition__c updatedExpedition = [SELECT Status__c FROM Expedition__c WHERE Id = :testExpedition.Id];
        System.assertEquals('Completed', updatedExpedition.Status__c);
    }

    @isTest
    static void testValidateCompletion() {
        Expedition__c testExpedition = [SELECT Id FROM Expedition__c LIMIT 1];
        Expedition_Action__c testExpeditionAction = [SELECT Id FROM Expedition_Action__c WHERE Expedition__c = :testExpedition.Id LIMIT 1];
        
        testExpeditionAction.Action_Completed__c = true;
        update testExpeditionAction;

        Test.startTest();
        Boolean isCompleted = ExpeditionInformationController.validateCompletion(testExpedition.Id);
        Test.stopTest();
        System.assert(isCompleted);
    }

    @isTest
    static void testUpdateStatusCompleted() {
        Expedition_Action__c testExpeditionAction = [SELECT Id FROM Expedition_Action__c LIMIT 1];

        Test.startTest();
        ExpeditionInformationController.updateStatusCompleted(testExpeditionAction.Id, true);
        Test.stopTest();

        Expedition_Action__c updatedAction = [SELECT Action_Completed__c FROM Expedition_Action__c WHERE Id = :testExpeditionAction.Id];
        System.assert(updatedAction.Action_Completed__c);
    }

    @isTest
    static void testUpdateActionFindings() {
        Expedition_Action__c testExpeditionAction = [SELECT Id, Findings_Input__c FROM Expedition_Action__c LIMIT 1];
        String newFinding = 'New finding for this action';

        Test.startTest();
        ExpeditionInformationController.updateActionFindings(testExpeditionAction.Id, newFinding);
        Test.stopTest();

        Expedition_Action__c updatedAction = [SELECT Findings_Input__c FROM Expedition_Action__c WHERE Id = :testExpeditionAction.Id];
        System.assertEquals('New finding for this action', updatedAction.Findings_Input__c);
    }
}
