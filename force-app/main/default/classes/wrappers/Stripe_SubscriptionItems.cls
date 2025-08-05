/**
 * @description Represents subscription items in Stripe API responses
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public class Stripe_SubscriptionItems {
    
    // List object properties
    public String object_type { get; set; }
    public List<Stripe_SubscriptionItemData> data { get; set; }
    public Boolean has_more { get; set; }
    public String url { get; set; }
    
    // Constructor
    public Stripe_SubscriptionItems() {
        this.data = new List<Stripe_SubscriptionItemData>();
    }
    
    /**
     * @description Parse subscription items from JSON response
     * @param itemsMap Map containing items data from Stripe
     * @return Stripe_SubscriptionItems Parsed items object
     */
    public static Stripe_SubscriptionItems parse(Map<String, Object> itemsMap) {
        Stripe_SubscriptionItems items = new Stripe_SubscriptionItems();
        
        // Parse basic list properties
        items.object_type = (String) itemsMap.get('object');
        items.has_more = (Boolean) itemsMap.get('has_more');
        items.url = (String) itemsMap.get('url');
        
        // Parse data array
        if (itemsMap.containsKey('data') && itemsMap.get('data') != null) {
            List<Object> dataList = (List<Object>) itemsMap.get('data');
            for (Object itemObj : dataList) {
                Map<String, Object> itemMap = (Map<String, Object>) itemObj;
                items.data.add(Stripe_SubscriptionItemData.parse(itemMap));
            }
        }
        
        return items;
    }
    
    /**
     * @description Get the first subscription item (most common use case)
     * @return Stripe_SubscriptionItemData First item or null
     */
    public Stripe_SubscriptionItemData getFirstItem() {
        return data != null && !data.isEmpty() ? data[0] : null;
    }
    
    /**
     * @description Get total quantity across all items
     * @return Integer Total quantity
     */
    public Integer getTotalQuantity() {
        Integer total = 0;
        if (data != null) {
            for (Stripe_SubscriptionItemData item : data) {
                total += item.quantity != null ? item.quantity : 0;
            }
        }
        return total;
    }
} 