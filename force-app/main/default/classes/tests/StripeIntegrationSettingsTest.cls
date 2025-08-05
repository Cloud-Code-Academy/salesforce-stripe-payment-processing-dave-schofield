@IsTest
public class StripeIntegrationSettingsTest {
    
    @IsTest
    static void testContactBypassPreventsRecursion() {
        // Setup test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        insert testContact;
        
        // Enable Stripe sync in settings for testing
        StripeIntegrationSettings.syncContactsOutbound = true;
        
        Test.startTest();
        
        // Verify sync is normally enabled
        System.assert(StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Sync should be enabled initially');
        
        // Bypass contact sync (simulating webhook processing)
        StripeIntegrationSettings.bypassContactSync();
        
        // Verify sync is disabled during bypass
        System.assert(!StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Sync should be disabled during bypass');
        
        // Perform DML operation that would normally trigger outbound sync
        testContact.Email = 'updated@example.com';
        update testContact; // Contact trigger fires but sees bypass = true
        
        // Verify sync is STILL disabled (static variable persisted through DML)
        System.assert(!StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Contact sync should still be bypassed');
        
        // Re-enable contact sync
        StripeIntegrationSettings.enableContactSync();
        
        // Verify sync is re-enabled
        System.assert(StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Sync should be re-enabled after webhook processing');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGranularSyncBypass() {
        // Enable Stripe sync in settings for testing
        StripeIntegrationSettings.syncContactsOutbound = true;
        StripeIntegrationSettings.syncSubscriptionsOutbound = true;
        
        Test.startTest();
        
        // Initially both should be enabled
        System.assert(StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Contact sync should be enabled initially');
        System.assert(StripeIntegrationSettings.isSubscriptionsOutboundEnabled(), 
                     'Subscription sync should be enabled initially');
        
        // Bypass only contact sync
        StripeIntegrationSettings.bypassContactSync();
        
        // Contact sync should be disabled, subscription sync still enabled
        System.assert(!StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Contact sync should be disabled');
        System.assert(StripeIntegrationSettings.isSubscriptionsOutboundEnabled(), 
                     'Subscription sync should still be enabled');
        
        // Re-enable contact sync
        StripeIntegrationSettings.enableContactSync();
        
        // Both should be enabled again
        System.assert(StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Contact sync should be re-enabled');
        System.assert(StripeIntegrationSettings.isSubscriptionsOutboundEnabled(), 
                     'Subscription sync should still be enabled');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testCustomMetadataOverridesBypass() {
        // Disable sync via custom metadata (simulated by test variable)
        StripeIntegrationSettings.syncContactsOutbound = false;
        
        Test.startTest();
        
        // Even without webhook processing, sync should be disabled due to metadata
        System.assert(!StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Sync should be disabled due to metadata setting');
        
        // Bypass contact sync
        StripeIntegrationSettings.bypassContactSync();
        
        // Should still be disabled
        System.assert(!StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Sync should remain disabled');
        
        // Re-enable contact sync
        StripeIntegrationSettings.enableContactSync();
        
        // Should still be disabled due to metadata
        System.assert(!StripeIntegrationSettings.isContactsOutboundEnabled(), 
                     'Sync should remain disabled due to metadata setting');
        
        Test.stopTest();
    }
}