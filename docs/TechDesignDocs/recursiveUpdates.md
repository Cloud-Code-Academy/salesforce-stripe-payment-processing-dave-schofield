  Recursive Loop Scenario:

  1. Salesforce Contact updated → Triggers
  ContactTrigger → ContactTriggerHandler.afterUpdate()
  2. Stripe API call → Updates customer in Stripe via
  updateStripeCustomers()
  3. Stripe webhook fired → customer.updated event sent
  to middleware
  4. Middleware forwards → Event to Salesforce webhook
  endpoint
  5. Salesforce processes → Stripe_WebhookProcessor
  handles customer.updated
  6. Contact updated again → Could trigger another
  outbound sync → LOOP


   Implementation path:
  1. Enhance StripeIntegrationSettings with webhook
  bypass methods
  2. Update Stripe_WebhookProcessor to use
  startWebhookProcessing()/endWebhookProcessing()
  3. Your existing triggers automatically benefit - no
  changes needed!

  The flow becomes:
  1. Webhook received → startWebhookProcessing() called
  2. Contact updated → Trigger fires →
  isContactsOutboundEnabled() returns false
  3. No outbound sync triggered → Recursive loop
  prevented
  4. endWebhookProcessing() called → Normal operations
  resume

  This leverages your existing architecture perfectly
  while solving the recursion problem!



    // All of this happens in ONE transaction:

  1. HTTP POST → Webhook_RestResource.doPost()
  2. StripeIntegrationSettings.startWebhookProcessing() // Static var = true
  3. Stripe_WebhookProcessor.process()
  4. update contact; // DML operation
  5. ContactTrigger fires (SAME transaction)
  6. ContactTriggerHandler.afterUpdate()
  7. StripeIntegrationSettings.isContactsOutboundEnabled() // Static var
  still = true
  8. Returns false, no outbound sync
  9. StripeIntegrationSettings.endWebhookProcessing() // Static var = false
  10. Transaction commits


Create contact in SF
Contact Trigger - Trigger handler - Queueable - Client
Get response from Stripe - update SF Contact with Stripe Id
But before updating contact, we don't need to send this update to Stripe (after update trigger), so set the bypass variable, then update SF Contact with Stripe Id, re-enable variable in both try and catch blocks. 


● Perfect! Now the logic is correct:

  Truth Table:
  - MDT false, syncContactsOutbound null → false (globally disabled)
  - MDT false, syncContactsOutbound false → false (globally
  disabled)
  - MDT false, syncContactsOutbound true → false (globally disabled,
   can't override)
  - MDT true, syncContactsOutbound null → true (enabled, no bypass)
  - MDT true, syncContactsOutbound false → false (temporarily
  bypassed)
  - MDT true, syncContactsOutbound true → true (force enabled)

  This gives us the proper hierarchy where MDT acts as the global
  kill switch, and syncContactsOutbound can only disable or force
  enable when MDT allows it.


  ---
  Perfect! Now the circular update prevention is
  implemented:

  Update contact in SF; sends to stripe
  Stripe sends webhook; webhook performs update (unnecessary)
    Sets bypass to not trigger Contact trigger again, but there is an unnecessary update from the webhook

  ✅ Outbound metadata: Both
  Stripe_CreateCustomerRQ and
  Stripe_UpdateCustomerRQ now send:
  - salesforce_contact_id (Contact.Id)
  - salesforce_last_modified
  (Contact.LastModifiedDate timestamp)

  ✅ Inbound comparison: isOwnUpdate() method
  checks:
  - Contact ID matches
  - LastModifiedDate timestamp matches
  - Handles errors gracefully (assumes external
  update on error)

  ✅ Skip processing: If it's our own update,
  logs and skips the webhook processing

  Flow now:
  1. Update Contact in Salesforce → Trigger →
  Future method → Stripe API (with metadata)
  2. Stripe webhook → processCustomerUpdated() →
  isOwnUpdate() returns true → Skip processing!

  This prevents the unnecessary circular update
  while still allowing legitimate external Stripe
   updates to sync back to Salesforce.

