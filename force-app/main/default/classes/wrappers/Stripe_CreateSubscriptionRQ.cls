/**
 * @description Request wrapper for Stripe Create Subscription API
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public class Stripe_CreateSubscriptionRQ {
    
    // Required fields
    public String customer { get; set; }
    public List<Stripe_SubscriptionItem> items { get; set; }
    
    // Optional fields
    public String collection_method { get; set; }
    public String payment_behavior { get; set; }
    public Stripe_PaymentSettings payment_settings { get; set; }
    public Map<String, String> metadata { get; set; }
    public String description { get; set; }
    public String trial_period_days { get; set; }
    public String trial_end { get; set; }
    public String default_payment_method { get; set; }
    public String default_source { get; set; }
    public String billing_cycle_anchor { get; set; }
    public String cancel_at_period_end { get; set; }
    public String proration_behavior { get; set; }
    public String expand { get; set; }
    
    // Constructor
    public Stripe_CreateSubscriptionRQ() {
        this.items = new List<Stripe_SubscriptionItem>();
        this.metadata = new Map<String, String>();
        this.payment_settings = new Stripe_PaymentSettings();
    }
    
    /**
     * @description Constructor that accepts a Stripe_Subscription__c record
     * @param subscriptionRecord The Stripe_Subscription__c record to sync
     */
    public Stripe_CreateSubscriptionRQ(Stripe_Subscription__c subscriptionRecord) {
        this();
        validate(subscriptionRecord);
        setValues(subscriptionRecord);
    }
    
    /**
     * @description Set values from Stripe_Subscription__c object to create subscription request
     * @param subscriptionRecord The Stripe_Subscription__c record
     */
    private void setValues(Stripe_Subscription__c subscriptionRecord) {
        // Get the Contact to retrieve Stripe Customer ID (already validated)
        Contact contact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id = :subscriptionRecord.Contact__c LIMIT 1];
        this.customer = contact.Stripe_Customer_ID__c;
        
        // Get the Stripe Price to retrieve Stripe Price ID (already validated)
        Stripe_Price__c price = [SELECT Id, Stripe_Price_ID__c FROM Stripe_Price__c WHERE Id = :subscriptionRecord.Stripe_Price__c LIMIT 1];
        Stripe_SubscriptionItem item = new Stripe_SubscriptionItem();
        item.price = price.Stripe_Price_ID__c;
        item.quantity = 1; // Default to 1, can be made configurable
        this.items.add(item);
        
        // Set collection method (default to charge_automatically)
        this.collection_method = 'charge_automatically';
        
        // Set description if available
        if (String.isNotBlank(subscriptionRecord.Product_Plan_Name__c)) {
            this.description = subscriptionRecord.Product_Plan_Name__c;
        }
        
        // Set metadata with Salesforce record ID for tracking
        this.metadata.put('salesforce_subscription_id', subscriptionRecord.Id);
        this.metadata.put('salesforce_contact_id', subscriptionRecord.Contact__c);
        this.metadata.put('salesforce_last_modified', String.valueOf(subscriptionRecord.LastModifiedDate.getTime()));
        
        // Set payment behavior to default_incomplete if no payment method is attached
        this.payment_behavior = 'default_incomplete';
        
        // Configure payment settings
        this.payment_settings.payment_method_types = new List<String>{'card'};
        this.payment_settings.save_default_payment_method = 'on_subscription';
    }
    
    /**
     * @description Validates that the subscription record has all required fields
     * @param subscriptionRecord The Stripe_Subscription__c record to validate
     * @throws StripeException if validation fails
     */
    private void validate(Stripe_Subscription__c subscriptionRecord) {
        List<String> errors = new List<String>();
        
        // Check if Contact is provided
        if (subscriptionRecord.Contact__c == null) {
            errors.add('Contact is required');
        }
        
        // Check if Stripe Price is provided
        if (subscriptionRecord.Stripe_Price__c == null) {
            errors.add('Stripe Price is required');
        }
        
        // Check if Product Plan Name is provided
        if (String.isBlank(subscriptionRecord.Product_Plan_Name__c)) {
            errors.add('Product Plan Name is required');
        }
        
        // Validate that Contact has a Stripe Customer ID
        if (subscriptionRecord.Contact__c != null) {
            Contact contact = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Id = :subscriptionRecord.Contact__c LIMIT 1];
            if (String.isBlank(contact.Stripe_Customer_ID__c)) {
                errors.add('Contact must have a Stripe Customer ID');
            }
        }
        
        // Validate that Stripe Price has a Stripe Price ID
        if (subscriptionRecord.Stripe_Price__c != null) {
            Stripe_Price__c price = [SELECT Id, Stripe_Price_ID__c FROM Stripe_Price__c WHERE Id = :subscriptionRecord.Stripe_Price__c LIMIT 1];
            if (String.isBlank(price.Stripe_Price_ID__c)) {
                errors.add('Stripe Price must have a Stripe Price ID');
            }
        }
        
        // If there are validation errors, throw an exception
        if (!errors.isEmpty()) {
            throw new StripeException('Subscription validation failed: ' + String.join(errors, ', '));
        }
    }
    
    /**
     * @description Static method for backward compatibility
     * @param subscriptionRecord The Stripe_Subscription__c record
     * @return Stripe_CreateSubscriptionRQ Configured request object
     */
    public static Stripe_CreateSubscriptionRQ syncSubscriptionFields(Stripe_Subscription__c subscriptionRecord) {
        return new Stripe_CreateSubscriptionRQ(subscriptionRecord);
    }
    
    /**
     * @description Convert request directly to form-encoded string
     * @return String Form-encoded request body
     */
    public String toFormEncoded() {
        List<String> params = new List<String>();
        
        // Required: Customer ID
        if (String.isNotBlank(customer)) {
            params.add('customer=' + EncodingUtil.urlEncode(customer, 'UTF-8'));
        }
        
        // Required: Items array
        if (items != null && !items.isEmpty()) {
            for (Integer i = 0; i < items.size(); i++) {
                Stripe_SubscriptionItem item = items[i];
                if (String.isNotBlank(item.price)) {
                    params.add('items[' + i + '][price]=' + EncodingUtil.urlEncode(item.price, 'UTF-8'));
                }
                if (item.quantity != null && item.quantity > 0) {
                    params.add('items[' + i + '][quantity]=' + item.quantity);
                }
                if (String.isNotBlank(item.tax_rates)) {
                    params.add('items[' + i + '][tax_rates][]=' + EncodingUtil.urlEncode(item.tax_rates, 'UTF-8'));
                }
                // Add item metadata if present
                if (item.metadata != null && !item.metadata.isEmpty()) {
                    for (String key : item.metadata.keySet()) {
                        String value = item.metadata.get(key);
                        if (String.isNotBlank(value)) {
                            params.add('items[' + i + '][metadata][' + key + ']=' + EncodingUtil.urlEncode(value, 'UTF-8'));
                        }
                    }
                }
            }
        }
        
        // Optional: Collection method
        if (String.isNotBlank(collection_method)) {
            params.add('collection_method=' + EncodingUtil.urlEncode(collection_method, 'UTF-8'));
        }
        
        // Optional: Payment behavior
        if (String.isNotBlank(payment_behavior)) {
            params.add('payment_behavior=' + EncodingUtil.urlEncode(payment_behavior, 'UTF-8'));
        }
        
        // Optional: Default payment method
        if (String.isNotBlank(default_payment_method)) {
            params.add('default_payment_method=' + EncodingUtil.urlEncode(default_payment_method, 'UTF-8'));
        }
        
        // Optional: Default source
        if (String.isNotBlank(default_source)) {
            params.add('default_source=' + EncodingUtil.urlEncode(default_source, 'UTF-8'));
        }
        
        // Optional: Billing cycle anchor
        if (String.isNotBlank(billing_cycle_anchor)) {
            params.add('billing_cycle_anchor=' + EncodingUtil.urlEncode(billing_cycle_anchor, 'UTF-8'));
        }
        
        // Optional: Cancel at period end
        if (String.isNotBlank(cancel_at_period_end)) {
            params.add('cancel_at_period_end=' + EncodingUtil.urlEncode(cancel_at_period_end, 'UTF-8'));
        }
        
        // Optional: Proration behavior
        if (String.isNotBlank(proration_behavior)) {
            params.add('proration_behavior=' + EncodingUtil.urlEncode(proration_behavior, 'UTF-8'));
        }
        
        // Optional: Payment settings
        if (payment_settings != null) {
            if (payment_settings.payment_method_types != null && !payment_settings.payment_method_types.isEmpty()) {
                for (Integer i = 0; i < payment_settings.payment_method_types.size(); i++) {
                    params.add('payment_settings[payment_method_types][' + i + ']=' + 
                              EncodingUtil.urlEncode(payment_settings.payment_method_types[i], 'UTF-8'));
                }
            }
            if (String.isNotBlank(payment_settings.save_default_payment_method)) {
                params.add('payment_settings[save_default_payment_method]=' + 
                          EncodingUtil.urlEncode(payment_settings.save_default_payment_method, 'UTF-8'));
            }
            if (payment_settings.payment_method_options != null && !payment_settings.payment_method_options.isEmpty()) {
                for (String key : payment_settings.payment_method_options.keySet()) {
                    String value = payment_settings.payment_method_options.get(key);
                    if (String.isNotBlank(value)) {
                        params.add('payment_settings[payment_method_options][' + key + ']=' + 
                                  EncodingUtil.urlEncode(value, 'UTF-8'));
                    }
                }
            }
        }
        
        // Optional: Metadata
        if (metadata != null && !metadata.isEmpty()) {
            for (String key : metadata.keySet()) {
                String value = metadata.get(key);
                if (String.isNotBlank(value)) {
                    params.add('metadata[' + key + ']=' + EncodingUtil.urlEncode(value, 'UTF-8'));
                }
            }
        }
        
        // Optional: Description
        if (String.isNotBlank(description)) {
            params.add('description=' + EncodingUtil.urlEncode(description, 'UTF-8'));
        }
        
        // Optional: Trial period days
        if (String.isNotBlank(trial_period_days)) {
            params.add('trial_period_days=' + EncodingUtil.urlEncode(trial_period_days, 'UTF-8'));
        }
        
        // Optional: Trial end timestamp
        if (String.isNotBlank(trial_end)) {
            params.add('trial_end=' + EncodingUtil.urlEncode(trial_end, 'UTF-8'));
        }
        
        // Optional: Expand parameter
        if (String.isNotBlank(expand)) {
            params.add('expand=' + EncodingUtil.urlEncode(expand, 'UTF-8'));
        }
        
        return String.join(params, '&');
    }
    
    /**
     * @description Add a subscription item to the request
     * @param priceId Stripe price ID
     * @param quantity Quantity (defaults to 1)
     * @param taxRates Tax rate IDs (optional)
     * @param itemMetadata Item-specific metadata (optional)
     */
    public void addItem(String priceId, Integer quantity, String taxRates, Map<String, String> itemMetadata) {
        Stripe_SubscriptionItem item = new Stripe_SubscriptionItem();
        item.price = priceId;
        item.quantity = quantity != null ? quantity : 1;
        item.tax_rates = taxRates;
        if (itemMetadata != null) {
            item.metadata = itemMetadata;
        }
        items.add(item);
    }
    
    /**
     * @description Add a subscription item with default quantity of 1
     * @param priceId Stripe price ID
     */
    public void addItem(String priceId) {
        addItem(priceId, 1, null, null);
    }
} 