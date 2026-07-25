# --- CONFIGURACIÓN DE INTERFAZ Y RESTRICCIONES ---
$ErrorActionPreference = "SilentlyContinue"

# Validar permisos de administrador (Obligatorio para interactuar con la papelera profunda del sistema)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] ERROR: Debes abrir PowerShell como ADMINISTRADOR para escanear sectores profundos." -ForegroundColor Red
    Exit
}

# --- BANNER GIGANTE CON TU NOMBRE (RECOVERY IKXPZL) ---
Clear-Host
Write-Host "██████╗ ███████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ██╗   ██╗    ██╗██╗  ██╗██╗  ██╗██████╗ ███████╗██╗     " -ForegroundColor Cyan
Write-Host "██╔══██╗██╔════╝██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗╚██╗ ██╔╝    ██║██║ ██╔╝╚██╗██╔╝██╔══██╗╚══███╔╝██║     " -ForegroundColor Cyan
Write-Host "██████╔╝█████╗  ██║     ██║   ██║██║   ██║█████╗  ██████╔╝ ╚████╔╝     ██║█████╔╝  ╚███╔╝ ██████╔╝  ███╔╝ ██║     " -ForegroundColor Cyan
Write-Host "██╔══██╗██╔══╝  ██║     ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗  ╚██╔╝      ██║██╔═██╗  ██╔██╗ ██╔═══╝  ███╔╝  ██║     " -ForegroundColor Cyan
Write-Host "██║  ██║███████╗╚██████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║   ██║       ██║██║  ██╗██╔╝ ██╗██║     ███████╗███████╗" -ForegroundColor Cyan
Write-Host "╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝       ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝" -ForegroundColor Cyan
Write-Host "                                   [ CLI Engine v1.0 ]" -ForegroundColor Gray
Write-Host "=========================================================================================================" -ForegroundColor DarkCyan
Write-Host "[*] Iniciando escaneo forense de archivos eliminados..." -ForegroundColor Yellow

# --- MOTOR DE ESCANEO DE ARCHIVOS ELIMINADOS ---
$RecyclePath = "C:\`$Recycle.Bin"
$DeletedArtifacts = @()
$Counter = 1

# Buscar los metadatos reales de archivos borrados en todos los perfiles de usuario
$MetaFiles = Get-ChildItem -Path $RecyclePath -Include "`$I*" -File -Recurse -Force

foreach ($File in $MetaFiles) {
    $RealFile = Get-ChildItem -Path $File.Directory.FullName -Filter ($File.Name -replace "^\`$I", "`$R") -File -Force
    
    if ($RealFile) {
        $DeletedArtifacts += [PSCustomObject]@{
            ID           = $Counter
            FileName     = $RealFile.Name
            SizeMB       = [Math]::Round(($RealFile.Length / 1MB), 2)
            OriginalPath = $RealFile.FullName
            MetaLocation = $File.FullName
        }
        $Counter++
    }
}

if ($DeletedArtifacts.Count -eq 0) {
    Write-Host "[-] No se han encontrado registros huérfanos recuperables en este volumen." -ForegroundColor Red
    Exit
}

# --- MOSTRAR TABLA DE SELECCIÓN ---
Write-Host "[+] Se han localizado $($DeletedArtifacts.Count) archivos eliminados en el disco:`n" -ForegroundColor Green
$DeletedArtifacts | Format-Table ID, FileName, @{Name="Size (MB)"; Expression={$_.SizeMB}}, OriginalPath -AutoSize

# --- PROCESO DE SELECCIÓN Y RECUPERACIÓN ---
$Selection = Read-Host "`n[?] Introduce el número ID del archivo que deseas recuperar (o 'q' para salir)"

if ($Selection -eq 'q') {
    Write-Host "[*] Operación cancelada por el usuario." -ForegroundColor Gray
    Exit
}

$TargetFile = $DeletedArtifacts | Where-Object { $_.ID -eq $Selection }

if (-not $TargetFile) {
    Write-Host "[-] ID no válido. Ejecuta el comando de nuevo para reescandear." -ForegroundColor Red
    Exit
}

# Configurar carpeta de salida en el Escritorio
$OutputDir = Join-Path [Environment]::GetFolderPath("Desktop") "IKXPZL_Recovered"
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory | Out-Null
}

$DestinationPath = Join-Path $OutputDir $TargetFile.FileName

# Reconstruir el archivo moviendo y renombrando los bloques binarios de la papelera oculta
try {
    Copy-Item -Path $TargetFile.OriginalPath -Destination $DestinationPath -Force
    Write-Host "`n[✔] SUCCESS: ¡Archivo recuperado con éxito!" -ForegroundColor Green
    Write-Host "[+] Guardado en: $DestinationPath" -ForegroundColor Cyan
}
catch {
    Write-Host "[-] Error crítico al reconstruir los sectores del archivo: $_" -ForegroundColor Red
}
