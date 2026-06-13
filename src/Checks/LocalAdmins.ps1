function Get-LocalAdminsResult {
  [CmdletBinding()]
  param(
    [Parameter()]
    [int] $MaxAdmins = 3,

    [Parameter()]
    [string[]] $BlacklistedAdmins = @("testadmin", "tempadmin")
  )

  $pointsMax = 15

  try {
    # Built-in local Administrators group SID (language independent)
    $adminGroupSid = "S-1-5-32-544"

    $adminGroupName = (Get-LocalGroup -SID $adminGroupSid -ErrorAction Stop).Name

    # Get members of the local Administrators group
    $members = @(
      Get-LocalGroupMember -Group $adminGroupName -ErrorAction Stop |
        Select-Object -ExpandProperty Name
    ) | Sort-Object

    $count = $members.Count

    $blacklistedFound = @()
    foreach ($m in $members) {
      $simple = ($m -split "\\")[-1].ToLowerInvariant()
      if ($BlacklistedAdmins -contains $simple) {
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
        -Details ("Admins ($count): " + ($members -join ", ") + " | " + ($reasons -join "; ")) `
        -Recommendation "Remove unnecessary admin accounts and follow least privilege." `
        -PointsMax $pointsMax `
        -RawData @{ Group = $adminGroupName; Members = $members; Count = $count }
    }

    return New-CheckResult `
      -Name "LocalAdmins" `
      -Status "Pass" `
      -Details ("Admins ($count): " + ($members -join ", ")) `
      -Recommendation "Keep the number of administrators low (least privilege)." `
      -PointsMax $pointsMax `
      -RawData @{ Group = $adminGroupName; Members = $members; Count = $count }
  } catch {
    return New-CheckResult `
      -Name "LocalAdmins" `
      -Status "Unknown" `
      -Details ("Error reading local administrators: " + $_.Exception.Message) `
      -Recommendation "Verify local admin membership manually." `
      -PointsMax $pointsMax
  }
}