/**
 * @description       : 
 * @author            : Pedro Delfino
 * @group             : 
 * @last modified on  : 17-09-2026
 * @last modified by  : Pedro Delfino
**/

public with sharing class AccountHandler {
    private static final Map<String, String> INDUSTRY_TYPE_MAP = new Map<String, String>{
        'Technology' => 'Technology Partner',
        'Financial Services' => 'Financial',
        'Healthcare' => 'Healthcare Provider'
    };

    /**
     * @description Handles before insert/update logic for Account records.
     * @param newAccounts List of Account records being inserted/updated
     * @param oldAccountMap Map of old Account records (null for insert)
     */
    public static void handleBeforeInsertUpdate(
        List<Account> newAccounts,
        Map<Id, Account> oldAccountMap
    ) {

        preventDuplicateNames(newAccounts, oldAccountMap);

        for (Account acc : newAccounts) {
            populateTypeFromIndustry(acc);
            syncBillingToShippingCity(acc, oldAccountMap?.get(acc.Id));
        }
    }

    /**
     * @description Prevents duplicate Account names by checking existing records.
     * Uses bulk-safe pattern: collect names, query once, validate all records.
     * @param newAccounts List of Account records being inserted/updated
     * @param oldAccountMap Map of old Account records (null for insert)
     */
    private static void preventDuplicateNames(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        Set<String> namesToCheck = new Set<String>();
        Set<Id> recordIds = new Set<Id>();

        for (Account acc : newAccounts) {
            if (acc.Name != oldAccountMap?.get(acc.Id)?.Name) {
                namesToCheck.add(acc.Name);
                recordIds.add(acc.Id);
            }
        }

        if (namesToCheck.isEmpty()) {
            return;
        }

        List<Account> existingAccounts = [
            SELECT Id, Name
            FROM Account
            WHERE Name IN :namesToCheck
            AND Id NOT IN :recordIds
            WITH USER_MODE
        ];

        Set<String> existingNames = new Set<String>();
        for (Account existing : existingAccounts) {
            existingNames.add(existing.Name);
        }

        for (Account acc : newAccounts) {
            if (acc.Name != oldAccountMap?.get(acc.Id)?.Name && existingNames.contains(acc.Name)) {
                acc.addError('An Account with this name already exists.');
            }
        }
    }

    /**
     * @description Auto-populates Account Type based on Industry value.
     * Maps Technology → Technology Partner, Financial Services → Financial, Healthcare → Healthcare Provider.
     * @param acc Account record to update
     */
    private static void populateTypeFromIndustry(Account acc) {
        // Only populate Type if it's blank and Industry is set
        if (String.isBlank(acc.Type) && String.isNotBlank(acc.Industry)) {
            acc.Type = INDUSTRY_TYPE_MAP.get(acc.Industry) ?? 'Other';
        }
    }

    /**
     * @description Syncs Billing City to Shipping City if Shipping City is blank and Billing City changed.
     * @param acc Account record being updated
     * @param oldAccount Old version of Account record (null for insert)
     */
    private static void syncBillingToShippingCity(Account acc, Account oldAccount) {
        boolean billingCityChanged = oldAccount == null || acc.BillingCity != oldAccount.BillingCity;

        if (
            billingCityChanged &&
            String.isNotBlank(acc.BillingCity) &&
            String.isBlank(acc.ShippingCity)
        ) {
            acc.ShippingCity = acc.BillingCity;
        }
    }
}

