# Step 1: Install required module (if not already installed)
# Install-Module -Name Az.Billing -AllowClobber -Force

# Step 2: Import modules
#Import-Module Az.Billing

# Step 3: Connect to Azure account
#Connect-AzAccount

$excelFilePath = "G:\r0b0ffy\work\IaaS_Unused.xlsx"
$sheetName = "Sheet2"
$excelData = Import-Excel -Path $excelFilePath -WorksheetName $sheetName

$results = @()

foreach ($row in $excelData) {
    $subscriptionId = $row.'Subscription'
    $resourceGroupName = $row.'ResourceGroup'
    $vmName = $row.'VM'
    
    try {
        # Set the subscription context
        Set-AzContext -SubscriptionId $subscriptionId

        # Define the date range
        $startDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
        $endDate = (Get-Date).ToString("yyyy-MM-dd")

        # Get the VM details
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

        # Fetch cost details using Azure Cost Management API
        $costs = Get-AzConsumptionUsageDetail `
            -StartDate $startDate `
            -EndDate $endDate `
            -ResourceGroup $resourceGroupName `
            -InstanceName $vm.Name
        
        # Sum up the costs
        $totalCost = ($costs | Measure-Object -Property PretaxCost -Sum).Sum

        # Collect results for exporting
        $result = [PSCustomObject]@{
            Subscription     = $subscriptionId
            ResourceGroup    = $resourceGroupName
            VM               = $vmName
            StartDate        = $startDate
            EndDate          = $endDate
            TotalCost        = $totalCost
        }
        $results += $result
        
        # Output the total cost to the console
        Write-Output "Total cost for VM '$vmName' from $startDate to $endDate is: $($totalCost) USD"
    }
    catch {
        Write-Host "An error occurred for VM '$vmName' in subscription '$subscriptionId': $_"
    }
}

# Output the results to CSV
$results | Export-Csv -Path "Prod02.csv" -NoTypeInformation

Write-Host "Results exported" -ForegroundColor Green
 
