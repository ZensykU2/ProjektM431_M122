function Write-GradientText {
  param(
    [string[]]$Lines,
    [hashtable]$StartColor = @{ R = 189; G = 110; B = 255 },
    [hashtable]$EndColor = @{ R = 0; G = 242; B = 254 }
  )
  foreach ($line in $Lines) {
    $len = $line.Length
    if ($len -eq 0) {
      Write-Host ""
      continue
    }
    $output = ""
    for ($i = 0; $i -lt $len; $i++) {
      $ratio = if ($len -gt 1) { $i / ($len - 1) } else { 0.5 }
      $r = [int]($StartColor.R + ($EndColor.R - $StartColor.R) * $ratio)
      $g = [int]($StartColor.G + ($EndColor.G - $StartColor.G) * $ratio)
      $b = [int]($StartColor.B + ($EndColor.B - $StartColor.B) * $ratio)
      $output += "`e[38;2;$r;$g;${b}m" + $line[$i]
    }
    Write-Host "$output`e[0m"
  }
}

function Write-WscBanner {
  $banner = @(
    " ██╗    ██╗██╗███╗   ██╗███████╗███████╗ ██████╗██╗   ██╗██████╗ ███████╗"
    " ██║    ██║██║████╗  ██║██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██╔════╝"
    " ██║ █╗ ██║██║██╔██╗ ██║███████╗█████╗  ██║     ██║   ██║██████╔╝█████╗  "
    " ██║███╗██║██║██║╚██╗██║╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██╔══╝  "
    " ╚███╔███╔╝██║██║ ╚████║███████║███████╗╚██████╗╚██████╔╝██║  ██║███████╗"
    "  ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝"
  )

  Write-GradientText -Lines $banner
  Write-Host ""

  $hostName = $env:COMPUTERNAME
  $userName = $env:USERNAME
  
  $osInfo = "Windows (Alternative)"
  try {
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
  } catch {}
  
  $psVersion = $PSVersionTable.PSVersion.ToString()
  $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

  Write-Host "`e[38;2;138;43;226m╭────────────────────────────────────────────────────────────────────────╮`e[0m"
  Write-Host "`e[38;2;138;43;226m│`e[0m  `e[1;38;2;0;242;254mSYSTEM SECURITY AUDIT`e[0m                                             `e[38;2;138;43;226m│`e[0m"
  Write-Host "`e[38;2;138;43;226m│`e[0m  `e[38;2;156;163;175mOS:   `e[0m $($osInfo.PadRight(56).Substring(0, 56)) `e[38;2;138;43;226m│`e[0m"
  Write-Host "`e[38;2;138;43;226m│`e[0m  `e[38;2;156;163;175mHost: `e[0m $($hostName.PadRight(56).Substring(0, 56)) `e[38;2;138;43;226m│`e[0m"
  Write-Host "`e[38;2;138;43;226m│`e[0m  `e[38;2;156;163;175mUser: `e[0m $($userName.PadRight(56).Substring(0, 56)) `e[38;2;138;43;226m│`e[0m"
  Write-Host "`e[38;2;138;43;226m│`e[0m  `e[38;2;156;163;175mDate: `e[0m $($date.PadRight(56).Substring(0, 56)) `e[38;2;138;43;226m│`e[0m"
  Write-Host "`e[38;2;138;43;226m╰────────────────────────────────────────────────────────────────────────╯`e[0m"
  Write-Host ""
}

function Write-ScanStart {
  param([string]$Name)
  Write-Host "`e[38;2;156;163;175m[ `e[38;2;138;43;226m⚙`e[38;2;156;163;175m ]`e[0m `e[1m$Name`e[0m`e[38;2;107;114;128m - Scanning and evaluating security state...`e[0m"
}

function Write-ScanFinish {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Details
  )

  # Move cursor up 1 line and clear it
  Write-Host -NoNewline "`e[1A`e[2K"

  $badge = switch ($Status) {
    "Pass" { "`e[38;2;74;222;128m[ ✔ PASS ]`e[0m" }
    "Fail" { "`e[38;2;248;113;113m[ ✘ FAIL ]`e[0m" }
    "Unknown" { "`e[38;2;251;191;36m[ ⚠ WARN ]`e[0m" }
    "NotRun" { "`e[38;2;156;163;175m[ ⊖ SKIP ]`e[0m" }
  }

  $cleanDetails = $Details
  if ($cleanDetails.Length -gt 70) {
    $cleanDetails = $cleanDetails.Substring(0, 67) + "..."
  }

  Write-Host "$badge `e[1m$Name`e[0m`e[38;2;156;163;175m: $cleanDetails`e[0m"
}

function Write-WscSummaryDashboard {
  param(
    [System.Collections.Generic.List[object]] $Results,
    [int] $Score,
    [double] $TotalAchieved,
    [double] $TotalMax,
    [string] $ReportFilePath
  )

  Write-Host ""
  Write-Host "`e[1;38;2;189;110;255mAUDIT RESULTS SUMMARY`e[0m"
  Write-Host "`e[38;2;107;114;128m" + ("=" * 80) + "`e[0m"

  # Score gauge
  $filledLength = [int][math]::Round(($Score / 100) * 30)
  $emptyLength = 30 - $filledLength
  $gaugeStr = ("█" * $filledLength) + ("░" * $emptyLength)

  $scoreColor = if ($Score -ge 80) {
    "`e[38;2;74;222;128m"
  } elseif ($Score -ge 50) {
    "`e[38;2;251;191;36m"
  } else {
    "`e[38;2;248;113;113m"
  }

  Write-Host ""
  Write-Host "  `e[1mSecurity Score: `e[0m$scoreColor$Score / 100`e[0m  [$scoreColor$gaugeStr`e[0m] ($TotalAchieved / $TotalMax pts)"
  Write-Host ""

  Write-Host "  `e[1;4mCheck Name`e[0m         `e[1;4mStatus`e[0m     `e[1;4mPoints`e[0m     `e[1;4mRecommendation`e[0m"

  foreach ($r in $Results) {
    $pointsAchieved = switch ($r.Status) {
      "Pass" { $r.PointsMax }
      "Fail" { 0 }
      "Unknown" { [math]::Round($r.PointsMax * 0.5, 2) }
      "NotRun" { 0 }
    }

    $statusStr = switch ($r.Status) {
      "Pass" { "`e[38;2;74;222;128mPass`e[0m" }
      "Fail" { "`e[38;2;248;113;113mFail`e[0m" }
      "Unknown" { "`e[38;2;251;191;36mWarn`e[0m" }
      "NotRun" { "`e[38;2;156;163;175mSkip`e[0m" }
    }

    $pointsStr = "$pointsAchieved/$($r.PointsMax)"
    $rec = $r.Recommendation
    if ($rec.Length -gt 42) {
      $rec = $rec.Substring(0, 39) + "..."
    }

    $pName = $r.Name.PadRight(18)
    $rawStatusPad = $r.Status.PadRight(10)
    $styledStatus = $rawStatusPad.Replace($r.Status, $statusStr)
    $pPoints = $pointsStr.PadRight(10)

    Write-Host "  $pName $styledStatus $pPoints $rec"
  }

  Write-Host ""
  Write-Host "`e[38;2;107;114;128m" + ("=" * 80) + "`e[0m"
  Write-Host "  `e[1;38;2;74;222;128m✔`e[0m Report generated: `e[4;38;2;0;191;255m$ReportFilePath`e[0m"
  Write-Host ""
}
