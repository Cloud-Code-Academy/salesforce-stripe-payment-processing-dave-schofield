/**
 * @description Utility class to manage Stripe integration settings
 * Provides a clean way to access custom metadata settings with test overrides
 * and temporary bypass functionality to prevent recursive updates
 */
public class StripeIntegrationSettings {
    
    @TestVisible
    public static Boolean syncContactsOutbound = null;
    
    @TestVisible
    public static Boolean syncSubscriptionsOutbound = null;
    
    // Cache MDT settings for performance - lazy loaded and test visible
    @TestVisible
    private static Stripe_Sync__mdt cachedSettings;
    
    /**
     * @description Get cached MDT settings with lazy loading
     * @return Stripe_Sync__mdt settings record
     */
    @TestVisible
    private static Stripe_Sync__mdt getSettings() {
        if (cachedSettings == null) {
            cachedSettings = Stripe_Sync__mdt.getInstance('Settings');
        }
        return cachedSettings;
    }
    
    /**
     * @description Check if Contacts outbound sync is enabled
     * @return Boolean indicating if contacts should sync to Stripe
     */
    public static Boolean isContactsOutboundEnabled() {
        // First check MDT - if disabled globally, always return false
        Boolean mdtEnabled = getSettings()?.Contacts_Outbound__c == true;
        if (!mdtEnabled) {
            return false;
        }
        
        // MDT is enabled - check for temporary bypass
        // null = use MDT setting, false = bypassed, true = force enabled
        if (syncContactsOutbound != null) {
            return syncContactsOutbound;
        }
        
        // No bypass, MDT is enabled
        return true;
    }
    
    /**
     * @description Check if Subscriptions outbound sync is enabled
     * @return Boolean indicating if subscriptions should sync to Stripe
     */
    public static Boolean isSubscriptionsOutboundEnabled() {
        // First check MDT - if disabled globally, always return false
        Boolean mdtEnabled = getSettings()?.Subscriptions_Outbound__c == true;
        if (!mdtEnabled) {
            return false;
        }
        
        // MDT is enabled - check for temporary bypass
        // null = use MDT setting, false = bypassed, true = force enabled
        if (syncSubscriptionsOutbound != null) {
            return syncSubscriptionsOutbound;
        }
        
        // No bypass, MDT is enabled
        return true;
    }
    
    /**
     * @description Check if Contacts inbound sync is enabled
     * @return Boolean indicating if contacts should be updated from Stripe webhooks
     */
    public static Boolean isContactsInboundEnabled() {
        // ?. = null-safe operator, == true converts null/false to false, true to true
        return getSettings()?.Contacts_Inbound__c == true;
    }
    
    /**
     * @description Check if Subscriptions inbound sync is enabled
     * @return Boolean indicating if subscriptions should be updated from Stripe webhooks
     */
    public static Boolean isSubscriptionsInboundEnabled() {
        // ?. = null-safe operator, == true converts null/false to false, true to true
        return getSettings()?.Subscriptions_Inbound__c == true;
    }
    
    /**
     * @description Temporarily bypass contact sync to prevent recursive updates
     * Use this when processing webhooks or updating Stripe IDs
     */
    public static void bypassContactSync() {
        syncContactsOutbound = false;
    }
    
    /**
     * @description Re-enable contact sync by resetting to check MDT
     */
    public static void enableContactSync() {
        syncContactsOutbound = null; // Reset to check MDT
    }
    
    /**
     * @description Temporarily bypass subscription sync to prevent recursive updates
     * Use this when processing webhooks or updating Stripe IDs
     */
    public static void bypassSubscriptionSync() {
        syncSubscriptionsOutbound = false;
    }
    
    /**
     * @description Re-enable subscription sync by resetting to check MDT
     */
    public static void enableSubscriptionSync() {
        syncSubscriptionsOutbound = null; // Reset to check MDT
    }
    
}