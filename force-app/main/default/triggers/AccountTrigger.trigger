trigger AccountTrigger on Account (before insert, before update) {
    AccountHandler.handleBeforeInsertUpdate(Trigger.new, Trigger.oldMap);
}
