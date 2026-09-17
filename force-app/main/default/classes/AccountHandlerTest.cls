/**
 * @description       : 
 * @author            : Pedro Delfino
 * @group             : 
 * @last modified on  : 17-09-2026
 * @last modified by  : Pedro Delfino
**/
@isTest
private class AccountHandlerTest {
    // ==================== POSITIVE PATH TESTS ====================

    @isTest
    static void testPopulateTypeFromIndustryOnInsert() {
        Account acc = new Account(
            Name = 'Tech Corp',
            Industry = 'Technology'
        );

        insert acc;

        Account result = [SELECT Id, Type FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Technology Partner', result.Type, 'Type should be populated from Industry');
    }

    @isTest
    static void testPopulateTypeFromIndustryOnUpdate() {
        Account acc = new Account(
            Name = 'Finance Inc',
            Industry = null
        );
        insert acc;

        acc.Industry = 'Financial Services';
        update acc;

        Account result = [SELECT Id, Type FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Financial', result.Type, 'Type should sync from updated Industry');
    }

    @isTest
    static void testSyncBillingToShippingCityOnInsert() {
        Account acc = new Account(
            Name = 'Ship Test Co',
            BillingCity = 'New York'
        );

        insert acc;

        Account result = [SELECT Id, ShippingCity FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('New York', result.ShippingCity, 'ShippingCity should sync from BillingCity');
    }

    @isTest
    static void testSyncBillingToShippingCityOnUpdate() {
        Account acc = new Account(
            Name = 'Update Ship Test',
            BillingCity = null
        );
        insert acc;

        acc.BillingCity = 'Boston';
        update acc;

        Account result = [SELECT Id, ShippingCity FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Boston', result.ShippingCity, 'ShippingCity should sync when BillingCity updated');
    }

    @isTest
    static void testTypePreservedIfAlreadySet() {
        Account acc = new Account(
            Name = 'Preserve Type Test',
            Industry = 'Technology',
            Type = 'Prospect'
        );

        insert acc;

        Account result = [SELECT Id, Type FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Prospect', result.Type, 'Type should not be overwritten if already set');
    }

    @isTest
    static void testIndustryOtherMapsToOther() {
        Account acc = new Account(
            Name = 'Other Industry Test',
            Industry = 'Manufacturing'
        );

        insert acc;

        Account result = [SELECT Id, Type FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Other', result.Type, 'Unknown Industry should map to "Other"');
    }

    @isTest
    static void testShippingCityPreservedIfAlreadySet() {
        Account acc = new Account(
            Name = 'Preserve Shipping Test',
            BillingCity = 'New York',
            ShippingCity = 'Los Angeles'
        );

        insert acc;

        Account result = [SELECT Id, ShippingCity FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Los Angeles', result.ShippingCity, 'ShippingCity should not be overwritten');
    }

    // ==================== NEGATIVE PATH TESTS ====================

    @isTest
    static void testPreventDuplicateAccountNameOnInsert() {
        Account acc1 = new Account(Name = 'Duplicate Test');
        insert acc1;

        Account acc2 = new Account(Name = 'Duplicate Test');

        try {
            insert acc2;
            Assert.fail('Expected DmlException for duplicate Account name');
        } catch (DmlException e) {
            Assert.isTrue(
                e.getMessage().contains('An Account with this name already exists'),
                'Error message should mention duplicate name'
            );
        }
    }

    @isTest
    static void testPreventDuplicateAccountNameOnUpdate() {
        Account acc1 = new Account(Name = 'Original Account 1');
        Account acc2 = new Account(Name = 'Original Account 2');
        insert new List<Account>{ acc1, acc2 };

        acc2.Name = 'Original Account 1'; // Try to change to duplicate name

        try {
            update acc2;
            Assert.fail('Expected DmlException for duplicate Account name on update');
        } catch (DmlException e) {
            Assert.isTrue(
                e.getMessage().contains('An Account with this name already exists'),
                'Update should prevent duplicate names'
            );
        }
    }

    @isTest
    static void testAllowNameChangeWhenNotDuplicate() {
        Account acc1 = new Account(Name = 'Original Name');
        insert acc1;

        acc1.Name = 'New Unique Name';
        update acc1;

        Account result = [SELECT Id, Name FROM Account WHERE Id = :acc1.Id];
        Assert.areEqual('New Unique Name', result.Name, 'Name update should succeed when not duplicate');
    }

    @isTest
    static void testSyncOnlyWhenBillingCityChanged() {
        Account acc = new Account(
            Name = 'No Sync Test',
            BillingCity = 'Portland',
            ShippingCity = 'Seattle'
        );
        insert acc;

        // Update different field (not BillingCity) — ShippingCity should not change
        acc.Industry = 'Technology';
        update acc;

        Account result = [SELECT Id, ShippingCity FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Seattle', result.ShippingCity, 'ShippingCity should remain unchanged');
    }

    @isTest
    static void testNullIndustryDoesNotPopulateType() {
        Account acc = new Account(
            Name = 'Null Industry Test',
            Industry = null
        );

        insert acc;

        Account result = [SELECT Id, Type FROM Account WHERE Id = :acc.Id];
        Assert.isNull(result.Type, 'Type should remain null when Industry is null');
    }

    // ==================== BULK PATH TESTS ====================

    @isTest
    static void testBulkPopulateTypeFromIndustry() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Tech 1', Industry = 'Technology'),
            new Account(Name = 'Finance 1', Industry = 'Financial Services'),
            new Account(Name = 'Health 1', Industry = 'Healthcare'),
            new Account(Name = 'Other 1', Industry = 'Retail')
        };

        insert accounts;

        Map<Id, Account> results = new Map<Id, Account>(
            [SELECT Id, Type FROM Account WHERE Id IN :accounts]
        );

        Assert.areEqual('Technology Partner', results.get(accounts[0].Id).Type, 'Bulk insert: Tech');
        Assert.areEqual('Financial', results.get(accounts[1].Id).Type, 'Bulk insert: Finance');
        Assert.areEqual('Healthcare Provider', results.get(accounts[2].Id).Type, 'Bulk insert: Healthcare');
        Assert.areEqual('Other', results.get(accounts[3].Id).Type, 'Bulk insert: Other');
    }

    @isTest
    static void testBulkPreventDuplicateNames() {
        List<Account> batch1 = new List<Account>{
            new Account(Name = 'Bulk Test 1'),
            new Account(Name = 'Bulk Test 2')
        };
        insert batch1;

        // Try to insert batch with duplicates and new names
        List<Account> batch2 = new List<Account>{
            new Account(Name = 'Bulk Test 1'), // Duplicate
            new Account(Name = 'Bulk Test 3') // New
        };

        try {
            insert batch2;
            Assert.fail('Expected DmlException for bulk duplicate Account');
        } catch (DmlException e) {
            // Verify first record failed, second may or may not succeed depending on order
            Assert.isTrue(e.getMessage().contains('An Account with this name already exists'));
        }
    }

    @isTest
    static void testBulkSyncBillingToShippingCity() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Bulk Ship 1', BillingCity = 'Boston'),
            new Account(Name = 'Bulk Ship 2', BillingCity = 'Chicago'),
            new Account(Name = 'Bulk Ship 3', BillingCity = 'Denver')
        };

        insert accounts;

        Map<Id, Account> results = new Map<Id, Account>(
            [SELECT Id, ShippingCity FROM Account WHERE Id IN :accounts]
        );

        Assert.areEqual('Boston', results.get(accounts[0].Id).ShippingCity, 'Bulk: City 1');
        Assert.areEqual('Chicago', results.get(accounts[1].Id).ShippingCity, 'Bulk: City 2');
        Assert.areEqual('Denver', results.get(accounts[2].Id).ShippingCity, 'Bulk: City 3');
    }

    @isTest
    static void testBulkUpdateMultipleFields() {
        // Industry left blank on insert so Type stays blank and can be populated on update
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Bulk Update 1', BillingCity = 'SF'),
            new Account(Name = 'Bulk Update 2', BillingCity = 'NYC'),
            new Account(Name = 'Bulk Update 3', BillingCity = 'Boston')
        };
        insert accounts;

        accounts[0].Industry = 'Technology';
        accounts[1].Industry = 'Healthcare';
        accounts[2].Industry = 'Financial Services';
        for (Account acc : accounts) {
            acc.BillingCity = 'Phoenix';
        }
        update accounts;

        Map<Id, Account> results = new Map<Id, Account>([
            SELECT Id, Type, ShippingCity FROM Account WHERE Id IN :accounts
        ]);

        Assert.areEqual('Technology Partner', results.get(accounts[0].Id).Type);
        Assert.areEqual('Healthcare Provider', results.get(accounts[1].Id).Type);
        Assert.areEqual('Financial', results.get(accounts[2].Id).Type);

        // ShippingCity was already synced on insert, so it stays unchanged despite the BillingCity update
        Assert.areEqual('SF', results.get(accounts[0].Id).ShippingCity);
        Assert.areEqual('NYC', results.get(accounts[1].Id).ShippingCity);
        Assert.areEqual('Boston', results.get(accounts[2].Id).ShippingCity);
    }


    @isTest
    static void testBulkNoGovernorLimitViolation() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Governor Test ' + i,
                Industry = 'Technology',
                BillingCity = 'City ' + i
            ));
        }
        insert accounts;

        List<Account> results = [SELECT Id, Name, Type, ShippingCity FROM Account WHERE Name LIKE 'Governor Test %'];
        Assert.areEqual(200, results.size());

        for (Account acc : results) {
            Assert.areEqual('Technology Partner', acc.Type);
            String cityIndex = acc.Name.removeStart('Governor Test ');
            Assert.areEqual('City ' + cityIndex, acc.ShippingCity);
        }
    }
}
