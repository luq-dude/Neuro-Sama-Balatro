# Balatro Integration Mod

A Mod to let Neuro-sama play Balatro. Based off of [lua-neuro-game-API](https://github.com/Gunoshozo/lua-neuro-sama-game-api),
modified to work with [love-2d-websocket](https://github.com/flaribbit/love2d-lua-websocket).

On game boot, the game will prompt Neuro to start a new run, so continuing a run
is not supported. This mod will handle all menus automatically. Trying to
control the game manually may result in a crash. A configurable option exists to
automatically restart the game in the event of a crash. If Neuro disconnects,
the game will probably fail to automatically reconnect and will require a manual
restart.

The mod is compatible with custom art mods, and probably works with most mods
that add custom content like jokers. However, context may be missing for some
custom effects.

Report any bugs in the thread on the Neuro-sama Discord.

## Installation

Install [Steamodded](https://github.com/Steamodded/smods) and either clone this
repo into the mod folder (default location on Windows is: %appdata%\Balatro\Mods)
or download the repo as a .zip and extract it there. Cloning is preferred to
make updating easier. This was tested and developed with SMODS version
[1.0.0-beta-0711a](https://github.com/Steamodded/smods/releases/tag/1.0.0-beta-0711a),
if you run into any issues on a later version try downgrading.

## Configuration

The file `config.lua` contains all the default config values as well as a
description of each one. While you can modify this file directly, it is
recommended that you instead create a new file `_config.lua` (name must be exact)
to prevent issues with git when updating. When loading a configuration value,
`_config.lua` will be checked first and `config.lua` will be used as a fallback
if the key is not found. You can make `_config.lua` a copy of `config.lua`, or
only specify the keys you want to change from their defaults. For example:

```lua
return {
    ["NEURO_SDK_WS_URL"] = "ws://some.other.url:8000"
    ["CAN_RESTART_ON_CRASH"] = false
}
```

will only override those two config values while keeping everything else set to
the default specified in `config.lua`.
