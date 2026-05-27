function Get-WscParams {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [hashtable] $BoundParameters
  )

  $reportPath = if ($BoundParameters.ContainsKey("ReportPath")) {
    [string] $BoundParameters.ReportPath
  } else {
    "."
  }

  $enableNet = if ($BoundParameters.ContainsKey("EnableNetworkChecks")) {
    [bool] $BoundParameters.EnableNetworkChecks
  } else {
    $false
  }

  $hostName = if ($BoundParameters.ContainsKey("NetworkTargetHost")) {
    [string] $BoundParameters.NetworkTargetHost
  } else {
    "www.microsoft.com"
  }

  $port = if ($BoundParameters.ContainsKey("NetworkTargetPort")) {
    [int] $BoundParameters.NetworkTargetPort
  } else {
    443
  }

  [pscustomobject]@{
    ReportPath = $reportPath
    EnableNetworkChecks = $enableNet
    NetworkTargetHost = $hostName
    NetworkTargetPort = $port
  }
}

function Test-WscParams {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [pscustomobject] $Params
  )

  if ([string]::IsNullOrWhiteSpace($Params.ReportPath)) { return $false }
  if ([string]::IsNullOrWhiteSpace($Params.NetworkTargetHost)) { return $false }
  if ($Params.NetworkTargetPort -lt 1 -or $Params.NetworkTargetPort -gt 65535) {
    return $false
  }

  try {
    if (-not (Test-Path -LiteralPath $Params.ReportPath)) {
      New-Item -ItemType Directory -Path $Params.ReportPath -Force | Out-Null
    }
    return $true
  } catch {
    return $false
  }
}