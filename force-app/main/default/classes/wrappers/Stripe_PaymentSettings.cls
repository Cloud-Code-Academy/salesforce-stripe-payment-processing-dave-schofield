/**
 * @description Represents payment settings for Stripe subscriptions
 * @author Cloud Fitness Academy Integration
 * @version 1.0
 */
public class Stripe_PaymentSettings {
    
    // Payment method types (card, bank_transfer, etc.)
    public List<String> payment_method_types { get; set; }
    
    // Whether to save the default payment method
    public String save_default_payment_method { get; set; }
    
    // Payment method options (JSON string for complex options)
    public Map<String, String> payment_method_options { get; set; }
    
    // Constructor
    public Stripe_PaymentSettings() {
        this.payment_method_types = new List<String>();
        this.payment_method_options = new Map<String, String>();
    }
    
    /**
     * @description Add a payment method type
     * @param paymentMethodType Type of payment method (e.g., 'card', 'bank_transfer')
     */
    public void addPaymentMethodType(String paymentMethodType) {
        if (String.isNotBlank(paymentMethodType)) {
            payment_method_types.add(paymentMethodType);
        }
    }
    
    /**
     * @description Set default payment method types for Cloud Fitness Academy
     */
    public void setDefaultPaymentMethods() {
        payment_method_types.clear();
        payment_method_types.add('card');
        save_default_payment_method = 'on_subscription';
    }
} 