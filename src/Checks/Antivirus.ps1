function Get-AntivirusResult {
  [CmdletBinding()]
  param()

  $pointsMax = 20

  try {
    $defenderData = $null
    $defenderError = $null

    try {
      # Available on Windows where Defender module is present
      $defenderData = Get-MpComputerStatus -ErrorAction Stop
    } catch {
      $defenderError = $_.Exception.Message
    }

    $avProducts = $null
    $avProductsError = $null

    try {
      # SecurityCenter2 shows registered AV products (Windows client)
      $avProducts = Get-CimInstance `
        -Namespace "root/SecurityCenter2" `
        -ClassName "AntiVirusProduct" `
        -ErrorAction Stop
    } catch {
      $avProductsError = $_.Exception.Message
    }

    $hasDefenderInfo = $null -ne $defenderData
    $hasProductsInfo = $null -ne $avProducts

    if (-not $hasDefenderInfo -and -not $hasProductsInfo) {
      return New-CheckResult `
        -Name "Antivirus" `
        -Status "Unknown" `
        -Details (
          "Unable to determine AV status. " +
          "DefenderError='$defenderError'; " +
          "SecurityCenter2Error='$avProductsError'"
        ) `
        -Recommendation "Verify that antivirus is installed and active." `
        -PointsMax $pointsMax
    }

    # Determine Defender status (best effort)
    $defenderOk = $null
    if ($hasDefenderInfo) {
      $defenderOk = (
        [bool] $defenderData.AMServiceEnabled -and
        [bool] $defenderData.AntivirusEnabled -and
        [bool] $defenderData.RealTimeProtectionEnabled
      )
    }

    # Determine presence of registered AV products (best effort)
    $productsCount = 0
    $productNames = @()
    if ($hasProductsInfo) {
      $productsCount = @($avProducts).Count
      $productNames = @($avProducts | Select-Object -ExpandProperty displayName)
    }

    # Decision logic:
    # - PASS if Defender is clearly OK OR there is at least one registered AV product.
    # - FAIL if Defender info exists and indicates disabled AND there are no registered products.
    # - UNKNOWN if info is partial/contradictory.
    $detailsParts = New-Object System.Collections.Generic.List[string]

    if ($hasDefenderInfo) {
      $detailsParts.Add(
        "Defender: AMServiceEnabled=$($defenderData.AMServiceEnabled), " +
          "AntivirusEnabled=$($defenderData.AntivirusEnabled), " +
          "RealTimeProtectionEnabled=$($defenderData.RealTimeProtectionEnabled)"
      )
    } else {
      $detailsParts.Add("Defender: not available ($defenderError)")
    }

    if ($hasProductsInfo) {
      $detailsParts.Add(
        "SecurityCenter2 AV products: count=$productsCount, names=$($productNames -join ', ')"
      )
    } else {
      $detailsParts.Add("SecurityCenter2: not available ($avProductsError)")
    }

    $details = $detailsParts -join " | "

    if ($defenderOk -eq $true -or ($hasProductsInfo -and $productsCount -gt 0)) {
      return New-CheckResult `
        -Name "Antivirus" `
        -Status "Pass" `
        -Details $details `
        -Recommendation "Keep antivirus enabled and up to date." `
        -PointsMax $pointsMax `
        -RawData @{
          Defender = $defenderData
          SecurityCenter2 = $avProducts
        }
    }

    if ($defenderOk -eq $false -and (-not $hasProductsInfo -or $productsCount -eq 0)) {
      return New-CheckResult `
        -Name "Antivirus" `
        -Status "Fail" `
        -Details $details `
        -Recommendation "Enable Microsoft Defender or install/enable a trusted antivirus solution." `
        -PointsMax $pointsMax `
        -RawData @{
          Defender = $defenderData
          SecurityCenter2 = $avProducts
        }
    }

    return New-CheckResult `
      -Name "Antivirus" `
      -Status "Unknown" `
      -Details $details `
      -Recommendation "Verify antivirus state manually (data not conclusive)." `
      -PointsMax $pointsMax `
      -RawData @{
        Defender = $defenderData
        SecurityCenter2 = $avProducts
      }
  } catch {
    return New-CheckResult `
      -Name "Antivirus" `
      -Status "Unknown" `
      -Details ("Error determining antivirus status: " + $_.Exception.Message) `
      -Recommendation "Verify antivirus state manually." `
      -PointsMax $pointsMax
  }
}