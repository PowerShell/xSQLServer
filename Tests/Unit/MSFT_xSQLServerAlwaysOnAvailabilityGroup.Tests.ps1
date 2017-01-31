$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerAlwaysOnAvailabilityGroup'

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

# Loading stub cmdlets
Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

$defaultAbsentParameters = @{
    Name = 'AbsentAG'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Present'
    AutomatedBackupPreference = 'Secondary'
    AvailabilityMode = 'AsynchronousCommit'
    BackupPriority = 50
    BasicAvailabilityGroup = $false
    ConnectionModeInPrimaryRole = 'AllowAllConnections'
    ConnectionModeInSecondaryRole = 'AllowNoConnections'
    FailureConditionLevel = 'OnServerDown'
    FailoverMode = 'Manual'
    HealthCheckTimeout = '30000'
    EndpointHostName = 'Server1'
}

$defaultPresentParameters = @{
    Name = 'PresentAG'
    SQLInstanceName = 'MSSQLSERVER'
    SQLServer = 'Server1'
    Ensure = 'Present'
    AutomatedBackupPreference = 'Secondary'
    AvailabilityMode = 'AsynchronousCommit'
    BackupPriority = 50
    BasicAvailabilityGroup = $false
    ConnectionModeInPrimaryRole = 'AllowAllConnections'
    ConnectionModeInSecondaryRole = 'AllowNoConnections'
    FailureConditionLevel = 'OnServerDown'
    FailoverMode = 'Manual'
    HealthCheckTimeout = '30000'
    EndpointHostName = 'Server1'
}

$mockConnectSqlVersion12 = {
    $mock = New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                PrimaryReplicaServerName = 'Server1'
                LocalReplicaRole = 'Primary'
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointUrl = 'TCP://Server1:5022'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Databases = @{
            'master' = @{
                Name = 'master'
            }
        }
        Endpoints = @(
            New-Object PSObject -Property @{
                EndpointType = 'DatabaseMirroring'
                Protocol = @{
                    TCP = @{
                        ListenerPort = 5022
                    }
                }
            }
        )
        IsHadrEnabled = $true
        Logins = @{
            'NT SERVICE\ClusSvc' = @{}
            'NT AUTHORITY\SYSTEM' = @{}
        }
        Name = 'Server1'
        NetName = 'Server1'
        Roles = @{}
        Version = @{
            Major = 12
        }
    }

    # Add the ExecuteWithResults method
    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
        return New-Object PSObject -Property @{
            Tables = @{
                Rows = @{
                    permission_name = @(
                        'testing'
                    )
                }
            }
        }
    }

    # Type the mock as a server object
    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

    return $mock
}

$mockConnectSqlVersion12IncorrectEndpointProtocol = {
    $mock = New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                PrimaryReplicaServerName = 'Server1'
                LocalReplicaRole = 'Primary'
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointUrl = 'UDP://Server1:5022'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Databases = @{
            'master' = @{
                Name = 'master'
            }
        }
        Endpoints = @(
            New-Object PSObject -Property @{
                EndpointType = 'DatabaseMirroring'
                Protocol = @{
                    TCP = @{
                        ListenerPort = 5022
                    }
                }
            }
        )
        IsHadrEnabled = $true
        Logins = @{
            'NT SERVICE\ClusSvc' = @{}
            'NT AUTHORITY\SYSTEM' = @{}
        }
        Name = 'Server1'
        NetName = 'Server1'
        Roles = @{}
        Version = @{
            Major = 12
        }
    }

    # Add the ExecuteWithResults method
    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
        return New-Object PSObject -Property @{
            Tables = @{
                Rows = @{
                    permission_name = @(
                        'testing'
                    )
                }
            }
        }
    }

    # Type the mock as a server object
    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

    return $mock
}

$mockConnectSqlVersion12IncorrectEndpointPort = {
    $mock = New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                PrimaryReplicaServerName = 'Server1'
                LocalReplicaRole = 'Primary'
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointUrl = 'TCP://Server1:1000'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Databases = @{
            'master' = @{
                Name = 'master'
            }
        }
        Endpoints = @(
            New-Object PSObject -Property @{
                EndpointType = 'DatabaseMirroring'
                Protocol = @{
                    TCP = @{
                        ListenerPort = 5022
                    }
                }
            }
        )
        IsHadrEnabled = $true
        Logins = @{
            'NT SERVICE\ClusSvc' = @{}
            'NT AUTHORITY\SYSTEM' = @{}
        }
        Name = 'Server1'
        NetName = 'Server1'
        Roles = @{}
        Version = @{
            Major = 12
        }
    }

    # Add the ExecuteWithResults method
    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
        return New-Object PSObject -Property @{
            Tables = @{
                Rows = @{
                    permission_name = @(
                        'testing'
                    )
                }
            }
        }
    }

    # Type the mock as a server object
    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

    return $mock
}

$mockConnectSqlVersion13 = {
    $mock = New-Object PSObject -Property @{
        AvailabilityGroups = @{
            PresentAG = @{
                AutomatedBackupPreference = 'Secondary'
                FailureConditionLevel = 'OnServerDown'
                HealthCheckTimeout = 30000
                Name = 'AvailabilityGroup1'
                BasicAvailabilityGroup = $false
                PrimaryReplicaServerName = 'Server1'
                LocalReplicaRole = 'Primary'
                AvailabilityReplicas = @{
                    Server1 = @{
                        AvailabilityMode = 'AsynchronousCommit'
                        BackupPriority = 50
                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointUrl = 'TCP://Server1:5022'
                        FailoverMode = 'Manual'
                    }
                }
            }
        }
        Databases = @{
            'master' = @{
                Name = 'master'
            }
        }
        Endpoints = @(
            New-Object PSObject -Property @{
                EndpointType = 'DatabaseMirroring'
                Protocol = @{
                    TCP = @{
                        ListenerPort = 5022
                    }
                }
            }
        )
        IsHadrEnabled = $true
        Logins = @{
            'NT SERVICE\ClusSvc' = @{}
            'NT AUTHORITY\SYSTEM' = @{}
        }
        Name = 'Server1'
        NetName = 'Server1'
        Roles = @{}
        Version = @{
            Major = 13
        }
    }

    # Add the ExecuteWithResults method
    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
        return New-Object PSObject -Property @{
            Tables = @{
                Rows = @{
                    permission_name = @(
                        'testing'
                    )
                }
            }
        }
    }

    # Type the mock as a server object
    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

    return $mock
}

$mockNewSqlAvailabilityReplica = {
    #TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    $mock = return New-Object PSObject -Property @{
        AvailabilityMode = 'AsynchronousCommit'
        BackupPriority = 50
        ConnectionModeInPrimaryRole = 'AllowAllConnections'
        ConnectionModeInSecondaryRole = 'AllowNoConnections'
        EndpointUrl = 'TCP://Server1:5022'
        FailoverMode = 'Manual'
        Name = 'Server1'
    }

    # Type the mock as an Availability Replica object
    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.AvailabilityReplica')

    return $mock
}

$mockInvokeQueryClusterServiceCorrectPermissions = {
    return New-Object PSObject -Property @{
        Tables = @{
            Rows = @{
                permission_name = @(
                    'Connect SQL',
                    'Alter Any Availability Group',
                    'View Server State'
                )
            }
        }
    }
}

$mockInvokeQueryClusterServiceMissingPermissions = {
    return New-Object PSObject -Property @{
        Tables = @{
            Rows = @{
                permission_name = @(
                    'Connect SQL',
                    'View Server State'
                )
            }
        }
    }
}

# Begin Testing
try
{
    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        
        Context 'When the Availability Group is Absent'{

            It 'Should not return an Availability Group when Ensure is set to Present and the version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $defaultAbsentParameters.Name
                    SQLServer = $defaultAbsentParameters.SQLServer
                    SQLInstanceName = $defaultAbsentParameters.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should not return an Availability Group when Ensure is set to Present and the version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $defaultAbsentParameters.Name
                    SQLServer = $defaultAbsentParameters.SQLServer
                    SQLInstanceName = $defaultAbsentParameters.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Ensure | Should Be 'Absent'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        Context 'When the Availability Group is Present'{

            It 'Should return the correct Availability Group properties when Ensure is set to Present and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $getParams = @{
                    Name = $defaultPresentParameters.Name
                    SQLServer = $defaultPresentParameters.SQLServer
                    SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $defaultPresentParameters.Name
                $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return the correct Availability Group properties when Ensure is set to Absent and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $defaultPresentParameters.Name
                    SQLServer = $defaultPresentParameters.SQLServer
                    SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $defaultPresentParameters.Name
                $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return the correct Availability Group properties when Ensure is set to Present and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $getParams = @{
                    Name = $defaultPresentParameters.Name
                    SQLServer = $defaultPresentParameters.SQLServer
                    SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $defaultPresentParameters.Name
                $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Not Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should return the correct Availability Group properties when Ensure is set to Absent and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $getParams = @{
                    Name = $defaultPresentParameters.Name
                    SQLServer = $defaultPresentParameters.SQLServer
                    SQLInstanceName = $defaultPresentParameters.SQLInstanceName
                }
                
                # Get the current state
                $result = Get-TargetResource @getParams

                $result.Name | Should Be $defaultPresentParameters.Name
                $result.SQLServer | Should Be $defaultPresentParameters.SQLServer
                $result.SQLInstanceName | Should Be $defaultPresentParameters.SQLInstanceName
                $result.Ensure | Should Be 'Present'
                $result.AutomatedBackupPreference | Should Not Be $null
                $result.AvailabilityMode | Should Not Be $null
                $result.BackupPriority | Should Not Be $null
                $result.ConnectionModeInPrimaryRole | Should Not Be $null
                $result.ConnectionModeInSecondaryRole | Should Not Be $null
                $result.FailureConditionLevel | Should Not Be $null
                $result.FailoverMode | Should Not Be $null
                $result.HealthCheckTimeout | Should Not Be $null
                $result.BasicAvailabilityGroup | Should Not Be $null

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        
        Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName Import-SQLPSModule -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
        Mock -CommandName New-TerminatingError { $ErrorType } -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the Availability Group is Absent' {

            Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroupReplica -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            
            It 'Should create the Availability Group when Ensure is set to Present and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'

                { Set-TargetResource @defaultAbsentParameters } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should create the Availability Group when Ensure is set to Present and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'
                $defaultAbsentParameters.BasicAvailabilityGroup = $true

                { Set-TargetResource @defaultAbsentParameters } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, HadrNotEnabled, when Ensure is set to Present, but Always On is not enabled' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        IsHadrEnabled = $false
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'
                
                { Set-TargetResource @defaultAbsentParameters } | Should Throw 'HadrNotEnabled'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should create the Availability Group when Ensure is set to Present and NT AUTHORITY\SYSTEM has the correct permissions' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceMissingPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' } -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT AUTHORITY\\SYSTEM' } -Scope It
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'

                { Set-TargetResource @defaultAbsentParameters } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT AUTHORITY\\SYSTEM' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
            
            It 'Should throw the correct error, ClusterPermissionsMissing, when Ensure is set to Present, but the cluster does not have the correct permissions' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceMissingPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' } -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceMissingPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT AUTHORITY\\SYSTEM' } -Scope It
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'
                
                { Set-TargetResource @defaultAbsentParameters } | Should Throw 'ClusterPermissionsMissing'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT AUTHORITY\\SYSTEM' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, DatabaseMirroringEndpointNotFound, when Ensure is set to Present, but no DatabaseMirroring endpoints are present' {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        AvailabilityGroups = @()
                        Endpoints = @()
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                        }
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'
                
                { Set-TargetResource @defaultAbsentParameters } | Should Throw 'DatabaseMirroringEndpointNotFound'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
            
            It 'Should throw the correct error, CreateAvailabilityGroupReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 12' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith { throw 'CreateAvailabilityGroupReplicaFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'
                
                { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error, CreateAvailabilityGroupReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 13' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityReplica -MockWith { throw 'CreateAvailabilityGroupReplicaFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'
                
                { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 12' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityGroup { throw 'CreateAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Test-TargetResource -MockWith {$false} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'
                
                { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 13' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName New-SqlAvailabilityGroup { throw 'CreateAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Test-TargetResource -MockWith {$false} -ModuleName $script:DSCResourceName -Scope It
                
                $defaultAbsentParameters.Ensure = 'Present'

                { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupFailed'
                
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }

        Context 'When the Availability Group is Present' {
            Mock -CommandName New-SqlAvailabilityGroup {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            Mock -CommandName Update-AvailabilityGroupReplica -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope Context
            
            It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultPresentParameters.Ensure = 'Absent'
                
                { Set-TargetResource @defaultPresentParameters } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultPresentParameters.Ensure = 'Absent'
                
                { Set-TargetResource @defaultPresentParameters } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error message, InstanceNotPrimaryReplica, when Ensure is set to Absent and the primary replica is not on the current instance' {

                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object PSObject -Property @{ 
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplicaServerName = 'Server1'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server1:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        IsHadrEnabled = $true
                        NetName = 'Server2'
                    }
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultPresentParameters.Ensure = 'Absent'
                
                { Set-TargetResource @defaultPresentParameters } | Should Throw 'InstanceNotPrimaryReplica'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 12' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith { throw 'RemoveAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultPresentParameters.Ensure = 'Absent'
                
                { Set-TargetResource @defaultPresentParameters } | Should Throw 'RemoveAvailabilityGroupFailed'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 13' {
                
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith {} -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith { throw 'RemoveAvailabilityGroupFailed' } -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                $defaultPresentParameters.Ensure = 'Absent'
                
                { Set-TargetResource @defaultPresentParameters } | Should Throw 'RemoveAvailabilityGroupFailed'

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should connect to the instance hosting the primary replica when the LocalReplicaRole is not Primary' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplicaServerName = 'Server2'
                                LocalReplicaRole = 'Secondary'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server1:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
                        }
                        Name = 'Server1'
                        NetName = 'Server1'
                        Roles = @{}
                        Version = @{
                            Major = 12
                        }
                    }

                    # Add the ExecuteWithResults method
                    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
                        return New-Object PSObject -Property @{
                            Tables = @{
                                Rows = @{
                                    permission_name = @(
                                        'testing'
                                    )
                                }
                            }
                        }
                    }

                    # Type the mock as a server object
                    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                
                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplicaServerName = 'Server2'
                                LocalReplicaRole = 'Primary'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server2:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
                        }
                        Name = 'Server1'
                        NetName = 'Server1'
                        Roles = @{}
                        Version = @{
                            Major = 12
                        }
                    }

                    # Add the ExecuteWithResults method
                    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
                        return New-Object PSObject -Property @{
                            Tables = @{
                                Rows = @{
                                    permission_name = @(
                                        'testing'
                                    )
                                }
                            }
                        }
                    }

                    # Type the mock as a server object
                    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server2' }
                
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq 'Server2' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }
            
            It 'Should set the AutomatedBackupPreference to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.AutomatedBackupPreference = 'Primary'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should set the AvailabilityMode to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.AvailabilityMode = 'SynchronousCommit'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the BackupPriority to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.BackupPriority = 42
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the BasicAvailabilityGroup to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.BasicAvailabilityGroup = $true
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should set the ConnectionModeInPrimaryRole to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.ConnectionModeInPrimaryRole = 'AllowReadWriteConnections'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the ConnectionModeInSecondaryRole to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the endpoint port is changed' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplicaServerName = 'Server1'
                                LocalReplicaRole = 'Primary'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server1:5021'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
                        }
                        Name = 'Server1'
                        NetName = 'Server1'
                        Roles = @{}
                        Version = @{
                            Major = 12
                        }
                    }

                    # Add the ExecuteWithResults method
                    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
                        return New-Object PSObject -Property @{
                            Tables = @{
                                Rows = @{
                                    permission_name = @(
                                        'testing'
                                    )
                                }
                            }
                        }
                    }

                    # Type the mock as a server object
                    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the EndpointHostName is specified' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.EndpointHostName = 'TestServer.Contoso.com'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the EndpointHostName is not specified' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplicaServerName = 'Server1'
                                LocalReplicaRole = 'Primary'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'TCP://Server1.contoso.com:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
                        }
                        Name = 'Server1'
                        NetName = 'Server1'
                        Roles = @{}
                        Version = @{
                            Major = 12
                        }
                    }

                    # Add the ExecuteWithResults method
                    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
                        return New-Object PSObject -Property @{
                            Tables = @{
                                Rows = @{
                                    permission_name = @(
                                        'testing'
                                    )
                                }
                            }
                        }
                    }

                    # Type the mock as a server object
                    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.Remove('EndpointHostName')
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the EndpointUrl to the desired state when the endpoint protocol is changed' {

                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object PSObject -Property @{
                        AvailabilityGroups = @{
                            PresentAG = @{
                                AutomatedBackupPreference = 'Secondary'
                                FailureConditionLevel = 'OnServerDown'
                                HealthCheckTimeout = 30000
                                Name = 'AvailabilityGroup1'
                                PrimaryReplicaServerName = 'Server1'
                                LocalReplicaRole = 'Primary'
                                AvailabilityReplicas = @{
                                    Server1 = @{
                                        AvailabilityMode = 'AsynchronousCommit'
                                        BackupPriority = 50
                                        ConnectionModeInPrimaryRole = 'AllowAllConnections'
                                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                                        EndpointUrl = 'HTTP://Server1:5022'
                                        FailoverMode = 'Manual'
                                    }
                                }
                            }
                        }
                        Databases = @{
                            'master' = @{
                                Name = 'master'
                            }
                        }
                        Endpoints = @(
                            New-Object PSObject -Property @{
                                EndpointType = 'DatabaseMirroring'
                                Protocol = @{
                                    TCP = @{
                                        ListenerPort = 5022
                                    }
                                }
                            }
                        )
                        IsHadrEnabled = $true
                        Logins = @{
                            'NT SERVICE\ClusSvc' = @{}
                            'NT AUTHORITY\SYSTEM' = @{}
                        }
                        Name = 'Server1'
                        NetName = 'Server1'
                        Roles = @{}
                        Version = @{
                            Major = 12
                        }
                    }

                    # Add the ExecuteWithResults method
                    $mock.Databases['master'] | Add-Member -MemberType ScriptMethod -Name ExecuteWithResults -Value {
                        return New-Object PSObject -Property @{
                            Tables = @{
                                Rows = @{
                                    permission_name = @(
                                        'testing'
                                    )
                                }
                            }
                        }
                    }

                    # Type the mock as a server object
                    $mock.PSObject.TypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')

                    return $mock
                } -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the FailureConditionLevel to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.FailureConditionLevel = 'OnAnyQualifiedFailureCondition'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }

            It 'Should set the FailoverMode to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It -ParameterFilter { $SQLServer -eq 'Server1' }
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.FailoverMode = 'Automatic'
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
            }

            It 'Should set the HealthCheckTimeout to the desired state' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                Mock -CommandName Invoke-Query -MockWith $mockInvokeQueryClusterServiceCorrectPermissions -ModuleName $script:DSCResourceName -Verifiable -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                
                $defaultPresentParametersIncorrectProperties = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectProperties.Ensure = 'Present'
                $defaultPresentParametersIncorrectProperties.HealthCheckTimeout = 42
                
                { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Invoke-Query -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        
        Context 'When the Availability Group is Absent' {

            It 'Should be $false when the desired state is Present and the SQL version is 12' {

                $defaultAbsentParameters.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @defaultAbsentParameters | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Absent and the SQL version is 12' {

                $defaultAbsentParameters.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                Test-TargetResource @defaultAbsentParameters | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Present and the SQL version is 13' {

                $defaultAbsentParameters.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @defaultAbsentParameters | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Absent and the SQL version is 13' {

                $defaultAbsentParameters.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                Test-TargetResource @defaultAbsentParameters | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }

        Context 'When the Availability Group is Present' {

            It 'Should be $false when the desired state is Absent and the SQL version is 12' {

                $defaultPresentParameters.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @defaultPresentParameters | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Present and the SQL version is 12' {
                
                $defaultPresentParameters.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @defaultPresentParameters | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Present, there is a parameter not correctly set, and the SQL version is 12' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                $defaultPresentParametersIncorrectParameter.AvailabilityMode = 'SynchronousCommit'
                
                Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Absent and the SQL version is 13' {

                $defaultPresentParameters.Ensure = 'Absent'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @defaultPresentParameters | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Present and the SQL version is 13' {
                
                $defaultPresentParameters.Ensure = 'Present'
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @defaultPresentParameters | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Present, there is a parameter not correctly set, and the SQL version is 13' {

                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion13 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                $defaultPresentParametersIncorrectParameter.AvailabilityMode = 'SynchronousCommit'
                $defaultPresentParametersIncorrectParameter.BasicAvailabilityGroup = $true
                
                Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $true when the desired state is Present and the Endpoint Host Name is not specified' {
                $defaultPresentParametersEndpointHostNameNotSpecified = $defaultPresentParameters.Clone()
                $defaultPresentParametersEndpointHostNameNotSpecified.Ensure = 'Present'
                $defaultPresentParametersEndpointHostNameNotSpecified.Remove('EndpointHostName')
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It
                
                Test-TargetResource @defaultPresentParametersEndpointHostNameNotSpecified | Should Be $true

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
            
            It 'Should be $false when the desired state is Present and the Endpoint Hostname is incorrectly configured' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12 -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                $defaultPresentParametersIncorrectParameter.EndpointHostName = 'server1.contoso.com'
                
                Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Present and the Endpoint Protocol is incorrectly configured' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12IncorrectEndpointProtocol -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                
                Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }

            It 'Should be $false when the desired state is Present and the Endpoint Port is incorrectly configured' {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlVersion12IncorrectEndpointPort -ModuleName $script:DSCResourceName -Verifiable -Scope It

                $defaultPresentParametersIncorrectParameter = $defaultPresentParameters.Clone()
                $defaultPresentParametersIncorrectParameter.Ensure = 'Present'
                
                Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                Assert-MockCalled -ModuleName $script:DSCResourceName -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            }
        }
    }

    InModuleScope -ModuleName $script:DSCResourceName {
        Describe "$($script:DSCResourceName)\Update-AvailabilityGroup" {
            Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -ModuleName $script:DSCResourceName
            
            Context 'When the Availability Group is altered' {
                It 'Should silently alter the Availability Group' {
                    $ag = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    
                    { Update-AvailabilityGroup -AvailabilityGroup $ag } | Should Not Throw

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, AlterAvailabilityGroupFailed, when altering the Availaiblity Group fails' {
                    $ag = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $ag.Name = 'AlterFailed'
                    
                    { Update-AvailabilityGroup -AvailabilityGroup $ag } | Should Throw 'AlterAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe "$($script:DSCResourceName)\Update-AvailabilityGroupReplica" {
            Mock -CommandName New-TerminatingError { $ErrorType } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When the Availability Group Replica is altered' {
                It 'Should silently alter the Availability Group Replica' {
                    $availabilityReplica = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                    
                    { Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica } | Should Not Throw

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, AlterAvailabilityGroupReplicaFailed, when altering the Availaiblity Group Replica fails' {
                    $availabilityReplica = New-Object Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                    $availabilityReplica.Name = 'AlterFailed'
                    
                    { Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica } | Should Throw 'AlterAvailabilityGroupReplicaFailed'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
