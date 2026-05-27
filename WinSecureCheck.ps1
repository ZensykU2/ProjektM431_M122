#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot/src/Models/CheckResult.ps1"

. "$PSScriptRoot/src/Utils/Admin.ps1"
. "$PSScriptRoot/src/Utils/Params.ps1"
. "$PSScriptRoot/src/Utils/Run.ps1"

. "$PSScriptRoot/src/Checks/SystemInfo.ps1"
. "$PSScriptRoot/src/Checks/LocalAdmins.ps1"
. "$PSScriptRoot/src/Checks/Firewall.ps1"
. "$PSScriptRoot/src/Checks/Updates.ps1"
. "$PSScriptRoot/src/Checks/Antivirus.ps1"
. "$PSScriptRoot/src/Checks/Ports.ps1"
. "$PSScriptRoot/src/Checks/Network.ps1"

. "$PSScriptRoot/src/Scoring/Score.ps1"
. "$PSScriptRoot/src/Reporting/Report.ps1"