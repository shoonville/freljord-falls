# Freljord Falls

A 3D last-one-afloat party brawler. Ride your boar across a cracking iceberg, dash rivals
into the brittle rim, grab UFO-dropped power-ups, and be the last cub on the floe.

Built as a single `index.html` using [Three.js](https://threejs.org) (r128) with
champion/boar models loaded from local `.glb` files. Online play uses
[PeerJS](https://peerjs.com) (WebRTC peer-to-peer, host-authoritative).

## Controls
- **Move:** WASD or Arrow keys
- **Dash:** Space (costs half your stamina bar; regenerates over time)
- **Use held item:** Shift (Hourglass = brief golden stasis; Tornado = fire it forward)

## Power-ups (dropped by the UFO)
- ⚡ **Live bolt** — hot potato; whoever holds it at 0 gets zapped. Pass it by ramming rivals.
- ⏳ **Hourglass** — Shift for ~2s of invulnerable golden stasis (also blocks the anvil).
- 🌪️ **Tornado** — Shift to fire a tornado that knocks rivals into the air.
- ⚒️ **Anvil** — hot potato; at 0 a giant anvil crushes whoever holds it (eliminated).

## Play modes
- **Local Play** — pick champions / Human-or-CPU for up to 4 slots and play on one machine.
- **Host Online / Join Online** — one player hosts (gets a room code), others join by code.
  The host runs the simulation and streams the match to everyone (~20 snapshots/sec).

## Run locally
Any static file server works (the page just needs to be served over http, not opened as a
`file://` URL). On Windows you can use the included script:

```powershell
./serve.ps1
```

Then open the printed `http://localhost:...` address. For online play across machines,
deploy it (below) so both players can open the same HTTPS URL.

## Deploy to GitHub Pages (for internet multiplayer)
WebRTC needs an HTTPS origin, which GitHub Pages provides for free.

1. Create a new repository on https://github.com/new (e.g. `freljord-falls`), public.
2. From this folder, point it at your repo and push:
   ```bash
   git remote add origin https://github.com/<your-username>/freljord-falls.git
   git branch -M main
   git push -u origin main
   ```
3. On GitHub: **Settings → Pages → Build and deployment → Source: Deploy from a branch**,
   select branch **main** / folder **/ (root)**, then **Save**.
4. Wait ~1 minute; your game is live at
   `https://<your-username>.github.io/freljord-falls/`.
5. Share that URL. To play online: both open it, one clicks **HOST ONLINE** and shares the
   room code, the other clicks **JOIN ONLINE** and enters it, then the host starts the match.

> Note: WebRTC P2P connects directly between players. On most home networks this just works;
> a small number of strict/corporate networks may need a TURN relay (can be added later).

## Files
- `index.html` — the entire game (HTML/CSS/JS).
- `*.glb` — boar + champion + pilot 3D models (required; keep them next to `index.html`).
- `serve.ps1` — tiny local static server for development.
