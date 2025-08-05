# Inbound Integration (Stripe → Salesforce)

This document outlines the webhook-based inbound integration from Stripe to Salesforce, enabling real-time synchronization of payment events, subscription changes, and customer updates.

## Overview

The inbound integration uses Stripe webhooks to receive real-time events and automatically update Salesforce records. This ensures data consistency and provides immediate visibility into payment and subscription status changes.

## Business Goals

Based on the technical requirements, the inbound integration addresses these key business needs:

### Customer Service Representatives
- **Real-time Updates**: See customer data changes from Stripe immediately in Salesforce
- **Payment History**: Access complete transaction history for customer support
- **Subscription Status**: View current subscription status and billing information

### Finance Team
- **Payment Monitoring**: Track successful and failed payments in real-time
- **Revenue Visibility**: Monitor subscription renewals and cancellations
- **Financial Reporting**: Generate accurate reports based on live payment data

### Sales Representatives
- **Customer Status**: View complete customer payment and subscription information
- **Billing History**: Access customer payment patterns for sales conversations
- **Subscription Management**: Track subscription lifecycle changes

## Webhook Architecture

### Selected Implementation: Replit Middleware with JWT Authentication

**Architecture Flow:**
```
Stripe → Replit Middleware → Salesforce REST Endpoint
```

The integration uses a **Replit-hosted middleware service** that:
1. **Receives** Stripe webhook events on public endpoint
2. **Verifies** webhook signature using Stripe webhook secret
3. **Authenticates** to Salesforce using JWT Bearer flow via Connected App
4. **Forwards** verified events to Salesforce webhook REST endpoint
5. **Prevents** recursive updates using static variable bypass pattern

### Middleware Service (Node.js on Replit)

```javascript
// middleware/index.js
const express = require("express");
const jwt = require("jsonwebtoken");
const axios = require("axios");
const fs = require("fs");
const { verifyWebhookEvent } = require("./stripeVerifier");

const app = express();
const privateKey = fs.readFileSync("./private.key", "utf8");

app.post("/stripe-webhook", express.raw({ type: "application/json" }), async (req, res) => {
  try {
    // Step 1: Verify Stripe webhook signature
    const signature = req.headers["stripe-signature"];
    const { valid, event, error } = verifyWebhookEvent(
      req.body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    );

    if (!valid) {
      return res.status(400).send(`Webhook Error: ${error.message}`);
    }

    // Step 2: Generate JWT for Salesforce authentication
    const payload = {
      iss: process.env.SF_CLIENT_ID,
      sub: process.env.SF_USERNAME,
      aud: process.env.SF_LOGIN_URL,
      exp: Math.floor(Date.now() / 1000) + 60 * 5,
    };
    const token = jwt.sign(payload, privateKey, { algorithm: "RS256" });

    // Step 3: Get Salesforce access token
    const params = new URLSearchParams();
    params.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
    params.append("assertion", token);

    const tokenResponse = await axios.post(
      `${process.env.SF_LOGIN_URL}/services/oauth2/token`,
      params.toString(),
      { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
    );

    const accessToken = tokenResponse.data.access_token;
    const instanceUrl = tokenResponse.data.instance_url;

    // Step 4: Forward event to Salesforce webhook endpoint
    const salesforceResponse = await axios.post(
      `${instanceUrl}/services/apexrest/webhook/stripe`,
      event,
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );

    res.status(200).send("OK");
  } catch (err) {
    console.error("Error processing Stripe webhook:", err.message);
    res.status(500).send("Failed to forward to Salesforce");
  }
});
```

### Salesforce Connected App Configuration

**Connected App Settings:**
- **App Name**: Stripe Integration Middleware
- **API Name**: Stripe_Integration_Middleware
- **Contact Email**: [your-email]
- **Enable OAuth Settings**: ✓
- **Callback URL**: Not required for JWT flow
- **Selected OAuth Scopes**:
  - Access and manage your data (api)
  - Perform requests on your behalf at any time (refresh_token, offline_access)
- **Use digital signatures**: ✓ (upload public key certificate)

**JWT Bearer Flow Setup:**
1. Generate RSA key pair (private.key for middleware, public cert for Connected App)
2. Upload public certificate to Connected App
3. Enable "Admin approved users are pre-authorized"
4. Create dedicated integration user with appropriate permissions

### Recursive Update Prevention

**Problem:** Bi-directional sync between Salesforce and Stripe can create infinite loops:
1. Contact updated in Salesforce → Triggers outbound sync to Stripe
2. Stripe customer updated → Fires webhook to Salesforce
3. Contact updated in Salesforce → Could trigger another outbound sync → **LOOP**

**Solution: Static Variable Bypass Pattern**

The integration prevents recursive updates using a static variable bypass pattern in the `StripeIntegrationSettings` utility class:

```apex
public class StripeIntegrationSettings {
    // Static variables for temporary webhook bypass
    private static Boolean webhookProcessingInProgress = false;
    private static Set<String> bypassedSyncs = new Set<String>();
    
    public static Boolean isContactsOutboundEnabled() {
        // First check if temporarily bypassed due to webhook processing
        if (isWebhookProcessingInProgress() || isSyncBypassed('CONTACTS')) {
            return false;
        }
        
        // Then check Custom Metadata setting
        return Stripe_Sync__mdt.getInstance('Settings')?.Contacts_Outbound__c == true;
    }
    
    public static void startWebhookProcessing() {
        webhookProcessingInProgress = true;
    }
    
    public static void endWebhookProcessing() {
        webhookProcessingInProgress = false;
        bypassedSyncs.clear();
    }
}
```

**Implementation in Webhook Processor:**

```apex
public class Stripe_WebhookProcessor {
    public void process(String payload) {
        // Enable webhook processing mode to prevent recursive triggers
        StripeIntegrationSettings.startWebhookProcessing();
        
        try {
            // Process webhook event and update Contact records
            // ContactTrigger fires but sees webhook processing = true and skips outbound sync
            
        } finally {
            // Always re-enable triggers after processing
            StripeIntegrationSettings.endWebhookProcessing();
        }
    }
}
```

**How it Works:**
1. **Webhook received** → `startWebhookProcessing()` sets static flag to `true`
2. **Contact updated** → ContactTrigger fires → `isContactsOutboundEnabled()` returns `false`
3. **No outbound sync triggered** → Recursive loop prevented
4. **Processing complete** → `endWebhookProcessing()` resets flag to `false`

**Key Benefits:**
- **Transaction-scoped**: Static variables persist throughout the entire transaction
- **Thread-safe**: Works reliably within Salesforce's execution context
- **Backward compatible**: Existing trigger code requires no changes
- **Granular control**: Can bypass specific sync types or all syncs

## Required Stripe Events

### Customer Events
| Event | Purpose | Business Impact | Salesforce Action |
|-------|---------|-----------------|-------------------|
| `customer.created` | New customer created in Stripe | Customer onboarding | Create/update Stripe_Customer__c record |
| `customer.updated` | Customer information changed | Data synchronization | Update Stripe_Customer__c and Contact records |
| `customer.deleted` | Customer removed from Stripe | Account cleanup | Mark records as inactive |

### Subscription Events
| Event | Purpose | Business Impact | Salesforce Action |
|-------|---------|-----------------|-------------------|
| `subscription.created` | New subscription started | Revenue tracking | Create Stripe_Subscription__c record |
| `subscription.updated` | Subscription plan/status changed | Billing management | Update subscription details |
| `subscription.deleted` | Subscription cancelled | Churn tracking | Update subscription status |
| `subscription.trial_will_end` | Trial ending soon | Customer retention | Trigger renewal notifications |

### Payment Events
| Event | Purpose | Business Impact | Salesforce Action |
|-------|---------|-----------------|-------------------|
| `invoice.payment_succeeded` | Payment completed successfully | Revenue recognition | Create Payment_Transaction__c record |
| `invoice.payment_failed` | Payment failed | Collections management | Update transaction status, trigger dunning |
| `payment_intent.succeeded` | One-time payment successful | Revenue tracking | Create Payment_Transaction__c record |
| `payment_intent.payment_failed` | One-time payment failed | Error handling | Update transaction status |

### Invoice Events
| Event | Purpose | Business Impact | Salesforce Action |
|-------|---------|-----------------|-------------------|
| `invoice.created` | New invoice generated | Billing visibility | Create invoice record |
| `invoice.finalized` | Invoice ready for payment | Payment processing | Update invoice status |
| `invoice.payment_succeeded` | Invoice paid | Revenue recognition | Update invoice and create transaction |
| `invoice.payment_failed` | Invoice payment failed | Collections | Update invoice status |

## Webhook Event Data Structures

### Base Event Structure

All Stripe webhook events follow this base structure:

```json
{
  "id": "evt_XXXXXXXXXXXXX",
  "object": "event",
  "api_version": "2024-04-10",
  "created": 1640995200,
  "data": {
    "object": {
      // Event-specific data object
    }
  },
  "livemode": false,
  "pending_webhooks": 1,
  "request": {
    "id": "req_XXXXXXXXXXXXX",
    "idempotency_key": null
  },
  "type": "customer.created"
}
```

### Apex Classes for Event Parsing

#### 1. Base Event Class

```apex
public class StripeEvent {
    public String id;
    public String object_type;
    public String api_version;
    public Long created;
    public StripeEventData data;
    public Boolean livemode;
    public Integer pending_webhooks;
    public StripeEventRequest request;
    public String type;
    
    public static StripeEvent parse(String json) {
        return (StripeEvent) JSON.deserialize(json, StripeEvent.class);
    }
    
    public class StripeEventData {
        public Object object_data; // Will be cast to specific type based on event
    }
    
    public class StripeEventRequest {
        public String id;
        public String idempotency_key;
    }
}
```

#### 2. Customer Event Data Structure

**Event**: `customer.created`, `customer.updated`, `customer.deleted`

```json
{
  "id": "cus_XXXXXXXXXXXXX",
  "object": "customer",
  "created": 1640995200,
  "email": "customer@example.com",
  "name": "John Doe",
  "phone": "+1234567890",
  "metadata": {
    "salesforce_contact_id": "003XXXXXXXXXXXXXXX"
  },
  "description": "Customer from Salesforce",
  "livemode": false,
  "preferred_locales": ["en"],
  "shipping": {
    "address": {
      "city": "San Francisco",
      "country": "US",
      "line1": "123 Main St",
      "line2": null,
      "postal_code": "94102",
      "state": "CA"
    },
    "name": "John Doe",
    "phone": "+1234567890"
  },
  "tax_exempt": "none",
  "test_clock": null
}
```

```apex
public class StripeCustomer {
    public String id;
    public String object_type;
    public Long created;
    public String email;
    public String name;
    public String phone;
    public Map<String, String> metadata;
    public String description;
    public Boolean livemode;
    public List<String> preferred_locales;
    public StripeShipping shipping;
    public String tax_exempt;
    public String test_clock;
    
    public class StripeShipping {
        public StripeAddress address;
        public String name;
        public String phone;
    }
    
    public class StripeAddress {
        public String city;
        public String country;
        public String line1;
        public String line2;
        public String postal_code;
        public String state;
    }
}
```

#### 3. Subscription Event Data Structure

**Event**: `subscription.created`, `subscription.updated`, `subscription.deleted`

```json
{
  "id": "sub_XXXXXXXXXXXXX",
  "object": "subscription",
  "created": 1640995200,
  "current_period_start": 1640995200,
  "current_period_end": 1643673600,
  "customer": "cus_XXXXXXXXXXXXX",
  "items": {
    "object": "list",
    "data": [
      {
        "id": "si_XXXXXXXXXXXXX",
        "object": "subscription_item",
        "created": 1640995200,
        "price": {
          "id": "price_XXXXXXXXXXXXX",
          "object": "price",
          "active": true,
          "created": 1640995200,
          "currency": "usd",
          "product": "prod_XXXXXXXXXXXXX",
          "recurring": {
            "interval": "month",
            "interval_count": 1
          },
          "unit_amount": 2999,
          "unit_amount_decimal": "2999"
        },
        "quantity": 1
      }
    ],
    "has_more": false,
    "total_count": 1,
    "url": "/v1/subscription_items?subscription=sub_XXXXXXXXXXXXX"
  },
  "status": "active",
  "metadata": {
    "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
  },
  "collection_method": "charge_automatically",
  "currency": "usd",
  "default_payment_method": "pm_XXXXXXXXXXXXX",
  "default_source": null,
  "default_tax_rates": [],
  "discount": null,
  "ended_at": null,
  "livemode": false,
  "next_pending_invoice_item_invoice": null,
  "pause_collection": null,
  "pending_invoice_item_interval": null,
  "pending_setup_intent": null,
  "pending_update": null,
  "quantity": 1,
  "schedule": null,
  "start_date": 1640995200,
  "transfer_data": null,
  "trial_end": null,
  "trial_start": null
}
```

```apex
public class StripeSubscription {
    public String id;
    public String object_type;
    public Long created;
    public Long current_period_start;
    public Long current_period_end;
    public String customer;
    public StripeSubscriptionItems items;
    public String status;
    public Map<String, String> metadata;
    public String collection_method;
    public String currency;
    public String default_payment_method;
    public String default_source;
    public List<Object> default_tax_rates;
    public Object discount;
    public Long ended_at;
    public Boolean livemode;
    public Object next_pending_invoice_item_invoice;
    public Object pause_collection;
    public Object pending_invoice_item_interval;
    public String pending_setup_intent;
    public Object pending_update;
    public Integer quantity;
    public Object schedule;
    public Long start_date;
    public Object transfer_data;
    public Long trial_end;
    public Long trial_start;
    
    public class StripeSubscriptionItems {
        public String object_type;
        public List<StripeSubscriptionItem> data;
        public Boolean has_more;
        public Integer total_count;
        public String url;
    }
    
    public class StripeSubscriptionItem {
        public String id;
        public String object_type;
        public Long created;
        public StripePrice price;
        public Integer quantity;
    }
    
    public class StripePrice {
        public String id;
        public String object_type;
        public Boolean active;
        public Long created;
        public String currency;
        public String product;
        public StripeRecurring recurring;
        public Integer unit_amount;
        public String unit_amount_decimal;
    }
    
    public class StripeRecurring {
        public String interval;
        public Integer interval_count;
    }
}
```

#### 4. Invoice Event Data Structure

**Event**: `invoice.payment_succeeded`, `invoice.payment_failed`, `invoice.created`, `invoice.finalized`

```json
{
  "id": "in_XXXXXXXXXXXXX",
  "object": "invoice",
  "created": 1640995200,
  "customer": "cus_XXXXXXXXXXXXX",
  "subscription": "sub_XXXXXXXXXXXXX",
  "payment_intent": "pi_XXXXXXXXXXXXX",
  "status": "paid",
  "collection_method": "charge_automatically",
  "currency": "usd",
  "amount_due": 2999,
  "amount_paid": 2999,
  "amount_remaining": 0,
  "metadata": {
    "salesforce_invoice_id": "a0iXXXXXXXXXXXXXXX"
  },
  "lines": {
    "object": "list",
    "data": [
      {
        "id": "il_XXXXXXXXXXXXX",
        "object": "line_item",
        "amount": 2999,
        "currency": "usd",
        "description": "Premium Plan - Monthly",
        "discount_amounts": [],
        "discounts": [],
        "livemode": false,
        "metadata": {},
        "period": {
          "end": 1643673600,
          "start": 1640995200
        },
        "price": {
          "id": "price_XXXXXXXXXXXXX",
          "object": "price",
          "active": true,
          "created": 1640995200,
          "currency": "usd",
          "product": "prod_XXXXXXXXXXXXX",
          "recurring": {
            "interval": "month",
            "interval_count": 1
          },
          "unit_amount": 2999,
          "unit_amount_decimal": "2999"
        },
        "proration": false,
        "quantity": 1,
        "subscription": "sub_XXXXXXXXXXXXX",
        "subscription_item": "si_XXXXXXXXXXXXX",
        "tax_amounts": [],
        "tax_rates": [],
        "type": "subscription"
      }
    ],
    "has_more": false,
    "total_count": 1,
    "url": "/v1/invoices/in_XXXXXXXXXXXXX/lines"
  },
  "livemode": false,
  "next_payment_attempt": null,
  "number": "INV-2024-001",
  "period_end": 1643673600,
  "period_start": 1640995200,
  "receipt_number": null,
  "starting_balance": 0,
  "subtotal": 2999,
  "tax": 0,
  "total": 2999,
  "total_tax_amounts": []
}
```

```apex
public class StripeInvoice {
    public String id;
    public String object_type;
    public Long created;
    public String customer;
    public String subscription;
    public String payment_intent;
    public String status;
    public String collection_method;
    public String currency;
    public Integer amount_due;
    public Integer amount_paid;
    public Integer amount_remaining;
    public Map<String, String> metadata;
    public StripeInvoiceLines lines;
    public Boolean livemode;
    public Long next_payment_attempt;
    public String number;
    public Long period_end;
    public Long period_start;
    public String receipt_number;
    public Integer starting_balance;
    public Integer subtotal;
    public Integer tax;
    public Integer total;
    public List<Object> total_tax_amounts;
    
    public class StripeInvoiceLines {
        public String object_type;
        public List<StripeInvoiceLine> data;
        public Boolean has_more;
        public Integer total_count;
        public String url;
    }
    
    public class StripeInvoiceLine {
        public String id;
        public String object_type;
        public Integer amount;
        public String currency;
        public String description;
        public List<Object> discount_amounts;
        public List<Object> discounts;
        public Boolean livemode;
        public Map<String, String> metadata;
        public StripePeriod period;
        public StripePrice price;
        public Boolean proration;
        public Integer quantity;
        public String subscription;
        public String subscription_item;
        public List<Object> tax_amounts;
        public List<Object> tax_rates;
        public String type;
    }
    
    public class StripePeriod {
        public Long end;
        public Long start;
    }
}
```

#### 5. Payment Intent Event Data Structure

**Event**: `payment_intent.succeeded`, `payment_intent.payment_failed`

```json
{
  "id": "pi_XXXXXXXXXXXXX",
  "object": "payment_intent",
  "amount": 2999,
  "currency": "usd",
  "customer": "cus_XXXXXXXXXXXXX",
  "status": "succeeded",
  "metadata": {
    "salesforce_transaction_id": "a0tXXXXXXXXXXXXXXX"
  },
  "description": "One-time payment for services",
  "payment_method_types": ["card"],
  "charges": {
    "object": "list",
    "data": [
      {
        "id": "ch_XXXXXXXXXXXXX",
        "object": "charge",
        "amount": 2999,
        "currency": "usd",
        "customer": "cus_XXXXXXXXXXXXX",
        "status": "succeeded",
        "payment_method": "pm_XXXXXXXXXXXXX",
        "created": 1640995200,
        "description": "One-time payment for services"
      }
    ],
    "has_more": false,
    "total_count": 1,
    "url": "/v1/charges?payment_intent=pi_XXXXXXXXXXXXX"
  },
  "created": 1640995200,
  "livemode": false,
  "payment_method": "pm_XXXXXXXXXXXXX",
  "receipt_email": "customer@example.com",
  "setup_future_usage": null,
  "shipping": null,
  "transfer_data": null,
  "transfer_group": null
}
```

```apex
public class StripePaymentIntent {
    public String id;
    public String object_type;
    public Integer amount;
    public String currency;
    public String customer;
    public String status;
    public Map<String, String> metadata;
    public String description;
    public List<String> payment_method_types;
    public StripeCharges charges;
    public Long created;
    public Boolean livemode;
    public String payment_method;
    public String receipt_email;
    public String setup_future_usage;
    public Object shipping;
    public Object transfer_data;
    public String transfer_group;
    
    public class StripeCharges {
        public String object_type;
        public List<StripeCharge> data;
        public Boolean has_more;
        public Integer total_count;
        public String url;
    }
    
    public class StripeCharge {
        public String id;
        public String object_type;
        public Integer amount;
        public String currency;
        public String customer;
        public String status;
        public String payment_method;
        public Long created;
        public String description;
    }
}
```

### Event Processing with Type Casting

```apex
public class StripeEventProcessor {
    
    public static void processEvent(StripeEvent event) {
        // Cast the generic object to the specific type based on event type
        switch on event.type {
            when 'customer.created', 'customer.updated', 'customer.deleted' {
                StripeCustomer customer = (StripeCustomer) event.data.object_data;
                processCustomerEvent(event.type, customer);
            }
            when 'subscription.created', 'subscription.updated', 'subscription.deleted' {
                StripeSubscription subscription = (StripeSubscription) event.data.object_data;
                processSubscriptionEvent(event.type, subscription);
            }
            when 'invoice.payment_succeeded', 'invoice.payment_failed', 'invoice.created', 'invoice.finalized' {
                StripeInvoice invoice = (StripeInvoice) event.data.object_data;
                processInvoiceEvent(event.type, invoice);
            }
            when 'payment_intent.succeeded', 'payment_intent.payment_failed' {
                StripePaymentIntent paymentIntent = (StripePaymentIntent) event.data.object_data;
                processPaymentIntentEvent(event.type, paymentIntent);
            }
            when else {
                Logger.warn('Unhandled event type: ' + event.type);
            }
        }
    }
    
    private static void processCustomerEvent(String eventType, StripeCustomer customer) {
        switch on eventType {
            when 'customer.created' {
                CustomerEventProcessor.processCustomerCreated(customer);
            }
            when 'customer.updated' {
                CustomerEventProcessor.processCustomerUpdated(customer);
            }
            when 'customer.deleted' {
                CustomerEventProcessor.processCustomerDeleted(customer);
            }
        }
    }
    
    // Similar methods for other event types...
}
```

### Alternative: Generic JSON Parsing

If you prefer a more flexible approach without strict typing:

```apex
public class StripeWebhookHandler {
    
    @HttpPost
    global static void handleWebhook() {
        try {
            String payload = RestContext.request.requestBody.toString();
            String signature = RestContext.request.headers.get('Stripe-Signature');
            
            // Verify signature
            if (!StripeWebhookVerifier.verifySignature(payload, signature)) {
                throw new StripeWebhookException('Invalid webhook signature');
            }
            
            // Parse as generic Map
            Map<String, Object> eventMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
            String eventType = (String) eventMap.get('type');
            Map<String, Object> eventData = (Map<String, Object>) eventMap.get('data');
            Map<String, Object> objectData = (Map<String, Object>) eventData.get('object');
            
            // Process based on event type
            switch on eventType {
                when 'customer.created' {
                    processCustomerCreated(objectData);
                }
                when 'subscription.created' {
                    processSubscriptionCreated(objectData);
                }
                when 'invoice.payment_succeeded' {
                    processInvoicePaymentSucceeded(objectData);
                }
                // ... other event types
            }
            
            RestContext.response.statusCode = 200;
            
        } catch (Exception e) {
            Logger.error('Webhook processing failed', e);
            RestContext.response.statusCode = 400;
        }
    }
    
    private static void processCustomerCreated(Map<String, Object> customerData) {
        String customerId = (String) customerData.get('id');
        String email = (String) customerData.get('email');
        String name = (String) customerData.get('name');
        String phone = (String) customerData.get('phone');
        
        // Create Salesforce records
        // ... implementation
    }
}
```

## Webhook Setup Process

### 1. Create Webhook Endpoint in Stripe

**Endpoint**: `POST /webhook_endpoints`
**Purpose**: Register Replit middleware webhook URL with Stripe

```json
{
  "url": "https://your-replit-app.replit.dev/stripe-webhook",
  "enabled_events": [
    "customer.created",
    "customer.updated",
    "customer.deleted",
    "subscription.created",
    "subscription.updated",
    "subscription.deleted",
    "subscription.trial_will_end",
    "invoice.payment_succeeded",
    "invoice.payment_failed",
    "payment_intent.succeeded",
    "payment_intent.payment_failed",
    "invoice.created",
    "invoice.finalized"
  ],
  "api_version": "2024-04-10"
}
```

### 2. Configure Environment Variables

**Replit Environment Variables:**
```bash
STRIPE_WEBHOOK_SECRET=whsec_XXXXXXXXXXXXX
SF_CLIENT_ID=3MVG9XXXXXXXXXXXXXXXXXX
SF_USERNAME=integration@yourorg.com
SF_LOGIN_URL=https://login.salesforce.com
```

### 3. Salesforce Webhook REST Endpoint

```apex
@RestResource(urlMapping='/webhook/*')
global without sharing class Webhook_RestResource {
    
    @HttpPost
    global static void doPost() {
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            
            String uri = req.requestURI;
            List<String> uriParts = uri.split('/');
            String service = uriParts.size() > 2 ? uriParts[2] : '';
            
            switch on service {
                when 'stripe' {
                    processStripeWebhook(req, res);
                }
                when else {
                    res.statusCode = 400;
                    res.responseBody = Blob.valueOf('Unknown service: ' + service);
                }
            }
        } catch (Exception e) {
            Logger.error('Webhook processing failed', e);
            RestContext.response.statusCode = 400;
        }
    }
    
    private static void processStripeWebhook(RestRequest req, RestResponse res) {
        String payload = req.requestBody.toString();
        
        // Parse and process the event with recursive update prevention
        Stripe_Event event = Stripe_Event.parse(payload);
        Stripe_WebhookProcessor processor = new Stripe_WebhookProcessor(event); 
        processor.process(payload);
        
        res.statusCode = 200;
        res.responseBody = Blob.valueOf('Webhook processed successfully');
    }
}
```

## Event Processing Logic

### Customer Event Processing

```apex
public class CustomerEventProcessor {
    
    public static void processCustomerCreated(StripeEvent event) {
        StripeCustomer customer = event.data.object;
        
        // Find existing Contact by Stripe Customer ID
        List<Contact> contacts = [
            SELECT Id, Stripe_Customer_ID__c 
            FROM Contact 
            WHERE Stripe_Customer_ID__c = :customer.id
        ];
        
        if (contacts.isEmpty()) {
            // Create new Contact if not found
            Contact newContact = new Contact(
                FirstName = customer.name?.split(' ')[0],
                LastName = customer.name?.split(' ').size() > 1 ? 
                    String.join(customer.name.split(' ').subList(1, customer.name.split(' ').size()), ' ') : '',
                Email = customer.email,
                Phone = customer.phone,
                Stripe_Customer_ID__c = customer.id
            );
            insert newContact;
        }
        
        // Create/update Stripe_Customer__c record
        upsertStripeCustomer(customer);
    }
    
    public static void processCustomerUpdated(StripeEvent event) {
        StripeCustomer customer = event.data.object;
        
        // Update Contact information
        List<Contact> contacts = [
            SELECT Id FROM Contact 
            WHERE Stripe_Customer_ID__c = :customer.id
        ];
        
        if (!contacts.isEmpty()) {
            Contact contact = contacts[0];
            contact.FirstName = customer.name?.split(' ')[0];
            contact.LastName = customer.name?.split(' ').size() > 1 ? 
                String.join(customer.name.split(' ').subList(1, customer.name.split(' ').size()), ' ') : '';
            contact.Email = customer.email;
            contact.Phone = customer.phone;
            update contact;
        }
        
        // Update Stripe_Customer__c record
        upsertStripeCustomer(customer);
    }
}
```

### Subscription Event Processing

```apex
public class SubscriptionEventProcessor {
    
    public static void processSubscriptionCreated(StripeEvent event) {
        StripeSubscription subscription = event.data.object;
        
        // Create Stripe_Subscription__c record
        Stripe_Subscription__c subRecord = new Stripe_Subscription__c(
            Stripe_Subscription_ID__c = subscription.id,
            Stripe_Customer__c = findStripeCustomerId(subscription.customer),
            Status__c = subscription.status,
            Current_Period_Start__c = Datetime.newInstance(subscription.current_period_start * 1000),
            Current_Period_End__c = Datetime.newInstance(subscription.current_period_end * 1000),
            Amount__c = subscription.items.data[0].price.unit_amount / 100.0,
            Currency__c = subscription.currency.toUpperCase(),
            Product_Plan_Name__c = subscription.items.data[0].price.product.name,
            Stripe_Price_ID__c = subscription.items.data[0].price.id
        );
        
        insert subRecord;
    }
    
    public static void processSubscriptionUpdated(StripeEvent event) {
        StripeSubscription subscription = event.data.object;
        
        // Update existing subscription record
        List<Stripe_Subscription__c> subscriptions = [
            SELECT Id FROM Stripe_Subscription__c 
            WHERE Stripe_Subscription_ID__c = :subscription.id
        ];
        
        if (!subscriptions.isEmpty()) {
            Stripe_Subscription__c subRecord = subscriptions[0];
            subRecord.Status__c = subscription.status;
            subRecord.Current_Period_Start__c = Datetime.newInstance(subscription.current_period_start * 1000);
            subRecord.Current_Period_End__c = Datetime.newInstance(subscription.current_period_end * 1000);
            subRecord.Amount__c = subscription.items.data[0].price.unit_amount / 100.0;
            update subRecord;
        }
    }
}
```

### Payment Event Processing

```apex
public class PaymentEventProcessor {
    
    public static void processPaymentSucceeded(StripeEvent event) {
        StripeInvoice invoice = event.data.object;
        
        // Create Payment_Transaction__c record
        Payment_Transaction__c transaction = new Payment_Transaction__c(
            Stripe_Payment_Intent_ID__c = invoice.payment_intent,
            Stripe_Customer__c = findStripeCustomerId(invoice.customer),
            Stripe_Subscription__c = findStripeSubscriptionId(invoice.subscription),
            Amount__c = invoice.amount_paid / 100.0,
            Currency__c = invoice.currency.toUpperCase(),
            Status__c = 'Succeeded',
            Transaction_Date__c = Datetime.newInstance(invoice.created * 1000),
            Payment_Method_Type__c = 'card' // Extract from payment method
        );
        
        insert transaction;
        
        // Update subscription status if needed
        updateSubscriptionStatus(invoice.subscription, 'active');
    }
    
    public static void processPaymentFailed(StripeEvent event) {
        StripeInvoice invoice = event.data.object;
        
        // Create failed transaction record
        Payment_Transaction__c transaction = new Payment_Transaction__c(
            Stripe_Payment_Intent_ID__c = invoice.payment_intent,
            Stripe_Customer__c = findStripeCustomerId(invoice.customer),
            Stripe_Subscription__c = findStripeSubscriptionId(invoice.subscription),
            Amount__c = invoice.amount_due / 100.0,
            Currency__c = invoice.currency.toUpperCase(),
            Status__c = 'Failed',
            Transaction_Date__c = Datetime.newInstance(invoice.created * 1000)
        );
        
        insert transaction;
        
        // Trigger dunning process
        triggerDunningProcess(invoice.customer, invoice.subscription);
    }
}
```

## Security Implementation

### Webhook Signature Verification

```apex
public class StripeWebhookVerifier {
    
    public static Boolean verifySignature(String payload, String signature) {
        try {
            // Get webhook secret from custom metadata
            String webhookSecret = Stripe_Configuration__mdt.getInstance().Webhook_Secret__c;
            
            // Create expected signature
            String expectedSignature = 't=' + System.currentTimeMillis() + ',v1=' + 
                generateHmacSha256(payload, webhookSecret);
            
            return signature.equals(expectedSignature);
            
        } catch (Exception e) {
            Logger.error('Webhook signature verification failed', e);
            return false;
        }
    }
    
    private static String generateHmacSha256(String data, String key) {
        // Implementation using Crypto class
        Blob hmac = Crypto.generateMac('HmacSHA256', Blob.valueOf(data), Blob.valueOf(key));
        return EncodingUtil.convertToHex(hmac);
    }
}
```

## Error Handling & Retry Logic

### Webhook Processing Errors

```apex
public class StripeWebhookProcessor implements Queueable {
    
    private StripeEvent event;
    private Integer retryCount;
    
    public StripeWebhookProcessor(StripeEvent event) {
        this.event = event;
        this.retryCount = 0;
    }
    
    public void execute(QueueableContext context) {
        try {
            // Process event based on type
            switch on event.type {
                when 'customer.created' {
                    CustomerEventProcessor.processCustomerCreated(event);
                }
                when 'subscription.created' {
                    SubscriptionEventProcessor.processSubscriptionCreated(event);
                }
                when 'invoice.payment_succeeded' {
                    PaymentEventProcessor.processPaymentSucceeded(event);
                }
                // ... other event types
            }
            
            // Log successful processing
            Logger.info('Webhook processed successfully', new Map<String, Object>{
                'event_id' => event.id,
                'event_type' => event.type
            });
            
        } catch (Exception e) {
            // Log error
            Logger.error('Webhook processing failed', e, new Map<String, Object>{
                'event_id' => event.id,
                'event_type' => event.type,
                'retry_count' => retryCount
            });
            
            // Retry logic (max 3 attempts)
            if (retryCount < 3) {
                retryCount++;
                System.enqueueJob(this);
            } else {
                // Create error record for manual review
                createErrorRecord(event, e);
            }
        }
    }
}
```

## Data Synchronization Strategy

### Real-time Updates

1. **Immediate Processing**: Webhook events are processed as soon as they're received
2. **Asynchronous Handling**: Use Queueable classes to prevent timeout issues
3. **Idempotency**: Ensure duplicate events don't create duplicate records
4. **Error Recovery**: Failed events are logged and can be reprocessed

### Data Consistency

1. **Stripe ID Tracking**: All Salesforce records include corresponding Stripe IDs
2. **Metadata Mapping**: Use Stripe metadata to store Salesforce record IDs
3. **Status Synchronization**: Keep subscription and payment status in sync
4. **Audit Trail**: Log all webhook events for troubleshooting

## Monitoring & Logging

### Webhook Health Monitoring

```apex
public class WebhookHealthMonitor {
    
    public static void logWebhookEvent(StripeEvent event, String status) {
        // Create webhook log record
        Webhook_Log__c log = new Webhook_Log__c(
            Event_ID__c = event.id,
            Event_Type__c = event.type,
            Processing_Status__c = status,
            Received_At__c = Datetime.now(),
            Payload_Size__c = JSON.serialize(event).length()
        );
        
        insert log;
    }
    
    public static void checkWebhookHealth() {
        // Query recent webhook logs
        List<Webhook_Log__c> recentLogs = [
            SELECT Id, Event_Type__c, Processing_Status__c, Received_At__c
            FROM Webhook_Log__c 
            WHERE Received_At__c > :Datetime.now().addHours(-1)
        ];
        
        // Analyze failure rates
        Integer totalEvents = recentLogs.size();
        Integer failedEvents = 0;
        
        for (Webhook_Log__c log : recentLogs) {
            if (log.Processing_Status__c == 'Failed') {
                failedEvents++;
            }
        }
        
        // Alert if failure rate is high
        if (totalEvents > 0 && (failedEvents / totalEvents) > 0.1) {
            sendAlert('High webhook failure rate detected');
        }
    }
}
```

## Implementation Timeline

### Week 3: Webhook Processing & Advanced Features

**Phase 1: Basic Webhook Setup**
1. Create webhook endpoint in Stripe
2. Implement basic webhook handler
3. Add signature verification
4. Test with Stripe CLI

**Phase 2: Event Processing**
1. Implement customer event processing
2. Add subscription event handling
3. Create payment event processors
4. Add error handling and retry logic

**Phase 3: Advanced Features**
1. Implement comprehensive logging
2. Add webhook health monitoring
3. Create error recovery mechanisms
4. Performance optimization

## Testing Strategy

### Webhook Testing

1. **Stripe CLI Testing**: Use Stripe CLI to send test events
2. **Mock Event Testing**: Create test events for all scenarios
3. **Error Scenario Testing**: Test with invalid signatures, malformed data
4. **Load Testing**: Verify performance under high event volume

### Integration Testing

1. **End-to-End Testing**: Test complete customer lifecycle
2. **Data Consistency Testing**: Verify data sync between systems
3. **Error Recovery Testing**: Test retry mechanisms and error handling
4. **Security Testing**: Verify webhook signature validation

## Production Considerations

### Performance Optimization

1. **Bulk Operations**: Use bulk DML for multiple record updates
2. **Asynchronous Processing**: Process events in background
3. **Database Optimization**: Use appropriate indexes on Stripe ID fields
4. **Governor Limit Management**: Monitor and stay within Salesforce limits

### Security Best Practices

1. **Webhook Secret Management**: Store secrets securely in Custom Metadata
2. **Signature Verification**: Always verify webhook signatures
3. **HTTPS Only**: Ensure all webhook communications use HTTPS
4. **Access Control**: Limit webhook endpoint access to Stripe IPs

### Monitoring & Alerting

1. **Webhook Health Dashboard**: Monitor webhook processing metrics
2. **Error Alerting**: Set up alerts for webhook failures
3. **Performance Monitoring**: Track processing times and success rates
4. **Data Quality Monitoring**: Verify data consistency between systems 