/**
 * @description Mock factory for Stripe API callouts in tests
 * Provides mock implementations for various Stripe API endpoints
 */
@isTest
public class Stripe_MockFactory {
    
    /**
     * @description Mock for Stripe get customer API callout
     */
    public class GetCustomerMock implements HttpCalloutMock {
        private String customerId;
        private String email;
        private String name;
        
        public GetCustomerMock() {
            this('cus_test123456789', 'test@example.com', 'Test Customer');
        }
        
        public GetCustomerMock(String customerId, String email, String name) {
            this.customerId = customerId;
            this.email = email;
            this.name = name;
        }
        
        public HttpResponse respond(HttpRequest req) {
            // Verify the request
            Assert.areEqual('GET', req.getMethod(), 'Request method should be GET');
            Assert.isTrue(req.getEndpoint().contains('/v1/customers/' + customerId), 
                'Endpoint should contain the customer ID');
            
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            // Mock Stripe customer response
            String mockResponse = '{' +
                '"id": "' + customerId + '",' +
                '"object": "customer",' +
                '"created": 1640995200,' +
                '"email": "' + email + '",' +
                '"livemode": false,' +
                '"metadata": {},' +
                '"name": "' + name + '",' +
                '"phone": "+1234567890",' +
                '"preferred_locales": [],' +
                '"shipping": null,' +
                '"tax_exempt": "none",' +
                '"test_clock": null' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for Stripe create customer API callout
     */
    public class CreateCustomerMock implements HttpCalloutMock {
        private String customerId;
        private String email;
        private String name;
        
        public CreateCustomerMock() {
            this('cus_test123456789', 'test@example.com', 'Test Customer');
        }
        
        public CreateCustomerMock(String customerId, String email, String name) {
            this.customerId = customerId;
            this.email = email;
            this.name = name;
        }
        
        public HttpResponse respond(HttpRequest req) {
            // Verify the request
            Assert.areEqual('POST', req.getMethod(), 'Request method should be POST');
            Assert.isTrue(req.getEndpoint().contains('/v1/customers'), 
                'Endpoint should be for creating customers');
            
            // Validate request body contains expected fields
            String requestBody = req.getBody();
            Assert.isTrue(requestBody.contains('email='), 'Request should contain email parameter');
            Assert.isTrue(requestBody.contains('name='), 'Request should contain name parameter');
            // Phone is optional - don't require it
            Assert.isTrue(requestBody.contains('description='), 'Request should contain description parameter');
            
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            // Mock Stripe customer creation response
            String mockResponse = '{' +
                '"id": "' + customerId + '",' +
                '"object": "customer",' +
                '"created": 1640995200,' +
                '"email": "' + email + '",' +
                '"livemode": false,' +
                '"metadata": {},' +
                '"name": "' + name + '",' +
                '"phone": "+1234567890",' +
                '"preferred_locales": [],' +
                '"shipping": null,' +
                '"tax_exempt": "none",' +
                '"test_clock": null' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for Stripe update customer API callout
     */
    public class UpdateCustomerMock implements HttpCalloutMock {
        private String customerId;
        private String email;
        private String name;
        
        public UpdateCustomerMock() {
            this('cus_test123456789', 'updated@example.com', 'Updated Customer');
        }
        
        public UpdateCustomerMock(String customerId, String email, String name) {
            this.customerId = customerId;
            this.email = email;
            this.name = name;
        }
        
        public HttpResponse respond(HttpRequest req) {
            // Verify the request
            Assert.areEqual('POST', req.getMethod(), 'Request method should be POST');
            Assert.isTrue(req.getEndpoint().contains('/v1/customers/' + customerId), 
                'Endpoint should contain the customer ID');
            
            // Validate request body contains expected fields
            String requestBody = req.getBody();
            Assert.isTrue(requestBody.contains('email='), 'Request should contain email parameter');
            Assert.isTrue(requestBody.contains('name='), 'Request should contain name parameter');
            // Phone is optional - don't require it
            
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            // Mock Stripe customer update response
            String mockResponse = '{' +
                '"id": "' + customerId + '",' +
                '"object": "customer",' +
                '"created": 1640995200,' +
                '"email": "' + email + '",' +
                '"livemode": false,' +
                '"metadata": {},' +
                '"name": "' + name + '",' +
                '"phone": "+1234567890",' +
                '"preferred_locales": [],' +
                '"shipping": null,' +
                '"tax_exempt": "none",' +
                '"test_clock": null' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for Stripe delete customer API callout
     */
    public class DeleteCustomerMock implements HttpCalloutMock {
        private String customerId;
        
        public DeleteCustomerMock() {
            this('cus_test123456789');
        }
        
        public DeleteCustomerMock(String customerId) {
            this.customerId = customerId;
        }
        
        public HttpResponse respond(HttpRequest req) {
            // Verify the request
            Assert.areEqual('DELETE', req.getMethod(), 'Request method should be DELETE');
            Assert.isTrue(req.getEndpoint().contains('/v1/customers/' + customerId), 
                'Endpoint should contain the customer ID');
            
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            // Mock Stripe customer deletion response
            String mockResponse = '{' +
                '"id": "' + customerId + '",' +
                '"object": "customer",' +
                '"deleted": true' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for Stripe create subscription API callout
     */
    public class CreateSubscriptionMock implements HttpCalloutMock {
        private String subscriptionId;
        private String customerId;
        private String status;
        
        public CreateSubscriptionMock() {
            this('sub_test123456789', 'cus_test123456789', 'active');
        }
        
        public CreateSubscriptionMock(String subscriptionId, String customerId, String status) {
            this.subscriptionId = subscriptionId;
            this.customerId = customerId;
            this.status = status;
        }
        
        public HttpResponse respond(HttpRequest req) {
            // Verify the request
            Assert.areEqual('POST', req.getMethod(), 'Request method should be POST');
            Assert.isTrue(req.getEndpoint().contains('/v1/subscriptions'), 
                'Endpoint should be for creating subscriptions');
            
            // Validate request body contains expected fields
            String requestBody = req.getBody();
            Assert.isTrue(requestBody.contains('customer='), 'Request should contain customer parameter');
            Assert.isTrue(requestBody.contains('items['), 'Request should contain items parameter');
            
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            // Mock Stripe subscription creation response
            String mockResponse = '{' +
                '"id": "' + subscriptionId + '",' +
                '"object": "subscription",' +
                '"created": 1640995200,' +
                '"current_period_start": 1640995200,' +
                '"current_period_end": 1643673600,' +
                '"customer": "' + customerId + '",' +
                '"status": "' + status + '",' +
                '"description": "Test subscription",' +
                '"collection_method": "charge_automatically",' +
                '"default_payment_method": null,' +
                '"default_source": null,' +
                '"default_tax_rates": [],' +
                '"trial_start": null,' +
                '"trial_end": null,' +
                '"metadata": {' +
                    '"salesforce_subscription_id": "sub_test123456789",' +
                    '"plan_type": "monthly"' +
                '},' +
                '"items": {' +
                    '"object": "list",' +
                    '"data": [' +
                        '{' +
                            '"id": "si_test123456789",' +
                            '"object": "subscription_item",' +
                            '"created": 1640995200,' +
                            '"quantity": 1,' +
                            '"subscription": "' + subscriptionId + '",' +
                            '"metadata": {},' +
                            '"price": {' +
                                '"id": "price_test123456789",' +
                                '"object": "price",' +
                                '"active": true,' +
                                '"created": 1640995200,' +
                                '"currency": "usd",' +
                                '"product": "prod_test123456789",' +
                                '"unit_amount": 9999,' +
                                '"unit_amount_decimal": "99.99",' +
                                '"metadata": {},' +
                                '"recurring": {' +
                                    '"interval": "month",' +
                                    '"interval_count": 1,' +
                                    '"usage_type": "licensed"' +
                                '}' +
                            '}' +
                        '}' +
                    '],' +
                    '"has_more": false,' +
                    '"total_count": 1,' +
                    '"url": "/v1/subscription_items"' +
                '}' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for Get Subscription API response
     */
    public class GetSubscriptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Mock a successful Get Subscription response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            String mockResponse = '{' +
                '"id": "sub_test123456789",' +
                '"object": "subscription",' +
                '"application": null,' +
                '"application_fee_percent": null,' +
                '"automatic_tax": {' +
                '"enabled": false' +
                '},' +
                '"billing_cycle_anchor": 1641024000,' +
                '"billing_thresholds": null,' +
                '"cancel_at": null,' +
                '"cancel_at_period_end": false,' +
                '"canceled_at": null,' +
                '"collection_method": "charge_automatically",' +
                '"created": 1641024000,' +
                '"currency": "usd",' +
                '"current_period_end": 1672560000,' +
                '"current_period_start": 1641024000,' +
                '"customer": "cus_test123456789",' +
                '"days_until_due": null,' +
                '"default_payment_method": null,' +
                '"default_source": null,' +
                '"default_tax_rates": [],' +
                '"description": null,' +
                '"discount": null,' +
                '"ended_at": null,' +
                '"items": {' +
                '"object": "list",' +
                '"data": [' +
                '{' +
                '"id": "si_test123456789",' +
                '"object": "subscription_item",' +
                '"billing_thresholds": null,' +
                '"created": 1641024000,' +
                '"metadata": {},' +
                '"price": {' +
                '"id": "price_test123456789",' +
                '"object": "price",' +
                '"active": true,' +
                '"billing_scheme": "per_unit",' +
                '"created": 1641024000,' +
                '"currency": "usd",' +
                '"custom_unit_amount": null,' +
                '"livemode": false,' +
                '"lookup_key": null,' +
                '"metadata": {},' +
                '"nickname": null,' +
                '"product": {' +
                '"id": "prod_test123456789",' +
                '"object": "product",' +
                '"active": true,' +
                '"created": 1641024000,' +
                '"default_price": null,' +
                '"description": "Premium subscription plan",' +
                '"images": [],' +
                '"livemode": false,' +
                '"metadata": {},' +
                '"name": "Premium Plan",' +
                '"package_dimensions": null,' +
                '"shippable": null,' +
                '"statement_descriptor": null,' +
                '"tax_code": null,' +
                '"unit_label": null,' +
                '"updated": 1641024000,' +
                '"url": null' +
                '},' +
                '"recurring": {' +
                '"aggregate_usage": null,' +
                '"interval": "month",' +
                '"interval_count": 1,' +
                '"trial_period_days": null,' +
                '"usage_type": "licensed"' +
                '},' +
                '"tax_behavior": "unspecified",' +
                '"tiers_mode": null,' +
                '"transform_quantity": null,' +
                '"type": "recurring",' +
                '"unit_amount": 9999,' +
                '"unit_amount_decimal": "9999"' +
                '},' +
                '"quantity": 1,' +
                '"subscription": "sub_test123456789",' +
                '"tax_rates": []' +
                '}' +
                '],' +
                '"has_more": false,' +
                '"total_count": 1,' +
                '"url": "/v1/subscription_items?subscription=sub_test123456789"' +
                '},' +
                '"latest_invoice": "in_test123456789",' +
                '"livemode": false,' +
                '"metadata": {},' +
                '"next_pending_invoice_item_invoice": null,' +
                '"on_behalf_of": null,' +
                '"pause_collection": null,' +
                '"payment_settings": {' +
                '"payment_method_options": null,' +
                '"payment_method_types": null,' +
                '"save_default_payment_method": "off"' +
                '},' +
                '"pending_invoice_item_interval": null,' +
                '"pending_setup_intent": null,' +
                '"pending_update": null,' +
                '"schedule": null,' +
                '"start_date": 1641024000,' +
                '"status": "active",' +
                '"test_clock": null,' +
                '"transfer_data": null,' +
                '"trial_end": null,' +
                '"trial_settings": {' +
                '"end_behavior": {' +
                '"missing_payment_method": "create_invoice"' +
                '}' +
                '},' +
                '"trial_start": null' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for Update Subscription API response
     */
    public class UpdateSubscriptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Mock a successful Update Subscription response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            String mockResponse = '{' +
                '"id": "sub_test123456789",' +
                '"object": "subscription",' +
                '"status": "active",' +
                '"customer": "cus_test123456789",' +
                '"currency": "usd",' +
                '"current_period_start": 1641024000,' +
                '"current_period_end": 1672560000,' +
                '"metadata": {' +
                '"salesforce_subscription_id": "a001234567890ABC",' +
                '"salesforce_last_modified": "1641024000000"' +
                '}' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for Delete Subscription API response
     */
    public class DeleteSubscriptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Mock a successful Delete Subscription response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            String mockResponse = '{' +
                '"id": "sub_test123456789",' +
                '"object": "subscription",' +
                '"deleted": true' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
    
    /**
     * @description Mock for error responses (4xx, 5xx)
     */
    public class ErrorMock implements HttpCalloutMock {
        private Integer statusCode;
        private String errorMessage;
        
        public ErrorMock() {
            this(400, 'Bad Request');
        }
        
        public ErrorMock(Integer statusCode, String errorMessage) {
            this.statusCode = statusCode;
            this.errorMessage = errorMessage;
        }
        
        public HttpResponse respond(HttpRequest req) {
            // Create mock error response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setStatus(errorMessage);
            
            // Mock Stripe error response
            String mockResponse = '{' +
                '"error": {' +
                '"type": "invalid_request_error",' +
                '"message": "' + errorMessage + '",' +
                '"param": "id"' +
                '}' +
                '}';
            
            res.setBody(mockResponse);
            return res;
        }
    }
} 