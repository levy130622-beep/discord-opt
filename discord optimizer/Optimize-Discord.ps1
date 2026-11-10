<#
.SYNOPSIS
    Script de optimizare Discord pentru partajare de ecran (Screen Share) fara lag.
    Creat special pentru PC-uri / laptopuri cu placi video integrate (Intel HD/UHD) si procesoare cu resurse limitate.
#>

param(
    [switch]$Auto,
    [switch]$DisableHardwareAcceleration,
    [switch]$EnableHardwareAcceleration
)

# Setare codare UTF-8 pentru consola Windows
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "         DISCORD STREAM & SCREEN SHARE OPTIMIZER               " -ForegroundColor Yellow -NoNewline
    Write-Host "  v1.1" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-HardwareDetails {
    Write-Host "[*] Detectare componente sistem..." -ForegroundColor Gray
    $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
    $gpu = (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join " / "
    $ramGB = [math]::Round(((Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).TotalVisibleMemorySize / 1MB), 1)

    Write-Host "  -> CPU: $cpu" -ForegroundColor White
    Write-Host "  -> GPU: $gpu" -ForegroundColor White
    Write-Host "  -> RAM: $ramGB GB" -ForegroundColor White
    Write-Host ""

    return @{
        CPU = $cpu
        GPU = $gpu
        RAM = $ramGB
        IsIntelHD = ($gpu -match "Intel.*HD|Intel.*UHD|Intel.*Graphics")
    }
}

function Stop-DiscordProcess {
    $processes = Get-Process -Name "Discord" -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "[!] Inchidere procese Discord active..." -ForegroundColor Yellow
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "  [OK] Discord a fost oprit." -ForegroundColor Green
    } else {
        Write-Host "[i] Discord nu ruleaza in acest moment." -ForegroundColor Gray
    }
    Write-Host ""
}

function Clear-DiscordCache {
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " 1. CURATARE CACHE & SHADERE GPU DISCORD" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " Curata shaderele GPU corupte si cache-ul fara sa te delogheze." -ForegroundColor Gray
    Write-Host ""

    $appData = $env:APPDATA
    $discordPath = Join-Path $appData "discord"

    if (-not (Test-Path $discordPath)) {
        Write-Host "  [X] Folderul Discord din %appdata% nu a fost gasit." -ForegroundColor Red
        return
    }

    $cacheFolders = @(
        "Cache",
        "Code Cache",
        "DawnGraphiteCache",
        "DawnWebGPUCache",
        "GPUCache",
        "GPUPersistentCache",
        "GrShaderCache",
        "ShaderCache",
        "Crashpad",
        "logs",
        "sentry",
        "VideoDecodeStats",
        "blob_storage"
    )

    $deletedCount = 0
    $freedBytes = 0

    foreach ($folder in $cacheFolders) {
        $target = Join-Path $discordPath $folder
        if (Test-Path $target) {
            try {
                $files = Get-ChildItem -Path $target -Recurse -File -Force -ErrorAction SilentlyContinue
                if ($files) {
                    $size = ($files | Measure-Object -Property Length -Sum).Sum
                    if ($size) { $freedBytes += $size }
                }
                Remove-Item -Path $target -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  [+] Sters: $folder" -ForegroundColor DarkGray
                $deletedCount++
            } catch {
                Write-Host "  [-] Nu s-a putut sterge complet: $folder" -ForegroundColor DarkYellow
            }
        }
    }

    $freedMB = [math]::Round($freedBytes / 1MB, 2)
    Write-Host "  [OK] S-au curatat $deletedCount foldere cache ($freedMB MB eliberati)." -ForegroundColor Green
    Write-Host ""
}

function Optimize-DiscordSettings {
    param([bool]$DisableHardwareAccel = $false)

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " 2. OPTIMIZARE SETARI INTERNE (settings.json)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan

    $settingsPath = Join-Path $env:APPDATA "discord\settings.json"

    $settings = $null
    if (Test-Path $settingsPath) {
        try {
            $rawContent = Get-Content -Path $settingsPath -Raw -ErrorAction Stop
            $settings = $rawContent | ConvertFrom-Json
            # Creare backup
            $backupPath = "$settingsPath.backup"
            Copy-Item -Path $settingsPath -Destination $backupPath -Force
            Write-Host "  [+] Backup creat: settings.json.backup" -ForegroundColor DarkGray
        } catch {
            Write-Host "  [!] Structura invalida, se initializeaza una curata." -ForegroundColor DarkYellow
        }
    }

    if ($null -eq $settings) {
        $settings = [PSCustomObject]@{
            BACKGROUND_COLOR = "#000000"
            DESKTOP_TTI_HTTP_CDT = $true
            chromiumSwitches = [PSCustomObject]@{}
            IS_MAXIMIZED = $true
            IS_MINIMIZED = $false
        }
    }

    # Audio experimental cauzeaza 100% CPU spike si lag masiv la partajare de ecran pe procesoare Dual/Quad-Core
    Write-Host "  [>] Setare subsistem audio: 'standard' (elimina spike-urile de CPU)" -ForegroundColor Cyan
    $settings | Add-Member -NotePropertyName "audioSubsystem" -NotePropertyValue "standard" -Force

    $settings | Add-Member -NotePropertyName "offloadAdmControls" -NotePropertyValue $true -Force
    $settings | Add-Member -NotePropertyName "DESKTOP_FULLSCREEN_POPUP_OCCLUSION" -NotePropertyValue $true -Force

    if ($DisableHardwareAccel) {
        Write-Host "  [>] Dezactivare Accelerare Hardware (Recomandat pentru placa video Intel HD 4600)" -ForegroundColor Cyan
        $settings | Add-Member -NotePropertyName "enableHardwareAcceleration" -NotePropertyValue $false -Force
    } else {
        Write-Host "  [i] Accelerarea Hardware este activata." -ForegroundColor Gray
        $settings | Add-Member -NotePropertyName "enableHardwareAcceleration" -NotePropertyValue $true -Force
    }

    try {
        $newJson = $settings | ConvertTo-Json -Depth 5
        Set-Content -Path $settingsPath -Value $newJson -Encoding UTF8
        Write-Host "  [OK] Fisierul settings.json a fost optimizat cu succes!" -ForegroundColor Green
    } catch {
        Write-Host "  [X] Nu s-au putut salva setarile: $_" -ForegroundColor Red
    }
    Write-Host ""
}

function Set-ProcessAndGraphicsPriority {
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " 3. PRIORITATE PROCES & OPTIMIZARE GRAFICA WINDOWS" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan

    # 1. Configurare preferinta GPU in Windows (DirectX UserGpuPreferences)
    $latestApp = Get-ChildItem -Path "$env:LOCALAPPDATA\Discord" -Directory -Filter "app-*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($latestApp) {
        $discordExe = Join-Path $latestApp.FullName "Discord.exe"
    } else {
        $discordExe = Join-Path $env:LOCALAPPDATA "Discord\Discord.exe"
    }

    if (Test-Path $discordExe) {
        try {
            $regPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            # GpuPreference=1 (Power saving / Integrated GPU)
            Set-ItemProperty -Path $regPath -Name $discordExe -Value "GpuPreference=1;" -Force
            Write-Host "  [OK] Preferinta GPU DirectX setata pentru Discord.exe" -ForegroundColor Green
        } catch {
            Write-Host "  [-] Nu s-a putut scrie in UserGpuPreferences: $_" -ForegroundColor DarkYellow
        }
    }

    # 2. Prioritate IFEO (Daca scriptul ruleaza ca Administrator)
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        try {
            $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Discord.exe\PerfOptions"
            if (-not (Test-Path $ifeoPath)) {
                New-Item -Path $ifeoPath -Force | Out-Null
            }
            # 6 = Above Normal (asigura ca stream-ul nu se blocheaza cand te joci sau ai alt program in prim-plan)
            Set-ItemProperty -Path $ifeoPath -Name "CpuPriorityClass" -Value 6 -Type DWord -Force
            Write-Host "  [OK] Prioritate CPU permanenta setata pe 'Above Normal' in Registru." -ForegroundColor Green
        } catch {
            Write-Host "  [-] Nu s-a putut scrie in Registrul HKLM: $_" -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "  [i] Sfat: Daca rulezi scriptul ca Administrator (Run as Administrator), se aplica prioritate mare automata." -ForegroundColor Gray
    }
    Write-Host ""
}

function Show-InAppSettingsGuide {
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " 4. GHID: SETARI ESENTIALE IN INTERIORUL DISCORD" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "Aceste optiuni din aplicatia Discord fac CEA MAI MARE diferenta la partajare:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Deschide Discord -> Setari utilizator (rotita de jos de langa nume):" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  A. [Voce si video] (Voice & Video) -> deruleaza la [AVANSAT]:" -ForegroundColor Yellow
    Write-Host "     1. [OpenH264 Video Codec]                       -> ACTIVEAZA (ON)" -ForegroundColor Green
    Write-Host "     2. [H.264 Hardware Acceleration]                -> DEZACTIVEAZA (OFF) <--" -ForegroundColor Red
    Write-Host "        *(Pe Intel HD Graphics, accelerarea H.264 sugruma placa video si blocheaza stream-ul!)*" -ForegroundColor DarkGray
    Write-Host "     3. [Foloseste tehnologia avansata de captura]   -> DEZACTIVEAZA (OFF) <--" -ForegroundColor Red
    Write-Host "        *(Use our latest technology to capture your screen - consuma mult GPU)*" -ForegroundColor DarkGray
    Write-Host "     4. [Foloseste metoda experimentala audio]       -> DEZACTIVEAZA (OFF) <--" -ForegroundColor Red
    Write-Host "     5. [Calitate a serviciului cu prioritate ridicata pachete] (QoS) -> DEZACTIVEAZA (OFF)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  B. [Setari cand dai Partajare / Go Live]:" -ForegroundColor Yellow
    Write-Host "     * Rezolutie: 720p" -ForegroundColor Green
    Write-Host "     * Frame rate: 30 FPS (NU 60 FPS!)" -ForegroundColor Green
    Write-Host "     * Alege sa partajezi aplicatia/fereastra specifica (NU intregul 'Ecran 1')." -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- LOGICA PRINCIPALA ---
Show-Header
$hw = Get-HardwareDetails

if ($Auto) {
    Stop-DiscordProcess
    Clear-DiscordCache
    Optimize-DiscordSettings -DisableHardwareAccel ($hw.IsIntelHD)
    Set-ProcessAndGraphicsPriority
    Show-InAppSettingsGuide
    Write-Host "[FINALIZAT] Optimizarea automata a fost aplicata cu succes!" -ForegroundColor Green
    exit 0
}

Write-Host "Alege o optiune:" -ForegroundColor White
Write-Host " 1. [RECOMANDAT] Optimizare completa automata (Curatare cache + Setari iGPU)" -ForegroundColor Green
Write-Host " 2. Doar curatare cache Discord (rezolva blocajele fara schimbari de setari)" -ForegroundColor White
Write-Host " 3. Dezactiveaza Accelerarea Hardware (vital pentru procesoare i3/i5 cu Intel HD)" -ForegroundColor White
Write-Host " 4. Reactiveaza Accelerarea Hardware" -ForegroundColor White
Write-Host " 5. Afiseaza doar ghidul de setari din interiorul Discord" -ForegroundColor White
Write-Host " 0. Iesire" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Introdu numarul optiunii (1-5)"

switch ($choice) {
    "1" {
        Stop-DiscordProcess
        Clear-DiscordCache
        Optimize-DiscordSettings -DisableHardwareAccel ($hw.IsIntelHD)
        Set-ProcessAndGraphicsPriority
        Show-InAppSettingsGuide
    }
    "2" {
        Stop-DiscordProcess
        Clear-DiscordCache
    }
    "3" {
        Stop-DiscordProcess
        Optimize-DiscordSettings -DisableHardwareAccel $true
        Write-Host "Accelerarea Hardware a fost dezactivata." -ForegroundColor Green
    }
    "4" {
        Stop-DiscordProcess
        Optimize-DiscordSettings -DisableHardwareAccel $false
        Write-Host "Accelerarea Hardware a fost activata." -ForegroundColor Green
    }
    "5" {
        Show-InAppSettingsGuide
    }
    default {
        Write-Host "Nicio modificare efectuata." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Apasa Enter pentru a finaliza..." -ForegroundColor Gray
Read-Host
