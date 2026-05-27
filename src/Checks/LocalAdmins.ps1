function Get-LocalAdminsResult {
  [CmdletBinding()]
  param(
    [Parameter()]
    [int] $MaxAdmins = 3,

    [Parameter()]
    [string[]] $BlacklistedAdmins = @("testadmin", "tempadmin")
  )

  try {
    # Get members of local Administrators group
    $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
    $members = @($group.psbase.Invoke("Members")) | ForEach-Object {
      $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)
    }

    $members = $members | Sort-Object
    $count = $members.Count

    $blacklistedFound = @()
    foreach ($m in $members) {
      if ($BlacklistedAdmins -contains $m.ToLower()) {
        $blacklistedFound += $m
      }
    }

    $isTooMany = $count -gt $MaxAdmins
    $hasBlacklist = $blacklistedFound.Count -gt 0

    if ($isTooMany -or $hasBlacklist) {
      $reasons = @()
      if ($isTooMany) { $reasons += "Too many admins ($count > $MaxAdmins)" }
      if ($hasBlacklist) {
        $reasons += "Blacklisted admin(s): " + ($blacklistedFound -join ", ")
      }

      return New-CheckResult `
        -Name "LocalAdmins" `
        -Status "Fail" `
        -Details (
          "Admins: " + ($members -join ", ") + " | " + ($reasons -join "; ")
        ) `
        -Recommendation "Remove unnecessary admin accounts and follow least privilege." `
        -PointsMax 15 `
        -RawData @{ AdminMembers = $members; Count = $count }
    }

    return New-CheckResult `
      -Name "LocalAdmins" `
      -Status "Pass" `
      -Details ("Admins ($count): " + ($members -join ", ")) `
      -Recommendation "Keep the number of administrators low (least privilege)." `
      -PointsMax 15 `
      -RawData @{ AdminMembers = $members; Count = $count }
  } catch {
    return New-CheckResult `
      -Name "LocalAdmins" `
      -Status "Unknown" `
      -Details ("Error reading local administrators: " + $_.Exception.Message) `
      -Recommendation "Verify local admin membership manually." `
      -PointsMax 15
  }
}