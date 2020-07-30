AddCSLuaFile()

if SERVER then
    include('hitboxcfg/server.lua')
    AddCSLuaFile('hitboxcfg/client.lua')
else
    include('hitboxcfg/client.lua')
end
