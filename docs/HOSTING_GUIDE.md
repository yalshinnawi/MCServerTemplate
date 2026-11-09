# Server Hosting & Administration Guide

A complete guide to configuring, managing, updating, and hosting the **Create Aeronautics Skybound** server.

---

## 📑 Table of Contents
1. [Hosting on a New / Different PC](#1-hosting-on-a-new--different-pc)
2. [Configuring Server Settings](#2-configuring-server-settings)
3. [Memory & JVM Allocation](#3-memory--jvm-allocation)
4. [How to Connect & Have Friends Join](#4-how-to-connect--have-friends-join)
5. [Changing or Updating the Modpack](#5-changing-or-updating-the-modpack)
6. [Server Administration & Console Commands](#6-server-administration--console-commands)

---

## 1. Hosting on a New / Different PC

When moving or hosting this server on another computer:

### Step 1: System Prerequisites
* **Java 21:** Minecraft 1.21.1 and NeoForge require **OpenJDK 21** (e.g. [Eclipse Temurin 21](https://adoptium.net/temurin/releases/?version=21)).
* **RAM:** Minimum 4 GB allocated to Java (6 GB to 8 GB recommended for Create + Aeronautics with multiple dimensions).
* **64-bit OS:** Windows 10/11 or modern Linux.

### Step 2: Clone or Copy the Repository
```bash
git clone <your-repository-url>
cd CreateAeroNauticsServer
```

### Step 3: Run the Server
* **Windows:** Double-click `start.bat`.
  * The script contains a built-in auto-detection check: if `java-runtime` is not present, it will automatically look for system Java 21 or download an OpenJDK 21 instance automatically.
* **Linux:** Make the script executable and run:
  ```bash
  chmod +x start.sh run.sh
  ./start.sh
  ```

### Step 4: Transferring Your Existing World (Optional)
If you have an existing world save from your previous host:
1. Copy the `world/` directory from the old PC to the server folder on the new PC.
2. Ensure the server is shut down before replacing the `world/` directory.

---

## 2. Configuring Server Settings

Core game rules and server properties are controlled in `server.properties`:

| Setting | Default | Description |
| :--- | :--- | :--- |
| `motd` | `Create Aeronautics Skybound Server` | Server description shown in the multiplayer server list. |
| `server-port` | `25565` | Default internal game port. Keep as `25565` for Playit. |
| `max-players` | `10` | Maximum simultaneous players allowed. |
| `difficulty` | `normal` | `peaceful`, `easy`, `normal`, or `hard`. |
| `online-mode` | `true` | Verifies accounts against Mojang session servers. Leave `true` to block username spoofing. |
| `white-list` | `false` | When `true`, only players added via `/whitelist add <name>` can join. |
| `simulation-distance` | `8` | Chunk radius around players where ticks/mechanics run. Lower (e.g. `6`) for better performance. |
| `view-distance` | `10` | Chunk render radius sent to players. |
| `allow-flight` | `false` | Set to `true` if flying ships or modded jetpacks trigger false fly-kick detections. |

---

## 3. Memory & JVM Allocation

### Adjusting RAM
To change how much RAM the server can use:
1. Open **`user_jvm_args.txt`**.
2. Find the line:
   ```text
   -Xmx6G -Xms4G
   ```
   * `-Xmx`: Maximum RAM limit (e.g., `-Xmx8G` for 8 Gigabytes).
   * `-Xms`: Initial RAM allocation (e.g., `-Xms4G` for 4 Gigabytes).
3. Save the file and restart the server.

### C. Friends Over the Internet via TCPShield (DDoS Protected & IP Masked)
1. Run `start.bat`.
2. Give friends your protected domain:
   ```text
   <your-domain>.duckdns.org
   ```
   *(All traffic routes through TCPShield's Anycast network, protecting your home IP).*

### D. Direct Port Forwarding (Alternative)
Friends connect directly using your public IP:
```text
<your-public-ip>:25565
```

---

## 5. Changing or Updating the Modpack

### Adding or Removing Mods
1. Download NeoForge 1.21.1 compatible `.jar` files into the `mods/` directory.
2. **Server vs. Client Mods:**
   * Only install mods that support dedicated servers.
   * **Do not** install client-only mods (e.g., Sodium, Iris, Oculus, FancyMenu, Presence Footsteps, AmbientSounds) on the server. They will cause the server to crash during launch with `Attempted to load class net/minecraft/client/Minecraft for invalid dist DEDICATED_SERVER`.
3. If you add or remove mods on the server, ensure all connecting players install the exact matching mod versions on their client launcher.

### Mod Configurations
* Global mod configs: Located in `config/`.
* World-specific server configs: Located in `defaultconfigs/` (for new worlds) or `world/serverconfig/` (for the active world).

---

## 6. Server Administration & Console Commands

Type these commands directly into the server terminal (without the leading `/`):

| Command | Purpose |
| :--- | :--- |
| `op <username>` | Grants full admin permissions to a player. |
| `deop <username>` | Revokes admin permissions. |
| `whitelist on` | Enables the server whitelist. |
| `whitelist add <username>` | Adds a player to the whitelist. |
| `whitelist remove <username>` | Removes a player from the whitelist. |
| `kick <username> [reason]` | Kicks a player from the server. |
| `ban <username> [reason]` | Permanently bans a player. |
| `save-all` | Forces the server to immediately write all world data to disk. |
| `stop` | Gracefully saves all chunks, disconnects players, and shuts down the server. Always use `stop` rather than closing the window. |

