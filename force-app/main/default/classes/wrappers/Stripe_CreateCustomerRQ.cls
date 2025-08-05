public class Stripe_CreateCustomerRQ {
    public String email;
    public String name;
    public String phone;
    public String description;
    public StripeAddress address;
    public Map<String, String> metadata;
    
    // Nested class for address
    public class StripeAddress {
        public String line1;
        public String line2;
        public String city;
        public String state;
        public String postal_code;
        public String country;
    }
    
    public Stripe_CreateCustomerRQ(Object contactRecord) {
        // Parse contact record and populate fields
        if (contactRecord instanceof Contact) {
            Contact c = (Contact) contactRecord;
            this.email = c.Email;
            this.name = c.FirstName + ' ' + c.LastName;
            this.phone = c.Phone;
            this.description = 'Customer created from Salesforce Contact: ' + c.Id;
            
            // Add metadata
            this.metadata = new Map<String, String>{
                'salesforce_contact_id' => c.Id,
                'salesforce_last_modified' => String.valueOf(c.LastModifiedDate.getTime())
            };
            
            // Add address if available (at least street or city is required)
            if (String.isNotBlank(c.MailingStreet) || String.isNotBlank(c.MailingCity)) {
                this.address = new StripeAddress();
                this.address.line1 = c.MailingStreet;
                this.address.city = c.MailingCity;
                this.address.state = c.MailingState;
                this.address.postal_code = c.MailingPostalCode;
                this.address.country = c.MailingCountry;
            }
        }
    }
    
    /**
     * Static factory method to sync Contact fields to Stripe customer
     * Provides a cleaner API for creating customer requests
     */
    public static Stripe_CreateCustomerRQ syncContactFields(Contact contact) {
        return new Stripe_CreateCustomerRQ(contact);
    }
    
    /**
     * Converts this request object to form-encoded string for Stripe API
     * Handles nested objects, maps, and lists properly
     * @return Form-encoded string
     */
    public String toFormEncoded() {
        List<String> params = new List<String>();
        
        // Simple string fields
        if (String.isNotBlank(email)) {
            params.add('email=' + EncodingUtil.urlEncode(email, 'UTF-8'));
        }
        if (String.isNotBlank(name)) {
            params.add('name=' + EncodingUtil.urlEncode(name, 'UTF-8'));
        }
        if (String.isNotBlank(phone)) {
            params.add('phone=' + EncodingUtil.urlEncode(phone, 'UTF-8'));
        }
        if (String.isNotBlank(description)) {
            params.add('description=' + EncodingUtil.urlEncode(description, 'UTF-8'));
        }
        
        // Map field - metadata
        if (metadata != null && !metadata.isEmpty()) {
            for (String key : metadata.keySet()) {
                String value = metadata.get(key);
                if (String.isNotBlank(value)) {
                    params.add('metadata[' + key + ']=' + EncodingUtil.urlEncode(value, 'UTF-8'));
                }
            }
        }
        
        // Nested object - address
        if (address != null) {
            if (String.isNotBlank(address.line1)) {
                params.add('address[line1]=' + EncodingUtil.urlEncode(address.line1, 'UTF-8'));
            }
            if (String.isNotBlank(address.line2)) {
                params.add('address[line2]=' + EncodingUtil.urlEncode(address.line2, 'UTF-8'));
            }
            if (String.isNotBlank(address.city)) {
                params.add('address[city]=' + EncodingUtil.urlEncode(address.city, 'UTF-8'));
            }
            if (String.isNotBlank(address.state)) {
                params.add('address[state]=' + EncodingUtil.urlEncode(address.state, 'UTF-8'));
            }
            if (String.isNotBlank(address.postal_code)) {
                params.add('address[postal_code]=' + EncodingUtil.urlEncode(address.postal_code, 'UTF-8'));
            }
            if (String.isNotBlank(address.country)) {
                params.add('address[country]=' + EncodingUtil.urlEncode(address.country, 'UTF-8'));
            }
        }
        
        return String.join(params, '&');
    }
} 