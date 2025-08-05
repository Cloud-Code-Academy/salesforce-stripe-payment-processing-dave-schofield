# Outbound Integration Endpoints (Salesforce → Stripe)

This document outlines the specific Stripe API endpoints required for outbound integrations from Salesforce to Stripe, organized by business process and use case.

## ⚠️ Important: Stripe API Versioning

**Stripe currently supports two API versions:**

### API v1 (Legacy)
- **Base URL**: `https://api.stripe.com/v1/`
- **Content-Type**: `application/x-www-form-urlencoded` (form-encoded data)
- **Status**: Legacy but still fully supported
- **Example**: `POST /v1/customers` with form-encoded body

### API v1 (Currently Working - Recommended)
- **Base URL**: `https://api.stripe.com/v1/`
- **Content-Type**: `application/x-www-form-urlencoded` (form-encoded data)
- **Status**: Fully supported and tested
- **Example**: `POST /v1/customers` with form-encoded body
- **Documentation**: [Stripe Customers API v1](https://docs.stripe.com/api/customers)

**This integration uses API v1 as it's fully supported and working.**

### API v2 (Future - Limited Availability)
- **Base URL**: `https://api.stripe.com/v2/`
- **Content-Type**: `application/json` (JSON data)
- **Status**: Limited endpoint availability
- **Documentation**: [Stripe API v2 Overview](https://docs.stripe.com/api-v2-overview)

**Note**: v2 customer endpoints are not yet documented or available. v1 is the current recommended approach.

## Quick Reference - All Endpoints

### Customer Management
| Endpoint | Method | Purpose | Business Use Case | Request | Action | Postman Link |
|----------|--------|---------|-------------------|---------|--------|--------------|
| `/customers` | POST | Create new customer | New customer onboarding | Body | createCustomer | [link](https://www.postman.com/stripedev/stripe-developers/request/jezh916/create-a-customer?tab=overview) |
| `/customers/{customer_id}` | POST | Update customer information | Customer data synchronization | Body | updateCustomer | [link]() |
| `/customers/{customer_id}` | GET | Retrieve customer details | Data validation and reconciliation | None | getCustomer | [link](https://www.postman.com/stripedev/stripe-developers/request/xnvtldm/retrieve-a-customer) |
| `/customers` | GET | List all customers | Bulk data synchronization | Query Params | getAllCustomers | [link](https://www.postman.com/stripedev/stripe-developers/request/yz5enya/list-all-customers) |
| `/customers/{customer_id}` | DELETE | Delete customer | Data cleanup and GDPR compliance | None | deleteCustomer | [link]() |

### Product & Pricing
| Endpoint | Method | Purpose | Business Use Case | Request | Action | Postman Link |
|----------|--------|---------|-------------------|---------|--------|--------------|
| `/products` | GET | List available products | Populate product selection UI | Query Params | getAllProducts | [link]() |
| `/prices` | GET | List pricing information | Display pricing options | Query Params | getAllPrices | [link]() |
| `/prices/{price_id}` | GET | Get specific price details | Validate pricing before subscription | None | getPrice | [link]() |
| `/products` | POST | Create new product | Dynamic product catalog management | Body | createProduct | [link]() |
| `/prices` | POST | Create new price | Dynamic pricing for fitness gear and services | Body | createPrice | [link]() |

### Subscription Management
| Endpoint | Method | Purpose | Business Use Case | Request | Action | Postman Link |
|----------|--------|---------|-------------------|---------|--------|--------------|
| `/subscriptions` | POST | Create new subscription | New subscription setup | Body | createSubscription | [link]() |
| `/subscriptions/{subscription_id}` | POST | Update subscription | Plan changes and upgrades/downgrades | Body | updateSubscription | [link]() |
| `/subscriptions/{subscription_id}` | DELETE | Cancel subscription | Customer cancellation requests | Query Params | cancelSubscription | [link]() |
| `/subscriptions/{subscription_id}` | GET | Get subscription details | Real-time status checks | None | getSubscription | [link]() |
| `/subscriptions` | GET | List subscriptions | Customer service and bulk reporting | Query Params | getAllSubscriptions | [link]() |
| `/subscriptions/{subscription_id}/pause` | POST | Pause subscription | Handle failed payments and temporary suspensions | Body | pauseSubscription | [link]() |
| `/subscriptions/{subscription_id}/resume` | POST | Resume subscription | Reactivate after payment issues resolved | Body | resumeSubscription | [link]() |

### Payment Processing
| Endpoint | Method | Purpose | Business Use Case | Request | Action | Postman Link |
|----------|--------|---------|-------------------|---------|--------|--------------|
| `/checkout/sessions` | POST | Create payment link | Secure payment collection | Body | createCheckoutSession | [link]() |
| `/checkout/sessions/{session_id}` | GET | Get session status | Track payment completion | None | getCheckoutSession | [link]() |
| `/payment_intents` | POST | Create payment intent | One-time payments | Body | createPaymentIntent | [link]() |
| `/payment_intents/{payment_intent_id}` | GET | Get payment intent status | Payment verification | None | getPaymentIntent | [link]() |
| `/payment_intents/{payment_intent_id}/confirm` | POST | Confirm payment intent | Process saved payment methods | Body | confirmPaymentIntent | [link]() |
| `/payment_intents/{payment_intent_id}/cancel` | POST | Cancel payment intent | Cancel pending coaching session payments | Body | cancelPaymentIntent | [link]() |

### Invoice Management
| Endpoint | Method | Purpose | Business Use Case | Request | Action | Postman Link |
|----------|--------|---------|-------------------|---------|--------|--------------|
| `/invoices` | POST | Create manual invoice | Manual billing | Body | createInvoice | [link]() |
| `/invoices/{invoice_id}` | GET | Get invoice details | Invoice status tracking | None | getInvoice | [link]() |
| `/invoices` | GET | List invoices | Financial reporting | Query Params | getAllInvoices | [link]() |

### Payment Methods
| Endpoint | Method | Purpose | Business Use Case | Request | Action | Postman Link |
|----------|--------|---------|-------------------|---------|--------|--------------|
| `/payment_methods/{payment_method_id}/attach` | POST | Attach payment method | Save customer payment methods | Body | attachPaymentMethod | [link]() |
| `/payment_methods/{payment_method_id}/detach` | POST | Detach payment method | Payment method updates | None | detachPaymentMethod | [link]() |
| `/customers/{customer_id}/payment_methods` | GET | List payment methods | Customer service | Query Params | getCustomerPaymentMethods | [link]() |

### Refunds
| Endpoint | Method | Purpose | Business Use Case | Request | Action | Postman Link |
|----------|--------|---------|-------------------|---------|--------|--------------|
| `/refunds` | POST | Create refund | Customer refund requests | Body | createRefund | [link]() |
| `/refunds/{refund_id}` | GET | Get refund details | Refund status tracking | None | getRefund | [link]() |



## Authentication & Base Configuration

### Stripe API Base URL
- **Base URL**: `https://api.stripe.com/v1/`
- **Authentication**: Bearer token using Stripe Secret Key
- **Content-Type**: `application/x-www-form-urlencoded`

## 1. Customer Management Endpoints

### 1.1 Create Customer
- **Endpoint**: `POST /customers`
- **Purpose**: Create a new customer in Stripe when a Contact is created in Salesforce
- **Request**:
  ```json
  {
    "email": "customer@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "metadata": {
      "salesforce_contact_id": "003XXXXXXXXXXXXXXX"
    },
    "description": "Customer from Salesforce"
  }
  ```
- **Response**:
  ```json
  {
    "id": "cus_SiPWBahu9JarOQ",
    "object": "customer",
    "address": null,
    "balance": 0,
    "created": 1753023539,
    "currency": null,
    "default_source": null,
    "delinquent": false,
    "description": "New customer from Postman",
    "discount": null,
    "email": "testemail@gmail.com.invalid",
    "invoice_prefix": "KP23KBZA",
    "invoice_settings": {
        "custom_fields": null,
        "default_payment_method": null,
        "footer": null,
        "rendering_options": null
    },
    "livemode": false,
    "metadata": {
      "salesforce_contact_id": "003XXXXXXXXXXXXXXX"
    },
    "name": "Post Man",
    "next_invoice_sequence": 1,
    "phone": "555-123-1234",
    "preferred_locales": [],
    "shipping": null,
    "tax_exempt": "none",
    "test_clock": null
  }
  ```
- **Business Use Case**: New customer onboarding process

### 1.2 Update Customer
- **Endpoint**: `POST /customers/{customer_id}`
- **Purpose**: Update customer information when Contact details change in Salesforce
- **Request**:
  ```json
  {
    "email": "updated@example.com",
    "name": "John Smith",
    "phone": "+1987654321",
    "metadata": {
      "salesforce_contact_id": "003XXXXXXXXXXXXXXX",
      "last_updated": "2024-01-15T10:30:00Z"
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "cus_XXXXXXXXXXXXX",
    "object": "customer",
    "created": 1640995200,
    "email": "updated@example.com",
    "name": "John Smith",
    "phone": "+1987654321",
    "metadata": {
      "salesforce_contact_id": "003XXXXXXXXXXXXXXX",
      "last_updated": "2024-01-15T10:30:00Z"
    },
    "livemode": false
  }
  ```
- **Business Use Case**: Customer information synchronization

### 1.3 Retrieve Customer
- **Endpoint**: `GET /customers/{customer_id}`
- **Purpose**: Fetch customer details from Stripe for verification and sync status
- **Request**: No request body (GET request)
- **Response**:
  ```json
{
    "id": "cus_SiPWBahu9JarOQ",
    "object": "customer",
    "address": null,
    "balance": 0,
    "created": 1753023539,
    "currency": null,
    "default_source": null,
    "delinquent": false,
    "description": "New customer from Postman",
    "discount": null,
    "email": "testemail@gmail.com.invalid",
    "invoice_prefix": "KP23KBZA",
    "invoice_settings": {
        "custom_fields": null,
        "default_payment_method": null,
        "footer": null,
        "rendering_options": null
    },
    "livemode": false,
    "metadata": {},
    "name": "Post Man",
    "next_invoice_sequence": 1,
    "phone": "555-123-1234",
    "preferred_locales": [],
    "shipping": null,
    "tax_exempt": "none",
    "test_clock": null
}
  ```
- **Business Use Case**: Data validation and reconciliation

### 1.4 List Customers
- **Endpoint**: `GET /customers`
- **Purpose**: Retrieve all customers for bulk synchronization operations
- **Request**: Query parameters
  ```
  ?limit=100&starting_after=cus_XXXXXXXXXXXXX
  ```
- **Response**:
  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "cus_XXXXXXXXXXXXX",
        "object": "customer",
        "created": 1640995200,
        "email": "customer@example.com",
        "name": "John Doe",
        "metadata": {
          "salesforce_contact_id": "003XXXXXXXXXXXXXXX"
        }
      }
    ],
    "has_more": true,
    "url": "/v1/customers"
  }
  ```
- **Business Use Case**: Bulk data synchronization and reconciliation

### 1.5 Delete Customer
- **Endpoint**: `DELETE /customers/{customer_id}`
- **Purpose**: Delete a customer from Stripe (data cleanup and GDPR compliance)
- **Request**: No request body (DELETE request)
- **Response**:
  ```json
  {
    "id": "cus_XXXXXXXXXXXXX",
    "object": "customer",
    "deleted": true
  }
  ```
- **Business Use Case**: Data cleanup, GDPR compliance, and removing test customers

## 2. Product & Price Management Endpoints

### 2.1 List Products
- **Endpoint**: `GET /products`
- **Purpose**: Retrieve available products for subscription setup
- **Request**: Query parameters
  ```
  ?active=true&limit=50
  ```
- **Response**:
  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "prod_XXXXXXXXXXXXX",
        "object": "product",
        "active": true,
        "created": 1640995200,
        "name": "Premium Plan",
        "description": "Premium subscription plan",
        "metadata": {
          "salesforce_product_id": "01tXXXXXXXXXXXXXXX"
        }
      }
    ],
    "has_more": false,
    "url": "/v1/products"
  }
  ```
- **Business Use Case**: Populate product selection in Salesforce UI

### 2.2 List Prices
- **Endpoint**: `GET /prices`
- **Purpose**: Retrieve pricing information for products
- **Request**: Query parameters
  ```
  ?product=prod_XXXXXXXXXXXXX&active=true&recurring=true
  ```
- **Response**:
  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "price_XXXXXXXXXXXXX",
        "object": "price",
        "active": true,
        "created": 1640995200,
        "currency": "usd",
        "product": "prod_XXXXXXXXXXXXX",
        "recurring": {
          "interval": "month",
          "interval_count": 1
        },
        "unit_amount": 2999,
        "unit_amount_decimal": "2999"
      }
    ],
    "has_more": false,
    "url": "/v1/prices"
  }
  ```
- **Business Use Case**: Display pricing options for subscription setup

### 2.3 Retrieve Price
- **Endpoint**: `GET /prices/{price_id}`
- **Purpose**: Get specific price details for subscription creation
- **Request**: No request body (GET request)
- **Response**:
  ```json
  {
    "id": "price_XXXXXXXXXXXXX",
    "object": "price",
    "active": true,
    "created": 1640995200,
    "currency": "usd",
    "product": "prod_XXXXXXXXXXXXX",
    "recurring": {
      "interval": "month",
      "interval_count": 1
    },
    "unit_amount": 2999,
    "unit_amount_decimal": "2999",
    "metadata": {
      "salesforce_price_id": "01sXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Business Use Case**: Validate pricing before creating subscriptions

### 2.4 Create Product
- **Endpoint**: `POST /products`
- **Purpose**: Create new products in Stripe for dynamic product catalog management
- **Request**:
  ```json
  {
    "name": "Premium Dumbbells Set",
    "description": "Professional grade dumbbells for home fitness",
    "metadata": {
      "salesforce_product_id": "a0pXXXXXXXXXXXXXXX",
      "category": "equipment",
      "sku": "DB-PREM-001"
    },
    "active": true
  }
  ```
- **Response**:
  ```json
  {
    "id": "prod_XXXXXXXXXXXXX",
    "object": "product",
    "active": true,
    "created": 1640995200,
    "name": "Premium Dumbbells Set",
    "description": "Professional grade dumbbells for home fitness",
    "metadata": {
      "salesforce_product_id": "a0pXXXXXXXXXXXXXXX",
      "category": "equipment",
      "sku": "DB-PREM-001"
    }
  }
  ```
- **Business Use Case**: Dynamic product catalog management for fitness gear store

### 2.5 Create Price
- **Endpoint**: `POST /prices`
- **Purpose**: Create new pricing for products with dynamic pricing capabilities
- **Request**:
  ```json
  {
    "product": "prod_XXXXXXXXXXXXX",
    "unit_amount": 12999,
    "currency": "usd",
    "recurring": {
      "interval": "month",
      "interval_count": 1
    },
    "metadata": {
      "salesforce_price_id": "01sXXXXXXXXXXXXXXX",
      "plan_type": "monthly_all"
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "price_XXXXXXXXXXXXX",
    "object": "price",
    "active": true,
    "created": 1640995200,
    "currency": "usd",
    "product": "prod_XXXXXXXXXXXXX",
    "recurring": {
      "interval": "month",
      "interval_count": 1
    },
    "unit_amount": 12999,
    "unit_amount_decimal": "12999",
    "metadata": {
      "salesforce_price_id": "01sXXXXXXXXXXXXXXX",
      "plan_type": "monthly_all"
    }
  }
  ```
- **Business Use Case**: Dynamic pricing for fitness gear and subscription plans

## 3. Subscription Management Endpoints

### 3.1 Create Subscription
- **Endpoint**: `POST /subscriptions`
- **Purpose**: Create a new subscription for a customer
- **Request**:
  ```json
  {
    "customer": "cus_XXXXXXXXXXXXX",
    "items": [
      {
        "price": "price_XXXXXXXXXXXXX",
        "quantity": 1
      }
    ],
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
    },
    "collection_method": "charge_automatically",
    "payment_behavior": "default_incomplete",
    "payment_settings": {
      "payment_method_types": ["card"],
      "save_default_payment_method": "on_subscription"
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "sub_XXXXXXXXXXXXX",
    "object": "subscription",
    "created": 1640995200,
    "current_period_start": 1640995200,
    "current_period_end": 1643673600,
    "customer": "cus_XXXXXXXXXXXXX",
    "items": {
      "object": "list",
      "data": [
        {
          "id": "si_XXXXXXXXXXXXX",
          "object": "subscription_item",
          "price": {
            "id": "price_XXXXXXXXXXXXX",
            "object": "price",
            "unit_amount": 2999
          },
          "quantity": 1
        }
      ]
    },
    "status": "incomplete",
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Business Use Case**: New subscription setup by sales representatives

### 3.2 Update Subscription
- **Endpoint**: `POST /subscriptions/{subscription_id}`
- **Purpose**: Modify existing subscription (change plan, quantity, etc.)
- **Request**:
  ```json
  {
    "items": [
      {
        "id": "si_XXXXXXXXXXXXX",
        "price": "price_XXXXXXXXXXXXX",
        "quantity": 2
      }
    ],
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX",
      "last_updated": "2024-01-15T10:30:00Z"
    },
    "proration_behavior": "create_prorations"
  }
  ```
- **Response**:
  ```json
  {
    "id": "sub_XXXXXXXXXXXXX",
    "object": "subscription",
    "created": 1640995200,
    "current_period_start": 1640995200,
    "current_period_end": 1643673600,
    "customer": "cus_XXXXXXXXXXXXX",
    "items": {
      "object": "list",
      "data": [
        {
          "id": "si_XXXXXXXXXXXXX",
          "object": "subscription_item",
          "price": {
            "id": "price_XXXXXXXXXXXXX",
            "object": "price",
            "unit_amount": 2999
          },
          "quantity": 2
        }
      ]
    },
    "status": "active",
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX",
      "last_updated": "2024-01-15T10:30:00Z"
    }
  }
  ```
- **Business Use Case**: Subscription plan changes and upgrades/downgrades

### 3.3 Cancel Subscription
- **Endpoint**: `DELETE /subscriptions/{subscription_id}`
- **Purpose**: Cancel an active subscription
- **Request**: Query parameters
  ```
  ?prorate=true&invoice_now=true
  ```
- **Response**:
  ```json
  {
    "id": "sub_XXXXXXXXXXXXX",
    "object": "subscription",
    "created": 1640995200,
    "current_period_start": 1640995200,
    "current_period_end": 1643673600,
    "customer": "cus_XXXXXXXXXXXXX",
    "canceled_at": 1640995300,
    "cancel_at_period_end": false,
    "status": "canceled",
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Business Use Case**: Customer cancellation requests

### 3.4 Retrieve Subscription
- **Endpoint**: `GET /subscriptions/{subscription_id}`
- **Purpose**: Get current subscription status and details
- **Request**: No request body (GET request)
- **Response**:
  ```json
  {
    "id": "sub_XXXXXXXXXXXXX",
    "object": "subscription",
    "created": 1640995200,
    "current_period_start": 1640995200,
    "current_period_end": 1643673600,
    "customer": "cus_XXXXXXXXXXXXX",
    "items": {
      "object": "list",
      "data": [
        {
          "id": "si_XXXXXXXXXXXXX",
          "object": "subscription_item",
          "price": {
            "id": "price_XXXXXXXXXXXXX",
            "object": "price",
            "unit_amount": 2999
          },
          "quantity": 1
        }
      ]
    },
    "status": "active",
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Business Use Case**: Real-time subscription status checks

### 3.5 List Subscriptions
- **Endpoint**: `GET /subscriptions`
- **Purpose**: Retrieve all subscriptions for a customer or bulk operations
- **Request**: Query parameters
  ```
  ?customer=cus_XXXXXXXXXXXXX&status=active&limit=100
  ```
- **Response**:
  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "sub_XXXXXXXXXXXXX",
        "object": "subscription",
        "created": 1640995200,
        "current_period_start": 1640995200,
        "current_period_end": 1643673600,
        "customer": "cus_XXXXXXXXXXXXX",
        "status": "active",
        "metadata": {
          "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
        }
      }
    ],
    "has_more": false,
    "url": "/v1/subscriptions"
  }
  ```
- **Business Use Case**: Customer service inquiries and bulk reporting

### 3.6 Pause Subscription
- **Endpoint**: `POST /subscriptions/{subscription_id}/pause`
- **Purpose**: Temporarily pause a subscription to handle failed payments
- **Request**:
  ```json
  {
    "pause_collection": {
      "behavior": "void"
    },
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX",
      "pause_reason": "payment_failure"
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "sub_XXXXXXXXXXXXX",
    "object": "subscription",
    "created": 1640995200,
    "current_period_start": 1640995200,
    "current_period_end": 1643673600,
    "customer": "cus_XXXXXXXXXXXXX",
    "status": "paused",
    "pause_collection": {
      "behavior": "void"
    },
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX",
      "pause_reason": "payment_failure"
    }
  }
  ```
- **Business Use Case**: Handle failed payments and temporary suspensions without losing customer data

### 3.7 Resume Subscription
- **Endpoint**: `POST /subscriptions/{subscription_id}/resume`
- **Purpose**: Reactivate a paused subscription after payment issues are resolved
- **Request**:
  ```json
  {
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX",
      "resume_reason": "payment_updated"
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "sub_XXXXXXXXXXXXX",
    "object": "subscription",
    "created": 1640995200,
    "current_period_start": 1640995200,
    "current_period_end": 1643673600,
    "customer": "cus_XXXXXXXXXXXXX",
    "status": "active",
    "metadata": {
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX",
      "resume_reason": "payment_updated"
    }
  }
  ```
- **Business Use Case**: Reactivate subscriptions after customers update payment methods

## 4. Checkout Session Endpoints

### 4.1 Create Checkout Session
- **Endpoint**: `POST /checkout/sessions`
- **Purpose**: Create a secure payment link for customer signup
- **Request**:
  ```json
  {
    "customer": "cus_XXXXXXXXXXXXX",
    "line_items": [
      {
        "price": "price_XXXXXXXXXXXXX",
        "quantity": 1
      }
    ],
    "mode": "subscription",
    "success_url": "https://your-salesforce-instance.com/apex/PaymentSuccess?session_id={CHECKOUT_SESSION_ID}",
    "cancel_url": "https://your-salesforce-instance.com/apex/PaymentCancel",
    "metadata": {
      "salesforce_contact_id": "003XXXXXXXXXXXXXXX",
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
    },
    "subscription_data": {
      "metadata": {
        "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
      }
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "cs_XXXXXXXXXXXXX",
    "object": "checkout.session",
    "created": 1640995200,
    "customer": "cus_XXXXXXXXXXXXX",
    "line_items": {
      "object": "list",
      "data": [
        {
          "price": {
            "id": "price_XXXXXXXXXXXXX",
            "object": "price",
            "unit_amount": 2999
          },
          "quantity": 1
        }
      ]
    },
    "mode": "subscription",
    "payment_status": "unpaid",
    "status": "open",
    "url": "https://checkout.stripe.com/pay/cs_XXXXXXXXXXXXX",
    "metadata": {
      "salesforce_contact_id": "003XXXXXXXXXXXXXXX",
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Business Use Case**: Secure payment collection for new subscriptions

### 4.2 Retrieve Checkout Session
- **Endpoint**: `GET /checkout/sessions/{session_id}`
- **Purpose**: Get checkout session status and details
- **Request**: No request body (GET request)
- **Response**:
  ```json
  {
    "id": "cs_XXXXXXXXXXXXX",
    "object": "checkout.session",
    "created": 1640995200,
    "customer": "cus_XXXXXXXXXXXXX",
    "line_items": {
      "object": "list",
      "data": [
        {
          "price": {
            "id": "price_XXXXXXXXXXXXX",
            "object": "price",
            "unit_amount": 2999
          },
          "quantity": 1
        }
      ]
    },
    "mode": "subscription",
    "payment_status": "paid",
    "status": "complete",
    "subscription": "sub_XXXXXXXXXXXXX",
    "metadata": {
      "salesforce_contact_id": "003XXXXXXXXXXXXXXX",
      "salesforce_subscription_id": "a0sXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Business Use Case**: Track payment completion status

## 5. Payment Intent Endpoints

### 5.1 Create Payment Intent
- **Endpoint**: `POST /payment_intents`
- **Purpose**: Create a payment intent for one-time payments
- **Request**:
  ```json
  {
    "amount": 2999,
    "currency": "usd",
    "customer": "cus_XXXXXXXXXXXXX",
    "metadata": {
      "salesforce_transaction_id": "a0tXXXXXXXXXXXXXXX"
    },
    "description": "One-time payment for services",
    "payment_method_types": ["card"]
  }
  ```
- **Response**:
  ```json
  {
    "id": "pi_XXXXXXXXXXXXX",
    "object": "payment_intent",
    "amount": 2999,
    "currency": "usd",
    "customer": "cus_XXXXXXXXXXXXX",
    "status": "requires_payment_method",
    "metadata": {
      "salesforce_transaction_id": "a0tXXXXXXXXXXXXXXX"
    },
    "description": "One-time payment for services",
    "payment_method_types": ["card"]
  }
  ```
- **Business Use Case**: One-time payments and manual charges

### 5.2 Retrieve Payment Intent
- **Endpoint**: `GET /payment_intents/{payment_intent_id}`
- **Purpose**: Get payment intent status and details
- **Request**: No request body (GET request)
- **Response**:
  ```json
  {
    "id": "pi_XXXXXXXXXXXXX",
    "object": "payment_intent",
    "amount": 2999,
    "currency": "usd",
    "customer": "cus_XXXXXXXXXXXXX",
    "status": "succeeded",
    "metadata": {
      "salesforce_transaction_id": "a0tXXXXXXXXXXXXXXX"
    },
    "description": "One-time payment for services",
    "payment_method_types": ["card"],
    "charges": {
      "object": "list",
      "data": [
        {
          "id": "ch_XXXXXXXXXXXXX",
          "object": "charge",
          "amount": 2999,
          "status": "succeeded"
        }
      ]
    }
  }
  ```
- **Business Use Case**: Payment status verification

### 5.3 Confirm Payment Intent
- **Endpoint**: `POST /payment_intents/{payment_intent_id}/confirm`
- **Purpose**: Confirm a payment intent with payment method
- **Request**:
  ```json
  {
    "payment_method": "pm_XXXXXXXXXXXXX",
    "return_url": "https://your-salesforce-instance.com/apex/PaymentComplete"
  }
  ```
- **Response**:
  ```json
  {
    "id": "pi_XXXXXXXXXXXXX",
    "object": "payment_intent",
    "amount": 2999,
    "currency": "usd",
    "customer": "cus_XXXXXXXXXXXXX",
    "status": "succeeded",
    "metadata": {
      "salesforce_transaction_id": "a0tXXXXXXXXXXXXXXX"
    },
    "payment_method": "pm_XXXXXXXXXXXXX",
    "charges": {
      "object": "list",
      "data": [
        {
          "id": "ch_XXXXXXXXXXXXX",
          "object": "charge",
          "amount": 2999,
          "status": "succeeded"
        }
      ]
    }
  }
  ```
- **Business Use Case**: Process payments with saved payment methods

### 5.4 Cancel Payment Intent
- **Endpoint**: `POST /payment_intents/{payment_intent_id}/cancel`
- **Purpose**: Cancel a pending payment intent for coaching sessions or other services
- **Request**:
  ```json
  {
    "metadata": {
      "salesforce_transaction_id": "a0tXXXXXXXXXXXXXXX",
      "cancel_reason": "session_cancelled"
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "pi_XXXXXXXXXXXXX",
    "object": "payment_intent",
    "amount": 2999,
    "currency": "usd",
    "customer": "cus_XXXXXXXXXXXXX",
    "status": "canceled",
    "metadata": {
      "salesforce_transaction_id": "a0tXXXXXXXXXXXXXXX",
      "cancel_reason": "session_cancelled"
    },
    "canceled_at": 1640995300
  }
  ```
- **Business Use Case**: Cancel pending coaching session payments when sessions are cancelled

## 6. Invoice Management Endpoints

### 6.1 Create Invoice
- **Endpoint**: `POST /invoices`
- **Purpose**: Create manual invoices for customers
- **Request**:
  ```json
  {
    "customer": "cus_XXXXXXXXXXXXX",
    "collection_method": "send_invoice",
    "metadata": {
      "salesforce_invoice_id": "a0iXXXXXXXXXXXXXXX"
    },
    "description": "Manual invoice for additional services",
    "due_date": 1643673600
  }
  ```
- **Response**:
  ```json
  {
    "id": "in_XXXXXXXXXXXXX",
    "object": "invoice",
    "created": 1640995200,
    "customer": "cus_XXXXXXXXXXXXX",
    "collection_method": "send_invoice",
    "status": "draft",
    "metadata": {
      "salesforce_invoice_id": "a0iXXXXXXXXXXXXXXX"
    },
    "description": "Manual invoice for additional services",
    "due_date": 1643673600,
    "amount_due": 0,
    "amount_paid": 0
  }
  ```
- **Business Use Case**: Manual billing and invoice generation

### 6.2 Retrieve Invoice
- **Endpoint**: `GET /invoices/{invoice_id}`
- **Purpose**: Get invoice details and status
- **Request**: No request body (GET request)
- **Response**:
  ```json
  {
    "id": "in_XXXXXXXXXXXXX",
    "object": "invoice",
    "created": 1640995200,
    "customer": "cus_XXXXXXXXXXXXX",
    "collection_method": "send_invoice",
    "status": "paid",
    "metadata": {
      "salesforce_invoice_id": "a0iXXXXXXXXXXXXXXX"
    },
    "description": "Manual invoice for additional services",
    "due_date": 1643673600,
    "amount_due": 2999,
    "amount_paid": 2999,
    "lines": {
      "object": "list",
      "data": [
        {
          "id": "il_XXXXXXXXXXXXX",
          "object": "line_item",
          "amount": 2999,
          "description": "Additional services"
        }
      ]
    }
  }
  ```
- **Business Use Case**: Invoice status tracking and customer service

### 6.3 List Invoices
- **Endpoint**: `GET /invoices`
- **Purpose**: Retrieve invoices for reporting and reconciliation
- **Request**: Query parameters
  ```
  ?customer=cus_XXXXXXXXXXXXX&status=paid&limit=100
  ```
- **Response**:
  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "in_XXXXXXXXXXXXX",
        "object": "invoice",
        "created": 1640995200,
        "customer": "cus_XXXXXXXXXXXXX",
        "status": "paid",
        "metadata": {
          "salesforce_invoice_id": "a0iXXXXXXXXXXXXXXX"
        },
        "amount_due": 2999,
        "amount_paid": 2999
      }
    ],
    "has_more": false,
    "url": "/v1/invoices"
  }
  ```
- **Business Use Case**: Financial reporting and customer billing history

## 7. Payment Method Management Endpoints

### 7.1 Attach Payment Method to Customer
- **Endpoint**: `POST /payment_methods/{payment_method_id}/attach`
- **Purpose**: Attach a payment method to a customer for future use
- **Request**:
  ```json
  {
    "customer": "cus_XXXXXXXXXXXXX"
  }
  ```
- **Response**:
  ```json
  {
    "id": "pm_XXXXXXXXXXXXX",
    "object": "payment_method",
    "customer": "cus_XXXXXXXXXXXXX",
    "type": "card",
    "card": {
      "brand": "visa",
      "exp_month": 12,
      "exp_year": 2025,
      "last4": "4242"
    }
  }
  ```
- **Business Use Case**: Save customer payment methods for recurring billing

### 7.2 Detach Payment Method
- **Endpoint**: `POST /payment_methods/{payment_method_id}/detach`
- **Purpose**: Remove a payment method from a customer
- **Request**: No request body required
- **Response**:
  ```json
  {
    "id": "pm_XXXXXXXXXXXXX",
    "object": "payment_method",
    "customer": null,
    "type": "card",
    "card": {
      "brand": "visa",
      "exp_month": 12,
      "exp_year": 2025,
      "last4": "4242"
    }
  }
  ```
- **Business Use Case**: Customer payment method updates

### 7.3 List Customer Payment Methods
- **Endpoint**: `GET /customers/{customer_id}/payment_methods`
- **Purpose**: Retrieve all payment methods for a customer
- **Request**: Query parameters
  ```
  ?type=card
  ```
- **Response**:
  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "pm_XXXXXXXXXXXXX",
        "object": "payment_method",
        "customer": "cus_XXXXXXXXXXXXX",
        "type": "card",
        "card": {
          "brand": "visa",
          "exp_month": 12,
          "exp_year": 2025,
          "last4": "4242"
        }
      }
    ],
    "has_more": false,
    "url": "/v1/customers/cus_XXXXXXXXXXXXX/payment_methods"
  }
  ```
- **Business Use Case**: Customer service and payment method management

## 8. Refund Management Endpoints

### 8.1 Create Refund
- **Endpoint**: `POST /refunds`
- **Purpose**: Process refunds for payments
- **Request**:
  ```json
  {
    "payment_intent": "pi_XXXXXXXXXXXXX",
    "amount": 2999,
    "reason": "requested_by_customer",
    "metadata": {
      "salesforce_refund_id": "a0rXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Response**:
  ```json
  {
    "id": "re_XXXXXXXXXXXXX",
    "object": "refund",
    "amount": 2999,
    "currency": "usd",
    "payment_intent": "pi_XXXXXXXXXXXXX",
    "reason": "requested_by_customer",
    "status": "succeeded",
    "metadata": {
      "salesforce_refund_id": "a0rXXXXXXXXXXXXXXX"
    }
  }
  ```
- **Business Use Case**: Customer refund requests and error corrections

### 8.2 Retrieve Refund
- **Endpoint**: `GET /refunds/{refund_id}`
- **Purpose**: Get refund status and details
- **Request**: No request body (GET request)
- **Response**:
  ```json
  {
    "id": "re_XXXXXXXXXXXXX",
    "object": "refund",
    "amount": 2999,
    "currency": "usd",
    "payment_intent": "pi_XXXXXXXXXXXXX",
    "reason": "requested_by_customer",
    "status": "succeeded",
    "metadata": {
      "salesforce_refund_id": "a0rXXXXXXXXXXXXXXX"
    },
    "created": 1640995200
  }
  ```
- **Business Use Case**: Refund status tracking



## 10. Error Handling & Rate Limiting

### Important Considerations:
- **Rate Limits**: Stripe enforces rate limits (100 requests per second for most endpoints)
- **Idempotency**: Use idempotency keys for retry operations
- **Error Codes**: Handle common error codes (400, 401, 402, 404, 429, 500)
- **Retry Logic**: Implement exponential backoff for failed requests

### Common Error Scenarios:
- **400 Bad Request**: Invalid parameters or missing required fields
- **401 Unauthorized**: Invalid API key
- **402 Payment Required**: Payment processing errors
- **404 Not Found**: Resource doesn't exist
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Stripe server errors

## Implementation Priority

### Phase 1 (Week 2 - Core Integration):
1. Customer creation and updates
2. Basic subscription management
3. Checkout session creation

### Phase 2 (Week 3 - Advanced Features):
1. Payment intent management
2. Invoice handling
3. Refund processing
4. Payment method management

### Phase 3 (Week 4 - Production Readiness):
1. Webhook endpoint management
2. Bulk operations
3. Error handling optimization

## Security Best Practices

1. **API Key Management**: Store Stripe secret keys in Named Credentials
2. **HTTPS Only**: All API calls must use HTTPS
3. **Input Validation**: Validate all data before sending to Stripe
4. **Error Logging**: Log errors without exposing sensitive data
5. **Idempotency**: Use idempotency keys to prevent duplicate operations 