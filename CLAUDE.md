# Parodio — Electron + React + TypeScript desktop app

## What this is

A desktop app (macOS + Windows) for **dubbing video clips with your own voice** — the user loads their
own video file, it plays with the original audio muted, and they speak over it into a microphone.
The output is a new video with the original picture and the recorded audio track.
Inspired by *The Choicer Voicer* (itch.io). Target audience is Czech, but the concept is universal.
Domain: parodio.cz.

## ⚠️ Legal framework — binding on architecture

**This is the core of the project. Never work around it, never propose a feature that violates it.**

1. The app and the repository **must not contain or distribute any copyrighted content**.
   No film/TV clips in the repo, no downloads from any central source operated by this project.
2. The repo contains **the tool only** (player/recorder), plus optionally original or freely
   licensed sample content (Creative Commons, public domain).
3. **Users load their own files** (drag & drop). Same legal model as VLC, OBS, RetroArch:
   the tool is legal, the content is the user's responsibility.
4. Any clip sharing between users happens **outside the app and outside the author's infrastructure**
   (e.g. privately over Discord) — never as a feature inside the app.
5. The real risk is not a studio lawsuit but a **DMCA takedown / GitHub repo removal**.
   We avoid it by never hosting or distributing content from the app itself.

**🚩 Red flag:** whenever a proposal comes up for "download/share clips", a "clip library",
a "content browser" or anything similar — **stop, say so explicitly, and redirect** back to the
"user loads their own file" model. Do not implement it, even if Martin asks for it in passing.

## MVP scope (approved — do not expand without asking)

Core only. **No multiplayer, no scoring/rating, no moddable content packs.**

1. Drag & drop of the user's own video file
2. Play the clip with the original audio muted
3. Record the microphone simultaneously during playback
4. Export the video (original picture + new audio track)

Video/audio via standard web APIs: `<video>`, Web Audio API, `MediaRecorder`.

**No server, no hosting, no telemetry.** This is also a marketing advantage ("an app that doesn't spy").
Monetization: voluntary donations (Buy Me a Coffee or similar), **not** a paid license, **not** DRM —
a client-side Electron app can't be protected anyway, and it isn't worth it at this scale.
Do not propose a licensing system, activation keys, or an ad network.

## Stack

electron-vite (main / preload / renderer), React + TypeScript, electron-builder (packaging), pnpm.
Electron 39.x, Node 22, pnpm 11, macOS arm64 (development).

Tauri was considered and rejected for the MVP (extra Rust layer).
Cross-platform release builds later via GitHub Actions (macOS + Windows runners).

## Build / run / test

- Dev: `pnpm dev`
- Dev with renderer inspection: `pnpm dev:debug` (adds `--remote-debugging-port=9222`)
- Type-check: `pnpm typecheck`
- Lint: `pnpm lint`
- Format: `pnpm format`
- Compile: `pnpm build` (typecheck + electron-vite build → `out/`)
- Package installers: `pnpm build:mac` / `build:win` / `build:linux`
- Unit tests: `pnpm test`
- E2E tests: `pnpm test:e2e` (requires `pnpm build` first)

## ⚠️ Non-negotiable Electron security rules

- `contextIsolation: true`, `sandbox: true`, `nodeIntegration: false` on EVERY BrowserWindow,
  always written out explicitly. Never weaken any of them "for convenience" — disabling any one
  turns a renderer XSS into full RCE.
- The renderer talks to the main process ONLY through the preload and `contextBridge.exposeInMainWorld`.
  Expose one narrow, named method per operation — NEVER `ipcRenderer` or `require`.
- Validate/whitelist every IPC channel name and every argument in the main-process handler.
  Treat all IPC input as untrusted, like an HTTP request from a client.
- Use `ipcRenderer.invoke` / `ipcMain.handle` for request/response; validate types before use.
- Never load remote or untrusted URLs into a window with Node access. This project doubly so —
  the app should have no network communication at all.
- Never disable `webSecurity`.
- Keep Electron patched (contextBridge bypass CVEs recur, e.g. CVE-2026-70601).

### Known traps (already solved once — do not repeat)

- **`sandbox: true` + preload:** a sandboxed preload cannot resolve bare npm modules.
  electron-vite externalizes them by default, which ends in `module not found: @electron-toolkit/preload`
  and a blank window. Fixed in `electron.vite.config.ts` (`externalizeDeps: false` for preload).
  **Never fix this by reverting to `sandbox: false`.**
- **CSP:** in dev it includes `style-src 'unsafe-inline'` because Vite injects inline styles.
  The production CSP must not have it — handle this at packaging time.
- **A preload failure must not take down the whole UI.** `Versions.tsx` uses optional chaining;
  keep that pattern anywhere that touches `window.electron` / `window.api`.

## Structure

- `src/main/` — main process (windows, IPC handlers, file access, video export)
- `src/preload/` — contextBridge API surface only
- `src/renderer/` — React app (no Node APIs)
- `src/shared/` — shared TS types (especially IPC contracts)

## Inspecting the running renderer

The app runs via `pnpm dev:debug` with CDP on port 9222.
**It must be started before the Claude Code session.**

For snapshots, screenshots, clicking, or reading the console in the renderer, **ALWAYS use the
playwright MCP** (`browser_snapshot`, `browser_take_screenshot`, `browser_click`, `browser_evaluate`).
Do not write ad-hoc CDP scripts over Node WebSocket and do not probe the port with curl —
the MCP server is connected and handles Playwright itself; it does not need to be in `node_modules`.
Do not reach for the `claude-in-chrome` skill; it cannot see an Electron renderer.

Note: `console.log` from the main process (e.g. `pong` on the IPC ping) goes to the stdout of the
`pnpm dev:debug` terminal, not to the renderer console. Don't look for it via MCP.

## Language

- All code, comments, commit messages, and documentation in **English**.
- **Czech only for user-facing UI strings** (the target audience is Czech).
  Keep them in a resource/i18n layer, not hardcoded in components.

## Conventions

- TypeScript strict. No `any` without a justifying comment.
- Prettier + ESLint are enforced by hooks; match the existing style.
- Smallest correct change (YAGNI). **Do not add dependencies without asking.**
- Add or adjust a test when behavior changes — once tests are installed.
- Files in `src/preload/` and `src/main/index.ts` are blocked by `.claude/hooks/guard.sh`.
  That is intentional. Do not route around it via `Bash`/`sed` — describe the change and leave it to Martin.

## Role

Martin can program and is building this app through Claude Code. Write code, but for architectural
decisions (structure, state management, video export format) propose options first and get sign-off.