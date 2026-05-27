function Get-SystemInfoResult {
  [CmdletBinding()]
  param()

  try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $details = "OS=$($os.Caption), Build=$($os.BuildNumber), Uptime=$([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1))h"

    return New-CheckResult `
      -Name "SystemInfo" `
      -Status "Pass" `
      -Details $details `
      -Recommendation "-" `
      -PointsMax 0 `
      -RawData @{ OS = $os }
  } catch {
    return New-CheckResult `
      -Name "SystemInfo" `
      -Status "Unknown" `
      -Details ("Error collecting system info: " + $_.Exception.Message) `
      -Recommendation "-" `
      -PointsMax 0
  }
}