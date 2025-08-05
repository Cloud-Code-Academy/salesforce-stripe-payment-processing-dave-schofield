/**
 * @description Trigger for Stripe_Subscription__c object to manage Stripe subscription synchronization
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
trigger StripeSubscriptionTrigger on Stripe_Subscription__c (before delete, after insert, after update, after undelete) {
    
    if (StripeIntegrationSettings.isSubscriptionsOutboundEnabled()) {
        switch on Trigger.operationType {
            when BEFORE_DELETE {
                StripeSubscriptionTriggerHandler.beforeDelete(Trigger.old);
            }
            when AFTER_INSERT {
                Logger.info('StripeSubscriptionTrigger.afterInsert').addTag('TESTING');
                StripeSubscriptionTriggerHandler.afterInsert(Trigger.new);
            }
            when AFTER_UPDATE {
                Logger.info('StripeSubscriptionTrigger.afterUpdate').addTag('TESTING');
                StripeSubscriptionTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
            }
            when AFTER_UNDELETE {
                Logger.info('StripeSubscriptionTrigger.afterUndelete').addTag('TESTING');
                StripeSubscriptionTriggerHandler.afterUndelete(Trigger.new);
            }
        }
        Logger.saveLog();
    }
} 