# =========================================================================
#  ABYZOTH SCAN - Sistema de Auditoría Forense y Anti-Bypass para SS
# =========================================================================
#  Desarrollado por: IkxPzl
#  Requisito: Ejecutar en una consola de PowerShell como Administrador.

Clear-Host
$Version = "4.0.0"
$FechaActual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$RutaReporte = "$env:USERPROFILE\Desktop\Abyzoth_Scan_Report_$FechaActual.txt"

# -------------------------------------------------------------------------
# INICIALIZACIÓN DE ARCHIVO DE REPORTE Y CABECERA (ESTRUCTURA GENERAL)
# -------------------------------------------------------------------------
@"
=========================================================================
                         ABYZOTH SCAN v$Version                          
=========================================================================
 Desarrollado por   : IkxPzl
 Fecha de Análisis  : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
 Operador de la SS  : $env:USERNAME
 Dispositivo Local  : $env:COMPUTERNAME
=========================================================================

"@ | Out-File -FilePath $RutaReporte -Encoding utf8

Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "                             ABYZOTH SCAN v$Version                       " -ForegroundColor Red
Write-Host "                       DESARROLLADO POR: IKXPZL                          " -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Inicializando los motores forenses..." -ForegroundColor Gray
Add-Content -Path $RutaReporte -Value "[$(Get-Date -Format 'HH:mm:ss')] Inicializando los motores forenses..."

# Diccionarios expandidos de firmas y palabras clave sospechosas
$FfmpegStrings = @(
    "ffmpeg", "grabadora", "record", "stream", "obs", "d3d", "capture", 
    "zen", "mozilla", "firefox", "file:", "medal", "action", "bandicam", 
    "sharex", "vlc", "lightshot", "overwolf", "shadowplay", "relive", 
    "screen", "recorder", "overlay", "injector", "temp"
)
$AhkStrings = @("macro", "trigger", "recoil", "aim", "cheat", "bhop", "script", "hotkey")

# Whitelist optimizada (Se añadieron NVIDIA, Discord, Steam, Epic y aplicaciones nativas)
$WhitelistPaths = @("roblox", "overwolf", "nvidia", "discord", "spotify", "steam", "epicgames", "microsoft")


# =========================================================================
# PRIMER MÓDULO: TELEMETRÍA DE PYTHON Y REGISTRO DE COMANDOS
# =========================================================================
Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "[MÓDULO 1] Analizando historial de líneas de comandos (Python / Shell)..." -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray
Add-Content -Path $RutaReporte -Value "`n[MÓDULO 1] Analizando historial de líneas de comandos (Python / Shell)..."

$SecurityEvents = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -ErrorAction SilentlyContinue
$AlertaModulo1 = $false

foreach ($Event in $SecurityEvents) {
    $MessageLower = $Event.Message.ToLower()
    if ($MessageLower -match "python" -or $MessageLower -match "cmd.exe" -or $MessageLower -match "powershell.exe") {
        foreach ($String in $FfmpegStrings) {
            if ($MessageLower -like "*$String*") {
                $HoraEvento = $Event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "[$HoraEvento] [!] CRÍTICO: Comando sospechoso detectado -> '$String'" -ForegroundColor Red
                Add-Content -Path $RutaReporte -Value "[ALERTA] [$HoraEvento] [!] CRÍTICO: Comando sospechoso detectado -> '$String'"
                Add-Content -Path $RutaReporte -Value "    └─ Detalle Técnico: $($Event.Message -replace '\s+', ' ')"
                $AlertaModulo1 = $true
            }
        }
    }
}

if (-not $AlertaModulo1) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: No se hallaron anomalías en la telemetría de comandos." -ForegroundColor Green
    Add-Content -Path $RutaReporte -Value "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: No se hallaron anomalías en la telemetría de comandos."
}


# =========================================================================
# SEGUNDO MÓDULO: PROCESOS EN MEMORIA E HISTORIALES (AHK / PSR)
# =========================================================================
Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "[MÓDULO 2] Inspeccionando memoria volátil, procesos activos y PSR..." -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray
Add-Content -Path $RutaReporte -Value "`n[MÓDULO 2] Inspeccionando memoria volátil, procesos activos y PSR..."

# Escaneo de procesos en memoria (Se incluyó PSR - Grabadora de acciones)
$ProcesosSospechosos = Get-Process | Where-Object {
    $_.Name -match "zen" -or $_.Name -match "firefox" -or $_.Name -match "obs" -or 
    $_.Name -match "medal" -or $_.Name -match "ShareX" -or $_.Name -match "AutoHotkey" -or
    $_.Name -match "psr"
}

$ProcesoActivo = $false
foreach ($Proc in $ProcesosSospechosos) {
    try { $Path = $Proc.Path } catch { $Path = "Acceso Denegado / Binario Oculto" }
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] [!] PROCESO ACTIVO: Se está ejecutando '$($Proc.Name)' (PID: $($Proc.Id))" -ForegroundColor DarkYellow
    Add-Content -Path $RutaReporte -Value "[ALERTA] [$Timestamp] [!] PROCESO ACTIVO: Se está ejecutando '$($Proc.Name)' (PID: $($Proc.Id))"
    Add-Content -Path $RutaReporte -Value "    └─ Ubicación: $Path"
    $ProcesoActivo = $true
}

if (-not $ProcesoActivo) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: No hay aplicaciones de captura, PSR o macros en memoria." -ForegroundColor Green
    Add-Content -Path $RutaReporte -Value "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: No hay aplicaciones de captura, PSR o macros en memoria."
}

# Historial reciente de archivos abiertos (.ahk / .py)
$RecentFiles = Get-ChildItem "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "\.ahk" -or $_.Name -match "\.py" -or $_.Name -match "zen" -or $_.Name -match "mozilla" }

foreach ($File in $RecentFiles) {
    $HoraModificacion = $File.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$HoraModificacion] [!] HISTORIAL: Archivo abierto recientemente -> $($File.Name)" -ForegroundColor Magenta
    Add-Content -Path $RutaReporte -Value "[ALERTA] [$HoraModificacion] [!] HISTORIAL: Archivo abierto recientemente -> $($File.Name)"
}


# =========================================================================
# TERCER MÓDULO: PERSISTENCIA DE SCRIPTS (.BAT) VÍA PCASVC
# =========================================================================
Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "[MÓDULO 3] Extrayendo logs imborrables de PcaSvc (Program Telemetry)..." -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray
Add-Content -Path $RutaReporte -Value "`n[MÓDULO 3] Extrayendo logs imborrables de PcaSvc (Program Telemetry)..."

$PcaLogPath = "Microsoft-Windows-Application-Experience/Program-Telemetry"
$PcaEvents = Get-WinEvent -FilterHashtable @{LogName=$PcaLogPath; Id=100} -ErrorAction SilentlyContinue
$PcaDetectado = $false

foreach ($Event in $PcaEvents) {
    $EventMsg = $Event.Message.ToLower()
    if ($EventMsg -match "\.bat" -or $EventMsg -match "cmd.exe" -or $EventMsg -match "temp") {
        $HoraPca = $Event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "[$HoraPca] [!] HISTORIAL PCASVC: Script o comando ejecutado en segundo plano" -ForegroundColor DarkYellow
        Add-Content -Path $RutaReporte -Value "[ALERTA] [$HoraPca] [!] HISTORIAL PCASVC: Script o comando ejecutado en segundo plano"
        Add-Content -Path $RutaReporte -Value "    └─ Firma del Evento: $($Event.Message -replace '\s+', ' ')"
        $PcaDetectado = $true
    }
}

if (-not $PcaDetectado) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: El registro de PcaSvc no muestra scripts sospechosos." -ForegroundColor Green
    Add-Content -Path $RutaReporte -Value "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: El registro de PcaSvc no muestra scripts sospechosos."
}


# =========================================================================
# CUARTO MÓDULO: ANÁLISIS DE EVASIONES E INTEGRIDAD (PREFETCH Y BAM)
# =========================================================================
Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "[MÓDULO 4] Buscando signos de manipulación del sistema (Prefetch / BAM)..." -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray
Add-Content -Path $RutaReporte -Value "`n[MÓDULO 4] Buscando signos de manipulación del sistema (Prefetch / BAM)..."

# Verificación de Estado de Prefetch
$PrefetchRegistry = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
$TimestampPrefetch = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
if ($PrefetchRegistry -and $PrefetchRegistry.EnablePrefetcher -eq 0) {
    Write-Host "[$TimestampPrefetch] [!!!] ACCIÓN EVASIVA: El Prefetcher del sistema operativo está APAGADO." -ForegroundColor Red
    Add-Content -Path $RutaReporte -Value "[ALERTA] [$TimestampPrefetch] [!!!] ACCIÓN EVASIVA: El Prefetcher está APAGADO."
} else {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [-] Estado del Prefetcher: Habilitado correctamente." -ForegroundColor Green
    Add-Content -Path $RutaReporte -Value "[$(Get-Date -Format 'HH:mm:ss')] [-] Estado del Prefetcher: Habilitado."
}

# Conteo físico de archivos Prefetch
$PrefetchCount = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
if ($PrefetchCount -lt 15) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [!!!] ACCIÓN EVASIVA: Carpeta Prefetch vaciada ($PrefetchCount archivos)." -ForegroundColor Red
    Add-Content -Path $RutaReporte -Value "[ALERTA] [$(Get-Date -Format 'HH:mm:ss')] [!!!] ACCIÓN EVASIVA: Carpeta Prefetch vaciada."
} else {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [-] Volumen de archivos Prefetch: Normal ($PrefetchCount elementos)." -ForegroundColor Green
    Add-Content -Path $RutaReporte -Value "[$(Get-Date -Format 'HH:mm:ss')] [-] Volumen de archivos Prefetch normal."
}

# Escaneo Profundo del Registro BAM
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Cruzando registros BAM con el almacenamiento físico..." -ForegroundColor Gray
$BamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
$GhostFilesCount = 0

if (Test-Path $BamPath) {
    $SubKeys = Get-ChildItem -Path $BamPath
    foreach ($Key in $SubKeys) {
        $UserValues = Get-ItemProperty -Path $Key.PSPath -ErrorAction SilentlyContinue
        if ($UserValues) {
            foreach ($Value in $UserValues.PSObject.Properties) {
                if ($Value.Name -match "\.exe|\.bat|\.py|\.ahk") {
                    $FilePathLower = $Value.Name.ToLower()
                    
                    # Filtro de Exclusión Inteligente (Falsos Positivos de Nvidia, Roblox, etc.)
                    $EsExcluido = $false
                    foreach ($Pattern in $WhitelistPaths) {
                        if ($FilePathLower -like "*$Pattern*") { 
                            $EsExcluido = $true 
                        }
                    }
                    
                    if (-not $EsExcluido) {
                        $ContieneTermino = $false
                        foreach ($Termino in $FfmpegStrings) {
                            if ($FilePathLower -like "*$Termino*") { 
                                $ContieneTermino = $true 
                                $TerminoDetectado = $Termino
                            }
                        }

                        # Si el archivo está registrado en BAM pero ya fue borrado físicamente
                        if ($ContieneTermino -and -not (Test-Path $Value.Name -ErrorAction SilentlyContinue)) {
                            $TimestampBam = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            Write-Host "[$TimestampBam] [!] ARCHIVO FANTASMA (BAM): Relacionado con [$TerminoDetectado] -> $($Value.Name)" -ForegroundColor Red
                            Add-Content -Path $RutaReporte -Value "[ALERTA] [$TimestampBam] [!] ARCHIVO FANTASMA (BAM): Borrado -> [$TerminoDetectado] en $($Value.Name)"
                            $GhostFilesCount++
                        }
                    }
                }
            }
        }
    }
}

if ($GhostFilesCount -eq 0) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: No se hallaron eliminaciones agresivas en BAM." -ForegroundColor Green
    Add-Content -Path $RutaReporte -Value "[$(Get-Date -Format 'HH:mm:ss')] [-] Limpio: No se hallaron eliminaciones agresivas en BAM."
}


# =========================================================================
# CIERRE Y REPORTE FINAL
# =========================================================================
Write-Host "`n=========================================================================" -ForegroundColor DarkRed
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Análisis estructural finalizado con éxito." -ForegroundColor Cyan
Write-Host " REPORTE DISPONIBLE EN EL ESCRITORIO POR IKXPZL:" -ForegroundColor Yellow
Write-Host " $RutaReporte" -ForegroundColor White
Write-Host "=========================================================================" -ForegroundColor DarkRed

Add-Content -Path $RutaReporte -Value "`n========================================================================="
Add-Content -Path $RutaReporte -Value "Análisis finalizado con éxito. Reporte cerrado."
Add-Content -Path $RutaReporte -Value "========================================================================="
