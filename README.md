# AMXX-PLUGINS

Colección personal de plugins y utilidades para **AMX Mod X** (Counter-Strike 1.6 / Half-Life Engine).

Este repositorio contiene plugins modulares, optimizados y genéricos diseñados para ser utilizados en cualquier tipo de servidor (Público, Automix, CSDM, HNS, Kreedz, etc.) sin dependencias contextuales o cerradas a una comunidad en particular.

---

## Estructura del Repositorio

Cada plugin se encuentra organizado en su propio directorio independiente con la estructura estándar de AMX Mod X lista para desplegar en `cstrike/addons/amxmodx/`:

```text
AMXX-PLUGINS/
├── .gitignore
├── README.md
├── compiler/                  # Compilador Pawn AMX Mod X 1.10 (Windows y Linux)
│   ├── amxxpc.exe / amxxpc
│   ├── compile.bat / compile.sh
│   └── README.md
├── docs/
│   └── INSTALACION_AMXX.md
├── include/                   # Cabeceras globales estándar de AMX Mod X (.inc)
└── plugins/                   # Directorio de plugins modulares
    └── <plugin_name>/
        ├── configs/           # Archivos de configuración (.cfg, .ini)
        ├── data/
        │   └── lang/          # Diccionarios multilingües (.txt)
        ├── scripting/         # Código fuente Pawn (.sma)
        │   └── include/       # Includes y APIs dedicadas del plugin (.inc)
        └── README.md          # Documentación, instalación y uso del plugin
```

---

## Catálogo de Plugins Disponibles

| Plugin | Versión | Descripción |
| :--- | :---: | :--- |
| [**antispam**](./plugins/antispam/) | `1.0` | Sistema avanzado de prevención de spam, detección de publicidad IPv4, lista negra de palabras/enlaces, lista blanca de comandos y auto-sanción. |
| [**adverts**](./plugins/adverts/) | `1.0` | Sistema de anuncios automáticos rotativos (Chat y HUD) con soporte para disparadores de comandos (Chat Triggers), ponderación de frecuencia y colores personalizables. |
| [**server_mute**](./plugins/server_mute/) | `1.0` | Sistema dual de silenciamiento: control individual para jugadores (`/mute`) y gestión administrativa global (`/gag`, `amx_gag`) con persistencia en nVault y lista blanca de comandos. |

---

## Requisitos Generales

- **Servidor:** [ReHLDS Engine (Releases)](https://github.com/dreamstalker/rehlds/releases) o HLDS actualizado.
- **Metamod:** [Metamod-r (Releases)](https://github.com/theAsmodai/metamod-r/releases) o Metamod 1.21-am / Metamod-P.
- **AMX Mod X:** [AMX Mod X (Descargas Oficiales)](https://www.amxmodx.org/downloads-new.php) (v1.8.3, v1.9 o [v1.10 Snapshots](https://www.amxmodx.org/snapshots.php)).
- **Módulos estándar:** `amxmodx`, `fakemeta`.

---

## Guía de Instalación de AMX Mod X

Si estás configurando un servidor desde cero y aún no tienes AMX Mod X o Metamod instalado, consulta la guía detallada:

**[Guía Paso a Paso: Cómo Instalar Metamod y AMX Mod X desde Cero](./docs/INSTALACION_AMXX.md)**

Contenido de la guía:
- Descargas oficiales necesarias.
- Configuración de `liblist.gam` en Windows y Linux.
- Activación de AMX Mod X en Metamod `plugins.ini`.
- Cómo compilar archivos `.sma` a `.amxx`.
- Comandos útiles para verificar el estado de los módulos y plugins en consola.

---

## Instalación Rápida de Plugins de este Repositorio

1. Clona o descarga este repositorio:
   ```bash
   git clone https://github.com/francisSM/AMXX-PLUGINS.git
   ```
2. Dirígete a la carpeta del plugin que desees instalar en `plugins/` (ej. `plugins/antispam/`).
3. Compila el archivo `.sma` usando el compilador incluido en la carpeta `compiler/`:
   - **En Windows:** Arrastra el archivo `.sma` sobre `compiler/compile.bat`, o ejecuta `compiler/compile.bat` para compilar todos los plugins.
   - **En Linux:** Ejecuta `./compiler/compile.sh <ruta_plugin.sma>`.
4. Copia los archivos a tu servidor `cstrike/addons/amxmodx/`:
   - El archivo binario compilado `.amxx` en `plugins/`.
   - Los archivos de `configs/` en `configs/`.
   - Los archivos de `data/lang/` en `data/lang/`.
5. Agrega el nombre del plugin al final de `cstrike/addons/amxmodx/configs/plugins.ini`.
6. Cambia de mapa o reinicia el servidor.

---

## Licencia

Este proyecto se distribuye bajo la licencia **MIT**. Eres libre de usar, modificar y distribuir estos plugins en tus servidores.
