public class Stripe_Utils {

    private static final Map<String, String> STRIPE_RESERVED_KEYWORDS = new Map<String, String>{
        'object_x' => 'object',
        'currency_x' => 'currency'
    };
    
    /**
     * Converts a JSON string to form-encoded string for Stripe API
     * @param jsonString JSON string representation of the object
     * @return Form-encoded string (e.g., "email=test@example.com&name=John%20Doe")
     */
    public static String jsonToFormEncoded(String jsonString) {
        if (String.isBlank(jsonString)) {
            return '';
        }
        
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        return toFormEncoded(params);
    }
    
    /**
     * Converts a Map<String, Object> to form-encoded string for Stripe API
     * @param params Map of key-value pairs to encode
     * @return Form-encoded string (e.g., "email=test@example.com&name=John%20Doe")
     */
    public static String toFormEncoded(Map<String, Object> params) {
        if (params == null || params.isEmpty()) {
            return '';
        }
        
        List<String> encodedParams = new List<String>();
        
        for (String key : params.keySet()) {
            Object value = params.get(key);
            if (value != null) {
                String stringValue = String.valueOf(value);
                if (String.isNotBlank(stringValue)) {
                    // Handle Apex reserved keyword mapping for Stripe API
                    String encodedKey = key;
                    if (STRIPE_RESERVED_KEYWORDS.containsKey(key)) {
                        encodedKey = STRIPE_RESERVED_KEYWORDS.get(key);
                    }
                    
                    encodedParams.add(encodedKey + '=' + EncodingUtil.urlEncode(stringValue, 'UTF-8'));
                }
            }
        }
        
        return String.join(encodedParams, '&');
    }
    
    /**
     * Replaces Stripe API field names with Apex-compatible field names
     * Handles reserved keyword conflicts in JSON responses
     * @param jsonString JSON string from Stripe API
     * @return JSON string with field names replaced
     */
    public static String replaceStripeFields(String jsonString) {
        if (String.isBlank(jsonString)) {
            return jsonString;
        }
        
        // Replace Stripe field names with Apex-compatible names using the map
        String result = jsonString;
        for (String apexField : STRIPE_RESERVED_KEYWORDS.keySet()) {
            String stripeField = STRIPE_RESERVED_KEYWORDS.get(apexField);
            result = result.replace('"' + stripeField + '":', '"' + apexField + '":');
        }
        
        return result;
    }

} 