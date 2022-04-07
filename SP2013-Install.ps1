Clear-Host
Set-Location -Path $PSScriptRoot
$config = $PSScriptRoot + '\SP2013-ConfigData.psd1'

Configuration SP2013-SingleFarm
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc
    Import-DSCResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName xWebAdministration

    $SPSetupAccount = Get-Credential -Username $ConfigurationData.NonNodeData.ServiceAccounts.SPSetupAccount -Message 'Setup Account'
    $FarmAccount = Get-Credential -Username $ConfigurationData.NonNodeData.ServiceAccounts.FarmAccount -Message 'Farm Account'
    $WebPoolManagedAccount = Get-Credential -Username $ConfigurationData.NonNodeData.ServiceAccounts.WapoolAccount -Message 'WebApps Pool Account'
    $ServicePoolManagedAccount = Get-Credential -Username $ConfigurationData.NonNodeData.ServiceAccounts.SapoolAccount -Message 'ServiceApps Pool Account'
    $SearchAccount = Get-Credential -Username $ConfigurationData.NonNodeData.ServiceAccounts.SearchAccount -Message 'Search ServiceApp Pool Account'
    $CrawlAccount = Get-Credential -Username $ConfigurationData.NonNodeData.ServiceAccounts.CrawlAccount -Message 'Search Crawl Account'
    $Passphrase = $SPSetupAccount
 
    node $AllNodes.NodeName
    {
        #**********************************************************
        # Install SP Binaries + Prerequisites
        #**********************************************************
        SPInstallPrereqs InstallPrereqs
        {
            IsSingleInstance     = 'Yes'
            Ensure               = 'Present'
            InstallerPath        = $ConfigurationData.NonNodeData.SPInstallationBinaryPath + '\prerequisiteinstaller.exe'
            OnlineMode           = $true
			PsDscRunAsCredential = $SPSetupAccount
        }

        SPInstall InstallSharePoint
        {
            IsSingleInstance     = 'Yes'
            Ensure               = 'Present'
            BinaryDir            = $ConfigurationData.NonNodeData.SPInstallationBinaryPath
            ProductKey           = $ConfigurationData.NonNodeData.SPProductKey
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = '[SPInstallPrereqs]InstallPrereqs'
        }

        #**************************************************************
        # Farm Creation
        #**************************************************************
        SPFarm CreateSPFarm
        {
            IsSingleInstance          = 'Yes'
            Ensure                    = 'Present'
            DatabaseServer            = $ConfigurationData.NonNodeData.DatabaseServer
            FarmConfigDatabaseName    = $ConfigurationData.NonNodeData.ConfigDBPrefix + 'Farm'
            AdminContentDatabaseName  = $ConfigurationData.NonNodeData.ContentDBPrefix + 'Admin'
            CentralAdministrationUrl  = 'http://' + [System.Net.Dns]::GetHostByName($env:computerName).HostName
            CentralAdministrationPort = $ConfigurationData.NonNodeData.CentralAdminPort
            CentralAdministrationAuth = $ConfigurationData.NonNodeData.CentralAdminAuth
            RunCentralAdmin           = $true
            Passphrase                = $Passphrase
            FarmAccount               = $FarmAccount
            PsDscRunAsCredential      = $FarmAccount
            DependsOn                 = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

        #**************************************************************
        # SP Managed Account & Service Application Pools Provisioning
        #**************************************************************
        SPManagedAccount ServicePoolManagedAccount
        {
            Ensure 				 = 'Present'
            AccountName          = $ServicePoolManagedAccount.UserName
            Account              = $ServicePoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = '[SPFarm]CreateSPFarm'
        }
      
        SPManagedAccount WebPoolManagedAccount
        {
            Ensure 				 = 'Present'
            AccountName          = $WebPoolManagedAccount.UserName
            Account              = $WebPoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = '[SPFarm]CreateSPFarm'
        }

        SPManagedAccount CrawlManagedAccount
        {
            Ensure 				 = 'Present'
            AccountName          = $CrawlAccount.UserName
            Account              = $CrawlAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = '[SPFarm]CreateSPFarm'
        }

		SPManagedAccount SearchManagedAccount
        {
            Ensure 				 = 'Present'
            AccountName          = $SearchAccount.UserName
            Account              = $SearchAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = '[SPFarm]CreateSPFarm'
        }

        SPServiceAppPool MainServiceAppPool
        {
            Ensure 					= 'Present'
			Name                 	= $ConfigurationData.NonNodeData.MainServiceAppPoolName
            ServiceAccount       	= $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential 	= $SPSetupAccount
            DependsOn            	= '[SPManagedAccount]ServicePoolManagedAccount'
        }

        SPServiceAppPool WebAppPool
        {
            Ensure 					= 'Present'
			Name                 	= $ConfigurationData.NonNodeData.WebAppPoolName
            ServiceAccount       	= $WebPoolManagedAccount.UserName
            PsDscRunAsCredential 	= $SPSetupAccount
            DependsOn            	= '[SPManagedAccount]WebPoolManagedAccount'
        }

		SPServiceAppPool SecurityTokenServiceApplicationPool
        {
            Ensure 					= 'Present'
            Name 					= $ConfigurationData.NonNodeData.STSAppPoolName
            ServiceAccount 			= $FarmAccount.UserName
            PsDscRunAsCredential	= $SPSetupAccount
            DependsOn            	= '[SPManagedAccount]ServicePoolManagedAccount'
        }

		SPServiceAppPool WordAutomationServiceAppPool
        {
            Ensure 					= 'Present'
            Name 					= $ConfigurationData.NonNodeData.WordAutomationService.ApplicationPool
            ServiceAccount			= $ServicePoolManagedAccount.UserName
			PsDscRunAsCredential	= $SPSetupAccount
            DependsOn            	= '[SPManagedAccount]ServicePoolManagedAccount'
        }

        SPServiceAppPool SearchServiceAppPool
        {
            Ensure 					= 'Present'
            Name 					= $ConfigurationData.NonNodeData.Search.ApplicationPool
            ServiceAccount			= $SearchAccount.UserName
			PsDscRunAsCredential	= $SPSetupAccount
            DependsOn            	= '[SPManagedAccount]ServicePoolManagedAccount'
        }

        #**************************************************************
        # SP Services Provisioning
        #**************************************************************
        SPServiceInstance AppManagementService
        {
            Ensure               = 'Present'
            Name                 = 'App Management Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance BusinessDataConnectivityService
        {
            Ensure               = 'Present'
            Name                 = 'Business Data Connectivity Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance ManagedMetadataWebService
        {
            Ensure               = 'Present'
            Name                 = 'Managed Metadata Web Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance MicrosoftSharePointFoundationIncomingEMail
        {
            Ensure               = 'Absent'
            Name                 = 'Microsoft SharePoint Foundation Incoming E-Mail'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance PowerPointConversionService 
        {
            Ensure               = 'Present'
            Name                 = 'PowerPoint Conversion Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance SecureStoreService
        {
            Ensure               = 'Present'
            Name                 = 'Secure Store Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance VisioGraphicsService
        {
            Ensure               = 'Present'
            Name                 = 'Visio Graphics Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance WordAutomationServices
        {
            Ensure               = 'Present'
            Name                 = 'Word Automation Services'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance SharePointServerSearch
        {
            Ensure               = 'Present'
            Name                 = 'SharePoint Server Search'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance SearchAdministrationWebService
        {
            Ensure               = 'Present'
            Name                 = 'Search Administration Web Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance SearchQueryandSiteSettingsService
        {
            Ensure               = 'Present'
            Name                 = 'Search Query and Site Settings Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPServiceInstance UserProfileService 
        {
            Ensure               = 'Present'
            Name                 = 'User Profile Service'
            PsDscRunAsCredential = $SPSetupAccount
        }

        SPUserProfileSyncService UserProfileSyncService
        {
            Ensure                    = 'Present'
            UserProfileServiceAppName = 'User Profile Service Application'
            RunOnlyWhenWriteable      = $true
            PsDscRunAsCredential      = $SPSetupAccount
            DependsOn                 = @('[SPServiceInstance]UserProfileService','[SPUserProfileServiceApp]UserProfileService')
        }
        
        #**************************************************************
        # SP Service Application Provisioning
        #**************************************************************
        SPAppManagementServiceApp AppManagementService
        {
            Ensure               = 'Present'
            Name                 = $ConfigurationData.NonNodeData.AppManagement.Name
            ProxyName            = $ConfigurationData.NonNodeData.AppManagement.Proxy
            ApplicationPool      = $ConfigurationData.NonNodeData.MainServiceAppPoolName
            DatabaseName         = $ConfigurationData.NonNodeData.ConfigDBPrefix + 'AppManagement'
            DatabaseServer       = $ConfigurationData.NonNodeData.DatabaseServer
            PsDscRunAsCredential = $FarmAccount
            DependsOn            = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPServiceInstance]AppManagementService')
        }

        SPBCSServiceApp BCSService
        {
            Ensure               	= 'Present'
            Name                    = $ConfigurationData.NonNodeData.BCS.Name
            ProxyName               = $ConfigurationData.NonNodeData.BCS.ProxyName
            ApplicationPool         = $ConfigurationData.NonNodeData.MainServiceAppPoolName
            DatabaseName          	= $ConfigurationData.NonNodeData.ConfigDBPrefix + 'BCS'
            DatabaseServer        	= $ConfigurationData.NonNodeData.DatabaseServer
            PsDscRunAsCredential  	= $FarmAccount
            DependsOn             	= @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPServiceInstance]BusinessDataConnectivityService','[SPSecureStoreServiceApp]SecureStoreService')
        }

        SPDistributedCacheService EnableDistributedCache
        {
            Ensure               = 'Present'
            Name                 = $ConfigurationData.NonNodeData.DistributedCache.Name
            CacheSizeInMB        = $ConfigurationData.NonNodeData.DistributedCache.CacheSizeInMB
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            CreateFirewallRules  = $true
            DependsOn            = @('[SPFarm]CreateSPFarm','[SPManagedAccount]ServicePoolManagedAccount')
        }

        SPManagedMetaDataServiceApp ManagedMetadataService
		{
            Ensure               	= 'Present'
			Name              		= $ConfigurationData.NonNodeData.ManagedMetadata.Name
			ApplicationPool   		= $ConfigurationData.NonNodeData.MainServiceAppPoolName
			DatabaseServer    		= $ConfigurationData.NonNodeData.DatabaseServer
            DatabaseName      		= $ConfigurationData.NonNodeData.ConfigDBPrefix + 'ManagedMetadata'
            TermStoreAdministrators = $farm.username
            PsDscRunAsCredential  	= $FarmAccount
            DependsOn            	= @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPServiceInstance]ManagedMetadataWebService')
        }

        SPManagedMetaDataServiceAppDefault ManagedMetadataServiceDefault
        {
            ServiceAppProxyGroup           = 'Default'
            DefaultSiteCollectionProxyName = $ConfigurationData.NonNodeData.ManagedMetadata.ProxyName
            DefaultKeywordProxyName        = $ConfigurationData.NonNodeData.ManagedMetadata.ProxyName
            PsDscRunAsCredential           = $FarmAccount
            DependsOn            	       = @('[SPFarm]CreateSPFarm','[SPManagedMetaDataServiceApp]ManagedMetadataService','[SPServiceInstance]ManagedMetadataWebService')
        }

        SPPowerPointAutomationServiceApp PowerPointService
        {
            Ensure                          = 'Present'
            Name                            = $ConfigurationData.NonNodeData.PowerPoint.Name
            ProxyName                       = $ConfigurationData.NonNodeData.PowerPoint.ProxyName
            ApplicationPool                 = $ConfigurationData.NonNodeData.MainServiceAppPoolName
            CacheExpirationPeriodInSeconds  = $ConfigurationData.NonNodeData.PowerPoint.CacheExpirationPeriodInSeconds
            MaximumConversionsPerWorker     = $ConfigurationData.NonNodeData.PowerPoint.MaximumConversionsPerWorker
            WorkerKeepAliveTimeoutInSeconds = $ConfigurationData.NonNodeData.PowerPoint.WorkerKeepAliveTimeoutInSeconds
            WorkerProcessCount              = $ConfigurationData.NonNodeData.PowerPoint.WorkerProcessCount
            WorkerTimeoutInSeconds          = $ConfigurationData.NonNodeData.PowerPoint.WorkerTimeoutInSeconds
            PsDscRunAsCredential            = $FarmAccount
            DependsOn                       = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPServiceInstance]PowerPointConversionService')
        }

		SPSecureStoreServiceApp SecureStoreService
        {
            Ensure               	    = 'Present'
            Name                  		= $ConfigurationData.NonNodeData.SecureStore.Name
            ProxyName                   = $ConfigurationData.NonNodeData.SecureStore.ProxyName
            ApplicationPool      		= $ConfigurationData.NonNodeData.MainServiceAppPoolName
            AuditingEnabled       		= $ConfigurationData.NonNodeData.SecureStore.AuditingEnabled
            AuditlogMaxSize       		= $ConfigurationData.NonNodeData.SecureStore.AuditlogMaxSize
            DatabaseName				= $ConfigurationData.NonNodeData.ConfigDBPrefix + 'SecureStore'
            DatabaseServer              = $ConfigurationData.NonNodeData.DatabaseServer
            MasterKey                   = $PassPhrase
            PsDscRunAsCredential  		= $FarmAccount
            DependsOn            		= @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPServiceInstance]SecureStoreService')
        }

        SPVisioServiceApp VisioService
        {
            Ensure               = 'Present'
            Name                 = $ConfigurationData.NonNodeData.Visio.Name
            ApplicationPool      = $ConfigurationData.NonNodeData.MainServiceAppPoolName
            PsDscRunAsCredential = $FarmAccount
            DependsOn            = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPServiceInstance]VisioGraphicsService')
        }

		SPDiagnosticLoggingSettings DiagnosticLog
        {
            IsSingleInstance 							= 'Yes'
            LogPath                                     = $ConfigurationData.NonNodeData.SPPath + '\ULS'
            LogSpaceInGB                                = $ConfigurationData.NonNodeData.Logs.LogSpaceInGB
            AppAnalyticsAutomaticUploadEnabled          = $ConfigurationData.NonNodeData.Logs.AppAnalyticsAutomaticUploadEnabled
            CustomerExperienceImprovementProgramEnabled = $ConfigurationData.NonNodeData.Logs.CustomerExperienceImprovementProgramEnabled
            DaysToKeepLogs                              = $ConfigurationData.NonNodeData.Logs.DaysToKeepLogs
            DownloadErrorReportingUpdatesEnabled        = $ConfigurationData.NonNodeData.Logs.DownloadErrorReportingUpdatesEnabled
            ErrorReportingAutomaticUploadEnabled        = $ConfigurationData.NonNodeData.Logs.ErrorReportingAutomaticUploadEnabled
            ErrorReportingEnabled                       = $ConfigurationData.NonNodeData.Logs.ErrorReportingEnabled
            EventLogFloodProtectionEnabled              = $ConfigurationData.NonNodeData.Logs.EventLogFloodProtectionEnabled
            EventLogFloodProtectionNotifyInterval       = $ConfigurationData.NonNodeData.Logs.EventLogFloodProtectionNotifyInterval
            EventLogFloodProtectionQuietPeriod          = $ConfigurationData.NonNodeData.Logs.EventLogFloodProtectionQuietPeriod
            EventLogFloodProtectionThreshold            = $ConfigurationData.NonNodeData.Logs.EventLogFloodProtectionThreshold
            EventLogFloodProtectionTriggerPeriod        = $ConfigurationData.NonNodeData.Logs.EventLogFloodProtectionTriggerPeriod
            LogCutInterval                              = $ConfigurationData.NonNodeData.Logs.LogCutInterval
            LogMaxDiskSpaceUsageEnabled                 = $ConfigurationData.NonNodeData.Logs.LogMaxDiskSpaceUsageEnabled
            ScriptErrorReportingDelay                   = $ConfigurationData.NonNodeData.Logs.ScriptErrorReportingDelay
            ScriptErrorReportingEnabled                 = $ConfigurationData.NonNodeData.Logs.ScriptErrorReportingEnabled
            ScriptErrorReportingRequireAuth             = $ConfigurationData.NonNodeData.Logs.ScriptErrorReportingRequireAuth
			PsDscRunAsCredential                        = $SPSetupAccount
            DependsOn                                   = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool')
        }

 	    SPUsageApplication UsageApplication
        {
            Name                  = $ConfigurationData.NonNodeData.Usage.Name
            DatabaseName          = $ConfigurationData.NonNodeData.ConfigDBPrefix + 'HealthDataUsage'
            DatabaseServer        = $ConfigurationData.NonNodeData.DatabaseServer
            UsageLogCutTime       = $ConfigurationData.NonNodeData.Usage.UsageLogCutTime
            UsageLogLocation      = $ConfigurationData.NonNodeData.SPPath + '\UsageLogs'
            UsageLogMaxFileSizeKB = $ConfigurationData.NonNodeData.Usage.UsageLogMaxFileSizeKB
            PsDscRunAsCredential  = $FarmAccount
            DependsOn             = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool')
        }

        SPWordAutomationServiceApp WordAutomationService
        {
            Ensure               						= 'Present'
            Name 										= $ConfigurationData.NonNodeData.WordAutomationService.Name
            ApplicationPool 							= $ConfigurationData.NonNodeData.WordAutomationService.ApplicationPool
            DatabaseName 								= $ConfigurationData.NonNodeData.ConfigDBPrefix + 'WordAutomationService'
            DatabaseServer								= $ConfigurationData.NonNodeData.DatabaseServer
            SupportedFileFormats 						= $ConfigurationData.NonNodeData.WordAutomationService.SupportedFileFormats
            DisableEmbeddedFonts 						= $ConfigurationData.NonNodeData.WordAutomationService.DisableEmbeddedFonts
            MaximumMemoryUsage 							= $ConfigurationData.NonNodeData.WordAutomationService.MaximumMemoryUsage
            RecycleThreshold 							= $ConfigurationData.NonNodeData.WordAutomationService.RecycleThreshold
            DisableBinaryFileScan 						= $ConfigurationData.NonNodeData.WordAutomationService.DisableBinaryFileScan
            ConversionProcesses 						= $ConfigurationData.NonNodeData.WordAutomationService.ConversionProcesses
            JobConversionFrequency 						= $ConfigurationData.NonNodeData.WordAutomationService.JobConversionFrequency
            NumberOfConversionsPerProcess 				= $ConfigurationData.NonNodeData.WordAutomationService.NumberOfConversionsPerProcess
            TimeBeforeConversionIsMonitored 			= $ConfigurationData.NonNodeData.WordAutomationService.TimeBeforeConversionIsMonitored
            MaximumConversionAttempts					= $ConfigurationData.NonNodeData.WordAutomationService.MaximumConversionAttempts
            MaximumSyncConversionRequests 				= $ConfigurationData.NonNodeData.WordAutomationService.MaximumSyncConversionRequests
            KeepAliveTimeout 							= $ConfigurationData.NonNodeData.WordAutomationService.KeepAliveTimeout
            MaximumConversionTime 						= $ConfigurationData.NonNodeData.WordAutomationService.MaximumConversionTime
			PsDscRunAsCredential 						= $FarmAccount
			DependsOn            						= @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPServiceInstance]WordAutomationServices')
        }

        SPSearchServiceApp SearchServiceApp
        {
            Ensure                      = 'Present'
            Name                  		= $ConfigurationData.NonNodeData.Search.Name
            ProxyName                   = $ConfigurationData.NonNodeData.Search.ProxyName
            ApplicationPool       		= $ConfigurationData.NonNodeData.Search.ApplicationPool
            DatabaseName          		= $ConfigurationData.NonNodeData.ConfigDBPrefix + 'Search'
            DatabaseServer		  		= $ConfigurationData.NonNodeData.DatabaseServer
            DefaultContentAccessAccount	= $CrawlAccount
			PsDscRunAsCredential  		= $FarmAccount
			DependsOn            		= @('[SPServiceAppPool]SearchServiceAppPool','[SPServiceInstance]SharePointServerSearch','[SPServiceInstance]SearchAdministrationWebService','[SPServiceInstance]SearchQueryandSiteSettingsService')
        }

		SPSearchTopology SearchTopology
        {
            ServiceAppName 				= $ConfigurationData.NonNodeData.Search.Name
			Admin 						= $ConfigurationData.NonNodeData.Search.Admin
			Crawler 					= $ConfigurationData.NonNodeData.Search.Crawler
			ContentProcessing 			= $ConfigurationData.NonNodeData.Search.ContentProcessing
            AnalyticsProcessing 		= $ConfigurationData.NonNodeData.Search.AnalyticsProcessing
			QueryProcessing 			= $ConfigurationData.NonNodeData.Search.QueryProcessing
            IndexPartition 				= $ConfigurationData.NonNodeData.Search.IndexPartition
            FirstPartitionDirectory 	= $ConfigurationData.NonNodeData.SPPath + '\SearchIndexes\'
			PsDscRunAsCredential 		= $FarmAccount;
			DependsOn            		= '[SPSearchServiceApp]SearchServiceApp'
        }

        SPSearchServiceSettings SearchServiceSettings
        {
            IsSingleInstance      = 'Yes'
            PerformanceLevel      = 'Maximum'
            ContactEmail          = $ConfigurationData.NonNodeData.SMTP.ReplyToAddress
            WindowsServiceAccount = $SearchManagedAccount
            PsDscRunAsCredential  = $SPSetupAccount
        }

        #**********************************************************
        # Search Content Sources
        #**********************************************************
		SPSearchContentSource LocalSharePointSites
		{
            Ensure               = 'Present'
			Name                 = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.Name
			ServiceAppName       = $ConfigurationData.NonNodeData.Search.Name
			ContentSourceType    = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.ContentSourceType
			Addresses            = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.Addresses
			CrawlSetting         = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.CrawlSetting
			ContinuousCrawl      = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.ContinuousCrawl
			FullSchedule         = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.FullSchedule
			Priority             = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.Priority
            Force                = $ConfigurationData.NonNodeData.Search.ContentSource.LocalSharePointSites.Force
			PsDscRunAsCredential = $FarmAccount
			DependsOn            = @('[SPSearchServiceApp]SearchServiceApp','[SPSearchTopology]SearchTopology')
        }

        SPSearchContentSource PlayGround
        {
            Ensure               = 'Present'
			Name                 = $ConfigurationData.NonNodeData.Search.ContentSource.Playground.Name
			ServiceAppName       = $ConfigurationData.NonNodeData.Search.Name
			ContentSourceType    = $ConfigurationData.NonNodeData.Search.ContentSource.Playground.ContentSourceType
			Addresses            = $ConfigurationData.NonNodeData.Search.ContentSource.Playground.Addresses
			CrawlSetting         = $ConfigurationData.NonNodeData.Search.ContentSource.Playground.CrawlSetting
			ContinuousCrawl      = $ConfigurationData.NonNodeData.Search.ContentSource.Playground.ContinuousCrawl
			FullSchedule         = $ConfigurationData.NonNodeData.Search.ContentSource.Playground.FullSchedule
			Priority             = $ConfigurationData.NonNodeData.Search.ContentSource.Playground.Priority
			PsDscRunAsCredential = $FarmAccount
			DependsOn            = @('[SPSearchServiceApp]SearchServiceApp','[SPSearchTopology]SearchTopology','[SPSearchContentSource]LocalSharePointSites')
        }

        SPSearchContentSource MySite
        {
            Ensure               = 'Present'
			Name                 = $ConfigurationData.NonNodeData.Search.ContentSource.MySite.Name
			ServiceAppName       = $ConfigurationData.NonNodeData.Search.Name
			ContentSourceType    = $ConfigurationData.NonNodeData.Search.ContentSource.MySite.ContentSourceType
			Addresses            = $ConfigurationData.NonNodeData.Search.ContentSource.MySite.Addresses
			CrawlSetting         = $ConfigurationData.NonNodeData.Search.ContentSource.MySite.CrawlSetting
			ContinuousCrawl      = $ConfigurationData.NonNodeData.Search.ContentSource.MySite.ContinuousCrawl
			FullSchedule         = $ConfigurationData.NonNodeData.Search.ContentSource.MySite.FullSchedule
			Priority             = $ConfigurationData.NonNodeData.Search.ContentSource.MySite.Priority
			PsDscRunAsCredential = $FarmAccount
			DependsOn            = @('[SPSearchServiceApp]SearchServiceApp','[SPSearchTopology]SearchTopology','[SPSearchContentSource]LocalSharePointSites')
        }

        SPUserProfileServiceApp UserProfileService
		{
            Name                 = $ConfigurationData.NonNodeData.UPS.Name
            ProxyName            = $ConfigurationData.NonNodeData.UPS.ProxyName
			ApplicationPool      = $ConfigurationData.NonNodeData.MainServiceAppPoolName
			MySiteHostLocation   = $ConfigurationData.NonNodeData.UPS.MySiteHostLocation
			ProfileDBName        = $ConfigurationData.NonNodeData.ConfigDBPrefix + 'Profile'
			ProfileDBServer      = $ConfigurationData.NonNodeData.UPS.ProfileDBServer
			SocialDBName         = $ConfigurationData.NonNodeData.ConfigDBPrefix + 'Social'
			SocialDBServer       = $ConfigurationData.NonNodeData.UPS.SocialDBServer
			SyncDBName           = $ConfigurationData.NonNodeData.ConfigDBPrefix + 'Sync'
			SyncDBServer         = $ConfigurationData.NonNodeData.UPS.SyncDBServer
            EnableNetBIOS        = $ConfigurationData.NonNodeData.UPS.EnableNetBIOS
			PsDscRunAsCredential = $SPSetupAccount
			DependsOn            = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]MainServiceAppPool','[SPSite]MySiteRootSite')
        }

		SPUserProfileSyncConnection ADDSDomain
		{
			UserProfileService 			= $ConfigurationData.NonNodeData.UPS.Name
			Forest 						= $ConfigurationData.NonNodeData.UPS.UserProfileSyncConnection.Forest
			Name 						= $ConfigurationData.NonNodeData.UPS.UserProfileSyncConnection.Name
			ConnectionCredentials 		= $SPSetupAccount
			UseSSL 						= $ConfigurationData.NonNodeData.UPS.UserProfileSyncConnection.UseSSL
			IncludedOUs 				= $ConfigurationData.NonNodeData.UPS.UserProfileSyncConnection.IncludedOUs
			Force 						= $ConfigurationData.NonNodeData.UPS.UserProfileSyncConnection.Force
			ConnectionType 				= $ConfigurationData.NonNodeData.UPS.UserProfileSyncConnection.ConnectionType
			PsDscRunAsCredential 		= $FarmAccount
			DependsOn            		= @('[SPUserProfileServiceApp]UserProfileService','[SPUserProfileSyncService]UserProfileSyncService')
        }

        #**********************************************************
        # Web Application Provisioning - PlayGround
        #**********************************************************
		SPWebApplication Playground
        {
            Ensure 						= 'Present'
            Name 						= $ConfigurationData.NonNodeData.WebApp_Playground.Name
            ApplicationPool 			= $ConfigurationData.NonNodeData.WebAppPoolName
            ApplicationPoolAccount 		= $WebPoolManagedAccount.UserName
            WebAppUrl 					= $ConfigurationData.NonNodeData.WebApp_Playground.Url
            AllowAnonymous 				= $ConfigurationData.NonNodeData.WebApp_Playground.AllowAnonymous
            DatabaseName 				= $ConfigurationData.NonNodeData.ContentDBPrefix + $ConfigurationData.NonNodeData.ContentDBNamePlayground
            DatabaseServer 				= $ConfigurationData.NonNodeData.DatabaseServer
            HostHeader 					= $ConfigurationData.NonNodeData.WebApp_Playground.HostHeader
            Path 						= $ConfigurationData.NonNodeData.WebApp_Playground.Path
            Port 						= $ConfigurationData.NonNodeData.WebApp_Playground.Port
            PsDscRunAsCredential 		= $FarmAccount
            DependsOn                   = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]WebAppPool')
        }

		SPSite PlaygroundRootSite
        {
            Url 						= $ConfigurationData.NonNodeData.PlaygroundRootSite.Url
			OwnerAlias 					= $ConfigurationData.NonNodeData.PlaygroundRootSite.OwnerAlias
			ContentDatabase 			= $ConfigurationData.NonNodeData.ContentDBPrefix + $ConfigurationData.NonNodeData.ContentDBNamePlayground
			Template 					= $ConfigurationData.NonNodeData.PlaygroundRootSite.Template
            Language 					= $ConfigurationData.NonNodeData.PlaygroundRootSite.Language
            CompatibilityLevel 			= $ConfigurationData.NonNodeData.PlaygroundRootSite.CompatibilityLevel
			PsDscRunAsCredential 		= $FarmAccount
            DependsOn 					= '[SPWebApplication]Playground'
        }

        #**********************************************************
        # Web Application Provisioning - MySite
        #**********************************************************
        SPWebApplication MySite
        {
            Ensure 						= 'Present'
            Name 						= $ConfigurationData.NonNodeData.WebApp_MySite.Name
            ApplicationPool 			= $ConfigurationData.NonNodeData.WebAppPoolName
            ApplicationPoolAccount 		= $WebPoolManagedAccount.UserName
            WebAppUrl 					= $ConfigurationData.NonNodeData.WebApp_MySite.Url
            AllowAnonymous 				= $ConfigurationData.NonNodeData.WebApp_MySite.AllowAnonymous
            DatabaseName 				= $ConfigurationData.NonNodeData.ContentDBPrefix + $ConfigurationData.NonNodeData.ContentDBNameMysite
            DatabaseServer 				= $ConfigurationData.NonNodeData.DatabaseServer
            HostHeader 					= $ConfigurationData.NonNodeData.WebApp_MySite.HostHeader
            Path 						= $ConfigurationData.NonNodeData.WebApp_MySite.Path
            Port 						= $ConfigurationData.NonNodeData.WebApp_MySite.Port
            PsDscRunAsCredential 		= $FarmAccount
            DependsOn                   = @('[SPFarm]CreateSPFarm','[SPServiceAppPool]WebAppPool')
        }

		SPSite MySiteRootSite
        {
            Url 						= $ConfigurationData.NonNodeData.MySiteRootSite.Url
			OwnerAlias 					= $ConfigurationData.NonNodeData.MySiteRootSite.OwnerAlias
			ContentDatabase 			= $ConfigurationData.NonNodeData.ContentDBPrefix + $ConfigurationData.NonNodeData.ContentDBNameMysite
			Template 					= $ConfigurationData.NonNodeData.MySiteRootSite.Template
            Language 					= $ConfigurationData.NonNodeData.MySiteRootSite.Language
            CompatibilityLevel 			= $ConfigurationData.NonNodeData.MySiteRootSite.CompatibilityLevel
			PsDscRunAsCredential 		= $FarmAccount
            DependsOn 					= '[SPWebApplication]MySite'
        }

        #**********************************************************
        # Misc
        #**********************************************************     
        SPOutgoingEmailSettings FarmOutgoingEmailSettings
        {
            WebAppUrl               = 'http://' + [System.Net.Dns]::GetHostByName($env:computerName).HostName
            SMTPServer              = $ConfigurationData.NonNodeData.SMTP.SMTPServer
            FromAddress             = $ConfigurationData.NonNodeData.SMTP.FromAddress
            ReplyToAddress          = $ConfigurationData.NonNodeData.SMTP.ReplyToAddress
            CharacterSet            = $ConfigurationData.NonNodeData.SMTP.CharacterSet
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn               = @('[SPSite]PlaygroundRootSite','[SPSite]MySiteRootSite')
        }
              
        xWebAppPool RemoveDotNet2AppPool
		{
			Ensure			        = 'Absent'
            Name			        = '.NET v2.0'
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

		xWebAppPool RemoveDotNet2ClassicAppPool
		{
			Ensure			        = 'Absent'
            Name			        = '.NET v2.0 Classic'
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

		xWebAppPool RemoveDotNet45AppPool
		{
			Ensure			        = 'Absent'
            Name			        = '.NET v4.5'
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

		xWebAppPool RemoveDotNet45ClassicAppPool
		{
			Ensure			        = 'Absent'
            Name			        = '.NET v4.5 Classic'
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

		xWebAppPool RemoveDotNetClassicNETAppPool
		{
			Ensure			        = 'Absent'
            Name			        = 'Classic .NET AppPool'
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

        xWebAppPool RemoveDefaultAppPool
        {
            Ensure                  = 'Absent'
            Name                    = 'DefaultAppPool'
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

        xWebSite RemoveDefaultWebSite
        {
            Ensure                  = 'Absent'
            Name                    = 'Default Web Site'
            PhysicalPath            = 'C:\inetpub\wwwroot'
            PsDscRunAsCredential    = $SPSetupAccount
            DependsOn = @('[SPInstallPrereqs]InstallPrereqs','[SPInstall]InstallSharePoint')
        }

        HostsFile PlayGroundSite
        {
            HostName  = $ConfigurationData.NonNodeData.WebApp_Playground.HostHeader
            IPAddress = '127.0.0.1'
            Ensure    = 'Present'
        }

        HostsFile MySite
        {
            HostName  = $ConfigurationData.NonNodeData.WebApp_MySite.HostHeader
            IPAddress = '127.0.0.1'
            Ensure    = 'Present'
        }

        #**********************************************************
        # Local Configuration Manager settings - LCM
        #**********************************************************
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $false
            DebugMode = 'All'
            ConfigurationMode = 'ApplyOnly'
        }
    }
}

SP2013-SingleFarm -ConfigurationData $config -OutputPath './MOF/SP' -ErrorAction Stop
Set-DscLocalConfigurationManager ./MOF/SP -Force -Verbose
Start-DscConfiguration -Path ./MOF/SP -Wait -Force -Verbose -ErrorVariable ev