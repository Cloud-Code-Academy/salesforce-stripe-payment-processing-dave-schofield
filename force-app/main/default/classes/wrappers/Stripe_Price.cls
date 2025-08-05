/**
 * @description Represents price information in Stripe API responses
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public class Stripe_Price {
    
    // Basic fields
    public String id { get; set; }
    public String object_type { get; set; }
    public Boolean active { get; set; }
    public Long created { get; set; }
    public String currency_x;
    public String product { get; set; }
    public Integer unit_amount { get; set; }
    public String unit_amount_decimal { get; set; }
    
    // Recurring information
    public Stripe_Recurring recurring { get; set; }
    
    // Metadata
    public Map<String, String> metadata { get; set; }
    
    // Constructor
    public Stripe_Price() {
        this.metadata = new Map<String, String>();
    }
    
    /**
     * @description Parse price data from JSON response
     * @param priceMap Map containing price data from Stripe
     * @return Stripe_Price Parsed price object
     */
    public static Stripe_Price parse(Map<String, Object> priceMap) {
        Stripe_Price price = new Stripe_Price();
        
        // Parse basic fields
        price.id = (String) priceMap.get('id');
        price.object_type = (String) priceMap.get('object');
        price.active = (Boolean) priceMap.get('active');
        price.created = (Long) priceMap.get('created');
        price.currency_x = (String) priceMap.get('currency');
        price.product = (String) priceMap.get('product');
        price.unit_amount = (Integer) priceMap.get('unit_amount');
        price.unit_amount_decimal = (String) priceMap.get('unit_amount_decimal');
        
        // Parse recurring information
        if (priceMap.containsKey('recurring') && priceMap.get('recurring') != null) {
            Map<String, Object> recurringMap = (Map<String, Object>) priceMap.get('recurring');
            price.recurring = Stripe_Recurring.parse(recurringMap);
        }
        
        // Parse metadata
        if (priceMap.containsKey('metadata') && priceMap.get('metadata') != null) {
            Map<String, Object> metadataMap = (Map<String, Object>) priceMap.get('metadata');
            for (String key : metadataMap.keySet()) {
                Object value = metadataMap.get(key);
                if (value != null) {
                    price.metadata.put(key, String.valueOf(value));
                }
            }
        }
        
        return price;
    }
    
    /**
     * @description Get the billing interval (month, year, etc.)
     * @return String Billing interval or null
     */
    public String getBillingInterval() {
        return recurring != null ? recurring.interval : null;
    }
    
    /**
     * @description Get the interval count
     * @return Integer Interval count or null
     */
    public Integer getIntervalCount() {
        return recurring != null ? recurring.interval_count : null;
    }
    
    /**
     * @description Check if this is a recurring price
     * @return Boolean True if recurring
     */
    public Boolean isRecurring() {
        return recurring != null;
    }
} 