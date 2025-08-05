/**
 * @description Represents recurring billing information in Stripe API responses
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public class Stripe_Recurring {
    
    // Recurring fields
    public String interval { get; set; }
    public Integer interval_count { get; set; }
    public String usage_type { get; set; }
    
    // Constructor
    public Stripe_Recurring() {
        this.interval_count = 1; // Default to 1
    }
    
    /**
     * @description Parse recurring data from JSON response
     * @param recurringMap Map containing recurring data from Stripe
     * @return Stripe_Recurring Parsed recurring object
     */
    public static Stripe_Recurring parse(Map<String, Object> recurringMap) {
        Stripe_Recurring recurring = new Stripe_Recurring();
        
        // Parse fields
        recurring.interval = (String) recurringMap.get('interval');
        recurring.interval_count = (Integer) recurringMap.get('interval_count');
        recurring.usage_type = (String) recurringMap.get('usage_type');
        
        return recurring;
    }
    
    /**
     * @description Check if this is a monthly recurring interval
     * @return Boolean True if monthly
     */
    public Boolean isMonthly() {
        return 'month'.equalsIgnoreCase(interval);
    }
    
    /**
     * @description Check if this is a yearly recurring interval
     * @return Boolean True if yearly
     */
    public Boolean isYearly() {
        return 'year'.equalsIgnoreCase(interval);
    }
    
    /**
     * @description Get a human-readable description of the recurring interval
     * @return String Description (e.g., "Every 1 month", "Every 12 months")
     */
    public String getDescription() {
        if (String.isBlank(interval)) {
            return 'One-time';
        }
        
        String intervalText = interval_count == 1 ? interval : interval + 's';
        return 'Every ' + interval_count + ' ' + intervalText;
    }
} 