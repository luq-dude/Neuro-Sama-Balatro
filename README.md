# Balatro Integration Mod

A Mod to let Neuro-sama play Balatro. Based off of [lua-neuro-game-API](https://github.com/Gunoshozo/lua-neuro-sama-game-api),
modified to work with [love-2d-websocket](https://github.com/flaribbit/love2d-lua-websocket). 


On game boot, the game will prompt Neuro to start a new run, so continuing a run is not supported.
This mod will handle all menus automatically. Trying to control the game manually may result in a crash. 
A configurable option exists to automatically restart the game in the event of a crash. If Neuro disconnects, the game will probably 
fail to automatically reconnect and will require a manual restart.

The mod is compatible with custom art mods, and probably works with most mods that add custom content like jokers. 
However, context may be missing for some custom effects.

Report any bugs in the thread on the Neuro-sama Discord.   

## Installation

Install [Steamodded](https://github.com/Steamodded/smods) and either clone this repo into the mod folder (default location on
Windows is: %appdata%\Balatro\Mods) or download the repo as a .zip and extract it there. Cloning is preferred to make updating easier.
This was tested and developed with SMODS version [1.0.0-beta-0711a](https://github.com/Steamodded/smods/releases/tag/1.0.0-beta-0711a),
if you run into any issues on a later version try downgrading. 

Edit `config.lua` to set the websocket URL for Neuro. Default is `ws://localhost:8000`.

