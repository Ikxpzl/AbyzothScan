# --- RECOVERY IKXPZL: DEEP CARVING ENGINE ---
$ErrorActionPreference = "SilentlyContinue"

# Validar permisos de administrador (Obligatorio para leer sectores crudos del volumen)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] ERROR: Debes abrir PowerShell como ADMINISTRADOR para escanear sectores profundos." -ForegroundColor Red
    Exit
}

# --- BANNER GIGANTE (RECOVERY IKXPZL) ---
Clear-Host
Write-Host "██████╗ ███████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ██╗   ██╗    ██╗██╗  ██╗██╗  ██╗██████╗ ███████╗██╗     " -ForegroundColor Cyan
Write-Host "██╔══██╗██╔════╝██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗╚██╗ ██╔╝    ██║██║ ██╔╝╚██╗██╔╝██╔══██╗╚══███╔╝██║     " -ForegroundColor Cyan
Write-Host "██████╔╝█████╗  ██║     ██║   ██║██║   ██║█████╗  ██████╔╝ ╚████╔╝     ██║█████╔╝  ╚███╔╝ ██████╔╝  ███╔╝ ██║     " -ForegroundColor Cyan
Write-Host "██╔══██╗██╔══╝  ██║     ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗  ╚██╔╝      ██║██╔═██╗  ██╔██╗ ██╔═══╝  ███╔╝  ██║     " -ForegroundColor Cyan
Write-Host "██║  ██║███████╗╚██████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║   ██║       ██║██║  ██╗██╔╝ ██╗██║     ███████╗███████╗" -ForegroundColor Cyan
Write-Host "╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝       ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝" -ForegroundColor Cyan
Write-Host "                               [ PERMANENT DELETION CARVER v1.5 ]" -ForegroundColor Gray
Write-Host "=========================================================================================================" -ForegroundColor DarkCyan

# --- VERIFICACIÓN DE MOTOR DE CORTE DE MICROSOFT (WINFR) ---
if (-not (Get-Command winfr -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Instalandor de dependencias forenses de Microsoft..." -ForegroundColor Yellow
    # Descarga el motor de recuperación oficial de Microsoft en segundo plano desde la Store de forma silenciosa
    Start-Process winget -ArgumentList "install --id 9N26S50LN705 --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
    if (-not (Get-Command winfr -ErrorAction SilentlyContinue)) {
        Write-Host "[-] No se pudo instalar el motor de recuperación automática. Asegúrate de tener conexión a Internet." -ForegroundColor Red
        Exit
    }
}

# --- SELECCIÓN DE UNIDAD ---
Write-Host "`n[+] Unidad del sistema detectada: C:" -ForegroundColor Green
$TargetUnit = "C:"
$OutputDir = Join-Path [Environment]::GetFolderPath("Desktop") "IKXPZL_Recovered"

Write-Host "[*] Preparando análisis de clusters y firmas en la unidad $TargetUnit..." -ForegroundColor Yellow
Write-Host "[*] Buscando archivos eliminados permanentemente (Shift+Delete / Comandos Forzados)..." -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------------------------------------------------" -ForegroundColor DarkCyan

# --- MENÚ DE INTERFAZ DE LÍNEA DE COMANDOS ---
Write-Host "Selecciona el método de extracción profunda:" -ForegroundColor White
Write-Host " [1] Escaneo de Segmentos (Para archivos borrados permanentemente hace poco)" -ForegroundColor Cyan
Write-Host " [2] Escaneo de Firmas Raw (Para recuperar extensiones específicas de trucos .exe, .sys, .json)" -ForegroundColor Cyan
$Mode = Read-Host "`n[?] Elige una opción (1 o 2)"

if ($Mode -eq "1") {
    Write-Host "`n[*] Iniciando modo Segmento Extendido. Analizando bloques huerfanos..." -ForegroundColor Yellow
    # Lanza el motor profundo en modo segmento hacia tu carpeta del Escritorio
    winfr C: $OutputDir /regular /verbose
}
elif ($Mode -eq "2") {
    $Ext = Read-Host "[?] Introduce la extensión a cazar sin punto (ejemplo: exe, sys, json, txt)"
    Write-Host "`n[*] Escaneando clusters libres buscando firmas binarias de archivos .$Ext ..." -ForegroundColor Yellow
    # Fuerza al disco duro a buscar rastros binarios crudos ignorando la tabla de archivos corrupta
    winfr C: $OutputDir /extensive /x /y:$Ext
}
else {
    Write-Host "[-] Selección inválida." -ForegroundColor Red
    Exit
}

# --- RESULTADO FINAL ---
if (Test-Path $OutputDir) {
    Write-Host "`n[✔] SUCCESS: ¡Proceso de extracción profunda finalizado!" -ForegroundColor Green
    Write-Host "[+] Los archivos extraídos del disco se han volcado en tu Escritorio: '$OutputDir'" -ForegroundColor Cyan
} else {
    Write-Host "`n[-] No se pudieron extraer estructuras legibles o el proceso fue cancelada." -ForegroundColor Red
}
