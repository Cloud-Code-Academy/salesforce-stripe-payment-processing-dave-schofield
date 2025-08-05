/**
 * @description Test User Builder for Cloud Fitness Academy
 * Provides a fluent API for creating test users with proper permissions and test data
 * Handles mixed DML operations by separating User creation from other data creation
 * 
 * @example
 * // Basic user creation
 * User testUser = CFA_TestUserBuilder.createUser()
 *     .withName('John', 'Doe')
 *     .withEmail('john.doe@test.com')
 *     .withProfile('CFA Base User')
 *     .build();
 * 
 * // User with permission sets
 * User adminUser = CFA_TestUserBuilder.createUser()
 *     .withProfile('System Administrator')
 *     .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
 *     .build();
 * 
 * // User with contact and test data
 * User coachUser = CFA_TestUserBuilder.createUser()
 *     .withProfile('CFA Base User')
 *     .withContact('Jane Smith')
 *     .withCFAData() // Creates CFA_Coaching_Session__c and CFA_Fitness_Product__c
 *     .withStripeData() // Creates Stripe_Subscription__c, Stripe_Payment_Method__c, etc.
 *     .build();
 * 
 * // User with fitness-specific contact
 * User fitnessUser = CFA_TestUserBuilder.createUser()
 *     .withProfile('CFA Base User')
 *     .withFitnessContact('John Doe', 'Weight Loss', 'Beginner')
 *     .withCFAData()
 *     .build();
 * 
 * // Complete setup for integration testing
 * User integrationUser = CFA_TestUserBuilder.createUser()
 *     .withName('Integration', 'Tester')
 *     .withEmail('integration.tester@test.com')
 *     .withProfile('System Administrator')
 *     .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
 *     .withFitnessContact('Test Customer', 'Weight Loss', 'Beginner')
 *     .withCFAData()
 *     .withStripeData()
 *     .build();
 */
@isTest
public class CFA_TestUserBuilder {
    
    // Builder state
    private String profileName = 'CFA Base User';
    private Set<String> permissionSetNames = new Set<String>();
    private Contact testContact;
    private Boolean includeCFAData = false;
    private Boolean includeStripeData = false;
    private String firstName = 'Test';
    private String lastName = 'User';
    private String email = 'test.user@example.com';
    private String username = 'test.user@example.com';
    private String alias = 'testuser';
    private String communityNickname = 'Test User';
    private String timeZoneSidKey = 'America/New_York';
    private String localeSidKey = 'en_US';
    private String emailEncodingKey = 'UTF-8';
    private String languageLocaleKey = 'en_US';
    
    // Created objects for cleanup
    private User createdUser;
    private List<SObject> createdRecords = new List<SObject>();
    
    /**
     * @description Start building a test user
     * @return CFA_TestUserBuilder instance
     */
    public static CFA_TestUserBuilder createUser() {
        return new CFA_TestUserBuilder();
    }
    
    /**
     * @description Set the profile for the test user
     * @param profileName The name of the profile to assign
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withProfile(String profileName) {
        this.profileName = profileName;
        return this;
    }
    
    /**
     * @description Set the profile using enum for type safety
     * @param profile The profile enum value
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withProfile(ProfileType profile) {
        this.profileName = profile.name();
        return this;
    }
    
    /**
     * @description Add permission sets to the test user
     * @param permissionSetNames Set of permission set names to assign
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withPermissionSets(Set<String> permissionSetNames) {
        this.permissionSetNames.addAll(permissionSetNames);
        return this;
    }
    
    /**
     * @description Add a single permission set to the test user
     * @param permissionSetName The permission set name to assign
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withPermissionSet(String permissionSetName) {
        this.permissionSetNames.add(permissionSetName);
        return this;
    }
    
    /**
     * @description Set the contact for the test user by name
     * @param contactName The name for the contact (will be created via CFA_TestDataFactory)
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withContact(String contactName) {
        // Use the data factory to create the contact object (not inserted yet)
        this.testContact = CFA_TestDataFactory.createContactObject(contactName);
        return this;
    }
    
    /**
     * @description Set the contact for the test user with fitness-specific data
     * @param contactName The name for the contact
     * @param fitnessGoals The fitness goals
     * @param experienceLevel The experience level
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withFitnessContact(String contactName, String fitnessGoals, String experienceLevel) {
        // Use the data factory to create the fitness contact object (not inserted yet)
        this.testContact = CFA_TestDataFactory.createFitnessContactObject(contactName, fitnessGoals, experienceLevel);
        return this;
    }
    

    
    /**
     * @description Include CFA data (CFA_Coaching_Session__c, CFA_Fitness_Product__c)
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withCFAData() {
        this.includeCFAData = true;
        return this;
    }
    
    /**
     * @description Include Stripe data (Stripe_Subscription__c, Stripe_Payment_Method__c, etc.)
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withStripeData() {
        this.includeStripeData = true;
        return this;
    }
    
    /**
     * @description Set user details
     * @param firstName User's first name
     * @param lastName User's last name
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withName(String firstName, String lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.communityNickname = firstName + ' ' + lastName;
        return this;
    }
    
    /**
     * @description Set user email and username
     * @param email User's email address
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withEmail(String email) {
        this.email = email;
        this.username = email;
        return this;
    }
    
    /**
     * @description Set user alias
     * @param alias User's alias
     * @return CFA_TestUserBuilder instance
     */
    public CFA_TestUserBuilder withAlias(String alias) {
        this.alias = alias;
        return this;
    }
    
    /**
     * @description Build and create the test user with all specified data
     * @return User The created test user
     */
    public User build() {
        // Step 1: Create User (setup object)
        createdUser = createUserRecord();
        
        // Step 2: Assign permission sets in a separate transaction
        if (!permissionSetNames.isEmpty()) {
            assignPermissionSets();
        }
        
        // Step 3: Create associated data in a separate transaction (non-setup objects)
        if (testContact != null || includeCFAData || includeStripeData) {
            createAssociatedData();
        }
        
        return createdUser;
    }
    
    /**
     * @description Get all created records for cleanup
     * @return List<SObject> All created records
     */
    public List<SObject> getCreatedRecords() {
        List<SObject> allRecords = new List<SObject>();
        if (createdUser != null) {
            allRecords.add(createdUser);
        }
        allRecords.addAll(createdRecords);
        return allRecords;
    }
       
    // Private helper methods
    
    private User createUserRecord() {
        // Get profile ID
        Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        
        // Create user
        User testUser = new User(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Username = username + '.' + System.currentTimeMillis() + '@test.com',
            Alias = alias,
            CommunityNickname = communityNickname + System.currentTimeMillis(),
            ProfileId = profile.Id,
            TimeZoneSidKey = timeZoneSidKey,
            LocaleSidKey = localeSidKey,
            EmailEncodingKey = emailEncodingKey,
            LanguageLocaleKey = languageLocaleKey,
            IsActive = true
        );
        
        insert testUser;
        return testUser;
    }
    
    private void assignPermissionSets() {
        // Use System.runAs with current user to create a separate transaction for permission set assignment
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<PermissionSet> permissionSets = [
                SELECT Id, Name 
                FROM PermissionSet 
                WHERE Name IN :permissionSetNames
            ];
            
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet ps : permissionSets) {
                assignments.add(new PermissionSetAssignment(
                    AssigneeId = createdUser.Id,
                    PermissionSetId = ps.Id
                ));
            }
            
            if (!assignments.isEmpty()) {
                insert assignments;
            }
        }
    }
    
    private void createAssociatedData() {
        // Use a separate transaction for non-setup objects to avoid mixed DML
        System.runAs(createdUser) {
            // Insert contact if provided (it was created by withContact methods)
            if (testContact != null) {
                insert testContact;
                createdRecords.add(testContact);
            }
            
            // Create CFA data if requested
            if (includeCFAData) {
                createCFAData();
            }
            
            // Create Stripe data if requested
            if (includeStripeData) {
                createStripeData();
            }
        }
    }
    
    private void createCFAData() {
        // Create CFA Fitness Product
        CFA_Fitness_Product__c product = new CFA_Fitness_Product__c(
            Description__c = 'Test product for unit testing',
            Base_Price__c = 99.99,
            Category__c = 'Equipment',
            Inventory_Quantity__c = 10,
            SKU__c = 'TEST-SKU-001',
            Is_Active__c = true
        );
        insert product;
        createdRecords.add(product);
        
        // Create CFA Coaching Session
        CFA_Coaching_Session__c session = new CFA_Coaching_Session__c(
            Contact__c = testContact.Id,
            Coach__c = createdUser.Id,
            Session_Date__c = System.now().addDays(7),
            Status__c = 'Scheduled',
            Amount__c = 150.00,
            Payment_Status__c = 'Pending',
            Duration_Minutes__c = 60,
            Session_Type__c = 'Initial Consultation',
            Session_Notes__c = 'Test coaching session'
        );
        insert session;
        createdRecords.add(session);
    }
    
    private void createStripeData() {
        // Create a default contact if one doesn't exist
        if (testContact == null) {
            testContact = CFA_TestDataFactory.createContactObject('TestStripe Contact');
            insert testContact;
            createdRecords.add(testContact);
        }
        
        // Create Stripe Product
        Stripe_Product__c stripeProduct = new Stripe_Product__c(
            Name = 'Test Stripe Product',
            Description__c = 'Test Stripe product for unit testing',
            Is_Active__c = true
        );
        insert stripeProduct;
        createdRecords.add(stripeProduct);
        
        // Create Stripe Price
        Stripe_Price__c stripePrice = new Stripe_Price__c(
            Stripe_Product__c = stripeProduct.Id,
            Amount__c = 99.99,
            Currency__c = 'USD',
            Billing_Interval__c = 'month',
            Billing_Interval_Count__c = 1,
            Is_Active__c = true
        );
        insert stripePrice;
        createdRecords.add(stripePrice);
        
        // Create Stripe Payment Method
        Stripe_Payment_Method__c paymentMethod = new Stripe_Payment_Method__c(
            Contact__c = testContact.Id,
            Type__c = 'Card',
            Card_Brand__c = 'Visa',
            Card_Last4__c = '4242',
            Card_Exp_Month__c = 12,
            Card_Exp_Year__c = 2025,
            Is_Default__c = true
        );
        insert paymentMethod;
        createdRecords.add(paymentMethod);
        
        // Create Stripe Subscription
        Stripe_Subscription__c subscription = new Stripe_Subscription__c(
            Contact__c = testContact.Id,
            Stripe_Price__c = stripePrice.Id,
            Stripe_Product__c = stripeProduct.Id,
            Amount__c = 99.99,
            Currency__c = 'USD',
            Status__c = 'Active',
            Current_Period_Start__c = System.now(),
            Current_Period_End__c = System.now().addMonths(1)
        );
        insert subscription;
        createdRecords.add(subscription);
        
        // Create Stripe Payment Transaction
        Stripe_Payment_Transaction__c paymentTransaction = new Stripe_Payment_Transaction__c(
            Contact__c = testContact.Id,
            Stripe_Subscription__c = subscription.Id,
            Amount__c = 99.99,
            Currency__c = 'USD',
            Status__c = 'Succeeded',
            Transaction_Date__c = System.now(),
            Description__c = 'Test payment transaction'
        );
        insert paymentTransaction;
        createdRecords.add(paymentTransaction);
    }
    
    /**
     * @description Profile enum for type safety
     */
    public enum ProfileType {
        SystemAdministrator,
        CFA_Base_User
    }
} 