@RestResource(urlMapping='/webhook/*')
global without sharing class Webhook_RestResource {

    @HttpGet
    global static String doGet() {
        return 'Webhook endpoint is working!';
    }

    @HttpPost
    global static void doPost() {
        // Basic debug to see if endpoint is hit at all
        System.debug('=== WEBHOOK ENDPOINT HIT ===');
        
        // Debug logging to see if webhook is received
        Logger.info('Webhook received').addTag('Stripe_Webhook');
        Logger.saveLog();
        
        Logger.info('Request URI: ' + RestContext.request.requestURI).addTag('Stripe_Webhook');
        Logger.info('Headers: ' + RestContext.request.headers).addTag('Stripe_Webhook');
        Logger.info('Body: ' + RestContext.request.requestBody.toString()).addTag('Stripe_Webhook');
        Logger.saveLog();

        // Quick test response
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf('Webhook received');
        
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            // get uri
            String uri = req.requestURI;
            Logger.info('Request URI: ' + uri).addTag('Stripe_Webhook');
            Logger.saveLog();
            // split on /
            List<String> uriParts = uri.split('/');
            // incoming request to /webhook/stripe...
            // [0] = "" (empty)
            // [1] = webhook
            // [2] = stripe
            String service = uriParts.size() > 2 ? uriParts[2] : '';
            switch on service {
                when 'stripe' {
                    processStripeWebhook(req, res);
                }
                when else {
                    res.statusCode = 400;
                    res.responseBody = Blob.valueOf('Unknown service for RestResource: ' + service);
                }
            }
        } catch (Exception e) {
            // Logger.error('Webhook processing failed', e);
            // Logger.saveLog();
            RestContext.response.statusCode = 400;
        }
    }

    private static void processStripeWebhook(RestRequest req, RestResponse res) {
        System.debug('=== PROCESSING STRIPE WEBHOOK ===');
        Logger.info('Processing Stripe webhook');
        Logger.saveLog();
        // get payload
        String payload = req.requestBody.toString();

        // consider moving this to queueable for asynchronou processing
        // System.enqueueJob(new StripeWebhookProcessor(event));
        // then return RestContext.response.statusCode = 200;
        
        // Process the webhook
        try {
            Logger.info('About to process Stripe webhook').addTag('DEBUG');
            Logger.saveLog();
            
            // Parse payload into event wrapper
            Stripe_Event event = new Stripe_Event(payload);
            Logger.info('Successfully parsed Stripe event: ' + event.type).addTag('DEBUG');
            Logger.saveLog();
            
            // Process the event
            Stripe_WebhookProcessor processor = new Stripe_WebhookProcessor(event); 
            processor.process();
            
            Logger.info('Successfully processed Stripe webhook').addTag('DEBUG');
            Logger.saveLog();
        } catch (Exception processingEx) {
            Logger.error('Failed to process Stripe webhook: ' + processingEx.getMessage()).addTag('Stripe_Webhook');
            Logger.saveLog();
            throw processingEx;
        }
        
        res.statusCode = 200;
        res.responseBody = Blob.valueOf('Webhook processed successfully');
    }

}