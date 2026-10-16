/**
 * @description       : 
 * @author            : Pedro Delfino
 * @group             : 
 * @last modified on  : 05-10-2026
 * @last modified by  : Pedro Delfino
**/
trigger AccountTrigger on Account (before insert, before update) {
    if(Trigger.isInsert) {
        AccountHandler.handleBeforeInsertUpdate(Trigger.new, Trigger.oldMap);
    }
}