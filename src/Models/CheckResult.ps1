function New-CheckResult {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $Name,

    [Parameter(Mandatory)]
    [ValidateSet("Pass", "Fail", "Unknown", "NotRun")]
    [string] $Status,

    [Parameter(Mandatory)]
    [string] $Details,

    [Parameter(Mandatory)]
    [string] $Recommendation,

    [Parameter(Mandatory)]
    [int] $PointsMax,

    [Parameter()]
    [hashtable] $RawData = @{}
  )

  [pscustomobject]@{
    Name = $Name
    Status = $Status
    Details = $Details
    Recommendation = $Recommendation
    PointsMax = $PointsMax
    RawData = $RawData
  }
}