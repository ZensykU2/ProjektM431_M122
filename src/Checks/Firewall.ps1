function Get-FirewallResult {
  [CmdletBinding()]
  param()

  try {
    $profiles = Get-NetFirewallProfile
    $disabled = $profiles | Where-Object { -not $_.Enabled } | Select-Object -ExpandProperty Name

    if ($null -eq $disabled -or $disabled.Count -eq 0) {
      return New-CheckResult `
        -Name "Firewall" `
        -Status "Pass" `
        -Details "All firewall profiles enabled (Domain/Private/Public)." `
        -Recommendation "Keep Windows Firewall enabled for all profiles." `
        -PointsMax 25 `
        -RawData @{ Profiles = $profiles }
    }

    return New-CheckResult `
      -Name "Firewall" `
      -Status "Fail" `
      -Details ("Disabled profiles: " + ($disabled -join ", ")) `
      -Recommendation "Enable Windows Firewall for all profiles." `
      -PointsMax 25 `
      -RawData @{ Profiles = $profiles }
  } catch {
    return New-CheckResult `
      -Name "Firewall" `
      -Status "Unknown" `
      -Details ("Error reading firewall profiles: " + $_.Exception.Message) `
      -Recommendation "Verify firewall status manually." `
      -PointsMax 25
  }
}