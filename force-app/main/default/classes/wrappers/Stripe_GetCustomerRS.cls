public class Stripe_GetCustomerRS {
    public String id;
    public String object_x;
    public StripeAddress address;
    public Integer balance;
    public Long created;
    public String currency_x;
    public String default_source;
    public Boolean delinquent;
    public String description;
    public String discount; // Changed from Object to String - can be JSON string if needed
    public String email;
    public String invoice_prefix;
    public StripeInvoiceSettings invoice_settings;
    public Boolean livemode;
    public StripeMetadata metadata;
    public String name;
    public Integer next_invoice_sequence;
    public String phone;
    public List<String> preferred_locales; // Changed from List<Object> to List<String>
    public StripeAddress shipping; // Changed from String to StripeAddress - same structure as address
    public String tax_exempt;
    public String test_clock; // Changed from Object to String - can be JSON string if needed
    
    // Nested class for address
    public class StripeAddress {
        public String city;
        public String country;
        public String line1;
        public String line2;
        public String postal_code;
        public String state;
    }
    
    // Nested class for metadata
    public class StripeMetadata {
        public String salesforce_contact_id;
        public String salesforce_last_modified;
    }
    
    // Nested class for invoice_settings
    public class StripeInvoiceSettings {
        public String custom_fields; // Changed from Map to String since it's null in sample
        public String default_payment_method;
        public String footer;
        public String rendering_options; // Changed from Map to String since it's null in sample
    }
    
    // Handle the 'currency' field name conflict with Apex reserved word
    public void setCurrency_x(String currency_x) {
        this.currency_x = currency_x;
    }
} 