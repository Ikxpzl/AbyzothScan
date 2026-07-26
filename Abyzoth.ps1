# =========================================================================
#  ABYZOTH SCAN - Sistema de Auditoría Forense y Anti-Bypass para SS
# =========================================================================
#  Desarrollado por: IkxPzl
#  Requisito: Ejecutar en una consola de PowerShell como Administrador.

Clear-Host
$Version     = "3.0.0"
$FechaActual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$RutaReporte = "$env:USERPROFILE\Desktop\Abyzoth_Scan_Report_$FechaActual.txt"

# -------------------------------------------------------------------------
# VARIABLES GLOBALES Y DICCIONARIOS
# -------------------------------------------------------------------------
$FfmpegStrings  = @("ffmpeg", "grabadora", "record", "stream", "obs", "d3d", "capture", "zen", "mozilla", "firefox", "file:", "medal", "action", "bandicam", "sharex", "vlc", "lightshot", "overwolf", "shadowplay", "relive", "screen", "recorder", "overlay", "injector", "temp")
$AhkStrings     = @("macro", "trigger", "recoil", "aim", "cheat", "bhop", "script", "hotkey")
$WhitelistPaths = @("roblox", "overwolf", "nvidia", "discord", "spotify")

# -------------------------------------------------------------------------
# FUNCIONES DEL NÚCLEO (CORE)
# -------------------------------------------------------------------------
function Escribir-Log {
    param (
        [string]$Mensaje,
        [System.ConsoleColor]$Color = "White",
        [bool]$EsAlerta = $false
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefijo   = "[$Timestamp] "
    
    Write-Host "$Prefijo$Mensaje" -ForegroundColor $Color
    if ($EsAlerta) {
        Add-Content -Path $RutaReporte -Value "[ALERTA] $Prefijo$Mensaje"
    } else {
        Add-Content -Path $RutaReporte -Value "$Prefijo$Mensaje"
    }
}

function Inicializar-Reporte {
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
    Escribir-Log "Inicializando los motores forenses..." "Gray"
}

# -------------------------------------------------------------------------
# MÓDULOS DE ANÁLISIS FORENSE
# -------------------------------------------------------------------------
function Invoke-ModuloComandos {
    Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
    Escribir-Log "[MÓDULO 1] Analizando historial de líneas de comandos (Python / Shell)..." "Cyan"
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray

    $SecurityEvents = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -ErrorAction SilentlyContinue
    $AlertaDetectada = $false

    foreach ($Event in $SecurityEvents) {
        $MessageLower = $Event.Message.ToLower()
        if ($MessageLower -match "python" -or $MessageLower -match "cmd.exe" -or $MessageLower -match "powershell.exe") {
            foreach ($String in $FfmpegStrings) {
                if ($MessageLower -like "*$String*") {
                    $HoraEvento = $Event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                    Escribir-Log "[!] CRÍTICO: Comando sospechoso detectado -> '$String' [Hora: $HoraEvento]" "Red" $true
                    Add-Content -Path $RutaReporte -Value "    └─ Detalle Técnico: $($Event.Message -replace '\s+', ' ')"
                    $AlertaDetectada = $true
                }
            }
        }
    }
    if (-not $AlertaDetectada) { Escribir-Log "[-] Limpio: No se hallaron anomalías en comandos." "Green" }
}

function Invoke-ModuloMemoria Historial {
    Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
    Escribir-Log "[MÓDULO 2] Inspeccionando memoria volátil e historiales recientes..." "Cyan"
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray

    $ProcesosSospechosos = Get-Process | Where-Object { $_.Name -match "zen" -or $_.Name -match "firefox" -or $_.Name -match "obs" -or $_.Name -match "medal" -or $_.Name -match "ShareX" -or $_.Name -match "AutoHotkey" }
    $ProcesoActivo = $false

    foreach ($Proc in $ProcesosSospechosos) {
        try { $Path = $Proc.Path } catch { $Path = "Acceso Denegado / Binario Oculto" }
        Escribir-Log "[!] PROCESO ACTIVO: Se está ejecutando '$($Proc.Name)' (PID: $($Proc.Id))" "DarkYellow" $true
        Add-Content -Path $RutaReporte -Value "    └─ Ubicación: $Path"
        $ProcesoActivo = $true
    }
    if (-not $ProcesoActivo) { Escribir-Log "[-] Limpio: No hay aplicaciones de captura/macros activas." "Green" }

    $RecentFiles = Get-ChildItem "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "\.ahk" -or $_.Name -match "\.py" -or $_.Name -match "zen" -or $_.Name -match "mozilla" }
    foreach ($File in $RecentFiles) {
        $HoraModificacion = $File.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Escribir-Log "[!] HISTORIAL: Archivo abierto recientemente -> $($File.Name) [Modificado: $HoraModificacion]" "Magenta" $true
    }
}

function Invoke-ModuloPcaSvc {
    Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
    Escribir-Log "[MÓDULO 3] Extrayendo logs imborrables de PcaSvc (Program Telemetry)..." "Cyan"
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray

    $PcaLogPath = "Microsoft-Windows-Application-Experience/Program-Telemetry"
    $PcaEvents  = Get-WinEvent -FilterHashtable @{LogName=$PcaLogPath; Id=100} -ErrorAction SilentlyContinue
    $PcaDetectado = $false

    foreach ($Event in $PcaEvents) {
        $EventMsg = $Event.Message.ToLower()
        if ($EventMsg -match "\.bat" -or $EventMsg -match "cmd.exe" -or $EventMsg -match "temp") {
            $HoraPca = $Event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
            Escribir-Log "[!] HISTORIAL PCASVC: Script o comando ejecutado en segundo plano [Hora: $HoraPca]" "DarkYellow" $true
            Add-Content -Path $RutaReporte -Value "    └─ Firma del Evento: $($Event.Message -replace '\s+', ' ')"
            $PcaDetectado = $true
        }
    }
    if (-not $PcaDetectado) { Escribir-Log "[-] Limpio: El registro persistente de PcaSvc no muestra anomalías." "Green" }
}

function Invoke-ModuloEvasionesBAM {
    Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
    Escribir-Log "[MÓDULO 4] Buscando signos de manipulación del sistema (Prefetch / BAM)..." "Cyan"
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray

    # Verificación de Prefetcher
    $PrefetchRegistry = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
    if ($PrefetchRegistry -and $PrefetchRegistry.EnablePrefetcher -eq 0) {
        Escribir-Log "[!!!] ACCIÓN EVASIVA: El Prefetcher del sistema operativo está APAGADO." "Red" $true
    } else {
        Escribir-Log "[-] Estado del Prefetcher: Habilitado correctamente." "Green"
    }

    # Volumen físico Prefetch
    $PrefetchCount = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
    if ($PrefetchCount -lt 15) {
        Escribir-Log "[!!!] ACCIÓN EVASIVA: Carpeta Prefetch vaciada. Solo se hallaron $PrefetchCount archivos." "Red" $true
    } else {
        Escribir-Log "[-] Volumen de la base de datos Prefetch: Normal ($PrefetchCount elementos)." "Green"
    }

    # Escaneo Forense del Registro BAM
    Escribir-Log "Cruzando registros BAM con el almacenamiento físico para buscar borrados rápidos..." "Gray"
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
                        
                        $EsExcluido = $false
                        foreach ($Pattern in $WhitelistPaths) {
                            if ($FilePathLower -like "*$Pattern*") { $EsExcluido = $true }
                        }
                        
                        if (-not $EsExcluido) {
                            $ContieneTermino = $false
                            foreach ($Termino in $FfmpegStrings) {
                                if ($FilePathLower -like "*$Termino*") { 
                                    $ContieneTermino = $true 
                                    $TerminoDetectado = $Termino
function Invoke-ModuloEvasionesBAM {
    Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
    Escribir-Log "[MÓDULO 4] Buscando signos de manipulación del sistema (Prefetch / BAM)..." "Cyan"
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray

    # Verificación de Prefetcher
    $PrefetchRegistry = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
    if ($PrefetchRegistry -and $PrefetchRegistry.EnablePrefetcher -eq 0) {
        Escribir-Log "[!!!] ACCIÓN EVASIVA: El Prefetcher del sistema operativo está APAGADO." "Red" $true
    } else {
        Escribir-Log "[-] Estado del Prefetcher: Habilitado correctamente." "Green"
    }

    # Volumen físico Prefetch
    $PrefetchCount = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
    if ($PrefetchCount -lt 15) {
        Escribir-Log "[!!!] ACCIÓN EVASIVA: Carpeta Prefetch vaciada. Solo se hallaron $PrefetchCount archivos." "Red" $true
    } else {
        Escribir-Log "[-] Volumen de la base de datos Prefetch: Normal ($PrefetchCount elementos)." "Green"
    }

    # Escaneo Forense del Registro BAM
    Escribir-Log "Cruzando registros BAM con el almacenamiento físico para buscar borrados rápidos..." "Gray"
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
                        
                        $EsExcluido = $false
                        foreach ($Pattern in $WhitelistPaths) {
                            if ($FilePathLower -like "*$Pattern*") { $EsExcluido = $true }
                        }
                        
                        if (-not $EsExcluido) {
                            $ContieneTermino = $false
                            foreach ($Termino in $FfmpegStrings) {
                                if ($FilePathLower -like "*$Termino*") { 
                                    $ContieneTermino = $true 
                                    $TerminoDetectado = $Termino
                                }
                            }
                            if ($ContieneTermino -and -not (Test-Path $Value.Name -ErrorAction SilentlyContinue)) {
                                Escribir-Log "[!] ARCHIVO FANTASMA (BAM): Ejecutado y eliminado del disco -> [$TerminoDetectado] en: $($Value.Name)" "Red" $true
                                $GhostFilesCount++
                            }
                        }
                    }
                }
            }
        }
    }
    if ($GhostFilesCount -eq 0) { 
        Escribir-Log "[-] Limpio: No se hallaron eliminaciones agresivas en BAM." "Green" 
    }
}

function Finalizar-Analisis {
    Write-Host "`n=========================================================================" -ForegroundColor DarkRed
    Escribir-Log "Análisis estructural finalizado con éxito." "Cyan"
    Write-Host " REPORTE DISPONIBLE EN EL ESCRITORIO POR IKXPZL:" -ForegroundColor Yellow
    Write-Host " $RutaReporte" -ForegroundColor White
    Write-Host "=========================================================================" -ForegroundColor DarkRed
}

# -------------------------------------------------------------------------
# HILO DE EJECUCIÓN SECUENCIAL (ORQUESTADOR)
# -------------------------------------------------------------------------
Inicializar-Reporte
Invoke-ModuloComandos
Invoke-ModuloMemoriaHistorial
Invoke-ModuloPcaSvc
Invoke-ModuloEvasionesBAM
Finalizar-Analisis

