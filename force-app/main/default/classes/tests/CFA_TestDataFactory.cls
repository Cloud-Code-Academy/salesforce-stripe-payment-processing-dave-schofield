/**
 * @description Test Data Factory for Cloud Fitness Academy
 * Provides static methods for creating test data with proper relationships
 */
@isTest
public class CFA_TestDataFactory {
    
    /**
     * @description Profile enum for type safety
     */
    public enum ProfileType {
        SystemAdministrator,
        CFA_Base_User
    }
    
    /**
     * @description Create a basic contact with required fields
     * @param name The full name for the contact
     * @return Contact The created contact record
     */
    public static Contact createContact(String name) {
        String[] nameParts = name.split(' ', 2);
        String firstName = nameParts[0];
        String lastName = nameParts.size() > 1 ? nameParts[1] : 'Contact';
        
        Contact contact = new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@test.com',
            Phone = '555-123-4567'
        );
        
        insert contact;
        return contact;
    }
    
    /**
     * @description Create a basic contact object without inserting (for use in builders)
     * @param name The full name for the contact
     * @return Contact The contact object (not inserted)
     */
    public static Contact createContactObject(String name) {
        String[] nameParts = name.split(' ', 2);
        String firstName = nameParts[0];
        String lastName = nameParts.size() > 1 ? nameParts[1] : 'Contact';
        
        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@test.com',
            Phone = '555-123-4567'
        );
    }
    
    /**
     * @description Create a contact with fitness-specific fields
     * @param name The full name for the contact
     * @param fitnessGoals The fitness goals
     * @param experienceLevel The experience level
     * @return Contact The created contact record
     */
    public static Contact createFitnessContact(String name, String fitnessGoals, String experienceLevel) {
        Contact contact = createContact(name);
        
        contact.CFA_Fitness_Goals__c = fitnessGoals;
        contact.CFA_Experience_Level__c = experienceLevel;
        contact.CFA_Sports_Activity_Interests__c = 'Running, Weight Training';
        contact.CFA_Health_Conditions__c = 'None';
        contact.CFA_Emergency_Contact_Name__c = 'Emergency Contact';
        contact.CFA_Emergency_Contact_Phone__c = '555-999-8888';
        
        update contact;
        return contact;
    }
    
    /**
     * @description Create a fitness contact object without inserting (for use in builders)
     * @param name The full name for the contact
     * @param fitnessGoals The fitness goals
     * @param experienceLevel The experience level
     * @return Contact The contact object (not inserted)
     */
    public static Contact createFitnessContactObject(String name, String fitnessGoals, String experienceLevel) {
        String[] nameParts = name.split(' ', 2);
        String firstName = nameParts[0];
        String lastName = nameParts.size() > 1 ? nameParts[1] : 'Contact';
        
        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@test.com',
            Phone = '555-123-4567',
            CFA_Fitness_Goals__c = fitnessGoals,
            CFA_Experience_Level__c = experienceLevel,
            CFA_Sports_Activity_Interests__c = 'Running, Weight Training',
            CFA_Health_Conditions__c = 'None',
            CFA_Emergency_Contact_Name__c = 'Emergency Contact',
            CFA_Emergency_Contact_Phone__c = '555-999-8888'
        );
    }
    
    /**
     * @description Create a basic fitness product
     * @param name The product name
     * @param category The product category
     * @param basePrice The base price
     * @return CFA_Fitness_Product__c The created product record
     */
    public static CFA_Fitness_Product__c createFitnessProduct(String name, String category, Decimal basePrice) {
        CFA_Fitness_Product__c product = new CFA_Fitness_Product__c(
            Description__c = 'Test product: ' + name,
            Base_Price__c = basePrice,
            Category__c = category,
            Inventory_Quantity__c = 100,
            SKU__c = 'SKU-' + name.replaceAll('\\s+', '-').toUpperCase(),
            Is_Active__c = true
        );
        
        insert product;
        return product;
    }
    
    /**
     * @description Create a coaching session
     * @param contactId The contact ID
     * @param coachId The coach (user) ID
     * @param sessionDate The session date
     * @param amount The session amount
     * @return CFA_Coaching_Session__c The created session record
     */
    public static CFA_Coaching_Session__c createCoachingSession(Id contactId, Id coachId, DateTime sessionDate, Decimal amount) {
        CFA_Coaching_Session__c session = new CFA_Coaching_Session__c(
            Contact__c = contactId,
            Coach__c = coachId,
            Session_Date__c = sessionDate,
            Status__c = 'Scheduled',
            Amount__c = amount,
            Payment_Status__c = 'Pending',
            Duration_Minutes__c = 60,
            Session_Type__c = 'Initial Consultation',
            Session_Notes__c = 'Test coaching session'
        );
        
        insert session;
        return session;
    }
    
    /**
     * @description Create a Stripe product
     * @param name The product name
     * @param description The product description
     * @return Stripe_Product__c The created product record
     */
    public static Stripe_Product__c createStripeProduct(String name, String description) {
        Stripe_Product__c product = new Stripe_Product__c(
            Description__c = description,
            Is_Active__c = true
        );
        
        insert product;
        return product;
    }
    
    /**
     * @description Create a Stripe price
     * @param productId The Stripe product ID
     * @param amount The price amount
     * @param currencyCode The currency code
     * @param billingInterval The billing interval
     * @return Stripe_Price__c The created price record
     */
    public static Stripe_Price__c createStripePrice(Id productId, Decimal amount, String currencyCode, String billingInterval) {
        Stripe_Price__c price = new Stripe_Price__c(
            Stripe_Product__c = productId,
            Amount__c = amount,
            Currency__c = currencyCode,
            Billing_Interval__c = billingInterval,
            Billing_Interval_Count__c = 1,
            Is_Active__c = true
        );
        
        insert price;
        return price;
    }
    
    /**
     * @description Create a Stripe subscription
     * @param contactId The contact ID
     * @param priceId The Stripe price ID
     * @param amount The subscription amount
     * @param currencyCode The currency code
     * @return Stripe_Subscription__c The created subscription record
     */
    public static Stripe_Subscription__c createStripeSubscription(Id contactId, Id priceId, Decimal amount, String currencyCode) {
        Stripe_Subscription__c subscription = new Stripe_Subscription__c(
            Contact__c = contactId,
            Stripe_Price__c = priceId,
            Amount__c = amount,
            Currency__c = currencyCode,
            Status__c = 'Active',
            Current_Period_Start__c = System.now(),
            Current_Period_End__c = System.now().addMonths(1)
        );
        
        insert subscription;
        return subscription;
    }
    
    /**
     * @description Create a Stripe payment method
     * @param contactId The contact ID
     * @param type The payment method type
     * @param cardBrand The card brand
     * @param cardLast4 The last 4 digits
     * @return Stripe_Payment_Method__c The created payment method record
     */
    public static Stripe_Payment_Method__c createStripePaymentMethod(Id contactId, String type, String cardBrand, String cardLast4) {
        Stripe_Payment_Method__c paymentMethod = new Stripe_Payment_Method__c(
            Contact__c = contactId,
            Type__c = type,
            Card_Brand__c = cardBrand,
            Card_Last4__c = cardLast4,
            Card_Exp_Month__c = 12,
            Card_Exp_Year__c = 2025,
            Is_Default__c = true
        );
        
        insert paymentMethod;
        return paymentMethod;
    }
    
    /**
     * @description Create a Stripe payment transaction
     * @param contactId The contact ID
     * @param subscriptionId The subscription ID
     * @param amount The transaction amount
     * @param currencyCode The currency code
     * @param status The transaction status
     * @return Stripe_Payment_Transaction__c The created transaction record
     */
    public static Stripe_Payment_Transaction__c createStripePaymentTransaction(Id contactId, Id subscriptionId, Decimal amount, String currencyCode, String status) {
        Stripe_Payment_Transaction__c paymentTransaction = new Stripe_Payment_Transaction__c(
            Contact__c = contactId,
            Stripe_Subscription__c = subscriptionId,
            Amount__c = amount,
            Currency__c = currencyCode,
            Status__c = status,
            Transaction_Date__c = System.now(),
            Description__c = 'Test payment transaction'
        );
        
        insert paymentTransaction;
        return paymentTransaction;
    }
} 