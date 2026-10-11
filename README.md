# Servidor Minecraft Fabric 26.3

Servidor dedicado Fabric para hasta **20 jugadores**, expuesto con **playit.gg** (sin port forward; tu red está en CGNAT).

## Stack

| Componente | Versión |
|---|---|
| Minecraft | 26.3 |
| Fabric Loader | 0.19.5 |
| Fabric API | 0.162.0+26.3 |
| JourneyMap | 26.3-6.0.10 |
| Java | 25 (Temurin) |
| playit | 1.0.10 (compilado para macOS) |

## Arrancar

```bash
./start.sh
```

Esto inicia `playitd` (si ya está claimed) y el servidor Fabric.

Solo el túnel:

```bash
./start-playit.sh
./stop-playit.sh
```

## Setup playit (una vez)

1. Abre el enlace de claim (te lo da el agente) e inicia sesión en playit.gg.
2. En el dashboard, crea un túnel **Minecraft Java** → local `127.0.0.1:25565`.
3. Comparte a tus amigos la dirección que playit muestra (algo como `xxx.playit.gg:12345`).

Si necesitas reclamar de nuevo:

```bash
./bin/playitd --socket-path=./playit.sock --secret-path=./playit.toml -l ./logs/playitd.log &
CODE=$(./bin/playit claim generate)
open "$(./bin/playit claim url --name mcserver --type self-managed "$CODE")"
./bin/playit --socket-path=./playit.sock claim exchange "$CODE"
```

## Dominio Cloudflare (`mc.r0r71z.dev`)

El script `update-dns.sh` sigue pudiendo actualizar un registro A, pero **con CGNAT no sirve para jugar**. Usa la dirección de playit para conectar.

Si más adelante tienes IP pública real, puedes volver al port forward + `mc.r0r71z.dev`.

## Clientes

1. Minecraft **26.3**
2. Fabric Loader
3. Fabric API `0.162.0+26.3`
4. JourneyMap `26.3-6.0.10` (recomendado)

## Notas

- EULA aceptado, `max-players=20`, whitelist off.
- RAM: 2–6 GB en `start.sh`.
