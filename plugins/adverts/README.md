# Advanced Advertisements & Chat Triggers (v1.0)

Plugin avanzado y optimizado para **AMX Mod X** que gestiona anuncios automáticos rotativos tanto en el **chat** como en el **HUD**, además de permitir la creación de **disparadores de chat** (chat triggers o comandos personalizados como `/rules`, `/discord`, `/help`, etc.).

---

## Características Principales

1. **Anuncios por Chat Rotativos con Colores:**
   - Envío periódico de anuncios al chat con soporte nativo para colores de Counter-Strike:
     * `!g` = Verde
     * `!t` = Color del equipo (Azul CT / Rojo TT)
     * `!n` = Color normal
   - Soporte multilingüe mediante el diccionario `data/lang/adverts.txt` o textos planos directos.

2. **Anuncios HUD en Pantalla:**
   - Permite mostrar mensajes informativos en pantalla (HUD) con efectos visuales configurables (fade in/out, hold time, coordenadas X e Y personalizadas).

3. **Sistema de Pesos y Frecuencia de Rotación:**
   - Asigna una prioridad numérica a cada anuncio (del 1 al 10) para definir cuántas veces aparece por cada ciclo de rotación (por ejemplo, anuncios importantes con peso 3 y anuncios estándar con peso 1).

4. **Variables Dinámicas Automáticas:**
   - `%tag%` = Tag configurado en `adverts.ini`.
   - `%map%` = Nombre del mapa actual.
   - `%servername%` = Nombre del servidor (`hostname`).
   - `%newline%` = Salto de línea para anuncios HUD.

5. **Disparadores de Chat (Chat Triggers):**
   - Responde automáticamente cuando los jugadores escriben ciertas palabras clave o comandos (ejemplo: `rules`, `/rules`, `discord`, `/discord`, `help`, `/ayuda`).
   - Incluye control de cooldown individual para evitar flood.
   - Opción configurable para responder únicamente al jugador o a todo el servidor.

6. **Recarga en Caliente:**
   - Comando `amx_reloadadverts` en consola para recargar la configuración sin reiniciar el mapa.

---

## Estructura de Archivos

```text
adverts/
├── configs/
│   └── adverts.ini        # Configuración de anuncios, pesos y disparadores
├── data/
│   └── lang/
│       └── adverts.txt    # Diccionario de traducciones (EN / ES)
├── scripting/
│   └── adverts.sma        # Código fuente Pawn
└── README.md              # Documentación del plugin
```

---

## Configuración (`configs/adverts.ini`)

```ini
[SETTINGS]
; Tag oficial para los anuncios de chat
tag = !g[Server]

[HUD]
; Mensajes rotativos en pantalla HUD:
; Bienvenidos a %servername%%newline%Disfruta tu partida en %map%

[CHAT]
; Anuncios rotativos con peso/frecuencia:
ADVERT_WELCOME 2
ADVERT_RULES 2
ADVERT_DISCORD 2
ADVERT_HELP 1

; Disparadores de chat (triggers):
rules = ADVERT_RULES
reglas = ADVERT_RULES
discord = ADVERT_DISCORD
help = ADVERT_HELP
ayuda = ADVERT_HELP
```

---

## Variables de Consola (CVars)

| CVar | Valor por Defecto | Descripción |
| :--- | :---: | :--- |
| `amx_adverts_enabled` | `1` | Activa (`1`) o desactiva (`0`) los anuncios HUD. |
| `amx_adverts_interval` | `60.0` | Intervalo en segundos entre cada anuncio HUD. |
| `amx_adverts_random` | `0` | Orden aleatorio (`1`) o secuencial por pesos (`0`) para HUD. |
| `amx_adverts_chat_enabled` | `1` | Activa (`1`) o desactiva (`0`) los anuncios por chat. |
| `amx_adverts_chat_interval` | `45.0` | Intervalo en segundos entre cada anuncio por chat. |
| `amx_adverts_chat_random` | `0` | Orden aleatorio (`1`) o secuencial por pesos (`0`) para chat. |
| `amx_adverts_chatcmd_enabled` | `1` | Activa o desactiva los disparadores de chat. |
| `amx_adverts_chatcmd_to_all` | `0` | `0` = muestra la respuesta solo al jugador; `1` = la muestra a todos. |
| `amx_adverts_chatcmd_cooldown` | `5.0` | Tiempo de espera en segundos entre ejecuciones por jugador. |

---

## Comandos de Consola

| Comando | Nivel de Acceso | Descripción |
| :--- | :---: | :--- |
| `amx_reloadadverts` | `ADMIN_CVAR` (flag `g`) | Recarga la configuración de `adverts.ini` en tiempo real. |

---

## Instalación

1. Compila `scripting/adverts.sma` usando el compilador `amxxpc`.
2. Copia `adverts.amxx` en:
   ```text
   cstrike/addons/amxmodx/plugins/
   ```
3. Copia `configs/adverts.ini` en:
   ```text
   cstrike/addons/amxmodx/configs/
   ```
4. Copia `data/lang/adverts.txt` en:
   ```text
   cstrike/addons/amxmodx/data/lang/
   ```
5. Añade la siguiente línea en `cstrike/addons/amxmodx/configs/plugins.ini`:
   ```ini
   adverts.amxx
   ```
6. Cambia de mapa o reinicia el servidor.
