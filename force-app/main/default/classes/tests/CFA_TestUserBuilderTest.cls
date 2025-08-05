@isTest
private class CFA_TestUserBuilderTest {
    
    @isTest
    static void testBasicUserCreation() {
        // Test basic user creation
        User testUser = CFA_TestUserBuilder.createUser()
            .withName('John', 'Doe')
            .withEmail('john.doe@test.com')
            .withProfile('CFA Base User')
            .build();
        
        // Assertions
        System.assertNotEquals(null, testUser.Id, 'User should be created with an ID');
        System.assertEquals('John', testUser.FirstName, 'First name should match');
        System.assertEquals('Doe', testUser.LastName, 'Last name should match');
        System.assertEquals('john.doe@test.com', testUser.Email, 'Email should match');
    }
    
    @isTest
    static void testUserWithPermissionSets() {
        // Test user creation with permission sets
        User testUser = CFA_TestUserBuilder.createUser()
            .withProfile('CFA Base User')
            .withPermissionSets(new Set<String> {'Stripe_Integration_User'})
            .build();
        
        // Verify permission set assignment
        List<PermissionSetAssignment> assignments = [
            SELECT Id, PermissionSet.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :testUser.Id
        ];
        
        System.assertEquals(1, assignments.size(), 'Should have one permission set assignment');
        System.assertEquals('Stripe_Integration_User', assignments[0].PermissionSet.Name, 'Permission set name should match');
    }
    
    @isTest
    static void testUserWithContact() {
        // Test user creation with contact
        User testUser = CFA_TestUserBuilder.createUser()
            .withProfile('CFA Base User')
            .withContact('Jane Smith')
            .build();
        
        // Verify contact was created
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Email LIKE 'jane.smith@test.com'];
        System.assertEquals(1, contacts.size(), 'Contact should be created');
        System.assertEquals('Jane', contacts[0].FirstName, 'Contact first name should match');
        System.assertEquals('Smith', contacts[0].LastName, 'Contact last name should match');
    }
    
    @isTest
    static void testUserWithCFAData() {
        // Test user creation with CFA data
        User testUser = CFA_TestUserBuilder.createUser()
            .withProfile('CFA Base User')
            .withCFAData()
            .build();
        
        // Verify CFA data was created
        List<CFA_Fitness_Product__c> products = [SELECT Id, Name FROM CFA_Fitness_Product__c WHERE Name = 'Test Fitness Product'];
        System.assertEquals(1, products.size(), 'CFA Fitness Product should be created');
        
        List<CFA_Coaching_Session__c> sessions = [SELECT Id, Coach__c FROM CFA_Coaching_Session__c WHERE Coach__c = :testUser.Id];
        System.assertEquals(1, sessions.size(), 'CFA Coaching Session should be created');
        System.assertEquals(testUser.Id, sessions[0].Coach__c, 'Session should be assigned to the test user');
    }
    
    @isTest
    static void testUserWithStripeData() {
        // Test user creation with Stripe data
        User testUser = CFA_TestUserBuilder.createUser()
            .withProfile('CFA Base User')
            .withStripeData()
            .build();
        
        // Verify Stripe data was created
        List<Stripe_Product__c> products = [SELECT Id, Name FROM Stripe_Product__c WHERE Name = 'Test Stripe Product'];
        System.assertEquals(1, products.size(), 'Stripe Product should be created');
        
        List<Stripe_Price__c> prices = [SELECT Id, Amount__c FROM Stripe_Price__c WHERE Amount__c = 99.99];
        System.assertEquals(1, prices.size(), 'Stripe Price should be created');
        
        List<Stripe_Payment_Method__c> paymentMethods = [SELECT Id, Card_Brand__c FROM Stripe_Payment_Method__c WHERE Card_Brand__c = 'Visa'];
        System.assertEquals(1, paymentMethods.size(), 'Stripe Payment Method should be created');
        
        List<Stripe_Subscription__c> subscriptions = [SELECT Id, Status__c FROM Stripe_Subscription__c WHERE Status__c = 'Active'];
        System.assertEquals(1, subscriptions.size(), 'Stripe Subscription should be created');
        
        List<Stripe_Payment_Transaction__c> transactions = [SELECT Id, Status__c FROM Stripe_Payment_Transaction__c WHERE Status__c = 'Succeeded'];
        System.assertEquals(1, transactions.size(), 'Stripe Payment Transaction should be created');
    }
    
    @isTest
    static void testCompleteUserSetup() {
        // Test complete user setup with all features
        User testUser = CFA_TestUserBuilder.createUser()
            .withName('Complete', 'User')
            .withEmail('complete.user@test.com')
            .withProfile('CFA Base User')
            .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
            .withContact('Test Contact')
            .withCFAData()
            .withStripeData()
            .build();
        
        // Verify all components were created
        System.assertNotEquals(null, testUser.Id, 'User should be created');
        
        // Verify permission sets
        List<PermissionSetAssignment> assignments = [
            SELECT Id, PermissionSet.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :testUser.Id
        ];
        System.assertEquals(2, assignments.size(), 'Should have two permission set assignments');
        
        // Verify contact
        List<Contact> contacts = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'Contact'];
        System.assertEquals(1, contacts.size(), 'Contact should be created');
        
        // Verify CFA data
        List<CFA_Fitness_Product__c> products = [SELECT Id FROM CFA_Fitness_Product__c WHERE Name = 'Test Fitness Product'];
        System.assertEquals(1, products.size(), 'CFA Fitness Product should be created');
        
        // Verify Stripe data
        List<Stripe_Product__c> stripeProducts = [SELECT Id FROM Stripe_Product__c WHERE Name = 'Test Stripe Product'];
        System.assertEquals(1, stripeProducts.size(), 'Stripe Product should be created');
    }
    
    @isTest
    static void testCleanup() {
        // Test cleanup functionality
        CFA_TestUserBuilder builder = CFA_TestUserBuilder.createUser()
            .withProfile('CFA Base User')
            .withCFAData()
            .withStripeData();
        
        User testUser = builder.build();
        
        // Verify records were created
        List<CFA_Fitness_Product__c> products = [SELECT Id FROM CFA_Fitness_Product__c WHERE Name = 'Test Fitness Product'];
        System.assertEquals(1, products.size(), 'Product should exist before cleanup');
        
    }
} 