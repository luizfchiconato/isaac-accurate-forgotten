local MyCharacterMod = RegisterMod("Gabriel Character Mod", 1)

local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.
-- local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2") -- Exact path, with the "resources" folder as the root
-- local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2") -- Exact path, with the "resources" folder as the root

function MyCharacterMod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    -- player:AddNullCostume(hairCostume)
    -- player:AddNullCostume(stolesCostume)
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.GiveCostumesOnInit)

local spinItem = Isaac.GetItemIdByName("Spin")


--------------------------------------------------------------------------------------------------


local game = Game() -- We only need to get the game object once. It's good forever!
local DAMAGE_REDUCTION = 0.6
local DAMAGE_MULTIPLIER = 2
local DAMAGE_ADD = 3
local FIREDELAY_MULTIPLIER = 2
local fireDelayMultiplierSet = false

local health = 206

function MyCharacterMod:HandleStartingStats(player, flag)
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

MyCharacterMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyCharacterMod.HandleStartingStats)

function MyCharacterMod:HandleHolyWaterTrail(player)
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

function MyCharacterMod:charging(entity, amount, damageflag, source, countdownframes)
	if source.Type == EntityType.ENTITY_TEAR and entity:IsEnemy() then
        print(source)
	end
end
	
MyCharacterMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,MyCharacterMod.charging)
MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyCharacterMod.HandleHolyWaterTrail)

---------------------------------------------------

local spin = Isaac.GetItemIdByName("Spin")

function MyCharacterMod:SpinUse(item)
    local roomEntities = Isaac.GetRoomEntities()
    local room = Game():GetRoom()
    local pos
    local sprite

    

    return {
        Discharge = true,
        Remove = false,
        ShowAnim = true
    }
end

local spinMode = 0
function spinning()
    local player = Isaac.GetPlayer(0)
    local sprite

    if spearMode == 1 then -- la lance est au sol

        -- on regarde si le joueur est assez pr�s
        if player.Position:Distance(spear.Position) < 25 then
            spearMode = 2 -- lance l'animation
            player:PlayExtraAnimation("Pickup")
            spear.Position = player.Position
            spear.Position.Y = spear.Position.Y+5
            spear.DepthOffset = 100
            sprite = spear:GetSprite()
            spear:ToNPC().Scale = player.SpriteScale.Y
            sprite:Play("Attack", true)
        end
        -- on regarde si la lance doit etre deplacee
        if (spearResetTime <= 0) or (IsAnybodyHere() == false) then -- (room:IsClear() == true) then
            sprite = spear:GetSprite()
            sprite:Play("Hide", true)
            spearMode = 3
        end
    end
    if spearMode == 2 then -- la lance est utilise
        spear.Position = player.Position
        sprite = spear:GetSprite()
        -- teste degats
        if (sprite:GetFrame() == 7) 
        or (sprite:GetFrame() == 13)
        or (sprite:GetFrame() == 19)
        or (sprite:GetFrame() == 25)
        or (sprite:GetFrame() == 31) then
            AOEdamage(player.Position, 110 * player.SpriteScale.Y, player.Damage * 1.6)
        end

        if sprite:IsFinished("Attack") then
            spear:Remove()
            spinMode = 0
            spearResetTime = player.MaxFireDelay * 20
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
			end
		end
	end

end

MyCharacterMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyCharacterMod.SpinUse, spin)




function MyCharacterMod:GiveForgottenPocketActive(player)
	if player:GetPlayerType() == gabrielType and player:GetActiveItem(ActiveSlot.SLOT_POCKET) == 0 then
		player:SetPocketActiveItem(spinItem)
	end
end

function MyCharacterMod:ForgottenPocketActiveCheck()
	for _, player in pairs(MyCharacterMod.GetPlayers()) do
		MyCharacterMod:GiveForgottenPocketActive(player)
	end
end

-- Extra-safe player iteration. Might not be necessary but shouldn't have much of an impact on performance.
function MyCharacterMod.GetPlayers()
	local players = {}
	for i=0, game:GetNumPlayers()-1 do
		local player = game:GetPlayer(i)
		if player and player:Exists() then
			players[i] = player
		end
	end
	return players
end


MyCharacterMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, MyCharacterMod.ForgottenPocketActiveCheck)
MyCharacterMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyCharacterMod.ForgottenPocketActiveCheck)


local takendamage = false
function MyCharacterMod.ForgottenTakeDamage(teste,target,amount,flag,source,num)
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

function MyCharacterMod:PostPlayerInit(player)
    fireDelayMultiplierSet = false
	health = 206
end

function MyCharacterMod:displayinfo()
    local Xoffset = 30
    local Yoffset = 20
    Isaac.RenderText(health,Xoffset,Yoffset,1,1,1,1)
end

function MyCharacterMod:tick()
    local player = Isaac.GetPlayer(0)

    if player:GetPlayerType() ~= gabrielType then
        return
    end

    local ents = Isaac.GetRoomEntities()
    for i=1,#ents do
        if ents[i].Type == EntityType.ENTITY_TEAR and ents[i].Variant ~= TearVariant.PUPULA then
            --ents[i]:ToTear().Scale = (ents[i]:ToTear().BaseScale) * 2
            ents[i]:ToTear():ChangeVariant(TearVariant.PUPULA)
            local spr = ents[i]:GetSprite()
            spr:ReplaceSpritesheet(0,"gfx/tears_bone.png")
            spr:LoadGraphics()
            tears[ents[i].Index] = ents[i]
        end
    end

    local entities = Isaac.FindByType(5, 10, -1)
    local pickupradius = 50

    for ent = 1, #entities do
        local entity = entities[ent]
        if entity:IsDead() == false and entity.Type == 5 then
            if entity.Variant == 10 and entity.SubType < 20 then
                if entity.Position.X < player.Position.X + pickupradius and entity.Position.X > player.Position.X - pickupradius and entity.Position.Y < player.Position.Y + pickupradius and entity.Position.Y > player.Position.Y - pickupradius then
                    if entity.SubType == 1 or entity.SubType == 9 then -- full red
                        addHealth(30)
                        entity:Remove()
                    elseif entity.SubType == 2 then -- half heart
                        addHealth(15)
                        entity:Remove()
                    elseif entity.SubType == 3 then -- soul heart
                        addHealth(40)
                        entity:Remove()
                    elseif entity.SubType == 4 then -- eternal heart
                        addHealth(60)
                        entity:Remove()
                    elseif entity.SubType == 5 then -- double red
                        addHealth(60)
                        entity:Remove()
                    elseif entity.SubType == 6 then -- black heart
                        addHealth(45)
                        entity:Remove()
                    elseif entity.SubType == 7 then -- gold heart
                        addHealth(20)
                        entity:Remove()
                    elseif entity.SubType == 8 then -- half soul heart
                        addHealth(40)
                        entity:Remove()
                    elseif entity.SubType == 10 then -- blended heart
                        addHealth(40)
                        entity:Remove()
                    elseif entity.SubType == 11 then -- bone heart
                        addHealth(60)
                        entity:Remove()
                    elseif entity.SubType == 12 then -- rotten heart
                        addHealth(30)
                        entity:Remove()
                    end

                    SFXManager():Play(SoundEffect.SOUND_BONE_HEART, 1.25, 0, false, 1.0)
                end
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

function MyCharacterMod:tearColision(tear, collider, low)
    addHealth(1)
end

function MyCharacterMod:tearInit(tear)
    removeHealth(1)
end


MyCharacterMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, MyCharacterMod.ForgottenTakeDamage)
MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.PostPlayerInit)
MyCharacterMod:AddCallback(ModCallbacks.MC_POST_RENDER, MyCharacterMod.displayinfo);
MyCharacterMod:AddCallback(ModCallbacks.MC_POST_UPDATE, MyCharacterMod.tick);
MyCharacterMod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, MyCharacterMod.tearColision);
MyCharacterMod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, MyCharacterMod.tearInit);

