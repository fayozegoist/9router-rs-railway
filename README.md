# 9Router Rust — Self-Hosted AI Gateway on Railway

Deploy [9Router Rust](https://github.com/CoolLoong/9router-rs), the native Rust port of 9Router, on Railway. One endpoint for Claude Code, Codex, Cursor, Cline, OpenCode and any OpenAI-compatible client, with 3-tier fallback, multi-account routing, quota tracking and RTK token compression.

This template is the Rust-engine counterpart of [fayozegoist/9router-railway](https://github.com/fayozegoist/9router-railway) (which ships the Node `decolua/9router` image).

## Deploy on Railway

1. Create a new service from this repo (Railway → **Deploy from GitHub repo**, or **Template → Deploy**).
2. Add a **volume** mounted at `/app/data`. Without it, every redeploy wipes your providers, keys and usage history.
3. Set `INITIAL_PASSWORD` to a strong value (see security note below). `JWT_SECRET` is optional but recommended.
4. Wait for the healthcheck on `/api/health` to pass, then open your Railway domain.
5. Log in with `INITIAL_PASSWORD`, then immediately set a real password in the dashboard account settings.
6. Add provider accounts under **Providers**, create a gateway key under **Endpoint & Key**.
7. Point your client at `https://<your-domain>/v1` with that key.

## Features

- **Unified endpoint** — one base URL and one key for every provider and CLI tool.
- **3-tier fallback** — subscription → cheap → free, automatic on quota exhaustion or error.
- **Multi-account** — several accounts per provider, round-robin or priority routing.
- **RTK token saver** — lossless compression of `git diff`, `grep`, `ls`, `tree`, log dumps before they hit the LLM; 20–40% input tokens saved.
- **Headroom** (optional) — external `/v1/compress` proxy, fails open if unreachable.
- **Caveman / Ponytail** — output-token savers (terse replies, YAGNI-first code).
- **Format translation** — OpenAI ↔ Claude ↔ Gemini ↔ Cursor ↔ Kiro ↔ Vertex ↔ Ollama ↔ OpenAI Responses.
- **Quota tracking + usage analytics** — live token counts, reset countdowns, cost estimates (display only; 9Router never bills you).
- **Rust engine** — single static-ish binary, lower memory and higher throughput than the Node build (upstream benchmark: 1,000 requests/round, concurrency 8).

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `20128` | Listen port. Railway injects this; the binary reads it. |
| `DATA_DIR` | `/app/data` | SQLite DB, settings, keys. Must be the volume mount. |
| `INITIAL_PASSWORD` | *(unset)* | Bootstrap dashboard password. **Set this.** |
| `JWT_SECRET` | *(random)* | Session signing secret. Set it so sessions survive redeploys. |
| `AUTH_COOKIE_SECURE` | `true` | `Secure` cookie flag. Keep `true` behind Railway's HTTPS edge. |
| `ENABLE_REQUEST_LOGS` | `false` | Full request/response logging. Noisy, use for debugging. |
| `HEADROOM_URL` | `http://localhost:8787` | Only if you run a Headroom sidecar. |

## Notes

- **Security-critical default:** if `INITIAL_PASSWORD` is unset, 9Router falls back to the hardcoded password `123456` and refuses remote dashboard login until it is changed. Always set `INITIAL_PASSWORD` on Railway.
- **Single replica only.** State lives in SQLite on the volume; scaling horizontally will corrupt or split it. Keep `numReplicas = 1`.
- **Build from source.** Upstream publishes no container image, so this template compiles `CoolLoong/9router-rs` at a pinned commit (`NINEROUTER_REF` in the `Dockerfile`). First build takes ~10–20 min; later builds reuse the layer cache. Bump the ref to upgrade.
- **Volume ownership.** Railway mounts volumes as root; the entrypoint chowns `DATA_DIR` to uid 1000 and drops privileges via `gosu`. The gateway never runs as root.
- **ffmpeg is included** for the media/audio features. Drop it from the `Dockerfile` if you don't need them.
- **Headroom is not provisioned.** It is optional upstream; add it as a second service and set `HEADROOM_URL` if you want it.
- **Port** is `20128` internally; Railway exposes it over HTTPS automatically.

## Self-hosting elsewhere

```bash
git clone https://github.com/CoolLoong/9router-rs.git
cd 9router-rs
npm --prefix dashboard ci && npm --prefix dashboard run build
cargo build --release --locked
DATA_DIR="$HOME/.9router" ./target/release/ninerouter --host 0.0.0.0 --port 20128 --no-browser
```

Docker:

```bash
docker build -t 9router-rs .
docker run -d -p 20128:20128 \
  -v "$HOME/.9router:/app/data" \
  -e INITIAL_PASSWORD=change-me \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  --name 9router-rs 9router-rs
```

## License

Template: MIT. Upstream 9Router Rust: MIT — https://github.com/CoolLoong/9router-rs
