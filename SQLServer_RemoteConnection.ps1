 $vms = @("haz16076169312") 

foreach ($vm in $vms) 
{ 
    try 
    {
        # Construct connection string
        $connectionString = "Server=$vm,14481;Integrated Security=True;multisubnetFailover=true;Encrypt=true;trustservercertificate=true;connection timeout=15"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()

        $sqlquery = "select serverproperty('edition')"#"EXEC dba_local..uspDBMon_Track_DBA_Changes 'test'"
        Invoke-Sqlcmd -Query $sqlquery -ConnectionString $connectionString
    }
    catch
    {
    Action = "Failed to execute SQL query: $_"
    }
}
 
