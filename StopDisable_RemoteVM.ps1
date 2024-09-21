# Define the list of VMs
$vms = @("haz16076169312") # Replace with your VM names

# Define the SQL services to be stopped and disabled
$sqlServiceNamePattern = "MSSQLSERVER"

# Initialize a list to store the results
$results = [System.Collections.Generic.List[PSObject]]::new()

# Function to stop and disable SQL services on a VM
function Stop-AndDisable-SQLServices {
    param (
        [string]$vmName
    )

    Write-Host "Processing VM: $vmName"

    $result = Invoke-Command -ComputerName $vmName -ScriptBlock {
        param (
            $sqlServiceNamePattern
        )

        $output = @()
        $sqlServices = Get-Service -Name $sqlServiceNamePattern -ErrorAction SilentlyContinue

        foreach ($service in $sqlServices) {
            if ($service.Status -eq 'Running') {
                $output += "Stopping service: $($service.Name)"
                Stop-Service -Name $service.Name -Force
            }
            $output += "Disabling service: $($service.Name)"
            Set-Service -Name $service.Name -StartupType Disabled
        }

        return $output
    } -ArgumentList $sqlServiceNamePattern

    foreach ($line in $result) {
        $results.Add([PSCustomObject]@{
            VMName = $vmName
            Action = $line
        }) | Out-Null
    }
}

# Loop through each VM and stop and disable SQL services
foreach ($vm in $vms) {
    Stop-AndDisable-SQLServices -vmName $vm
}

# Export the results to a CSV file
$results | Export-Csv -Path "SQLServiceActions.csv" -NoTypeInformation

Write-Host "SQL services have been stopped and disabled on all specified VMs. Results saved to SQLServiceActions.csv."
