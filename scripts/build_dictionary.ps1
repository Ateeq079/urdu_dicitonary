# build_dictionary.ps1
# Processes the MoizRauf TSV files and generates assets/dictionary.json

$ErrorActionPreference = "Stop"

$entries = @{}

function Process-TSV {
    param([string]$Path, [string]$Type)
    
    if (-not (Test-Path $Path)) {
        Write-Host "Skipping $Path (not found)"
        return
    }
    
    $lines = [System.IO.File]::ReadAllLines((Resolve-Path $Path).Path, [System.Text.Encoding]::UTF8)
    
    for ($i = 1; $i -lt $lines.Length; $i++) {
        $parts = $lines[$i] -split "`t"
        if ($parts.Length -lt 4) { continue }
        
        if ($Type -eq "gold") {
            $urdu = $parts[0].Trim()
            $roman = $parts[1].Trim().ToLower()
            $english = $parts[2].Trim().ToLower()
            $urRomScore = 0
            $urEnScore = 0
            [int]::TryParse($parts[3].Trim(), [ref]$urRomScore) | Out-Null
            [int]::TryParse($parts[4].Trim(), [ref]$urEnScore) | Out-Null
            
            if ($urdu -eq "" -or $english -eq "" -or $roman -eq "") { continue }
            if ($urRomScore -lt 3 -or $urEnScore -lt 3) { continue }
            
            # Gold entries override existing
            $entries[$urdu] = @{ urdu = $urdu; roman = $roman; english = $english }
        }
        else {
            $urdu = $parts[0].Trim()
            $roman = $parts[1].Trim().ToLower()
            $urRomScore = 0.0
            $english = $parts[3].Trim().ToLower()
            $urEnScore = 0.0
            [double]::TryParse($parts[2].Trim(), [ref]$urRomScore) | Out-Null
            if ($parts.Length -ge 5) {
                [double]::TryParse($parts[4].Trim(), [ref]$urEnScore) | Out-Null
            }
            
            if ($urdu -eq "" -or $english -eq "" -or $roman -eq "") { continue }
            if ($urdu.Length -lt 2) { continue }
            if ($urEnScore -lt 0.4 -and $english -ne $roman) { continue }
            if ($urRomScore -lt 0.5) { continue }
            
            # First seen wins (higher quality files processed first)
            if (-not $entries.ContainsKey($urdu)) {
                $entries[$urdu] = @{ urdu = $urdu; roman = $roman; english = $english }
            }
        }
    }
}

Write-Host "Processing high-quality entries..."
Process-TSV -Path "scripts/en_ur_rom.high.tsv" -Type "auto"

Write-Host "Processing mid-quality entries..."
Process-TSV -Path "scripts/en_ur_rom.mid.tsv" -Type "auto"

Write-Host "Processing low-quality entries..."
Process-TSV -Path "scripts/en_ur_rom.low.tsv" -Type "auto"

Write-Host "Processing gold annotations (human-verified)..."
Process-TSV -Path "scripts/Gold_Annotations.tsv" -Type "gold"

# Build JSON array
$jsonArray = @()
foreach ($key in ($entries.Keys | Sort-Object)) {
    $e = $entries[$key]
    $jsonArray += @{
        urdu = $e.urdu
        roman = $e.roman
        english = $e.english
    }
}

# Write output
if (-not (Test-Path "assets")) {
    New-Item -ItemType Directory -Path "assets" | Out-Null
}

$jsonString = $jsonArray | ConvertTo-Json -Depth 3 -Compress
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) "assets/dictionary.json"),
    $jsonString,
    [System.Text.Encoding]::UTF8
)

Write-Host ""
Write-Host "Built assets/dictionary.json"
Write-Host "  $($jsonArray.Length) entries"
Write-Host "  $((Get-Item assets/dictionary.json).Length) bytes"
