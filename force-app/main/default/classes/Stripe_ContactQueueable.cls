/**
 * @description Queueable class to handle Stripe customer operations (create/update) asynchronously
 * Supports automatic chunking and chaining for large datasets
 * @author Cloud Fitness Academy Integration
 * @version 2.1
 */
public class Stripe_ContactQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Id> allContactIds;
    private Integer startIndex;
    private Integer batchSize;
    private String operation; // 'create_customer' or 'update_customer'
    
    // Default batch size - configurable for future needs
    private static final Integer DEFAULT_BATCH_SIZE = 100;

    // Custom setting to control queueable execution and prevent runaway jobs
    @TestVisible
    private Boolean runQueueable;
    
    /**
     * @description Main constructor for starting a new job (public API)
     * @param contactIds Set of contact IDs to process
     * @param operation Either 'create_customer' or 'update_customer'
     */
    public Stripe_ContactQueueable(Set<Id> contactIds, String operation) {
        this(new List<Id>(contactIds), 0, DEFAULT_BATCH_SIZE, operation);
    }
    
    /**
     * @description Internal constructor for chaining batches (used by queueable internally)
     * @param contactIds List of all contact IDs to process
     * @param startIndex Starting index for this batch
     * @param batchSize Number of records to process in this batch
     * @param operation Either 'create_customer' or 'update_customer'
     */
    private Stripe_ContactQueueable(List<Id> contactIds, Integer startIndex, Integer batchSize, String operation) {
        this.allContactIds = contactIds;
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
        if (allContactIds == null || allContactIds.isEmpty()) {
            Logger.error('ERROR: No contact IDs provided');
            Logger.saveLog();
            return;
        }
        
        if (startIndex >= allContactIds.size()) {
            Logger.error('ERROR: Start index (' + startIndex + ') is beyond list size (' + allContactIds.size() + ')');
            Logger.saveLog();
            return;
        }
        
        // Calculate the end index for this batch
        Integer endIndex = Math.min(startIndex + batchSize, allContactIds.size());
        
        // Get the subset of contact IDs for this batch
        List<Id> currentBatchIds = new List<Id>();
        for (Integer i = startIndex; i < endIndex; i++) {
            currentBatchIds.add(allContactIds[i]);
        }
        
        // Query fresh Contact records to avoid read-only issues
        // Include LastModifiedDate for update operations
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Phone, MailingStreet, MailingCity, 
                   MailingState, MailingPostalCode, MailingCountry, Stripe_Customer_ID__c, LastModifiedDate
            FROM Contact 
            WHERE Id IN :currentBatchIds
        ];
        
        Stripe_Client client = new Stripe_Client();
        
        // Process based on operation type
        switch on operation {
            when 'create_customer' {
                processCreateCustomers(contacts, client);
            }
            when 'update_customer' {
                processUpdateCustomers(contacts, client);
            }
            when else {
                Logger.error('ERROR: Unknown operation: ' + operation);
                Logger.saveLog();
                return;
            }
        }
        
        // Chain to next batch if there are more contacts to process
        // Note: Cannot chain queueable jobs in test context
        Integer nextStartIndex = startIndex + batchSize;
        
        if (nextStartIndex < allContactIds.size() && !Test.isRunningTest()) {
            System.enqueueJob(new Stripe_ContactQueueable(allContactIds, nextStartIndex, batchSize, operation));
        }
    }
    
    /**
     * @description Process create customer operations
     * @param contacts List of contacts to create in Stripe
     * @param client Stripe client instance
     */
    private void processCreateCustomers(List<Contact> contacts, Stripe_Client client) {
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact contact : contacts) {
            try {
                // Call Stripe API
                Map<String, Object> params = new Map<String, Object>();
                params.put('contact', contact);
                
                String stripeId = (String) client.handleAction('create_customer', params);
                
                if (String.isNotBlank(stripeId)) {
                    // Update Contact with Stripe ID
                    contact.Stripe_Customer_ID__c = stripeId;
                    contactsToUpdate.add(contact);
                    
                } else {
                    // Log error
                    Logger.error('ERROR: CreateCustomer response was null or missing ID for contact: ' + contact.Id);
                    Logger.saveLog();
                }
                
            } catch (Exception e) {
                // Log error
                Logger.error('EXCEPTION creating Stripe customer for contact ' + contact.Id + ': ' + e.getMessage());
                Logger.saveLog();
            }
        }
        
        
        // Update contacts with Stripe IDs
        if (!contactsToUpdate.isEmpty()) {
            try {
                // Temporarily bypass contact sync to prevent recursive triggers
                StripeIntegrationSettings.bypassContactSync();
                update contactsToUpdate;
                StripeIntegrationSettings.enableContactSync();
            } catch (Exception e) {
                // Re-enable sync even if update fails
                StripeIntegrationSettings.enableContactSync();
                Logger.error('Exception updating contacts: ' + e.getMessage());
                Logger.saveLog();
            }
        }
    }
    
    /**
     * @description Process update customer operations
     * @param contacts List of contacts to update in Stripe
     * @param client Stripe client instance
     */
    private void processUpdateCustomers(List<Contact> contacts, Stripe_Client client) {
        for (Contact contact : contacts) {
            try {
                // Call Stripe API
                Map<String, Object> params = new Map<String, Object>();
                params.put('customerId', contact.Stripe_Customer_ID__c);
                params.put('contact', contact);
                Boolean success = (Boolean) client.handleAction('update_customer', params);
                
                if (!success) {
                    Logger.error('Stripe update failed for contact: ' + contact.Id).addTag('Stripe_Queueable');
                    Logger.saveLog();
                }
                
            } catch (Exception e) {
                Logger.error('Exception updating Stripe customer for contact ' + contact.Id + ': ' + e.getMessage()).addTag('Stripe_Queueable');
                Logger.saveLog();
            }
        }
    }
}