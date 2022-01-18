# SimpleAzureVMStartStop.ps1 - PowerShell Script

A simple PowerShell script to start/stop Azure Virtual Machines. For use with Azure Automation and a Managed Identity.
The Managed Identity needs the permissions according to [`CustomRoleDefinition.json`](CustomRoleDefinition.json).

## Features

- Uses the modern ("Az") Azure PowerShell module (instead of the old AzureRm module)
- Uses Managed Identity instead of RunAs Accounts
- Simple
- Free
