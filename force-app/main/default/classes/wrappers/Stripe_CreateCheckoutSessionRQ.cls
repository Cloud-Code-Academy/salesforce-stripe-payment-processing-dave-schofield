public class Stripe_CreateCheckoutSessionRQ {
    public String customer;
    public String mode;
    public List<LineItem> line_items;
    public String success_url;
    public String cancel_url;
    public Map<String, String> metadata;
    public SubscriptionData subscription_data;
    
    // Nested class for line items
    public class LineItem {
        public String price;
        public Integer quantity;
        
        public LineItem(String priceId, Integer qty) {
            this.price = priceId;
            this.quantity = qty;
        }
    }
    
    // Nested class for subscription data
    public class SubscriptionData {
        public Map<String, String> metadata;
        
        public SubscriptionData(Map<String, String> meta) {
            this.metadata = meta;
        }
    }
    
    /**
     * Constructor for creating checkout session from Salesforce subscription record
     * Gets customer ID and price ID from the subscription record relationships
     * @param subscriptionRecord The Stripe_Subscription__c record with Contact and Price relationships
     */
    public Stripe_CreateCheckoutSessionRQ(Stripe_Subscription__c subscriptionRecord) {
        // Get customer ID from related Contact
        this.customer = subscriptionRecord.Contact__r.Stripe_Customer_ID__c;
        
        // Get price ID from related Price record
        String priceId = subscriptionRecord.Stripe_Price__r.Stripe_Price_ID__c;
        
        this.mode = 'subscription';
        this.line_items = new List<LineItem>{ new LineItem(priceId, 1) };
        
        // Default URLs - can be overridden
        // @TestVisible
        Stripe_Sync__mdt stripeSettings = Stripe_Sync__mdt.getInstance('Settings');
        this.success_url = stripeSettings.Checkout_Success_URL__c;
        this.cancel_url = stripeSettings.Checkout_Error_URL__c;
        
        // Add metadata for tracking
        this.metadata = new Map<String, String>{
            'salesforce_subscription_id' => subscriptionRecord.Id,
            'created_from' => 'salesforce',
            'created_at' => String.valueOf(Datetime.now().getTime())
        };
        
        // Link the subscription to the checkout session
        this.subscription_data = new SubscriptionData(new Map<String, String>{
            'salesforce_subscription_id' => subscriptionRecord.Id
        });
    }
    
    /**
     * Constructor with custom URLs
     * @param subscriptionRecord The Stripe_Subscription__c record with Contact and Price relationships
     * @param successUrl Custom success URL
     * @param cancelUrl Custom cancel URL
     */
    public Stripe_CreateCheckoutSessionRQ(Stripe_Subscription__c subscriptionRecord, String successUrl, String cancelUrl) {
        this(subscriptionRecord);
        
        if (String.isNotBlank(successUrl)) {
            this.success_url = successUrl;
        }
        if (String.isNotBlank(cancelUrl)) {
            this.cancel_url = cancelUrl;
        }
    }
    
    /**
     * Static factory method for easier usage - follows pattern from Stripe_CreateCustomerRQ.syncContactFields()
     * @param subscriptionRecord The Stripe_Subscription__c record with Contact and Price relationships
     * @return Configured checkout session request
     */
    public static Stripe_CreateCheckoutSessionRQ forSubscription(Stripe_Subscription__c subscriptionRecord) {
        return new Stripe_CreateCheckoutSessionRQ(subscriptionRecord);
    }
    
    /**
     * Converts this request object to form-encoded string for Stripe API
     * Handles nested objects, maps, and lists properly
     * @return Form-encoded string
     */
    public String toFormEncoded() {
        List<String> params = new List<String>();
        
        // Simple string fields
        if (String.isNotBlank(customer)) {
            params.add('customer=' + EncodingUtil.urlEncode(customer, 'UTF-8'));
        }
        if (String.isNotBlank(mode)) {
            params.add('mode=' + EncodingUtil.urlEncode(mode, 'UTF-8'));
        }
        if (String.isNotBlank(success_url)) {
            params.add('success_url=' + EncodingUtil.urlEncode(success_url, 'UTF-8'));
        }
        if (String.isNotBlank(cancel_url)) {
            params.add('cancel_url=' + EncodingUtil.urlEncode(cancel_url, 'UTF-8'));
        }
        
        // Line items array
        if (line_items != null && !line_items.isEmpty()) {
            for (Integer i = 0; i < line_items.size(); i++) {
                LineItem item = line_items[i];
                if (String.isNotBlank(item.price)) {
                    params.add('line_items[' + i + '][price]=' + EncodingUtil.urlEncode(item.price, 'UTF-8'));
                }
                if (item.quantity != null) {
                    params.add('line_items[' + i + '][quantity]=' + String.valueOf(item.quantity));
                }
            }
        }
        
        // Metadata map
        if (metadata != null && !metadata.isEmpty()) {
            for (String key : metadata.keySet()) {
                String value = metadata.get(key);
                if (String.isNotBlank(value)) {
                    params.add('metadata[' + key + ']=' + EncodingUtil.urlEncode(value, 'UTF-8'));
                }
            }
        }
        
        // Subscription data metadata
        if (subscription_data != null && subscription_data.metadata != null && !subscription_data.metadata.isEmpty()) {
            for (String key : subscription_data.metadata.keySet()) {
                String value = subscription_data.metadata.get(key);
                if (String.isNotBlank(value)) {
                    params.add('subscription_data[metadata][' + key + ']=' + EncodingUtil.urlEncode(value, 'UTF-8'));
                }
            }
        }
        
        return String.join(params, '&');
    }
}