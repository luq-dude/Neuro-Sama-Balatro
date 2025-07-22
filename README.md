# Balatro Integration Mod

WIP mod to let Neuro-Sama play Balatro. Based off of [lua-neuro-game-API](https://github.com/Gunoshozo/lua-neuro-sama-game-api),
modified to work with [love-2d-websocket](https://github.com/flaribbit/love2d-lua-websocket). 

## Installation

Install [Steamodded](https://github.com/Steamodded/smods) and either clone this repo into the mod folder (default location on
Windows is: %appdata%\Balatro\Mods) or download the repo as a .zip and extract it there.
This was tested with SMODS version [1.0.0-beta-0711a](https://github.com/Steamodded/smods/releases/tag/1.0.0-beta-0711a),
if you run into any issues on a later version try downgrading. 

Edit `config.lua` to contain the websocket URL for Neuro. Default is `ws://localhost:8080`. 

