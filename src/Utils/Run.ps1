function Initialize-WscRun {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $ReportPath
  )

  $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
  $fileName = "WinSecureCheck_Report_$timestamp.txt"
  $reportFilePath = Join-Path -Path $ReportPath -ChildPath $fileName

  $header = @(
    "WinSecureCheck Report"
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Host: $env:COMPUTERNAME"
    "User: $env:USERNAME"
    "PowerShell: $($PSVersionTable.PSVersion)"
    "----------------------------------------"
    ""
  )

  Set-Content -LiteralPath $reportFilePath -Value $header -Encoding UTF8

  [pscustomobject]@{
    Timestamp = $timestamp
    ReportFilePath = $reportFilePath
  }
}