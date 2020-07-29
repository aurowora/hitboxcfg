local HITBOX_OVERRIDES = {}

if file.Exists('hitboxcfg.dat', 'DATA') then
    local comp = file.Read('hitboxcfg.dat', 'DATA')

    if not comp then
        ErrorNoHalt('Couldn\'t read hitboxcfg.dat')
    else
        local decomp = util.Decompress(comp)

        if not decomp or decomp == '' then
            error('Hitbox config data is corrupted. (DECOMPRESSION FAILED)')
        end

        HITBOX_OVERRIDES = util.JSONToTable(decomp)

        if not HITBOX_OVERRIDES then
            error('Hitbox config data is corrupted. (JSON PARSE FAILED)')
        end
    end
end

ServerLog(string.format('Loaded %d hit box overrides.\n', table.Count(HITBOX_OVERRIDES)))

util.AddNetworkString('HitBoxCfg_RequestInfo')
util.AddNetworkString('HitBoxCfg_SendInfo')
util.AddNetworkString('HitBoxCfg_Commit')

net.Receive('HitBoxCfg_RequestInfo', function (l, ply)
    if not ply:IsSuperAdmin() then
        ServerLog(sting.format('[Suspicious] %s (%s) tried to request hitgroup info despite not being a super admin.\n', ply:Nick(), ply:SteamID64()))
        return
    end

    local model = net.ReadString()

    net.Start('HitBoxCfg_SendInfo')
    if HITBOX_OVERRIDES[model] then
        print('Found hit box overrides for ' .. model)
        net.WriteTable(HITBOX_OVERRIDES[model])
    else
        print('No hitbox overrides for ' .. model)
        net.WriteTable({})
    end
    net.Send(ply)
end)

net.Receive('HitBoxCfg_Commit', function (l, ply)
    if not ply:IsSuperAdmin() then
        ServerLog(sting.format('[Suspicious] %s (%s) tried to set hitgroup info despite not being a super admin.\n', ply:Nick(), ply:SteamID64()))
        return
    end

    local model = net.ReadString()
    local tab = net.ReadTable()

    HITBOX_OVERRIDES[model] = tab

    local json = util.TableToJSON(HITBOX_OVERRIDES)
    local comp = util.Compress(json)
    file.Write('hitboxcfg.dat', comp)
    ServerLog(string.format('Saved %d hit box overrides.\n', table.Count(HITBOX_OVERRIDES)))
end)

local PS_HEADSHOT = 3
local PS_BODY = 2
local PS_REDUCED = 1

local function record_ply_hitbox(ply, dmg, dir, trace)
    ply.cfg_last_hitbox = trace.HitBox
end

hook.Add('PlayerTraceAttack', 'PlayerTraceAttack_HitBoxCfg', record_ply_hitbox)

local function scale_player_damage(ply, hitgroup, dmginfo)
    if HITBOX_OVERRIDES[ply:GetModel()] then
        local ov = HITBOX_OVERRIDES[ply:GetModel()]
        local hb = ply.cfg_last_hitbox and ply.cfg_last_hitbox or -1
        ply.cfg_last_hitbox = nil

        if ov['hitgroup_sets'][0] and ov['hitgroup_sets'][0][hb] then
            local oval = ov['hitgroup_sets'][0][hb]

            --Mimic what TTT does here
            if dmginfo:IsBulletDamage() and ply:HasEquipmentItem(EQUIP_ARMOR) then
                dmginfo:ScaleDamage(0.7)
            end

            ply.was_headshot = false

            if oval == PS_HEADSHOT then
                ply.was_headshot = dmginfo:IsBulletDamage()
                local wep = util.WeaponFromDamage(dmginfo)

                if IsValid(wep) then
                    local s = wep:GetHeadshotMultiplier(ply, dmginfo) or 2
                    dmginfo:ScaleDamage(s)
                end
            elseif oval == PS_REDUCED then
               dmginfo:ScaleDamage(0.55) 
            end

            if (dmginfo:IsDamageType(DMG_DIRECT) or
            dmginfo:IsExplosionDamage() or
            dmginfo:IsDamageType(DMG_FALL) or
            dmginfo:IsDamageType(DMG_PHYSGUN)) then
                dmginfo:ScaleDamage(2)
            end

            --This will prevent the regular TTT damage scaling logic from being executed.
            return false
        end
    end
 end

 hook.Add('ScalePlayerDamage', 'ScalePlayerDamage_HitBoxCfg', scale_player_damage)