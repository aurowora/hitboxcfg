AddCSLuaFile()

if SERVER then
    include('hitboxcfg/server.lua')
else
    AddCSLuaFile('hitboxcfg/client.lua')
    include('hitboxcfg/client.lua')
end