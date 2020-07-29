--Constants
local COLOR_HEADSHOT = Color(255, 0, 0)
local COLOR_REDUCED = Color(0, 0, 255)
local COLOR_BODY = Color(0, 255, 0)

local NATIVE_HEADSHOT = {HITGROUP_HEAD}
local NATIVE_BODY = {HITGROUP_CHEST, HITGROUP_STOMACH, HITGROUP_GENERIC}
local NATIVE_REDUCED = {HITGROUP_LEFTARM, HITGROUP_RIGHTARM, HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG, HITGROUP_GEAR}

local PS_HEADSHOT = 3
local PS_BODY = 2
local PS_REDUCED = 1


--State vars
local CURRENT_PLAYER = nil
local CURRENT_MODEL = nil
local CURRENT_EDITOR_DATA = {}

--Commands

local function IsEditing()
    if not CURRENT_MODEL or not CURRENT_PLAYER then
        return false
    end
    return true
end

local function get_override(grp, hb)
    if not CURRENT_EDITOR_DATA or not CURRENT_EDITOR_DATA['hitgroup_sets'] or not CURRENT_EDITOR_DATA['hitgroup_sets'][grp] or not CURRENT_EDITOR_DATA['hitgroup_sets'][grp][hb] then return 0 end

    return CURRENT_EDITOR_DATA['hitgroup_sets'][grp][hb]
end

concommand.Add("hbc_selply", function(ply, cmd, args, str)
    if not LocalPlayer():IsSuperAdmin() then return end

    if IsEditing() then
        chat.AddText('You\'re already editing a model. Type hbc_unsel or hbc_commit to stop editing.')
        return
    end

    if table.Count(args) != 1 then return end

    local idx = tonumber(args[1])

    if not idx then return end

    CURRENT_PLAYER = Player(idx)

    if not CURRENT_PLAYER or not IsValid(CURRENT_PLAYER) then return end

    CURRENT_MODEL = CURRENT_PLAYER:GetModel()

    net.Start('HitBoxCfg_RequestInfo')
    net.WriteString(CURRENT_MODEL)
    net.SendToServer()
end)

net.Receive('HitBoxCfg_SendInfo', function ()
    CURRENT_EDITOR_DATA = net.ReadTable()

    PrintTable(CURRENT_EDITOR_DATA)

    CURRENT_EDITOR_DATA['hint_hitgroup_set_count'] = CURRENT_PLAYER:GetHitboxSetCount() --I cannot get this to work on the server, so I will save this here.

    if not CURRENT_EDITOR_DATA['hitgroup_sets'] then CURRENT_EDITOR_DATA['hitgroup_sets'] = {} end

    chat.AddText('Selected ' .. CURRENT_PLAYER:GetModel())
end)

concommand.Add("hbc_listgrp", function(ply, cmd, args, str)
    if not LocalPlayer():IsSuperAdmin() then return end

    if not IsEditing() then
        chat.AddText('You are not currently editing any model.')
        return
    end

    if CURRENT_PLAYER:GetHitboxSetCount() == nil then return end

		for group=0, CURRENT_PLAYER:GetHitboxSetCount() - 1 do
		    
            for hitbox=0, CURRENT_PLAYER:GetHitBoxCount( group ) - 1 do
                print(string.format('%d %d %d %d', group, hitbox, CURRENT_PLAYER:GetHitBoxHitGroup(hitbox, group), get_override(group, hitbox)))
			end
		end

end)

concommand.Add("hbc_setgrp", function(ply, cmd, args, str)
    if not LocalPlayer():IsSuperAdmin() then return end

    if not IsEditing() then
        chat.AddText('You are not currently editing any model.')
        return
    end

    if table.Count(args) != 3 then return end

    local grp = tonumber(args[1])
    local hb = tonumber(args[2])
    local ov = tonumber(args[3])

    if not grp or not hb or not ov then return end

    if grp != 0 then
        chat.AddText('Due to limitations in GMOD, overriding hit group (damage values) for groups > 0 is not supported currently.')
    end

    if not CURRENT_EDITOR_DATA['hitgroup_sets'][grp] then
        CURRENT_EDITOR_DATA['hitgroup_sets'][grp] = {}
    end

    if ov == 0 then
        CURRENT_EDITOR_DATA['hitgroup_sets'][grp][hb] = nil
    elseif ov >= PS_REDUCED and ov <= PS_HEADSHOT then
        CURRENT_EDITOR_DATA['hitgroup_sets'][grp][hb] = ov
    end
end)

concommand.Add("hbc_clear", function(ply, cmd, args, str)
    if not LocalPlayer():IsSuperAdmin() then return end

    if not IsEditing() then
        chat.AddText('You are not currently editing any model.')
        return
    end

    CURRENT_EDITOR_DATA = {}
end)

concommand.Add("hbc_commit", function(ply, cmd, args, str)
    if not LocalPlayer():IsSuperAdmin() then return end

    if not IsEditing() then
        chat.AddText('You are not currently editing any model.')
        return
    end

    net.Start('HitBoxCfg_Commit')
    net.WriteString(CURRENT_MODEL)
    net.WriteTable(CURRENT_EDITOR_DATA)
    net.SendToServer()

    CURRENT_PLAYER = nil
    CURRENT_EDITOR_DATA = {}
    CURRENT_MODEL = nil
end)

concommand.Add("hbc_unsel", function(ply, cmd, args, str)
    if not LocalPlayer():IsSuperAdmin() then return end

    if not IsEditing() then
        chat.AddText('You are not currently editing any model.')
        return
    end

    CURRENT_MODEL = nil
    CURRENT_PLAYER = nil
    CURRENT_EDITOR_DATA = {}
end)

--Renderer
local function render_hitboxes()
    if LocalPlayer():IsSuperAdmin() and IsEditing() then
        for k,ent in pairs(player.GetAll()) do
            if ent == CURRENT_PLAYER then
                if ent:GetHitboxSetCount() == nil then continue end

		        for group=0, ent:GetHitboxSetCount() - 1 do
		    
                    for hitbox=0, ent:GetHitBoxCount( group ) - 1 do

                        local pos, ang =  ent:GetBonePosition( ent:GetHitBoxBone(hitbox, group) )
                        local mins, maxs = ent:GetHitBoxBounds(hitbox, group)

                        local hg = ent:GetHitBoxHitGroup(hitbox, group)

                        local clr

                        if table.HasValue(NATIVE_HEADSHOT, hg) then
                            clr = COLOR_HEADSHOT
                        elseif table.HasValue(NATIVE_BODY, hg) then
                            clr = COLOR_BODY
                        elseif table.HasValue(NATIVE_REDUCED, hg) then
                            clr = COLOR_REDUCED
                        else
                            clr = Color(255, 255, 255)
                        end

                        if CURRENT_EDITOR_DATA and CURRENT_EDITOR_DATA['hitgroup_sets'] and CURRENT_EDITOR_DATA['hitgroup_sets'][group] and CURRENT_EDITOR_DATA['hitgroup_sets'][group][hitbox] then
                            if CURRENT_EDITOR_DATA['hitgroup_sets'][group][hitbox] == PS_HEADSHOT then
                                clr = COLOR_HEADSHOT
                            elseif CURRENT_EDITOR_DATA['hitgroup_sets'][group][hitbox] == PS_BODY then
                                clr = COLOR_BODY
                            elseif CURRENT_EDITOR_DATA['hitgroup_sets'][group][hitbox] == PS_REDUCED then
                                clr = COLOR_REDUCED
                            end
                        end

                        render.DrawWireframeBox( pos, ang, mins, maxs, clr, true )
                    end
		        end
            end
        end
    end
end

hook.Add("PostDrawOpaqueRenderables", "HitboxEditorRender", render_hitboxes)