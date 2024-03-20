# SimpleAzureVMStartStop.ps1 - PowerShell Script

A simple PowerShell script to start/stop Azure Virtual Machines. For use with Azure Automation and a Managed Identity.
The Managed Identity needs the permissions according to [`CustomRoleDefinition.json`](CustomRoleDefinition.json).

Tested with PowerShell 5.1 as a runtime.

## Features

- Starts/Stops one specific VM or all VMs in a Resource Group
- Uses the modern ("Az") Azure PowerShell module (instead of the old AzureRm module)
- Uses Managed Identity instead of RunAs Accounts
- Supports System-Assigned and User-Assigned Managed Identities (thanks @SanderBlom)
- Simple
- Free
