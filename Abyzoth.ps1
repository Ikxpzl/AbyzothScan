# =========================================================================
#  ABYZOTH SCAN v5.0.2 - Sistema Forense por Índices (Sintaxis Garantizada)
# =========================================================================
#  Desarrollado por: IkxPzl
#  Requisito: Ejecutar en una consola de PowerShell como Administrador.

Clear-Host
$FechaActual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$RutaReporte = "$env:USERPROFILE\Desktop\Abyzoth_Scan_Report_$FechaActual.txt"

# 1. ARREGLOS DE CONTROL (LISTAS DE BÚSQUEDA Y EXCLUSIÓN)
$FirmasSospechosas = @("ffmpeg", "grabadora", "record", "stream", "obs", "d3d", "capture", "zen", "mozilla", "firefox", "file:", "medal", "action", "bandicam", "sharex", "vlc", "lightshot", "overwolf", "shadowplay", "relive", "screen", "recorder", "overlay", "injector", "temp", "macro", "trigger", "recoil", "aim", "cheat", "bhop", "script", "hotkey", "psr")
$Exclusiones       = @("roblox", "overwolf", "nvidia", "discord", "spotify", "steam", "epicgames", "microsoft")

# 2. CONTENEDORES DE ALERTAS (ESTRUCTURA DE ALMACENAMIENTO PLANA)
$Alertas_Comandos = @()
$Alertas_Memoria  = @()
$Alertas_PcaSvc   = @()
$Alertas_Bypass   = @()

# Cabecera estética inicial
Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "                      ABYZOTH SCAN (COMPILACIÓN CORREGIDA)               " -ForegroundColor Red
Write-Host "                       DESARROLLADO POR: IKXPZL                          " -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "[+] Iniciando recolección de datos en segundo plano..." -ForegroundColor Gray

# =========================================================================
# FASE 1: RECOLECCIÓN DE DATOS
# =========================================================================

# Sección A: Auditoría de Eventos de Consola (ID 4688)
$EventosSeguridad = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -ErrorAction SilentlyContinue
foreach ($Ev in $EventosSeguridad) {
    $LineaComando = $Ev.Message.ToLower()
    if ($LineaComando -match "python" -or $LineaComando -match "cmd.exe" -or $LineaComando -match "powershell.exe") {
        foreach ($Firma in $FirmasSospechosas) {
            if ($LineaComando -like "*$Firma*") {
                $Alertas_Comandos += "[!] COINCIDENCIA: '$Firma' encontrada en -> $($Ev.TimeCreated.ToString('HH:mm:ss'))"
            }
        }
    }
}

# Sección B: Auditoría de Procesos Activos y PSR
$TodosLosProcesos = Get-Process
foreach ($P in $TodosLosProcesos) {
    foreach ($Firma in @("zen", "firefox", "obs", "medal", "sharex", "autohotkey", "psr")) {
        if ($P.Name.ToLower() -match $Firma) {
            try { $RutaBinar = $P.Path } catch { $RutaBinar = "Oculto/Protegido" }
            $Alertas_Memoria += "[!] PROCESO ACTIVO: Se detectó '$($P.Name)' (PID: $($P.Id)) en la ruta [$RutaBinar]"
        }
    }
}

# Sección C: Auditoría de Persistencia en PcaSvc
$EventosPca = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Application-Experience/Program-Telemetry"; Id=100} -ErrorAction SilentlyContinue
foreach ($Ev in $EventosPca) {
    $MsgPca = $Ev.Message.ToLower()
    if ($MsgPca -match "\.bat" -or $MsgPca -match "cmd.exe" -or $MsgPca -match "temp") {
        $Alertas_PcaSvc += "[!] REGISTRO PCASVC ($($Ev.TimeCreated.ToString('HH:mm:ss'))): Script/Comando -> $($Ev.Message -replace '\s+', ' ')"
    }
}

# Sección D: Auditoría de Integridad (Prefetch)
$PrefetchReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
if ($PrefetchReg -and $PrefetchReg.EnablePrefetcher -eq 0) {
    $Alertas_Bypass += "[!!!] CRÍTICO: El servicio Prefetcher está APAGADO en el Registro de Windows."
}
$ContadorPf = (Get-ChildItem -Path "$env:SystemRoot\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
if ($ContadorPf -lt 15) {
    $Alertas_Bypass += "[!!!] CRÍTICO: Carpeta Prefetch vaciada recientemente. Solo quedan $ContadorPf archivos."
}

# Sección E: Auditoría de Archivos Fantasma (BAM)
$RutaBam = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
if (Test-Path $RutaBam) {
    $SubClavesBam = Get-ChildItem -Path $RutaBam
    foreach ($Clave in $SubClavesBam) {
        $ValoresUsuario = Get-ItemProperty -Path $Clave.PSPath -ErrorAction SilentlyContinue
        if ($ValoresUsuario) {
            foreach ($Propiedad in $ValoresUsuario.PSObject.Properties) {
                if ($Propiedad.Name -match "\.exe|\.bat|\.py|\.ahk") {
                    $RutaNormalizada = $Propiedad.Name.ToLower()
                    
                    # Verificar si la ruta está en la lista de exclusiones
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
# FASE 2: INTERFAZ VISUAL ORDENADA
# =========================================================================
Clear-Host
Write-Host "=========================================================================" -ForegroundColor DarkRed
Write-Host "                         ABYZOTH SCAN v5.0.2                             " -ForegroundColor Red
Write-Host "                       DESARROLLADO POR: IKXPZL                          " -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor DarkRed

# EXPOSICIÓN ORDENADA DEL MÓDULO 1
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ [MÓDULO 1] RESULTADOS DE TELEMETRÍA DE COMANDOS (PYTHON / SHELL)      │" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
if ($Alertas_Comandos.Count -gt 0) {
    foreach ($A in $Alertas_Comandos) { Write-Host " $A" -ForegroundColor Red }
} else {
    Write-Host " [-] Registro limpio. No se encontraron comandos anómalos." -ForegroundColor Green
}

# EXPOSICIÓN ORDENADA DEL MÓDULO 2
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ [MÓDULO 2] RESULTADOS DE MEMORIA VOLÁTIL Y PROCESOS DE CAPTURA (PSR) │" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
if ($Alertas_Memoria.Count -gt 0) {
    foreach ($A in $Alertas_Memoria) { Write-Host " $A" -ForegroundColor Yellow }
} else {
    Write-Host " [-] Memoria limpia. No hay softwares de grabación o PSR activos." -ForegroundColor Green
}

# EXPOSICIÓN ORDENADA DEL MÓDULO 3
Write-Host "`n┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ [MÓDULO 3] HISTORIAL PERSISTENTE DE SCRIPTS .BAT (PCASVC TELEMETRY)   │" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
if ($Alertas_PcaSvc.Count -gt 0) {
    foreach ($A in $Alertas_PcaSvc) { Write-Host " $A" -ForegroundColor Yellow }
} else {
    Write-Host " [-] Telemetría limpia. Sin rastros de scripts de limpieza .bat recientes." -ForegroundColor Green
}

# EXPOSICIÓN ORDENADA DEL MÓDULO 4
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

[MÓDULO 1] TELEMETRÍA DE COMANDOS:
$($Alertas_Comandos -join "`r`n")
$(if($Alertas_Comandos.Count -eq 0){"Sin alertas."})

[MÓDULO 2] MEMORIA Y PROCESOS (PSR):
$($Alertas_Memoria -join "`r`n")
$(if($Alertas_Memoria.Count -eq 0){"Sin alertas."})

[MÓDULO 3] HISTORIAL PCASVC (.BAT):
$($Alertas_PcaSvc -join "`r`n")
$(if($Alertas_PcaSvc.Count -eq 0){"Sin alertas."})

[MÓDULO 4] INTENCIONES DE BYPASS Y BORRADOS (BAM / PREFETCH):
$($Alertas_Bypass -join "`r`n")
$(if($Alertas_Bypass.Count -eq 0){"Sin alertas."})
=========================================================================
"@
$ContenidoTxt | Out-File -FilePath $RutaReporte -Encoding utf8

Write-Host "`n=========================================================================" -ForegroundColor DarkRed
Write-Host " REPORTE EXPEDIDO CON ÉXITO EN EL ESCRITORIO POR IKXPZL:" -ForegroundColor Yellow
Write-Host " -> $RutaReporte" -ForegroundColor White
Write-Host "=========================================================================" -ForegroundColor DarkRed
