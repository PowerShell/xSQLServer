<#
.EXAMPLE
    This example shows how to ensure that the Availability Group Replica 'SQL2' exists in the Availability Group 'TestAG'.

    In the event this is applied to a Failover Cluster Instance (FCI), the
    ProcessOnlyOnActiveNode property will tell the Test-TargetResource function
    to evaluate if any changes are needed if the node is actively hosting the
    SQL Server Instance.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                = '*'
            SQLInstanceName         = 'MSSQLSERVER'
            AvailabilityGroupName   = 'TestAG'
            ProcessOnlyOnActiveNode = $true
        },

        @{
            NodeName = 'SQL1'
            Role     = 'PrimaryReplica'
        },

        @{
            NodeName = 'SQL2'
            Role     = 'SecondaryReplica'
        }
    )
}

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    Node $AllNodes.NodeName
    {
        # Adding the required service account to allow the cluster to log into SQL
        SqlServerLogin AddNTServiceClusSvc
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SQLInstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Add the required permissions to the cluster service login
        SqlServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[SqlServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Create a DatabaseMirroring endpoint
        SqlServerEndpoint HADREndpoint
        {
            EndPointName         = 'HADR'
            Ensure               = 'Present'
            Port                 = 5022
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SQLInstanceName
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlAlwaysOnService EnableHADR
        {
            Ensure               = 'Present'
            InstanceName         = $Node.InstanceName
            ServerName           = $Node.NodeName
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            SqlAG AddTestAG
            {
                Ensure               = 'Present'
                Name                 = $Node.AvailabilityGroupName
                InstanceName         = $Node.SQLInstanceName
                ServerName           = $Node.NodeName
                DependsOn            = '[SqlAlwaysOnService]EnableHADR', '[SqlServerEndpoint]HADREndpoint', '[SqlServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SqlAdministratorCredential
            }
        }

        if ( $Node.Role -eq 'SecondaryReplica' )
        {
            # Add the availability group replica to the availability group
            SqlAGReplica AddReplica
            {
                Ensure                     = 'Present'
                Name                       = $Node.NodeName
                AvailabilityGroupName      = $Node.AvailabilityGroupName
                ServerName                 = $Node.NodeName
                InstanceName               = $Node.SQLInstanceName
                PrimaryReplicaServerName   = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).NodeName
                PrimaryReplicaInstanceName = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).SQLInstanceName
                DependsOn                  = '[SqlAlwaysOnService]EnableHADR'
                ProcessOnlyOnActiveNode    = $Node.ProcessOnlyOnActiveNode
            }
        }
    }
}
