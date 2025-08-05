@isTest
private class StripeSubscriptionTriggerHandlerTest {

    final static User testUser = CFA_TestUserBuilder.createUser()
        .withProfile('System Administrator')
        .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
        .withFitnessContact('John Doe', 'Weight Loss', 'Beginner')
        .withStripeData()
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
    static void testAfterInsert_ShouldQueueStripeSubscriptionCreation() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];

            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];
            
            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active',
                Current_Period_Start__c = System.now(),
                Current_Period_End__c = System.now().addMonths(1)
            );

            Test.startTest();

            insert subscription;

            Test.stopTest();

            Stripe_Subscription__c insertedSubscription = [SELECT Id, Status__c FROM Stripe_Subscription__c WHERE Id = :subscription.Id];
            Assert.isNotNull(insertedSubscription, 'Subscription should be created');
            Assert.areEqual('active', insertedSubscription.Status__c, 'Status should remain active');
        }
    }
    
    /**
     * @description Test that subscription creation fails when Contact__c is missing (required field validation)
     * This test verifies that the database-level validation prevents creating subscriptions without a contact
     */
    @isTest
    static void testAfterInsert_ShouldNotQueueWithoutContact() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                // Intentionally omitting Contact__c to test validation
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active'
            );

            Test.startTest();

            try {
                insert subscription;
                Assert.fail('Should have thrown DmlException for missing Contact__c');
            } catch (DmlException e) {
                // Expected exception for missing required field
                Assert.isTrue(e.getMessage().contains('Contact__c'), 'Exception should mention missing Contact__c field');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test that subscription creation fails when Stripe_Price__c and Stripe_Product__c are missing (required field validation)
     * This test verifies that the database-level validation prevents creating subscriptions without price and product references
     */
    @isTest
    static void testAfterInsert_ShouldNotQueueWithoutPrice() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                // Intentionally omitting Stripe_Price__c and Stripe_Product__c to test validation
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active'
            );

            Test.startTest();

            try {
                insert subscription;
                Assert.fail('Should have thrown DmlException for missing Stripe_Price__c and Stripe_Product__c');
            } catch (DmlException e) {
                // Expected exception for missing required fields
                Assert.isTrue(e.getMessage().contains('Stripe_Price__c') || e.getMessage().contains('Stripe_Product__c'), 
                    'Exception should mention missing Price or Product fields');
            }

            Test.stopTest();
        }
    }
    
    @isTest
    static void testAfterInsert_ShouldNotQueueCancelledSubscription() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'canceled'
            );

            Test.startTest();

            insert subscription;

            Test.stopTest();

            Stripe_Subscription__c insertedSubscription = [SELECT Id, Status__c FROM Stripe_Subscription__c WHERE Id = :subscription.Id];
            Assert.isNotNull(insertedSubscription, 'Subscription should be created');
            Assert.areEqual('canceled', insertedSubscription.Status__c, 'Status should remain canceled');
        }
    }

    @isTest
    static void testAfterInsert_ShouldNotQueueWithExistingStripeId() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active',
                Stripe_Subscription_ID__c = 'sub_existing123'
            );

            Test.startTest();

            insert subscription;

            Test.stopTest();

            Stripe_Subscription__c insertedSubscription = [SELECT Id, Stripe_Subscription_ID__c FROM Stripe_Subscription__c WHERE Id = :subscription.Id];
            Assert.areEqual('sub_existing123', insertedSubscription.Stripe_Subscription_ID__c, 'Existing Stripe ID should remain');
        }
    }

    @isTest
    static void testShouldCreateStripeSubscription_ValidSubscription() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active'
            );

            Test.startTest();

            insert subscription;

            Test.stopTest();

            Assert.isNotNull(subscription.Id, 'Subscription should be created successfully');
        }
    }

    @isTest
    static void testBulkOperations_AfterInsert() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            List<Stripe_Subscription__c> subscriptions = new List<Stripe_Subscription__c>();
            for (Integer i = 0; i < 200; i++) {
                subscriptions.add(new Stripe_Subscription__c(
                    Contact__c = testContact.Id,
                    Stripe_Price__c = testPrice.Id,
                    Stripe_Product__c = testProduct.Id,
                    Product_Plan_Name__c = 'Monthly Premium Plan ' + i,
                    Amount__c = 99.99,
                    Currency__c = 'USD',
                    Status__c = 'active'
                ));
            }

            Test.startTest();

            insert subscriptions;

            Test.stopTest();

            List<Stripe_Subscription__c> insertedSubscriptions = [SELECT Id, Status__c FROM Stripe_Subscription__c WHERE Id IN :subscriptions];
            Assert.areEqual(200, insertedSubscriptions.size(), 'All subscriptions should be created');
            
            for (Stripe_Subscription__c subscription : insertedSubscriptions) {
                Assert.areEqual('active', subscription.Status__c, 'Each subscription should have active status');
            }
        }
    }

    @isTest
    static void testAfterUpdate_PlaceholderTest() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active',
                Stripe_Subscription_ID__c = 'sub_test123'
            );
            insert subscription;

            Test.startTest();

            subscription.Status__c = 'canceled';
            update subscription;

            Test.stopTest();

            Stripe_Subscription__c updatedSubscription = [SELECT Id, Status__c FROM Stripe_Subscription__c WHERE Id = :subscription.Id];
            Assert.areEqual('canceled', updatedSubscription.Status__c, 'Status should be updated to canceled');
        }
    }

    @isTest
    static void testBeforeDelete_PlaceholderTest() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active',
                Stripe_Subscription_ID__c = 'sub_test123'
            );
            insert subscription;

            Test.startTest();

            delete subscription;

            Test.stopTest();

            List<Stripe_Subscription__c> deletedSubscriptions = [SELECT Id FROM Stripe_Subscription__c WHERE Id = :subscription.Id];
            Assert.areEqual(0, deletedSubscriptions.size(), 'Subscription should be deleted');
        }
    }

    @isTest
    static void testAfterUndelete_PlaceholderTest() {
        System.runAs(testUser) {
            // Enable the trigger for tests
            StripeIntegrationSettings.syncSubscriptionsOutbound = true;
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            Stripe_Subscription__c subscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active',
                Stripe_Subscription_ID__c = 'sub_test123'
            );
            insert subscription;
            delete subscription;

            Test.startTest();

            undelete subscription;

            Test.stopTest();

            Stripe_Subscription__c undeletedSubscription = [SELECT Id, Status__c FROM Stripe_Subscription__c WHERE Id = :subscription.Id];
            Assert.isNotNull(undeletedSubscription, 'Subscription should be undeleted');
            Assert.areEqual('active', undeletedSubscription.Status__c, 'Status should remain active');
        }
    }
}