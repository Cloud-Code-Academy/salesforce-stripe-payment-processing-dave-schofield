# Cloud Fitness Academy - Salesforce Data Model

## Overview
This document defines the complete data model for the Cloud Fitness Academy Salesforce-Stripe integration, including all custom objects, fields, and relationships. **Salesforce is the System of Record** - all business data is created and managed in Salesforce, with Stripe serving as the payment processing layer.

## System of Record Strategy

### **Data Flow Direction**
- **Salesforce → Stripe**: Products, Prices, Customers, Subscriptions (business data)
- **Stripe → Salesforce**: Payment events, invoice status, subscription status (payment processing data)

### **Sync Status Tracking**
All objects that sync to Stripe include:
- `Sync_Status__c`: Tracks sync state (Pending, In Sync, Error)
- `Error_Message__c`: Stores error details for failed syncs
- External ID fields: Store Stripe IDs after successful sync

## Standard Objects

### Contact
**Purpose**: Primary customer record with fitness-specific fields and Stripe integration
```apex
Fields:
// Core Customer Information
- *FirstName (Text(40)) // Standard Salesforce field
- *LastName (Text(80)) // Standard Salesforce field
- *Email (Email) // Standard Salesforce field
- Phone (Phone) // Standard Salesforce field
- Mobile (Phone) // Standard Salesforce field
- MailingAddress (Address) // Standard Salesforce field
- OtherAddress (Address) // Standard Salesforce field
- Birthdate (Date) // Standard Salesforce field
- Gender (Picklist: Male, Female, Other, Prefer not to say) // Standard Salesforce field

// Fitness Business Fields
- Fitness_Goals__c (Picklist: Weight Loss, Muscle Gain, General Fitness, Sport Specific)
- Sports_Activity_Interests__c (Text(255))
- Experience_Level__c (Picklist: Beginner, Intermediate, Advanced)
- Health_Conditions__c (Long Text Area)
- Emergency_Contact_Name__c (Text(100))
- Emergency_Contact_Phone__c (Phone)
- Coach__c (Lookup to User)
- Lead_Source__c (Picklist: Website, Referral, Social Media, Email Campaign, Phone Call, Walk-in, Other)

// Stripe Integration Fields
// Stripe sync controlled by presence of Stripe_Customer_ID__c
- Stripe_Customer_ID__c (Text(255), External ID) // Populated after Stripe sync
- Stripe_Sync_Status__c (Picklist: Pending, In Sync, Error) // System of Record
- Stripe_Error_Message__c (Long Text Area) // System of Record
- Last_Sync_Date__c (DateTime)

// Payment & Subscription Fields
- Subscription_Status__c (Picklist: Active, Inactive, Suspended, Cancelled)
- Platform_Access_Level__c (Picklist: None, Single Plan, All Plans, Premium)
- Last_Payment_Date__c (Date)
- Next_Billing_Date__c (Date)
- Total_Revenue__c (Currency)
- Failed_Payment_Count__c (Number)
- Stripe_Default_Payment_Method__c (Text(255)) // Stripe payment method ID
```

### User (for Coaches)
**Purpose**: Coach management and revenue tracking
```apex
Fields:
- *FirstName (Text(40)) // Standard Salesforce field
- *LastName (Text(80)) // Standard Salesforce field
- *Email (Email) // Standard Salesforce field
- Is_Coach__c (Checkbox)
- Coach_Specialization__c (Picklist: Strength, Weight Loss, Running, Nutrition)
- Hourly_Rate__c (Currency)
- Active_Sessions__c (Number)
- Total_Revenue__c (Currency)
```

## Custom Objects

### Stripe_Product__c (NEW)
**Purpose**: Store Stripe product information that subscriptions reference
```apex
Fields:
- *Name (Text(255))
- Stripe_Product_ID__c (Text(255), External ID) // Populated after Stripe sync
- Description__c (Long Text Area)
- Product_Image_URL__c (URL) // URL to product image
- Is_Active__c (Checkbox, Default: true)
```

### Stripe_Price__c (RENAMED from Stripe_Pricing_Plan__c)
**Purpose**: Store Stripe price information that subscription items reference
```apex
Fields:
- *Name (Text(255))
- Stripe_Price_ID__c (Text(255), External ID) // Populated after Stripe sync
- *Stripe_Product__c (Lookup to Stripe_Product__c) // REQUIRED RELATIONSHIP
- *Amount__c (Currency)
- *Currency__c (Text(3), Default: USD)
- *Billing_Interval__c (Picklist: Month, Year, Week, Day)
- Billing_Interval_Count__c (Number, Default: 1) // e.g., 3 for "every 3 months"
- Is_Active__c (Checkbox, Default: true)
- *Type__c (Picklist: One-time, Recurring)
- Unit_Amount__c (Number) // Stripe stores in cents
- *Billing_Scheme__c (Picklist: Per Unit, Tiered, Default: Per Unit)
- Lookup_Key__c (Text(200)) // Optional, for dynamic price retrieval
- *Tax_Behavior__c (Picklist: Exclusive, Inclusive, Unspecified, Default: Exclusive)
- Description__c (Long Text Area)
- Features__c (Long Text Area)
```

### Stripe_Subscription__c (ENHANCED)
**Purpose**: Stripe subscription record with enhanced fields
```apex
Fields:
- *Contact__c (Master-Detail to Contact) // REQUIRED RELATIONSHIP
- *Stripe_Product__c (Lookup to Stripe_Product__c) // REQUIRED RELATIONSHIP
- *Stripe_Price__c (Lookup to Stripe_Price__c) // REQUIRED RELATIONSHIP
- Stripe_Subscription_ID__c (Text(255), External ID) // Populated after Stripe sync
- *Product_Plan_Name__c (Picklist: Monthly Single, Monthly All, Annual All)
- *Status__c (Picklist: Pending, Active, Inactive, Past Due, Cancelled, Unpaid) // Added Pending
- *Amount__c (Currency)
- *Currency__c (Text(3))
- Current_Period_Start__c (DateTime) // Changed from Date
- Current_Period_End__c (DateTime) // Changed from Date
- Trial_Start__c (DateTime) // NEW
- Trial_End__c (DateTime) // NEW
- Cancel_At_Period_End__c (Checkbox) // NEW
- Canceled_At__c (DateTime) // NEW
- Billing_Cycle_Anchor__c (DateTime) // NEW
- Collection_Method__c (Picklist: Charge Automatically, Send Invoice) // NEW
- Days_Until_Due__c (Number) // NEW
- Default_Payment_Method__c (Text(255)) // NEW
- Default_Tax_Rates__c (Long Text Area) // NEW - JSON array
- Pause_Collection__c (Checkbox) // NEW
- Pause_Collection_Behavior__c (Picklist: Keep As Draft, Mark Uncollectible, Void) // NEW
- Stripe_Checkout_Session_ID__c (Text(255))
- Checkout_URL__c (URL)
```

### Stripe_Subscription_Item__c (NEW)
**Purpose**: Track individual items within subscriptions (for complex subscriptions with multiple products)
```apex
Fields:
- *Stripe_Subscription__c (Master-Detail to Stripe_Subscription__c) // REQUIRED RELATIONSHIP
- *Stripe_Price__c (Lookup to Stripe_Price__c) // REQUIRED RELATIONSHIP
- Stripe_Subscription_Item_ID__c (Text(255), External ID) // Populated after Stripe sync
- *Quantity__c (Number, Default: 1)
- *Amount__c (Currency)
- *Currency__c (Text(3))
- *Status__c (Picklist: Active, Inactive, Cancelled)
```

### Stripe_Discount__c (NEW)
**Purpose**: Track discounts applied to subscriptions
```apex
Fields:
- *Stripe_Subscription__c (Master-Detail to Stripe_Subscription__c) // REQUIRED RELATIONSHIP
- *Stripe_Coupon_ID__c (Text(255))
- *Discount_Type__c (Picklist: Percentage, Fixed Amount)
- Amount_Off__c (Currency)
- Percent_Off__c (Percent)
- *Currency__c (Text(3))
- *Duration__c (Picklist: Once, Forever, Repeating)
- Duration_In_Months__c (Number)
- Is_Active__c (Checkbox, Default: true)
```

### Stripe_Invoice__c (NEW)
**Purpose**: Track invoices generated by Stripe for subscriptions
```apex
Fields:
- Stripe_Invoice_ID__c (Text(255), External ID) // Populated after Stripe sync
- *Contact__c (Lookup to Contact) // REQUIRED RELATIONSHIP
- Stripe_Subscription__c (Lookup to Stripe_Subscription__c)
- *Amount_Due__c (Currency)
- Amount_Paid__c (Currency)
- *Currency__c (Text(3))
- *Status__c (Picklist: Draft, Open, Paid, Void, Uncollectible)
- Due_Date__c (Date)
- Period_Start__c (DateTime)
- Period_End__c (DateTime)
- Hosted_Invoice_URL__c (URL)
- Invoice_PDF_URL__c (URL)
```

### Stripe_Payment_Method__c (NEW)
**Purpose**: Store customer payment methods for future use
```apex
Fields:
- *Contact__c (Master-Detail to Contact) // REQUIRED RELATIONSHIP
- Stripe_Payment_Method_ID__c (Text(255), External ID) // Populated after Stripe sync
- *Type__c (Picklist: Card, Bank Account, SEPA Debit, etc.)
- Card_Brand__c (Text(50)) // Visa, Mastercard, etc.
- Card_Last4__c (Text(4))
- Card_Exp_Month__c (Number)
- Card_Exp_Year__c (Number)
- Is_Default__c (Checkbox)
- Is_Active__c (Checkbox, Default: true)
```

### Payment_Transaction__c (ENHANCED)
**Purpose**: Track all payment transactions with enhanced fields
```apex
Fields:
- *Contact__c (Master-Detail to Contact) // REQUIRED RELATIONSHIP
- Stripe_Subscription__c (Lookup to Stripe_Subscription__c)
- Stripe_Invoice__c (Lookup to Stripe_Invoice__c) // NEW
- Payment_Method__c (Lookup to Stripe_Payment_Method__c) // NEW
- Stripe_Payment_Intent_ID__c (Text(255), External ID) // Populated after Stripe sync
- *Amount__c (Currency)
- *Currency__c (Text(3))
- *Status__c (Picklist: Succeeded, Failed, Pending, Cancelled)
- Payment_Method_Type__c (Text(50))
- *Transaction_Date__c (DateTime)
- Description__c (Text(255))
- Failure_Reason__c (Text(255))
- Refund_Amount__c (Currency)
- Refund_Status__c (Picklist: None, Partial, Full)
- Receipt_URL__c (URL) // NEW
- Application_Fee_Amount__c (Currency) // NEW
- Transfer_Data__c (Long Text Area) // NEW - JSON for transfer details
```

### CFA_Coaching_Session__c
**Purpose**: Track coaching sessions with payment integration
```apex
Fields:
- *Contact__c (Master-Detail to Contact)
- *Coach__c (Lookup to User)
- *Session_Date__c (DateTime)
- *Status__c (Picklist: Scheduled, Completed, Cancelled, No-Show)
- *Amount__c (Currency)
- Stripe_Payment_Intent_ID__c (Text(255))
- Payment_Status__c (Picklist: Pending, Paid, Failed, Refunded)
- Session_Notes__c (Long Text Area)
- *Duration_Minutes__c (Number)
- *Session_Type__c (Picklist: Initial Consultation, Follow-up, Progress Review)
- Created_Date__c (DateTime)
```

### CFA_Fitness_Product__c
**Purpose**: Physical product catalog with Stripe integration
```apex
Fields:
- *Name (Text(255))
- Description__c (Long Text Area)
- *Base_Price__c (Currency)
- *Category__c (Picklist: Equipment, Apparel, Accessories, Supplements)
- *Inventory_Quantity__c (Number)
- Stripe_Product_ID__c (Text(255), External ID) // Populated after Stripe sync
- Is_Active__c (Checkbox, Default: true)
- Annual_Subscriber_Discount__c (Percent)
- *SKU__c (Text(50))
- Weight__c (Number)
- Dimensions__c (Text(100))
- Created_Date__c (DateTime)
```

## Data Model Relationships

```
Contact (1)
├── Stripe_Subscription__c (1:Many)
│   ├── Stripe_Subscription_Item__c (1:Many)
│   └── Stripe_Discount__c (1:Many)
├── Stripe_Payment_Method__c (1:Many)
├── Payment_Transaction__c (1:Many)
├── Stripe_Invoice__c (1:Many)
├── CFA_Coaching_Session__c (1:Many)
│   └── Coach__c (Lookup to User)
└── Coach__c (Lookup to User)

User (1)
├── CFA_Coaching_Session__c (Lookup)
└── Contact (Lookup - Coach__c)

Stripe_Product__c (1)
├── Stripe_Price__c (1:Many)
│   └── Stripe_Subscription_Item__c (Lookup)
└── CFA_Fitness_Product__c (Lookup - Stripe_Product_ID__c)
```

Stripe_Subscription__c (1)
├── Stripe_Product__c (Lookup)
├── Stripe_Price__c (Lookup)
├── Stripe_Subscription_Item__c (1:Many)
├── Stripe_Discount__c (1:Many)
└── Stripe_Invoice__c (1:Many)

Payment_Transaction__c (1)
├── Stripe_Subscription__c (Lookup)
├── Stripe_Invoice__c (Lookup)
└── Payment_Method__c (Lookup)
```

## Key Relationships Explained

### **Customer Hierarchy**
- **Contact** is the primary customer record with Stripe integration fields
- All Stripe-related objects hang off the Contact directly
- No separate customer object needed - Contact serves as both Salesforce and Stripe customer

### **Product Hierarchy**
- **Stripe_Product__c** represents what you're selling
- **Stripe_Price__c** represents how much it costs and billing details
- **Stripe_Subscription__c** represents the actual subscription for a customer

### **Subscription Components**
- **Stripe_Subscription__c** can have multiple **Stripe_Subscription_Item__c** (for complex subscriptions)
- **Stripe_Subscription__c** can have multiple **Stripe_Discount__c** (for coupons/promotions)
- **Stripe_Subscription__c** generates multiple **Stripe_Invoice__c** (one per billing cycle)

### **Payment Flow**
- **Payment_Transaction__c** records individual payments
- **Stripe_Payment_Method__c** stores reusable payment methods
- **Stripe_Invoice__c** tracks billing cycles and amounts

## Creation Order & Dependencies (System of Record)

### **Phase 1: Foundation Objects**
1. **Stripe_Product__c** (Create first - no dependencies)
   - Admin creates product in Salesforce
   - Trigger calls Stripe API to create product
   - Stripe Product ID stored in `Stripe_Product_ID__c`

2. **Stripe_Price__c** (Depends on Stripe_Product__c)
   - Admin creates price in Salesforce
   - Trigger calls Stripe API to create price
   - Stripe Price ID stored in `Stripe_Price_ID__c`

3. **Contact** (Enhanced with Stripe fields)
   - Sales rep creates contact in Salesforce
   - Presence of `Stripe_Customer_ID__c` controls Stripe sync
   - Trigger calls Stripe API to create customer
   - Stripe Customer ID stored in `Contact.Stripe_Customer_ID__c`

### **Phase 2: Core Integration**
4. **Stripe_Subscription__c** (Depends on Contact, Stripe_Product__c, Stripe_Price__c)
   - Sales rep creates subscription in Salesforce
   - Process Builder calls Stripe API to create subscription
   - Stripe Subscription ID stored in `Stripe_Subscription_ID__c`

5. **Payment_Transaction__c** (Depends on Contact)
   - Created via webhooks from Stripe payment events
   - Tracks all payment activity

### **Phase 3: Advanced Features**
6. **Stripe_Subscription_Item__c** (Depends on Stripe_Subscription__c, Stripe_Price__c)
   - Created automatically when subscription is created
   - Links subscription to specific prices

7. **Stripe_Discount__c** (Depends on Stripe_Subscription__c)
   - Created when discounts are applied to subscriptions

8. **Stripe_Invoice__c** (Depends on Contact, Stripe_Subscription__c)
   - Created via webhooks from Stripe invoice events

## Sync Management (System of Record)

### **Salesforce → Stripe Sync**
- **Products**: Created in Salesforce, synced to Stripe via triggers
- **Prices**: Created in Salesforce, synced to Stripe via triggers  
- **Customers**: Created in Salesforce (Contact), synced to Stripe via Contact triggers
- **Subscriptions**: Created in Salesforce, synced to Stripe via Process Builder

### **Stripe → Salesforce Sync**
- **Payment Events**: Webhooks create Payment_Transaction__c records
- **Invoice Events**: Webhooks create Stripe_Invoice__c records
- **Subscription Status**: Webhooks update Stripe_Subscription__c status
- **Customer Updates**: Webhooks update Contact records

### **Sync Status Tracking**
All objects that sync to Stripe include:
- `Sync_Status__c`: Pending, In Sync, Error
- `Error_Message__c`: Detailed error information
- External ID fields: Store Stripe IDs after successful sync

### **Error Handling**
- Failed syncs remain in "Pending" or "Error" status
- Manual retry buttons available in Salesforce UI
- Bulk sync tools for data recovery
- Automated alerts for failed operations

## Benefits of This Data Model

1. **Complete Stripe Integration**: Covers all major Stripe objects (products, prices, subscription items, discounts, invoices)
2. **Flexible Pricing**: Support for complex pricing models with multiple items per subscription
3. **Discount Management**: Track coupons and promotional discounts
4. **Invoice Tracking**: Complete invoice history and PDF access
5. **Payment Method Management**: Store and manage customer payment methods
6. **Better Reporting**: More granular data for analytics and reporting
7. **Coach Integration**: Seamless integration with coaching services
8. **Product Catalog**: Physical product management with Stripe sync
9. **System of Record**: Salesforce controls all business data and processes
10. **Sync Management**: Clear tracking of data synchronization status 