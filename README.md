# ttt_hitboxcfg
A simple tool to edit the hitgroups of models in TTT.

### Introduction
Often times model makers don't properly setup the hitgroups of their models. For competitve gamemodes like TTT, this can be frusterating as such models are often times unable to be headshotted. The proper way to fix this would be to decompile the model using source SDK tools and adjust the QC file, however this is time consuming and can result in more complicated models breaking. Additionally, you will often need to rename and reupload (either to the WS or fastdl) the resulting model, which some modelers are annoyed by (which is, of course, totally justified). This tool aims to reduce the amount of time needed to add working and fair custom player models to your TTT servers.

### Limitations
Due to limitations in what GMOD allows you to do with Hitboxes, this addon is not capable of

1) Adding hitboxes that weren't there before.
2) Removing hitboxes. This can result in some models being unfixable without recompiling if the modeler added a hitbox that encases the entire model which the game will think was hit before any headshot box. Such as:

![image](https://raw.githubusercontent.com/Xytime/hitboxcfg/master/img/img1.png)

An example of a model that should work fairly well with hitboxcfg is (though do note that editing any hitbox encased entirely by the body box will not be effective):

![image](https://raw.githubusercontent.com/Xytime/hitboxcfg/master/img/img2.png)

Though this model is probably too small for TTT.

3) HitBoxCfg can only change hitgroups for models using hitgroup set id 0.
4) If you change the model of the player you are editing, you must hbc_unsel / hbc_commit and re-sel the player in order to continue working. (Not a GMOD limitation, this one is just me being lazy)

### Commands
All commands are restricted to super admins. The following client commands are available:

|Command|Argument|Description|
|-------|--------|-----------|
|hbc_selply|Integer|Select a player using their player index (`status`) to edit the model of. Often times this will be a bot that has been made to wear the model in question|
|hbc_listgrp|No argument|List all hit boxes of the currently selected player along side the native (model built in) and overriden hitgroup assignments|
|hbc_setgrp|Three Integers|Set the hit box of the selected model identified by the first integer / second integer to the pseudo-hitgroup identified by the third. Set to zero to clear the override.|
|hbc_clear|No arguments.|Clear all hit box overrides for the selected model.|
|hbc_commit|No arguments.|Send the changes to the server and instruct the server to write the changes out to disk. Unselects the current model.|
|hbc_unsel|No arguments.|Unselects the current player. Any changes made since loading the player are lost.|

### Pseudo-hitgroups
TTT doesn't actually do that many things with hit groups. TTT will apply a head shot based on the headshot multiplier of the weapon in question or a damage reduction if it hits an arm or a player's gear. To reflect this, we only implement 3 hit groups.

|Pseudo-Hitgroup|Identifer|Color in-game|Description|
|---------------|---------|-------------|-----------|
|Headshot|3|Red|Applies the headshot multiplier to the player (2 if unspecified)|
|Body|2|Green|No damage multiplier is applied|
|Reduced|1|Blue|The player only takes 55% of the damage. By default, this is applied in TTT for things like gear and the arms|

Any native hit groups will be mapped to the newest pseudo-hitgroup when drawn in-game.

### Configuration

The configuration is stored in `/data/hitboxcfg.dat`. It is an LZMA compressed JSON file. You can edit it manually if you desire like so:

```
mv hitboxcfg.dat hitboxcfg.json.lzma
lzma -d hitboxcfg.json.lzma
# Edit the resulting JSON file with your favorite text editor
```

Recompressing it,  placing it back onto the server, and changing the map will apply your changes.

However, normally configuration can be done in-game by any super admin.

1) Find a player wearing the model you'd like to fix. Normally I like to use a bot that was forced to wear a given model using console commands (`lua_run for k,v in pairs(player.GetBots()) do v:SetModel('modelhere') end`). Bots like to move around, so setting `bot_zombie 1` can also be helpful.
2) Get the bot's userid by typing `status` in console. The number you're looking for is before the bot's name in the status listing.
3) Run the `hbc_selply` command with the bot's userid as the only argument. This should draw wireframes around the bot. These boxes are the hit boxes.
4) Identify the hit box you'd like to change. Most of the time, you just need to guess and keep trying until you've got the right one. You can use the hbc_setgrp commands to change the hitboxes. If I'm trying to set a headshot hitbox, I typically start with `hbc_setgrp 0 0 3` and, if that isn't the right hit box, I'll revert it with `hbc_setgrp 0 0 0`. Then I will repeat the process, incrementing the second zero each time, until I've found the hit box I'm trying to modify.
5) After you've got the hit boxes set to your liking, save your changes by typing `hbc_commit`. The changes will be applied immediately.