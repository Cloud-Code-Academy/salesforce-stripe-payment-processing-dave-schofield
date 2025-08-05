public with sharing class Stripe_WebhookProcessor {

    private Stripe_Event event;
    private Integer retryCount;
    private static final Integer MAX_RETRIES = 3;
    
    /**
     * Constructor for processing a webhook event
     * @param event The parsed Stripe event
     */
    public Stripe_WebhookProcessor(Stripe_Event event) {
        this.event = event;
        this.retryCount = 0;
    }
    
    /**
     * Constructor for retry scenarios
     * @param event The parsed Stripe event
     * @param retryCount Current retry attempt number
     */
    public Stripe_WebhookProcessor(Stripe_Event event, Integer retryCount) {
        this.event = event;
        this.retryCount = retryCount;
    }
    
    public void process() {
        // Process the already-parsed event

        try {
            
            
            // Process event based on type
            switch on event.type {
                when 'customer.created' {
                    processCustomerCreated(event);
                }
                when 'customer.updated' {
                    processCustomerUpdated(event);
                }
                when 'customer.deleted' {
                    processCustomerDeleted(event);
                }
                when 'customer.subscription.created' {
                    processSubscriptionCreated(event);
                }
                when 'customer.subscription.updated' {
                    processSubscriptionUpdated(event);
                }
                when 'customer.subscription.deleted' {
                    processSubscriptionDeleted(event);
                }
                // PAYMENT EVENT PROCESSING
                when 'checkout.session.completed' {
                    processCheckoutSessionCompleted(event);
                }
                when 'invoice.payment_succeeded' {
                    processInvoicePaymentSucceeded(event);
                }
                when 'invoice.payment_failed' {
                    processInvoicePaymentFailed(event);
                }

                when else {
                    Logger.warn('Unhandled event type: [' + event.type + '], event ID: ' + event.id).addTag('Stripe_Webhook');
                    Logger.saveLog();
                }
            }
            

            
        } catch (Exception e) {
            // Log error
            Logger.error('Webhook processing failed for ' + event.type + ' (ID: ' + event.id + '): ' + e.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            
            // Retry logic
            if (retryCount < MAX_RETRIES) {
                retryCount++;
                // Enqueue retry with exponential backoff
                System.enqueueJob(new Stripe_WebhookProcessor(event, retryCount));
            } else {
                // Max retries reached, create error record for manual review
                Logger.error('Max retries reached for webhook ' + event.id + ' (' + event.type + ')').addTag('Stripe_Webhook');
                Logger.saveLog();
            }
        }
    }

    private void processCustomerCreated(Stripe_Event event) {
        // TODO: Implement customer creation logic when needed
    }
    
    private void processCustomerUpdated(Stripe_Event event) {
        try {
            
            // Check if inbound sync is enabled
            if (!StripeIntegrationSettings.isContactsInboundEnabled()) {
                return;
            }
            
            // Extract customer data from event
            Map<String, Object> customerData = event.getObjectData();
            String stripeCustomerId = (String) customerData.get('id');
            
            // Find matching Contact
            List<Contact> contacts = [
                SELECT Id, Email, FirstName, LastName, Phone, 
                       MailingStreet, MailingCity, MailingState, 
                       MailingPostalCode, MailingCountry,
                       Stripe_Customer_ID__c, LastModifiedDate
                FROM Contact 
                WHERE Stripe_Customer_ID__c = :stripeCustomerId 
                LIMIT 1
            ];
            
            if (contacts.isEmpty()) {
                Logger.warn('No Contact found for Stripe customer: ' + stripeCustomerId).addTag('Stripe_Webhook');
                Logger.saveLog();
                return;
            }
            
            Contact contact = contacts[0];
            
            // Check if this webhook is from our own update
            if (isOwnUpdate(contact, customerData)) {
                return;
            }
            
            updateContactFromStripeData(contact, customerData);
            
            // Bypass contact sync to prevent recursive triggers
            StripeIntegrationSettings.bypassContactSync();
            try {
                
                Database.SaveResult result = Database.update(contact, false);
                StripeIntegrationSettings.enableContactSync();
                
                if (!result.isSuccess()) {
                    Logger.error('Contact update failed for: ' + contact.Id).addTag('Stripe_Webhook');
                    for (Database.Error error : result.getErrors()) {
                        Logger.error('DML Error: ' + error.getMessage() + ' on fields: ' + error.getFields()).addTag('Stripe_Webhook');
                    }
                    Logger.saveLog();
                }
            } catch (Exception updateEx) {
                StripeIntegrationSettings.enableContactSync();
                Logger.error('Exception during contact update: ' + updateEx.getMessage()).addTag('Stripe_Webhook');
                Logger.saveLog();
                throw updateEx;
            }
            
            
        } catch (Exception e) {
            Logger.error('Error processing customer.updated webhook: ' + e.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            throw e;
        }
    }
    
    private void processCustomerDeleted(Stripe_Event event) {
        // TODO: Implement customer deletion logic when needed
    }
    
    /**
     * @description Check if webhook is from our own Salesforce update
     * @param contact Current contact record
     * @param customerData Stripe customer data from webhook
     * @return Boolean indicating if this is our own update
     */
    private Boolean isOwnUpdate(Contact contact, Map<String, Object> customerData) {
        try {
            // Extract metadata from Stripe customer data
            Map<String, Object> metadata = (Map<String, Object>) customerData.get('metadata');
            if (metadata == null) {
                return false; // No metadata, assume external update
            }
            
            // Get Salesforce metadata values
            String stripeContactId = (String) metadata.get('salesforce_contact_id');
            String stripeLastModified = (String) metadata.get('salesforce_last_modified');
            
            // Check if contact ID matches
            if (stripeContactId != contact.Id) {
                return false; // Different contact or no contact ID in metadata
            }
            
            // Check if last modified timestamp matches
            if (String.isBlank(stripeLastModified)) {
                return false; // No timestamp in metadata
            }
            
            String contactLastModified = String.valueOf(contact.LastModifiedDate.getTime());
            return stripeLastModified == contactLastModified;
            
        } catch (Exception e) {
            Logger.warn('Error checking webhook metadata: ' + e.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            return false; // On error, assume external update to be safe
        }
    }
    
    private void updateContactFromStripeData(Contact contact, Map<String, Object> customerData) {
        // Update contact fields from Stripe customer data
        contact.Email = (String) customerData.get('email');
        contact.Phone = (String) customerData.get('phone');
        
        // Handle name fields - Stripe stores as single 'name' field
        String name = (String) customerData.get('name');
        if (String.isNotBlank(name)) {
            List<String> nameParts = name.split(' ', 2);
            contact.FirstName = nameParts[0];
            if (nameParts.size() > 1) {
                contact.LastName = nameParts[1];
            }
        }
        
        // Handle address
        Map<String, Object> address = (Map<String, Object>) customerData.get('address');
        if (address != null) {
            contact.MailingStreet = (String) address.get('line1');
            contact.MailingCity = (String) address.get('city');
            contact.MailingState = (String) address.get('state');
            contact.MailingPostalCode = (String) address.get('postal_code');
            contact.MailingCountry = (String) address.get('country');
        }
    }
    
    // =====================================================
    // SUBSCRIPTION WEBHOOK PROCESSING METHODS
    // =====================================================
    
    private void processSubscriptionCreated(Stripe_Event event) {
        try {
            // Check if inbound sync is enabled
            if (!StripeIntegrationSettings.isSubscriptionsInboundEnabled()) {
                return;
            }
            
            // Extract subscription data from event
            Map<String, Object> subscriptionData = event.getObjectData();
            String stripeSubscriptionId = (String) subscriptionData.get('id');
            String stripeCustomerId = (String) subscriptionData.get('customer');
            
            // Validate that all required related records exist
            if (!validateRequiredRelatedRecords(subscriptionData)) {
                Logger.error('Cannot create subscription - required records missing for subscription: ' + stripeSubscriptionId).addTag('Stripe_Webhook');
                Logger.saveLog();
                return;
            }
            
            // Find matching Contact by Stripe Customer ID (we know it exists from validation)
            List<Contact> contacts = [
                SELECT Id FROM Contact 
                WHERE Stripe_Customer_ID__c = :stripeCustomerId 
                LIMIT 1
            ];
            
            Contact contact = contacts[0];
            
            // Check if subscription already exists
            List<Stripe_Subscription__c> existingSubscriptions = [
                SELECT Id FROM Stripe_Subscription__c 
                WHERE Stripe_Subscription_ID__c = :stripeSubscriptionId 
                LIMIT 1
            ];
            
            if (!existingSubscriptions.isEmpty()) {
                return;
            }
            
            // Create new subscription record
            Stripe_Subscription__c newSubscription = createSubscriptionFromStripeData(contact.Id, subscriptionData);
            
            // Bypass subscription sync to prevent recursive triggers
            StripeIntegrationSettings.bypassSubscriptionSync();
            try {
                
                Database.SaveResult result = Database.insert(newSubscription, false);
                StripeIntegrationSettings.enableSubscriptionSync();
                
                if (!result.isSuccess()) {
                    Logger.error('Subscription creation failed for Stripe ID: ' + stripeSubscriptionId).addTag('Stripe_Webhook');
                    for (Database.Error error : result.getErrors()) {
                        Logger.error('DML Error: ' + error.getMessage() + ' on fields: ' + error.getFields()).addTag('Stripe_Webhook');
                    }
                    Logger.saveLog();
                }
            } catch (Exception createEx) {
                StripeIntegrationSettings.enableSubscriptionSync();
                Logger.error('Exception during subscription creation: ' + createEx.getMessage()).addTag('Stripe_Webhook');
                Logger.saveLog();
                throw createEx;
            }
            
        } catch (Exception e) {
            Logger.error('Error processing customer.subscription.created webhook: ' + e.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            throw e;
        }
    }
    
    private void processSubscriptionUpdated(Stripe_Event event) {
        try {
            // Check if inbound sync is enabled
            if (!StripeIntegrationSettings.isSubscriptionsInboundEnabled()) {
                return;
            }
            
            // Extract subscription data from event
            Map<String, Object> subscriptionData = event.getObjectData();
            String stripeSubscriptionId = (String) subscriptionData.get('id');
            
            // Find matching Subscription
            List<Stripe_Subscription__c> subscriptions = [
                SELECT Id, Contact__c, Product_Plan_Name__c, Amount__c, Currency__c, Status__c, 
                       Stripe_Price__c, Stripe_Subscription_ID__c, Current_Period_Start__c, 
                       Current_Period_End__c, LastModifiedDate
                FROM Stripe_Subscription__c 
                WHERE Stripe_Subscription_ID__c = :stripeSubscriptionId 
                LIMIT 1
            ];
            
            if (subscriptions.isEmpty()) {
                Logger.warn('No Subscription found for Stripe subscription: ' + stripeSubscriptionId).addTag('Stripe_Webhook');
                Logger.saveLog();
                return;
            }
            
            Stripe_Subscription__c subscription = subscriptions[0];
            
            // Check if this webhook is from our own update
            if (isOwnSubscriptionUpdate(subscription, subscriptionData)) {
                return;
            }
            
            updateSubscriptionFromStripeData(subscription, subscriptionData);
            
            // Bypass subscription sync to prevent recursive triggers
            StripeIntegrationSettings.bypassSubscriptionSync();
            try {
                
                Database.SaveResult result = Database.update(subscription, false);
                StripeIntegrationSettings.enableSubscriptionSync();
                
                if (!result.isSuccess()) {
                    Logger.error('Subscription update failed for: ' + subscription.Id).addTag('Stripe_Webhook');
                    for (Database.Error error : result.getErrors()) {
                        Logger.error('DML Error: ' + error.getMessage() + ' on fields: ' + error.getFields()).addTag('Stripe_Webhook');
                    }
                    Logger.saveLog();
                }
            } catch (Exception updateEx) {
                StripeIntegrationSettings.enableSubscriptionSync();
                Logger.error('Exception during subscription update: ' + updateEx.getMessage()).addTag('Stripe_Webhook');
                Logger.saveLog();
                throw updateEx;
            }
            
            
        } catch (Exception e) {
            Logger.error('Error processing customer.subscription.updated webhook: ' + e.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            throw e;
        }
    }
    
    private void processSubscriptionDeleted(Stripe_Event event) {
        try {
            // Check if inbound sync is enabled
            if (!StripeIntegrationSettings.isSubscriptionsInboundEnabled()) {
                return;
            }
            
            // Extract subscription data from event
            Map<String, Object> subscriptionData = event.getObjectData();
            String stripeSubscriptionId = (String) subscriptionData.get('id');
            
            // Find matching Subscription
            List<Stripe_Subscription__c> subscriptions = [
                SELECT Id, Status__c, Stripe_Subscription_ID__c
                FROM Stripe_Subscription__c 
                WHERE Stripe_Subscription_ID__c = :stripeSubscriptionId 
                LIMIT 1
            ];
            
            if (subscriptions.isEmpty()) {
                Logger.warn('No Subscription found for deleted Stripe subscription: ' + stripeSubscriptionId).addTag('Stripe_Webhook');
                Logger.saveLog();
                return;
            }
            
            Stripe_Subscription__c subscription = subscriptions[0];
            
            // Update status to cancelled rather than deleting the record
            subscription.Status__c = 'Cancelled';
            
            // Bypass subscription sync to prevent recursive triggers
            StripeIntegrationSettings.bypassSubscriptionSync();
            try {
                
                Database.SaveResult result = Database.update(subscription, false);
                StripeIntegrationSettings.enableSubscriptionSync();
                
                if (!result.isSuccess()) {
                    Logger.error('Subscription cancellation failed for: ' + subscription.Id).addTag('Stripe_Webhook');
                    for (Database.Error error : result.getErrors()) {
                        Logger.error('DML Error: ' + error.getMessage() + ' on fields: ' + error.getFields()).addTag('Stripe_Webhook');
                    }
                    Logger.saveLog();
                }
            } catch (Exception updateEx) {
                StripeIntegrationSettings.enableSubscriptionSync();
                Logger.error('Exception during subscription cancellation: ' + updateEx.getMessage()).addTag('Stripe_Webhook');
                Logger.saveLog();
                throw updateEx;
            }
            
        } catch (Exception e) {
            Logger.error('Error processing customer.subscription.deleted webhook: ' + e.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            throw e;
        }
    }
    
    /**
     * @description Check if subscription webhook is from our own Salesforce update
     * @param subscription Current subscription record
     * @param subscriptionData Stripe subscription data from webhook
     * @return Boolean indicating if this is our own update
     */
    private Boolean isOwnSubscriptionUpdate(Stripe_Subscription__c subscription, Map<String, Object> subscriptionData) {
        try {
            // Extract metadata from Stripe subscription data
            Map<String, Object> metadata = (Map<String, Object>) subscriptionData.get('metadata');
            if (metadata == null) {
                return false; // No metadata, assume external update
            }
            
            // Get Salesforce metadata values
            String stripeSubscriptionId = (String) metadata.get('salesforce_subscription_id');
            String stripeLastModified = (String) metadata.get('salesforce_last_modified');
            
            // Check if subscription ID matches
            if (stripeSubscriptionId != subscription.Id) {
                return false; // Different subscription or no subscription ID in metadata
            }
            
            // Check if last modified timestamp matches
            if (String.isBlank(stripeLastModified)) {
                return false; // No timestamp in metadata
            }
            
            String subscriptionLastModified = String.valueOf(subscription.LastModifiedDate.getTime());
            return stripeLastModified == subscriptionLastModified;
            
        } catch (Exception e) {
            Logger.warn('Error checking subscription webhook metadata: ' + e.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            return false; // On error, assume external update to be safe
        }
    }
    
    /**
     * @description Create new subscription record from Stripe subscription data
     * @param contactId Related Contact ID
     * @param subscriptionData Stripe subscription data
     * @return Stripe_Subscription__c record to insert
     */
    private Stripe_Subscription__c createSubscriptionFromStripeData(Id contactId, Map<String, Object> subscriptionData) {
        Stripe_Subscription__c subscription = new Stripe_Subscription__c();
        
        subscription.Contact__c = contactId;
        subscription.Stripe_Subscription_ID__c = (String) subscriptionData.get('id');
        subscription.Status__c = (String) subscriptionData.get('status');
        subscription.Currency__c = (String) subscriptionData.get('currency');
        
        // Handle subscription items and pricing
        List<Object> items = (List<Object>) subscriptionData.get('items');
        if (items != null && !items.isEmpty()) {
            Map<String, Object> firstItem = (Map<String, Object>) items[0];
            Map<String, Object> price = (Map<String, Object>) firstItem.get('price');
            if (price != null) {
                String stripePriceId = (String) price.get('id');
                subscription.Amount__c = (Decimal) price.get('unit_amount') / 100; // Convert from cents
                
                // Use validation method for price lookup
                Id priceRecordId = validateAndGetStripePriceId(stripePriceId);
                if (priceRecordId != null) {
                    subscription.Stripe_Price__c = priceRecordId;
                }
                
                // Handle product information
                Map<String, Object> product = (Map<String, Object>) price.get('product');
                if (product != null) {
                    String stripeProductId = (String) product.get('id');
                    subscription.Product_Plan_Name__c = (String) product.get('name');
                    
                    // Use validation method for product lookup
                    Id productRecordId = validateAndGetStripeProductId(stripeProductId);
                    if (productRecordId != null) {
                        subscription.Stripe_Product__c = productRecordId;
                    }
                }
            }
        }
        
        // Handle period dates
        Long currentPeriodStart = (Long) subscriptionData.get('current_period_start');
        if (currentPeriodStart != null) {
            subscription.Current_Period_Start__c = DateTime.newInstance(currentPeriodStart * 1000);
        }
        
        Long currentPeriodEnd = (Long) subscriptionData.get('current_period_end');
        if (currentPeriodEnd != null) {
            subscription.Current_Period_End__c = DateTime.newInstance(currentPeriodEnd * 1000);
        }
        
        return subscription;
    }
    
    /**
     * @description Update subscription record from Stripe subscription data
     * @param subscription Subscription record to update
     * @param subscriptionData Stripe subscription data
     */
    private void updateSubscriptionFromStripeData(Stripe_Subscription__c subscription, Map<String, Object> subscriptionData) {
        subscription.Status__c = (String) subscriptionData.get('status');
        subscription.Currency__c = (String) subscriptionData.get('currency');
        
        // Handle subscription items and pricing
        List<Object> items = (List<Object>) subscriptionData.get('items');
        if (items != null && !items.isEmpty()) {
            Map<String, Object> firstItem = (Map<String, Object>) items[0];
            Map<String, Object> price = (Map<String, Object>) firstItem.get('price');
            if (price != null) {
                String stripePriceId = (String) price.get('id');
                subscription.Amount__c = (Decimal) price.get('unit_amount') / 100; // Convert from cents
                
                // Use validation method for price lookup
                Id priceRecordId = validateAndGetStripePriceId(stripePriceId);
                if (priceRecordId != null) {
                    subscription.Stripe_Price__c = priceRecordId;
                }
                
                // Handle product information
                Map<String, Object> product = (Map<String, Object>) price.get('product');
                if (product != null) {
                    String stripeProductId = (String) product.get('id');
                    subscription.Product_Plan_Name__c = (String) product.get('name');
                    
                    // Use validation method for product lookup
                    Id productRecordId = validateAndGetStripeProductId(stripeProductId);
                    if (productRecordId != null) {
                        subscription.Stripe_Product__c = productRecordId;
                    }
                }
            }
        }
        
        // Handle period dates
        Long currentPeriodStart = (Long) subscriptionData.get('current_period_start');
        if (currentPeriodStart != null) {
            subscription.Current_Period_Start__c = DateTime.newInstance(currentPeriodStart * 1000);
        }
        
        Long currentPeriodEnd = (Long) subscriptionData.get('current_period_end');
        if (currentPeriodEnd != null) {
            subscription.Current_Period_End__c = DateTime.newInstance(currentPeriodEnd * 1000);
        }
    }
    
    /**
     * @description Validates and retrieves Salesforce record ID for Stripe Price
     * @param stripePriceId Stripe price ID from webhook
     * @return Id Salesforce record ID if found, null otherwise
     */
    private Id validateAndGetStripePriceId(String stripePriceId) {
        if (String.isBlank(stripePriceId)) {
            Logger.warn('Stripe Price ID is blank').addTag('Stripe_Webhook');
            Logger.saveLog();
            return null;
        }
        
        List<Stripe_Price__c> stripePrices = [
            SELECT Id, Name FROM Stripe_Price__c 
            WHERE Stripe_Price_ID__c = :stripePriceId 
            LIMIT 1
        ];
        
        if (!stripePrices.isEmpty()) {
            return stripePrices[0].Id;
        } else {
            Logger.warn('No Stripe_Price__c record found for Stripe Price ID: ' + stripePriceId + '. Subscription will be created without price reference.').addTag('Stripe_Webhook');
            Logger.saveLog();
            return null;
        }
    }
    
    /**
     * @description Validates and retrieves Salesforce record ID for Stripe Product
     * @param stripeProductId Stripe product ID from webhook
     * @return Id Salesforce record ID if found, null otherwise
     */
    private Id validateAndGetStripeProductId(String stripeProductId) {
        if (String.isBlank(stripeProductId)) {
            Logger.warn('Stripe Product ID is blank').addTag('Stripe_Webhook');
            Logger.saveLog();
            return null;
        }
        
        List<Stripe_Product__c> stripeProducts = [
            SELECT Id, Name FROM Stripe_Product__c 
            WHERE Stripe_Product_ID__c = :stripeProductId 
            LIMIT 1
        ];
        
        if (!stripeProducts.isEmpty()) {
            return stripeProducts[0].Id;
        } else {
            Logger.warn('No Stripe_Product__c record found for Stripe Product ID: ' + stripeProductId + '. Subscription will be created without product reference.').addTag('Stripe_Webhook');
            Logger.saveLog();
            return null;
        }
    }
    
    /**
     * @description Validates if all required related records exist for subscription creation
     * @param subscriptionData Stripe subscription data from webhook
     * @return Boolean true if all required records exist (Contact is required)
     */
    private Boolean validateRequiredRelatedRecords(Map<String, Object> subscriptionData) {
        String stripeCustomerId = (String) subscriptionData.get('customer');
        
        if (String.isBlank(stripeCustomerId)) {
            Logger.error('No customer ID found in subscription data').addTag('Stripe_Webhook');
            Logger.saveLog();
            return false;
        }
        
        List<Contact> contacts = [
            SELECT Id FROM Contact 
            WHERE Stripe_Customer_ID__c = :stripeCustomerId 
            LIMIT 1
        ];
        
        if (contacts.isEmpty()) {
            Logger.error('No Contact found for Stripe customer: ' + stripeCustomerId + '. Cannot create subscription.').addTag('Stripe_Webhook');
            Logger.saveLog();
            return false;
        }
        
        return true;
    }
    
    // =====================================================
    // PAYMENT WEBHOOK PROCESSING METHODS
    // =====================================================
    
    /**
     * @description Process checkout session completed event - payment link was successful
     * @param event Stripe event containing checkout session data
     */
    private void processCheckoutSessionCompleted(Stripe_Event event) {
        try {
            // Extract checkout session data from event
            Map<String, Object> sessionData = event.getObjectData();
            String checkoutSessionId = (String) sessionData.get('id');
            String paymentStatus = (String) sessionData.get('payment_status');
            String sessionStatus = (String) sessionData.get('status');
            String customerId = (String) sessionData.get('customer');
            String subscriptionId = (String) sessionData.get('subscription');
            
            // Extract metadata for Salesforce linking
            Map<String, Object> metadata = (Map<String, Object>) sessionData.get('metadata');
            if (metadata != null) {
                String salesforceSubscriptionId = (String) metadata.get('salesforce_subscription_id');
                
                if (String.isNotBlank(salesforceSubscriptionId)) {
                    // Find and update the Salesforce subscription record
                    List<Stripe_Subscription__c> subscriptions = [
                        SELECT Id, Status__c, Stripe_Subscription_ID__c, Contact__c
                        FROM Stripe_Subscription__c 
                        WHERE Id = :salesforceSubscriptionId 
                        LIMIT 1
                    ];
                    
                    if (!subscriptions.isEmpty()) {
                        Stripe_Subscription__c subscription = subscriptions[0];
                        subscription.Status__c = 'Active';
                        subscription.Stripe_Subscription_ID__c = subscriptionId;
                        
                        // Bypass subscription sync to prevent recursive triggers
                        StripeIntegrationSettings.bypassSubscriptionSync();
                        try {
                            update subscription;
                            
                            // Create Payment_Transaction__c record for successful checkout
                            createPaymentTransaction(sessionData, subscription.Contact__c, subscription.Id, 'succeeded');
                        } finally {
                            StripeIntegrationSettings.enableSubscriptionSync();
                        }
                    } else {
                        Logger.warn('No subscription found for ID: ' + salesforceSubscriptionId).addTag('Stripe_Payment');
                    }
                }
            }
            
            
        } catch (Exception e) {
            Logger.error('Error processing checkout.session.completed webhook: ' + e.getMessage()).addTag('Stripe_Payment');
            Logger.error('Stack trace: ' + e.getStackTraceString()).addTag('Stripe_Payment');
            Logger.saveLog();
            throw e;
        }
    }
    
    /**
     * @description Process invoice payment succeeded event  
     * @param event Stripe event containing invoice data
     */
    private void processInvoicePaymentSucceeded(Stripe_Event event) {
        try {
            // Extract invoice data from event
            Map<String, Object> invoiceData = event.getObjectData();
            String invoiceId = (String) invoiceData.get('id');
            String customerId = (String) invoiceData.get('customer');
            String subscriptionId = (String) invoiceData.get('subscription');
            Integer amountPaidCents = (Integer) invoiceData.get('amount_paid');
            String currency_x = (String) invoiceData.get('currency_x');
            
            // Create Payment_Transaction__c record for successful recurring payment
            if (String.isNotBlank(customerId)) {
                // Find the contact for this customer
                List<Contact> contacts = [SELECT Id FROM Contact WHERE Stripe_Customer_ID__c = :customerId LIMIT 1];
                if (!contacts.isEmpty()) {
                    createPaymentTransactionFromInvoice(invoiceData, contacts[0].Id, 'succeeded', amountPaidCents);
                }
            }
            
            
        } catch (Exception e) {
            Logger.error('Error processing invoice.payment_succeeded webhook: ' + e.getMessage()).addTag('Stripe_Payment');
            Logger.error('Stack trace: ' + e.getStackTraceString()).addTag('Stripe_Payment');
            Logger.saveLog();
            throw e;
        }
    }
    
    /**
     * @description Process invoice payment failed event
     * @param event Stripe event containing invoice data
     */
    private void processInvoicePaymentFailed(Stripe_Event event) {
        try {
            // Extract invoice data from event
            Map<String, Object> invoiceData = event.getObjectData();
            String invoiceId = (String) invoiceData.get('id');
            String customerId = (String) invoiceData.get('customer');
            String subscriptionId = (String) invoiceData.get('subscription');
            
            // TODO: Handle payment failure logic (Phase 3.2)
            // - Create failed Payment_Transaction__c record
            // - Update subscription status
            // - Send notification to customer/coach
            
            
        } catch (Exception e) {
            Logger.error('Error processing invoice.payment_failed webhook: ' + e.getMessage()).addTag('Stripe_Payment');
            Logger.error('Stack trace: ' + e.getStackTraceString()).addTag('Stripe_Payment');
            Logger.saveLog();
            throw e;
        }
    }
    
    /**
     * @description Create Payment_Transaction__c record from checkout session data
     * @param sessionData Checkout session data from webhook
     * @param contactId Related Contact ID
     * @param subscriptionId Related Subscription ID
     * @param status Transaction status (Succeeded/Failed)
     */
    private void createPaymentTransaction(Map<String, Object> sessionData, Id contactId, Id subscriptionId, String status) {
        try {
            Stripe_Payment_Transaction__c paymentTransaction = new Stripe_Payment_Transaction__c();
            
            // Basic transaction info
            paymentTransaction.Contact__c = contactId;
            paymentTransaction.Stripe_Subscription__c = subscriptionId;
            paymentTransaction.Status__c = status;
            paymentTransaction.Transaction_Type__c = 'Payment';
            paymentTransaction.Transaction_Date__c = Datetime.now();
            
            // Extract payment details from session - handle proper type casting
            Integer amountTotalCents = (Integer) sessionData.get('amount_total');
            if (amountTotalCents != null) {
                paymentTransaction.Amount__c = amountTotalCents / 100.0; // Convert cents to dollars
            }
            
            paymentTransaction.Currency__c = (String) sessionData.get('currency');
            paymentTransaction.Stripe_Payment_Intent_ID__c = (String) sessionData.get('payment_intent');
            
            // Store session ID for reference
            paymentTransaction.Description__c = 'Payment via checkout session: ' + (String) sessionData.get('id');
            
            insert paymentTransaction;
            
        } catch (Exception e) {
            Logger.error('Failed to create Payment_Transaction__c from checkout session: ' + e.getMessage()).addTag('Stripe_Payment');
            Logger.error('Stack trace: ' + e.getStackTraceString()).addTag('Stripe_Payment');
        }
    }
    
    /**
     * @description Create Payment_Transaction__c record from invoice data
     * @param invoiceData Invoice data from webhook
     * @param contactId Related Contact ID
     * @param status Transaction status (Succeeded/Failed)
     * @param amountPaidCents Amount paid in cents (already cast to Integer)
     */
    private void createPaymentTransactionFromInvoice(Map<String, Object> invoiceData, Id contactId, String status, Integer amountPaidCents) {
        try {
            Stripe_Payment_Transaction__c paymentTransaction = new Stripe_Payment_Transaction__c();
            
            // Basic transaction info
            paymentTransaction.Contact__c = contactId;
            paymentTransaction.Status__c = status;
            paymentTransaction.Transaction_Type__c = 'Payment';
            paymentTransaction.Transaction_Date__c = Datetime.now();
            
            // Amount already cast to Integer, convert to dollars
            if (amountPaidCents != null) {
                paymentTransaction.Amount__c = amountPaidCents / 100.0;
            }
            
            paymentTransaction.Currency__c = (String) invoiceData.get('currency_x');
            paymentTransaction.Stripe_Invoice__c = (String) invoiceData.get('id');
            
            // Link to subscription if available
            String subscriptionId = (String) invoiceData.get('subscription');
            if (String.isNotBlank(subscriptionId)) {
                List<Stripe_Subscription__c> subscriptions = [
                    SELECT Id FROM Stripe_Subscription__c 
                    WHERE Stripe_Subscription_ID__c = :subscriptionId 
                    LIMIT 1
                ];
                if (!subscriptions.isEmpty()) {
                    paymentTransaction.Stripe_Subscription__c = subscriptions[0].Id;
                }
            }
            
            paymentTransaction.Description__c = 'Recurring payment for invoice: ' + (String) invoiceData.get('id');
            
            insert paymentTransaction;
            
        } catch (Exception e) {
            Logger.error('Failed to create Payment_Transaction__c from invoice: ' + e.getMessage()).addTag('Stripe_Payment');
            Logger.error('Stack trace: ' + e.getStackTraceString()).addTag('Stripe_Payment');
        }
    }
    
}