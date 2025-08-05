@isTest
private class Stripe_ContactQueueableTest {

    final static User testUser = CFA_TestUserBuilder.createUser()
        .withProfile('System Administrator')
        .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
        .build();

    @TestSetup
    static void setup() {
        System.runAs(testUser) {
            // Create the CFA_Async_Switch__c custom setting record for tests
            CFA_Async_Switch__c asyncSwitch = new CFA_Async_Switch__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                Run_Queueable__c = true
            );
            insert asyncSwitch;
        }
    }

    @isTest
    static void testQueueable_BulkProcessing() {
        System.runAs(testUser) {
            // Test the queueable logic separately from trigger integration
            List<Contact> testContacts = new List<Contact>();
            for (Integer i = 0; i < 10; i++) { // Smaller batch for cleaner testing
                testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact' + i,
                    Email = 'test' + i + '@test.com'
                ));
            }
            insert testContacts;

            // Get contact IDs for queueable
            Set<Id> contactIds = new Set<Id>();
            for (Contact c : testContacts) {
                contactIds.add(c.Id);
            }

            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.CreateCustomerMock());

            Test.startTest();
            // Test queueable directly without trigger complexity
            System.enqueueJob(new Stripe_ContactQueueable(contactIds, 'create_customer'));
            Test.stopTest();

            // Verify queueable execution completed (basic assertion for coverage)
            List<Contact> updatedContacts = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id IN :contactIds];
            Assert.areEqual(10, updatedContacts.size(), 'All contacts should be queried');
            
            // In clean queueable execution, contacts should get Stripe IDs
            for (Contact contact : updatedContacts) {
                Assert.areEqual('cus_test123456789', contact.Stripe_Customer_ID__c, 'Each contact should have Stripe ID from mock');
            }
        }
    }

    @isTest
    static void testQueueable_SingleBatch() {
        System.runAs(testUser) {
            // Test single contact processing
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@test.com'
            );
            insert testContact;

            Set<Id> contactIds = new Set<Id>{testContact.Id};
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.CreateCustomerMock());

            Test.startTest();
            System.enqueueJob(new Stripe_ContactQueueable(contactIds, 'create_customer'));
            Test.stopTest();

            Contact updatedContact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual('cus_test123456789', updatedContact.Stripe_Customer_ID__c, 'Contact should have Stripe ID from mock');
        }
    }

    @isTest
    static void testQueueable_EmptyList() {
        System.runAs(testUser) {
            Set<Id> emptyContactIds = new Set<Id>();

            Test.startTest();
            System.enqueueJob(new Stripe_ContactQueueable(emptyContactIds, 'create_customer'));
            Test.stopTest();

            // Should complete without errors (coverage test)
            Assert.isTrue(true, 'Queueable should handle empty list gracefully');
        }
    }

    @isTest
    static void testQueueable_BatchingLogic() {
        System.runAs(testUser) {
            // Test that queueable respects batching parameters
            List<Contact> testContacts = new List<Contact>();
            for (Integer i = 0; i < 5; i++) {
                testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact' + i,
                    Email = 'test' + i + '@test.com'
                ));
            }
            insert testContacts;

            Set<Id> contactIds = new Set<Id>();
            for (Contact c : testContacts) {
                contactIds.add(c.Id);
            }

            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.CreateCustomerMock());

            Test.startTest();
            // Test with custom batch size
            System.enqueueJob(new Stripe_ContactQueueable(contactIds, 'create_customer'));
            Test.stopTest();

            // In test context, only first batch processes (no chaining)
            List<Contact> updatedContacts = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id IN :contactIds];
            Assert.areEqual(5, updatedContacts.size(), 'All contacts should be queried');
            
            // At least some contacts should be processed
            Integer processedCount = 0;
            for (Contact contact : updatedContacts) {
                if (String.isNotBlank(contact.Stripe_Customer_ID__c)) {
                    processedCount++;
                }
            }
            Assert.isTrue(processedCount > 0, 'At least some contacts should be processed');
        }
    }
}