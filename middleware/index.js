require("dotenv").config();
const express = require("express");
const jwt = require("jsonwebtoken");
const axios = require("axios");
const fs = require("fs");
const { verifyWebhookEvent } = require("./stripeVerifier");

const privateKey = fs.readFileSync("./private.key", "utf8");

const app = express();

// Stripe route MUST use raw body parser for signature verification
app.post(
  "/stripe-webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      const signature = req.headers["stripe-signature"];
      const { valid, event, error } = verifyWebhookEvent(
        req.body, // raw buffer
        signature,
        process.env.STRIPE_SECRET_KEY, // this should be the webhook secret, not the secret key
      );

      if (!valid) {
        console.error(
          "⚠️ Webhook signature verification failed:",
          error.message,
        );
        return res.status(400).send(`Webhook Error: ${error.message}`);
      }

      console.log("✅ Verified Stripe event:", event.type);

      // Step 1: Create JWT payload
      const payload = {
        iss: process.env.SF_CLIENT_ID,
        sub: process.env.SF_USERNAME,
        aud: process.env.SF_LOGIN_URL,
        exp: Math.floor(Date.now() / 1000) + 60 * 5,
      };

      // Step 2: Sign the JWT
      const token = jwt.sign(payload, privateKey, { algorithm: "RS256" });

      // Step 3: Prepare form data for Salesforce OAuth JWT token request
      const params = new URLSearchParams();
      params.append(
        "grant_type",
        "urn:ietf:params:oauth:grant-type:jwt-bearer",
      );
      params.append("assertion", token);

      // Step 4: Request access token from Salesforce
      const tokenResponse = await axios.post(
        `${process.env.SF_LOGIN_URL}/services/oauth2/token`,
        params.toString(),
        { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
      );

      const accessToken = tokenResponse.data.access_token;
      const instanceUrl = tokenResponse.data.instance_url;
      console.log("instance url: " + instanceUrl);

      // Step 5: Forward Stripe event to Salesforce Apex REST endpoint
      const salesforceResponse = await axios.post(
        `${instanceUrl}/services/apexrest/webhook/stripe`,
        event,
        {
          headers: { Authorization: `Bearer ${accessToken}` },
        },
      );

      console.log("Salesforce response:", salesforceResponse.data);
      res.status(200).send("OK");
    } catch (err) {
      console.error(
        "Error processing Stripe webhook:",
        err.response?.data || err.message,
      );
      res.status(500).send("Failed to forward to Salesforce");
    }
  },
);

// Now apply JSON parser for all other routes
app.use(express.json());

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
