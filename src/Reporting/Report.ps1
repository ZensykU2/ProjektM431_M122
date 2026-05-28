function Write-WscReport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $ReportFilePath,

    [Parameter(Mandatory)]
    [System.Collections.Generic.List[object]] $Results,

    [Parameter(Mandatory)]
    [double] $TotalAchieved,

    [Parameter(Mandatory)]
    [double] $TotalMax,

    [Parameter(Mandatory)]
    [int] $Score
  )

  $lines = New-Object System.Collections.Generic.List[string]

  $lines.Add("SUMMARY")
  $lines.Add("Score: $Score / 100")
  $lines.Add("Total: $TotalAchieved / $TotalMax")
  $lines.Add("")

  $fail = @(
  $Results |
    Where-Object { $_.Status -eq "Fail" } |
    Select-Object -ExpandProperty Name
  )

  $unk = @(
    $Results |
      Where-Object { $_.Status -eq "Unknown" } |
      Select-Object -ExpandProperty Name
  )

  if ($fail.Count -gt 0) {
    $lines.Add("Failed checks: " + ($fail -join ", "))
  }

  if ($unk.Count -gt 0) {
    $lines.Add("Unknown checks: " + ($unk -join ", "))
  }
  
  $lines.Add("")
  $lines.Add("----------------------------------------")
  $lines.Add("DETAILS")
  $lines.Add("")

  foreach ($r in $Results) {
    $pointsAchieved = switch ($r.Status) {
      "Pass" { $r.PointsMax }
      "Fail" { 0 }
      "Unknown" { [math]::Round($r.PointsMax * 0.5, 2) }
      "NotRun" { 0 }
    }

    $lines.Add("$($r.Name): $($r.Status) ($pointsAchieved/$($r.PointsMax))")
    $lines.Add("Details: $($r.Details)")
    $lines.Add("Recommendation: $($r.Recommendation)")
    $lines.Add("")
  }

  Add-Content -LiteralPath $ReportFilePath -Value $lines -Encoding UTF8
}