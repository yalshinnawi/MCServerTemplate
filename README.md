# Create Aeronautics Skybound Server Template

A dedicated Minecraft server template for **Create Aeronautics Skybound**, running on **NeoForge 1.21.1**.

---

## 📖 Documentation & Guides

* **[Server Hosting & Administration Guide](docs/HOSTING_GUIDE.md):** Detailed guide on hosting on a new PC, changing server settings, adjusting RAM, modifying the modpack, console commands, and player connection options.
* **[Troubleshooting & Common Issues](docs/TROUBLESHOOTING.md):** Solutions for connection resets, timeouts, missing ports, LAN/firewall blocks, mod mismatches, and lag diagnosis with `spark`.

---

## 🚀 Quick Start

### Windows
1. Double-click **`start.bat`**.
2. It will automatically:
   * Start the **Playit.gg tunnel** in the background (if `playit.exe` is present and not already active).
   * Automatically detect or download a compatible Java 21 runtime.
   * Launch the Minecraft server.

### Linux / macOS
1. Open terminal in this folder and make the script executable:
   ```bash
   chmod +x start.sh run.sh
   ```
2. Start the server:
   ```bash
   ./start.sh
   ```

---

## 🎮 How to Connect

* **Host Machine:** In Minecraft Multiplayer, connect using:
  ```text
  localhost
  ```
* **Players on the Same Local Wi-Fi (LAN):** Connect using the host's local IP:
  ```text
  192.168.x.x
  ```
  *(Host must set Wi-Fi to Private and allow port 25565 in Windows Firewall; see [Hosting Guide](docs/HOSTING_GUIDE.md)).*
* **Remote Friends (Over the Internet):** Connect using your active Playit tunnel address:
  ```text
  <your-playit-domain>:<port>
  ```
  *(Example: `chords-infected.tun.ply.gg:1779`)*

> [!NOTE]
> All players must have the matching **Create Aeronautics** modpack installed on **NeoForge 1.21.1**.

---

## ⚙️ Configuration & Tweaks

* **RAM Allocation:** Open `user_jvm_args.txt` or `variables.txt` and edit `-Xmx6G -Xms4G` to match your system memory.
* **Server Settings:** Edit `server.properties` to configure MOTD, max players, whitelist, etc.
* **Playit Tunnel:** To claim or manage your Playit tunnel, open `playit.exe` in a terminal or visit [playit.gg](https://playit.gg).

---

## 📁 Repository Structure

```text
├── config/             # Mod configuration files
├── defaultconfigs/     # Default world configs
├── docs/               # Detailed hosting and troubleshooting guides
│   ├── HOSTING_GUIDE.md
│   └── TROUBLESHOOTING.md
├── kubejs/             # Custom KubeJS scripts & recipes
├── mods/               # Dedicated server mod jars
├── server.properties   # Minecraft server settings
├── user_jvm_args.txt   # Memory & JVM launch arguments
├── variables.txt       # ServerPackCreator configuration
├── start.bat           # One-click Windows launcher (Playit + Server + Auto-Java)
├── start.sh            # One-click Linux launcher
└── .gitignore          # Excludes logs, world saves, and heavy runtimes
```
