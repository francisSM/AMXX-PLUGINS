# Guía Completa: Cómo Instalar y Configurar AMX Mod X (CS 1.6 / GoldSrc)

Esta guía explica paso a paso cómo instalar **Metamod** y **AMX Mod X** desde cero en un servidor de **Counter-Strike 1.6** (válido para servidores dedicados **HLDS** o **ReHLDS**, tanto en **Windows** como en **Linux**), y cómo compilar e instalar los plugins de este repositorio.

---

## 1. Arquitectura de un Servidor con AMX Mod X

Para que AMX Mod X funcione, necesita ejecutarse a través de **Metamod**, que actúa como puente intermediario entre el motor del juego (GoldSrc) y los mods/plugins:

```text
Servidor CS 1.6 (HLDS / ReHLDS)
       │
       ▼
    Metamod (metamod.dll / metamod.so)
       │
       ▼
   AMX Mod X (amxmodx_mm.dll / amxmodx_mm_i386.so)
       │
       ├── Core y Módulos (fakemeta, cstrike, engine, regex, etc.)
       └── Plugins (.amxx) <--- Plugins de este repositorio
```

---

## 2. Descargas Oficiales Necesarias

A continuación se detallan los enlaces directos a las últimas versiones estables y repositorios oficiales de cada componente:

### Servidores Modernos (ReHLDS Stack - Recomendado)

| Componente | Repositorio Oficial | Descarga Directa (Releases) |
| :--- | :--- | :--- |
| **ReHLDS Engine** | [dreamstalker/rehlds](https://github.com/dreamstalker/rehlds) | [Últimas Releases de ReHLDS](https://github.com/dreamstalker/rehlds/releases) |
| **Metamod-r** | [theAsmodai/metamod-r](https://github.com/theAsmodai/metamod-r) | [Últimas Releases de Metamod-r](https://github.com/theAsmodai/metamod-r/releases) |
| **ReGameDLL CS** | [s1lentq/ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS) | [Últimas Releases de ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS/releases) |
| **AMX Mod X (v1.10 / v1.9)** | [alliedmodders/amxmodx](https://github.com/alliedmodders/amxmodx) | [Descargas Oficiales AMXX](https://www.amxmodx.org/downloads-new.php) / [Snapshots 1.10](https://www.amxmodx.org/snapshots.php) |
| **ReAPI (Módulo AMXX)** | [s1lentq/reapi](https://github.com/s1lentq/reapi) | [Últimas Releases de ReAPI](https://github.com/s1lentq/reapi/releases) |

### Servidores Clásicos (HLDS Original)

| Componente | Fuente Oficial | Enlace de Descarga |
| :--- | :--- | :--- |
| **Metamod 1.21.1-am** | AlliedModders | [Descargar Metamod](https://www.amxmodx.org/downloads-new.php) |
| **Metamod-P** | Jussi Kivilinna | [SourceForge Metamod-P](http://metamod-p.sourceforge.net/) |
| **AMX Mod X 1.8.2 / 1.8.3** | AlliedModders | [Descargas AMXX](https://www.amxmodx.org/downloads-new.php) |

> Nota sobre paquetes AMX Mod X: Para instalar AMXX en Counter-Strike 1.6 siempre se requieren dos archivos zip/tar.gz:
> 1. **Base Package** (`amxmodx-X.X.X-base-windows.zip` o `linux.tar.gz`)
> 2. **Counter-Strike Addon** (`amxmodx-X.X.X-cstrike-windows.zip` o `linux.tar.gz`)

---

## 3. Paso a Paso: Instalación de Metamod

1. En la carpeta raíz de tu servidor (donde se encuentra `cstrike`), navega a `cstrike/addons/`.
   - Si la carpeta `addons/` no existe, créala.
2. Crea la carpeta `cstrike/addons/metamod/` y dentro de ella crea la subcarpeta `dlls/`:
   ```text
   cstrike/addons/metamod/dlls/
   ```
3. Coloca el archivo binario de Metamod dentro de `cstrike/addons/metamod/dlls/`:
   - En **Windows**: `metamod.dll`
   - En **Linux**: `metamod.so` (o `metamod_i386.so`)

4. **Vincular Metamod al juego (`cstrike/liblist.gam`):**
   Abre el archivo `cstrike/liblist.gam` con un editor de texto (como Notepad o VS Code) y busca la línea `gamedll`:
   
   - **En Windows**, reemplaza:
     ```ini
     gamedll "dlls\mp.dll"
     ```
     por:
     ```ini
     gamedll "addons\metamod\dlls\metamod.dll"
     ```

   - **En Linux**, reemplaza:
     ```ini
     gamedll_linux "dlls/cs.so"
     ```
     por:
     ```ini
     gamedll_linux "addons/metamod/dlls/metamod.so"
     ```

5. Crea el archivo de configuración de plugins de Metamod:
   - Ruta: `cstrike/addons/metamod/plugins.ini`

---

## 4. Paso a Paso: Instalación de AMX Mod X

1. Extrae el paquete **AMX Mod X Base** dentro de la carpeta `cstrike/`. Esto creará la estructura:
   ```text
   cstrike/addons/amxmodx/
   ├── configs/
   ├── data/
   ├── dlls/
   ├── logs/
   ├── modules/
   ├── plugins/
   └── scripting/
   ```
2. Extrae el paquete **Counter-Strike Addon** encima de `cstrike/` (reemplazando archivos si lo solicita).
3. **Activar AMX Mod X en Metamod:**
   Abre el archivo `cstrike/addons/metamod/plugins.ini` que creaste en el paso anterior y añade la siguiente línea:

   - **En Windows:**
     ```ini
     win32 addons/amxmodx/dlls/amxmodx_mm.dll
     ```
   - **En Linux:**
     ```ini
     linux addons/amxmodx/dlls/amxmodx_mm_i386.so
     ```

---

## 5. Cómo Compilar e Instalar Plugins de este Repositorio

Todos los plugins en **AMXX-PLUGINS** vienen con su código fuente original (`.sma`). Para instalarlos en tu servidor debes compilarlos para generar el binario `.amxx`.

### Opción A: Compilación en Windows (Arrastrar y Soltar)
1. Navega a `cstrike/addons/amxmodx/scripting/`.
2. Si el plugin requiere un archivo include (`.inc`), cópialo dentro de `cstrike/addons/amxmodx/scripting/include/`.
3. Copia el archivo fuente `.sma` (ej. `antispam.sma`) dentro de `scripting/`.
4. Arrastra el archivo `.sma` sobre el ejecutable `compile.exe` o `amxxpc.exe`.
5. Se abrirá una ventana de consola y el plugin compilado aparecerá automáticamente dentro de `scripting/compiled/antispam.amxx`.
6. Mueve `antispam.amxx` a la carpeta `cstrike/addons/amxmodx/plugins/`.

### Opción B: Compilación por Línea de Comandos (Windows o Linux)
Ejecuta el compilador desde la terminal:
```bash
# En Windows:
.\amxxpc.exe antispam.sma -iinclude -o..\plugins\antispam.amxx

# En Linux:
./amxxpc antispam.sma -iinclude -o../plugins/antispam.amxx
```

### Opción C: Compilador Web Online
Si no tienes el compilador local a mano, puedes utilizar el compilador web oficial:
- [AlliedModders Web Compiler](https://www.amxmodx.org/webcompiler.cgi)

---

## 6. Despliegue de Archivos del Plugin en el Servidor

Cada plugin de este repositorio incluye carpetas organizadas listas para copiar y pegar:

| Archivo en el Repositorio | Destino en tu Servidor CS 1.6 |
| :--- | :--- |
| `scripting/antispam.sma` | `cstrike/addons/amxmodx/scripting/` |
| `scripting/include/antispam.inc` | `cstrike/addons/amxmodx/scripting/include/` |
| `configs/antispam.ini` | `cstrike/addons/amxmodx/configs/` |
| `data/lang/antispam.txt` | `cstrike/addons/amxmodx/data/lang/` |
| Binario compilado `antispam.amxx` | `cstrike/addons/amxmodx/plugins/` |

### Activar el Plugin:
Abre `cstrike/addons/amxmodx/configs/plugins.ini` y agrega al final:
```ini
antispam.amxx
```

---

## 7. Comprobación y Comandos Útiles

Una vez iniciado tu servidor o cambiado el mapa, abre la consola del servidor o la consola de jugador con RCON y verifica:

1. **Verificar que Metamod esté corriendo:**
   ```text
   meta list
   ```
   *Debe responder:* `AMX Mod X, running, amxmodx_mm...`

2. **Verificar los plugins cargados en AMXX:**
   ```text
   amx_plugins
   ```
   *El estado de tus plugins debe mostrarse como `running`.*

3. **Verificar módulos activos de AMXX:**
   ```text
   amx_modules
   ```
   *Debe mostrar módulos como FakeMeta, CStrike, Engine cargados correctamente.*

4. **Recargar configuración del AntiSpam sin reiniciar:**
   ```text
   antispam_reload
   ```
   *Recarga instantáneamente listas negras, blancas y ajustes desde `antispam.ini`.*
