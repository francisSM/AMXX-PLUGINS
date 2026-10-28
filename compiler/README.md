# Compilador AMX Mod X 1.10 (Standalone)

Esta carpeta contiene los binarios oficiales del compilador Pawn de **AMX Mod X 1.10.0.5484** para entornos Windows y Linux, junto con scripts automatizados para compilar cualquier plugin del repositorio sin necesidad de instalaciones adicionales ni configuraciones complejas.

---

## Contenido del Directorio

* **Windows:**
  * `amxxpc.exe`: Ejecutable del compilador Pawn para Windows.
  * `amxxpc32.dll`: Librería de enlace dinámico requerida por el compilador en Windows.
  * `compile.exe`: Utilidad batch oficial de AMX Mod X.
  * `compile.bat`: Script automatizado para compilar plugins en Windows.
* **Linux:**
  * `amxxpc`: Binario ejecutable para sistemas operativos Linux (32/64 bits con multiarch).
  * `amxxpc32.so`: Librería compartida requerida en Linux.
  * `compile.sh`: Script en Bash automatizado para compilar en Linux.

---

## Cómo Compilar en Windows

### Opción 1: Arrastrar y Soltar (Recomendada)
Arrastra cualquier archivo `.sma` (por ejemplo `antispam.sma` o `server_mute.sma`) y suéltalo directamente sobre el archivo `compile.bat`. El archivo `.amxx` resultante se generará en la misma carpeta donde se encuentra el archivo fuente.

### Opción 2: Compilar Todo el Repositorio
Haz doble clic sobre `compile.bat` sin argumentos. El script buscará automáticamente todos los archivos `.sma` de las carpetas del repositorio y los compilará uno a uno utilizando las carpetas globales de inclusión (`include/`).

### Opción 3: Vía Símbolo del Sistema / PowerShell
Desde la raíz del repositorio, ejecuta:

```bat
.\compiler\amxxpc.exe "plugins\antispam\scripting\antispam.sma" -i"include" -i"plugins\antispam\scripting\include" -o"plugins\antispam\scripting\antispam.amxx"
```

---

## Cómo Compilar en Linux

1. Otorga permisos de ejecución a los binarios y al script:
   ```bash
   chmod +x compiler/amxxpc compiler/compile.sh
   ```
2. Compila un plugin específico:
   ```bash
   ./compiler/compile.sh plugins/antispam/scripting/antispam.sma
   ```
3. O compila todos los plugins del repositorio automáticamente:
   ```bash
   ./compiler/compile.sh
   ```

---

## Notas Técnicas

* Los scripts incluyen automáticamente la ruta de cabeceras globales `include/` y las carpetas de inclusión de cada plugin (`scripting/include/`).
* Versión del compilador: `1.10.0.5484`.

