/**
 * @description Queueable class to handle Stripe subscription operations (create/update) asynchronously
 * Supports automatic chunking and chaining for large datasets
 * @author Cloud Fitness Academy Integration
 * @version 2.1
 */
public class StripeSubscriptionQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Id> allSubscriptionIds;
    private Integer startIndex;
    private Integer batchSize;
    private String operation; // 'create_subscription', 'update_subscription', or 'create_checkout_session'
    
    // Default batch size - configurable for future needs
    private static final Integer DEFAULT_BATCH_SIZE = 100;

    // Custom setting to control queueable execution and prevent runaway jobs
    @TestVisible
    private Boolean runQueueable;
    
    /**
     * @description Main constructor for starting a new job (public API)
     * @param subscriptionIds Set of subscription IDs to process
     * @param operation Either 'create_subscription', 'update_subscription', or 'create_checkout_session'
     */
    public StripeSubscriptionQueueable(Set<Id> subscriptionIds, String operation) {
        this(new List<Id>(subscriptionIds), 0, DEFAULT_BATCH_SIZE, operation);
    }
    
    /**
     * @description Internal constructor for chaining batches (used by queueable internally)
     * @param subscriptionIds List of all subscription IDs to process
     * @param startIndex Starting index for this batch
     * @param batchSize Number of records to process in this batch
     * @param operation Either 'create_subscription', 'update_subscription', or 'create_checkout_session'
     */
    private StripeSubscriptionQueueable(List<Id> subscriptionIds, Integer startIndex, Integer batchSize, String operation) {
        this.allSubscriptionIds = subscriptionIds;
        this.startIndex = startIndex;
        this.batchSize = batchSize;
        this.operation = operation;
    }
    
    /**
     * @description Execute method for Queueable interface
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        // Queueable processing started
        if(runQueueable == null) {
            runQueueable = CFA_Async_Switch__c.getOrgDefaults().Run_Queueable__c;
        }
        if (!runQueueable) {
            Logger.error('Queueable is disabled. Skipping execution.');
            Logger.saveLog();
            return;
        }
        
        // Validate input parameters
        if (allSubscriptionIds == null || allSubscriptionIds.isEmpty()) {
            Logger.error('ERROR: No subscription IDs provided');
            Logger.saveLog();
            return;
        }
        
        if (startIndex >= allSubscriptionIds.size()) {
            Logger.error('ERROR: Start index (' + startIndex + ') is beyond list size (' + allSubscriptionIds.size() + ')');
            Logger.saveLog();
            return;
        }
        
        // Calculate the end index for this batch
        Integer endIndex = Math.min(startIndex + batchSize, allSubscriptionIds.size());
        
        // Get the subset of subscription IDs for this batch
        List<Id> currentBatchIds = new List<Id>();
        for (Integer i = startIndex; i < endIndex; i++) {
            currentBatchIds.add(allSubscriptionIds[i]);
        }
        
        // Query fresh Subscription records to avoid read-only issues
        // Include LastModifiedDate for update operations
        List<Stripe_Subscription__c> subscriptions = [
            SELECT Id, Contact__c, Product_Plan_Name__c, Amount__c, Currency__c, Status__c, 
                   Stripe_Price__c, Stripe_Subscription_ID__c, Current_Period_Start__c, 
                   Current_Period_End__c, LastModifiedDate, Checkout_URL__c, Stripe_Checkout_Session_ID__c,
                   Contact__r.Stripe_Customer_ID__c, Stripe_Price__r.Stripe_Price_ID__c
            FROM Stripe_Subscription__c 
            WHERE Id IN :currentBatchIds
        ];
        
        Stripe_Client client = new Stripe_Client();
        
        // Process based on operation type
        switch on operation {
            when 'create_subscription' {
                processCreateSubscriptions(subscriptions, client);
            }
            when 'update_subscription' {
                processUpdateSubscriptions(subscriptions, client);
            }
            when 'create_checkout_session' {
                processCreateCheckoutSessions(subscriptions, client);
            }
            when else {
                Logger.error('ERROR: Unknown operation: ' + operation);
                Logger.saveLog();
                return;
            }
        }
        
        // Chain to next batch if there are more subscriptions to process
        // Note: Cannot chain queueable jobs in test context
        Integer nextStartIndex = startIndex + batchSize;
        
        if (nextStartIndex < allSubscriptionIds.size() && !Test.isRunningTest()) {
            System.enqueueJob(new StripeSubscriptionQueueable(allSubscriptionIds, nextStartIndex, batchSize, operation));
        }
    }
    
    /**
     * @description Process create subscription operations
     * @param subscriptions List of subscriptions to create in Stripe
     * @param client Stripe client instance
     */
    private void processCreateSubscriptions(List<Stripe_Subscription__c> subscriptions, Stripe_Client client) {
        List<Stripe_Subscription__c> subscriptionsToUpdate = new List<Stripe_Subscription__c>();
        
        for (Stripe_Subscription__c subscription : subscriptions) {
            try {
                // Call Stripe API
                Map<String, Object> params = new Map<String, Object>();
                params.put('subscriptionRecord', subscription);
                
                Map<String, Object> response = (Map<String, Object>) client.handleAction('create_subscription', params);
                
                if (response != null && String.isNotBlank((String) response.get('id'))) {
                    // Update Subscription with Stripe ID and status
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
                    // Log error
                    Logger.error('ERROR: CreateSubscription response was null or missing ID for subscription: ' + subscription.Id);
                    Logger.saveLog();
                }
                
            } catch (Exception e) {
                // Log error
                Logger.error('EXCEPTION creating Stripe subscription for subscription ' + subscription.Id + ': ' + e.getMessage());
                Logger.saveLog();
            }
        }
        
        
        // Update subscriptions with Stripe IDs
        if (!subscriptionsToUpdate.isEmpty()) {
            try {
                // Temporarily bypass subscription sync to prevent recursive triggers
                StripeIntegrationSettings.bypassSubscriptionSync();
                update subscriptionsToUpdate;
                StripeIntegrationSettings.enableSubscriptionSync();
            } catch (Exception e) {
                // Re-enable sync even if update fails
                StripeIntegrationSettings.enableSubscriptionSync();
                Logger.error('Exception updating subscriptions: ' + e.getMessage());
                Logger.saveLog();
            }
        }
    }
    
    /**
     * @description Process update subscription operations
     * @param subscriptions List of subscriptions to update in Stripe
     * @param client Stripe client instance
     */
    private void processUpdateSubscriptions(List<Stripe_Subscription__c> subscriptions, Stripe_Client client) {
        for (Stripe_Subscription__c subscription : subscriptions) {
            try {
                // Call Stripe API
                Map<String, Object> params = new Map<String, Object>();
                params.put('subscriptionId', subscription.Stripe_Subscription_ID__c);
                params.put('subscriptionRecord', subscription);
                Boolean success = (Boolean) client.handleAction('update_subscription', params);
                
                if (!success) {
                    Logger.error('Stripe update failed for subscription: ' + subscription.Id).addTag('Stripe_Queueable');
                    Logger.saveLog();
                }
                
            } catch (Exception e) {
                Logger.error('Exception updating Stripe subscription for subscription ' + subscription.Id + ': ' + e.getMessage()).addTag('Stripe_Queueable');
                Logger.saveLog();
            }
        }
    }
    
    /**
     * @description Process create checkout session operations
     * @param subscriptions List of subscriptions to create checkout sessions for
     * @param client Stripe client instance
     */
    private void processCreateCheckoutSessions(List<Stripe_Subscription__c> subscriptions, Stripe_Client client) {
        List<Stripe_Subscription__c> subscriptionsToUpdate = new List<Stripe_Subscription__c>();
        
        for (Stripe_Subscription__c subscription : subscriptions) {
            try {
                // Skip if checkout session already exists
                if (String.isNotBlank(subscription.Checkout_URL__c) || 
                    String.isNotBlank(subscription.Stripe_Checkout_Session_ID__c)) {
                    continue;
                }
                
                // Validate required data exists
                if (String.isBlank(subscription.Contact__r.Stripe_Customer_ID__c) ||
                    String.isBlank(subscription.Stripe_Price__r.Stripe_Price_ID__c)) {
                    Logger.error('Missing required data for checkout session: Subscription ' + subscription.Id + 
                               ', Customer ID: ' + subscription.Contact__r.Stripe_Customer_ID__c + 
                               ', Price ID: ' + subscription.Stripe_Price__r.Stripe_Price_ID__c)
                              .addTag('Stripe_Queueable');
                    continue;
                }
                
                // Create checkout session via Stripe API
                Map<String, Object> params = new Map<String, Object>();
                params.put('subscriptionRecord', subscription);
                
                Map<String, Object> response = (Map<String, Object>) client.handleAction('create_checkout_session', params);
                
                if (response != null && String.isNotBlank((String) response.get('url'))) {
                    // Update subscription with checkout session data
                    subscription.Checkout_URL__c = (String) response.get('url');
                    subscription.Stripe_Checkout_Session_ID__c = (String) response.get('id');
                    
                    
                    subscriptionsToUpdate.add(subscription);
                } else {
                    Logger.error('Failed to create checkout session for subscription: ' + subscription.Id).addTag('Stripe_Queueable');
                }
                
            } catch (Exception e) {
                Logger.error('Exception generating checkout session for subscription ' + subscription.Id + ': ' + e.getMessage()).addTag('Stripe_Queueable');
                Logger.saveLog();
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
                Logger.error('Error updating subscriptions with checkout session data: ' + e.getMessage()).addTag('Stripe_Queueable');
                Logger.saveLog();
            }
        }
    }
}