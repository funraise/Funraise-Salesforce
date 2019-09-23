# Funraise-Salesforce
A collection of salesforce metadata used to integrate with the Funraise platform

## Installation 

To install the package, you can either deploy the contents of this repository or use the managed package (coming soon!) to recieve updates automatically.


## Setup
### Create a Connected App in Salesforce to setup OAuth
Note: Before doing the steps below, be sure you have installed the package in the link provided above in the [Installation section](#Installation)
1. In your Salesforce organization, navigate to Setup -> Build -> Create -> Apps and select "New" under **Connected Apps**
2. Fill out the new Connected App form and check the box for *Enable OAuth Settings*
3. Set the *Callback URL* field to **https://platform.funraise.io/salesforce/access/token** 
4. Add the OAuth Scopes **Access and manage your data (api)** and **Perform requests on your behalf at any time (refresh_token, offline_access)** and **Save** the record
5. When viewing the Connected App record under Setup -> Build -> Create -> Apps, the **Consumer Key** and **Consumer Secret** should be visible, these values will be used to integrate with Funraise

### Give the Salesforce user that will perform the OAuth flow in Funraise the permission set
1. Apply "Funraise Permission Set" to your user that performs the OAuth flow so that the REST endpoints are available for Funraise to call

### Setup the Integration in the Funraise Platform
1. When you are logged in to the Funraise platform, select the cog in the top right and click **Integrations**
2. Click the **Settings** expand for the Salesforce integration (**Note:** If you do not see a Salesforce.com option when viewing the integrations screen, contact Funraise support to enable the feature)
3. Select your type of Salesforce environment.  *Production* will correspond to using login.salesforce.com, while *Sandbox* will use test.salesforce.com
4. Enter your **Consumer Key** from the Salesforce Connected App in the **Client Key** field
5. Enter your **Client Secret** from the Salesforce Connected App in the **Client Secret** field
6. A pop-up Salesforce OAuth window will appear asking if you want to give Funraise access to manage your data, click **Allow**
7. You should get a message saying *Salesforce Successfully Connected** at which point you can safely close the pop-up window
8. All Done!  New donations will be sync'd to salesforce and you can manually sync donations by selecting the *Actions* dropdown in the Transaction log and selecting **Send to Salesforce**

## Usage
The package will let you customize how data flows from Funraise into Salesforce.  Once the package is installed, there will be a Funraise app in Salesforce with tabs for Setup and Errors.  

The setup page is where the mappings can be changed.  Any changes will only apply to future incoming Funraise data.  

## How it works
If you want to trace how the code converts a POST request from the Funraise server to, choose one of the controllers in the src/classes directory.  All of the controllers that accept a REST webservice call from the Funraise platform are titled frWS<entity>Controller.   From there you can observe how the request is deserialized and used to create concret sObjects, in some cases using customized mappings.
