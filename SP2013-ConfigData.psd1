@{
    AllNodes = @(
        @{
            NodeName = $env:COMPUTERNAME
			PSDscAllowDomainUser = $true
            PSDscAllowPlainTextPassword = $true
        }
    )

	NonNodeData = @(
        @{
			ServiceAccounts = @(
				@{
					SPSetupAccount		= $env:userdomain + '\svcSP_Setup'
					FarmAccount			= $env:userdomain + '\svcSP_Farm'
					WapoolAccount      	= $env:userdomain + '\svcSP_Pool'
					SapoolAccount      	= $env:userdomain + '\svcSP_Srvc'
					CrawlAccount       	= $env:userdomain + '\svcSP_Crawler'
					SearchAccount      	= $env:userdomain + '\svcSP_Srch'
				}
			)
			
			#---------------------BINARIES INSTALL------------------------
			# Define Installation of SharePoint Prerequisites and Binaries
            FullInstallation = $True

			# Location of the SharePoint Binaries -- #Insert Your Own Path
			SPInstallationBinaryPath = 'G:\Tool\SP2013'

            # Location of the SharePoint Logs and Services -- #Insert Your Own Path
            SPPath = 'G:\SP'

			# SharePoint Product Key -- #Insert Your Own Key :)
            SPProductKey 			= 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX' 

			#---------------------FARM CREATION------------------------
			# DB Prefix
			ConfigDBPrefix 			= 'SP_Config_'
			ContentDBPrefix 		= 'SP_Content_'

			# ContentDB Name
			ContentDBNamePlayground = 'Playground_01'
			ContentDBNameMysite 	= 'MySite_01'

			# Database Server Name
            DatabaseServer 	= $env:COMPUTERNAME
            
			# Central Admin Details
			CentralAdminPort 		= 80
			CentralAdminAuth 		= 'NTLM'

			#---------------------APP POOLS------------------------
			MainServiceAppPoolName  = 'SharePoint Service Applications'
			STSAppPoolName			= 'SecurityTokenServiceApplicationPool'
            WebAppPoolName          = 'SharePoint Web Applications Pool'

			#---------------------ULS Logs-----------------------------------
			Logs = @(
				@{
					LogSpaceInGB                                = 5
					AppAnalyticsAutomaticUploadEnabled          = $false
					CustomerExperienceImprovementProgramEnabled = $true
					DaysToKeepLogs                              = 7
					DownloadErrorReportingUpdatesEnabled        = $false
					ErrorReportingAutomaticUploadEnabled        = $false
					ErrorReportingEnabled                       = $false
					EventLogFloodProtectionEnabled              = $true
					EventLogFloodProtectionNotifyInterval       = 5
					EventLogFloodProtectionQuietPeriod          = 2
					EventLogFloodProtectionThreshold            = 5
					EventLogFloodProtectionTriggerPeriod        = 2
					LogCutInterval                              = 15
					LogMaxDiskSpaceUsageEnabled                 = $true
					ScriptErrorReportingDelay                   = 30
					ScriptErrorReportingEnabled                 = $true
					ScriptErrorReportingRequireAuth             = $true
				}
			)

			#---------------------SharePoint Services------------------------
			AppManagement = @(
				@{
					Name                  	= 'App Management Service Application'
					Proxy					= 'App Management Service Application Proxy'
				}
			)

			BCS = @(
				@{
					Name                  	= 'Business Data Connectivity Service Application'
					ProxyName				= 'Business Data Connectivity Service Application Proxy'
				}
			)

			DistributedCache = @(
				@{
					Name                  	= 'AppFabricCachingService'
					CacheSizeInMB			= 1024
				}
			)

			ManagedMetadata = @(
				@{
					Name                 			= 'Managed Metadata Service'
					ProxyName						= 'Managed Metadata Service Proxy'
					IsSingleInstance               	= 'Yes'
				}
			)

			PowerPoint = @(
				@{
					Name                 			= 'PowerPoint Automation Service Application'
					ProxyName						= 'PowerPoint Automation Service Application Proxy'
					CacheExpirationPeriodInSeconds	= 600
					MaximumConversionsPerWorker		= 5
					WorkerKeepAliveTimeoutInSeconds = 120
					WorkerProcessCount				= 3
					WorkerTimeoutInSeconds			= 300
					IsSingleInstance               	= 'Yes'
				}
			)

			Visio = @(
				@{
					Name		= 'Visio Graphics Service'
					ProxyName	= 'Visio Graphics Service Proxy'
				}
			)

			SecureStore = @(
				@{
					Name                  	= 'Secure Store Service Application'
					ProxyName				= 'Secure Store Service Application Proxy'
					AuditingEnabled      	= $true
					AuditlogMaxSize       	= 30
				}
			)

			Usage = @(
				@{
					Name                  	= 'Usage and Health Data Collection Service Application'
					UsageLogCutTime       	= 5
					UsageLogMaxFileSizeKB 	= 1024
				}
			)

			WordAutomationService = @(
				@{
					Name 										= 'Word Automation Services';
					SupportedFileFormats 						= @("docx","doc","rtf","mht","xml")
					TimeBeforeConversionIsMonitored 			= 5
					RecycleThreshold 							= 50
					MaximumSyncConversionRequests 				= 25
					ConversionProcesses 						= 2
					MaximumConversionTime 						= 600
					DisableEmbeddedFonts 						= $False
					DisableBinaryFileScan 						= $False
					JobConversionFrequency 						= 1
					ApplicationPool 							= 'Word Automation Service Application Pool'
					MaximumMemoryUsage 							= 10
					KeepAliveTimeout 							= 30
					NumberOfConversionsPerProcess 				= 10
					MaximumConversionAttempts					= 2
				}
			)

			Search = @(
				@{
					Name 						= 'Search Service Application'
					ProxyName					= 'Search Service Application Proxy'
					ApplicationPool       		= 'SharePoint Server Search'
					Admin 						= $env:COMPUTERNAME
					Crawler 					= $env:COMPUTERNAME
					ContentProcessing 			= $env:COMPUTERNAME
					AnalyticsProcessing 		= $env:COMPUTERNAME
					QueryProcessing 			= $env:COMPUTERNAME
					IndexPartition 				= $env:COMPUTERNAME

					ContentSource = @(
						@{
							LocalSharePointSites = @(
								@{
									Name                 = 'Local SharePoint Sites'
									ContentSourceType    = 'SharePoint'
									Addresses            = 'http://sp01.contoso.com'
									CrawlSetting         = 'CrawlSites'
									Force				 = $true
									ContinuousCrawl      = $false
									FullSchedule         = $null
									Priority             = 'Normal'
								}
							)
							Playground = @(
								@{
									Name                 = 'Playground'
									ContentSourceType    = 'SharePoint'
									Addresses            = 'http://playground.contoso.com'
									CrawlSetting         = 'CrawlSites'
									Force				 = $true
									ContinuousCrawl      = $true
									FullSchedule         = $null
									Priority             = 'Normal'
								}
							)
							MySite = @(
								@{
									Name                 = 'MySite'
									ContentSourceType    = 'SharePoint'
									Addresses            = @('http://mysite.contoso.com','sps3://mysite.contoso.com')
									CrawlSetting         = 'CrawlSites'
									Force				 = $true
									ContinuousCrawl      = $false
									FullSchedule         = $null
									Priority             = 'Normal'
								}
							)
						}
					)
				}
			)

			UPS = @(
				@{
					Name 										= 'User Profile Service Application'
					ProxyName 									= 'User Profile Service Application Proxy'
					ApplicationPool 							= 'SharePoint Service Applications'
					MySiteHostLocation							= 'http://mysite.contoso.com/'
					EnableNetBIOS 								= $true
					UserProfileSyncConnection = @(
						@{
							Forest 						= 'contoso.com'
							Name 						= 'AD DS'
							UseSSL 						= $false
							IncludedOUs 				= @("OU=HQ,OU=CONTOSO,DC=contoso,DC=com")
							Force 						= $false
							ConnectionType 				= 'ActiveDirectory'
						}
					)
				}
			)

			#---------------------Web Application PlayGround----------------------
			WebApp_Playground = @(
				@{
					Name 						= 'Playground'
					Url 						= 'http://playground.contoso.com'
					AllowAnonymous 				= $false
					HostHeader 					= 'playground.contoso.com'
					Path 						= 'C:\inetpub\wwwroot\wss\VirtualDirectories\playground.contoso.com80'
					Port 						= '80'
				}
			)

			PlaygroundRootSite = @(
				@{
					Url 						= 'http://playground.contoso.com'
					OwnerAlias 					= $env:userdomain + '\svcSP_Farm'
					Template 					= 'STS#0'
					Language 					= 1033
					CompatibilityLevel 			= 15
				}
			)

			#---------------------Web Application Mysite--------------------------
			WebApp_MySite = @(
				@{
					Name 						= 'MySite'
					Url 						= 'http://mysite.contoso.com/'
					AllowAnonymous 				= $false
					HostHeader 					= 'mysite.contoso.com'
					Path 						= 'C:\inetpub\wwwroot\wss\VirtualDirectories\mysite.contoso.com80'
					Port 						= '80'
				}
			)

			MySiteRootSite = @(
				@{
			        Url 						= 'http://mysite.contoso.com'
					OwnerAlias 					= $env:userdomain + '\svcSP_Farm'
					Template 					= 'SPSMSITEHOST#0'
					Language 					= 1033
					CompatibilityLevel 			= 15
				}
			)

			#---------------------Misc-------------------------
			SMTP = @(
				@{
					SMTPServer          = 'smtp.office365.com'
					FromAddress         = 'noreply@contoso.com'
					ReplyToAddress      = 'noreply@contoso.com'
					CharacterSet        = '65001'
				}
			)
        }
    )
}