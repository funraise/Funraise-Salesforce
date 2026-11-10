# Funraise-Salesforce
A collection of salesforce metadata used to integrate with the Funraise platform

## Installation 

To install the package, you can either deploy the contents of this repository or use the managed package (coming soon!) to receive updates automatically.

## Salesforce CLI workflow

This repository uses the Metadata API package format used by the existing managed package. Salesforce CLI can retrieve
and deploy this format directly; 2GP and a Dev Hub are not required.

The checked-in `sfdx-project.json` makes this repository recognizable as a Salesforce CLI project. The `src`
directory remains Metadata API format so the existing package manifest and managed-package workflow are preserved.
The manifest uses Metadata API version 68.0 because External Client App metadata is not available in the old 43.0
manifest used by this package.

1. Install the Salesforce CLI and verify that `sf` is available on your `PATH`.
2. Authenticate without storing a Salesforce password in this repository:

   ```bash
   sf org login web --alias funraise-packaging --instance-url https://login.salesforce.com
   ```

   Use `https://test.salesforce.com` when authenticating to a sandbox.
3. Retrieve the manifest into the existing metadata-format directory:

   ```bash
   ./scripts/sf-pull.sh funraise-packaging
   ```

4. Deploy the local metadata to an org:

   ```bash
   ./scripts/sf-push.sh funraise-packaging
   ```

The scripts use `src/package.xml` and preserve the current managed-package workflow. The packaged `Funraise_Platform`
External Client App and its global OAuth and OAuth settings are included in the manifest. Review the retrieve diff before
committing it, especially when Salesforce adds new metadata fields. Salesforce returns the client ID in retrieved OAuth
metadata; the client ID is included because it is not a secret. The client secret must remain in deployment/platform
secret configuration and must never be committed.

For an existing non-source-tracked org, Salesforce documents manifest-based `project retrieve start` and
`project deploy start` as the supported CLI workflow. 2GP is only needed for a second-generation packaging lifecycle,
not for Metadata API work on this existing package.


## Setup
### Package the External Client App

Salesforce now recommends an External Client App for new integrations. The app should be distributed as part of the
managed package with:

1. OAuth enabled and callback URLs for the supported Funraise environments.
2. OAuth scopes **Access and manage your data (api)** and **Perform requests at any time (refresh_token, offline_access)**.
3. Authorization Code / Web Server Flow enabled.
4. **Require Proof Key for Code Exchange (PKCE) extension for Supported Authorization Flows** enabled.
5. **Require Secret for Web Server Flow** and **Require Secret for Refresh Token Flow** enabled, alongside PKCE.

Configure the packaged app's consumer key and secret in the Platform deployment configuration as
`SALESFORCE_OAUTH_CLIENT_ID` and `SALESFORCE_OAUTH_CLIENT_SECRET`; these are deployment secrets and must not be committed.

Organizations no longer enter client credentials. Saving Salesforce settings migrates the integration to the packaged app
and starts a new PKCE authorization flow.

### Give the Salesforce user that will perform the OAuth flow in Funraise the permission set
1. Apply "Funraise Permission Set" to your user that performs the OAuth flow so that the REST endpoints are available for Funraise to call

### Setup the Integration in the Funraise Platform
1. When you are logged in to the Funraise platform, select the cog in the top right and click **Integrations**
2. Click the **Settings** expand for the Salesforce integration (**Note:** If you do not see a Salesforce.com option when viewing the integrations screen, contact Funraise support to enable the feature)
3. Select your type of Salesforce environment.  *Production* will correspond to using login.salesforce.com, while *Sandbox* will use test.salesforce.com
4. Save the integration settings. Funraise supplies the packaged External Client App credentials; organizations no longer enter a client key or client secret.
5. A pop-up Salesforce OAuth window will appear asking if you want to give Funraise access to manage your data. Click **Allow**.
6. You should get a message saying *Salesforce Successfully Connected*, at which point you can safely close the pop-up window.
7. All done! New donations will be synced to Salesforce. You can manually sync donations by selecting the *Actions* dropdown in the Transaction log and selecting **Send to Salesforce**.

## Usage
The package will let you customize how data flows from Funraise into Salesforce.  Once the package is installed, there will be a Funraise app in Salesforce with tabs for Setup and Errors.  

The setup page is where the mappings can be changed.  Any changes will only apply to future incoming Funraise data.  

## How it works
If you want to trace how the code converts a POST request from the Funraise server to, choose one of the controllers in the src/classes directory.  All of the controllers that accept a REST webservice call from the Funraise platform are titled frWS<entity>Controller.   From there you can observe how the request is deserialized and used to create concret sObjects, in some cases using customized mappings.
