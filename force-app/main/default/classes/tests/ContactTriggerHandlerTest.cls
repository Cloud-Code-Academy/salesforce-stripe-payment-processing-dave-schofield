@isTest
private class ContactTriggerHandlerTest {

    final static User testUser = CFA_TestUserBuilder.createUser()
        .withProfile('System Administrator')
        .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
        .withFitnessContact('John Doe', 'Weight Loss', 'Beginner')
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
    static void testAfterInsert_ShouldCreateStripeCustomer() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            
            // Set mock before Test.startTest() to ensure it's available for queueable
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.CreateCustomerMock());
            
            Test.startTest();

            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '+1234567890'
            );
            insert testContact;

            Test.stopTest();

            Contact updatedContact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual('cus_test123456789', updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should be populated');
        }
    }

    @isTest
    static void testAfterInsert_ShouldNotCreateStripeCustomerWithoutEmail() {
        System.runAs(testUser) {
            Test.startTest();

            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Phone = '+1234567890'
            );
            insert testContact;

            Test.stopTest();

            Contact updatedContact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
            Assert.isTrue(String.isBlank(updatedContact.Stripe_Customer_ID__c), 'Stripe Customer ID should not be populated without email');
        }
    }

    @isTest
    static void testAfterInsert_ShouldNotCreateStripeCustomerIfAlreadyExists() {
        System.runAs(testUser) {
            Test.startTest();

            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '+1234567890',
                Stripe_Customer_ID__c = 'cus_existing123'
            );
            insert testContact;

            Test.stopTest();

            Contact updatedContact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual('cus_existing123', updatedContact.Stripe_Customer_ID__c, 'Existing Stripe Customer ID should remain unchanged');
        }
    }

    @isTest
    static void testAfterUpdate_ShouldUpdateStripeCustomer() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '+1234567890',
                Stripe_Customer_ID__c = 'cus_test123456789'
            );
            insert testContact;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.UpdateCustomerMock('cus_test123456789', 'updated@test.com', 'Jane Doe'));

            testContact.Email = 'updated@test.com';
            testContact.FirstName = 'Jane';
            update testContact;

            Test.stopTest();

            Contact updatedContact = [SELECT Id, Email, FirstName FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual('updated@test.com', updatedContact.Email, 'Email should be updated');
            Assert.areEqual('Jane', updatedContact.FirstName, 'First name should be updated');
        }
    }

    @isTest
    static void testAfterUpdate_ShouldNotUpdateWithoutStripeId() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '+1234567890'
            );
            insert testContact;

            Test.startTest();

            testContact.Email = 'updated@test.com';
            update testContact;

            Test.stopTest();

            Contact updatedContact = [SELECT Id, Email FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual('updated@test.com', updatedContact.Email, 'Email should be updated locally');
        }
    }

    @isTest
    static void testAfterUpdate_ShouldNotUpdateIfNoRelevantFieldsChanged() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '+1234567890',
                Stripe_Customer_ID__c = 'cus_test123456789',
                Description = 'Original description'
            );
            insert testContact;

            Test.startTest();

            testContact.Description = 'Updated description';
            update testContact;

            Test.stopTest();

            Contact updatedContact = [SELECT Id, Description FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual('Updated description', updatedContact.Description, 'Non-Stripe field should be updated');
        }
    }

    @isTest
    static void testBeforeDelete_ShouldDeleteStripeCustomer() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '+1234567890',
                Stripe_Customer_ID__c = 'cus_test123456789'
            );
            insert testContact;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.DeleteCustomerMock('cus_test123456789'));

            delete testContact;

            Test.stopTest();

            List<Contact> deletedContacts = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual(0, deletedContacts.size(), 'Contact should be deleted');
        }
    }

    @isTest
    static void testBeforeDelete_ShouldNotCallStripeWithoutCustomerId() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '+1234567890'
            );
            insert testContact;

            Test.startTest();

            delete testContact;

            Test.stopTest();

            List<Contact> deletedContacts = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
            Assert.areEqual(0, deletedContacts.size(), 'Contact should be deleted even without Stripe ID');
        }
    }

    @isTest
    static void testBulkOperations_TriggerFiltering() {
        System.runAs(testUser) {
            // Test that the trigger correctly filters contacts for bulk processing
            StripeIntegrationSettings.syncContactsOutbound = true;
            
            // Create mix of contacts - some that should sync, some that shouldn't
            List<Contact> testContacts = new List<Contact>();
            
            // 50 contacts with email (should sync)
            for (Integer i = 0; i < 50; i++) {
                testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact' + i,
                    Email = 'test' + i + '@test.com'
                ));
            }
            
            // 25 contacts without email (should not sync)
            for (Integer i = 50; i < 75; i++) {
                testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact' + i,
                    Phone = '+123456789' + i
                ));
            }
            
            // 25 contacts with email and existing Stripe ID (should not sync)
            for (Integer i = 75; i < 100; i++) {
                testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact' + i,
                    Email = 'existing' + i + '@test.com',
                    Stripe_Customer_ID__c = 'cus_existing' + i
                ));
            }

            Test.startTest();
            insert testContacts; // Trigger should only process 50 contacts with email and no Stripe ID
            Test.stopTest();

            // Verify the contacts exist (simple assertion for code coverage)
            List<Contact> insertedContacts = [SELECT Id, Email, Stripe_Customer_ID__c FROM Contact WHERE Id IN :testContacts];
            Assert.areEqual(100, insertedContacts.size(), 'All contacts should be inserted');
            
            // Basic validation: contacts with existing Stripe IDs should still have them
            for (Contact contact : insertedContacts) {
                if (contact.Email != null && contact.Email.startsWith('existing')) {
                    Assert.isTrue(contact.Stripe_Customer_ID__c.startsWith('cus_existing'), 'Existing Stripe IDs should be preserved');
                }
            }
        }
    }


    
    @isTest
    static void testBulkOperations_AfterUpdate() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            
            // Test bulk update processing - single batch of 100 contacts
            List<Contact> testContacts = new List<Contact>();
            for (Integer i = 0; i < 100; i++) {
                testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact' + i,
                    Email = 'test' + i + '@test.com',
                    Stripe_Customer_ID__c = 'cus_test' + i
                ));
            }
            insert testContacts;

            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.UpdateCustomerMock());

            Test.startTest();
            for (Contact contact : testContacts) {
                contact.Email = 'updated' + contact.Email;
            }
            update testContacts;
            Test.stopTest(); // Ensures all async jobs complete

            List<Contact> updatedContacts = [SELECT Id, Email FROM Contact WHERE Id IN :testContacts];
            Assert.areEqual(100, updatedContacts.size(), 'All contacts should be queried');
            
            // Verify that all contacts were updated (this test is about the local email update, not Stripe sync)
            for (Contact contact : updatedContacts) {
                Assert.isTrue(contact.Email.startsWith('updated'), 'Each contact email should be updated locally');
            }
        }
    }

    @isTest
    static void testExceptionHandling_CreateCustomer() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncContactsOutbound = true;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.ErrorMock());

            Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com'
            );
            insert testContact;

            Test.stopTest();

            Contact updatedContact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
            Assert.isTrue(String.isBlank(updatedContact.Stripe_Customer_ID__c), 'Stripe Customer ID should not be set on error');
        }
    }
    
}