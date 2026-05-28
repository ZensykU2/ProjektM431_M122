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
    Write-Host "Invalid parameters (ReportPath/Host/Port)." -ForegroundColor Red
    exit 2
  }

  if (-not (Test-IsAdmin)) {
    Write-Host "Admin rights required. Run PowerShell as Administrator." -ForegroundColor Red
    exit 1
  }

  $criticalPorts = @(
    3389, 445, 139, 22, 21, 23, 5900, 1433, 3306
  )

  $run = Initialize-WscRun -ReportPath $params.ReportPath
  $results = New-Object System.Collections.Generic.List[object]

  Write-Host "Running check: SystemInfo"
  $results.Add((Get-SystemInfoResult))

  Write-Host "Running check: LocalAdmins"
  $results.Add((Get-LocalAdminsResult))

  Write-Host "Running check: Firewall"
  $results.Add((Get-FirewallResult))

  Write-Host "Running check: Updates"
  $results.Add((Get-UpdatesResult -ThresholdDays 30))

  Write-Host "Running check: Antivirus"
  $results.Add((Get-AntivirusResult))

  Write-Host "Running check: Ports"
  $results.Add((Get-PortsResult -CriticalPorts $criticalPorts))

  if ($params.EnableNetworkChecks) {
    Write-Host "Running check: NetworkChecks"
    $results.Add(
      (Get-NetworkChecksResult `
          -HostName $params.NetworkTargetHost `
          -Port $params.NetworkTargetPort)
    )
  } else {
    $results.Add(
      (New-CheckResult `
          -Name "NetworkChecks" `
          -Status "NotRun" `
          -Details "Not enabled (use -EnableNetworkChecks)" `
          -Recommendation "Enable network checks if connectivity should be verified." `
          -PointsMax 10)
    )
  }

  $score = Get-WscScore -Results $results
  Write-WscReport `
    -ReportFilePath $run.ReportFilePath `
    -Results $results `
    -TotalAchieved $score.TotalAchieved `
    -TotalMax $score.TotalMax `
    -Score $score.Score

  Write-Host "Report saved: $($run.ReportFilePath)" -ForegroundColor Green
  exit 0
} catch {
  Write-Host "Fatal error: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
  exit 3
}