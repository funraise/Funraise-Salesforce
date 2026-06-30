trigger frAccountInboundSync on Account (after update) {
    frInboundSupporterSync.handleAccounts(Trigger.new, Trigger.oldMap);
}
