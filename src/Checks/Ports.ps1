function Get-PortsResult {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [int[]] $CriticalPorts
  )

  $pointsMax = 10

  try {
    # --- TCP Listening (reliable) ---
    $tcpListening = @(
      Get-NetTCPConnection -State Listen -ErrorAction Stop |
        Select-Object -ExpandProperty LocalPort -Unique
    )

    $criticalTcp = @($tcpListening | Where-Object { $CriticalPorts -contains $_ })

    if ($criticalTcp.Count -gt 0) {
      $criticalTcpSorted = $criticalTcp | Sort-Object
      return New-CheckResult `
        -Name "Ports" `
        -Status "Fail" `
        -Details ("Critical TCP ports listening: " + ($criticalTcpSorted -join ", ")) `
        -Recommendation "Close/disable unnecessary services or restrict access with firewall rules." `
        -PointsMax $pointsMax `
        -RawData @{
          TcpListeningPorts = ($tcpListening | Sort-Object)
          CriticalTcp = $criticalTcpSorted
        }
    }

    # --- UDP Endpoints (best effort) ---
    try {
      $udpEndpoints = @(
        Get-NetUDPEndpoint -ErrorAction Stop |
          Select-Object -ExpandProperty LocalPort -Unique
      )
    } catch {
      return New-CheckResult `
        -Name "Ports" `
        -Status "Unknown" `
        -Details (
          "TCP ok (no critical TCP ports). UDP endpoints not determinable: " +
          $_.Exception.Message
        ) `
        -Recommendation "Review UDP services manually if required." `
        -PointsMax $pointsMax `
        -RawData @{
          TcpListeningPorts = ($tcpListening | Sort-Object)
          CriticalTcp = @()
        }
    }

    $criticalUdp = @($udpEndpoints | Where-Object { $CriticalPorts -contains $_ })

    if ($criticalUdp.Count -gt 0) {
      $criticalUdpSorted = $criticalUdp | Sort-Object
      return New-CheckResult `
        -Name "Ports" `
        -Status "Fail" `
        -Details ("Critical UDP ports detected: " + ($criticalUdpSorted -join ", ")) `
        -Recommendation "Close/disable unnecessary UDP services or restrict exposure." `
        -PointsMax $pointsMax `
        -RawData @{
          TcpListeningPorts = ($tcpListening | Sort-Object)
          UdpPorts = ($udpEndpoints | Sort-Object)
          CriticalTcp = @()
          CriticalUdp = $criticalUdpSorted
        }
    }

    return New-CheckResult `
      -Name "Ports" `
      -Status "Pass" `
      -Details "No critical TCP/UDP ports detected." `
      -Recommendation "Keep only required services exposed; review listening ports regularly." `
      -PointsMax $pointsMax `
      -RawData @{
        TcpListeningPorts = ($tcpListening | Sort-Object)
        UdpPorts = ($udpEndpoints | Sort-Object)
        CriticalTcp = @()
        CriticalUdp = @()
      }
  } catch {
    return New-CheckResult `
      -Name "Ports" `
      -Status "Unknown" `
      -Details ("Error determining ports: " + $_.Exception.Message) `
      -Recommendation "Review listening services manually." `
      -PointsMax $pointsMax
  }
}