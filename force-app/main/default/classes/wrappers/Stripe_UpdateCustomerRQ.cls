// alternataive don't use a specific class
// just map<string, object> for update call

public class Stripe_UpdateCustomerRQ {
    // All possible fields (all optional for updates)
    public String email;
    public String name;
    public String phone;
    public String description;
    public Map<String, String> metadata;
    public StripeAddress address;
    public StripeShipping shipping;
    public String tax_exempt;
    public String default_source;
    public Integer balance;
    public String invoice_prefix;
    public Integer next_invoice_sequence;
    public List<String> preferred_locales;
    
    // Nested classes for complex objects
    public class StripeAddress {
        public String line1;
        public String line2;
        public String city;
        public String state;
        public String postal_code;
        public String country;
    }
    
    public class StripeShipping {
        public StripeAddress address;
        public String name;
        public String phone;
    }
    
    // Private constructor - use builder
    private Stripe_UpdateCustomerRQ() {}
    
    // Builder class for fluent API
    public class Builder {
        private Stripe_UpdateCustomerRQ request;
        
        public Builder() {
            this.request = new Stripe_UpdateCustomerRQ();
        }
        
        public Builder setEmail(String email) {
            request.email = email;
            return this;
        }
        
        public Builder setName(String name) {
            request.name = name;
            return this;
        }
        
        public Builder setPhone(String phone) {
            request.phone = phone;
            return this;
        }
        
        public Builder setDescription(String description) {
            request.description = description;
            return this;
        }
        
        public Builder setMetadata(Map<String, String> metadata) {
            request.metadata = metadata;
            return this;
        }
        
        public Builder addMetadata(String key, String value) {
            if (request.metadata == null) {
                request.metadata = new Map<String, String>();
            }
            request.metadata.put(key, value);
            return this;
        }
        
        public Builder setAddress(String line1, String city, String state, String postalCode, String country) {
            // Only set address if we have at least line1 or city
            if (String.isNotBlank(line1) || String.isNotBlank(city)) {
                request.address = new StripeAddress();
                request.address.line1 = line1;
                request.address.city = city;
                request.address.state = state;
                request.address.postal_code = postalCode;
                request.address.country = country;
            }
            return this;
        }
        
        /**
         * Set address from Contact mailing address fields
         * Only sets address if at least street or city is populated
         */
        public Builder setAddressFromContact(Contact contact) {
            return setAddress(
                contact.MailingStreet,
                contact.MailingCity,
                contact.MailingState,
                contact.MailingPostalCode,
                contact.MailingCountry
            );
        }
        
        /**
         * Set all fields from Contact for Stripe sync
         * Includes email, name, phone, address, and metadata
         */
        public Builder setFromContact(Contact contact) {
            setEmail(contact.Email);
            setName(contact.FirstName + ' ' + contact.LastName);
            setPhone(contact.Phone);
            setAddressFromContact(contact);
            addMetadata('salesforce_contact_id', contact.Id);
            Long timestamp = contact.LastModifiedDate.getTime();
            Logger.info('Setting Stripe metadata - Contact: ' + contact.Id + ', Timestamp: ' + timestamp + ', LastModifiedDate: ' + contact.LastModifiedDate).addTag('TIMESTAMP_DEBUG');
            Logger.saveLog();
            addMetadata('salesforce_last_modified', String.valueOf(timestamp));
            return this;
        }
        
        public Builder setAddress(StripeAddress address) {
            request.address = address;
            return this;
        }
        
        public Builder setShipping(String name, String phone, StripeAddress address) {
            request.shipping = new StripeShipping();
            request.shipping.name = name;
            request.shipping.phone = phone;
            request.shipping.address = address;
            return this;
        }
        
        public Builder setTaxExempt(String taxExempt) {
            request.tax_exempt = taxExempt;
            return this;
        }
        
        public Builder setDefaultSource(String defaultSource) {
            request.default_source = defaultSource;
            return this;
        }
        
        public Builder setBalance(Integer balance) {
            request.balance = balance;
            return this;
        }
        
        public Builder setInvoicePrefix(String invoicePrefix) {
            request.invoice_prefix = invoicePrefix;
            return this;
        }
        
        public Builder setNextInvoiceSequence(Integer nextInvoiceSequence) {
            request.next_invoice_sequence = nextInvoiceSequence;
            return this;
        }
        
        public Builder setPreferredLocales(List<String> preferredLocales) {
            request.preferred_locales = preferredLocales;
            return this;
        }
        
        public Stripe_UpdateCustomerRQ build() {
            return request;
        }
    }
    
    // Static method to start building
    public static Builder builder() {
        return new Builder();
    }
    
    /**
     * Static factory method to sync Contact fields to Stripe customer
     * Provides a cleaner API for creating update requests
     */
    public static Stripe_UpdateCustomerRQ syncContactFields(Contact contact) {
        return builder().setFromContact(contact).build();
    }
    
    /**
     * Converts this request object to form-encoded string for Stripe API
     * Handles nested objects, maps, and lists properly
     * @return Form-encoded string
     */
    public String toFormEncoded() {
        List<String> params = new List<String>();
        
        // Simple string and integer fields using reflection
        Map<String, Object> simpleFields = new Map<String, Object>{
            'email' => email,
            'name' => name,
            'phone' => phone,
            'description' => description,
            'tax_exempt' => tax_exempt,
            'default_source' => default_source,
            'invoice_prefix' => invoice_prefix,
            'balance' => balance,
            'next_invoice_sequence' => next_invoice_sequence
        };
        
        for (String fieldName : simpleFields.keySet()) {
            Object value = simpleFields.get(fieldName);
            if (value != null && String.isNotBlank(String.valueOf(value))) {
                params.add(fieldName + '=' + EncodingUtil.urlEncode(String.valueOf(value), 'UTF-8'));
            }
        }
        
        // List field - preferred_locales
        if (preferred_locales != null && !preferred_locales.isEmpty()) {
            for (String locale : preferred_locales) {
                if (String.isNotBlank(locale)) {
                    params.add('preferred_locales[]=' + EncodingUtil.urlEncode(locale, 'UTF-8'));
                }
            }
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
        
        // Nested object - shipping
        if (shipping != null) {
            if (String.isNotBlank(shipping.name)) {
                params.add('shipping[name]=' + EncodingUtil.urlEncode(shipping.name, 'UTF-8'));
            }
            if (String.isNotBlank(shipping.phone)) {
                params.add('shipping[phone]=' + EncodingUtil.urlEncode(shipping.phone, 'UTF-8'));
            }
            
            // Nested address within shipping
            if (shipping.address != null) {
                if (String.isNotBlank(shipping.address.line1)) {
                    params.add('shipping[address][line1]=' + EncodingUtil.urlEncode(shipping.address.line1, 'UTF-8'));
                }
                if (String.isNotBlank(shipping.address.line2)) {
                    params.add('shipping[address][line2]=' + EncodingUtil.urlEncode(shipping.address.line2, 'UTF-8'));
                }
                if (String.isNotBlank(shipping.address.city)) {
                    params.add('shipping[city]=' + EncodingUtil.urlEncode(shipping.address.city, 'UTF-8'));
                }
                if (String.isNotBlank(shipping.address.state)) {
                    params.add('shipping[state]=' + EncodingUtil.urlEncode(shipping.address.state, 'UTF-8'));
                }
                if (String.isNotBlank(shipping.address.postal_code)) {
                    params.add('shipping[postal_code]=' + EncodingUtil.urlEncode(shipping.address.postal_code, 'UTF-8'));
                }
                if (String.isNotBlank(shipping.address.country)) {
                    params.add('shipping[country]=' + EncodingUtil.urlEncode(shipping.address.country, 'UTF-8'));
                }
            }
        }
        
        return String.join(params, '&');
    }
} 