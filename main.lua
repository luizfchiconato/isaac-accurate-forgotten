local mod = RegisterMod("Accurate Forgotten Character Mod", 1)

local Consts = require("consts")

local gabrielType = Isaac.GetPlayerTypeByName("Accurate Forgotten", false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.
-- local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2") -- Exact path, with the "resources" folder as the root
-- local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2") -- Exact path, with the "resources" folder as the root

function mod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    -- player:AddNullCostume(hairCostume)
    -- player:AddNullCostume(stolesCostume)
end


--------------------------------------------------------------------------------------------------
--------------------------------------- STARTING STATS HANDLE ------------------------------------
--------------------------------------------------------------------------------------------------


local game = Game() -- We only need to get the game object once. It's good forever!
local DAMAGE_MULTIPLIER = 2
local DAMAGE_ADD = 3
local FIREDELAY_MULTIPLIER = 2
local fireDelayMultiplierSet = false

local health = 206

function mod:HandleStartingStats(player, flag)
    if player:GetPlayerType() ~= gabrielType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    if flag == CacheFlag.CACHE_DAMAGE then
        -- Every time the game reevaluates how much damage the player should have, it will reduce the player's damage by DAMAGE_REDUCTION, which is 0.6
        player.Damage = (player.Damage * DAMAGE_MULTIPLIER) + DAMAGE_ADD
        if fireDelayMultiplierSet == false then
            player.MaxFireDelay = (player.MaxFireDelay * FIREDELAY_MULTIPLIER)
            fireDelayMultiplierSet = true
        end
    end
end


function mod:HandleHolyWaterTrail(player)
    if player:GetPlayerType() ~= gabrielType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    -- Every 4 frames. The percentage sign is the modulo operator, which returns the remainder of a division operation!
    if game:GetFrameCount() % 4 == 0 then
        -- Vector.Zero is the same as Vector(0, 0). It is a constant!
        --local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, player.Position, Vector.Zero, player):ToEffect()
        --creep.SpriteScale = Vector(0.5, 0.5) -- Make it smaller!
        --creep:Update() -- Update it to get rid of the initial red animation that lasts a single frame.
    end
end

function mod:charging(entity, amount, damageflag, source, countdownframes)
	if source.Type == EntityType.ENTITY_TEAR and entity:IsEnemy() then
        print(source)
	end
end

-- Extra-safe player iteration. Might not be necessary but shouldn't have much of an impact on performance.
function mod.GetPlayers()
	local players = {}
	for i=0, game:GetNumPlayers()-1 do
		local player = game:GetPlayer(i)
		if player and player:Exists() then
			players[i] = player
		end
	end
	return players
end

function mod:PostPlayerInit(player)
    fireDelayMultiplierSet = false
	health = 206
end
	


--------------------------------------------------------------------------------------------------
-------------------------------------- SPIN ITEM IMPLEMENTATION ----------------------------------
--------------------------------------------------------------------------------------------------

local spin = Isaac.GetItemIdByName("Spin")
local spinItem = Isaac.GetItemIdByName("Spin")
local spinEntity = Isaac.GetEntityTypeByName("Spin")

local spinInstance
local spinMode = 0

function mod:SpinUse(item)
    local player = Isaac.GetPlayer(0)
    local pos = player.Position
    pos.Y = pos.Y - 13

    spinInstance = Isaac.Spawn(spinEntity, 0, 0, pos, Vector(0,0), player)
    spinMode = 1

    SFXManager():Play(Isaac.GetSoundIdByName("Spin"), 1.25, 0, false, 1.0)

    return {
        Discharge = true,
        Remove = false,
        ShowAnim = false
    }
end

local spinCounter = 0
local frameCounter = 0

function runningSpinItem()
    local player = Isaac.GetPlayer(0)
    local sprite = player:GetSprite()

    if spinMode == 1 then
        
        local pos = player.Position
        pos.Y = pos.Y - 13
        spinInstance.Position = pos
        --spinInstance.Position.Y = spinInstance.Position.Y+5
        spinInstance.DepthOffset = 100
        sprite = spinInstance:GetSprite()
        spinInstance:ToNPC().Scale = player.SpriteScale.Y
        spinInstance.SpriteScale = spinInstance.SpriteScale * 5

        spinInstance:AddEntityFlags(EntityFlag.FLAG_NO_BLOOD_SPLASH)
        spinInstance:ToNPC().CanShutDoors = false

        sprite:Play("Spin", true)
        spinMode = 2
    end

    if spinMode == 2 then
        frameCounter = frameCounter + 1
        sprite:Update()
        
        local pos = player.Position
        pos.Y = pos.Y - 13
        spinInstance.Position = pos
        --spinInstance.Position.Y = spinInstance.Position.Y+5
        spinInstance.DepthOffset = 100
        spinInstance:ToNPC().Scale = player.SpriteScale.Y

        if (frameCounter % 7 == 2)
        then
            spinCounter = spinCounter + 1
            AOEdamage(player.Position, 90 * player.SpriteScale.Y, player.Damage / 1.5)
        end

        if spinCounter == 4 then
            spinInstance:Die()
            spinCounter = 0
            frameCounter = 0
            spinMode = 0
        end
    end
end

function AOEdamage(loc, radius, degat)
	local	player = Isaac.GetPlayer(0)
	local	entities = Isaac.GetRoomEntities()
	local	dist

	for i = 1, #entities do
		dist = entities[i].Position:Distance(loc)

		if entities[i]:IsVulnerableEnemy()
		or entities[i].Type == EntityType.ENTITY_FIREPLACE then
			if dist < radius then
				entities[i]:TakeDamage(degat,0,EntityRef(player),30)

                local knockback = 40

                local knockbackForce = entities[i].Position:__sub(player.Position):Resized(knockback)
		        entities[i].Velocity = Lerp(entities[i].Velocity, knockbackForce, 0.75)

                SFXManager():Play(Isaac.GetSoundIdByName("Enemy Spun"), 1.25, 0, false, 1.0)
			end
		end
	end

end

function Lerp(first, second, percent)
	return (first + (second - first)*percent)
end

function mod:GiveForgottenPocketActive(player)
	if player:GetPlayerType() == gabrielType and player:GetActiveItem(ActiveSlot.SLOT_POCKET) == 0 then
		player:SetPocketActiveItem(spinItem)
	end
end

function mod:ForgottenPocketActiveCheck()
	for _, player in pairs(mod.GetPlayers()) do
		mod:GiveForgottenPocketActive(player)
	end
end


--------------------------------------------------------------------------------------------------
------------------------------------ HEALTH HANDLING FUNCTIONS -----------------------------------
--------------------------------------------------------------------------------------------------

local takendamage = false
function mod.ForgottenTakeDamage(teste,target,amount,flag,source,num)
    local player = Isaac.GetPlayer(0)

    if target.Type == EntityType.ENTITY_PLAYER then
        if takendamage == false then
            takendamage = true
            if player:GetPlayerType() ~= gabrielType then
                return
            end

            print('a')
        
            removeHealth(60)
        
            if health <= 0 then
                player:Kill()
            end
        
            player:TakeDamage(1, DamageFlag.DAMAGE_FAKE, source, 800)
        
            return false
        else 
            takendamage = false
        end
    end
end



function mod:displayinfo()
    --local player = Isaac.GetPlayer(0)
    --local position = Isaac.WorldToRenderPosition(player.Position)

    local Xoffset, Yoffset = dynamicText(health)

    --local Xoffset = position.X
    --local Yoffset = position.Y
    Isaac.RenderText(health,Xoffset,Yoffset,1,1,1,1)
end

function dynamicText(str)
    local player_position = Isaac.WorldToRenderPosition(Isaac.GetPlayer(0).Position, 2)

    local scroll_offset = Game():GetRoom():GetRenderScrollOffset()

    local text_width_half = Isaac.GetTextWidth(str) / 2.0

    local x = player_position.X + 0 + scroll_offset.X - text_width_half
    local y = player_position.Y + 5 + scroll_offset.Y

    return x, y
end

function renderText(str, positionProducer, r, g, b, a)
    local x, y = positionProducer(str)

    Isaac.RenderText(str, x, y, r, g, b, a)
end

function mod:tick()
    local player = Isaac.GetPlayer(0)

    if player:GetPlayerType() ~= gabrielType then
        return
    end

    updateTearsSprite()
    handleHealthPickups(player)
    runningSpinItem()

end

function updateTearsSprite()
    local ents = Isaac.GetRoomEntities()
    for i=1,#ents do
        if ents[i].Type == EntityType.ENTITY_TEAR and ents[i].Variant ~= TearVariant.PUPULA then
            --ents[i]:ToTear().Scale = (ents[i]:ToTear().BaseScale) * 2
            ents[i]:ToTear():ChangeVariant(TearVariant.PUPULA)
            local spr = ents[i]:GetSprite()
            spr:ReplaceSpritesheet(0,"gfx/tears_bone.png")
            spr:LoadGraphics()
        end
    end
end

function handleHealthPickups(player)
    local entities = Isaac.FindByType(5, 10, -1)
    local pickupradius = 50

    for ent = 1, #entities do
        local entity = entities[ent]
        if entity:IsDead() == false and entity.Type == 5 then
            if entity.Variant == 10 and entity.SubType < 20 then
                if entity.Position.X < player.Position.X + pickupradius and entity.Position.X > player.Position.X - pickupradius and entity.Position.Y < player.Position.Y + pickupradius and entity.Position.Y > player.Position.Y - pickupradius then
                    if entity.SubType == 1 or entity.SubType == 9 then -- full red
                        addHealth(Consts.RED_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 2 then -- half heart
                        addHealth(Consts.HALF_RED_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 3 then -- soul heart
                        addHealth(Consts.SOUL_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 4 then -- eternal heart
                        addHealth(Consts.ETERNAL_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 5 then -- double red
                        addHealth(Consts.DOUBLE_RED_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 6 then -- black heart
                        addHealth(Consts.BLACK_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 7 then -- gold heart
                        addHealth(Consts.GOLD_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 8 then -- half soul heart
                        addHealth(Consts.HALF_SOUL_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 10 then -- blended heart
                        addHealth(Consts.BLENDED_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 11 then -- bone heart
                        addHealth(Consts.BONE_HEART_REGEN)
                        entity:Remove()
                    elseif entity.SubType == 12 then -- rotten heart
                        addHealth(Consts.ROTTEN_HEART_REGEN)
                        entity:Remove()
                    end

                    SFXManager():Play(SoundEffect.SOUND_BONE_HEART, 1.25, 0, false, 1.0)
                end

                if player:HasCollectible(53) then
                    if entity.SubType == 1 or entity.SubType == 2 or entity.SubType == 5 or entity.SubType == 9 or entity.SubType == 10 then
                        local tempVel = entity.Velocity
                        if entity.Position.X > player.Position.X then
                            tempVel.X = -1.5
                        else
                            tempVel.X = 1.5
                        end
                        if entity.Position.Y > player.Position.Y then
                            tempVel.Y = -1.5
                        else
                            tempVel.Y = 1.5
                        end								
                        entity.Velocity = tempVel
                    end
                end
            end
        end
    end
end

function addHealth(amount)
    local tempHealth = health + amount
    if (tempHealth > 206) then
        tempHealth = 206
    end
    health = tempHealth
end

function removeHealth(amount)
    print(health)

    if (amount <= 10) then
        SFXManager():Play(SoundEffect.SOUND_BONE_DROP, 1.25, 0, false, 1.0)
    else
        SFXManager():Play(SoundEffect.SOUND_BONE_BREAK, 1.25, 0, false, 1.0)
    end
    

    if (health == 1) then
        health = 0
        local player = Isaac.GetPlayer(0)
        player:Kill()
        return
    end

    local tempHealth = health - amount
    print(tempHealth)
    if (tempHealth <= 0) then
        tempHealth = 1
    end
    
    health = tempHealth
end


--------------------------------------------------------------------------------------------------
------------------------------------- TEAR ACCURACY FUNCTIONS ------------------------------------
--------------------------------------------------------------------------------------------------

function mod:tearColision(tear, collider, low)
    addHealth(1)
end

function mod:tearInit(tear)
    removeHealth(1)
end



mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.GiveCostumesOnInit)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.HandleStartingStats)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ForgottenTakeDamage)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.PostPlayerInit)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.displayinfo);
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.tick);
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, mod.tearColision);
mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, mod.tearInit);
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,mod.charging)
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.HandleHolyWaterTrail)
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.SpinUse, spin)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.ForgottenPocketActiveCheck)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.ForgottenPocketActiveCheck)
