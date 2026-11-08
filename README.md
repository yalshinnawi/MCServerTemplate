# ✈️ Create Aeronautics Skybound — Server Template

A high-performance Minecraft 1.21.1 NeoForge server template specifically configured for large modpacks (**Create Aeronautics Skybound**, 380+ mods, physics simulations, airships, and trains).

Runs **natively on bare-metal Java** with zero virtualization overhead for maximum TPS (ticks-per-second) and RAM efficiency.

---

## 🚀 Quick Start (One Command)

### On Windows:
Double-click **`start.bat`** (or run in CMD / PowerShell / Git Bash):
```cmd
start.bat
```

### On Linux / macOS / WSL:
Make executable and run:
```bash
chmod +x start.sh
./start.sh
```

> [!TIP]
> **What the startup script does automatically:**
> 1. Detects your installed Java runtime and verifies Java 21+ compatibility (or offers automated installation if missing).
> 2. Automatically accepts `eula.txt`.
> 3. Reads performance-tuned Generational ZGC flags from `user_jvm_args.txt`.
> 4. Boots the NeoForge server directly on bare-metal hardware.

---

## 🛠️ CLI Commands & Flags

| Command (Windows) | Command (Linux / macOS) | Description |
| :--- | :--- | :--- |
| `start.bat` | `./start.sh` | Normal start: verifies Java, boots server directly. |
| `start.bat -tunnel` | `./start.sh -tunnel` | Starts server **AND** launches the Playit.gg WAN tunnel for friends to join. |
| `start.bat backup` | `./start.sh backup` | Safely creates a timestamped archive of the `world/` folder into `./backups/`. |
| `start.bat help` | `./start.sh help` | Displays the help menu with configuration tips. |

---

## 🌐 Connecting Friends & Network Setup

### 1. External Friends (Across the Internet)
Start the server with the tunnel flag:
```cmd
start.bat -tunnel
```
Friends connect using your Playit domain and port:
```text
chords-infected.tun.ply.gg:1779
```

### 2. Same Local Wi-Fi (LAN)
If players are on the same local Wi-Fi, they connect using your host PC's local IP:
```text
192.168.4.76:25565
```
*(Make sure your Windows Network Profile is set to **Private** and Windows Firewall allows inbound TCP port `25565`)*.

---

## ⚙️ Memory & Performance Tuning

### RAM Allocation (`user_jvm_args.txt`)
Open [`user_jvm_args.txt`](file:///user_jvm_args.txt) to adjust RAM according to your hosting PC:
```text
-Xms4G
-Xmx8G
```
- **8 GB System RAM:** Use `-Xms3G -Xmx5G`
- **16 GB System RAM (Default):** Use `-Xms4G -Xmx8G`
- **32 GB+ System RAM:** Use `-Xms6G -Xmx12G`

### Generational ZGC
Java 21 Generational ZGC is pre-configured in `user_jvm_args.txt` (`-XX:+UseZGC -XX:+ZGenerational`). This virtually eliminates the 1-2 second garbage-collection freeze spikes common with 300+ modpacks.

---

## 🗺️ Recommended: Chunk Pre-Generation with Chunky

In heavy Create modpacks with high-speed airships and trains, dynamic chunk generation while players fly causes extreme CPU load and server stalls on dual-core processors.

**Pre-generate your world before opening the server to players:**

1. In the server console, run:
   ```text
   worldborder set 6000
   chunky radius 3000
   chunky start
   ```
2. Monitor progress:
   ```text
   chunky progress
   ```
3. Once Chunky reaches 100%, players can explore smoothly with minimal chunk-generation tick lag!

---

## 💻 Laptop Hosting Best Practices

If hosting from a Windows laptop:
1. **Power Plan**: Go to Windows Control Panel -> **Power Options** -> choose **High Performance** (or **Ultimate Performance**). Always keep the laptop plugged into **AC power**.
2. **Lid Close Action**: Set **When I close the lid (Plugged in)** to **Do nothing** so Windows won't put the server to sleep.

---

## 📖 In-Depth Guides

- [**Hosting & Configuration Guide**](file:///docs/HOSTING_GUIDE.md): Detailed walkthrough for migrating to a new PC, changing server properties, adding/removing mods, and console commands.
- [**Troubleshooting & Diagnostics**](file:///docs/TROUBLESHOOTING.md): Solutions for Connection Reset, getsockopt timeouts, carrier DNS issues, and `spark` TPS profiling.
