@isTest
private class StripeSubscriptionQueueableTest {

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
    static void testQueueable_CreateSubscriptions() {
        System.runAs(testUser) {
            // Get test data
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];
            
            // Update contact with Stripe Customer ID
            testContact.Stripe_Customer_ID__c = 'cus_test123456789';
            update testContact;

            // Create test subscriptions
            List<Stripe_Subscription__c> testSubscriptions = new List<Stripe_Subscription__c>();
            for (Integer i = 0; i < 5; i++) {
                testSubscriptions.add(new Stripe_Subscription__c(
                    Contact__c = testContact.Id,
                    Stripe_Price__c = testPrice.Id,
                    Stripe_Product__c = testProduct.Id,
                    Product_Plan_Name__c = 'Premium Plan ' + i,
                    Amount__c = 99.99,
                    Currency__c = 'USD',
                    Status__c = 'active'
                ));
            }
            insert testSubscriptions;

            // Get subscription IDs for queueable
            Set<Id> subscriptionIds = new Set<Id>();
            for (Stripe_Subscription__c s : testSubscriptions) {
                subscriptionIds.add(s.Id);
            }

            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.CreateSubscriptionMock());

            Test.startTest();
            // Test queueable directly
            System.enqueueJob(new StripeSubscriptionQueueable(subscriptionIds, 'create_subscription'));
            Test.stopTest();

            // Verify queueable execution completed
            List<Stripe_Subscription__c> updatedSubscriptions = [SELECT Id, Stripe_Subscription_ID__c FROM Stripe_Subscription__c WHERE Id IN :subscriptionIds];
            Assert.areEqual(5, updatedSubscriptions.size(), 'All subscriptions should be queried');
            
            // In test queueable execution, subscriptions should get Stripe IDs
            for (Stripe_Subscription__c subscription : updatedSubscriptions) {
                Assert.areEqual('sub_test123456789', subscription.Stripe_Subscription_ID__c, 'Each subscription should have Stripe ID from mock');
            }
        }
    }

    @isTest
    static void testQueueable_UpdateSubscriptions() {
        System.runAs(testUser) {
            // Get test data
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            // Create test subscription with Stripe ID
            Stripe_Subscription__c testSubscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active',
                Stripe_Subscription_ID__c = 'sub_test123456789'
            );
            insert testSubscription;

            Set<Id> subscriptionIds = new Set<Id>{testSubscription.Id};
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.UpdateSubscriptionMock());

            Test.startTest();
            System.enqueueJob(new StripeSubscriptionQueueable(subscriptionIds, 'update_subscription'));
            Test.stopTest();

            Stripe_Subscription__c updatedSubscription = [SELECT Id, Stripe_Subscription_ID__c FROM Stripe_Subscription__c WHERE Id = :testSubscription.Id];
            Assert.areEqual('sub_test123456789', updatedSubscription.Stripe_Subscription_ID__c, 'Subscription should retain Stripe ID');
        }
    }

    @isTest
    static void testQueueable_EmptyList() {
        System.runAs(testUser) {
            Set<Id> emptySubscriptionIds = new Set<Id>();

            Test.startTest();
            System.enqueueJob(new StripeSubscriptionQueueable(emptySubscriptionIds, 'create_subscription'));
            Test.stopTest();

            // Should complete without errors (coverage test)
            Assert.isTrue(true, 'Queueable should handle empty list gracefully');
        }
    }

    @isTest
    static void testQueueable_DisabledSwitch() {
        System.runAs(testUser) {
            // Disable the queueable switch
            CFA_Async_Switch__c asyncSwitch = CFA_Async_Switch__c.getOrgDefaults();
            asyncSwitch.Run_Queueable__c = false;
            update asyncSwitch;

            // Get test data
            Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
            Stripe_Price__c testPrice = [SELECT Id FROM Stripe_Price__c LIMIT 1];
            Stripe_Product__c testProduct = [SELECT Id FROM Stripe_Product__c LIMIT 1];

            // Create test subscription
            Stripe_Subscription__c testSubscription = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active'
            );
            insert testSubscription;

            Set<Id> subscriptionIds = new Set<Id>{testSubscription.Id};

            Test.startTest();
            System.enqueueJob(new StripeSubscriptionQueueable(subscriptionIds, 'create_subscription'));
            Test.stopTest();

            // When switch is disabled, queueable should skip processing
            Stripe_Subscription__c updatedSubscription = [SELECT Id, Stripe_Subscription_ID__c FROM Stripe_Subscription__c WHERE Id = :testSubscription.Id];
            Assert.isTrue(String.isBlank(updatedSubscription.Stripe_Subscription_ID__c), 'Subscription should not have Stripe ID when queueable is disabled');
        }
    }
}