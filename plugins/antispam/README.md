# Anti-Spam & Chat Filter (v1.0)

Plugin modular, ligero y de alto rendimiento para **AMX Mod X** que previene el spam en el chat, flood repetitivo de binds, publicidad de direcciones IPv4 (incluso con camuflaje de espacios o puertos) y palabras/enlaces no deseados tanto en el chat como en el nickname de los jugadores.

---

## Características Principales

1. **Detección Avanzada de IPv4:**
   - Detecta direcciones IPv4 reales (4 octetos válidos entre 0 y 255).
   - Bloquea IPs con o sin puerto, separadas por espacios, guiones o comas (ej. `190. 200. 10. 5:27015`).

2. **Lista Negra Dinámica (`[blacklist]`):**
   - Configura palabras, dominios o enlaces prohibidos en `antispam.ini`.
   - Se bloquean en tiempo real tanto en mensajes de chat (`say` / `say_team`) como en el nombre del jugador (`client_putinserver` y `ClientUserInfoChanged`).

3. **Lista Blanca Flexible (`[whitelist]`):**
   - Permite definir comandos de juego comunes (`spec`, `help`, `timeleft`, `thetime`, etc.) y expresiones habituales (`gg`, `gl`, `hf`, `ty`, etc.) para evitar falsos positivos si los jugadores los usan con frecuencia.
   - Cualquier mensaje que inicie con `/`, `!` o `.` queda exento de detección de flood por defecto.

4. **Protección y Renombrado de Nicks:**
   - Si un jugador entra con una IP o palabra prohibida en su nick, o intenta cambiárselo durante la partida, el plugin lo renombra automáticamente a `<rename_prefix>_<id>` (por defecto `Player_1`, `Player_2`, etc., configurable en `antispam.ini`).

5. **Sistema Escalonado de Sanciones:**
   - **Nivel 1:** Advertencia privada en el chat.
   - **Nivel 2:** Auto-Mute temporal de 60 segundos con anuncio global.
   - **Nivel 3:** Expulsión del servidor (`kick`).
   - **Nivel 4+:** Baneo temporal de 15 minutos (`amx_ban 15`).
   - Todos los tiempos y ventanas de reincidencia son 100% configurables.

6. **Inmunidad para Administradores:**
   - Los jugadores con privilegios administrativos (`ADMIN_CHAT`, `ADMIN_BAN`, `ADMIN_KICK`, `ADMIN_IMMUNITY`, `ADMIN_RCON`) no sufren sanciones ni renombrados forzosos, recibiendo únicamente un aviso preventivo.

7. **Registro y Auditoría:**
   - Registra todos los incidentes en `addons/amxmodx/logs/antispam_incidents.log` con nombre, SteamID, IP y razón de la sanción.

8. **Recarga en Caliente:**
   - Comando `antispam_reload` en consola para recargar la configuración, blacklist y whitelist sin reiniciar el servidor ni cambiar de mapa.

9. **Soporte Multilingüe:**
   - Diccionario `data/lang/antispam.txt` con soporte completo para Español e Inglés.

---

## Estructura de Archivos

```text
antispam/
├── configs/
│   └── antispam.ini       # Configuración principal, blacklist y whitelist
├── data/
│   └── lang/
│       └── antispam.txt   # Diccionario de traducciones (EN / ES)
├── scripting/
│   ├── include/
│   │   └── antispam.inc   # Cabecera Pawn con API pública (Natives & Forwards)
│   └── antispam.sma       # Código fuente Pawn
└── README.md              # Documentación del plugin
```

---

## Configuración (`configs/antispam.ini`)

```ini
[settings]
; Duración del auto-mute en segundos tras detectar spam/IP/palabra bloqueada
mute_duration = 60.0

; Duración del ban temporal en minutos ante reincidencia grave (Nivel 4+)
ban_duration = 15

; Ventana de tiempo (segundos) para considerar que una infracción es reincidente
reoffense_window = 45.0

; Intervalo máximo (segundos) entre mensajes idénticos para considerarlo flood/spam
repeat_time_window = 3.0

; Prefijo para renombrar jugadores cuyo nombre contenga IP o palabra bloqueada
rename_prefix = "Player"

[blacklist]
; Palabras, enlaces o dominios bloqueados (entre comillas)
; "ejemplo.com"
; "palabramaliciosa"

[whitelist]
; Comandos de juego o palabras cortas permitidas que no cuentan para flood
"spec"
"join"
"help"
"menu"
"timeleft"
"thetime"
"rtv"
"nom"
"top"
"rank"
"afk"
"gg"
"gl"
"hf"
"ty"
"np"
```

---

## Comandos de Consola

| Comando | Nivel de Acceso | Descripción |
| :--- | :---: | :--- |
| `antispam_reload` | `ADMIN_RCON` (flag `l`) | Recarga `antispam.ini` (ajustes, blacklist y whitelist) en caliente sin reiniciar el mapa. |

---

## Instalación

1. Descarga los archivos de esta carpeta.
2. Compila `scripting/antispam.sma` con el compilador `amxxpc` de tu versión de AMX Mod X.
3. Copia `antispam.amxx` en tu servidor en:
   ```text
   cstrike/addons/amxmodx/plugins/
   ```
4. Copia `configs/antispam.ini` en:
   ```text
   cstrike/addons/amxmodx/configs/
   ```
5. Copia `data/lang/antispam.txt` en:
   ```text
   cstrike/addons/amxmodx/data/lang/
   ```
6. Agrega la siguiente línea en `cstrike/addons/amxmodx/configs/plugins.ini`:
   ```ini
   antispam.amxx
   ```
7. Cambia de mapa o reinicia el servidor.

---

## Requisitos

- **AMX Mod X:** Versión `1.8.3`, `1.9` o `1.10+`.
- **Módulos:** `amxmodx`, `fakemeta`.
- **Dependencias externas:** Ninguna (100% independiente).

---

## API para Desarrolladores (`scripting/include/antispam.inc`)

Otros plugins pueden integrarse con `antispam` incluyendo su cabecera `#include <antispam>`:

```pawn
// Comprueba si un jugador está auto-silenciado
native bool:antispam_is_user_muted(id);

// Retorna los segundos restantes de silencio del jugador (0.0 si no está muteado)
native Float:antispam_get_user_mute_time(id);

// Silencia o desilencia a un jugador (fDuration <= 0.0 para desmutear)
native bool:antispam_set_user_mute(id, Float:fDuration);

// Analiza si un texto contiene palabras/dominios de la blacklist
native bool:antispam_has_blacklisted_word(const szText[]);

// Analiza si un texto contiene una dirección IPv4
native bool:antispam_is_ip_address(const szText[]);

// Forward ejecutado cuando un jugador recibe una sanción
forward antispam_on_sanction(id, iLevel, const szReason[]);
```
