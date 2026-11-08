# Troubleshooting & Common Issues Guide

A troubleshooting reference for errors, network failures, and performance issues on the **Create Aeronautics Skybound** server.

---

## 🛠️ Quick Diagnostics Checklist
Before debugging, check:
1. Is the server finished loading? Look for: `Done (xx.xxxs)! For help, type "help"` in the console.
2. Is `playit.exe` running in its own window?
3. Did the player include the port (e.g. `:1779`) when connecting via Playit?
4. Are both client and server running the exact same NeoForge 1.21.1 modpack?

---

## 🔴 Network & Connection Errors

### 1. `Internal Exception: java.net.SocketException: Connection reset`
* **Cause:** The player typed the raw IP address (`147.185.x.x:port`) instead of the domain name. Playit’s shared proxy enforces a `NoRawIp` security policy and forcibly drops the connection.
* **Fix:** Connect using the assigned domain name and port:
  ```text
  chords-infected.tun.ply.gg:1779
  ```

---

### 2. `Connection timed out: getsockopt` (LAN / Local Wi-Fi)
* **Cause:** The host computer's Wi-Fi network profile is set to **Public**, causing Windows Defender Firewall to block incoming connections from other devices on the same Wi-Fi.
* **Fix:**
  1. On the host PC: Open **Settings** → **Network & Internet** → **Wi-Fi** → Click your network → Change to **Private network**.
  2. Ensure port 25565 is allowed in Windows Firewall (run as Administrator in PowerShell):
     ```powershell
     netsh advfirewall firewall add rule name="Minecraft 25565" dir=in action=allow protocol=TCP localport=25565
     ```

---

### 3. "Connecting to the server..." for ~1 minute followed by `Timed out`
* **Scenario A: Connecting to Playit from inside the same home Wi-Fi.**
  * **Cause:** Most home routers do not support **NAT Loopback (Hairpinning)**. Traffic leaving your router and attempting to loop back to your own server gets dropped.
  * **Fix:** 
    * If on the host PC: Connect to `localhost`.
    * If on another PC on the same Wi-Fi: Connect to the host's local IP (e.g., `192.168.4.76`).
* **Scenario B: Connecting from a Mobile Hotspot (Cellular).**
  * **Cause:** Cellular carriers (T-Mobile, AT&T, Verizon) often use restrictive cellular DNS or filter custom ports over IPv6.
  * **Fix:**
    * Change DNS on the laptop to Cloudflare (`1.1.1.1`) or Google (`8.8.8.8`).
    * Force Java to use IPv4 by adding `-Djava.net.preferIPv4Stack=true` to your launcher's JVM arguments.

---

### 4. `Incompatible mod set` or `Failed to synchronize registry data`
* **Cause:** The player's Minecraft client has different mod versions or is missing mods that the server requires.
* **Fix:** Ensure all players install the exact same modpack release. If you manually added or updated mods in the server's `mods/` folder, copy those exact `.jar` files to the clients' `mods/` folders.

---

## 💥 Startup & Crash Issues

### 5. `Attempted to load class net/minecraft/client/Minecraft for invalid dist DEDICATED_SERVER`
* **Cause:** A **client-only mod** was placed into the server's `mods/` directory.
* **Fix:**
  * Check the crash log in `crash-reports/` or `logs/latest.log` to identify which mod crashed.
  * Common client-only mods: Sodium, Iris, Oculus, FancyMenu, BetterThirdPerson, Presence Footsteps, AmbientSounds, Zoom mods.
  * Delete the client-only mod from the server's `mods/` directory.

---

### 6. `OutOfMemoryError: Java heap space`
* **Cause:** The server ran out of allocated RAM while generating terrain or managing complex Create / Aeronautics machines.
* **Fix:**
  1. Open `user_jvm_args.txt`.
  2. Increase the maximum memory allocation:
     ```text
     -Xmx8G -Xms4G
     ```
  3. Ensure your physical machine has enough free RAM before starting.

---

### 7. `FAILED TO BIND TO PORT! Address already in use: bind`
* **Cause:** Another instance of Java is already running in the background and holding port `25565`.
* **Fix:**
  1. Open PowerShell and find the running Java process:
     ```powershell
     Get-Process java, javaw
     ```
  2. Terminate the hung process:
     ```powershell
     Stop-Process -Name java -Force
     ```
  3. Rerun `start.bat`.

---

## ⚡ Performance & Tick Lag

### Diagnosing Lag with `spark`
The server comes with the **spark** performance profiler mod installed:
* Check real-time TPS and tick duration:
  ```text
  spark tps
  ```
* Run a 60-second performance profiler:
  ```text
  spark sampler --timeout 60
  ```
  This outputs a web link showing exact CPU hotspots (e.g. high entity counts, runaway Create contraptions, or chunk loading).

### Quick Performance Optimizations
1. In `server.properties`, reduce `simulation-distance=6` and `view-distance=8`.
2. Check `config/servercore.toml` to tweak dynamic performance optimizations.
3. Clean up loose entities or runaway physics contraptions using in-game admin tools.

