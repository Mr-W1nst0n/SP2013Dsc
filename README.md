# SharePoint 2013 Single Farm Provisioning

Adjust .\ConfigData.psd1 with your own values

```ruby
# Location of the SharePoint Binaries -- #Insert Your Own Path
SPInstallationBinaryPath = 'G:\Tool\SP2013'

# Location of the SharePoint Logs and Services -- #Insert Your Own Path
SPPath = 'G:\SP'

# SharePoint Product Key -- #Insert Your Own Key :)
SPProductKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX' 
```

### DSC Resources Used  
- SharePointDsc
- xWebAdministration
- NetworkingDsc

### Service Application Provisioned  
- App Management Service
- Business Data Connectivity Service
- Managed Metadata Service
- PowerPoint Automation Service
- Search Service
- Secure Store Service
- Usage and Health Data Collection Service
- User Profile Service *(CredSSP)*
- Visio Graphics
- Word Automation

### Web Application Provisioned  
- Central Admin Url
- playground.contoso.com
- mysite.contoso.com
