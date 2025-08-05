/**
 * @description Represents individual subscription item data in Stripe API responses
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public class Stripe_SubscriptionItemData {
    
    // Basic fields
    public String id { get; set; }
    public String object_type { get; set; }
    public Long created { get; set; }
    public Integer quantity { get; set; }
    
    // Price information
    public Stripe_Price price { get; set; }
    
    // Subscription information
    public String subscription { get; set; }
    
    // Metadata
    public Map<String, String> metadata { get; set; }
    
    // Constructor
    public Stripe_SubscriptionItemData() {
        this.metadata = new Map<String, String>();
    }
    
    /**
     * @description Parse subscription item data from JSON response
     * @param itemMap Map containing item data from Stripe
     * @return Stripe_SubscriptionItemData Parsed item object
     */
    public static Stripe_SubscriptionItemData parse(Map<String, Object> itemMap) {
        Stripe_SubscriptionItemData item = new Stripe_SubscriptionItemData();
        
        // Parse basic fields
        item.id = (String) itemMap.get('id');
        item.object_type = (String) itemMap.get('object');
        item.created = (Long) itemMap.get('created');
        item.quantity = (Integer) itemMap.get('quantity');
        item.subscription = (String) itemMap.get('subscription');
        
        // Parse price object
        if (itemMap.containsKey('price') && itemMap.get('price') != null) {
            Map<String, Object> priceMap = (Map<String, Object>) itemMap.get('price');
            item.price = Stripe_Price.parse(priceMap);
        }
        
        // Parse metadata
        if (itemMap.containsKey('metadata') && itemMap.get('metadata') != null) {
            Map<String, Object> metadataMap = (Map<String, Object>) itemMap.get('metadata');
            for (String key : metadataMap.keySet()) {
                Object value = metadataMap.get(key);
                if (value != null) {
                    item.metadata.put(key, String.valueOf(value));
                }
            }
        }
        
        return item;
    }
    
    /**
     * @description Get the price ID from the price object
     * @return String Price ID or null
     */
    public String getPriceId() {
        return price != null ? price.id : null;
    }
    
    /**
     * @description Get the unit amount from the price object
     * @return Integer Unit amount in cents or null
     */
    public Integer getUnitAmount() {
        return price != null ? price.unit_amount : null;
    }
    
    /**
     * @description Get the currency from the price object
     * @return String Currency code or null
     */
    public String getCurrency() {
        return price != null ? price.currency_x : null;
    }
} 