function Get-WscScore {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [System.Collections.Generic.List[object]] $Results
  )

  $totalMax = 0.0
  $totalAchieved = 0.0

  foreach ($r in $Results) {
    if ($r.Status -eq "NotRun") { continue }

    $totalMax += [double] $r.PointsMax

    switch ($r.Status) {
      "Pass" { $totalAchieved += [double] $r.PointsMax }
      "Fail" { $totalAchieved += 0 }
      "Unknown" { $totalAchieved += ([double] $r.PointsMax) * 0.5 }
      default { $totalAchieved += 0 }
    }
  }

  if ($totalMax -le 0) {
    throw "Scoring error: TotalMax=0"
  }

  $score = [math]::Round(($totalAchieved / $totalMax) * 100)

  [pscustomobject]@{
    TotalAchieved = [math]::Round($totalAchieved, 2)
    TotalMax = [math]::Round($totalMax, 2)
    Score = [int] $score
  }
}