# Servidor Minecraft Fabric 26.3

Servidor dedicado Fabric para hasta **20 jugadores**. Con CGNAT, el acceso remoto se hace con **Tailscale**.

## Stack

| Componente | Versión |
|---|---|
| Minecraft | 26.3 |
| Fabric Loader | 0.19.5 |
| Fabric API | 0.165.0+26.3 |
| JourneyMap | 26.3-6.0.10 |
| Java | 25 (Temurin) |

## Acceso con Tailscale

Sin port forward ni límites de tráfico de túneles. Cada jugador instala Tailscale (gratis Personal).

### En este Mac (host del server)

1. Instala Tailscale: https://tailscale.com/download/mac  
   (o App Store → “Tailscale”, o `brew install --cask tailscale` en tu terminal — pide contraseña).
2. Abre **Tailscale** → **Log in** (Google/Microsoft/GitHub/Apple).
3. Deja el interruptor **Connected** en ON.
4. Copia la IP Tailscale de este Mac:

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4
# o: tailscale ip -4
```

Verás algo como `100.x.x.x`.

5. Arranca Minecraft: `./start.sh`
6. En [admin.tailscale.com](https://login.tailscale.com/admin/machines) → **Invite users** / comparte invite link a tus amigos.

### En cada amigo (jugador)

1. Instala Tailscale y acepta tu invitación al mismo tailnet.
2. Connected = ON.
3. En Minecraft → Multiplayer → Direct Connection: `100.x.x.x:25565`  
   (la IP del Mac host, no la de ellos).

Opcional: en el admin de Tailscale, renombra la máquina a `mcserver` y pueden usar `mcserver:25565` si MagicDNS está activo.

## Arrancar

```bash
./start.sh
```

## Backup del mundo (iCloud)

No pongas la carpeta `world/` en vivo dentro de iCloud (puede corromperse mientras juegas). El mundo vive local y se copia a iCloud con:

```bash
./backup-world.sh
```

Guarda en:
`iCloud Drive/MinecraftBackups/mcserver/AAAA-MM-DD_HH-MM-SS/`

Mantiene los últimos 10 backups (`KEEP=20 ./backup-world.sh` para cambiar). Ideal: parar el server o hacer `/save-all` antes.

El script copia `world/` y `mods/`, **no** `config/`. Si cambias claims u otros ajustes, copia `config/` a mano al backup.

Restaurar (el server debe estar parado):

```bash
./restore-world.sh              # elige de una lista
./restore-world.sh 2026-10-11_02-24-34   # backup concreto
```

Antes de sobrescribir, mueve el mundo actual a `world.pre-restore.*` por seguridad.

## Dominio Cloudflare (`mc.r0r71z.dev`)

`update-dns.sh` puede actualizar un registro A, pero **con CGNAT no sirve para jugar**. Usa Tailscale. Si más adelante tienes IP pública real, puedes volver al port forward + dominio.

## Mods en el server (`mods/`)

| Mod | Versión | Notas |
|---|---|---|
| Fabric API | 0.165.0+26.3 | requerido |
| JourneyMap | 26.3-6.0.10 | mapa (opcional en cliente) |
| Balm | 26.3.0.3 | requerido por TrashSlot y Waystones |
| TrashSlot | 26.3.0.1 | slot de basura (opcional en cliente) |
| SLC SimpleLandClaim (ShopGuard) | 0.9.0+mc26.3 | claims; **solo server** |
| Discord-MC-Chat (DMCC) | 2.7.1 | chat bidireccional Discord ↔ Minecraft (**solo server**) |
| JEI | 31.12.0.65 | recetas (requiere Mezz Config; opcional en cliente) |
| Mezz Config | 0.6.8 | requerido por JEI |
| Collective | 8.58 | requerido por Tree Harvester |
| Tree Harvester | 10.3 | talar árboles enteros |
| Accelerating Happy Ghasts | 0.0.1-26.3 | ghasts más rápidos |
| Grim Kingdoms Lost Structures | 2.0.0 | datapack de estructuras |
| Weapons Expanded | 2.1.2.1 | armas nuevas |
| Better Revive | 2.2.1 | tumbas y reanimación (minijuego Life Pulse al mínimo) |
| Remnants (The Eclipsed Realm) | 3.1.0 | dimensión y bosses |
| GeckoLib | 5.5.7 | requerido por Remnants |
| JAuml | 2.3.1 | requerido por Remnants |
| Macaw's Furniture | 3.4.2 | muebles |
| Aerial Hell | 0.7.8 | dimensión de islas flotantes |
| Shogi | 26.3.0.3 | requerido por Waystones |
| Waystones | 26.3.0.1 | teletransporte entre waystones |
| Dream Displays | 1.10.6 | pantallas de vídeo (opcional en cliente para verlas) |
| AutoModpack | 5.0.0-rc.7 | sincroniza el pack al entrar |

When Dungeons Arise **no está instalado**: no hay build Fabric para Minecraft 26.3 (última: 2.1.71 para 26.1.2).

## Discord bridge (DMCC)

Solo server. Config: `config/discord-mc-chat.json` (ignorado por git; contiene el token). AutoModpack **no** envía este archivo a los clientes.

1. Crea un bot en https://discord.com/developers/applications → Bot → token.
2. Invita el bot al Discord con permisos de leer/enviar mensajes y Manage Webhooks.
3. Activa modo desarrollador en Discord → copia el ID del canal de chat.
4. Edita `config/discord-mc-chat.json`:
   - `generic.botToken` → token del bot
   - `generic.channelId` → ID del canal
5. Reinicia el server (`./start.sh`). Sin token/canal válidos, DMCC falla al arrancar.

Docs: https://blog.xujiayao.com/posts/4ba0a17a/

## Clientes (AutoModpack)

Minecraft **no** instala mods al conectar. Cada jugador hace un bootstrap **una sola vez**; después, entrar al server descarga y actualiza el pack.

### Primera vez

1. Minecraft **26.3** + [Fabric Loader](https://fabricmc.net/use/installer/) (misma versión que el server: **0.19.5**).
2. Pon `automodpack-5.0.0-rc.7.jar` (está en `mods/` del server) en la carpeta `mods` de Fabric del jugador.  
   Alternativa: el [instalador Fabric modificado de AutoModpack](https://modrinth.com/mod/automodpack).
3. Conéctate a `100.x.x.x:25565` (IP Tailscale del host).
4. Acepta el certificado / fingerprint la primera vez, deja que baje el pack y **reinicia** el juego si lo pide.

Las siguientes veces el pack se actualiza al entrar o al arrancar. AutoModpack v5 es release candidate (beta).

### Qué se sincroniza

**Obligatorio** (sin esto Fabric echa): Fabric API, Weapons Expanded, Better Revive, Remnants, GeckoLib, JAuml, Macaw's Furniture, Aerial Hell, Waystones, Shogi, Balm.

**Opcional** (se puede desmarcar en AutoModpack): JourneyMap, JEI + Mezz Config, TrashSlot, Dream Displays, Tree Harvester + Collective.

**No se envía al cliente:** SLC/ShopGuard, Discord-MC-Chat (ni su config con el token).

Tras cambiar jars en `mods/` del server, un op corre `/automodpack generate` (o reinicia; `generate-modpack-on-start` está activo).

### Claims (SLC)

Pala de oro: dos esquinas para reclamar; clic en el aire para modo carve. Comandos: `/claim`, `/claim show`, `/claim remove`, `/claim trust <jugador>`. Ops: `/claim zone` o azada de oro.

Los claims viejos de TheLandClaim se borraron a propósito; hay que reclamar de nuevo.

## Notas

- EULA aceptado, `max-players=20`, whitelist off.
- RAM: 2–6 GB en `start.sh`. Aerial Hell + Remnants + Dream Displays pesan; si el TPS baja, subir `-Xmx`.
- `allow-flight=true` (vuelo de Aerial Hell; si no, Minecraft expulsa).
- Reinicia el server (`stop` + `./start.sh`) tras añadir mods.
