# Customer Sync Analysis: Contact Fields & Stripe Integration

## Overview

This document analyzes the Contact fields needed for Sales Representatives based on the Cloud Fitness Academy business requirements, and provides recommendations for which fields should be synced to Stripe for payment processing.

## Sales Representative Needs Analysis

Based on the technical requirements document, Sales Representatives need to:

- Create customer records in Salesforce that automatically appear in Stripe
- Update customer information and see changes reflected in both systems
- View complete customer payment history from Salesforce
- Set up new subscriptions with different pricing plans

## Common Contact Fields for Sales Representatives

### **Core Customer Information**
```apex
// Standard Salesforce Contact Fields
FirstName, LastName, Email, Phone, Mobile
AccountId (relationship to Account)
MailingAddress (Street, City, State, PostalCode, Country)
OtherAddress (if different from mailing)
Birthdate
Gender
Lead_Source__c (Picklist: Website, Referral, Social Media, etc.)
```

### **Business-Specific Fields for Cloud Fitness Academy**
```apex
// Fitness-Related Fields
Fitness Goals section
    Picklists: Weight Loss, Muscle Gain, General Fitness, Sport Specific
Sports/Activity Interests (Text)
Experience_Level__c (Picklist: Beginner, Intermediate, Advanced)
Health_Conditions__c (Text Area)
Emergency_Contact_Name__c, Emergency_Contact_Phone__c
Coach__c (Lookup to User/Contact for assigned coach)
```

### **Stripe Integration Fields**
```apex
// Stripe Sync Fields
  // Stripe sync controlled by presence of Stripe_Customer_ID__c
  Stripe_Customer_ID__c (Text - stores Stripe customer ID)
  Stripe_Sync_Status__c (Picklist: Pending, In Sync, Error)
  Stripe_Error_Message__c (Text Area)
  Last_Sync_Date__c (DateTime)
```

## Fields Commonly Synced to Stripe

### **Primary Sync Fields (Always)**
```apex
// These fields are typically synced to Stripe for all customers
Email (Stripe: email)
FirstName + LastName (Stripe: name)
Phone (Stripe: phone)
MailingAddress (Stripe: address)
```

### **Secondary Sync Fields (Conditional)**
```apex
// These fields are synced based on business rules
Metadata fields (Stripe: metadata):
- salesforce_contact_id
- fitness_goals
- experience_level
- assigned_coach
- lead_source
- sports_interests
```

## Recommended Field Configuration

### **For Cloud Fitness Academy Use Case:**

#### **Essential Fields to Add:**
```apex
// Fitness Business Fields
Fitness_Goals__c (Picklist)
Sports_Activity_Interests__c (Text)
Experience_Level__c (Picklist)
Health_Conditions__c (Text Area)
Emergency_Contact_Name__c (Text)
Emergency_Contact_Phone__c (Phone)
Coach__c (Lookup to User)
Lead_Source__c (Picklist)

// Stripe Integration Fields
// Stripe sync controlled by presence of Stripe_Customer_ID__c
Stripe_Customer_ID__c (Text)
Stripe_Sync_Status__c (Picklist)
Stripe_Error_Message__c (Text Area)
Last_Sync_Date__c (DateTime)
```

#### **Stripe Sync Mapping:**
```apex
// Simple fields (direct mapping)
Contact.Email → Stripe Customer.email
Contact.FirstName + ' ' + Contact.LastName → Stripe Customer.name
Contact.Phone → Stripe Customer.phone
Contact.MailingAddress → Stripe Customer.address

// Metadata fields (for business context)
Contact.Id → Stripe Customer.metadata.salesforce_contact_id
Contact.Fitness_Goals__c → Stripe Customer.metadata.fitness_goals
Contact.Sports_Activity_Interests__c → Stripe Customer.metadata.sports_interests
Contact.Experience_Level__c → Stripe Customer.metadata.experience_level
Contact.Lead_Source__c → Stripe Customer.metadata.lead_source
Contact.Coach__c → Stripe Customer.metadata.assigned_coach
```

## Data Flow Architecture

### **Salesforce → Stripe (Customer Creation)**
```
Contact Created/Updated
    ↓
Check if Stripe_Customer_ID__c is blank
    ↓
Map Contact fields to Stripe Customer
    ↓
Call Stripe API
    ↓
Update Contact with Stripe Customer ID
    ↓
Set Sync Status to "In Sync"
```

### **Stripe → Salesforce (Webhook Updates)**
```
Stripe Event Received
    ↓
Verify Webhook Signature
    ↓
Process Event Type
    ↓
Update Salesforce Records
    ↓
Log Sync Activity
```

## Field-Level Security Considerations

### **Sales Representative Access**
- **Read/Write**: Core customer information, sales fields
- **Read Only**: Stripe integration fields (prevent manual editing)
- **No Access**: Sensitive health information, internal notes

### **System Administrator Access**
- **Full Access**: All fields for troubleshooting and maintenance
- **Sync Control**: Ability to manually trigger sync operations
- **Error Resolution**: Access to sync error messages and logs