
. "$PSScriptRoot/../src/Utils/Format.ps1"
. "$PSScriptRoot/../src/Models/CheckResult.ps1"
. "$PSScriptRoot/../src/Reporting/Report.ps1"

Write-WscBanner

$results = New-Object System.Collections.Generic.List[object]

Write-ScanStart -Name "SystemInfo"
Start-Sleep -Milliseconds 200
$r1 = New-CheckResult -Name "SystemInfo" -Status "Pass" -Details "OS=Microsoft Windows 11 Home, Build=26200, Uptime=48.5h" -Recommendation "-" -PointsMax 0
$results.Add($r1)
Write-ScanFinish -Name "SystemInfo" -Status $r1.Status -Details $r1.Details

Write-ScanStart -Name "LocalAdmins"
Start-Sleep -Milliseconds 200
$r2 = New-CheckResult -Name "LocalAdmins" -Status "Pass" -Details "Admins (2): DESKTOP-1OI5QOK\Administrator, DESKTOP-1OI5QOK\User" -Recommendation "Keep local admins minimal" -PointsMax 15
$results.Add($r2)
Write-ScanFinish -Name "LocalAdmins" -Status $r2.Status -Details $r2.Details

Write-ScanStart -Name "Firewall"
Start-Sleep -Milliseconds 200
$r3 = New-CheckResult -Name "Firewall" -Status "Pass" -Details "All firewall profiles enabled" -Recommendation "Keep Windows Firewall enabled" -PointsMax 25
$results.Add($r3)
Write-ScanFinish -Name "Firewall" -Status $r3.Status -Details $r3.Details

Write-ScanStart -Name "Updates"
Start-Sleep -Milliseconds 200
$r4 = New-CheckResult -Name "Updates" -Status "Fail" -Details "Last update: 45 days ago (older than 30 days threshold)" -Recommendation "Install Windows updates within 30 days" -PointsMax 20
$results.Add($r4)
Write-ScanFinish -Name "Updates" -Status $r4.Status -Details $r4.Details

Write-ScanStart -Name "Antivirus"
Start-Sleep -Milliseconds 200
$r5 = New-CheckResult -Name "Antivirus" -Status "Unknown" -Details "Defender enabled but real-time protection warning" -Recommendation "Verify AV state manually" -PointsMax 20
$results.Add($r5)
Write-ScanFinish -Name "Antivirus" -Status $r5.Status -Details $r5.Details

Write-ScanStart -Name "Ports"
Start-Sleep -Milliseconds 200
$r6 = New-CheckResult -Name "Ports" -Status "Pass" -Details "No critical TCP/UDP ports detected." -Recommendation "Keep only required services exposed" -PointsMax 10
$results.Add($r6)
Write-ScanFinish -Name "Ports" -Status $r6.Status -Details $r6.Details

Write-ScanStart -Name "NetworkChecks"
Start-Sleep -Milliseconds 200
$r7 = New-CheckResult -Name "NetworkChecks" -Status "NotRun" -Details "Not enabled (use -EnableNetworkChecks)" -Recommendation "Enable network checks if connectivity should be verified." -PointsMax 10
$results.Add($r7)
Write-ScanFinish -Name "NetworkChecks" -Status $r7.Status -Details $r7.Details

$reportFilePath = "$PSScriptRoot/WinSecureCheck_Report_Mock.txt"

Write-WscReport `
  -ReportFilePath $reportFilePath `
  -Results $results `
  -TotalAchieved 60 `
  -TotalMax 90 `
  -Score 77

Write-WscSummaryDashboard -Results $results -Score 77 -TotalAchieved 60 -TotalMax 90 -ReportFilePath $reportFilePath
