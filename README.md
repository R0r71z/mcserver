# Servidor Minecraft Fabric 26.3

Servidor dedicado Fabric para hasta **20 jugadores**. Con CGNAT, el acceso remoto se hace con **Tailscale**.

## Stack

| Componente | Versión |
|---|---|
| Minecraft | 26.3 |
| Fabric Loader | 0.19.5 |
| Fabric API | 0.162.0+26.3 |
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
| Fabric API | 0.162.0+26.3 | requerido |
| JourneyMap | 26.3-6.0.10 | mapa |
| Balm | 26.3.0.3 | requerido por TrashSlot |
| TrashSlot | 26.3.0.1 | slot de basura |
| SecurityCraft (Fabric port) | V0.6 | CurseForge port, no el oficial NeoForge |
| Areed's CoreLib | 1.3.0 | requerido por TheLandClaim |
| TheLandClaim (ClaimsMod) | 1.1.1 | protección de terreno |
| Discord-MC-Chat (DMCC) | 2.7.1 | chat bidireccional Discord ↔ Minecraft (solo server) |

## Discord bridge (DMCC)

Solo server. Config: `config/discord-mc-chat.json` (ignorado por git; contiene el token).

1. Crea un bot en https://discord.com/developers/applications → Bot → token.
2. Invita el bot al Discord con permisos de leer/enviar mensajes y Manage Webhooks.
3. Activa modo desarrollador en Discord → copia el ID del canal de chat.
4. Edita `config/discord-mc-chat.json`:
   - `generic.botToken` → token del bot
   - `generic.channelId` → ID del canal
5. Reinicia el server (`./start.sh`). Sin token/canal válidos, DMCC falla al arrancar.

Docs: https://blog.xujiayao.com/posts/4ba0a17a/

## Clientes

1. Minecraft **26.3** + Fabric Loader
2. Fabric API `0.162.0+26.3`
3. JourneyMap `26.3-6.0.10` (recomendado)
4. **TrashSlot** (opcional): Balm + TrashSlot en el cliente
5. **SecurityCraft Fabric** V0.6 (client + server; mismos jars que el server)
6. **TheLandClaim**: CoreLib + ClaimsMod en el cliente si hace falta UI/comandos (sigue la doc del mod)

## Notas

- EULA aceptado, `max-players=20`, whitelist off.
- RAM: 2–6 GB en `start.sh`.
- Reinicia el server (`stop` + `./start.sh`) tras añadir mods.
