function install-azcli {
    $azcli = Get-Command az -ErrorAction SilentlyContinue
    if (!$azcli) {
        Write-Host "Azure CLI is not installed. Installing now." -ForegroundColor Yellow
        $azcli = Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile $env:TEMP\AzureCLI.msi
        Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i `"$env:TEMP\AzureCLI.msi`" /quiet"
        Write-Host "Azure CLI has been installed." -ForegroundColor Green
    }
    else {
        Write-Host "Azure CLI is already installed." -ForegroundColor Green
    }
}

function install-azmodule {
    $azmodule = Get-Module -ListAvailable -Name Az -ErrorAction SilentlyContinue
    if (!$azmodule) {
        Write-Host "Azure PowerShell module is not installed. Installing now." -ForegroundColor Yellow
        Install-Module -Name Az -AllowClobber -Force -Scope CurrentUser
        Write-Host "Azure PowerShell module has been installed." -ForegroundColor Green
    }
    else {
        Write-Host "Azure PowerShell module is already installed." -ForegroundColor Green
    }
}

#Function to check if user is logged in to Azure - Borrowed from Koko's script
function azlogin() {  
    $context = az account show --output json 2>&1
    az config set core.login_experience_v2=off

    if ($context -like "*Please run 'az login'*") {  
        Write-Host "You are not logged in to Azure. Logging in now" -ForegroundColor yellow
        az login
        $account = az account show --output json
        if ($account) {
            Write-Host "Successfully logged in to Azure." -ForegroundColor Green
        }
        else {
            Write-Host "Login failed. Exiting."
            Break
        }
    } 
    elseif ($context -like "*No subscription found*") {
        Write-Host "You are not logged in to Azure. Logging in now" -ForegroundColor yellow
        az login --only-show-errors  -o none
        $account = az account show --output json
        if ($account) {
            Write-Host "Successfully logged in to Azure CLI." -ForegroundColor Green
        } 
        else {
            Write-Host "Login failed. Exiting." -ForegroundColor Red
            Break  
        }
    }
    else {  
        ## Get status of azCLI
        clear-host
        Write-host "During this process you will be prompted to sign in twice." -ForegroundColor Yellow
        Write-host ""
        write-host "The first sign-in forces a tenant change. This is useful for individuals with access to multiple tenants with different accounts." -ForegroundColor Yellow
        write-host "The second sign-in is to authenticate the account and connect to the selected tenant." -ForegroundColor Yellow
        Write-host ""
        Write-host "Use an account that has access to the Tenant you wish to target" -foregroundcolor Yellow
        Start-Sleep -Seconds 3

        az login --only-show-errors -o none
        
        Clear-Host
        write-host "Getting Tenants..." -ForegroundColor yellow
        $tenants = az rest --method GET --uri https://management.azure.com/tenants?api-version=2020-01-01 --query "value[].{TenantId:tenantId, DisplayName:displayName}" --output tsv
        $tenantList = @()
        $i = 1

        foreach ($tenant in $tenants -split "`n") {
            $tenantDetails = $tenant -split "`t"
            $tenantList += @{
                "Number"   = $i
                "TenantId" = $tenantDetails[0]
                "Name"     = $tenantDetails[1]
            }
            write-host "$i. $($tenantDetails[1]) | $($tenantDetails[0])"
            $i++
        }

        write-host ""
        Write-Host "Enter the number next to the tenant you wish to target"
        Write-Host "If it is not shown in the list enter '0' to manually connect"
        Write-host ""
        $selectedTenant = read-host "Enter tenant index number you wish to connect to."
        $newTenant = $tenantList[$selectedTenant - 1]

        if ($newTenant) {
            if ($selectedTenant -eq 0) {
                $manualTenant = Read-host "Manually enter the Tenant Id you wish to connect to"

                az login --tenant $manualTenant
            }

            else {
                az login --tenant $newTenant.TenantId
            }
        }
        
    }  
} 

#Function to check user is logged into Azure powershell module
function pslogin() {

    $azLoggedIn = Get-AzContext
    
    if (!$azLoggedIn) {
        Write-Host "You are not logged in to Azure Powershell. Logging in now" -ForegroundColor yellow
        Connect-AzAccount -force

        $azLoggedIn = Get-AzContext
        
        if ($azLoggedIn) {
            Write-Host "Successfully logged in to Azure Powershell" -ForegroundColor Green
        }
        else {
            Write-Host "Login failed. Exiting." -ForegroundColor Red
            Break
        }
    }
    
    else {
        $azLoggedIn = Get-AzContext
        $tenants = Get-AzTenant
        $tenants = $tenants | Where-Object { $_.Id -eq $azLoggedIn.Tenant.Id }

        clear-host
        Write-host "During this process you will be prompted to sign in twice." -ForegroundColor Yellow
        Write-host ""
        write-host "The first sign-in forces a tenant change. This is useful for individuals with access to multiple tenants with different accounts." -ForegroundColor Yellow
        write-host "The second sign-in is to authenticate the account and connect to the selected tenant." -ForegroundColor Yellow
        Write-host ""
        Write-host "Use an account that has access to the Tenant you wish to target" -foregroundcolor Yellow
        Start-Sleep -Seconds 2

        Connect-AzAccount -force

        Clear-Host
        write-host "Getting Tenants..." -ForegroundColor yellow
        $tenants = Get-AzTenant
        $tenantList = @()
        $i = 1

        foreach ($tenant in $tenants) {
            $tenantList += @{
                "Number"   = $i
                "TenantId" = $tenant.Id
                "Name"     = $tenant.Name
            }
            write-host "$i. $($tenant.Name) | $($tenant.TenantId)"
            $i++
        }

        write-host ""
        Write-Host "Enter the number next to the tenant you wish to target"
        Write-Host "If it is not shown in the list enter '0' to manually connect"
        Write-host ""
        $selectedTenant = read-host "Enter tenant index number you wish to connect to."
        $newTenant = $tenantList[$selectedTenant - 1]

        if ($newTenant) {
            if ($selectedTenant -eq 0) {
                $manualTenant = Read-host "Manually enter the Tenant Id you wish to connect to"

                Connect-AzAccount -TenantId $manualTenant
            }

            else {
                connect-AzAccount -tenantId $newTenant.TenantId
            }
        }
        
        

        else {

        }

    }

    $azLoggedIn = Get-AzContext
    $tenants = Get-AzTenant
    $tenants = $tenants | Where-Object { $_.Id -eq $azLoggedIn.Tenant.Id }

    return @{
        workingSubscription = $azLoggedIn.Subscription.Name
        workingTenant       = $tenants.Name
        tenantId            = $azLoggedIn.Tenant.Id
    }
    
}

function az-status {
    ## Get status of azCLI
    $azsub = az account show --query name -o tsv #Get current azcli subscription
    $aztenant = az account show --query tenantId -o tsv #Get current tenant for azcli
    $tenantfriendlyname = az rest --method GET --uri https://management.azure.com/tenants?api-version=2020-01-01 --query "value[?tenantId=='$aztenant'].{TenantId:tenantId, DisplayName:displayName}" --output tsv
    $splitname = $tenantfriendlyname -split "`t"

    ## Get status of PowerShell
    $tenants = Get-AzTenant
    $psstatus = get-azcontext #Get current subscription for PowerShell
    $currentpstenant = $tenants | Where-Object { $_.Id -eq $psstatus.Tenant.Id }

    write-host "(azcli) You are connected to tenant: " -NoNewLine; write-host $splitname[1] -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $azsub -ForegroundColor Yellow
    write-host "(PowerShell) You are connected to tenant: " -NoNewLine; write-host $currentpstenant.Name -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $psstatus.Subscription.Name -ForegroundColor Yellow
}

function get-subscription {
    param (
        [string]$tenantId
    )

    Clear-Host
    write-host "Getting Subscriptions..." -ForegroundColor yellow
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }
    $subList = @()
    $i = 1

    foreach ($sub in $subscriptions) {
        $subList += @{
            "Number"         = $i
            "SubscriptionId" = $sub.Id
            "Name"           = $sub.Name
        }
        write-host "$i. $($sub.Name)"
        $i++
    }

    write-host ""
    Write-Host "Enter the number next to the Subscription you wish to target"
    Write-Host "If it is not shown in the list enter '0' to manually connect"
    Write-host ""
    $selectedSub = read-host "Enter subscription index number you wish to connect to."
    $newSub = $subList[$selectedSub - 1]

    if ($newSub) {
        if ($selectedSub -eq 0) {
            $manualSub = Read-host "Manually enter the Subscription Id you wish to connect to"
            write-host $manualSub

            Set-AzContext -Subscription $manualSub
            pause
        }

        else {
            Set-AzContext -Subscription $newSub.SubscriptionId
        }
    }

    $azLoggedIn = Get-AzContext
    $tenants = Get-AzTenant
    $tenants = $tenants | Where-Object { $_.Id -eq $azLoggedIn.Tenant.Id }

    return @{
        workingSubscription = $azLoggedIn.Subscription.Name
        workingTenant       = $tenants.Name
    }
}