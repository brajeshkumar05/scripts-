<# This script is used to rename the database name from the list of database mentioned on the excel sheet and save it on the excel,
make sure to change the variables value #>
#Connect to Azure account
#Connect-AzAccount

$excelFilePath = "G:\r0b0ffy\work\test.xlsx"
$sheetName = "Sheet1"
$excelData = Import-Excel -Path $excelFilePath -WorksheetName $sheetName
$outputFilePath = "G:\r0b0ffy\work\test_output2.xlsx"

$successList = @()
$failureList = @()

foreach ($row in $excelData) {
    $subscriptionId = $row.subscriptionName
    $resourceGroupName = $row.ResourceGroupName
    $serverName = $row.ServerID
    $databaseName = $row.databaseName
    $newDatabaseName = "${databaseName}_delete"
    
    try {
        # Set the subscription context
        Set-AzContext -SubscriptionId $subscriptionId

        # Rename database
        Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -NewName $newDatabaseName

        # Add success record to the success list
        $successList += [PSCustomObject]@{
            SubscriptionId    = $subscriptionId
            ResourceGroupName = $resourceGroupName
            ServerName        = $serverName
            DatabaseName      = $databaseName
            NewDatabaseName   = $newDatabaseName
            Status            = "Success"
        }
    }
    catch {
        # Add failure record to the failure list
        $failureList += [PSCustomObject]@{
            SubscriptionId    = $subscriptionId
            ResourceGroupName = $resourceGroupName
            ServerName        = $serverName
            DatabaseName      = $databaseName
            ErrorMessage      = $_.Exception.Message
            Status            = "Failure"
        }
    }
}

# Remove existing output file if it exists
if (Test-Path $outputFilePath) {
    Remove-Item $outputFilePath
}

# Export results to the Excel file
$successSheetName = "Success"
$failureSheetName = "Failure"

# Export success list to the success sheet
$successList | Export-Excel -Path $outputFilePath -WorksheetName $successSheetName -AutoSize -Append

# Export failure list to the failure sheet
$failureList | Export-Excel -Path $outputFilePath -WorksheetName $failureSheetName -AutoSize -Append

Write-Host "Results exported to $outputFilePath" -ForegroundColor Green
