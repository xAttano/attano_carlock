# attanos_carlock

Advanced ESX vehicle locking, hotwiring, and key sharing system for FiveM.

`attanos_carlock` is a lightweight and optimized vehicle key system built for ESX servers using ox_lib, ox_target, and ox_inventory. Players can lock and unlock owned vehicles, hotwire NPC vehicles, lockpick cars, share keys with other players, and manage vehicle interactions through a modern NUI control menu.

Perfect for serious roleplay, economy, survival, gang, and immersion-focused FiveM servers.

Need support? Join my discord. https://discord.gg/6SCshsRxch

---

# Features

- Vehicle locking and unlocking system
- Vehicle key ownership system
- Temporary hotwire keys
- Vehicle lockpicking
- Vehicle hotwiring
- Key sharing between players
- ox_target support
- Modern NUI vehicle control menu
- Engine toggle support
- Door controls
- Window controls
- Seat switching
- Vehicle light controls
- Interior light toggle
- Vehicle horn and light feedback
- Optional sound effects
- Lockpick break chance system
- Skillcheck-based lockpicking and hotwiring
- Supports NPC vehicle locking
- Prevents driving without keys
- Prevents exiting locked vehicles
- Lightweight and optimized
- Fully configurable

---

# Dependencies

- ESX Framework
- ox_lib
- ox_target
- ox_inventory
- oxmysql

---

# Installation

## Using Git

```bash
cd resources
git clone https://github.com/xAttano/attanos_carlock
```

## Manual Installation

1. Download the resource
2. Place `attanos_carlock` into your resources folder

---

# Setup

Add this to your `server.cfg`:

```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure attanos_carlock
```

---

# Configuration

All settings can be configured inside:

```txt
config/config_carlock.lua
```

You can customize:

- Lockpick settings
- Hotwire settings
- Skillcheck difficulty
- Vehicle interaction radius
- Progress durations
- Vehicle sounds
- Vehicle lights
- Notification settings
- Vehicle lock behavior
- Key requirements
- NPC vehicle locking
- Keybinds
- ox_target integration
- Vehicle menu behavior

---

# Vehicle Menu Features

The built-in vehicle menu allows players to:

- Lock or unlock vehicles
- Toggle the engine
- Open and close doors
- Control windows
- Swap seats
- Manage headlights
- Toggle interior lights

Default keybind:

```txt
F7
```

---

# Commands

## Lock / Unlock Vehicle

```txt
/carlock
```

Default keybind:

```txt
L
```

## Give Vehicle Key

```txt
/givekey
```

---

# Hotwire System

Vehicles without keys can be hotwired using a configurable skillcheck system.

Features include:

- Configurable hotwire duration
- Temporary session-based keys
- Skillcheck difficulty settings
- Driver seat requirement
- Optional NPC vehicle support

---

# Lockpick System

Players can break into locked vehicles using lockpicks.

Features include:

- ox_inventory lockpick support
- Configurable lockpick item
- Break chance system
- Skillcheck difficulty
- Dispatch integration support
- NPC vehicle compatibility

---

# Built For

- Serious RP servers
- Economy servers
- Survival servers
- Gang servers
- Realistic vehicle systems
- Immersive gameplay
- Custom progression servers

---

# Additional Terms

You may use and modify this resource for your server.

You may not resell, redistribute, or reupload this resource without permission.

Credit to Attano Scripts is appreciated.

---

# Future Plans

- Vehicle key items
- Job vehicle permissions
- Vehicle ownership transfers
- Police lock bypass
- Advanced alarm systems
- Vehicle tracking integration
- Multi-character support improvements

---

# Keywords

FiveM car lock script, ESX vehicle keys, FiveM hotwire script, FiveM lockpick system, FiveM ESX scripts, ox_target vehicle script, FiveM vehicle menu, FiveM key system, ESX car keys, FiveM vehicle locking, FiveM RP vehicle system, ox_inventory vehicle keys, FiveM vehicle control menu, FiveM carlock script
