local cuts = {}

local rep, ss = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")

local AnimationFolder = rep.Animations
local GunAnimations = AnimationFolder.Guns

local GunsFolder = rep.Guns

local Modules = ss.Modules
local GunModules = Modules.Guns

local DictionaryModule = require(GunModules.Dictionary)

local twnService = game:GetService("TweenService")
local OtherFolder = rep.Other

function cuts:GiveGun(g)
	
	local Dictionary = DictionaryModule[g]
	
	local Humanoid = self:WaitForChild("Humanoid")
	local Animator = Humanoid:FindFirstChild("Animator")
	local RightArm = self:FindFirstChild("Right Arm")
	
	local Gun = GunsFolder:FindFirstChild(g):Clone()
	Gun.Parent = self
	local Handle = Gun.Handle
	
	local motor6d = Instance.new("Motor6D", Handle)
	motor6d.Part0 = Handle
	motor6d.Part1 = RightArm
	
	motor6d.C0 = DictionaryModule[g].C0
	
	Gun:SetAttribute("Ammo", Dictionary.Ammo)
	Gun:SetAttribute("Halt", false)
	
	local function playIdle()
		
		local GunAnimationFolder = GunAnimations[g]
		local IdleAnimation = GunAnimationFolder.Idle
		
		local s, e = pcall(function()
			Animator:LoadAnimation(IdleAnimation):Play()
		end)
		
		if e then
			task.wait(1)
			Animator:LoadAnimation(IdleAnimation):Play()
		end
		
	end
	
	playIdle()
	
end

function cuts:ShootGun(mousePos)
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self, workspace.Spare}
	
	local Gun = self:FindFirstChildWhichIsA("Model")
	local ShootPart = Gun.Shoot
	
	local Light = ShootPart.Light:Clone()
	Light.Parent = ShootPart
	
	local ShootSound = ShootPart.Shoot:Clone()
	ShootSound.Parent = ShootPart
	ShootSound:Play()
	game.Debris:AddItem(ShootSound, ShootSound.TimeLength)
	
	local Dictionary = DictionaryModule[Gun.Name]
	
	local humrp = self.HumanoidRootPart
	
	local max = Dictionary.Max
	local difference = (humrp.Position - mousePos)
	
	local distance = math.clamp(difference.Magnitude, 0, max)
	local newPos = -(difference.Unit * distance) + humrp.Position
	
	local newPart = Instance.new("Part", workspace.Spare)
	newPart.Name = "BeamG"
	newPart.Position = newPos
	newPart.Size = Vector3.new(1, 1, 1) * 0.00001
	newPart.CanCollide = false
	newPart.Anchored = true
	newPart.Transparency = 1
	
	local distance = (humrp.Position - newPart.Position).Magnitude
	local divisonrate = 5000
	
	
	twnService:Create(Light, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Brightness = 25, Range = 5}):Play()
	task.delay(0.1, function()
		twnService:Create(Light, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Brightness = 0, Range = 5}):Play()
	end)
	
	
	local Atch1 = Instance.new("Attachment", newPart)
	local Atch0 = ShootPart.Attachment
	
	local Beam = ShootPart.Beam:Clone()
	Beam.Parent = ShootPart

	Beam.Attachment0 = Atch0
	Beam.Attachment1 = Atch1
	
	
	task.spawn(function()
		
		local val1 = 0
		local val2 = 0
		local val3 = 0
		
		local increaserate = Dictionary.IncreaseRate
		
		repeat
			
			val1 += increaserate
			if val1 >= 1 then
				val2 += increaserate
			end
			if val2 >= 1 then
				val3 += increaserate
			end

			
			Beam.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, val1*1.15),
				NumberSequenceKeypoint.new(0.25, val1),
				NumberSequenceKeypoint.new(0.5, val2),
				NumberSequenceKeypoint.new(1, val3)
			}
			task.wait(distance/divisonrate)
		until val1 >= 1 and val2 >= 1 and val3 >= 1

		newPart:Destroy()
		Beam:Destroy()
		Light:Destroy()
		
	end)
	
	
	local direction = newPart.Position - ShootPart.Position
	
	local raycast = workspace:Raycast(ShootPart.Position, direction*(ShootPart.Position - newPart.Position).Magnitude, params)
	if raycast and raycast.Instance then
		
		local function lookForParent()
			for i,v in pairs(string.split(raycast.Instance:GetFullName(), ".")) do
				if workspace:FindFirstChild(v) ~= nil then
					return workspace:FindFirstChild(v)
				end
			end
		end
		
		local Target = lookForParent()
		
		if Target:FindFirstChildWhichIsA("Humanoid") then
			local HumanoidTarget = Target.Humanoid
			
			local multi = 1
			if raycast.Instance == Target.Head then
				multi = Dictionary.HeadshotMultiplier
			end
			
			HumanoidTarget:TakeDamage(Dictionary.Damage*multi)
			
			local HitSound = ShootPart.Hit:Clone()
			HitSound.Parent = raycast.Instance
			HitSound:Play()
			game.Debris:AddItem(HitSound, HitSound.TimeLength)
			
			
			local hitEffect = Instance.new("Part", Target)
			hitEffect.Size = Vector3.new(2,2,2)
			hitEffect.BrickColor = BrickColor.new("Really red")
			hitEffect.Anchored = true
			hitEffect.CanCollide = false
			hitEffect.Position = Target.HumanoidRootPart.Position
			hitEffect.Shape = Enum.PartType.Ball
			hitEffect.Material = "Neon"
			
			twnService:Create(hitEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = hitEffect.Size*5, Transparency = 1}):Play()
			
			game.Debris:AddItem(hitEffect, 0.5)
			
		end
		
	end
	
end

function cuts:Reload()
	
	local Gun = self:FindFirstChildWhichIsA("Model")
	local GunDictionary = DictionaryModule[Gun.name]
	
	if Gun:GetAttribute("Halt") or Gun:GetAttribute("Ammo") >= GunDictionary.Ammo then return end
	
	Gun:SetAttribute("Halt", true)
	
	local ReloadBillboard = OtherFolder.Reload:Clone()
	ReloadBillboard.Parent = self.HumanoidRootPart
	ReloadBillboard.Adornee = self.HumanoidRootPart
	ReloadBillboard.Enabled = true
	
	Gun.Shoot.Reloading:Play()
	
	task.spawn(function()
		repeat
			Gun:SetAttribute("Ammo", Gun:GetAttribute("Ammo")+1)
			task.wait(GunDictionary.ReloadTime)
		until Gun:GetAttribute("Ammo") >= GunDictionary.Ammo
		task.wait(1)
		Gun:SetAttribute("Halt", false)
		ReloadBillboard:Destroy()
	end)
	
end

return cuts
