 # Define a list of SQL servers
$SqlServers = @("server1","server2","server3")  # Replace with actual server names

# Define the SQL query
$sqlQuery = @"
DECLARE @command VARCHAR(5000)  
DECLARE @DBInfo TABLE   -- Temporary table created on the memory
( 
    ServerName VARCHAR(100),  
    DatabaseName VARCHAR(100),  
    PhysicalFileName NVARCHAR(520),  
    FileSizeMB DECIMAL(10,2),  
    SpaceUsedMB DECIMAL(10,2),  
    FreeSpaceMB DECIMAL(10,2),
    FreeSpacePct VARCHAR(8)
)
 
SELECT @command = 'Use [' + '?' + '] SELECT  
@@servername as ServerName,  
' + '''' + '?' + '''' + ' AS DatabaseName, filename,
    convert(decimal(12,2), round(a.size/128.000,2)) as FileSizeMB,
    convert(decimal(12,2), round(fileproperty(a.name, ' + '''' + 'SpaceUsed' + '''' + ')/128.000,2)) as SpaceUsedMB,
    convert(decimal(12,2), round((a.size - fileproperty(a.name, ' + '''' + 'SpaceUsed' + '''' + '))/128.000,2)) as FreeSpaceMB,
    CAST(100 * (CAST(((a.size / 128.0 - CAST(FILEPROPERTY(a.name, ' + '''' + 'SpaceUsed' + '''' + ' ) AS INT) / 128.0) / (a.size / 128.0)) AS DECIMAL(4,2))) AS VARCHAR(8)) + ' + '''' + '%' + '''' + ' AS FreeSpacePct
FROM dbo.sysfiles a'
 
INSERT INTO @DBInfo
EXEC sp_MSForEachDB @command  
 
SELECT * FROM @DBInfo 
WHERE DatabaseName NOT IN ('distribution', 'master', 'model', 'msdb', 'tempdb', 'dba_local', 'DBA_Audit')
"@

# Define the output file path
$outputFile = "DatabaseFGSpaceReport.xlsx"

# Initialize a variable to hold all results
$allResults = @()

# Run the query on each server and collect results
foreach ($server in $SqlServers) {
    Write-Host "Running query on server: $server"
    
    try {
        # Execute SQL query on the server
        $result = Invoke-Sqlcmd -ServerInstance $server -Database "master" -Query $sqlQuery -ErrorAction Stop -TrustServerCertificate
        
        # Check if results are returned and add to the list
        if ($result) {
            # Select only relevant columns for export
            $serverResults = $result | Select-Object ServerName, DatabaseName, PhysicalFileName, FileSizeMB, SpaceUsedMB, FreeSpaceMB, FreeSpacePct
            
            # Add header for the server
            $header = [PSCustomObject]@{
                ServerName       = "Server: $server"
                DatabaseName     = ""
                PhysicalFileName = ""
                FileSizeMB       = ""
                SpaceUsedMB      = ""
                FreeSpaceMB      = ""
                FreeSpacePct     = ""
            }
            $allResults += $header
            $allResults += $serverResults
        } else {
            Write-Host "No data returned for server $server."
        }
    } catch {
        Write-Host "Error connecting to server ${server}: $_"
    }
}

# Check if any results were collected
if ($allResults.Count -gt 0) {
    # Export results to Excel
    $allResults | Export-Excel -Path $outputFile -AutoSize -Title "Database File Group space Report"
    Write-Host "Results have been saved to $outputFile."
} else {
    Write-Host "No results to save."
}
 
