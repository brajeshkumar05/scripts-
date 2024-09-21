# Set the path to the Excel file
$excelFilePath = "C:\users\xxx.xlsx"

# Set the name of the sheet within the Excel file
$sheetName = "Sheet1"

# Read the Excel file into a variable
$excelData = Import-Excel -Path $excelFilePath -WorksheetName $sheetName

# Loop through each row in the Excel data
foreach ($row in $excelData) 
{
    $serverName = $row.'Server Details'
    $databaseName = $row.Database.Split(".")[4]
    $loginName = $row.'Process ID'
    
    try 
    {
        # Construct connection string
        $connectionString = "Server=$serverName,14481;Integrated Security=True;multisubnetFailover=true;Encrypt=true;trustservercertificate=true;connection timeout=15"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()

        # Checking if the login already exists, if not create it
        $loginExistsQuery = "SELECT COUNT(*) FROM sys.server_principals WHERE name = '$loginName' AND type IN ('U','S');"
        $loginExists = Invoke-Sqlcmd -Query $loginExistsQuery -ConnectionString $connectionString

        if ($loginExists.Column1 -eq 0) 
        {
            $createLoginQuery = "USE [Master]; CREATE LOGIN [$loginName] FROM WINDOWS WITH DEFAULT_DATABASE=[master]"
            Invoke-Sqlcmd -Query $createLoginQuery -ConnectionString $connectionString
        }

        foreach ($db in $databaseName) 
        {
            # Check if the user exists in the database
            $userExistsQuery = "SELECT COUNT(*) FROM sys.database_principals WHERE name = '$loginName';"
            $userExists = Invoke-Sqlcmd -Query $userExistsQuery -ConnectionString $connectionString
        
            if ($userExists.Column1 -eq 0) 
            {
                $createUserQuery = "USE [$db]; CREATE USER [$loginName] FOR LOGIN [$loginName]; ALTER ROLE [db_datareader] ADD MEMBER [$loginName]"
                Invoke-Sqlcmd -Query $createUserQuery -ConnectionString $connectionString
            }
        }          
    } 
    catch 
    {
        Write-Host "An error occurred: $_"
    }
}
