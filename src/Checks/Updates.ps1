function Get-UpdatesResult {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [int] $ThresholdDays
  )

  try {
    $hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending
    $last = $hotfixes | Select-Object -First 1

    if ($null -eq $last) {
      return New-CheckResult `
        -Name "Updates" `
        -Status "Unknown" `
        -Details "No hotfix data found." `
        -Recommendation "Verify update status manually." `
        -PointsMax 20
    }

    $days = (New-TimeSpan -Start $last.InstalledOn -End (Get-Date)).Days
    $details = "Last update: $($last.InstalledOn.ToString('yyyy-MM-dd')) ($days days ago)"

    if ($days -le $ThresholdDays) {
      return New-CheckResult `
        -Name "Updates" `
        -Status "Pass" `
        -Details $details `
        -Recommendation "Keep installing updates regularly." `
        -PointsMax 20 `
        -RawData @{ LastHotFix = $last }
    }

    return New-CheckResult `
      -Name "Updates" `
      -Status "Fail" `
      -Details ($details + " (older than $ThresholdDays days)") `
      -Recommendation "Install Windows updates within 30 days." `
      -PointsMax 20 `
      -RawData @{ LastHotFix = $last }
  } catch {
    return New-CheckResult `
      -Name "Updates" `
      -Status "Unknown" `
      -Details ("Error reading updates: " + $_.Exception.Message) `
      -Recommendation "Verify updates manually." `
      -PointsMax 20
  }
}