@isTest
private class Stripe_ClientTest {

    final static User testUser = CFA_TestUserBuilder.createUser()
        .withProfile('System Administrator')
        .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
        .withFitnessContact('John Doe', 'Weight Loss', 'Beginner')
        .build();

    @isTest
    static void testGetCustomer() {
        // SETUP
        System.runAs(testUser) {
            // Query for the existing test contact created by the builder
            Contact testContact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Name = 'John Doe' LIMIT 1];
            testContact.Stripe_Customer_ID__c = 'cus_test123456789';
            update testContact;

            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for get_customer action
            Map<String, Object> params = new Map<String, Object>();
            params.put('customerId', 'cus_test123456789');

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.GetCustomerMock());

            // Call the get_customer action
            Stripe_GetCustomerRS result = (Stripe_GetCustomerRS) client.handleAction('get_customer', params);

            Test.stopTest();

            // ASSERT
            Assert.isNotNull(result, 'Response should not be null');
            Assert.areEqual('cus_test123456789', result.id, 'Customer ID should match');
            Assert.areEqual('customer', result.object_x, 'Object type should be customer');
            Assert.areEqual('test@example.com', result.email, 'Email should match');
            Assert.areEqual('Test Customer', result.name, 'Name should match');
        }
    }

    @isTest
    static void testCreateCustomer() {
        // SETUP
        System.runAs(testUser) {
            // Query for the existing test contact created by the builder
            Contact testContact = [SELECT Id, FirstName, LastName, Email, Phone, 
                MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry  
                FROM Contact 
                WHERE Name = 'John Doe' 
                LIMIT 1];
            testContact.Email = 'jane.smith@example.com';
            testContact.Phone = '+1234567890';
            update testContact;

            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for create_customer action
            Map<String, Object> params = new Map<String, Object>();
            params.put('contact', testContact);

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.CreateCustomerMock());

            // Call the create_customer action
            String result = (String) client.handleAction('create_customer', params);

            Test.stopTest();

            // ASSERT
            Assert.isNotNull(result, 'Response should not be null');
            Assert.areEqual('cus_test123456789', result, 'Customer ID should match');
        }
    }

    @isTest
    static void testUpdateCustomer() {
        // SETUP
        System.runAs(testUser) {
            // Query for the existing test contact created by the builder
            Contact testContact = [SELECT Id, FirstName, LastName, Email, Phone, 
                MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry  
                FROM Contact 
                WHERE Name = 'John Doe' 
                LIMIT 1];
            testContact.Email = 'updated@example.com';
            testContact.Phone = '+1987654321';
            update testContact;

            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for update_customer action
            Map<String, Object> params = new Map<String, Object>();
            params.put('customerId', 'cus_test123456789');
            params.put('contact', testContact);

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.UpdateCustomerMock());

            // Call the update_customer action
            Stripe_UpdateCustomerRS result = (Stripe_UpdateCustomerRS) client.handleAction('update_customer', params);

            Test.stopTest();

            // ASSERT
            Assert.isNotNull(result, 'Response should not be null');
            Assert.areEqual('cus_test123456789', result.id, 'Customer ID should match');
            Assert.areEqual('customer', result.object_x, 'Object type should be customer');
            Assert.areEqual('updated@example.com', result.email, 'Email should match');
            Assert.areEqual('Updated Customer', result.name, 'Name should match');
            Assert.areEqual('+1234567890', result.phone, 'Phone should match');
        }
    }

    @isTest
    static void testDeleteCustomer() {
        // SETUP
        System.runAs(testUser) {
            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for delete_customer action
            Map<String, Object> params = new Map<String, Object>();
            params.put('customerId', 'cus_test123456789');

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.DeleteCustomerMock());

            // Call the delete_customer action
            Boolean result = (Boolean) client.handleAction('delete_customer', params);

            Test.stopTest();

            // ASSERT
            Assert.isTrue(result, 'Delete operation should return true');
        }
    }

    @isTest
    static void testCreateSubscription() {
        // SETUP
        System.runAs(testUser) {
            // Get the test contact and update it with a Stripe Customer ID
            Contact testContact = [SELECT Id FROM Contact WHERE Name = 'John Doe' LIMIT 1];
            testContact.Stripe_Customer_ID__c = 'cus_test123456789';
            update testContact;
            
            // Create a test Stripe Product record
            Stripe_Product__c testProduct = new Stripe_Product__c(
                Name = 'Test Premium Plan',
                Description__c = 'Test product for subscription testing',
                Is_Active__c = true
            );
            insert testProduct;
            
            // Create a test Stripe Price record
            Stripe_Price__c testPrice = new Stripe_Price__c(
                Stripe_Product__c = testProduct.Id,
                Amount__c = 99.99,
                Currency__c = 'USD',
                Billing_Interval__c = 'month',
                Billing_Interval_Count__c = 1,
                Is_Active__c = true,
                Stripe_Price_ID__c = 'price_test123456789'
            );
            insert testPrice;
            
            // Create a test subscription record with all required fields
            Stripe_Subscription__c subscriptionRecord = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Price__c = testPrice.Id,
                Stripe_Product__c = testProduct.Id,
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'Active',
                Current_Period_Start__c = System.now(),
                Current_Period_End__c = System.now().addMonths(1)
            );

            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for create_subscription action
            Map<String, Object> params = new Map<String, Object>();
            params.put('subscriptionRecord', subscriptionRecord);

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.CreateSubscriptionMock());

            // Call the create_subscription action
            Map<String, Object> result = (Map<String, Object>) client.handleAction('create_subscription', params);

            Test.stopTest();

            // ASSERT
            Assert.isNotNull(result, 'Response should not be null');
            Assert.areEqual('sub_test123456789', result.get('id'), 'Subscription ID should match');
            Assert.areEqual('active', result.get('status'), 'Status should be active');
        }
    }

    @isTest
    static void testGetSubscription() {
        // SETUP
        System.runAs(testUser) {
            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for get_subscription action
            Map<String, Object> params = new Map<String, Object>();
            params.put('subscriptionId', 'sub_test123456789');

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.GetSubscriptionMock());

            // Call the get_subscription action
            Map<String, Object> result = (Map<String, Object>) client.handleAction('get_subscription', params);

            Test.stopTest();

            // ASSERT
            Assert.isNotNull(result, 'Response should not be null');
            Assert.areEqual('sub_test123456789', result.get('id'), 'Subscription ID should match');
        }
    }

    @isTest
    static void testUpdateSubscription() {
        // SETUP
        System.runAs(testUser) {
            // Get the test contact and update it with a Stripe Customer ID
            Contact testContact = [SELECT Id FROM Contact WHERE Name = 'John Doe' LIMIT 1];
            
            // Create a test subscription record
            Stripe_Subscription__c subscriptionRecord = new Stripe_Subscription__c(
                Contact__c = testContact.Id,
                Stripe_Subscription_ID__c = 'sub_test123456789',
                Product_Plan_Name__c = 'Monthly Premium Plan',
                Amount__c = 99.99,
                Currency__c = 'USD',
                Status__c = 'active'
            );
            insert subscriptionRecord;

            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for update_subscription action
            Map<String, Object> params = new Map<String, Object>();
            params.put('subscriptionId', 'sub_test123456789');
            params.put('subscriptionRecord', subscriptionRecord);

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.UpdateSubscriptionMock());

            // Call the update_subscription action
            Boolean result = (Boolean) client.handleAction('update_subscription', params);

            Test.stopTest();

            // ASSERT
            Assert.isTrue(result, 'Update operation should return true');
        }
    }

    @isTest
    static void testDeleteSubscription() {
        // SETUP
        System.runAs(testUser) {
            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for delete_subscription action
            Map<String, Object> params = new Map<String, Object>();
            params.put('subscriptionId', 'sub_test123456789');

            // TEST
            Test.startTest();

            // Set up mock callout
            Test.setMock(HttpCalloutMock.class, new Stripe_MockFactory.DeleteSubscriptionMock());

            // Call the delete_subscription action
            Boolean result = (Boolean) client.handleAction('delete_subscription', params);

            Test.stopTest();

            // ASSERT
            Assert.isTrue(result, 'Delete operation should return true');
        }
    }

    @isTest
    static void testUnknownAction() {
        // SETUP
        System.runAs(testUser) {
            // Create the Stripe client
            Stripe_Client client = new Stripe_Client();

            // Prepare parameters for unknown action
            Map<String, Object> params = new Map<String, Object>();
            params.put('testParam', 'testValue');

            // TEST & ASSERT
            Test.startTest();

            try {
                // Call an unknown action - should throw StripeException
                client.handleAction('unknown_action', params);
                Assert.fail('Should have thrown StripeException for unknown action');
            } catch (StripeException e) {
                // Expected exception
                Assert.isTrue(e.getMessage().contains('Unknown action: unknown_action'), 
                    'Exception message should contain the unknown action name');
            }

            Test.stopTest();
        }
    }
    

}