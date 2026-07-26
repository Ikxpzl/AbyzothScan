# =========================================================================
#  ABYZOTH SCAN v1.1.0 - Sistema Forense 
# =========================================================================
#  Desarrollado por: IkxPzl (Rediseño Estético, Corrección de Errores y Erratas)
#  Requisito: Ejecutar en una consola de PowerShell como Administrador.

Clear-Host
$Version = "6.5.0"
$FechaActual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$RutaReporte = "$env:USERPROFILE\Desktop\Abyzoth_Scan_Report_$FechaActual.txt"
$RutaReporteConsoleHost = "$env:USERPROFILE\Desktop\Abyzoth_ConsoleHost_Full_$FechaActual.txt"

# 1. ARREGLOS DE CONTROL (LISTAS DE BÚSQUEDA Y EXCLUSIÓN MULTI-CAPA)
# Se eliminaron 'firefox' y 'mozilla' para evitar falsos positivos masivos de navegación.
$FirmasSospechosas = @("ffmpeg", "grabadora", "record", "stream", "obs", "d3d", "capture", "zen", "medal", "action", "bandicam", "sharex", "vlc", "lightshot", "overwolf", "shadowplay", "relive", "screen", "recorder", "overlay", "injector", "temp", "macro", "trigger", "recoil", "aim", "cheat", "bhop", "script", "hotkey", "psr", "meny.py", "menu.py", ".py")
$Exclusiones       = @("roblox", "overwolf", "nvidia", "discord", "spotify", "steam", "epicgames", "microsoft", "windows")

# 2. CONTENEDORES DE ALERTAS
$Alertas_Comandos   = @()
$Alertas_Memoria    = @()
$Alertas_PcaSvc     = @()
$Alertas_Bypass     = @()
$Alertas_PowerShell = @()
$TotalLineasPS      = 0

# Cabecera Cyberpunk / Minimalista Industrial
Write-Host " ┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host " │                   ABYZOTH FORENSIC ENGINE v$Version                   │" -ForegroundColor Cyan
Write-Host " │                       CORE LOGIC BY: IKXPZL                           │" -ForegroundColor DarkCyan
Write-Host " └───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host " [i] Iniciando detecciones forenses de alta velocidad..." -ForegroundColor Gray
Write-Host " -------------------------------------------------------------------------" -ForegroundColor Gray

# =========================================================================
# FASE 1: RECOLECCIÓN Y PROCESAMIENTO (MÓDULOS FORENSES)
# =========================================================================

# MÓDULO 1: Eventos de Consola (ID 4688)
Write-Host " [>] Extrayendo telemetría de auditoría de procesos (ID 4688)..." -ForegroundColor Gray
$EventosSeguridad = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 200 -ErrorAction SilentlyContinue
if ($EventosSeguridad) {
    foreach ($Ev in $EventosSeguridad) {
        $LineaComando = $Ev.Message.ToLower()
        # Detección ultra-precisa de Python y scripts derivados
        if ($LineaComando -match "python" -or $LineaComando -match "\.py\b" -or $LineaComando -match "meny" -or $LineaComando -match "menu\.py") {
            $HoraEv = $Ev.TimeCreated.ToString('HH:mm:ss')
            $Alertas_Comandos += "[!] ALERTA PYTHON ($HoraEv) -> Script detectado en entorno de ejecución."
            $Alertas_Comandos += "    └─ Ejecución: $($Ev.Message -replace '\s+', ' ')"
            foreach ($Firma in $FirmasSospechosas) {
                if ($LineaComando -like "*$Firma*" -and $Firma -ne ".py" -and $Firma -ne "script") {
                    $Alertas_Comandos += "       [x] Indicador Relacionado: Parámetro sospechoso -> '$Firma'"
                }
            }
        }
        elseif ($LineaComando -match "cmd\.exe" -or $LineaComando -match "powershell\.exe") {
            foreach ($Firma in $FirmasSospechosas) {
                if ($LineaComando -like "*$Firma*") {
                    $Alertas_Comandos += "[!] COINCIDENCIA SHELL ($($Ev.TimeCreated.ToString('HH:mm:ss'))) -> Consola invocó patrón '$Firma'"
                }
            }
        }
    }
}

# MÓDULO 2: Procesos Activos en Memoria
Write-Host " [>] Analizando volcado de descriptores de procesos en memoria..." -ForegroundColor Gray
$TodosLosProcesos = Get-Process
foreach ($P in $TodosLosProcesos) {
    foreach ($Firma in @("zen", "obs", "medal", "sharex", "autohotkey", "psr", "python")) {
        if ($P.Name.ToLower() -match $Firma) {
            try { $RutaBinar = $P.Path } catch { $RutaBinar = "Protegido por Kernel/Sistema" }
            $Alertas_Memoria += "[!] EN EJECUCIÓN -> Proceso: $($P.Name) [PID: $($P.Id)] | Ruta: $RutaBinar"
        }
    }
}

# MÓDULO 3: Telemetría Persistente de PcaSvc (Program Telemetry)
Write-Host " [>] Rastreando caché de telemetría e historial de aplicación (PcaSvc)..." -ForegroundColor Gray
$EventosPca = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Application-Experience/Program-Telemetry"; Id=100} -MaxEvents 200 -ErrorAction SilentlyContinue
if ($EventosPca) {
    foreach ($Ev in $EventosPca) {
        $MsgPca = $Ev.Message.ToLower()
        if ($MsgPca -match "\.bat" -or $MsgPca -match "cmd.exe" -or $MsgPca -match "temp" -or $MsgPca -match "meny" -or $MsgPca -match "\.py") {
            $Alertas_PcaSvc += "[!] REGISTRO PCASVC ($($Ev.TimeCreated.ToString('HH:mm:ss'))) -> Evidencia de ejecución: $($Ev.Message -replace '\s+', ' ')"
        }
    }
}

# MÓDULO EXTRA: Historial de comandos de PowerShell (PSReadLine)
Write-Host " [>] Volcando búfer persistente de PSReadLine..." -ForegroundColor Gray
$RutaHistorialPS = "$env:appdata\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
if (Test-Path $RutaHistorialPS) {
    $LineasHistorial = Get-Content -Path $RutaHistorialPS -ErrorAction SilentlyContinue
    if ($LineasHistorial) {
        $TotalLineasPS = $LineasHistorial.Count
@"
=========================================================================
               ABYZOTH SECURITY ENGINE - CONSOLEHOST LOG                 
=========================================================================
 Desarrollador      : IkxPzl
 Total de Comandos  : $TotalLineasPS líneas analizadas
 Fecha de Extracción: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
-------------------------------------------------------------------------
"@ | Out-File -FilePath $RutaReporteConsoleHost -Encoding utf8

        $Indice = 1
        foreach ($CmdLine in $LineasHistorial) {
            Add-Content -Path $RutaReporteConsoleHost -Value "[$Indice] $CmdLine"
            $CmdLineLower = $CmdLine.ToLower()
            foreach ($Firma in $FirmasSospechosas) {
                if ($CmdLineLower -like "*$Firma*") {
                    # Corrección de índice: Sincronizado exactamente con el número de línea analizado
                    $Alertas_PowerShell += "[!] HISTORIAL (Línea $Indice) -> Comando sospechoso: $CmdLine"
                }
            }
            $Indice++
        }
    }
}

# MÓDULO 4 (PARTE A): Integridad y Vaciamiento de Prefetch
Write-Host " [>] Verificando marcas de tiempo e integridad de Prefetch..." -ForegroundColor Gray
$PrefetchReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
if ($PrefetchReg -and $PrefetchReg.EnablePrefetcher -eq 0) {
    $Alertas_Bypass += "[!!!] ALERTA CRÍTICA: El servicio de Prefetcher se encuentra deshabilitado en el registro."
}
$ContadorPf = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
if ($ContadorPf -lt 15) {
    $Alertas_Bypass += "[!!!] EVASIÓN DETECTADA: El directorio Prefetch ha sido limpiado recientemente (Solo quedan $ContadorPf archivos)."
}

# MÓDULO 4 (PARTE B): Cruce de Datos e Inconsistencias BAM (Background Activity Moderator)
Write-Host " [>] Analizando llaves criptográficas del Background Activity Moderator (BAM)..." -ForegroundColor Gray
$RutaBam = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
if (Test-Path $RutaBam) {
    $SubClavesBam = Get-ChildItem -Path $RutaBam
    foreach ($Clave in $SubClavesBam) {
        $ValoresUsuario = Get-ItemProperty -Path $Clave.PSPath -ErrorAction SilentlyContinue
        if ($ValoresUsuario) {
            foreach ($Propiedad in $ValoresUsuario.PSObject.Properties) {
                if ($Propiedad.Name -match "\.exe|\.bat|\.py|\.ahk") {
                    $RutaNormalizada = $Propiedad.Name.ToLower()
                    
                    $Ignorar = $false
                    foreach ($Excluir in $Exclusiones) {
                        if ($RutaNormalizada -like "*$Excluir*") { $Ignorar = $true }
                    }
                    
                    if (-not $Ignorar) {
                        foreach ($Firma in $FirmasSospechosas) {
                            if ($RutaNormalizada -like "*$Firma*") {
                                # Corrección: Limpieza del prefijo del registro para evitar fallos en Test-Path
                                $RutaLimpia = $Propiedad.Name -replace '\\\\\?\\', ''
                                if (-not (Test-Path $RutaLimpia -ErrorAction SilentlyContinue)) {
                                    $Alertas_Bypass += "[!] DESTRUCCIÓN DE EVIDENCIA (BAM) -> Archivo patrón [$Firma] fue ejecutado y eliminado posteriormente: $RutaLimpia"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

# =========================================================================
# FASE 2: INTERFAZ VISUAL EN BLOQUES Y PANELES (MUESTRA EN CMD)
# =========================================================================

# Función para armar bloques limpios y profesionales estilo CLI moderno
function Mostrar-Panel-Forense([string]$NombreModulo, [array]$ColeccionAlertas, $ColorAlerta) {
    $Cantidad = $ColeccionAlertas.Count
    Write-Host ""
    if ($Cantidad -gt 0) {
        Write-Host " ╔══ $NombreModulo ════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host "   [!] Anomalías detectadas: $Cantidad" -ForegroundColor Red
        Write-Host " ────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkCyan
        foreach ($Alerta in $ColeccionAlertas) {
            Write-Host "   $Alerta" -ForegroundColor $ColorAlerta
        }
        Write-Host " ╚═══════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    } else {
        Write-Host " ╔══ $NombreModulo ════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host "   [+] Estado del módulo: LIMPIO (Sin anomalías registradas)" -ForegroundColor Green
        Write-Host " ╚═══════════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    }
}

# Despliegue de los paneles en consola con la nueva paleta ordenada
Mostrar-Panel-Forense "MÓDULO 1: AUDITORÍA DE COMANDOS (ID 4688 / PYTHON)" $Alertas_Comandos Red
Mostrar-Panel-Forense "MÓDULO 2: PROCESOS EN MEMORIA VOLÁTIL" $Alertas_Memoria Gray
Mostrar-Panel-Forense "MÓDULO 3: TELEMETRÍA DE APLICACIÓN PCASVC" $Alertas_PcaSvc DarkCyan
Mostrar-Panel-Forense "MÓDULO EXTRA: HISTORIAL PERSISTENTE POWERSHELL" $Alertas_PowerShell Cyan
Mostrar-Panel-Forense "MÓDULO 4: INTEGRIDAD DE SISTEMA (ANTI-BYPASS / BAM)" $Alertas_Bypass Magenta

# =========================================================================
# FASE 3: VOLCADO DE LOGS TEXTUALES
# =========================================================================

$ReporteTexto = @"
=========================================================================
               INFORME FORENSE FINALIZADO - ABYZOTH v$Version
=========================================================================
Fecha y Hora de Cierre: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Líneas de Comandos de PowerShell Revisadas: $TotalLineasPS

[MÓDULO 1 - RESTRICCIONES DE COMANDO E HISTORIAL DE PROCESOS]
$($Alertas_Comandos -join "`r`n")

[MÓDULO 2 - MAPA DE PROCESOS ACTIVOS EN MEMORIA]
$($Alertas_Memoria -join "`r`n")

[MÓDULO 3 - LOGS DE TELEMETRÍA PCASVC]
$($Alertas_PcaSvc -join "`r`n")

[MÓDULO EXTRA - HISTORIAL DE PSREADLINE DEPURADO]
$($Alertas_PowerShell -join "`r`n")

[MÓDULO 4 - TÉCNICAS DE EVASIÓN, MODIFICACIONES Y BORRADO DE ARCHIVOS]
$($Alertas_Bypass -join "`r`n")
=========================================================================
                       FIN DEL REPORTE GENERADO
=========================================================================
"@

# Exportar reporte principal a escritorio en UTF-8 estándar
$ReporteTexto | Out-File -FilePath $RutaReporte -Encoding utf8

Write-Host ""
Write-Host " ┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "   [+] Análisis forense concluido con éxito." -ForegroundColor Gray
Write-Host "   [+] Archivo de Reporte Estructurado: $RutaReporte" -ForegroundColor Green
Write-Host "   [+] Historial Completo ConsoleHost:  $RutaReporteConsoleHost" -ForegroundColor Green
Write-Host " └───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""
