function Get-NetworkChecksResult {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $HostName,

    [Parameter(Mandatory)]
    [ValidateRange(1, 65535)]
    [int] $Port
  )

  $pointsMax = 10

  $dnsStatus = "Unknown"
  $pingStatus = "Unknown"
  $portStatus = "Unknown"

  $dnsDetail = ""
  $pingDetail = ""
  $portDetail = ""

  try {
    # DNS
    try {
      $dns = Resolve-DnsName -Name $HostName -ErrorAction Stop
      $dnsStatus = "Pass"
      $dnsDetail = "Resolved"
    } catch {
      $msg = $_.Exception.Message
      # If host truly not found -> Fail, else Unknown (timeout, DNS unavailable)
      if ($msg -match "non-existent domain|does not exist|NXDOMAIN|Name does not exist") {
        $dnsStatus = "Fail"
      } else {
        $dnsStatus = "Unknown"
      }
      $dnsDetail = $msg
    }

    # Ping
    try {
      $pingOk = Test-Connection -ComputerName $HostName -Count 1 -Quiet -ErrorAction Stop
      $pingStatus = if ($pingOk) { "Pass" } else { "Fail" }
      $pingDetail = if ($pingOk) { "Reachable" } else { "No reply" }
    } catch {
      $pingStatus = "Unknown"
      $pingDetail = $_.Exception.Message
    }

    # Port test
    try {
      $tcpOk = Test-NetConnection `
        -ComputerName $HostName `
        -Port $Port `
        -InformationLevel Quiet `
        -WarningAction SilentlyContinue `
        -ErrorAction Stop

      $portStatus = if ($tcpOk) { "Pass" } else { "Fail" }
      $portDetail = if ($tcpOk) { "TCP OK" } else { "TCP failed" }
    } catch {
      $portStatus = "Unknown"
      $portDetail = $_.Exception.Message
    }

    $details = "DNS=$dnsStatus ($dnsDetail) | Ping=$pingStatus ($pingDetail) | Port=$portStatus ($portDetail)"

    # Overall status logic:
    # - Any Fail => Fail
    # - Else any Unknown => Unknown
    # - Else Pass
    $subStatuses = @($dnsStatus, $pingStatus, $portStatus)
    if ($subStatuses -contains "Fail") {
      return New-CheckResult `
        -Name "NetworkChecks" `
        -Status "Fail" `
        -Details $details `
        -Recommendation "Check DNS settings, routing/connectivity, and outbound firewall rules." `
        -PointsMax $pointsMax `
        -RawData @{
          Host = $HostName
          Port = $Port
          DnsStatus = $dnsStatus
          PingStatus = $pingStatus
          PortStatus = $portStatus
        }
    }

    if ($subStatuses -contains "Unknown") {
      return New-CheckResult `
        -Name "NetworkChecks" `
        -Status "Unknown" `
        -Details $details `
        -Recommendation "Network check was inconclusive (timeouts/errors). Verify connectivity manually." `
        -PointsMax $pointsMax `
        -RawData @{
          Host = $HostName
          Port = $Port
          DnsStatus = $dnsStatus
          PingStatus = $pingStatus
          PortStatus = $portStatus
        }
    }

    return New-CheckResult `
      -Name "NetworkChecks" `
      -Status "Pass" `
      -Details $details `
      -Recommendation "Connectivity looks good." `
      -PointsMax $pointsMax `
      -RawData @{
        Host = $HostName
        Port = $Port
        DnsStatus = $dnsStatus
        PingStatus = $pingStatus
        PortStatus = $portStatus
      }
  } catch {
    return New-CheckResult `
      -Name "NetworkChecks" `
      -Status "Unknown" `
      -Details ("Error running network checks: " + $_.Exception.Message) `
      -Recommendation "Verify network connectivity manually." `
      -PointsMax $pointsMax
  }
}