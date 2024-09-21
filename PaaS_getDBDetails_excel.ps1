<# This script is used to find database name from the list of servers mentioned on the excel sheet and save it on the excel,
make sure to change the variables value #>
# Connect to Azure account
# Connect-AzAccount

$excelFilePath = "G:\r0b0ffy\work\Unused_PaaS_list_nonprod.xlsx"
$sheetName = "NonProd"
$excelData = Import-Excel -Path $excelFilePath -WorksheetName $sheetName
$outputFilePath = "G:\r0b0ffy\work\unused_PaaS_beforeChg.xlsx"

# Initialize the output Excel file with headers
if (-Not (Test-Path -Path $outputFilePath)) {
    $header = @("ResourceGroupName", "ServerName", "DatabaseName")
    $null | Export-Excel -Path $outputFilePath -WorksheetName "NonProd" -Header $header
}

foreach ($row in $excelData) {
    $subscriptionId = $row.'subscriptionName'
    $resourceGroupName = $row.'ResourceGroupName'
    $serverName = $row.'ServerID'
    $databaseName = $row.'databaseName'
    
    try {
        # Set the subscription context
        Set-AzContext -SubscriptionId $subscriptionId

        # Get the list of databases on the server excluding the master database
        $databases = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName | Where-Object { $_.DatabaseName -ne "master" }
        
        # Append the data to the Excel file
        $databases | Select-Object ResourceGroupName, ServerName, DatabaseName | Export-Excel -Path $outputFilePath -WorksheetName "NonProd_Databases" -Append
    }
    catch {
        Write-Host "An error occurred for '$serverName' in subscription '$subscriptionId': $_"
    }
}

Write-Host "Results exported" -ForegroundColor Green
