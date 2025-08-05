/**
 * @description Trigger handler for Contact object to manage Stripe customer synchronization
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public with sharing class ContactTriggerHandler {
    
    private static final Set<String> STRIPE_SYNC_FIELDS = new Set<String>{
        'Email', 'FirstName', 'LastName', 'Phone', 'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode', 'MailingCountry'
    };
    
    /**
     * @description Handle after insert events - create customer in Stripe
     * @param newContacts List of newly inserted contacts
     */
    public static void afterInsert(List<Contact> newContacts) {
        // Check if integration is enabled (redundant check for safety)
        if (!StripeIntegrationSettings.isContactsOutboundEnabled()) {
            return;
        }
        
        // Contact trigger handler processing
        
        List<Contact> contactsToSync = new List<Contact>();
        
        // Filter contacts that need Stripe sync (have email and no existing Stripe ID)
        for (Contact contact : newContacts) {
            if (shouldCreateStripeCustomer(contact)) {
                contactsToSync.add(contact);
            }
        }
        
        // Queue Stripe customer creation for asynchronous processing
        if (!contactsToSync.isEmpty()) {
            Set<Id> contactIds = new Set<Id>();
            for (Contact contact : contactsToSync) {
                contactIds.add(contact.Id);
            }
            
            // Use chunked processing to respect governor limits
            System.enqueueJob(new Stripe_ContactQueueable(contactIds, 'create_customer'));
        }
    }
    
    /**
     * @description Handle after update events - sync changes to Stripe
     * @param newContacts List of updated contacts
     * @param oldContacts Map of old contact values
     */
    public static void afterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        // Check if integration is enabled (redundant check for safety)
        if (!StripeIntegrationSettings.isContactsOutboundEnabled()) {
            return;
        }
        
        
        List<Contact> contactsToSync = new List<Contact>();
        
        // Filter contacts that have relevant field changes and existing Stripe ID
        for (Contact contact : newContacts) {
            Contact oldContact = oldContacts.get(contact.Id);
            if (shouldUpdateStripeCustomer(contact, oldContact)) {
                contactsToSync.add(contact);
            } else {
            }
        }
        
        if (!contactsToSync.isEmpty()) {
            // Convert to Set<Id> for queueable method
            Set<Id> contactIds = new Set<Id>();
            for (Contact contact : contactsToSync) {
                contactIds.add(contact.Id);
            }
            System.enqueueJob(new Stripe_ContactQueueable(contactIds, 'update_customer'));
        }
    }
    
    /**
     * @description Handle before delete events - handle customer deletion in Stripe
     * @param oldContacts List of contacts being deleted
     */
    public static void beforeDelete(List<Contact> oldContacts) {
        // Check if integration is enabled (redundant check for safety)
        if (!StripeIntegrationSettings.isContactsOutboundEnabled()) {
            return;
        }
        
        List<Contact> contactsToDelete = new List<Contact>();
        
        // Filter contacts that have Stripe IDs
        for (Contact contact : oldContacts) {
            if (String.isNotBlank(contact.Stripe_Customer_ID__c)) {
                contactsToDelete.add(contact);
            }
        }
        
        if (!contactsToDelete.isEmpty()) {
            deleteStripeCustomers(contactsToDelete);
        }
    }
    
    /**
     * @description Determine if a contact should have a Stripe customer created
     * @param contact The contact to evaluate
     * @return Boolean indicating if Stripe customer should be created
     */
    private static Boolean shouldCreateStripeCustomer(Contact contact) {
        // Check if contact has email and no existing Stripe ID
        return String.isNotBlank(contact.Email) && 
               String.isBlank(contact.Stripe_Customer_ID__c);
    }
    
    /**
     * @description Determine if a contact should be updated in Stripe
     * @param newContact The updated contact
     * @param oldContact The old contact values
     * @return Boolean indicating if Stripe customer should be updated
     */
    private static Boolean shouldUpdateStripeCustomer(Contact newContact, Contact oldContact) {
        // Check if contact has Stripe ID
        if (String.isBlank(newContact.Stripe_Customer_ID__c)) {
            return false;
        }
        
        // Check if relevant fields have changed
        return newContact.Email != oldContact.Email ||
               newContact.FirstName != oldContact.FirstName ||
               newContact.LastName != oldContact.LastName ||
               newContact.Phone != oldContact.Phone ||
               newContact.MailingStreet != oldContact.MailingStreet ||
               newContact.MailingCity != oldContact.MailingCity ||
               newContact.MailingState != oldContact.MailingState ||
               newContact.MailingPostalCode != oldContact.MailingPostalCode ||
               newContact.MailingCountry != oldContact.MailingCountry;
    }
    
    
    /**
     * @description Delete Stripe customers for the given contacts
     * @param contacts List of contacts to delete from Stripe
     */
    private static void deleteStripeCustomers(List<Contact> contacts) {
        Stripe_Client client = new Stripe_Client();
        
        for (Contact contact : contacts) {
            try {
                // Call Stripe API to delete customer
                Map<String, Object> params = new Map<String, Object>();
                params.put('customerId', contact.Stripe_Customer_ID__c);
                Boolean success = (Boolean) client.handleAction('delete_customer', params);
                
                if (success) {
                    // Success handling will be implemented separately
                    
                } else {
                    // Error handling will be implemented separately
                }
                
            } catch (Exception e) {
                // Error handling will be implemented separately
            }
        }
    }
} 