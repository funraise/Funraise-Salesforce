# Funraise-Salesforce
Salesforce unmanaged package used to integrate with the Funraise platform

## Installation

To install the package, you can either deploy the contents of this repository or use the latest unmanaged package install link [found here](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t36000000rj4a)

## Setup
### Create a Connected App in Salesforce to setup OAuth 
1. In your Salesforce organization, navigate to Setup -> Build -> Create -> Apps and select "New" under **Connected Apps**
2. Fill out the new Connected App form and check the box for *Enable OAuth Settings*
3. Set the *Callback URL* field to **https://platform.funraise.io/salesforce/access/token** 
4. Add the OAuth Scopes **Access and manage your data (api)** and **Perform requests on your behalf at any time (refresh_token, offline_access)** and **Save** the record
5. When viewing the Connected App record under Setup -> Build -> Create -> Apps, the **Consumer Key** and **Consumer Secret** should be visible, these values will be used to integrate with Funraise

### Setup the Integration in the Funraise Platform
1. When you are logged in to the Funraise platform, select the cog in the top right and click **Integrations**
2. Click the **Settings** expand for the Salesforce integration (**Note:** If you do not see a Salesforce.com option when viewing the integrations screen, contact Funraise support to enable the feature)
3. Select your type of Salesforce environment.  *Production* will correspond to using login.salesforce.com, while *Sandbox* will use test.salesforce.com
4. Enter your **Consumer Key** from the Salesforce Connected App in the **Client Key** field
5. Enter your **Client Secret** from the Salesforce Connected App in the **Client Secret** field
6. A pop-up Salesforce OAuth window will appear asking if you want to give Funraise access to manage your data, click **Allow**
7. You should get a message saying *Salesforce Successfully Connected** at which point you can safely close the pop-up window
8. All Done!  New donations will be sync'd to salesforce and you can manually sync donations by selecting the *Actions* dropdown in the Transaction log and selecting **Send to Salesforce**
