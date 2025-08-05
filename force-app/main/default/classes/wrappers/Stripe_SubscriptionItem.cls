/**
 * @description Represents a subscription item in Stripe
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public class Stripe_SubscriptionItem {
    
    // Required fields
    public String price { get; set; }
    public Integer quantity { get; set; }
    
    // Optional fields
    public String tax_rates { get; set; }
    public Map<String, String> metadata { get; set; }
    
    // Constructor
    public Stripe_SubscriptionItem() {
        this.quantity = 1; // Default quantity
        this.metadata = new Map<String, String>();
    }
    
    /**
     * @description Constructor with price ID
     * @param priceId Stripe price ID
     */
    public Stripe_SubscriptionItem(String priceId) {
        this();
        this.price = priceId;
    }
    
    /**
     * @description Constructor with price ID and quantity
     * @param priceId Stripe price ID
     * @param quantity Quantity of items
     */
    public Stripe_SubscriptionItem(String priceId, Integer quantity) {
        this(priceId);
        this.quantity = quantity != null ? quantity : 1;
    }
} 