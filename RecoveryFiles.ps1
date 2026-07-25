# --- CONFIGURACIÓN DE INTERFAZ Y RESTRICCIONES ---
$ErrorActionPreference = "SilentlyContinue"

# Validar permisos de administrador (Obligatorio para interactuar con los sectores crudos de los discos)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] ERROR: Debes abrir PowerShell como ADMINISTRADOR para realizar un escaneo profundo." -ForegroundColor Red
    Exit
}

# --- BANNER GIGANTE CON TU FIRMA (RECOVERY IKXPZL) ---
Clear-Host
Write-Host "██████╗ ███████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ██╗   ██╗    ██╗██╗  ██╗██╗  ██╗██████╗ ███████╗██╗     " -ForegroundColor Cyan
Write-Host "██╔══██╗██╔════╝██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗╚██╗ ██╔╝    ██║██║ ██╔╝╚██╗██╔╝██╔══██╗╚══███╔╝██║     " -ForegroundColor Cyan
Write-Host "██████╔╝█████╗  ██║     ██║   ██║██║   ██║█████╗  ██████╔╝ ╚████╔╝     ██║█████╔╝  ╚███╔╝ ██████╔╝  ███╔╝ ██║     " -ForegroundColor Cyan
Write-Host "██╔══██╗██╔══╝  ██║     ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗  ╚██╔╝      ██║██╔═██╗  ██╔██╗ ██╔═══╝  ███╔╝  ██║     " -ForegroundColor Cyan
Write-Host "██║  ██║███████╗╚██████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║   ██║       ██║██║  ██╗██╔╝ ██╗██║     ███████╗███████╗" -ForegroundColor Cyan
Write-Host "╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝       ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝" -ForegroundColor Cyan
Write-Host "                                   [ Multi-Drive Deep Carver v2.1 ]" -ForegroundColor Gray
Write-Host "=========================================================================================================" -ForegroundColor DarkCyan

# --- DETECCIÓN AUTOMÁTICA DE DEPENDENCIAS FORENSES (WINFR) ---
if (-not (Get-Command winfr -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Instalando dependencias forenses de Microsoft en segundo plano..." -ForegroundColor Yellow
    Start-Process winget -ArgumentList "install --id 9N26S50LN705 --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
    if (-not (Get-Command winfr -ErrorAction SilentlyContinue)) {
        Write-Host "[-] Error crítico: No se pudo instalar el motor automático de Microsoft." -ForegroundColor Red
        Exit
    }
}

# --- DETECCIÓN DE UNIDADES ACTIVAS DEL USUARIO ---
Write-Host "[+] Escaneando almacenamiento y discos conectados..." -ForegroundColor Green
$Unidades = Get-Volume | Where-Object { $_.DriveLetter -and ($_.DriveType -eq "Fixed" -or $_.DriveType -eq "Removable") }

Write-Host "`nUnidades disponibles encontradas:" -ForegroundColor White
Write-Host "--------------------------------------------------------" -ForegroundColor DarkCyan
foreach ($u in $Unidades) {
    $SizeGB = [Math]::Round(($u.Size / 1GB), 1)
    $FreeGB = [Math]::Round(($u.SizeRemaining / 1GB), 1)
    Write-Host "  Letra: [$($u.DriveLetter):] | Nombre: $($u.FileSystemLabel) | Tamaño: $SizeGB GB | Libre: $FreeGB GB" -ForegroundColor Cyan
}
Write-Host "--------------------------------------------------------" -ForegroundColor DarkCyan

# Seleccionar qué unidad se va a analizar
$DriveToScanInput = Read-Host "`n[?] Introduce la letra del disco que quieres escanear (Ejemplo: C o D)"
$DriveToScan = ($DriveToScanInput -replace ":", "").ToUpper() + ":"

if (-not (Get-Volume -DriveLetter $DriveToScanInput[0] -ErrorAction SilentlyContinue)) {
    Write-Host "[-] ERROR: La unidad especificada no existe en el sistema." -ForegroundColor Red
    Exit
}

# --- CONTROL AUTOMÁTICO DE LA RUTA DE DESTINO ---
$DriveToSave = $null
foreach ($u in $Unidades) {
    if ("$($u.DriveLetter):" -ne $DriveToScan) {
        $DriveToSave = "$($u.DriveLetter):"
        break
    }
}

# Formatear rutas estrictas sin barras duplicadas ni conflictos para winfr
if ($null -eq $DriveToSave) {
    Write-Host "`n[!] ADVERTENCIA: Solo tienes un disco ($DriveToScan). Forzando volcado local..." -ForegroundColor Yellow
    $OutputDir = "C:\IKXPZL_Recovered"
} else {
    Write-Host "`n[+] Configuración segura: Analizando unidad $DriveToScan y guardando resultados en $DriveToSave" -ForegroundColor Green
    $OutputDir = "$DriveToSave\IKXPZL_Recovered"
}

# --- SELECCIÓN DEL MÉTODO DE EXTRACCIÓN ---
Write-Host "`nSelecciona el método de extracción profunda:" -ForegroundColor White
Write-Host " [1] Escaneo de Segmentos (Para archivos eliminados permanentemente / Shift+Delete)" -ForegroundColor Cyan
Write-Host " [2] Escaneo de Firmas Raw (Rastrea sectores libres buscando extensiones específicas: exe, sys, txt)" -ForegroundColor Cyan
$Mode = Read-Host "`n[?] Elige tu opción (1 o 2)"

Write-Host "`n=========================================================================================================" -ForegroundColor DarkCyan

# Asegurar la existencia previa del directorio de salida para evitar el error de "carpeta de destino"
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory | Out-Null
}

if ($Mode -eq "1") {
    Write-Host "[*] Iniciando modo Segmento Extendido de Microsoft sobre $DriveToScan ..." -ForegroundColor Yellow
    # Sintaxis limpia nativa requerida por winfr
    winfr $DriveToScan $OutputDir /regular /verbose
}
elif ($Mode -eq "2") {
    $Ext = Read-Host "[?] Introduce la extensión del archivo que borraste (ejemplo: exe, sys, txt)"
    $Ext = $Ext -replace "\.", ""
    Write-Host "`n[*] Escaneando clusters buscando cabeceras binarias crudas para archivos .$Ext en $DriveToScan..." -ForegroundColor Yellow
    winfr $DriveToScan $OutputDir /extensive /x /y:$Ext
}
else {
    Write-Host "[-] Selección inválida. Cancelando proceso." -ForegroundColor Red
    Exit
}

# --- COMPROBACIÓN FINAL ---
if ((Get-ChildItem $OutputDir).Count -gt 0) {
    Write-Host "`n[✔] SUCCESS: ¡Extracción finalizada con éxito!" -ForegroundColor Green
    Write-Host "[+] Los archivos rescatados se han volcado en la ruta segura: '$OutputDir'" -ForegroundColor Cyan
} else {
    Write-Host "`n[-] El motor terminó el análisis. Si la carpeta está vacía, el disco SSD ya purgó los bloques mediante TRIM." -ForegroundColor Yellow
}
