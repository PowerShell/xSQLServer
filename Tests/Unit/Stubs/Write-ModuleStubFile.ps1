<#
    .SYNOPSIS
        Generates a file contaning function stubs of all cmdlets from the module given as a parameter.

    .PARAMETER ModuleName
        The name of the module to load and generate stubs from. This module must exist on the computer where this function is run.

    .PARAMETER Path
         Path to where to write the stubs file. The filename will be generated from the module name. The default path is the working directory.

    .EXAMPLE
        Write-ModuleStubFile -ModuleName OperationsManager

    .EXAMPLE
        Write-ModuleStubFile -ModuleName SqlServer -Path C:\Source
#>
function Write-ModuleStubFile
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.IO.DirectoryInfo]
        $Path = ( Get-Location ).Path
    )

    # Import the supplied module
    Import-Module -Name $ModuleName -DisableNameChecking -Force -ErrorAction Stop

    # Get the module object
    $module = Get-Module -Name $ModuleName

    # Define the output file name
    $outFile = Join-Path -Path $Path -ChildPath "$($module.Name )_$($module.Version)_Stubs.psm1"

    # Verify the output file doesn't already exist
    if ( Test-Path -Path $outFile )
    {
        throw "The file '$outFile' already exists."
    }

    # Define the length of the indent
    $indent = ' ' * 4

    # Define the header of the file
    $headerStringBuilder = New-Object -TypeName System.Text.StringBuilder
    [System.Void]$headerStringBuilder.AppendLine('<#')
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.AppendLine('.SYNOPSIS')
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.AppendLine("Cmdlet stubs for the module $($module.Name).")
    [System.Void]$headerStringBuilder.AppendLine()
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.AppendLine('.DESCRIPTION')
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.AppendLine("This module contains the stubs for the cmdlets in the module $($module.Name) version $($module.Version.ToString()).")
    [System.Void]$headerStringBuilder.AppendLine()
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.AppendLine('.NOTES')
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.Append($indent)
    [System.Void]$headerStringBuilder.AppendLine("The stubs in this module were generated from the $($MyInvocation.MyCommand) function which is distributed as part of the SqlServerDsc module.")
    [System.Void]$headerStringBuilder.AppendLine('#>')
    [System.Void]$headerStringBuilder.AppendLine()
    [System.Void]$headerStringBuilder.AppendLine('# Suppressing this rule because these functions are from an external module and are only being used as stubs')
    [System.Void]$headerStringBuilder.AppendLine('[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(''PSAvoidUsingUserNameAndPassWordParams'', '''')]')
    [System.Void]$headerStringBuilder.AppendLine('param()')
    $headerStringBuilder.ToString() | Out-File -FilePath $outFile -Encoding utf8 -Append


    # Get the cmdlets in the module
    $cmdlets = Get-Command -Module $ModuleName -CommandType Cmdlet

    foreach ( $cmdlet in $cmdlets )
    {
        # Clear the alias variable to ensure unnecessary aliases are not created
        Remove-Variable -Name alias -ErrorAction SilentlyContinue

        # Create a string builder object to build the functions
        $functionDefinition = New-Object -TypeName System.Text.StringBuilder

        # Reset the end of definition variable
        $endOfDefinition = $false

        # Get the Cmdlet metadata
        $metadata = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList $cmdlet

        # Get the definition of the cmdlet
        $definition = [System.Management.Automation.ProxyCommand]::Create($metadata)

        # Define the beginning of the function
        [System.Void]$functionDefinition.AppendLine("function $($cmdlet.Name)")
        [System.Void]$functionDefinition.AppendLine('{')


        # Iterate over each line in the cmdlet
        foreach ( $line in $definition.Split([System.Environment]::NewLine) )
        {
            # Reset variables which are used to determine what kind of line this is currently on
            $endOfParameter = $false
            $formatParam = $false

            # Make the objects generic to better support mocking
            $line = $line -replace '\[Microsoft.[\d\w\.]+\]', '[System.Object]'
            $line = $line -replace 'SupportsShouldProcess=\$true, ', ''

            # Determine if any line modifications need to be made
            switch -Regex ( $line.TrimEnd() )
            {
                # Last line of param section
                '\}\)$'
                {
                    $line = $line -replace '\}\)(\s+)?$','}'
                    $endOfDefinition = $true
                }

                # Last line of a parameter definition
                ',$'
                {
                    $endOfParameter = $true
                }

                # Format Param line
                'param\($'
                {
                    $line = $line -replace 'param\(','param'
                    $formatParam = $true
                }
            }

            # Write the current line with an indent
            if ( -not [System.String]::IsNullOrEmpty($line.Trim()) )
            {
                [System.Void]$functionDefinition.Append($indent)
                [System.Void]$functionDefinition.AppendLine($line.TrimEnd())
            }

            # Add a blank line after the parameter section
            if ( $endOfParameter )
            {
                [System.Void]$functionDefinition.AppendLine()
            }

            # Move the right paranthesis at the end of the param section to a new line
            if ( $endOfDefinition )
            {
                [System.Void]$functionDefinition.Append($indent)
                [System.Void]$functionDefinition.AppendLine(')')
                break
            }

            # Move the left parenthesis to the next line after the "param" keyword
            if ( $formatParam )
            {
                [System.Void]$functionDefinition.Append($indent)
                [System.Void]$functionDefinition.AppendLine('(')
            }
        }

        # Build the body of the function
        [System.Void]$functionDefinition.AppendLine()
        [System.Void]$functionDefinition.Append($indent)
        [System.Void]$functionDefinition.AppendLine('throw ''{0}: StubNotImplemented'' -f $MyInvocation.MyCommand')
        [System.Void]$functionDefinition.AppendLine('}')
        [System.Void]$functionDefinition.AppendLine()

        # Find any aliases which may exist for the cmdlet
        $alias = Get-Alias -Definition $cmdlet.Name -ErrorAction SilentlyContinue

        # If any aliases exist
        if ( $alias )
        {
            # Create an alias in the stubs
            [System.Void]$functionDefinition.Append("New-Alias -Name $($alias.DisplayName) -Value $($alias.Definition)")
            [System.Void]$functionDefinition.AppendLine()
        }

        # Export the function text to the file
        $functionDefinition.ToString() | Out-File -FilePath $outFile -Encoding utf8 -Append
    }
}
