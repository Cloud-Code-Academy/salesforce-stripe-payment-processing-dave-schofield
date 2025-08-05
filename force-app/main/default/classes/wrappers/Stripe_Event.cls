public class Stripe_Event {
    public String id;
    public String object_type;
    public String api_version;
    public Long created;
    public Stripe_EventData data;
    public Boolean livemode;
    public Integer pending_webhooks;
    public Stripe_EventRequest request;
    public String type;
    
    /**
     * Constructor that parses JSON payload into Stripe_Event
     * @param jsonPayload The raw JSON string from webhook
     */
    public Stripe_Event(String jsonPayload) {
        Stripe_Event parsed = parse(jsonPayload);
        this.id = parsed.id;
        this.object_type = parsed.object_type;
        this.api_version = parsed.api_version;
        this.created = parsed.created;
        this.data = parsed.data;
        this.livemode = parsed.livemode;
        this.pending_webhooks = parsed.pending_webhooks;
        this.request = parsed.request;
        this.type = parsed.type;
    }
    
    /**
     * Default constructor for manual creation (e.g., tests)
     */
    public Stripe_Event() {
        // Default constructor
    }
    
    /**
     * Parses a JSON string into a Stripe_Event object
     * @param jsonString The JSON string from the webhook payload
     * @return Stripe_Event object
     */
    public static Stripe_Event parse(String jsonString) {
        try {
            // Parse to untyped Map first to handle reserved keywords
            Map<String, Object> eventMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            
            // Rename reserved keyword fields
            renameKey(eventMap, 'object', 'object_type');
            
            // Handle data section
            Map<String, Object> dataMap = (Map<String, Object>) eventMap.get('data');
            if (dataMap != null) {
                renameKey(dataMap, 'object', 'object_data');
                
                // Handle nested object inside data
                Map<String, Object> objectDataMap = (Map<String, Object>) dataMap.get('object_data');
                if (objectDataMap != null) {
                    renameKey(objectDataMap, 'object', 'object_name');
                }
            }
            
            // Manually map to Stripe_Event to avoid Object type issues
            Stripe_Event event = new Stripe_Event();
            event.id = (String) eventMap.get('id');
            event.object_type = (String) eventMap.get('object_type');
            event.api_version = (String) eventMap.get('api_version');
            event.created = (Long) eventMap.get('created');
            event.livemode = (Boolean) eventMap.get('livemode');
            event.pending_webhooks = (Integer) eventMap.get('pending_webhooks');
            event.type = (String) eventMap.get('type');
            
            // Handle data section
            if (dataMap != null) {
                event.data = new Stripe_EventData();
                event.data.object_data = (Map<String, Object>) dataMap.get('object_data');
            }
            
            // Handle request section
            Map<String, Object> requestMap = (Map<String, Object>) eventMap.get('request');
            if (requestMap != null) {
                event.request = new Stripe_EventRequest();
                event.request.id = (String) requestMap.get('id');
                event.request.idempotency_key = (String) requestMap.get('idempotency_key');
            }
            
            return event;
        } catch (Exception e) {
            Logger.error('Failed to parse Stripe event JSON: ' + e.getMessage()).addTag('DEBUG');
            Logger.saveLog();
            throw new Stripe_WebhookException('Invalid webhook payload format: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to rename keys in a Map to avoid reserved keywords
     * @param mapToModify The map to modify
     * @param oldKey The key to rename
     * @param newKey The new key name
     */
    private static void renameKey(Map<String, Object> mapToModify, String oldKey, String newKey) {
        if (mapToModify != null && mapToModify.containsKey(oldKey)) {
            mapToModify.put(newKey, mapToModify.get(oldKey));
            mapToModify.remove(oldKey);
        }
    }
    
    /**
     * Gets the event object data as a Map for flexible access
     * @return Map containing the event object data
     */
    public Map<String, Object> getObjectData() {
        if (data != null && data.object_data != null) {
            return data.object_data;
        }
        return new Map<String, Object>();
    }
    
    /**
     * Gets the event object data as a specific type
     * @param targetType The target class type
     * @return Cast object data
     */
    public Map<String, Object> getObjectDataAs(Type targetType) {
        if (data != null && data.object_data != null) {
            return data.object_data;
        }
        return new Map<String, Object>();
    }
    
    /**
     * Checks if this is a customer-related event
     * @return true if customer event
     */
    public Boolean isCustomerEvent() {
        return type.startsWith('customer.');
    }
    
    /**
     * Checks if this is a subscription-related event
     * @return true if subscription event
     */
    public Boolean isSubscriptionEvent() {
        return type.startsWith('subscription.');
    }
    
    /**
     * Checks if this is a payment-related event
     * @return true if payment event
     */
    public Boolean isPaymentEvent() {
        return type.startsWith('payment_intent.') || type.startsWith('invoice.payment_');
    }
    
    /**
     * Checks if this is an invoice-related event
     * @return true if invoice event
     */
    public Boolean isInvoiceEvent() {
        return type.startsWith('invoice.');
    }
    
    public class Stripe_EventData {
        public Map<String, Object> object_data; // Mapped from "object" field in JSON (renamed to avoid reserved keyword)
    }
    
    public class Stripe_EventRequest {
        public String id;
        public String idempotency_key;
    }
} 