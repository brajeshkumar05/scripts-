# Define the list of subscriptions
$subscriptions = 
'sp-pl-azuresql-nonprod-000',
'sp-pl-azuresql-nonprod-001',
'sp-pl-azuresql-nonprod-002',
'sp-pl-azuresql-nonprod-003',
'sp-pl-azuresql-nonprod-004',
'sp-pl-azuresql-nonprod-005',
'sp-pl-azuresql-nonprod-006',
'sp-pl-azuresql-nonprod-007',
'sp-pl-azuresql-nonprod-008',
'sp-pl-azuresql-nonprod-009',
'sp-pl-azuresql-nonprod-010',
'sp-pl-azuresql-nonprod-011',
'sp-pl-azuresql-prod-000',
'sp-pl-azuresql-prod-001',
'sp-pl-azuresql-prod-002',
'sp-pl-azuresql-prod-003',
'sp-pl-azuresql-prod-004',
'sp-pl-azuresql-prod-005',
'sp-pl-azuresql-prod-006'

$results = @()

foreach ($subscription in $subscriptions) {
    Set-AzContext -SubscriptionId $subscription

    # Get all SQL servers in the current subscription
    $sqlServers = Get-AzSqlServer

    foreach ($server in $sqlServers) {
        # Get all databases for the current SQL server
        $databases = Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName

        # Retrieve tags from the server
        $applicationName = $server.Tags["applicationname"]
        $notificationDistList = $server.Tags["notificationdistlist"]
        $Appowner = $server.Tags["applicationowner"]
        $Owner = $server.Tags["owner"]

        foreach ($database in $databases) {
            # Filter databases based on the specified prefixes
            if ($database.DatabaseName -like '*old*' -or $database.DatabaseName -like '*copy*' -or $database.DatabaseName -like '*test*'-or $database.DatabaseName -like '*back*'-or $database.DatabaseName -like '*restore*') {
                $results += [PSCustomObject]@{
                    SubscriptionName     = $subscription
                    ServerName           = $server.ServerName
                    DatabaseName         = $database.DatabaseName
                    ApplicationName      = $applicationName
                    NotificationDistList = $notificationDistList
                    ApplicationOwner     = $Appowner
                    Owner                = $Owner
                }
            }
        }
    }
}

# Output the results
$results | Export-Csv -Path "AzureSqlServersAndDatabases.csv" -NoTypeInformation

Write-Host "Results exported to AzureSqlServersAndDatabases.csv" -ForegroundColor Green
 
