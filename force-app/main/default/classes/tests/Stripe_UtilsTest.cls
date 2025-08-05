@isTest
private class Stripe_UtilsTest {

    final static User testUser = CFA_TestUserBuilder.createUser()
        .withProfile('System Administrator')
        .withPermissionSets(new Set<String> {'Stripe_Integration_User', 'Stripe_Objects'})
        .build();

    @isTest
    static void testJsonToFormEncoded_ValidJson() {
        System.runAs(testUser) {
            String jsonString = '{"email":"test@example.com","name":"John Doe","phone":"+1234567890"}';

            Test.startTest();

            String result = Stripe_Utils.jsonToFormEncoded(jsonString);

            Test.stopTest();

            Assert.isTrue(result.contains('email=test%40example.com'), 'Should contain URL-encoded email');
            Assert.isTrue(result.contains('name=John+Doe'), 'Should contain URL-encoded name');
            Assert.isTrue(result.contains('phone=%2B1234567890'), 'Should contain URL-encoded phone');
            Assert.isTrue(result.contains('&'), 'Should contain parameter separators');
        }
    }

    @isTest
    static void testJsonToFormEncoded_EmptyJson() {
        System.runAs(testUser) {
            Test.startTest();

            String result = Stripe_Utils.jsonToFormEncoded('');

            Test.stopTest();

            Assert.areEqual('', result, 'Empty JSON should return empty string');
        }
    }

    @isTest
    static void testJsonToFormEncoded_NullJson() {
        System.runAs(testUser) {
            Test.startTest();

            String result = Stripe_Utils.jsonToFormEncoded(null);

            Test.stopTest();

            Assert.areEqual('', result, 'Null JSON should return empty string');
        }
    }

    @isTest
    static void testToFormEncoded_ValidMap() {
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>{
                'email' => 'test@example.com',
                'name' => 'John Doe',
                'amount' => 100,
                'active' => true
            };

            Test.startTest();

            String result = Stripe_Utils.toFormEncoded(params);

            Test.stopTest();

            Assert.isTrue(result.contains('email=test%40example.com'), 'Should contain URL-encoded email');
            Assert.isTrue(result.contains('name=John+Doe'), 'Should contain URL-encoded name');
            Assert.isTrue(result.contains('amount=100'), 'Should contain amount');
            Assert.isTrue(result.contains('active=true'), 'Should contain boolean value');
            Assert.isTrue(result.contains('&'), 'Should contain parameter separators');
        }
    }

    @isTest
    static void testToFormEncoded_EmptyMap() {
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>();

            Test.startTest();

            String result = Stripe_Utils.toFormEncoded(params);

            Test.stopTest();

            Assert.areEqual('', result, 'Empty map should return empty string');
        }
    }

    @isTest
    static void testToFormEncoded_NullMap() {
        System.runAs(testUser) {
            Test.startTest();

            String result = Stripe_Utils.toFormEncoded(null);

            Test.stopTest();

            Assert.areEqual('', result, 'Null map should return empty string');
        }
    }

    @isTest
    static void testToFormEncoded_WithNullValues() {
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>{
                'email' => 'test@example.com',
                'name' => null,
                'phone' => '',
                'description' => 'Valid description'
            };

            Test.startTest();

            String result = Stripe_Utils.toFormEncoded(params);

            Test.stopTest();

            Assert.isTrue(result.contains('email=test%40example.com'), 'Should contain email');
            Assert.isTrue(result.contains('description=Valid+description'), 'Should contain description');
            Assert.isFalse(result.contains('name='), 'Should not contain null values');
            Assert.isFalse(result.contains('phone='), 'Should not contain empty string values');
        }
    }

    @isTest
    static void testToFormEncoded_WithReservedKeywords() {
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>{
                'object_x' => 'customer',
                'currency_x' => 'USD',
                'email' => 'test@example.com'
            };

            Test.startTest();

            String result = Stripe_Utils.toFormEncoded(params);

            Test.stopTest();

            Assert.isTrue(result.contains('object=customer'), 'Should convert object_x to object');
            Assert.isTrue(result.contains('currency=USD'), 'Should convert currency_x to currency');
            Assert.isTrue(result.contains('email=test%40example.com'), 'Should contain email unchanged');
            Assert.isFalse(result.contains('object_x='), 'Should not contain original reserved keyword');
            Assert.isFalse(result.contains('currency_x='), 'Should not contain original reserved keyword');
        }
    }

    @isTest
    static void testReplaceStripeFields_ValidJson() {
        System.runAs(testUser) {
            String jsonString = '{"object":"customer","currency":"USD","email":"test@example.com","id":"cus_123"}';

            Test.startTest();

            String result = Stripe_Utils.replaceStripeFields(jsonString);

            Test.stopTest();

            Assert.isTrue(result.contains('"object_x":"customer"'), 'Should replace object with object_x');
            Assert.isTrue(result.contains('"currency_x":"USD"'), 'Should replace currency with currency_x');
            Assert.isTrue(result.contains('"email":"test@example.com"'), 'Should keep non-reserved fields unchanged');
            Assert.isTrue(result.contains('"id":"cus_123"'), 'Should keep other fields unchanged');
            Assert.isFalse(result.contains('"object":"customer"'), 'Should not contain original reserved keyword');
            Assert.isFalse(result.contains('"currency":"USD"'), 'Should not contain original reserved keyword');
        }
    }

    @isTest
    static void testReplaceStripeFields_EmptyJson() {
        System.runAs(testUser) {
            Test.startTest();

            String result = Stripe_Utils.replaceStripeFields('');

            Test.stopTest();

            Assert.areEqual('', result, 'Empty JSON should return empty string');
        }
    }

    @isTest
    static void testReplaceStripeFields_NullJson() {
        System.runAs(testUser) {
            Test.startTest();

            String result = Stripe_Utils.replaceStripeFields(null);

            Test.stopTest();

            Assert.areEqual(null, result, 'Null JSON should return null');
        }
    }

    @isTest
    static void testReplaceStripeFields_NoReservedKeywords() {
        System.runAs(testUser) {
            String jsonString = '{"email":"test@example.com","name":"John Doe","id":"cus_123"}';

            Test.startTest();

            String result = Stripe_Utils.replaceStripeFields(jsonString);

            Test.stopTest();

            Assert.areEqual(jsonString, result, 'JSON without reserved keywords should remain unchanged');
        }
    }

    @isTest
    static void testReplaceStripeFields_NestedJson() {
        System.runAs(testUser) {
            String jsonString = '{"object":"customer","data":{"object":"subscription","currency":"USD"},"id":"cus_123"}';

            Test.startTest();

            String result = Stripe_Utils.replaceStripeFields(jsonString);

            Test.stopTest();

            Assert.isTrue(result.contains('"object_x":"customer"'), 'Should replace top-level object');
            Assert.isTrue(result.contains('"object_x":"subscription"'), 'Should replace nested object');
            Assert.isTrue(result.contains('"currency_x":"USD"'), 'Should replace nested currency');
            Assert.isTrue(result.contains('"id":"cus_123"'), 'Should keep other fields unchanged');
        }
    }

    @isTest
    static void testCompleteWorkflow_JsonToFormEncodedWithReplacements() {
        System.runAs(testUser) {
            String originalJson = '{"object":"customer","currency":"USD","email":"test@example.com"}';
            
            Test.startTest();

            String replacedJson = Stripe_Utils.replaceStripeFields(originalJson);
            String formEncoded = Stripe_Utils.jsonToFormEncoded(replacedJson);

            Test.stopTest();

            Assert.isTrue(formEncoded.contains('object=customer'), 'Should contain replaced object field in form encoding');
            Assert.isTrue(formEncoded.contains('currency=USD'), 'Should contain replaced currency field in form encoding');
            Assert.isTrue(formEncoded.contains('email=test%40example.com'), 'Should contain email field in form encoding');
        }
    }

    @isTest
    static void testSpecialCharacterEncoding() {
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>{
                'description' => 'Test & Special Characters: @#$%^&*()',
                'name' => 'José María',
                'address' => '123 Main St, Apt #5'
            };

            Test.startTest();

            String result = Stripe_Utils.toFormEncoded(params);

            Test.stopTest();

            Assert.isTrue(result.contains('description=Test+%26+Special'), 'Should properly encode special characters');
            Assert.isTrue(result.contains('name=Jos%C3%A9+Mar%C3%ADa'), 'Should properly encode Unicode characters');
            Assert.isTrue(result.contains('address=123+Main+St%2C+Apt+%235'), 'Should properly encode address characters');
        }
    }

    @isTest
    static void testLargeDataHandling() {
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>();
            for (Integer i = 0; i < 100; i++) {
                params.put('field' + i, 'value' + i + '@test.com');
            }

            Test.startTest();

            String result = Stripe_Utils.toFormEncoded(params);

            Test.stopTest();

            Assert.isTrue(result.length() > 0, 'Should handle large data sets');
            Assert.isTrue(result.contains('field0=value0%40test.com'), 'Should contain first field');
            Assert.isTrue(result.contains('field99=value99%40test.com'), 'Should contain last field');
            
            Integer ampersandCount = result.countMatches('&');
            Assert.areEqual(99, ampersandCount, 'Should have correct number of separators');
        }
    }
}