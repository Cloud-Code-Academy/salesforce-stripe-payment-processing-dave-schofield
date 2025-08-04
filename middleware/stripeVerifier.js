// stripeVerifier.js
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

function verifyWebhookEvent(rawBody, signature, webhookSecret) {
  try {
    const event = stripe.webhooks.constructEvent(
      rawBody,
      signature,
      webhookSecret,
    );
    return { valid: true, event };
  } catch (error) {
    return { valid: false, error };
  }
}

module.exports = { verifyWebhookEvent };
