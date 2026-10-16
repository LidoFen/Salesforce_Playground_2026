/**
 * @description       : 
 * @author            : Pedro Delfino
 * @group             : 
 * @last modified on  : 05-10-2026
 * @last modified by  : Pedro Delfino
**/

public with sharing class AccountHandler {
    /**
     * @description Handles before insert/update logic for Account records.
     * @param newAccounts List of Account records being inserted/updated
     * @param oldAccountMap Map of old Account records (null for insert)
     */
    public static void handleBeforeInsertUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {

        AccountLogic.preventDuplicateNames(newAccounts, oldAccountMap);

        for (Account acc : newAccounts) {
            AccountLogic.populateTypeFromIndustry(acc);
            AccountLogic.syncBillingToShippingCity(acc, oldAccountMap?.get(acc.Id));
        }
    }
}

