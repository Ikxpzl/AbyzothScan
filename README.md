# 💀 ABYZOTH SCAN v6.5.0 - Sistema Forense de Alta Velocidad

![PowerShell](https://shields.io)
![Security](https://shields.io)

**Abyzoth Scan** es una herramienta forense avanzada y automatizada desarrollada en PowerShell para entornos de alta velocidad. Está diseñada específicamente para auditores de seguridad, administradores de sistemas y moderadores de comunidades competitivas de videojuegos que necesitan realizar inspecciones rápidas (*screensharing / screenscan*) en busca de software no autorizado, automatizaciones, técnicas de evasión o destrucción de evidencias.

---

## 🚀 Ejecución Rápida (One-Liner)

No necesitas descargar manualmente el script. Puedes ejecutar la minería forense de forma remota inyectando el código directamente en la memoria de PowerShell.

### Instrucciones de uso:

1. Presiona la tecla **Windows**.
2. Escribe **CMD** (Símbolo del sistema).
3. Haz clic derecho y selecciona **Ejecutar como Administrador**.
4. Copia, pega y ejecuta el siguiente comando:

```cmd
powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/Ikxpzl/AbyzothScan/refs/heads/main/abyzoth.ps1' | iex"
```

---

## 🔍 Módulos Forenses Incluidos

El motor analiza de manera simultánea múltiples capas del sistema operativo sin congelar la máquina:

* **Módulo 1: Auditoría de Procesos (ID 4688)** ➔ Inspecciona eventos de seguridad recientes rastreando ejecuciones sospechosas de entornos Python (`.py`), consolas ocultas y argumentos prohibidos.
* **Módulo 2: Descriptores en Memoria Volátil** ➔ Escanea hilos y procesos activos (`Get-Process`) buscando firmas en tiempo real (herramientas de grabación, macros, inyectores).
* **Módulo 3: Telemetría de Aplicación (PcaSvc)** ➔ Analiza la caché del servicio de experiencia de aplicaciones de Windows para detectar software que fue ejecutado desde directorios temporales.
* **Módulo Extra: Volcado de PSReadLine** ➔ Analiza el historial persistente de comandos de PowerShell buscando scripts maliciosos o comandos de bypass, sincronizando el índice de líneas con precisión exacta.
* **Módulo 4 (A y B): Integridad, BAM y Anti-Bypass** ➔ Comprueba si el Prefetch fue deshabilitado o vaciado, y cruza datos con las llaves criptográficas del *Background Activity Moderator* (BAM) para identificar ejecutables sospechosos que fueron **borrados después de usarse**.

---

## 🎨 Interfaz Visual y Reportes

El script desecha la interfaz monótona tradicional de Windows y despliega una terminal optimizada con diseño industrial en bloques utilizando una paleta de colores moderna (**Cyan, Magenta y Rojo** para anomalías críticas).

Al finalizar la auditoría, genera automáticamente dos archivos en tu **Escritorio**:
1. `Abyzoth_Scan_Report_[Fecha].txt` ➔ Reporte limpio y resumido por categorías de las anomalías detectadas.
2. `Abyzoth_ConsoleHost_Full_[Fecha].txt` ➔ Volcado íntegro indexado de todo el historial de comandos de PowerShell encontrado.

---

## 🛠️ Requisitos del Sistema

* **Sistema Operativo**: Windows 10 o Windows 11.
* **Privilegios**: Ejecución obligatoria en una terminal con permisos de **Administrador** (necesario para leer el registro BAM y los logs de seguridad de eventos).

---
*Desarrollado por **IkxPzl** - Optimizado para análisis forense rápido y detección de firmas multi-capa.*
