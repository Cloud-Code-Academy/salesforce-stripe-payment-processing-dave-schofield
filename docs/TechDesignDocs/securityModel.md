# Cloud Fitness Academy - Security Model

## Overview
This document defines the security model for Cloud Fitness Academy, following Salesforce best practices of **zero permissions on profiles** and **all access granted via permission sets**. This approach provides flexibility, scalability, and better security management.

## Security Principles

### **1. Zero Profile Permissions**
- **Base Profile**: "Cloud Fitness Academy - Standard User" with minimal standard Salesforce access
- **No custom object permissions** on profiles
- **No custom field permissions** on profiles
- All access granted through permission sets

### **2. Permission Set Strategy**
- **Granular permission sets** for specific functional areas
- **Mix and match approach** for different user roles
- **Least privilege principle** - users only get what they need
- **Read-only access** to sensitive integration fields

### **3. Object Access Control**
- **Stripe integration fields**: Read-only for most users
- **Financial data**: Restricted access
- **Sync status fields**: Admin access only for troubleshooting

## Comprehensive Security Model (Production)

### **Base Profile: "Cloud Fitness Academy - Standard User"**
```apex
// Minimal access for all users
- Read access to Contact (basic fields only)
- Read access to User (for coach assignments)
- No access to custom objects by default
- No access to Stripe objects by default
```

### **Permission Set 1: "Cloud Fitness Academy - Contact Management"**
```apex
// For Sales Representatives and Customer Service
Objects:
- Contact: Read, Create, Edit, Delete
- User: Read (for coach lookups)

Fields (Contact):
- All standard fields: Read/Edit
- All fitness business fields: Read/Edit
- Stripe integration fields: Read Only (prevent manual editing)
- Payment fields: Read Only (financial data)

Tabs:
- Contacts
- Users (for coach assignments)
```

### **Permission Set 2: "Cloud Fitness Academy - Stripe Integration Admin"**
```apex
// For System Administrators and Finance Team
Objects:
- Stripe_Product__c: Read, Create, Edit, Delete
- Stripe_Price__c: Read, Create, Edit, Delete
- Stripe_Subscription__c: Read, Create, Edit, Delete
- Stripe_Subscription_Item__c: Read, Create, Edit, Delete
- Stripe_Discount__c: Read, Create, Edit, Delete
- Stripe_Invoice__c: Read, Create, Edit, Delete
- Stripe_Payment_Method__c: Read, Create, Edit, Delete
- Payment_Transaction__c: Read, Create, Edit, Delete

Fields:
- All fields: Read/Edit
- Sync status fields: Read/Edit (for troubleshooting)

Tabs:
- All Stripe-related tabs
- Payment Transactions
```

### **Permission Set 3: "Cloud Fitness Academy - Coach"**
```apex
// For Fitness Coaches
Objects:
- Contact: Read, Edit (limited fields)
- CFA_Coaching_Session__c: Read, Create, Edit, Delete
- User: Read (for coach assignments)

Fields (Contact):
- Core customer info: Read/Edit
- Fitness business fields: Read/Edit
- Stripe integration fields: Read Only
- Payment fields: Read Only

Fields (CFA_Coaching_Session__c):
- All fields: Read/Edit

Tabs:
- Contacts
- Coaching Sessions
- Users
```

### **Permission Set 4: "Cloud Fitness Academy - Product Management"**
```apex
// For Product Managers and Inventory
Objects:
- CFA_Fitness_Product__c: Read, Create, Edit, Delete
- Stripe_Product__c: Read Only
- Stripe_Price__c: Read Only

Fields:
- All CFA_Fitness_Product__c fields: Read/Edit
- Stripe sync fields: Read Only

Tabs:
- Fitness Products
- Stripe Products (Read Only)
- Stripe Prices (Read Only)
```

### **Permission Set 5: "Cloud Fitness Academy - Finance"**
```apex
// For Finance and Accounting Team
Objects:
- Payment_Transaction__c: Read, Create, Edit
- Stripe_Invoice__c: Read, Create, Edit
- Stripe_Subscription__c: Read Only
- Contact: Read (payment-related fields only)

Fields:
- All payment and invoice fields: Read/Edit
- Financial fields on Contact: Read Only
- Stripe sync fields: Read Only

Tabs:
- Payment Transactions
- Stripe Invoices
- Stripe Subscriptions (Read Only)
- Contacts (Read Only)
```

## Simplified Security Model (Project Scope)

For the current project implementation, we'll use a simplified 4-permission set model:

### **Permission Set 1: "Cloud Fitness Academy - Contact Access"**
```apex
// For Sales Representatives and Customer Service
Objects:
- Contact: Read, Create, Edit, Delete
- User: Read (for coach lookups)

Fields (Contact):
- All standard fields: Read/Edit
- All fitness business fields: Read/Edit
- Stripe integration fields: Read Only
- Payment fields: Read Only

Tabs:
- Contacts
- Users
```

### **Permission Set 2: "Cloud Fitness Academy - User Management"**
```apex
// For System Administrators and HR
Objects:
- User: Read, Create, Edit, Delete

Fields:
- All User fields: Read/Edit
- Coach-specific fields: Read/Edit

Tabs:
- Users
```

### **Permission Set 3: "Cloud Fitness Academy - CFA Objects"**
```apex
// For Coaches and Product Managers
Objects:
- CFA_Coaching_Session__c: Read, Create, Edit, Delete
- CFA_Fitness_Product__c: Read, Create, Edit, Delete

Fields:
- All CFA object fields: Read/Edit

Tabs:
- Coaching Sessions
- Fitness Products
```

### **Permission Set 4: "Cloud Fitness Academy - Stripe Objects"**
```apex
// For System Administrators and Finance
Objects:
- Stripe_Product__c: Read, Create, Edit, Delete
- Stripe_Price__c: Read, Create, Edit, Delete
- Stripe_Subscription__c: Read, Create, Edit, Delete
- Stripe_Subscription_Item__c: Read, Create, Edit, Delete
- Stripe_Discount__c: Read, Create, Edit, Delete
- Stripe_Invoice__c: Read, Create, Edit, Delete
- Stripe_Payment_Method__c: Read, Create, Edit, Delete
- Payment_Transaction__c: Read, Create, Edit, Delete

Fields:
- All Stripe object fields: Read/Edit

Tabs:
- All Stripe-related tabs
- Payment Transactions
```

## User Role Assignments (Simplified Model)

### **Sales Representative**
```apex
Base Profile: Cloud Fitness Academy - Standard User
+ Permission Set: Cloud Fitness Academy - Contact Access
```

### **Fitness Coach**
```apex
Base Profile: Cloud Fitness Academy - Standard User
+ Permission Set: Cloud Fitness Academy - Contact Access
+ Permission Set: Cloud Fitness Academy - CFA Objects
```

### **System Administrator**
```apex
Base Profile: Cloud Fitness Academy - Standard User
+ Permission Set: Cloud Fitness Academy - Contact Access
+ Permission Set: Cloud Fitness Academy - User Management
+ Permission Set: Cloud Fitness Academy - CFA Objects
+ Permission Set: Cloud Fitness Academy - Stripe Objects
```

### **Product Manager**
```apex
Base Profile: Cloud Fitness Academy - Standard User
+ Permission Set: Cloud Fitness Academy - CFA Objects
```

### **Finance Team**
```apex
Base Profile: Cloud Fitness Academy - Standard User
+ Permission Set: Cloud Fitness Academy - Stripe Objects
```

## Implementation Strategy

### **Phase 1: Foundation**
1. Create base profile with minimal permissions
2. Create simplified permission sets
3. Assign to test users
4. Validate access and functionality

### **Phase 2: Granular (Future)**
1. Create detailed permission sets
2. Migrate users to granular model
3. Implement field-level security
4. Add custom permissions as needed

## Security Best Practices

### **1. Field-Level Security**
- **Stripe integration fields**: Read-only for non-admin users
- **Financial data**: Restricted access
- **Sync status fields**: Admin access only

### **2. Object Permissions**
- **Contact**: Most users need read/edit
- **Stripe objects**: Admin and finance only
- **CFA objects**: Coaches and product managers

### **3. Tab Access**
- **Standard tabs**: Based on object permissions
- **Custom tabs**: Explicitly assigned via permission sets
- **Hidden tabs**: Not assigned to permission sets

### **4. Record-Level Security**
- **Sharing rules**: Based on role hierarchy
- **Owner-based sharing**: Default Salesforce behavior
- **Territory management**: If using territories

## Monitoring and Maintenance

### **Regular Reviews**
- **Quarterly**: Review permission set assignments
- **Annually**: Audit access patterns
- **On role changes**: Immediate permission updates

### **Access Monitoring**
- **Login history**: Track user access
- **Field usage**: Monitor field access patterns
- **Object usage**: Track object access frequency

### **Security Alerts**
- **Failed login attempts**: Monitor for security issues
- **Unusual access patterns**: Flag potential security concerns
- **Permission changes**: Log all permission modifications

## Conclusion

This security model provides a solid foundation for Cloud Fitness Academy while maintaining flexibility for future growth. The simplified model meets current project needs while the comprehensive model provides a roadmap for production deployment.

The zero-profile-permissions approach aligns with Salesforce best practices and provides the flexibility needed for a growing organization with diverse user roles and responsibilities. 