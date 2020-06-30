<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Sync_Pledge_donation_fields</fullName>
        <description>See workflow description</description>
        <field>Pledge_Donation_uq__c</field>
        <formula>CASESAFEID(Pledge_Donation__c)</formula>
        <name>Sync Pledge donation fields</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sync_Pledge_subscription_fields</fullName>
        <field>Pledge_Subscription_uq__c</field>
        <formula>CASESAFEID(Pledge_Subscription__c)</formula>
        <name>Sync Pledge subscription fields</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Sync Pledge fields</fullName>
        <actions>
            <name>Sync_Pledge_donation_fields</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Sync_Pledge_subscription_fields</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>There are 2 fields for each relationship.  One is a lookup, another is an external id field used for database operations (unique, upserting). This workflow rule will keep them in sync</description>
        <formula>(Pledge_Donation__c &lt;&gt; Pledge_Donation_uq__c) ||
(Pledge_Subscription__c &lt;&gt;
 Pledge_Subscription_uq__c )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
