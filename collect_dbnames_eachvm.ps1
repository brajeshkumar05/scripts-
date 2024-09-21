 # Define the list of SQL Server instances
$sqlServers = @(
"HAZ76JCQT31,14481",
"HAZ78HGLGE2,14481"
)

# Define the output CSV file path
$outputCsv = "G:\r0b0ffy\work\sql_server_databases.csv"

# Initialize an empty array to store the results
$results = @()

# Loop through each SQL Server instance
foreach ($sqlServer in $sqlServers) {
    # Establish a connection to the SQL Server instance
    $connectionString = "Server=$sqlServer;Integrated Security=True;"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $sqlConnection.ConnectionString = $connectionString

    try {
        # Open the connection
        $sqlConnection.Open()

        # Query to get the server name and database names, excluding specific databases
        $query = @"
        SELECT SERVERPROPERTY('ServerName') AS ServerName, name AS DatabaseName 
        FROM sys.databases 
        WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb', 'dba_local', 'DBA_Audit')
"@

        # Execute the query
        $sqlCommand = $sqlConnection.CreateCommand()
        $sqlCommand.CommandText = $query
        $reader = $sqlCommand.ExecuteReader()

        # Read the data
        while ($reader.Read()) {
            $results += [PSCustomObject]@{
                ServerName = $reader["ServerName"]
                DatabaseName = $reader["DatabaseName"]
            }
        }

        # Close the reader and the connection
        $reader.Close()
        $sqlConnection.Close()
    }
    catch {
        Write-Host "Failed to connect to $sqlServer" -ForegroundColor Red
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "Database information has been exported to $outputCsv"
 
