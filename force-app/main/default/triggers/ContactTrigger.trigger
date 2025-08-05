/**
 * @description Trigger for Contact object to manage Stripe customer synchronization
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
trigger ContactTrigger on Contact (before delete, after insert, after update) {
    
    if (StripeIntegrationSettings.isContactsOutboundEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_DELETE {
                ContactTriggerHandler.beforeDelete(Trigger.old);
            }
            when AFTER_INSERT {
                Logger.info('ContactTrigger.afterInsert').addTag('TESTING');
                ContactTriggerHandler.afterInsert(Trigger.new);
            }
            when AFTER_UPDATE {
                Logger.info('ContactTrigger.afterUpdate').addTag('TESTING');
                ContactTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
            }
        }
        Logger.saveLog();
    }

} 