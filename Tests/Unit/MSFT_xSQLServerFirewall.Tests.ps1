# Suppressing this rule because PlainText is required for one of the functions used in this test
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerFirewall'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        <#
            Testing two major versions to verify Integration Services differences (i.e service name).
            No point in testing each supported SQL Server version, since there are no difference
            between the other major versions.
        #>
        $testProductVersion = @(
            11, # SQL Server 2012
            10  # SQL Server 2008 and 2008 R2
        )

        $mockSqlDatabaseEngineName = 'MSSQL'
        $mockSqlAgentName = 'SQLAgent'
        $mockSqlFullTextName = 'MSSQLFDLauncher'
        $mockSqlReportingName = 'ReportServer'
        $mockSqlIntegrationName = 'MsDtsServer{0}0' # {0} will be replaced by SQL major version in runtime
        $mockSqlAnalysisName = 'MSOLAP'

        $mockSqlDatabaseEngineInstanceIdName = $mockSqlDatabaseEngineName
        $mockSqlAnalysisServicesInstanceIdName = 'MSAS'

        $mockSqlCollation = 'Finnish_Swedish_CI_AS'
        $mockSqlLoginMode = 'Integrated'

        $mockSetupExecutableName = 'setup.exe'
        $mockDatabaseEngineExecutableName  = 'sqlservr.exe'
        $mockIntegrationServicesExecutableName = 'MsDtsSrvr.exe'

        $mockFirewallRulePort_ReportingServicesNoSslProtocol = 'tcp'
        $mockFirewallRulePort_ReportingServicesNoSslLocalPort = 80
        $mockFirewallRulePort_ReportingServicesSslProtocol = 'tcp'
        $mockFirewallRulePort_ReportingServicesSslLocalPort = 443
        $mockFirewallRulePort_IntegrationServicesProtocol = 'tcp'
        $mockFirewallRulePort_IntegrationServicesLocalPort = 135

        $mockSqlSharedDirectory = 'C:\Program Files\Microsoft SQL Server'
        $mockSqlSharedWowDirectory = 'C:\Program Files (x86)\Microsoft SQL Server'
        $mockSqlProgramDirectory = 'C:\Program Files\Microsoft SQL Server'
        $mockSqlSystemAdministrator = 'COMPANY\Stacy'


        $mockSqlAnalysisCollation = 'Finnish_Swedish_CI_AS'
        $mockSqlAnalysisAdmins = @('COMPANY\Stacy','COMPANY\SSAS Administrators')
        $mockSqlAnalysisDataDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Data'
        $mockSqlAnalysisTempDirectory= 'C:\Program Files\Microsoft SQL Server\OLAP\Temp'
        $mockSqlAnalysisLogDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Log'
        $mockSqlAnalysisBackupDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Backup'
        $mockSqlAnalysisConfigDirectory = 'C:\Program Files\Microsoft SQL Server\OLAP\Config'

        $mockDefaultInstance_InstanceName = 'MSSQLSERVER'

        $mockSQLBrowserServiceName = 'SQLBrowser'

        $mockDefaultInstance_InstanceName = 'MSSQLSERVER'
        $mockDefaultInstance_DatabaseServiceName = $mockDefaultInstance_InstanceName
        $mockDefaultInstance_AgentServiceName = 'SQLSERVERAGENT'
        $mockDefaultInstance_FullTextServiceName = $mockSqlFullTextName
        $mockDefaultInstance_ReportingServiceName = $mockSqlReportingName
        $mockDefaultInstance_IntegrationServiceName = $mockSqlIntegrationName
        $mockDefaultInstance_AnalysisServiceName = 'MSSQLServerOLAPService'

        $mockNamedInstance_InstanceName = 'TEST'
        $mockNamedInstance_DatabaseServiceName = "$($mockSqlDatabaseEngineName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_AgentServiceName = "$($mockSqlAgentName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_FullTextServiceName = "$($mockSqlFullTextName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_ReportingServiceName = "$($mockSqlReportingName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_IntegrationServiceName = $mockSqlIntegrationName
        $mockNamedInstance_AnalysisServiceName = "$($mockSqlAnalysisName)`$$($mockNamedInstance_InstanceName)"

        $mockmockSourceCredentialUserName = "COMPANY\sqladmin"
        $mockmockSourceCredentialPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $mockSourceCredential = New-Object System.Management.Automation.PSCredential( $mockmockSourceCredentialUserName, $mockmockSourceCredentialPassword )

        $mockSqlServiceAccount = 'COMPANY\SqlAccount'
        $mockAgentServiceAccount = 'COMPANY\AgentAccount'

        #region Function mocks
        $mockGetSqlMajorVersion = {
            return $mockCurrentSqlMajorVersion
        }

        $mockEmptyHashtable = {
            return @()
        }

        $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber = '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}'
        $mockSqlServerManagementStudio2012_ProductIdentifyingNumber = '{A7037EB2-F953-4B12-B843-195F4D988DA1}'
        $mockSqlServerManagementStudio2014_ProductIdentifyingNumber = '{75A54138-3B98-4705-92E4-F619825B121F}'
        $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber = '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}'
        $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber = '{7842C220-6E9A-4D5A-AE70-0E138271F883}'
        $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber = '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}'

        $mockRegistryUninstallProductsPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

        $mockGetItemProperty_UninstallProducts2008R2 = {
            return @(
                $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber,  # Mock product SSMS 2008 and SSMS 2008 R2
                $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber  # Mock product ADV_SSMS 2012
            )
        }

        $mockGetItemProperty_UninstallProducts2012 = {
            return @(
                $mockSqlServerManagementStudio2012_ProductIdentifyingNumber,    # Mock product ADV_SSMS 2008 and ADV_SSMS 2008 R2
                $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber    # Mock product SSMS 2014
            )
        }

        $mockGetItemProperty_UninstallProducts2014 = {
            return @(
                $mockSqlServerManagementStudio2014_ProductIdentifyingNumber,    # Mock product SSMS 2012
                $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber     # Mock product ADV_SSMS 2014
            )
        }

        $mockGetItemProperty_UninstallProducts = {
            return @(
                $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber,  # Mock product SSMS 2008 and SSMS 2008 R2
                $mockSqlServerManagementStudio2012_ProductIdentifyingNumber,    # Mock product ADV_SSMS 2008 and ADV_SSMS 2008 R2
                $mockSqlServerManagementStudio2014_ProductIdentifyingNumber,    # Mock product SSMS 2012
                $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber,  # Mock product ADV_SSMS 2012
                $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber,    # Mock product SSMS 2014
                $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber     # Mock product ADV_SSMS 2014
            )
        }

        $mockGetCimInstance_DefaultInstance_DatabaseService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_AgentService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_FullTextService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_ReportingService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_IntegrationService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockDefaultInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_DefaultInstance_AnalysisService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetService_DefaultInstance = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FullTextServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_ReportingServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockDefaultInstance_IntegrationServiceName -f $mockCurrentSqlMajorVersion) -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AnalysisServiceName -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_DatabaseService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_DatabaseServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_AgentService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AgentServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockAgentServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_FullTextService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_FullTextServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_ReportingService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_ReportingServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_IntegrationService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockNamedInstance_IntegrationServiceName -f $mockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_NamedInstance_AnalysisService = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AnalysisServiceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value $mockSqlServiceAccount -PassThru -Force
                )
            )
        }

        $mockGetService_NamedInstance = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_DatabaseServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AgentServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_FullTextServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_ReportingServiceName -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockNamedInstance_IntegrationServiceName -f $mockCurrentSqlMajorVersion) -PassThru -Force
                ),
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AnalysisServiceName -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ConfigurationState = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'SQL_Replication_Core_Inst' -Value 1 -PassThru -Force
                )
            )
        }

        $mockRegistryPathSqlInstanceId = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
        $mockRegistryPathAnalysisServicesInstanceId = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\OLAP'
        $mockGetItemProperty_SqlInstanceId = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name $mockCurrentInstanceName -Value $mockCurrentDatabaseEngineInstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SqlInstanceId_ParameterFilter = {
            $Path -eq $mockRegistryPathSqlInstanceId -and
            $Name -eq $mockCurrentInstanceName
        }

        $mockGetItemProperty_AnalysisServicesInstanceId = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name $mockCurrentInstanceName -Value $mockCurrentAnalysisServiceInstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter = {
            $Path -eq $mockRegistryPathAnalysisServicesInstanceId -and
            $Name -eq $mockCurrentInstanceName
        }

        $mockGetItemProperty_DatabaseEngineSqlBinRoot = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'SQLBinRoot' -Value $mockCurrentDatabaseEngineSqlBinDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\setup" -and
            $Name -eq 'SQLBinRoot'
        }

        $mockGetItemProperty_AnalysisServicesSqlBinRoot = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'SQLBinRoot' -Value $mockCurrentAnalysisServicesSqlBinDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockCurrentAnalysisServiceInstanceId\setup" -and
            $Name -eq 'SQLBinRoot'
        }

        $mockGetItemProperty_IntegrationsServicesSqlPath = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'SQLPath' -Value $mockCurrentIntegrationServicesSqlPathDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\setup" -and
            $Name -eq 'SQLPath'
        }

        $mockGetItemProperty_SharedDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name '28A1158CDF9ED6B41B2B7358982D4BA8' -Value $mockSqlSharedDirectory -PassThru -Force
                )
            )
        }

        $mockGetItem_SharedDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Property' -Value '28A1158CDF9ED6B41B2B7358982D4BA8' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SharedWowDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name '28A1158CDF9ED6B41B2B7358982D4BA8' -Value $mockSqlSharedWowDirectory -PassThru -Force
                )
            )
        }

        $mockGetItem_SharedWowDirectory = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Property' -Value '28A1158CDF9ED6B41B2B7358982D4BA8' -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_Setup = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'SqlProgramDir' -Value $mockSqlProgramDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ServicesAnalysis = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'ImagePath' -Value ('"C:\Program Files\Microsoft SQL Server\OLAP\bin\msmdsrv.exe" -s "{0}"' -f $mockSqlAnalysisConfigDirectory) -PassThru -Force
                )
            )
        }

        $mockGetNetFirewallRule = {
            return @(
                (
                    New-CimInstance -ClassName 'MSFT_NetFirewallRule' -Property @{
                        'DisplayName' = $DisplayName
                        'Enabled' = $true
                        'Profile' = 'Any'
                        'Direction' = 1 # 1 = Inbound, 2 = Outbound
                    } -Namespace 'root/standardcimv2' -ClientOnly
                )
            )
        }

        $mockGetNetFirewallApplicationFilter = {
            if ($AssociatedNetFirewallRule.DisplayName -eq "SQL Server Database Engine instance $mockCurrentInstanceName")
            {
                return @(
                    (
                        New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Program' -Value (Join-Path $mockCurrentDatabaseEngineSqlBinDirectory -ChildPath $mockDatabaseEngineExecutableName) -PassThru -Force
                    )
                )
            }
            elseif ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Integration Services Application')
            {
                return @(
                    (
                        New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Program' -Value (Join-Path -Path (Join-Path $mockCurrentIntegrationServicesSqlPathDirectory -ChildPath 'Binn') -ChildPath $mockIntegrationServicesExecutableName) -PassThru -Force
                    )
                )
            }
            else
            {
                throw "Mock Get-NetFirewallApplicationFilter was called with a rule containing an unknown display name; $($AssociatedNetFirewallRule.DisplayName)"
            }
        }

        $mockGetNetFirewallServiceFilter = {
            if ($AssociatedNetFirewallRule.DisplayName -eq "SQL Server Analysis Services instance $mockCurrentInstanceName")
            {
                return @(
                    (
                        New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Service' -Value $mockCurrentSqlAnalysisServiceName -PassThru -Force
                    )
                )
            }
            elseif ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Browser')
            {
                return @(
                    (
                        New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Service' -Value $mockSQLBrowserServiceName -PassThru -Force
                    )
                )
            }
            else
            {
                throw "Mock Get-NetFirewallServiceFilter was called with a rule containing an unknown display name; $($AssociatedNetFirewallRule.DisplayName)"
            }
        }

        $mockGetNetFirewallPortFilter = {
            if ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Reporting Services 80')
            {
                return @(
                    (
                        New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $mockFirewallRulePort_ReportingServicesNoSslProtocol -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'LocalPort' -Value $mockFirewallRulePort_ReportingServicesNoSslLocalPort -PassThru -Force
                    )
                )
            }
            elseif ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Reporting Services 443')
            {
                return @(
                    (
                        New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $mockFirewallRulePort_ReportingServicesSslProtocol -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'LocalPort' -Value $mockFirewallRulePort_ReportingServicesSslLocalPort -PassThru -Force
                    )
                )
            }
            elseif ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Integration Services Port')
            {
                return @(
                    (
                        New-Object Object |
                            Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $mockFirewallRulePort_IntegrationServicesProtocol -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'LocalPort' -Value $mockFirewallRulePort_IntegrationServicesLocalPort -PassThru -Force
                    )
                )
            }
            else
            {
                throw "Mock Get-NetFirewallPortFilter was called with a rule containing an unknown display name; $($AssociatedNetFirewallRule.DisplayName)"
            }
        }

        $mockGetNewNetFirewallRule = {
            if (
                (
                    $DisplayName -eq "SQL Server Database Engine instance $mockCurrentInstanceName" -and
                    $Application -eq (Join-Path $mockCurrentDatabaseEngineSqlBinDirectory -ChildPath $mockDatabaseEngineExecutableName)
                ) -or
                (
                    $DisplayName -eq 'SQL Server Browser' -and
                    $Service -eq $mockSQLBrowserServiceName
                ) -or
                (
                    $DisplayName -eq "SQL Server Analysis Services instance $mockCurrentInstanceName" -and
                    $Service -eq $mockCurrentSqlAnalysisServiceName
                ) -or
                (
                    $DisplayName -eq "SQL Server Reporting Services 80" -and
                    $Protocol -eq 'TCP' -and
                    $LocalPort -eq 80
                ) -or
                (
                    $DisplayName -eq "SQL Server Reporting Services 443" -and
                    $Protocol -eq 'TCP' -and
                    $LocalPort -eq 443
                ) -or
                (
                    $DisplayName -eq "SQL Server Integration Services Application" -and
                    $Application -eq (Join-Path -Path (Join-Path $mockCurrentIntegrationServicesSqlPathDirectory -ChildPath 'Binn') -ChildPath $mockIntegrationServicesExecutableName)
                ) -or
                (
                    $DisplayName -eq "SQL Server Integration Services Port" -and
                    $Protocol -eq 'TCP' -and
                    $LocalPort -eq 135
                )
            )
            {
                return
            }

            throw "`nMock Get-NewFirewallRule was called with an unexpected rule configuration`n" + `
                    "Display Name: $DisplayName`n" + `
                    "Application: $Application`n" + `
                    "Service: $Service`n" + `
                    "Protocol: $Protocol`n" + `
                    "Local port: $LocalPort`n"
        }

        $mockConnectSQLAnalysis = {
            return @(
                (
                    New-Object Object |
                        Add-Member ScriptProperty ServerProperties  {
                            return @{
                                'CollationName' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisCollation -PassThru -Force )
                                'DataDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisDataDirectory -PassThru -Force )
                                'TempDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisTempDirectory -PassThru -Force )
                                'LogDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisLogDirectory -PassThru -Force )
                                'BackupDir' = @( New-Object Object | Add-Member NoteProperty -Name 'Value' -Value $mockSqlAnalysisBackupDirectory -PassThru -Force )
                            }
                        } -PassThru |
                        Add-Member ScriptProperty Roles  {
                            return @{
                                'Administrators' = @( New-Object Object |
                                    Add-Member ScriptProperty Members {
                                        return New-Object Object |
                                            Add-Member ScriptProperty Name {
                                                return $mockSqlAnalysisAdmins
                                            } -PassThru -Force
                                    } -PassThru -Force
                                ) }
                        } -PassThru -Force
                )
            )
        }

        $mockRobocopyExecutableName = 'Robocopy.exe'
        $mockRobocopyExectuableVersionWithoutUnbufferedIO = '6.2.9200.00000'
        $mockRobocopyExectuableVersionWithUnbufferedIO = '6.3.9600.16384'
        $mockRobocopyExectuableVersion = ''     # Set dynamically during runtime
        $mockRobocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
        $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
        $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'
        $mockRobocopyArgumentUseUnbufferedIO = '/J'
        $mockRobocopyArgumentSourcePath = 'C:\Source\SQL2016'
        $mockRobocopyArgumentDestinationPath = 'D:\Temp'

        $mockGetItem_SqlMajorVersion = {
            return New-Object Object |
                        Add-Member ScriptProperty VersionInfo {
                            return New-Object Object |
                                        Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value ('{0}.0.0000.00000' -f $mockCurrentSqlMajorVersion) -PassThru -Force
                        } -PassThru -Force
        }

        $mockGetItem_SqlMajorVersion_ParameterFilter = {
            $Path -eq $mockCurrentPathToSetupExecutable
        }

        $mockStartProcessExpectedArgument = ''  # Set dynamically during runtime
        $mockStartProcessExitCode = 0  # Set dynamically during runtime

        $mockStartProcess = {
            if ( $ArgumentList -cne $mockStartProcessExpectedArgument )
            {
                throw "Expected arguments was not the same as the arguments in the function call.`nExpected: '$mockStartProcessExpectedArgument' `n But was: '$ArgumentList'"
            }

            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value 0 -PassThru -Force
        }

        $mockStartProcess_WithExitCode = {
            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value $mockStartProcessExitCode -PassThru -Force
        }

        $mockSourcePathUNCWithoutLeaf = '\\server\share'
        $mockSourcePathGuid = 'cc719562-0f46-4a16-8605-9f8a47c70402'
        $mockNewGuid = {
            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'Guid' -Value $mockSourcePathGuid -PassThru -Force
        }

        $mockGetTemporaryFolder = {
            return $mockSourcePathUNC
        }

        <#
        Needed a way to see into the Set-method for the arguments the Set-method is building and sending to 'setup.exe', and fail
        the test if the arguments is different from the expected arguments.
        Solved this by dynamically set the expected arguments before each It-block. If the arguments differs the mock of
        StartWin32Process throws an error message, similiar to what Pester would have reported (expected -> but was).
        #>
        $mockStartWin32ProcessExpectedArgument = '' # Set dynamically during runtime
        $mockStartWin32Process = {
            if ( $Arguments -ne $mockStartWin32ProcessExpectedArgument )
            {
                throw "Expected arguments was not the same as the arguments in the function call.`nExpected: '$mockStartWin32ProcessExpectedArgument' `n But was: '$Arguments'"
            }

            return 'Process started'
        }
        #endregion Function mocks

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            # These are written with both lower-case and upper-case to make sure we support that.
            Features = 'SQLEngine,Rs,As,Is'
            SourceCredential = $mockSourceCredential
        }

        Describe "xSQLServerFirewall\Get-TargetResource" -Tag 'Get' {
            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            BeforeEach {
                # General mocks
                Mock -CommandName Get-Item -ParameterFilter $mockGetItem_SqlMajorVersion_ParameterFilter -MockWith $mockGetItem_SqlMajorVersion -Verifiable

                # Mock SQL Server Database Engine registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_SqlInstanceId -Verifiable

                # Mock SQL Server Analysis Services registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesInstanceId -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_DatabaseEngineSqlBinRoot -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesSqlBinRoot -Verifiable

                # Mock SQL Server Integration Services Registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter `
                    -MockWith $mockGetItemProperty_IntegrationsServicesSqlPath -Verifiable

                Mock -CommandName New-SmbMapping -Verifiable
                Mock -CommandName Remove-SmbMapping -Verifiable
            }

            $testProductVersion | ForEach-Object -Process {
                $mockCurrentSqlMajorVersion = $_

                $mockCurrentPathToSetupExecutable = Join-Path -Path $mockSourcePath -ChildPath $mockSetupExecutableName

                $mockCurrentInstanceName = $mockDefaultInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockDefaultInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"


                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockCurrentSqlMajorVersion. Testing helper function Get-SqlRootPath" {
                    It 'Should return the the correct path for Database Engine' {
                        $result = GetSQLPath -Feature 'SQLEngine' -InstanceName $mockDefaultInstance_InstanceName
                        $result | Should Be $mockCurrentDatabaseEngineSqlBinDirectory

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It
                    }

                    It 'Should return the the correct path for Analysis Services' {
                        $result = GetSQLPath -Feature 'As' -InstanceName $mockDefaultInstance_InstanceName
                        $result | Should Be $mockCurrentAnalysisServicesSqlBinDirectory

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It
                    }

                    It 'Should return the the correct path for Integration Services' {
                        $result = GetSQLPath -Feature 'Is' -InstanceName $mockDefaultInstance_InstanceName -SQLVersion $mockCurrentSqlMajorVersion
                        $result | Should Be $mockCurrentIntegrationServicesSqlPathDirectory

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and there is no components installed" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-FirewallRule -Verifiable
                        Mock -CommandName New-FirewallRule -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.SourcePath | Should Be $testParameters.SourcePath
                    }

                    It 'Should not return any values in the read parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should BeNullOrEmpty
                        $result.BrowserFirewall | Should BeNullOrEmpty
                        $result.ReportingServicesFirewall | Should BeNullOrEmpty
                        $result.AnalysisServicesFirewall | Should BeNullOrEmpty
                        $result.IntegrationServicesFirewall | Should BeNullOrEmpty
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should Be 'Present' # This should actually return 'Absent', but due to a bug it does not. See issue #313.
                        $result.Features | Should BeNullOrEmpty
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName New-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName New-FirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.SourcePath | Should Be $testParameters.SourcePath
                        $result.Features | Should Be $testParameters.Features
                    }

                    It 'Should return $false for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should Be $false
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should Be 'Absent'
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 6 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName New-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName New-FirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.SourcePath | Should Be $testParameters.SourcePath
                    }

                    It 'Should return $true for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should Be $true
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should Be 'Present'
                        $result.Features | Should Be $testParameters.Features
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName New-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                $mockCurrentInstanceName = $mockNamedInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockNamedInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName New-FirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.SourcePath | Should Be $testParameters.SourcePath
                        $result.Features | Should Be $testParameters.Features
                    }

                    It 'Should return $false for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should Be $false
                    }

                    It 'Should return $false for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should Be $false
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should Be 'Absent'
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 6 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName New-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName New-FirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should Be $testParameters.InstanceName
                        $result.SourcePath | Should Be $testParameters.SourcePath
                    }

                    It 'Should return $true for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should Be $true
                    }

                    It 'Should return $true for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should Be $true
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should Be 'Present'
                        $result.Features | Should Be $testParameters.Features
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName New-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe "xSQLServerFirewall\Set-TargetResource" -Tag 'Set' {
            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            BeforeEach {
                # General mocks
                Mock -CommandName Get-Item -ParameterFilter $mockGetItem_SqlMajorVersion_ParameterFilter -MockWith $mockGetItem_SqlMajorVersion -Verifiable

                # Mock SQL Server Database Engine registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_SqlInstanceId -Verifiable

                # Mock SQL Server Analysis Services registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesInstanceId -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_DatabaseEngineSqlBinRoot -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesSqlBinRoot -Verifiable

                # Mock SQL Server Integration Services Registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter `
                    -MockWith $mockGetItemProperty_IntegrationsServicesSqlPath -Verifiable

                Mock -CommandName New-NetFirewallRule -MockWith $mockGetNewNetFirewallRule
                Mock -CommandName New-SmbMapping -Verifiable
                Mock -CommandName Remove-SmbMapping -Verifiable
            }

            $testProductVersion | ForEach-Object -Process {
                $mockCurrentSqlMajorVersion = $_

                $mockCurrentPathToSetupExecutable = Join-Path -Path $mockSourcePath -ChildPath $mockSetupExecutableName

                $mockCurrentInstanceName = $mockDefaultInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockDefaultInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"


                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                # Mock this here because only the first test uses it.
                Mock -CommandName Test-TargetResource -MockWith { return $false }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and there is no components installed" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Get-FirewallRule -Verifiable
                        Mock -CommandName New-FirewallRule -Verifiable

                        Mock New-TerminatingError -MockWith { return $ErrorType }
                    }

                    It 'Should throw the correct error when Set-TargetResource verifies result with Test-TargetResource' {
                        { Set-TargetResource @testParameters } | Should Throw TestFailedAfterSet

                        Assert-MockCalled -CommandName New-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName New-FirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It
                    }
                }

                # Mock this here so the rest of the test uses it.
                Mock -CommandName Test-TargetResource -MockWith { return $true }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should create all firewall rules without throwing' {
                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 14 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 3 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should not call mock New-NetFirewallRule' {
                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                $mockCurrentInstanceName = $mockNamedInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockNamedInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should create all firewall rules without throwing' {
                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 14 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 3 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should not call mock New-NetFirewallRule' {
                        { Set-TargetResource @testParameters } | Should Not Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe "xSQLServerFirewall\Test-TargetResource" -Tag 'Test' {
            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            BeforeEach {
                # General mocks
                Mock -CommandName Get-Item -ParameterFilter $mockGetItem_SqlMajorVersion_ParameterFilter -MockWith $mockGetItem_SqlMajorVersion -Verifiable

                # Mock SQL Server Database Engine registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_SqlInstanceId -Verifiable

                # Mock SQL Server Analysis Services registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesInstanceId -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_DatabaseEngineSqlBinRoot -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesSqlBinRoot -Verifiable

                # Mock SQL Server Integration Services Registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter `
                    -MockWith $mockGetItemProperty_IntegrationsServicesSqlPath -Verifiable

                Mock -CommandName New-SmbMapping -Verifiable
                Mock -CommandName Remove-SmbMapping -Verifiable
            }

            $mockCurrentSqlMajorVersion = $_

            $mockCurrentPathToSetupExecutable = Join-Path -Path $mockSourcePath -ChildPath $mockSetupExecutableName

            $mockCurrentInstanceName = $mockDefaultInstance_InstanceName
            $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
            $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

            $mockCurrentSqlAnalysisServiceName = $mockDefaultInstance_AnalysisServiceName

            $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
            $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
            $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"


            $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
            $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
            $mockSqlTempDatabasePath = ''
            $mockSqlTempDatabaseLogPath = ''
            $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
            $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

            Context "When the system is not in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters.Clone()
                    $testParameters += @{
                        InstanceName = $mockCurrentInstanceName
                        SourcePath = $mockSourcePath
                    }

                    Mock -CommandName Get-NetFirewallRule -Verifiable
                    Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                    Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                    Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                }

                It 'Should return $false from Test-TargetResource' {
                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should Be $false
                }
            }

            Context "When the system is in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters.Clone()
                    $testParameters += @{
                        InstanceName = $mockCurrentInstanceName
                        SourcePath = $mockSourcePath
                    }

                    Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                    Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                    Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                    Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                }

                It 'Should return $true from Test-TargetResource' {
                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should Be $true
                }
            }
        }
   }
}
finally
{
    Invoke-TestCleanup
}
