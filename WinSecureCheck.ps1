#Requires -Version 7.0

param(
  [Parameter()]
  [string] $ReportPath = ".",

  [Parameter()]
  [switch] $EnableNetworkChecks,

  [Parameter()]
  [string] $NetworkTargetHost = "www.microsoft.com",

  [Parameter()]
  [ValidateRange(1, 65535)]
  [int] $NetworkTargetPort = 443
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot/src/Models/CheckResult.ps1"

. "$PSScriptRoot/src/Utils/Admin.ps1"
. "$PSScriptRoot/src/Utils/Params.ps1"
. "$PSScriptRoot/src/Utils/Run.ps1"
. "$PSScriptRoot/src/Utils/Format.ps1"

. "$PSScriptRoot/src/Checks/SystemInfo.ps1"
. "$PSScriptRoot/src/Checks/LocalAdmins.ps1"
. "$PSScriptRoot/src/Checks/Firewall.ps1"
. "$PSScriptRoot/src/Checks/Updates.ps1"
. "$PSScriptRoot/src/Checks/Antivirus.ps1"
. "$PSScriptRoot/src/Checks/Ports.ps1"
. "$PSScriptRoot/src/Checks/Network.ps1"

. "$PSScriptRoot/src/Scoring/Score.ps1"
. "$PSScriptRoot/src/Reporting/Report.ps1"

try {
  $params = Get-WscParams -BoundParameters $PSBoundParameters
  if (-not (Test-WscParams -Params $params)) {
    Write-Host "`e[38;2;248;113;113m[!] Invalid parameters (ReportPath/Host/Port).`e[0m"
    exit 2
  }

  if (-not (Test-IsAdmin)) {
    Write-Host "`e[38;2;248;113;113m[!] Admin rights required. Run PowerShell as Administrator.`e[0m"
    exit 1
  }

  # Render beautiful title banner and machine info
  Write-WscBanner

  $criticalPorts = @(
    3389, 445, 139, 22, 21, 23, 5900, 1433, 3306
  )

  $run = Initialize-WscRun -ReportPath $params.ReportPath
  $results = New-Object System.Collections.Generic.List[object]

  Write-ScanStart -Name "SystemInfo"
  Start-Sleep -Milliseconds 150
  $resSystemInfo = Get-SystemInfoResult
  $results.Add($resSystemInfo)
  Write-ScanFinish -Name "SystemInfo" -Status $resSystemInfo.Status -Details $resSystemInfo.Details

  Write-ScanStart -Name "LocalAdmins"
  Start-Sleep -Milliseconds 150
  $resLocalAdmins = Get-LocalAdminsResult
  $results.Add($resLocalAdmins)
  Write-ScanFinish -Name "LocalAdmins" -Status $resLocalAdmins.Status -Details $resLocalAdmins.Details

  Write-ScanStart -Name "Firewall"
  Start-Sleep -Milliseconds 150
  $resFirewall = Get-FirewallResult
  $results.Add($resFirewall)
  Write-ScanFinish -Name "Firewall" -Status $resFirewall.Status -Details $resFirewall.Details

  Write-ScanStart -Name "Updates"
  Start-Sleep -Milliseconds 150
  $resUpdates = Get-UpdatesResult -ThresholdDays 30
  $results.Add($resUpdates)
  Write-ScanFinish -Name "Updates" -Status $resUpdates.Status -Details $resUpdates.Details

  Write-ScanStart -Name "Antivirus"
  Start-Sleep -Milliseconds 150
  $resAntivirus = Get-AntivirusResult
  $results.Add($resAntivirus)
  Write-ScanFinish -Name "Antivirus" -Status $resAntivirus.Status -Details $resAntivirus.Details

  Write-ScanStart -Name "Ports"
  Start-Sleep -Milliseconds 150
  $resPorts = Get-PortsResult -CriticalPorts $criticalPorts
  $results.Add($resPorts)
  Write-ScanFinish -Name "Ports" -Status $resPorts.Status -Details $resPorts.Details

  if ($params.EnableNetworkChecks) {
    Write-ScanStart -Name "NetworkChecks"
    Start-Sleep -Milliseconds 150
    $resNetwork = Get-NetworkChecksResult `
        -HostName $params.NetworkTargetHost `
        -Port $params.NetworkTargetPort
    $results.Add($resNetwork)
    Write-ScanFinish -Name "NetworkChecks" -Status $resNetwork.Status -Details $resNetwork.Details
  } else {
    Write-ScanStart -Name "NetworkChecks"
    Start-Sleep -Milliseconds 150
    $resNetwork = New-CheckResult `
        -Name "NetworkChecks" `
        -Status "NotRun" `
        -Details "Not enabled (use -EnableNetworkChecks)" `
        -Recommendation "Enable network checks if connectivity should be verified." `
        -PointsMax 10
    $results.Add($resNetwork)
    Write-ScanFinish -Name "NetworkChecks" -Status $resNetwork.Status -Details $resNetwork.Details
  }

  $score = Get-WscScore -Results $results
  Write-WscReport `
    -ReportFilePath $run.ReportFilePath `
    -Results $results `
    -TotalAchieved $score.TotalAchieved `
    -TotalMax $score.TotalMax `
    -Score $score.Score

  # Render beautiful TUI summary dashboard
  Write-WscSummaryDashboard `
    -Results $results `
    -Score $score.Score `
    -TotalAchieved $score.TotalAchieved `
    -TotalMax $score.TotalMax `
    -ReportFilePath $run.ReportFilePath

  exit 0
} catch {
  Write-Host "`e[38;2;248;113;113m[!] Fatal error: $($_.Exception.Message)`e[0m"
  Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
  exit 3
}