# WinSecureCheck

Automatisierter Windows Sicherheits- und System-Check mit PowerShell.
Erstellt einen TXT-Report inkl. Sicherheits-Score (0–100).

## Voraussetzungen
- Windows 10/11
- PowerShell 7 (pwsh)
- Ausführung als Administrator (Admin ist Pflicht)

## PowerShell 7 starten
Wenn Windows PowerShell 5.1 geöffnet ist, starte PowerShell 7 so:

```powershell
pwsh
```

Version prüfen:

```powershell
$PSVersionTable.PSVersion
```

## Ausführen
Im Projektordner (als Administrator) ausführen:

```powershell
.\WinSecureCheck.ps1 -ReportPath C:\Temp
```

Optional mit NetworkChecks:

```powershell
.\WinSecureCheck.ps1 -ReportPath C:\Temp -EnableNetworkChecks `
  -NetworkTargetHost www.microsoft.com -NetworkTargetPort 443
```

## Output
- Der Report wird als TXT-Datei im angegebenen `-ReportPath` gespeichert.
- Der Report enthält pro Check Status (Pass/Fail/Unknown/NotRun) und Punkte (x/y),
  sowie eine Gesamtsumme und Score 0–100.

## Projektstruktur
- `WinSecureCheck.ps1`: Orchestrator (Main)
- `src/Checks/*`: einzelne Checks
- `src/Scoring/Score.ps1`: Score-Berechnung
- `src/Reporting/Report.ps1`: Report-Generierung
- `src/Utils/*`: Admin/Run/Params Helpers