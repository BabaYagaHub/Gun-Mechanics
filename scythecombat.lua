local wep = {}

local rep, ss = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")

local debris = game:GetService("Debris")

local Animations = rep.Animations
local Modules = ss.Modules

local WeaponAnimations = Animations.Weapons
local SharedModules = Modules.Shared
local WeaponModules = Modules.Weapons

local UtilitiesModule = require(SharedModules.Utilities)
local DamageModule = require(SharedModules.Damage)
local W_DictionaryModule = require(WeaponModules.Dictionary)
local W_HitboxModule = require(WeaponModules.Hitbox)
local W_HitEffectsModule = require(WeaponModules.HitEffect)

local function genEffects(target)
	W_HitEffectsModule.new(target)
end

local swingfunctions = {
	[1] = function(model)
		local humrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		local Hitbox = W_HitboxModule.Generate(model, humrp.CFrame * CFrame.new(0,0,-4), Vector3.new(5,7,5)*1.5, false)
		local t = tick()
		repeat task.wait(0.05) until Hitbox[1] or (tick()-t) > 0.25
		
		local Weapon = UtilitiesModule.GetWeaponInModel(model)
		local Dictionary = W_DictionaryModule[Weapon.Name]
		
		local Damage = Dictionary.Damage[1]
		
		for i,v in pairs(Hitbox) do
			genEffects(v.HumanoidRootPart)
			DamageModule.Damage(model, v, Damage)
			if (humrp.Position - v.HumanoidRootPart.Position).Magnitude <= 5 then
				local vel = Instance.new("BodyVelocity", v.HumanoidRootPart)
				vel.MaxForce = Vector3.new(1,1,1)*100000
				vel.Velocity = (humrp.Position - v.HumanoidRootPart.Position).Unit*10 + Vector3.new(0,5,0)
				debris:AddItem(vel, 0.1)
			end
		end
		
	end,
	[2] = 1,
	[3] = 1,
	[4] = function(model)
		local humrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		local Hitbox = W_HitboxModule.Generate(model, humrp.CFrame * CFrame.new(0,0,-4), Vector3.new(5,7,5)*1.5, false)
		local t = tick()
		repeat task.wait(0.05) until Hitbox[1] or (tick()-t) > 0.25

		local Weapon = UtilitiesModule.GetWeaponInModel(model)
		local Dictionary = W_DictionaryModule[Weapon.Name]

		local Damage = Dictionary.Damage[1]

		for i,v in pairs(Hitbox) do
			genEffects(v.HumanoidRootPart)
			DamageModule.Damage(model, v, Damage)
			local vel = Instance.new("BodyVelocity", v.HumanoidRootPart)
			vel.MaxForce = Vector3.new(1,1,1)*100000
			vel.Velocity = humrp.CFrame.lookVector*50 + Vector3.new(0,50,0)
			debris:AddItem(vel, 0.1)
		end
	end,
}

function wep.Swing(model)
	if not model:GetAttribute("Special") then model:SetAttribute("Special", 0) end
	if not model:GetAttribute("SwingCooldown") then model:SetAttribute("SwingCooldown", 0) end
	if not model:GetAttribute("Swing") then model:SetAttribute("Swing", 1) end
	if model:GetAttribute("SwingCooldown") ~= 0 then return end
	
	local Weapon = UtilitiesModule.GetWeaponInModel(model)
	local Animations = WeaponAnimations[Weapon.Name]
	
	local Dictionary = W_DictionaryModule[Weapon.Name]
	
	local Cooldown = Dictionary.Cooldown
	local Damage = Dictionary.Damage
	
	local humrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	
	local hum = model:FindFirstChildWhichIsA("Humanoid")
	local animator = hum:FindFirstChild("Animator") or UtilitiesModule.newInstance("Animator", {Parent = hum})
	
	local currentSwing = model:GetAttribute("Swing")
	local currentAnimation = Animations:FindFirstChild("Swing"..currentSwing)
	local nextCurrentAnimation = Animations:FindFirstChild("Swing"..currentSwing+1)
	
	local old = hum.WalkSpeed
	hum.WalkSpeed /= 2
	task.delay(0.25, function()
		hum.WalkSpeed *= 2
	end)
	
	if not nextCurrentAnimation then
		model:SetAttribute("Swing", 1)
		currentAnimation = Animations:FindFirstChild("Swing"..currentSwing)
		model:SetAttribute("SwingCooldown", Cooldown*5)
	else
		model:SetAttribute("SwingCooldown", Cooldown)
		model:SetAttribute("Swing", currentSwing+1)
	end
	
	local function playAnimations()
		local anim = UtilitiesModule.Anim(currentAnimation, animator, true)
		anim.Priority = "Action"
		anim:Play()
		task.delay(anim.Length*1.1, function()
			local idleanim = UtilitiesModule.Anim(Animations.Idle, animator, true)
			idleanim.Priority = "Idle"
			idleanim:Play()
		end)
	end
	
	playAnimations()
	
	local func = swingfunctions[currentSwing]
	if type(func) == "number" then
		swingfunctions[func](model)
	else
		swingfunctions[currentSwing](model)
	end
	
	

	
end


return wep
