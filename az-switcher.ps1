## Pre-requisites
#Load the required functions
try {
    # Dot source functions.ps1
    Write-Host "Locating and loading required functions... Please wait" -ForegroundColor Green
    . "$PSScriptRoot/functions.ps1"

    $functionCheck = Get-Command -Name pslogin, azlogin -CommandType Function -ErrorAction Stop
    
    # Check if the function exists
    if ($functionCheck) {
        Write-Host "Functions have been found. Continuing..." -ForegroundColor Green
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

## Get status of azCLI
$azsub = az account show --query name -o tsv #Get current azcli subscription
$aztenant = az account show --query tenantId -o tsv #Get current tenant for azcli
$tenantfriendlyname = az rest --method GET --uri https://management.azure.com/tenants?api-version=2020-01-01 --query "value[?tenantId=='$aztenant'].{TenantId:tenantId, DisplayName:displayName}" --output tsv
$splitname = $tenantfriendlyname -split "`t"


## Get status of PowerShell
$tenants = Get-AzTenant
$psstatus = get-azcontext #Get current subscription for PowerShell
$currentpstenant = $tenants | Where-Object { $_.Id -eq $psstatus.Tenant.Id }

#Set termloop variable to 0
$termloop = 0

#Main loop
while ($termloop -ne 1) {

    try {
        clear-host
        write-host "Az Switcher - Main Menu" -ForegroundColor Cyan
        write-host "***********************" -ForegroundColor Cyan
        write-host ""
        write-host "(azcli) You are connected to tenant: " -NoNewLine; write-host $splitname[1] -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $azsub -ForegroundColor Yellow
        write-host "(PowerShell) You are connected to tenant: " -NoNewLine; write-host $currentpstenant.Name -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $psstatus.Subscription.Name -ForegroundColor Yellow
        write-host ""
        Write-Host "To change azcli, enter" -NoNewline; write-host " '1'" -ForegroundColor blue
        Write-Host "To change PowerShell, enter" -NoNewline; write-host " '2'" -ForegroundColor blue
        Write-Host "To exit, enter" -NoNewline; write-host " '0'" -ForegroundColor red
        write-host ""
        $sbName = Read-Host "Select an option to continue"
    
        if ($sbName -eq 1) {
            clear-host
            write-host "Change azcli Tenant/Subscription" -ForegroundColor Cyan
            write-host "********************************" -ForegroundColor Cyan
            write-host ""
            write-host "You are connected to tenant: " -NoNewLine; write-host $splitname[1] -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $azsub -ForegroundColor Yellow
            write-host ""
            Write-Host "To change Tenant, enter" -NoNewline; write-host " '1'" -ForegroundColor blue
            Write-Host "To change Subscription, enter" -NoNewline; write-host " '2'" -ForegroundColor blue
            Write-Host "To exit to main menu, enter" -NoNewline; write-host " '0'" -ForegroundColor red
            write-host ""
            $sbName = Read-Host "Select an option to continue"

            if ($sbName -eq 1) {
                #Execute the function 'azlogin'
                azlogin
                $azsub = az account show --query name -o tsv #Get current azcli subscription
                $aztenant = az account show --query tenantId -o tsv #Get current tenant for azcli
                $tenantfriendlyname = az rest --method GET --uri https://management.azure.com/tenants?api-version=2020-01-01 --query "value[?tenantId=='$aztenant'].{TenantId:tenantId, DisplayName:displayName}" --output tsv
                $splitname = $tenantfriendlyname -split "`t"
            }

            elseif ($sbName -eq 2) {
                #Execute the function 'get-subscription'
                Write-host "Function currently unavailable. Please select option 1 to change subscription" -ForegroundColor Red
                pause
            }
        }

        elseif ($sbName -eq 2) {
            #Execute the function 'pslogin'
            #$azContext = pslogin

            clear-host
            write-host "Change PowerShell Tenant/Subscription" -ForegroundColor Cyan
            write-host "*************************************" -ForegroundColor Cyan
            write-host ""
            write-host "(PowerShell) You are connected to tenant: " -NoNewLine; write-host $currentpstenant.Name -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $psstatus.Subscription.Name -ForegroundColor Yellow
            write-host ""
            Write-Host "To change Tenant, enter" -NoNewline; write-host " '1'" -ForegroundColor blue
            Write-Host "To change Subscription, enter" -NoNewline; write-host " '2'" -ForegroundColor blue
            Write-Host "To exit to main menu, enter" -NoNewline; write-host " '0'" -ForegroundColor red
            write-host ""
            $sbName = Read-Host "Select an option to continue"

            if ($sbName -eq 1) {
                #Execute the function 'pslogin'
                pslogin
                $psstatus = get-azcontext
                $tenants = Get-AzTenant
                $currentpstenant = $tenants | Where-Object { $_.Id -eq $psstatus.Tenant.Id }
            }

            elseif ($sbName -eq 2) {
                #Execute the function 'get-subscription'
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