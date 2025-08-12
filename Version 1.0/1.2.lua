local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Utility = ReplicatedStorage.Utility
local Component = require(Utility.Component)
local Zone = require(Utility.ZonePlus)
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Promise = require(Utility.Promise)
local bullet = game:GetService("ServerStorage"):WaitForChild("particlebullet")


local NPCGuard = Component.new({
	Tag = "GuardNPC"
})

function NPCGuard:Construct()
	
	local createZone = require(self.Instance.Parent.createZone)
	
	self.active = false
	self.players = {}
	
	

	-- SetUpZone
	if createZone.zone then
		self.zone = createZone.zone
	else
		createZone.new()
		self.zone = createZone.zone
	end

	-- State
	self.state = "idle"

	-- Target part to guard
	self.targetPart = self.Instance:FindFirstChild("TargetPart")
	if not self.targetPart then
		warn("TargetPart not found for NPCGuard")
	end

	self.humanoid = self.Instance.NPC:FindFirstChildOfClass("Humanoid")
	self.hrp = self.Instance.NPC:FindFirstChild("HumanoidRootPart")
	self.gun = self.Instance.NPC:FindFirstChild("M4")
	self.back = self.gun.Back
	self.Hand = self.gun.Hand
	self.back.Enabled = true
	self.Hand.Enabled = false
	self.barrel = self.gun.Barrel
	--Sounds
	self.EquipSound = self.gun.Equip
	self.Firesound = self.gun.Fire
	self.reloadsound = self.gun.Reload
	self.hitSound = self.gun.Impact.Hit
	
	self.Target = nil
	
	self.ammo = tonumber(self.Instance.NPC:GetAttribute("ammo"))
	self.firerate = tonumber(self.Instance.NPC:GetAttribute("firerate"))
	self.range = tonumber(self.Instance.NPC:GetAttribute("range"))  -- Define the detection range to start chasing
	self.attackRange = tonumber(self.Instance.NPC:GetAttribute("attackRange")) --Define range to start shooting
	self.chaseAgain = tonumber(self.Instance.NPC:GetAttribute("chaseAgain")) -- Define Range to rechase
	
end

function NPCGuard:RemovePlayer(_player)
	local index = table.find(self.players, _player)
	if index then
		table.remove(self.players, index)
	end
end

function NPCGuard:AddPlayer(_player)
	table.insert(self.players, _player)
end

function NPCGuard:Manager()
	
	if not self.Instance:FindFirstChild("NPC") then
		return
	end
	
	if #self.players < 1 then
		self:returnToPost(true)
		self:unequip()
		self.active = false
		return
	end	
	
	if self.state ~= "Attack" and self.state ~= "Chasing" then
		self.Target = self:FindTarget()
	end
	
	if self.state == "returning" then
		--print("Returnoing")
		self:returnToPost(false)
	end
	
	if self.state == "Patrol" then
		--print("Patrolling")
		self:randomPatrols(true)
	end
	
	if self.state == "Chasing" then
		--print("Chasing")
		self:chaseTarget(self.Target)
	end
	
	if self.state == "Attack" then
		--print("Attacking")
		self:attack(self.Target)
	end
	
	
	wait(0.1)
	
	self:Manager()
			
end

function NPCGuard:equip()
	self.humanoid:SetAttribute("state", "")
	self.humanoid:SetAttribute("state", "equip")
	task.wait(0.5)
	self.back.Enabled = false
	self.Hand.Enabled = true
	self.EquipSound:Play()
end

function NPCGuard:unequip()
	self.humanoid:SetAttribute("state", "")
	self.humanoid:SetAttribute("state", "equip")
	self.back.Enabled = true
	self.Hand.Enabled = false
	self.EquipSound:Play()
end


function NPCGuard:aim()
	self.humanoid:SetAttribute("state", "")
	self.humanoid:SetAttribute("state", "aim")
end

function NPCGuard:shoot()
	self.humanoid:SetAttribute("state", "")
	self.humanoid:SetAttribute("state", "aimshoot")
	for _, part in pairs(self.barrel:GetChildren()) do
		if part:IsA("ParticleEmitter") then
			part:Emit(1)
		end
	end
	self.Firesound:Play()
end

function NPCGuard:reload()
	self.humanoid:SetAttribute("state", "")
	self.humanoid:SetAttribute("state", "reload")
	self.reloadsound:Play()
end

function NPCGuard:guard()
	self.humanoid:SetAttribute("state", "")
	self.humanoid:SetAttribute("state", "guard")
end

--This function is for the NPC to search for targetsd
function NPCGuard:FindTarget()
	for _, player in ipairs(self.players) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local playerPosition = character.HumanoidRootPart.Position
			local distance = (self.hrp.Position - playerPosition).magnitude
			if distance <= self.range then
				self.state = "Chasing"
				return player
			end
		end
	end
end


function NPCGuard:generateMovement(position, fullPath)
	
	local waypointLimit = 0
	
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentMaxSlope = 45,
		WaypointSpacing = 1
	})
	
	local targetCFrame = CFrame.new(position)

	-- Extract the position from the new CFrame
	local targetPosition = targetCFrame.Position

	-- Compute the path using the position extracted from the new CFrame
	path:ComputeAsync(self.hrp.Position, targetPosition)

	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		
		if fullPath then
			waypointLimit = #waypoints
		else	
			waypointLimit = math.min(20, #waypoints)
		end
		
		self.humanoid:ChangeState(Enum.HumanoidStateType.Running)

		for i = 1, waypointLimit do
			
			if fullPath then
				
				self.Target = self:FindTarget()
				
				if self.Target then
					break
				end
			end
			
			local waypoint = waypoints[i]
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			self.humanoid:MoveTo(waypoint.Position)
			local success, errorMessage = self.humanoid.MoveToFinished:Wait()

			if not success then
				warn("Movement to waypoint failed: " .. tostring(errorMessage))
				self.state = "returning"
				self.Target = nil
				return
			end
		end
	else
		warn("Pathfinding failed with status: " .. tostring(path.Status))
	end
end

function NPCGuard:attack(targetPlayer)
	local targetCharacter = targetPlayer.Character

	if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
		local targetPosition = targetCharacter.HumanoidRootPart.Position
		local distance = (self.hrp.Position - targetPosition).magnitude
		local selfPosition = self.hrp.Position
		
		if self.ammo < 1 then
			self.ammo = 40
			self:reload()
			task.wait(3.5)
		end
		
		self.ammo -= 1
		
		if distance > self.chaseAgain then
			self.state = "Chasing"
		end
		
		local lookVector = (targetPosition - selfPosition).unit
		
		local projectile = bullet:Clone()
		projectile.Position = self.barrel.WorldCFrame.Position
		-- Set the orientation to face the target
		self.hrp.CFrame = CFrame.new(selfPosition, selfPosition + lookVector)
		self:shoot()
		task.wait(self.firerate)
		self:aim()
		
		projectile.CFrame = CFrame.new(projectile.Position, projectile.Position + lookVector)
		projectile.Anchored = false
		projectile.CanCollide = false

		-- Create a BodyVelocity to move the projectile
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = (targetPosition - projectile.Position).unit * 80 -- Adjust speed as needed
		bodyVelocity.Parent = projectile
		
		projectile.Parent = workspace
		coroutine.wrap(function()
			task.delay(0.2, function()
				if projectile then
					projectile.Transparency = 0
				end
			end)
		end)()
		

		-- Create a Touched event to handle collision
		local signal
		local owner = nil
		if self.Instance:FindFirstChild("NPC") then
			owner = self.Instance.NPC
		end
		
		signal = projectile.Touched:Connect(function(hit)
			
			local part = hit
			local b = projectile
			if hit.Parent == nil then
				signal:Disconnect()
				return
			end
			if (part and part.Name == 'Beskar')  or (part and part.Name == 'reflect')  or (part and part.Name == 'B')   or (part and part.Name == 'B2') or (part and part.Name == "Blade1") or (part and part.Name == "Blade2") then
				owner = targetCharacter
				--warn("hit reflect")
				if not b:FindFirstChild("Reflected") then
					coroutine.wrap(function()
						local bool = Instance.new("BoolValue")
						bool.Name = "Reflected"
						bool.Parent = b
						task.delay(0.5, function()
							if b then
								bool:Destroy()
							end
						end)
					end)()

					--Y, X, Z
					b.CFrame = b.CFrame *  CFrame.new(0,0,-5) * CFrame.fromEulerAngles(math.rad(math.random(-60,60)), math.rad(math.random(-60,60)), 0) * CFrame.Angles(0, math.pi, 0)
					local lookVector = projectile.CFrame.LookVector
					
					bodyVelocity.Velocity = lookVector * 50
				end
			elseif hit.Parent:isA("Model") and hit.Parent ~= owner then
				local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid then
					self.hitSound:Play()
					humanoid:TakeDamage(10) -- Damage value
					if humanoid.Health <= 0 then
						if owner == targetPlayer.Character then
							self:RemovePlayer(targetPlayer)
							self.Target = nil
							self.state = "Patrol"
						end
					end
				end
				projectile:Destroy() -- Destroy the projectile after hitting
				signal:Disconnect()
			end	
		end)
		
		
		coroutine.wrap(function()
			task.delay(3, function()
				if projectile then
					projectile:Destroy()
					signal:Disconnect()
				end
			end)
		end)()
		
	else
		self:RemovePlayer(targetPlayer)
		self.Target = nil
		self.state = "Patrol"
		return
	end
end


--This function is for the NPC to chase a target
function NPCGuard:chaseTarget(targetPlayer)
	
	self.humanoid.WalkSpeed = 20
		
	local targetCharacter = targetPlayer.Character
	
	if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
		
		local position = targetCharacter.HumanoidRootPart.Position
		
		
		local distance = (self.hrp.Position - position).magnitude
		
		if distance <= self.attackRange then
			self.state = "Attack"
			self:aim()
			task.wait(0.3)
			return
		end
		
		self:generateMovement(position, false)
		
	else
		self:RemovePlayer(targetPlayer)
		self.Target = nil
		self.state = "Patrol"
		return
	end
end

--This Function Is For the NPC to go Back to its Post
function NPCGuard:returnToPost(state)
	
	if self.targetPart and self.humanoid and self.hrp then
		
		local position = self.targetPart.Position
		
		self:generateMovement(position, state)
		
		local distance = (self.hrp.Position - position).magnitude

		if distance <= 5 then
		
			self.state = "idle"
			local targetOrientation = self.targetPart.Orientation
			self.hrp.CFrame = CFrame.new(self.hrp.Position) * CFrame.Angles(0, math.rad(targetOrientation.Y), 0)
		end
		
	end
end

function NPCGuard:randomPatrols(state)

	if self.targetPart and self.humanoid and self.hrp then
		
		if self.Target == nil then
			self:guard()
			task.wait(1)
			
			self.humanoid.WalkSpeed = 14
			
			local position = self.targetPart.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
			self:generateMovement(position, state)
		end

	end
end



function NPCGuard:Start()
	
	Players.PlayerRemoving:Connect(function(_player)
		self:RemovePlayer(_player)
		if _player == self.Target then
			self.Target = nil
			self.state = "Patrol"
		end
	end)
	
	
	self.zone.playerEntered:Connect(function(_player)
		self:AddPlayer(_player)
		
		if not self.active then
			if self.back.Enabled then
				self:equip()
				task.wait(3)
			end
			self.state = "Patrol"
			self.active = true
			self:Manager()
		end
	end)

	self.zone.playerExited:Connect(function(_player)
		self:RemovePlayer(_player)
	end)
	
	self.humanoid.HealthChanged:Connect(function()
		if self.humanoid.Health <= 0 then
			self.Instance:Destroy()
			self:Destroy()
		end
	end)
end

return NPCGuard
