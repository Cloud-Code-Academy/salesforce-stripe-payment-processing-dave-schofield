Support for syncing additional objects

LWCs/Platform Events for real-time notifications (ex. when viewing a record)

Nightly job for sync/catch up on any failures

Name lookup fields - ex. price is autonumber, but want to see other fields

Consolidate SOQL & DML into single class per object like ContactDomain/ContactRepo
    Handle the bypass in there either as parameter or doUpdate() and doUpdateAndBypass() 
    So then when updating new Contacts with stripe ids use doUpdateAndBypassStripe(contactList);



## Webhook Timing Considerations

### Current Behavior
The bidirectional sync between Salesforce and Stripe is working correctly with circular update prevention. However, there are some timing nuances worth documenting:

### Circular Update Prevention
- **Working**: Salesforce updates → Stripe → webhook correctly skipped as "own update"
- **Working**: External Stripe updates → Salesforce (after brief delay)

### Timing Observations
- External Stripe updates may be initially skipped due to metadata timestamp matching
- System self-corrects after 30-60 seconds through natural Contact LastModifiedDate changes
- Multiple webhook events observed for single updates (e.g., timestamps :03:15 and :03:53 for same change)

### Future Enhancement Opportunity
Consider implementing a time buffer in `Stripe_WebhookProcessor.isOwnUpdate()` method:



### Benefits of Time Buffer Approach
- **Immediate processing** of external Stripe updates (no waiting period)
- **Maintains circular prevention** for recent Salesforce-initiated changes  
- **More predictable behavior** independent of background processes
- **Handles Stripe webhook retries** correctly (preserves original event.created time)

### Current Status
System is functional as-is. Enhancement is optional optimization for faster external update processing.





