<#
.SYNOPSIS
 Script to start or stop Azure VMs with Azure Automation.
.DESCRIPTION
 This script is intended to start or stop Azure Virtual Machines in a simple way in Azure Automation.
 The script uses Azure Automation Managed Identity and the modern ("Az") Azure PowerShell Module.
    
 Requirements:
 Give the Azure Automation Managed Identity necessary rights to Start/Stop VMs in the Resource Group.
 You can create a custom role for this purpose with the following permissions: 
   - Microsoft.Compute/virtualMachines/deallocate/action
   - Microsoft.Compute/virtualMachines/start/action
   - Microsoft.Compute/virtualMachines/read

.NOTES
  Version:        1.2.0
  Author:         Andreas Dieckmann
  Creation Date:  2022-03-11
  GitHub:         https://github.com/diecknet/Simple-Azure-VM-Start-Stop
  Blog:           https://diecknet.de
  License:        MIT License

  Copyright (c) 2022 Andreas Dieckmann

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  
.LINK 
  https://diecknet.de/
.LINK
  https://github.com/diecknet/Simple-Azure-VM-Start-Stop

.INPUTS
    None

.OUTPUTS
    String to determine result of the script

#>

param(
    [Parameter(Mandatory = $true)]
    # Specify the name of the Virtual Machine, or use the asterisk symbol "*" to affect all VMs in the resource group
    $VMName,
    [Parameter(Mandatory = $true)]
    $ResourceGroupName,
    [Parameter(Mandatory = $false)]
    # Optionally specify Azure Subscription ID
    $AzureSubscriptionID,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Start", "Stop")]
    # Specify desired Action, allowed values "Start" or "Stop"
    $Action
)

Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$errorCount = 0

# connect to Azure, suppress output
try {
    $null = Connect-AzAccount -Identity
}
catch {
    $ErrorMessage = "Error connecting to Azure: " + $_.Exception.message
    Write-Error $ErrorMessage
    throw $ErrorMessage
    exit
}

# select Azure subscription by ID if specified, suppress output
if ($AzureSubscriptionID) {
    try {
        $null = Select-AzSubscription -SubscriptionID $AzureSubscriptionID    
    }
    catch {
        $ErrorMessage = "Error selecting Azure Subscription ($AzureSubscriptionID): " + $_.Exception.message
        Write-Error $ErrorMessage
        throw $ErrorMessage
        exit
    }
}

# check if we are in an Azure Context
try {
    $AzContext = Get-AzContext
}
catch {
    $ErrorMessage = "Error while trying to retrieve the Azure Context: " + $_.Exception.message
    Write-Error $ErrorMessage
    throw $ErrorMessage
    exit
}
if ([string]::IsNullOrEmpty($AzContext.Subscription)) {
    $ErrorMessage = "Error. Didn't find any Azure Context. Have you assigned the permissions according to 'CustomRoleDefinition.json' to the Managed Identity?"
    Write-Error $ErrorMessage
    throw $ErrorMessage
    exit
}

if ($VMName -eq "*") {
    try {
        # if "*" was given as the VMName, get all VMs in the resource group
        $VMs = Get-AzVM -ResourceGroupName $ResourceGroupName
    }
    catch {
        $ErrorMessage = "Error getting VMs from resource group ($ResourceGroupName): " + $_.Exception.message

        Write-Error $ErrorMessage
        throw $ErrorMessage
        exit
    }
    
}
else {
    try {
        # get only the specified VM
        $VMs = Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $VMName
    }
    catch {
        $ErrorMessage = "Error getting VM ($VMName) from resource group ($ResourceGroupName): " + $_.Exception.message
        Write-Error $ErrorMessage
        throw $ErrorMessage
        exit
    }
    
}

# Loop through all specified VMs (if more than one). The loop only executes once if only one VM is specified.
foreach ($VM in $VMs) {
    switch ($Action) {
        "Start" {
            # Start the VM
            try {
                Write-Output "Starting VM $($VM.Name)..."
                $null = $VM | Start-AzVM -ErrorAction Stop -NoWait
            }
            catch {
                $ErrorMessage = $_.Exception.message
                Write-Error "Error starting the VM $($VM.Name): " + $ErrorMessage
                # increase error count
                $errorCount++
                Break
            }
        }
        "Stop" {
            # Stop the VM
            try {
                Write-Output "Stopping VM $($VM.Name)..."
                $null = $VM | Stop-AzVM -ErrorAction Stop -Force -NoWait
            }
            catch {
                $ErrorMessage = $_.Exception.message
                Write-Error "Error stopping the VM $($VM.Name): " + $ErrorMessage
                # increase error count
                $errorCount++
                Break
            }
        }    
    }
}

$endOfScriptText = "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
if ($errorCount -gt 0) {
    throw "Errors occured: $errorCount `r`n$endofScriptText"
}
Write-Output $endOfScriptText