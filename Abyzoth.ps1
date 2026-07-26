# =========================================================================
#  ABYZOTH SCAN v1.0.0 - Sistema Forense Ampliado de Alta Velocidad
# =========================================================================
#  Desarrollado por: IkxPzl
#  Requisito: Ejecutar en una consola de PowerShell como Administrador.

Clear-Host
$Version = "6.5.0"
$FechaActual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$RutaReporte = "$env:USERPROFILE\Desktop\Abyzoth_Scan_Report_$FechaActual.txt"
$RutaReporteConsoleHost = "$env:USERPROFILE\Desktop\Abyzoth_ConsoleHost_Full_$FechaActual.txt"

# 1. ARREGLOS DE CONTROL (LISTAS DE BÚSQUEDA Y EXCLUSIÓN MULTI-CAPA)
$FirmasSospechosas = @("ffmpeg", "grabadora", "record", "stream", "obs", "d3d", "capture", "zen", "mozilla", "firefox", "file:", "medal", "action", "bandicam", "sharex", "vlc", "lightshot", "overwolf", "shadowplay", "relive", "screen", "recorder", "overlay", "injector", "temp", "macro", "trigger", "recoil", "aim", "cheat", "bhop", "script", "hotkey", "psr", "meny.py", "menu.py", ".py")
$Exclusiones       = @("roblox", "overwolf", "nvidia", "discord", "spotify", "steam", "epicgames", "microsoft")

# 2. CONTENEDORES DE ALERTAS (ESTRUCTURA DE ALMACENAMIENTO PLANA)
$Alertas_Comandos   = @()
$Alertas_Memoria    = @()
$Alertas_PcaSvc     = @()
$Alertas_Bypass     = @()
$Alertas_PowerShell = @()
$TotalLineasPS      = 0

# Cabecera estética inicial
Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "                      ABYZOTH SCAN v$Version (MAX DEPTH)                 " -ForegroundColor Red
Write-Host "                       DESARROLLADO POR: IKXPZL                          " -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "[+] Ejecutando minería forense extendida sin congelamiento..." -ForegroundColor Gray

# =========================================================================
# FASE 1: RECOLECCIÓN DE DATOS (ÍNDICES LIMITADOS DE ALTA VELOCIDAD)
# =========================================================================

# MÓDULO 1: Eventos de Consola (ID 4688) - BÚSQUEDA EXTENDIDA INDEXADA
$EventosSeguridad = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 200 -ErrorAction SilentlyContinue
foreach ($Ev in $EventosSeguridad) {
    $LineaComando = $Ev.Message.ToLower()
    
    if ($LineaComando -match "python" -or $LineaComando -match "\.py" -or $LineaComando -match "meny") {
        $HoraEv = $Ev.TimeCreated.ToString('HH:mm:ss')
        $Alertas_Comandos += "[!] DETECTADO PYTHON ($HoraEv): Actividad o Script en el sistema."
        $Alertas_Comandos += "    └─ Comando completo: $($Ev.Message -replace '\s+', ' ')"
        
        foreach ($Firma in $FirmasSospechosas) {
            if ($LineaComando -like "*$Firma*") {
                $Alertas_Comandos += "       [!] ALERTA CRÍTICA: Argumento sospechoso de riesgo -> '$Firma'"
            }
        }
    }
    elseif ($LineaComando -match "cmd\.exe" -or $LineaComando -match "powershell\.exe") {
        foreach ($Firma in $FirmasSospechosas) {
            if ($LineaComando -like "*$Firma*") {
                $Alertas_Comandos += "[!] COINCIDENCIA SHELL: '$Firma' encontrada en consola -> $($Ev.TimeCreated.ToString('HH:mm:ss'))"
            }
        }
    }
}

# MÓDULO 2: Auditoría de Procesos Activos en Memoria y PSR
$TodosLosProcesos = Get-Process
foreach ($P in $TodosLosProcesos) {
    foreach ($Firma in @("zen", "firefox", "obs", "medal", "sharex", "autohotkey", "psr", "python")) {
        if ($P.Name.ToLower() -match $Firma) {
            try { $RutaBinar = $P.Path } catch { $RutaBinar = "Oculto/Protegido" }
            $Alertas_Memoria += "[!] PROCESO ACTIVO: Se detectó '$($P.Name)' (PID: $($P.Id)) en la ruta [$RutaBinar]"
        }
    }
}

# MÓDULO 3: Telemetría Persistente de PcaSvc - ESCANEO EXTENDIDO INDEXADO
$EventosPca = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Application-Experience/Program-Telemetry"; Id=100} -MaxEvents 200 -ErrorAction SilentlyContinue
foreach ($Ev in $EventosPca) {
    $MsgPca = $Ev.Message.ToLower()
    if ($MsgPca -match "\.bat" -or $MsgPca -match "cmd.exe" -or $MsgPca -match "temp" -or $MsgPca -match "meny" -or $MsgPca -match "\.py") {
        $Alertas_PcaSvc += "[!] REGISTRO PCASVC ($($Ev.TimeCreated.ToString('HH:mm:ss'))): Script/Comando -> $($Ev.Message -replace '\s+', ' ')"
    }
}

# MÓDULO EXTRA: Historial ilimitado de PowerShell (PSReadLine)
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
            $Indice++

            $CmdLineLower = $CmdLine.ToLower()
            foreach ($Firma in $FirmasSospechosas) {
                if ($CmdLineLower -like "*$Firma*") {
                    $Alertas_PowerShell += "[!] COMANDO SOSPECHOSO (Línea $Indice): $CmdLine"
                }
            }
        }
    }
}

# MÓDULO 4 (PARTE A): Integridad de Prefetch
$PrefetchReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
if ($PrefetchReg -and $PrefetchReg.EnablePrefetcher -eq 0) {
    $Alertas_Bypass += "[!!!] ACCIÓN EVASIVA: El servicio Prefetcher está APAGADO en el Registro de Windows."
}
$ContadorPf = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
if ($ContadorPf -lt 15) {
    $Alertas_Bypass += "[!!!] ACCIÓN EVASIVA: Carpeta Prefetch vaciada recientemente. Solo quedan $ContadorPf archivos."
}

# MÓDULO 4 (PARTE B): Cruce de Datos BAM
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
                                if (-not (Test-Path $Propiedad.Name -ErrorAction SilentlyContinue)) {
                                    $Alertas_Bypass += "[!] EVASIÓN BAM: El archivo de patrón [$Firma] fue ejecutado y posteriormente BORRADO: $($Propiedad.Name)"
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
# FASE 2: INTERFAZ VISUAL ORDENADA (RÉNDER EN PANTALLA)
# =========================================================================
Clear-Host
Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "                         ABYZOTH SCAN v$Version                             " -ForegroundColor Red
Write-Host "                       DESARROLLADO POR: IKXPZL                          " -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor DarkRed

# EXPOSICIÓN MÓDULO 1
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ [MÓDULO 1] RESULTADOS DE TELEMETRÍA DE COMANDOS (PYTHON / SHELL)      │" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
if ($Alertas_Comandos.Count -gt 0) {
    foreach ($A in $Alertas_Comandos) { Write-Host " $A" -ForegroundColor Red }
} else {
    Write-Host " [-] Registro limpio. No se encontraron comandos anómalos." -ForegroundColor Green
}

# EXPOSICIÓN MÓDULO 2
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ [MÓDULO 2] RESULTADOS DE MEMORIA VOLÁTIL Y PROCESOS DE CAPTURA (PSR) │" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
if ($Alertas_Memoria.Count -gt 0) {
    foreach ($A in $Alertas_Memoria) { Write-Host " $A" -ForegroundColor Yellow }
} else {
    Write-Host " [-] Memoria limpia. No hay softwares de grabación o PSR activos." -ForegroundColor Green
}

# EXPOSICIÓN MÓDULO 3
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ [MÓDULO 3] HISTORIAL PERSISTENTE DE SCRIPTS .BAT (PCASVC TELEMETRY)   │" -ForegroundColor Cyan
    Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
if ($Alertas_PcaSvc.Count -gt 0) {
    foreach ($A in $Alertas_PcaSvc) { Write-Host " $A" -ForegroundColor Yellow }
} else {
    Write-Host " [-] Telemetría limpia. Sin rastros de scripts de limpieza .bat recientes." -ForegroundColor Green
}

# EXPOSICIÓN MÓDULO EXTRA
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ [MÓDULO EXTRA] HISTORIAL DE COMANDOS MANUALES DE POWERSHELL           │" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host " [+] Volumen total en historial: $TotalLineasPS líneas analizadas en segundo plano." -ForegroundColor Gray
if ($Alertas_PowerShell.Count -gt 0) {
    $NumAlertas = $Alertas_PowerShell.Count
    Write-Host " [!] ADVERTENCIA: Se encontraron $NumAlertas comandos que coinciden con firmas de riesgo." -ForegroundColor DarkYellow
    Write-Host "     Las líneas sospechosas detalladas se exportaron directamente al reporte .txt." -ForegroundColor Gray
} else {
    Write-Host " [-] Historial de comandos limpio de firmas sospechosas." -ForegroundColor Green
}

# EXPOSICIÓN MÓDULO 4
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ [MÓDULO 4] ANÁLISIS DE EVASIONES E INTEGRIDAD (PREFETCH Y REGISTRO BAM)│" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
if ($Alertas_Bypass.Count -gt 0) {
    foreach ($A in $Alertas_Bypass) { Write-Host " $A" -ForegroundColor Red }
} else {
    Write-Host " [-] Integridad verificada. No se detectaron borrados ni modificaciones." -ForegroundColor Green
}

# =========================================================================
# FASE 3: ESCRITURA FÍSICA DEL REPORTE (.TXT) EN EL ESCRITORIO
# =========================================================================
$ContenidoTxt = @"
=========================================================================
                         ABYZOTH SCAN REPORT                             
=========================================================================
 Desarrollador: IkxPzl
 Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
 Dispositivo: $env:COMPUTERNAME
 User: $env:USERNAME
-------------------------------------------------------------------------

[MÓDULO 1] TELEMETRÍA DE COMANDOS (PYTHON):
$($Alertas_Comandos -join "`r`n")
$(if($Alertas_Comandos.Count -eq 0){"Sin alertas."})

[MÓDULO 2] MEMORIA Y PROCESOS (PSR):
$($Alertas_Memoria -join "`r`n")
$(if($Alertas_Memoria.Count -eq 0){"Sin alertas."})

[MÓDULO 3] HISTORIAL PCASVC (.BAT):
$($Alertas_PcaSvc -join "`r`n")
$(if($Alertas_PcaSvc.Count -eq 0){"Sin alertas."})

[MÓDULO EXTRA] COMANDOS CRÍTICOS ENCONTRADOS EN POWERSHELL ($TotalLineasPS líneas totales):
$($Alertas_PowerShell -join "`r`n")
$(if($Alertas_PowerShell.Count -eq 0){"Sin alertas."})

[MÓDULO 4] INTENCIONES DE BYPASS Y BORRADOS (BAM / PREFETCH):
$($Alertas_Bypass -join "`r`n")
$(if($Alertas_Bypass.Count -eq 0){"Sin alertas."})
=========================================================================
"@
$ContenidoTxt | Out-File -FilePath $RutaReporte -Encoding utf8

Write-Host "`n=========================================================================" -ForegroundColor DarkRed
Write-Host " REPORTE PRINCIPAL GENERADO EN EL ESCRITORIO POR IKXPZL:" -ForegroundColor Yellow
Write-Host " -> $RutaReporte" -ForegroundColor White
Write-Host " HISTORIAL COMPLETO DE POWERSHELL EXTRACTADO ($TotalLineasPS LÍNEAS):" -ForegroundColor Yellow
Write-Host " -> $RutaReporteConsoleHost" -ForegroundColor White
Write-Host "=========================================================================" -ForegroundColor DarkRed
