trigger frContactInboundSync on Contact (after update) {
    frInboundSupporterSync.handleContacts(Trigger.new, Trigger.oldMap);
}
