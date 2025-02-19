param (
    [switch]$status
)

## Pre-requisites
## Load the required functions
try {
    ## Dot source functions.ps1
    . "$PSScriptRoot/functions.ps1"

    $functionCheck = Get-Command -Name pslogin, azlogin -CommandType Function -ErrorAction Stop
    
    ## Check if the function exists
    if ($functionCheck) {
    } 
        
    else {
        Write-Host "Functions not found. Check that 'functions.ps1' exists in path '$PSScriptRoot/functions.ps1'" -ForegroundColor Red
    }
} 
    
catch {
    Write-Host "An error occurred. It is not you it is us! There was likely an issue loading functions. Please re-run ensuring that functions.ps1 is found $PSScriptRoot" -ForegroundColor Red
    write-host ""
    Write-host "Error details: " -ForegroundColor Red
    Write-host "**************" -ForegroundColor Red
    Write-host "$_" -ForegroundColor Red
    Pause
    Clear-Host
    exit
}

if ($status) {
    az-status
    exit
}

$azcliinstalledcheck = Get-Command az -ErrorAction SilentlyContinue
$psinstalledcheck = Get-Command connect-azaccount -ErrorAction SilentlyContinue

if (!$azcliinstalledcheck) {
    if (!$IsAdmin.IsInRole([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        write-host "You seem to be missing required modules, You need to run this script as an administrator on first run to install them" -ForegroundColor Red
        exit
    }

    else {
        Write-Host "Azure CLI not found. Would you like to install?" -ForegroundColor Red
        $installresponse = Read-Host "Press 'y' to install or any other key to exit"
    }

    if ($installresponse -eq "y") {
        Write-Host "Installing Azure CLI..." -ForegroundColor Green
        install-azcli

        if (!$psinstalledcheck) {
            Write-Host "Azure PowerShell not found. Would you like to install?" -ForegroundColor Red
            $installresponse = Read-Host "Press 'y' to install or any other key to exit"
        
            if ($installresponse -eq "y") {
                Write-Host "Installing Azure PowerShell..." -ForegroundColor Green
                install-azcli
                Write-Host "Finished. You will need to restart your terminal" -ForegroundColor Green
                exit
            }
        
            else {
                Write-Host "Exiting..." -ForegroundColor Red
                exit
            }
            exit
        }
    }

    else {
        Write-Host "Exiting..." -ForegroundColor Red
        exit
    }
    exit
}

if (!$psinstalledcheck) {
    if (!$IsAdmin.IsInRole([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        write-host "You seem to be missing required modules, You need to run this script as an administrator on first run to install them" -ForegroundColor Red
        exit
    }

    else {
        Write-Host "Azure PowerShell not found. Would you like to install?" -ForegroundColor Red
        $installresponse = Read-Host "Press 'y' to install or any other key to exit"
    }

    if ($installresponse -eq "y") {
        Write-Host "Installing Azure PowerShell..." -ForegroundColor Green
        install-azcli
        Write-Host "Finished. You will need to restart your terminal" -ForegroundColor Green
        exit
    }

    else {
        Write-Host "Exiting..." -ForegroundColor Red
        exit
    }
    exit
}

## Set termloop variable to 0
$termloop = 0

## Main loop
while ($termloop -ne 1) {

    try {
        clear-host
        write-host "Az Switcher - Main Menu" -ForegroundColor Cyan
        write-host "***********************" -ForegroundColor Cyan
        write-host ""
        ## Call az-status function
        az-status

        write-host ""
        Write-Host "To change azcli, enter" -NoNewline; write-host " '1'" -ForegroundColor blue
        Write-Host "To change PowerShell, enter" -NoNewline; write-host " '2'" -ForegroundColor blue
        Write-Host "To exit, enter" -NoNewline; write-host " '0'" -ForegroundColor red
        write-host ""
        $sbName = Read-Host "Select an option to continue"
    
        ## Azcli menu
        if ($sbName -eq 1) {
            clear-host
            write-host "Change azcli Tenant/Subscription" -ForegroundColor Cyan
            write-host "********************************" -ForegroundColor Cyan
            write-host ""
            Write-Host "To change Tenant, enter" -NoNewline; write-host " '1'" -ForegroundColor blue
            Write-Host "To change Subscription, enter" -NoNewline; write-host " '2'" -ForegroundColor blue
            Write-Host "To exit to main menu, enter" -NoNewline; write-host " '0'" -ForegroundColor red
            write-host ""
            $sbName = Read-Host "Select an option to continue"

            if ($sbName -eq 1) {
                ## Execute the function 'azlogin'
                azlogin
                $azsub = az account show --query name -o tsv #Get current azcli subscription
                $aztenant = az account show --query tenantId -o tsv #Get current tenant for azcli
                $tenantfriendlyname = az rest --method GET --uri https://management.azure.com/tenants?api-version=2020-01-01 --query "value[?tenantId=='$aztenant'].{TenantId:tenantId, DisplayName:displayName}" --output tsv
                $splitname = $tenantfriendlyname -split "`t"
            }

            elseif ($sbName -eq 2) {
                ## Execute the function 'get-subscription'
                Write-host "Function currently unavailable. Please select option 1 to change subscription" -ForegroundColor Red
                pause
            }
        }

        ## Powershell menu
        elseif ($sbName -eq 2) {
            clear-host
            write-host "Change PowerShell Tenant/Subscription" -ForegroundColor Cyan
            write-host "*************************************" -ForegroundColor Cyan
            write-host ""
            Write-Host "To change Tenant, enter" -NoNewline; write-host " '1'" -ForegroundColor blue
            Write-Host "To change Subscription, enter" -NoNewline; write-host " '2'" -ForegroundColor blue
            Write-Host "To exit to main menu, enter" -NoNewline; write-host " '0'" -ForegroundColor red
            write-host ""
            $sbName = Read-Host "Select an option to continue"

            if ($sbName -eq 1) {
                ## Execute the function 'pslogin'
                pslogin
                $psstatus = get-azcontext
                $tenants = Get-AzTenant
                $currentpstenant = $tenants | Where-Object { $_.Id -eq $psstatus.Tenant.Id }
            }

            elseif ($sbName -eq 2) {
                ## Execute the function 'get-subscription'
                get-subscription -tenantId $psstatus.Tenant.Id
                $psstatus = get-azcontext
                $tenants = Get-AzTenant
                $currentpstenant = $tenants | Where-Object { $_.Id -eq $psstatus.Tenant.Id }
            }
        }

        elseif ($sbName -eq 0) {
            clear-host
            Write-Host "Exiting..." -ForegroundColor Green
            start-sleep -Seconds 2
            clear-host
            exit
        }
    
    } 
    
    catch {
        Write-Host "An error occurred. Check logs at './logs/role-assignments.log' for more info" -ForegroundColor Red
        Write-host "$_" -ForegroundColor Red
        pause
    }

}