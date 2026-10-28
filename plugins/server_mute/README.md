# Player Mute & Admin Gag System

Sistema modular y profesional de silenciamiento dual para servidores Counter-Strike 1.6 y AMX Mod X 1.10+. Proporciona tanto control individual para jugadores (silenciar a otros de forma local) como herramientas administrativas avanzadas para sancionar el spam, insultos o toxicidad mediante gags globales con persistencia en nVault.

---

## Características Principales

1. **Silenciamiento Individual (Cliente a Cliente):**
   * Menú interactivo en pantalla (`/mute`) para silenciar individualmente a jugadores molestos sin afectar al resto del servidor.
   * Comandos rápidos `/muteall` y `/unmuteall` para silenciar o restaurar el audio de todos los jugadores conectados instantáneamente.
   * Persistencia por sesión: las preferencias de silencio se mantienen mientras el jugador permanezca conectado al servidor.

2. **Sistema Administrativo de Sanción Global (Admin Gag):**
   * Control total para administradores mediante comando de consola (`amx_gag`, `amx_ungag`) y menú interactivo visual (`/gag`, `/gagmenu`, `/adminmute`).
   * Selección de tipo de sanción:
     * **Chat + Voz:** Bloqueo integral de mensajes de texto y comunicación por micrófono.
     * **Solo Chat:** Bloqueo de mensajes en `say` y `say_team`.
     * **Solo Voz:** Bloqueo de voz por micrófono mediante Fakemeta (`FM_Voice_SetClientListening`).
   * Duraciones predeterminadas configurables: 5, 10, 30, 45 y 60 minutos (o cualquier tiempo en minutos vía comando de consola).
   * Inmunidad administrativa: Los administradores con flag `a` (`ADMIN_IMMUNITY`) no pueden ser silenciados, salvo por administradores principales con flag `l` (`ADMIN_RCON`).

3. **Bloqueo Inteligente de Mensajes de Radio:**
   * Bloqueo de comandos y audios de radio estándar (`coverme`, `takepoint`, `needbackup`, `roger`, etc.) para jugadores sancionados, evitando que eludan el gag mediante avisos de radio.

4. **Lista Blanca de Comandos Útiles (`server_mute.ini`):**
   * Los jugadores con sanción de gag no pueden conversar libremente, pero sí se les permite ejecutar comandos legítimos del servidor que inicien con `/`, `!` o `.` (por ejemplo: `/timeleft`, `/thetime`, `/nextmap`, `/rtv`, `/rules`, `/menu`).
   * La lista es 100% configurable por el administrador en `configs/server_mute.ini` sin necesidad de recompilar.

5. **Persistencia en nVault:**
   * Las sanciones de gag se guardan en el archivo de base de datos nVault `admin_gags.vault`.
   * Si un jugador desconecta y vuelve a entrar o si el servidor cambia de mapa, la sanción continúa activa con el tiempo restante exacto.

6. **Soporte Multilingüe:**
   * Archivo de traducción `data/lang/server_mute.txt` con soporte completo para Español e Inglés.

7. **API Pública para Desarrolladores:**
   * Cabecera Pawn `server_mute.inc` que exporta funciones nativas y eventos hacia otros plugins.

---

## Estructura de Archivos

```text
server_mute/
├── configs/
│   └── server_mute.ini        # Lista de comandos permitidos durante el gag
├── data/
│   └── lang/
│       └── server_mute.txt    # Diccionario de traducciones (Español / Inglés)
├── scripting/
│   ├── include/
│   │   └── server_mute.inc    # Cabecera Pawn con API pública (Natives y Forwards)
│   └── server_mute.sma        # Código fuente Pawn
└── README.md                  # Documentación del plugin
```

---

## Requisitos de Instalación

* **Motor:** ReHLDS o HLDS oficial.
* **AMX Mod X:** Versión 1.9.0 o superior (recomendado 1.10+).
* **Módulos requeridos:**
  * `fakemeta`
  * `nvault`

---

## Instrucciones de Instalación

1. Copia el archivo de configuración en tu servidor:
   * `configs/server_mute.ini` -> `cstrike/addons/amxmodx/configs/server_mute.ini`
2. Copia el diccionario multilingüe:
   * `data/lang/server_mute.txt` -> `cstrike/addons/amxmodx/data/lang/server_mute.txt`
3. Copia el archivo de inclusión si vas a compilar localmente o desarrollar plugins integrados:
   * `scripting/include/server_mute.inc` -> `cstrike/addons/amxmodx/scripting/include/server_mute.inc`
4. Compila `server_mute.sma` y coloca el binario compilado:
   * `server_mute.amxx` -> `cstrike/addons/amxmodx/plugins/server_mute.amxx`
5. Activa el plugin añadiendo su nombre al final de `cstrike/addons/amxmodx/configs/plugins.ini`:
   ```ini
   server_mute.amxx
   ```
6. Reinicia el servidor o cambia de mapa para cargar el plugin.

---

## Configuración (`configs/server_mute.ini`)

En este archivo puedes definir qué comandos de chat se le permite ejecutar a un jugador silenciado:

```ini
; ==============================================================================
; Configuración de Comandos Permitidos Durante Gag (server_mute.ini)
; ==============================================================================
; Los jugadores con sanción de gag en el chat no pueden enviar mensajes públicos,
; pero sí pueden ejecutar comandos útiles del servidor si están listados aquí.
; No incluyas barras '/' ni prefijos, solo la palabra clave en minúsculas.

[allowed_commands]
timeleft
thetime
nextmap
currentmap
rtv
nominate
nom
help
ayuda
rules
reglas
menu
rank
top15
stats
mute
unmute
```

---

## Comandos Disponibles

### Comandos para Jugadores:
| Comando | Descripción |
| :--- | :--- |
| `/mute`, `!mute`, `.mute` | Abre el menú interactivo para silenciar o escuchar a otros jugadores. |
| `/muteall`, `!muteall` | Silencia a todos los jugadores conectados. |
| `/unmuteall`, `!unmuteall` | Restaura el sonido de todos los jugadores conectados. |

### Comandos para Administradores:
| Comando | Acceso | Descripción |
| :--- | :--- | :--- |
| `/gag`, `/gagmenu`, `/adminmute` | `ADMIN_KICK`, `ADMIN_BAN` o `ADMIN_RCON` | Abre el menú interactivo para gestionar y aplicar silencios a jugadores. |
| `amx_gag <nombre/#userid> [tiempo] [flags]` | `ADMIN_KICK`, `ADMIN_BAN` o `ADMIN_RCON` | Aplica un gag por consola. Parámetros opcionales: tiempo en minutos (por defecto 10), flags: `c` (chat), `v` (voz) o `a` (ambos). |
| `amx_ungag <nombre/#userid>` | `ADMIN_KICK`, `ADMIN_BAN` o `ADMIN_RCON` | Remueve la sanción de silencio a un jugador por consola. |

---

## API para Desarrolladores (`server_mute.inc`)

Para utilizar las funciones de este plugin desde otro desarrollo en AMX Mod X, incluye su cabecera:

```pawn
#include <server_mute>
```

### Funciones Nativas Disponibles:

```pawn
// Verifica si un jugador tiene sanción de gag activa aplicada por un admin
native bool:server_is_user_gagged(id);

// Retorna los flags de la sanción (GAG_CHAT, GAG_VOICE, GAG_ALL)
native server_get_user_gag_flags(id);

// Retorna los segundos restantes de la sanción
native server_get_user_gag_remaining(id);

// Aplica una sanción de gag a un jugador
native bool:server_gag_user(id, iMinutes, iFlags, const szAdmin[] = "");

// Remueve la sanción de gag a un jugador
native bool:server_ungag_user(id, const szAdmin[] = "");

// Verifica si un jugador 'id' ha silenciado localmente a 'iTarget'
native bool:server_is_player_muted_by(id, iTarget);
```

### Forwards (Eventos):

```pawn
// Se ejecuta cuando un administrador aplica un gag a un jugador
forward server_on_player_gagged(id, iAdmin, iMinutes, iFlags);

// Se ejecuta cuando un gag expira o es retirado por un administrador
forward server_on_player_ungagged(id, iAdmin);
```

---

## Créditos

* **Autor original:** ggv
* **Modificaciones, contextualización genérica y modernización:** [F]rancisc0001
* **Plataforma:** AMX Mod X 1.10+ / Counter-Strike 1.6
