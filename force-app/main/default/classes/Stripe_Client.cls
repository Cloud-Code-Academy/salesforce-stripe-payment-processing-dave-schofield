// Stripe_Client or String_Service
public with sharing class Stripe_Client {

	private static final String LOG_TAG = 'Stripe';

    public Object handleAction(String action, Map<String, Object> params) {
        // add try catch 
        switch on action {
			// CUSTOMER
            when 'create_customer' {
                return createCustomer(params);
            }
            when 'get_customer' {
                return getCustomer(params);
            }
            when 'update_customer' {
                return updateCustomer(params);
            }
            when 'delete_customer' {
                return deleteCustomer(params);
            }

			// SUBSCRIPTION
			when 'create_subscription' {
				return createSubscription(params);
			}
			when 'get_subscription' {
				return getSubscription(params);
			}
			when 'update_subscription' {
				return updateSubscription(params);
			}	
			when 'delete_subscription' {
				return deleteSubscription(params);
			}
			
			// CHECKOUT SESSIONS
			when 'create_checkout_session' {
				return createCheckoutSession(params);
			}
			
			when else {
                Logger.error('Unknown action: ' + action);
				Logger.saveLog();
                throw new StripeException('Unknown action: ' + action);
            }
        }
    }

    private String createCustomer(Map<String, Object> params) {
		Contact contact = (Contact) params.get('contact');
        Stripe_CreateCustomerRQ createCustomerRQ = Stripe_CreateCustomerRQ.syncContactFields(contact);
        HttpRequest req = buildRequest('POST', '/v1/customers', createCustomerRQ.toFormEncoded());
        String responseBody = makeCallout(req);
        
        // Deserialize just to get the ID
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        String stripeId = (String) responseMap.get('id');

		return stripeId;
	}

	private Stripe_GetCustomerRS getCustomer(Map<String, Object> params) {
		Logger.info('Stripe_Client.getCustomer').addTag('TESTING');
		Logger.saveLog();
		String customerId = (String) params.get('customerId');
		HttpRequest req = buildRequest('GET', '/v1/customers/' + customerId, null);
		Stripe_GetCustomerRS res = (Stripe_GetCustomerRS) JSON.deserialize(
			makeCallout(req), 
			Stripe_GetCustomerRS.class
		);
		return res;
	}

	private Boolean updateCustomer(Map<String, Object> params) {
		String customerId = (String) params.get('customerId');
		Contact contact = (Contact) params.get('contact');
		
		Stripe_UpdateCustomerRQ updateCustomerRQ = Stripe_UpdateCustomerRQ.syncContactFields(contact);
		
		HttpRequest req = buildRequest('POST', '/v1/customers/' + customerId, updateCustomerRQ.toFormEncoded());
		String responseBody = makeCallout(req);
		
		// Return true if we got a response (makeCallout returns null on error and logs automatically)
		return responseBody != null;
	}
	
	private Boolean deleteCustomer(Map<String, Object> params) {
		String customerId = (String) params.get('customerId');
		HttpRequest req = buildRequest('DELETE', '/v1/customers/' + customerId, null);
		String response = makeCallout(req);
		return response != null;
	}

	private Map<String, Object> createSubscription(Map<String, Object> params) {
		Stripe_Subscription__c subscriptionRecord = (Stripe_Subscription__c) params.get('subscriptionRecord');
		Stripe_CreateSubscriptionRQ createSubscriptionRQ = new Stripe_CreateSubscriptionRQ(subscriptionRecord);
		HttpRequest req = buildRequest('POST', '/v1/subscriptions', createSubscriptionRQ.toFormEncoded());
		String responseBody = makeCallout(req);
		
		// Deserialize and extract only the essential fields we need
		Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		Map<String, Object> result = new Map<String, Object>();
		
		// Extract only the fields we actually use
		result.put('id', responseMap.get('id'));
		result.put('status', responseMap.get('status'));
		
		// Add helper method for incomplete check
		result.put('isIncomplete', 'incomplete'.equalsIgnoreCase((String) responseMap.get('status')));
		
		return result;
	}
	
	private Map<String, Object> getSubscription(Map<String, Object> params) {
		String subscriptionId = (String) params.get('subscriptionId');
		HttpRequest req = buildRequest('GET', '/v1/subscriptions/' + subscriptionId, null);
		String responseBody = makeCallout(req);
		
		if (responseBody != null) {
			return (Map<String, Object>) JSON.deserializeUntyped(responseBody);
		}
		return null;
	}
	
	private Boolean updateSubscription(Map<String, Object> params) {
		String subscriptionId = (String) params.get('subscriptionId');
		Stripe_Subscription__c subscriptionRecord = (Stripe_Subscription__c) params.get('subscriptionRecord');
		
		// Create a simple update request with metadata tracking
		Map<String, Object> updateParams = new Map<String, Object>();
		
		// Add metadata for recursive prevention
		Map<String, String> metadata = new Map<String, String>();
		metadata.put('salesforce_subscription_id', subscriptionRecord.Id);
		metadata.put('salesforce_last_modified', String.valueOf(subscriptionRecord.LastModifiedDate.getTime()));
		updateParams.put('metadata', metadata);
		
		// Convert to form-encoded body
		List<String> formParams = new List<String>();
		Map<String, String> metadataMap = (Map<String, String>) updateParams.get('metadata');
		for (String key : metadataMap.keySet()) {
			String value = metadataMap.get(key);
			if (String.isNotBlank(value)) {
				formParams.add('metadata[' + key + ']=' + EncodingUtil.urlEncode(value, 'UTF-8'));
			}
		}
		String formBody = String.join(formParams, '&');
		
		HttpRequest req = buildRequest('POST', '/v1/subscriptions/' + subscriptionId, formBody);
		String response = makeCallout(req);
		return response != null;
	}
	
	private Boolean deleteSubscription(Map<String, Object> params) {
		String subscriptionId = (String) params.get('subscriptionId');
		HttpRequest req = buildRequest('DELETE', '/v1/subscriptions/' + subscriptionId, null);
		String response = makeCallout(req);
		return response != null;
	}

	private Map<String, Object> createCheckoutSession(Map<String, Object> params) {
		Stripe_Subscription__c subscriptionRecord = (Stripe_Subscription__c) params.get('subscriptionRecord');
		
		// Create wrapper class to handle form encoding - it gets customer and price IDs from the record
		Stripe_CreateCheckoutSessionRQ checkoutSessionRQ = Stripe_CreateCheckoutSessionRQ.forSubscription(subscriptionRecord);
		
		HttpRequest req = buildRequest('POST', '/v1/checkout/sessions', checkoutSessionRQ.toFormEncoded());
		String responseBody = makeCallout(req);
		
		if (responseBody != null) {
			// Deserialize and extract the essential fields we need
			Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
			Map<String, Object> result = new Map<String, Object>();
			
			// Extract only the fields we actually use
			result.put('id', responseMap.get('id'));
			result.put('url', responseMap.get('url'));
			result.put('status', responseMap.get('status'));
			result.put('payment_status', responseMap.get('payment_status'));
			
			return result;
		}
		
		return null;
	}
    
	/**
	 * Makes a callout to the Stripe API using the provided strategy
	 * @param strategy The strategy to use for the API call
	 * @return String The response from the API (project ID or issue key)
	 */
		private static HttpRequest buildRequest(String method, String path, String body) {
		// Create the HTTP request
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:Stripe_Legacy' + path);
		req.setMethod(method);
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		req.setHeader('Authorization', 'Bearer {!$Credential.Password}');
		if (method != 'GET' && body != null) {
			req.setBody(body);
		}
        return req;
	}


    /**
	 * Makes a callout to the Stripe API using the provided strategy
	 * @param strategy The strategy to use for the API call
	 * @return String The response from the API (project ID or issue key)
	 */
	private static String makeCallout(HttpRequest req) {
		try {
			Logger.info('Making Stripe API call: ' + req.getMethod() + ' ' + req.getEndpoint()).addTag(LOG_TAG);
			
			// Send the request
			Http http = new Http();
			HttpResponse res = http.send(req);
			
			// Process the response
			if (res.getStatusCode() != null && (res.getStatusCode() == 200 || res.getStatusCode() == 201)) {
				Logger.info('Stripe API call successful: ' + res.getStatusCode()).addTag(LOG_TAG);
				Logger.saveLog();
				// Replace Stripe field names with Apex-compatible names before returning
				return Stripe_Utils.replaceStripeFields(res.getBody());
			} else {
				String errorMsg = 'Stripe API call failed: ' + res.getStatusCode() + ' ' + res.getStatus();
				if (String.isNotBlank(res.getBody())) {
					errorMsg += ' Response: ' + res.getBody();
				}
				Logger.error(errorMsg).addTag(LOG_TAG);
				Logger.saveLog();
				return null;
			}
		} catch (Exception e) {
			Logger.error('Exception in Stripe API call: ' + e.getMessage()).addTag(LOG_TAG);
			Logger.saveLog();
			return null;
		}
	}

}