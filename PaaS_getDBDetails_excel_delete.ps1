<# This script is used to find a particular database name from the list of servers mentioned on the excel sheet and save it on the excel,
make sure to change the variables value #>

# Connect to Azure account
# Connect-AzAccount

$excelFilePath = "G:\r0b0ffy\work\test.xlsx"
$sheetName = "Sheet1"
$excelData = Import-Excel -Path $excelFilePath -WorksheetName $sheetName
$outputFilePath = "G:\r0b0ffy\work\test_output1.xlsx"

# Initialize the output Excel file with headers
if (-Not (Test-Path -Path $outputFilePath)) {
    $header = @("ResourceGroupName", "ServerName", "DatabaseName")
    $null | Export-Excel -Path $outputFilePath -WorksheetName "Sheet1" -Header $header
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
        $databases = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName  | Where-Object { $_.DatabaseName -like '*delete*' }
        
        # Append the data to the Excel file
        $databases | Select-Object ResourceGroupName, ServerName, DatabaseName | Export-Excel -Path $outputFilePath -WorksheetName "NonProd_Databases" -Append
    }
    catch {
        Write-Host "An error occurred for '$serverName' in subscription '$subscriptionId': $_"
    }
}

Write-Host "Results exported $outputFilePath" -ForegroundColor Green
