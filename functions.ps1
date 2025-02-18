#Function to check if user is logged in to Azure - Borrowed from Koko's script
function azlogin() {  
    $context = az account show --output json 2>&1 
    if ($context -like "*Please run 'az login'*") {  
        Write-Host "You are not logged in to Azure. Logging in now" -ForegroundColor yellow
        az login --only-show-errors  -o none
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
        $tenants = Get-AzTenant #Get all tenants
        $aztenant = az account show --query tenantId -o tsv #Get current tenant for azcli
        $currentazclitenant = $tenants | Where-Object { $_.Id -eq $aztenant } #Search for tenant based on ID

        Write-Host "You are connected to Azure Tenant: $($currentazclitenant.Name). Do you want to change?" -ForegroundColor yellow
        $changeTenant = Read-Host "Enter your response to continue (Y/n)"

        if ($changeTenant -eq "Y") {
            Write-Host "During this process you will be prompted to sign in twice." -ForegroundColor Yellow
            Write-host ""
            Write-Host "The first sign-in forces a tenant change. This is useful for individuals with access to multiple tenants with different accounts." -ForegroundColor Yellow
            Write-Host "The second sign-in is to authenticate the account and connect to the selected tenant." -ForegroundColor Yellow
            Write-host ""
            Write-Host "Use an account that has access to the Tenant you wish to target" -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        
            az login --allow-no-subscriptions
        
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

                    az login --tenant $manualTenant
                }

                else {
                    az login --tenant $newTenant.TenantId
                }
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

        write-host ""
        Write-Host "You are connected to Azure Tenant: $($tenants.Name). Do you want to change?" -ForegroundColor yellow
        $changeTenant = Read-Host "Enter your response to continue (Y/n)"

        if ($changeTenant -eq "Y") {
            Write-host "During this process you will be prompted to sign in twice." -ForegroundColor Yellow
            Write-host ""
            write-host "The first sign-in forces a tenant change. This is useful for individuals with access to multiple tenants with different accounts." -ForegroundColor Yellow
            write-host "The second sign-in is to authenticate the account and connect to the selected tenant." -ForegroundColor Yellow
            Write-host ""
            Write-host "Use an account that has access to the Tenant you wish to target" -foregroundcolor Yellow
            Start-Sleep -Seconds 3

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