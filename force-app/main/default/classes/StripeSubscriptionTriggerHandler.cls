/**
 * @description Trigger handler for Stripe_Subscription__c object to manage Stripe subscription synchronization
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public with sharing class StripeSubscriptionTriggerHandler {
    
    private static final Set<String> STRIPE_SYNC_FIELDS = new Set<String>{
        'Contact__c', 'Product_Plan_Name__c', 'Amount__c', 'Currency__c', 'Status__c'
    };
    
    /**
     * @description Handle before delete events - handle subscription deletion in Stripe
     * @param oldSubscriptions List of subscriptions being deleted
     */
    public static void beforeDelete(List<Stripe_Subscription__c> oldSubscriptions) {
        // TODO: Implement subscription deletion logic
        // - Check if subscription has Stripe ID
        // - Call Stripe API to cancel/delete subscription
        // - Handle errors and prevent deletion if needed
    }
    
    /**
     * @description Handle after insert events - create subscription in Stripe or generate checkout session for pending subscriptions
     * @param newSubscriptions List of newly inserted subscriptions
     */
    public static void afterInsert(List<Stripe_Subscription__c> newSubscriptions) {
        // Check if integration is enabled (redundant check for safety)
        if (!StripeIntegrationSettings.isSubscriptionsOutboundEnabled()) {
            return;
        }
        
        List<Stripe_Subscription__c> subscriptionsToSync = new List<Stripe_Subscription__c>();
        List<Stripe_Subscription__c> pendingSubscriptions = new List<Stripe_Subscription__c>();
        
        // Filter subscriptions that need different processing
        for (Stripe_Subscription__c subscription : newSubscriptions) {
            if (shouldGenerateCheckoutSession(subscription)) {
                pendingSubscriptions.add(subscription);
            } else if (shouldCreateStripeSubscription(subscription)) {
                subscriptionsToSync.add(subscription);
            }
        }
        
        // Generate checkout sessions for pending subscriptions (asynchronously)
        if (!pendingSubscriptions.isEmpty()) {
            Set<Id> pendingSubscriptionIds = new Set<Id>();
            for (Stripe_Subscription__c subscription : pendingSubscriptions) {
                pendingSubscriptionIds.add(subscription.Id);
            }
            
            // Use existing queueable pattern for checkout session generation
            System.enqueueJob(new StripeSubscriptionQueueable(pendingSubscriptionIds, 'create_checkout_session'));
        }
        
        // Queue Stripe subscription creation for asynchronous processing
        if (!subscriptionsToSync.isEmpty()) {
            Set<Id> subscriptionIds = new Set<Id>();
            for (Stripe_Subscription__c subscription : subscriptionsToSync) {
                subscriptionIds.add(subscription.Id);
            }
            
            // Use chunked processing to respect governor limits
            System.enqueueJob(new StripeSubscriptionQueueable(subscriptionIds, 'create_subscription'));
        }
    }
    
    /**
     * @description Handle after update events - sync changes to Stripe
     * @param newSubscriptions List of updated subscriptions
     * @param oldSubscriptions Map of old subscription values
     */
    public static void afterUpdate(List<Stripe_Subscription__c> newSubscriptions, Map<Id, Stripe_Subscription__c> oldSubscriptions) {
        // Check if integration is enabled (redundant check for safety)
        if (!StripeIntegrationSettings.isSubscriptionsOutboundEnabled()) {
            return;
        }
        
        
        List<Stripe_Subscription__c> subscriptionsToSync = new List<Stripe_Subscription__c>();
        
        // Filter subscriptions that have relevant field changes and existing Stripe ID
        for (Stripe_Subscription__c subscription : newSubscriptions) {
            Stripe_Subscription__c oldSubscription = oldSubscriptions.get(subscription.Id);
            if (shouldUpdateStripeSubscription(subscription, oldSubscription)) {
                subscriptionsToSync.add(subscription);
            } else {
            }
        }
        
        if (!subscriptionsToSync.isEmpty()) {
            // Convert to Set<Id> for queueable method
            Set<Id> subscriptionIds = new Set<Id>();
            for (Stripe_Subscription__c subscription : subscriptionsToSync) {
                subscriptionIds.add(subscription.Id);
            }
            System.enqueueJob(new StripeSubscriptionQueueable(subscriptionIds, 'update_subscription'));
        }
    }
    
    /**
     * @description Handle after undelete events - restore subscription in Stripe if needed
     * @param newSubscriptions List of undeleted subscriptions
     */
    public static void afterUndelete(List<Stripe_Subscription__c> newSubscriptions) {
        // Check if integration is enabled (redundant check for safety)
        if (!StripeIntegrationSettings.isSubscriptionsOutboundEnabled()) {
            return;
        }
        
        List<Stripe_Subscription__c> subscriptionsToRestore = new List<Stripe_Subscription__c>();
        
        // Filter subscriptions that should be restored
        for (Stripe_Subscription__c subscription : newSubscriptions) {
            if (shouldCreateStripeSubscription(subscription)) {
                subscriptionsToRestore.add(subscription);
            }
        }
        
        // Queue Stripe subscription restoration for asynchronous processing
        if (!subscriptionsToRestore.isEmpty()) {
            Set<Id> subscriptionIds = new Set<Id>();
            for (Stripe_Subscription__c subscription : subscriptionsToRestore) {
                subscriptionIds.add(subscription.Id);
            }
            
            System.enqueueJob(new StripeSubscriptionQueueable(subscriptionIds, 'create_subscription'));
        }
    }
    
    /**
     * @description Determine if a subscription should be created in Stripe
     * @param subscription The subscription to evaluate
     * @return Boolean indicating if Stripe subscription should be created
     */
    private static Boolean shouldCreateStripeSubscription(Stripe_Subscription__c subscription) {
        // Check if subscription has required fields
        if (subscription.Contact__c == null || subscription.Stripe_Price__c == null) {
            return false;
        }
        
        // Check if subscription doesn't already have Stripe ID
        if (String.isNotBlank(subscription.Stripe_Subscription_ID__c)) {
            return false;
        }
        
        // Check if status is appropriate for Stripe sync (not cancelled, etc.)
        if (String.isNotBlank(subscription.Status__c) && 
            (subscription.Status__c.equalsIgnoreCase('Cancelled') || 
             subscription.Status__c.equalsIgnoreCase('Deleted'))) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @description Determine if a subscription should be updated in Stripe
     * @param newSubscription The updated subscription
     * @param oldSubscription The old subscription values
     * @return Boolean indicating if Stripe subscription should be updated
     */
    private static Boolean shouldUpdateStripeSubscription(Stripe_Subscription__c newSubscription, Stripe_Subscription__c oldSubscription) {
        // Check if subscription has Stripe ID
        if (String.isBlank(newSubscription.Stripe_Subscription_ID__c)) {
            return false;
        }
        
        // Check if relevant fields have changed
        return newSubscription.Contact__c != oldSubscription.Contact__c ||
               newSubscription.Product_Plan_Name__c != oldSubscription.Product_Plan_Name__c ||
               newSubscription.Amount__c != oldSubscription.Amount__c ||
               newSubscription.Currency__c != oldSubscription.Currency__c ||
               newSubscription.Status__c != oldSubscription.Status__c ||
               newSubscription.Stripe_Price__c != oldSubscription.Stripe_Price__c;
    }
    
    /**
     * @description Create Stripe subscriptions for the given subscriptions
     * @param subscriptions List of subscriptions to create in Stripe
     */
    private static void createStripeSubscriptions(List<Stripe_Subscription__c> subscriptions) {
        Stripe_Client client = new Stripe_Client();
        List<Stripe_Subscription__c> subscriptionsToUpdate = new List<Stripe_Subscription__c>();
        
        for (Stripe_Subscription__c subscription : subscriptions) {
            try {
                // Prepare parameters for Stripe API call
                Map<String, Object> params = new Map<String, Object>();
                params.put('subscriptionRecord', subscription);
                
                // Call Stripe API to create subscription
                Map<String, Object> response = (Map<String, Object>) client.handleAction('create_subscription', params);
                
                if (response != null && String.isNotBlank((String) response.get('id'))) {
                    // Update subscription with Stripe ID and status
                    subscription.Stripe_Subscription_ID__c = (String) response.get('id');
                    subscription.Status__c = (String) response.get('status');
                    
                    // Handle incomplete subscriptions
                    if ((Boolean) response.get('isIncomplete')) {
                        // TODO: Generate checkout URL for payment completion
                        // This would typically involve creating a Checkout Session
                        subscription.Status__c = 'Incomplete - Payment Required';
                    }
                    
                    subscriptionsToUpdate.add(subscription);
                } else {
                    // Handle error - no response or missing ID
                    subscription.Status__c = 'Error - Creation Failed';
                    subscriptionsToUpdate.add(subscription);
                }
                
            } catch (Exception e) {
                // Handle exceptions and update subscription status
                Logger.error('Error creating Stripe subscription: ' + e.getMessage());
                Logger.saveLog();
                subscription.Status__c = 'Error - ' + e.getMessage().left(50);
                subscriptionsToUpdate.add(subscription);
            }
        }
        
        // Update all subscriptions with results
        if (!subscriptionsToUpdate.isEmpty()) {
            try {
                update subscriptionsToUpdate;
            } catch (Exception e) {
                Logger.error('Error updating subscriptions after Stripe creation: ' + e.getMessage());
                Logger.saveLog();
            }
        }
    }
    
    /**
     * @description Update Stripe subscriptions for the given subscriptions
     * @param subscriptions List of subscriptions to update in Stripe
     */
    private static void updateStripeSubscriptions(List<Stripe_Subscription__c> subscriptions) {
        // TODO: Implement Stripe subscription updates
        // - Call Stripe API to update subscriptions
        // - Handle status changes and related updates
        // - Update Contact subscription status if needed
    }
    
    /**
     * @description Delete Stripe subscriptions for the given subscriptions
     * @param subscriptions List of subscriptions to delete from Stripe
     */
    private static void deleteStripeSubscriptions(List<Stripe_Subscription__c> subscriptions) {
        // TODO: Implement Stripe subscription deletion
        // - Call Stripe API to cancel/delete subscriptions
        // - Handle errors and prevent deletion if needed
        // - Update related Contact records
    }
    
    /**
     * @description Determine if a subscription needs a checkout session generated (for payment link)
     * @param subscription The subscription to evaluate
     * @return Boolean indicating if checkout session should be generated
     */
    private static Boolean shouldGenerateCheckoutSession(Stripe_Subscription__c subscription) {
        // Check if subscription has required fields
        if (subscription.Contact__c == null || subscription.Stripe_Price__c == null) {
            return false;
        }
        
        // Check if status is "Pending" (case insensitive)
        if (String.isBlank(subscription.Status__c) || 
            !subscription.Status__c.equalsIgnoreCase('pending')) {
            return false;
        }
        
        // Check if checkout session already exists
        if (String.isNotBlank(subscription.Checkout_URL__c) ||
            String.isNotBlank(subscription.Stripe_Checkout_Session_ID__c)) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @description Generate checkout sessions for pending subscriptions
     * @param subscriptions List of pending subscriptions that need payment links
     */
    private static void generateCheckoutSessions(List<Stripe_Subscription__c> subscriptions) {
        // Query subscriptions with related Contact and Price data
        Map<Id, Stripe_Subscription__c> subscriptionMap = new Map<Id, Stripe_Subscription__c>([
            SELECT Id, Contact__c, Stripe_Price__c, Status__c,
                   Contact__r.Stripe_Customer_ID__c, Contact__r.Email,
                   Stripe_Price__r.Stripe_Price_ID__c, Stripe_Price__r.Name
            FROM Stripe_Subscription__c 
            WHERE Id IN :subscriptions
        ]);
        
        Stripe_Client client = new Stripe_Client();
        List<Stripe_Subscription__c> subscriptionsToUpdate = new List<Stripe_Subscription__c>();
        
        for (Stripe_Subscription__c subscription : subscriptions) {
            try {
                // Get the subscription with relationships
                Stripe_Subscription__c subscriptionWithData = subscriptionMap.get(subscription.Id);
                
                // Validate required data
                if (String.isBlank(subscriptionWithData.Contact__r.Stripe_Customer_ID__c) ||
                    String.isBlank(subscriptionWithData.Stripe_Price__r.Stripe_Price_ID__c)) {
                    Logger.error('Missing required data for checkout session: Subscription ' + subscription.Id + 
                               ', Customer ID: ' + subscriptionWithData.Contact__r.Stripe_Customer_ID__c + 
                               ', Price ID: ' + subscriptionWithData.Stripe_Price__r.Stripe_Price_ID__c)
                              .addTag('Stripe_Checkout');
                    continue;
                }
                
                // Prepare parameters for checkout session creation
                Map<String, Object> params = new Map<String, Object>();
                params.put('subscriptionRecord', subscriptionWithData);
                
                // Call Stripe API to create checkout session
                Map<String, Object> response = (Map<String, Object>) client.handleAction('create_checkout_session', params);
                
                if (response != null && String.isNotBlank((String) response.get('url'))) {
                    // Update subscription with checkout session data
                    subscription.Checkout_URL__c = (String) response.get('url');
                    subscription.Stripe_Checkout_Session_ID__c = (String) response.get('id');
                    
                    
                    subscriptionsToUpdate.add(subscription);
                } else {
                    Logger.error('Failed to create checkout session for subscription: ' + subscription.Id)
                              .addTag('Stripe_Checkout');
                }
                
            } catch (Exception e) {
                Logger.error('Exception generating checkout session for subscription ' + subscription.Id + ': ' + e.getMessage())
                          .addTag('Stripe_Checkout');
            }
        }
        
        // Update subscriptions with checkout session data
        if (!subscriptionsToUpdate.isEmpty()) {
            try {
                // Bypass subscription sync to prevent recursive triggers
                StripeIntegrationSettings.bypassSubscriptionSync();
                update subscriptionsToUpdate;
                StripeIntegrationSettings.enableSubscriptionSync();
                
                
            } catch (Exception e) {
                StripeIntegrationSettings.enableSubscriptionSync();
                Logger.error('Error updating subscriptions with checkout session data: ' + e.getMessage())
                          .addTag('Stripe_Checkout');
                Logger.saveLog();
            }
        }
    }
} 