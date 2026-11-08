# ✈️ Create Aeronautics Skybound — Production Containerized Server

A high-performance, containerized Minecraft server infrastructure specifically architected for large modpacks (featuring **Create Aeronautics**, complex kinetics, and physics simulations) running on constrained laptop hardware (**Intel Core i7-6600U dual-core CPU, 16 GB system RAM, Windows 10/11 with Docker WSL2**).

---

## 🚀 One-Click Start (The Only Script You Need)

Everything—from dependency verification and `.wslconfig` tuning to launching the server, tailing logs, and managing backups—is handled by **one single script**:

### On Windows:
Just **double-click** `start.bat` in Windows File Explorer, or run in PowerShell / CMD:
```cmd
start.bat
```

### On Linux / macOS / WSL2:
Run in your terminal:
```bash
./start.sh
```

> [!TIP]
> **What running the script does automatically:**
> 1. Verifies that Docker is installed (and offers to install it via `winget` / package manager if missing).
> 2. Starts the Docker engine if stopped.
> 3. Configures `.wslconfig` (memory capped at 12 GB, 4 CPU, 4 GB swap) to protect your 16 GB laptop from pagefile thrashing.
> 4. Prepares `.env` and seeds `./data` volume with mod configurations.
> 5. Launches the server in Docker and attaches directly to live console logs!

---

## 🛠️ Single-Script Command Reference

You can pass simple arguments to `start.bat` (Windows) or `./start.sh` (Linux/macOS) for every server operation:

| Operation | Windows Command | Linux / macOS / WSL Command | Description |
| :--- | :--- | :--- | :--- |
| **Start & Stream Logs** | `start.bat` | `./start.sh` | Default action: checks deps, boots server, tails logs. |
| **Start + WAN Tunnel** | `start.bat -tunnel` | `./start.sh -tunnel` | Starts server + containerized Playit.gg tunnel. |
| **Stop Server** | `start.bat stop` | `./start.sh stop` | Gracefully shuts down all containers (`stop_grace_period: 60s`). |
| **Restart Server** | `start.bat restart` | `./start.sh restart` | Restarts all containers cleanly. |
| **View Live Logs** | `start.bat logs` | `./start.sh logs` | Tails server console output (`Ctrl+C` to detach). |
| **Interactive Console** | `start.bat rcon` | `./start.sh rcon` | Connects directly to in-game server RCON console. |
| **Run Console Command**| `start.bat rcon list` | `./start.sh rcon list` | Executes a single command and returns. |
| **Zero-Downtime Backup**| `start.bat backup` | `./start.sh backup` | Freezes writes, flushes chunks, creates compressed `.tar.gz`. |
| **Dependency Doctor** | `start.bat setup` | `./start.sh setup` | Manually checks/tunes Docker, WSL2, and `.wslconfig`. |

---

## 🔒 Automated Safe Backups (`start.bat backup`)

When you run `start.bat backup` (or `./start.sh backup`), the script:
1. Temporarily freezes chunk autosaving via RCON: `rcon-cli save-off`.
2. Flushes pending chunk and entity modifications to disk: `rcon-cli save-all flush`.
3. Pauses 2 seconds for complete I/O quiescence.
4. Creates a compressed, timestamped archive in `./backups/world_backup_<timestamp>.tar.gz`.
5. Safely re-enables autosave: `rcon-cli save-on`.

---

## ⚡ Host OS & WSL2 Tuning (Crucial for 16 GB Dual-Core Laptop)

1. **Power Plan**: Open Windows Control Panel -> **Power Options** -> select **High Performance** (or **Ultimate Performance**). Ensure the laptop is plugged into **AC power**.
2. **Lid Close Action**: Set **When I close the lid (Plugged in)** to **Do nothing** so Windows won't suspend the Docker VM.
3. **WSL2 Memory Cap (`.wslconfig`)**: Automatically managed by `start.bat`. If configuring manually, ensure `C:\Users\<User>\.wslconfig` contains:
   ```ini
   [wsl2]
   memory=12GB
   processors=4
   swap=4GB
   localhostForwarding=true
   ```

---

## 🗺️ Chunk Pre-Generation with Chunky (Mandatory Bootstrap)

In large Create modpacks with high-speed airships and trains, dynamic chunk generation while players fly causes extreme CPU load and server stalls on dual-core processors.

**Pre-generate all chunks before opening the server to players:**

1. Connect to the server console:
   ```cmd
   start.bat rcon
   ```
2. Execute the exact command sequence:
   ```text
   /worldborder set 6000
   /chunky radius 3000
   /chunky start
   ```
3. Monitor progress:
   ```text
   /chunky progress
   ```
4. Once pre-generation reaches 100%, players can explore freely with minimal chunk-generation tick lag!

---

## 🧩 Essential Server-Side Optimization Mods

To ensure smooth 20 TPS tick rates with Create Aeronautics on a dual-core host, verify that these server-side optimization mods are present in `./data/mods`:

| Mod Name | Function & Purpose |
| :--- | :--- |
| **ModernFix** | Drastically reduces RAM usage, eliminates memory leaks, optimizes dynamic registries, and accelerates world loading. |
| **FerriteCore** | Optimizes Minecraft memory usage by reducing memory footprint of blockstates, models, and neighbor tables. |
| **Canary / Radium** | Unofficial Forge/NeoForge port of Lithium. Highly optimizes general chunk, block entity, AI, and collision ticking physics. |
| **FastSuite** | Optimizes recipe lookups and crafting data structures, eliminating TPS drops when modded machines search for recipes. |
| **Krypton** | Optimizes Minecraft networking stack, Netty channel pipelines, and packet compression/batching for high latency links. |

---

## ⚙️ Architecture & JVM Tuning Highlights

- **Generational ZGC (`-XX:+UseZGC -XX:+ZGenerational`)**:
  Separates objects into young and old generations concurrently. Pauses are guaranteed sub-millisecond, preventing the periodic 3–8 second GC freezes common with standard G1GC on 9 GB+ modded heaps.
- **`MAX_TICK_TIME="-1"`**:
  Disables the Minecraft watchdog shutdown timer. Dual-core CPUs running Create physics calculations occasionally take >60 seconds during intensive contraption assemblies; setting `-1` prevents accidental server crashes.
- **`VIEW_DISTANCE="6"` & `SIMULATION_DISTANCE="4"`**:
  Balances immersive visibility with minimal tick overhead, keeping active ticking blocks tightly bounded.
- **`SYNC_CHUNK_WRITES="false"`**:
  Enables asynchronous chunk writing, removing disk I/O wait cycles from the main server tick thread.
