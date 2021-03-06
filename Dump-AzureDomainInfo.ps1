﻿<#
    File: Dump-AzureDomainInfo.ps1
    Author: Karl Fosaaen (@kfosaaen), NetSPI - 2017
    Description: PowerShell functions for enumerating information from AzureAD/MSOL domains.
#>

# To Do:
#       Add better error handling
#       Add option to disable group dump
#       Add additional AzureRM features/data


#Requires -Modules MSOnline,AzureRM


Function Dump-AzureDomainInfo-MSOL
{
<#
    .SYNOPSIS
        Dumps information from an MSOL domain via authenticated MSOL connection.
    .PARAMETER folder
        The folder to output to.   
    .EXAMPLE
        PS C:\> Dump-AzureDomainInfo -folder Test -Verbose
        VERBOSE: Getting Domain Contact Info...
        VERBOSE: Getting Domains...
        VERBOSE: 4 Domains were found.
        VERBOSE: Getting Domain Users...
        VERBOSE: 200 Domain Users were found across 4 domains.
        VERBOSE: Getting Domain Groups...
        VERBOSE: 90 Domain Groups were found.
        VERBOSE: Getting Domain Users for each group...
        VERBOSE: Domain Group Users were enumerated for 90 groups.
        VERBOSE: Getting Domain Devices...
        VERBOSE: 22 devices were enumerated.
        VERBOSE: Getting Domain Service Principals...
        VERBOSE: 134 service principals were enumerated.
        VERBOSE: All done.

#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Folder to output to.")]
        [string]$folder
    )

    # Folder Parameter Checking
    if ($folder){if(Test-Path $folder){if(Test-Path $folder"\MSOL"){}else{New-Item -ItemType Directory $folder"\MSOL"|Out-Null}}else{New-Item -ItemType Directory $folder|Out-Null ; New-Item -ItemType Directory $folder"\MSOL"|Out-Null}}
    else{if(Test-Path MSOL){}else{New-Item -ItemType Directory MSOL|Out-Null};$folder=".\"}

    # Authenticate to MSOL
    Connect-MsolService

    # Get/Write Company Info
    Write-Verbose "Getting Domain Contact Info..."
    Get-MsolCompanyInformation | Out-File -LiteralPath $folder"\MSOL\DomainCompanyInfo.txt"

    # Get/Write Domains
    Write-Verbose "Getting Domains..."
    $domains = Get-MsolDomain 
    $domains | select  Name,Status,Authentication | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Domains.CSV"
    $domainCount = $domains.Count
    Write-Verbose "$domainCount Domains were found."

    # Get/Write Users for each domain
    Write-Verbose "Getting Domain Users..."
    $userCount=0
    $domains | select  Name | ForEach-Object {$DomainIter=$_.Name; $domainUsers=Get-MsolUser -All -DomainName $DomainIter; $userCount+=$domainUsers.Count; $domainUsers | Select-Object @{Label="Domain"; Expression={$DomainIter}},UserPrincipalName,DisplayName,isLicensed | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\"$DomainIter"_Users.CSV"}
    Write-Verbose "$userCount Domain Users were found across $domainCount domains."

    # Get/Write Groups
    Write-Verbose "Getting Domain Groups..."
    if(Test-Path $folder"\MSOL\Groups"){}
    else{New-Item -ItemType Directory $folder"\MSOL\Groups" | Out-Null}
    $groups = Get-MsolGroup -All -GroupType Security
    $groupCount = $groups.Count
    Write-Verbose "$groupCount Domain Groups were found."
    Write-Verbose "Getting Domain Users for each group..."
    $groups | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Groups.CSV"
    $groups | ForEach-Object {$groupName=$_.DisplayName; Get-MsolGroupMember -All -GroupObjectId $_.ObjectID | Select-Object @{ Label = "Group Name"; Expression={$groupName}}, EmailAddress, DisplayName | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Groups\group_"$groupName"_Users.CSV"}
    Write-Verbose "Domain Group Users were enumerated for $groupCount groups."

    # Get/Write Devices
    Write-Verbose "Getting Domain Devices..."
    $devices = Get-MsolDevice -All 
    $devices | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Domain_Devices.CSV"
    $deviceCount = $devices.Count
    Write-Verbose "$deviceCount devices were enumerated."


    # Get/Write Service Principals
    Write-Verbose "Getting Domain Service Principals..."
    $principals = Get-MsolServicePrincipal -All
    $principals | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Domain_SPNs.CSV"
    $principalCount = $principals.Count
    Write-Verbose "$principalCount service principals were enumerated."


    Write-Verbose "All done with MSOL tasks.`n"
}

Function Dump-AzureDomainInfo-AzureRM
{
<#
    .SYNOPSIS
        Dumps information from an AzureAD domain via authenticated AzureRM connection.
    .PARAMETER folder
        The folder to output to.   
    .EXAMPLE
        PS C:\> Dump-AzureDomainInfo-AzureRM -folder Test -Verbose
        VERBOSE: Getting Domain Users...
        VERBOSE: 200 Domain Users were found.
        VERBOSE: Getting Domain Groups...
        VERBOSE: 150 Domain Groups were found.
        VERBOSE: Getting Domain Users for each group...
        VERBOSE: Domain Group Users were enumerated for 150 groups.
        VERBOSE: Getting Domain Service Principals...
        VERBOSE: 140 service principals were enumerated.
        VERBOSE: All done with AzureRM tasks.

#>

    # AzureRM Functions - https://docs.microsoft.com/en-us/azure/azure-resource-manager/powershell-azure-resource-manager
    # 
    # Get-AzureRmSubscription
    # Get-AzureRmSqlDatabase


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Folder to output to.")]
        [string]$folder
    )

    # Folder Parameter Checking
    if ($folder){if(Test-Path $folder){if(Test-Path $folder"\AzureRM"){}else{New-Item -ItemType Directory $folder"\AzureRM"|Out-Null}}else{New-Item -ItemType Directory $folder|Out-Null ; New-Item -ItemType Directory $folder"\AzureRM"|Out-Null}}
    else{if(Test-Path AzureRM){}else{New-Item -ItemType Directory AzureRM|Out-Null};$folder=".\"}

    # Authenticate to AzureRM
    Login-AzureRmAccount

    # Get TenantId
    $tenantID = Get-AzureRmTenant | select TenantId

    # Get/Write Users for each domain
    Write-Verbose "Getting Domain Users..."
    $userCount=0
    $users=Get-AzureRmADUser 
    $users | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Users.CSV"
    $userCount=$users.Count
    Write-Verbose "$userCount Domain Users were found."

    # Get/Write Groups
    Write-Verbose "Getting Domain Groups..."
    if(Test-Path $folder"\AzureRM\Groups"){}
    else{New-Item -ItemType Directory $folder"\AzureRM\Groups" | Out-Null}
    $groups=Get-AzureRmADGroup
    $groupCount = $groups.Count
    Write-Verbose "$groupCount Domain Groups were found."
    Write-Verbose "Getting Domain Users for each group..."
    $groups | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Groups.CSV"
    $groups | ForEach-Object {$groupName=$_.DisplayName; Get-AzureRmADGroupMember -GroupObjectId $_.Id | Select-Object @{ Label = "Group Name"; Expression={$groupName}}, DisplayName | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Groups\group_"$groupName"_Users.CSV"}
    Write-Verbose "Domain Group Users were enumerated for $groupCount groups."

    #Get-​Azure​Rm​AD​Application
    # TBD
    
    # Get/Write Service Principals
    Write-Verbose "Getting Domain Service Principals..."
    $principals = Get-AzureRmADServicePrincipal
    $principals | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Domain_SPNs.CSV"
    $principalCount = $principals.Count
    Write-Verbose "$principalCount service principals were enumerated."
    

    Write-Verbose "All done with AzureRM tasks.`n"
}

Function Dump-AzureDomainInfo-All
{
    
        [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Folder to output to.")]
        [string]$folder
    )
    if($folder){
        Dump-AzureDomainInfo-MSOL -folder $folder
        Dump-AzureDomainInfo-AzureRM -folder $folder
    }
    else{
        Dump-AzureDomainInfo-MSOL
        Dump-AzureDomainInfo-AzureRM
    }
}