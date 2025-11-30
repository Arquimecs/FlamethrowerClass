local FlamethrowerClient = {}
FlamethrowerClient.__index = FlamethrowerClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players: Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local events = ReplicatedStorage.events

local Flamethrower = events.Flamethrower
local GetData = events.GetData
local GetFlamethrowerData = events.GetFlamethrowerData

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local UI = PlayerGui.UI
local HUD = UI.HUD
local Fuel = HUD.Fuel
local Fill = Fuel.Fill
local Mouse: Mouse = Player:GetMouse()
local Backpack = Player.Backpack

function FlamethrowerClient.new() -- initial flamethrower class boot up, called whenever the player first needs the flamethrower, isnt deleted until player leaves

	local self = setmetatable({}, FlamethrowerClient)

	self.Connections = {}
	self.PlayerData = GetData:InvokeServer()
	self.FlamethrowerData = "None"
	self.MaxFuel = 0
	self.Fuel = 0
	self.DPS = 0
	self.Name = 0
	self.Cost = 0
	self.Equipped = false
	self.MouseDown = false

	FlamethrowerClient.FlamethrowerData = self.FlamethrowerData

	return self
end

function FlamethrowerClient:Initialize()

	self.FlamethrowerData = GetFlamethrowerData:InvokeServer()
	self.MaxFuel = self.FlamethrowerData.Fuel
	self.Fuel = self.FlamethrowerData.Fuel
	self.DPS = self.FlamethrowerData.DPS
	self.Name = self.FlamethrowerData.Name
	self.Cost = self.FlamethrowerData.Cost
	local Name: string = self.Name
	self.FlamethrowerObject = Backpack:FindFirstChild(Name)
	self:Recharge()
	self:SetUpConnections()

end

function FlamethrowerClient:SetUpConnections()
	
	self.Connections["ToolEquipped"] = self.FlamethrowerObject.Equipped:Connect(function()
		
		self.Equipped = true
		
	end)
	
	self.Connections["ToolUnequipped"] = self.FlamethrowerObject.Unequipped:Connect(function()

		self.Equipped = false
		self.MouseDown = false
		
	end)
	
	self.Connections["InputBegan"] = UserInputService.InputBegan:Connect(function(input, chat)

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

			if not self.Equipped then return end

			self.MouseDown = true
			Flamethrower:FireServer(true)

			task.spawn(function()

				while self.MouseDown and self.Fuel > 0 do
					
					self.Fuel -= 1
					Fill.Size.Y.Scale = self.Fuel/self.MaxFuel

					task.wait(0.1)
				end

				if self.Fuel <= 0 then
					Flamethrower:FireServer(false)
				end
			end)
		end
	end)

	self.Connections["InputEnded"] = UserInputService.InputEnded:Connect(function(input, chat)

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not self.Equipped then return end

			self.MouseDown = false
			Flamethrower:FireServer(false)
		end
	end)
end

function FlamethrowerClient:Recharge()
	
	local timer = 0	

	self.Connections["Heartbeat"] = RunService.Heartbeat:Connect(function()

		local timeNeeded = 3
		local fuel: number = self.Fuel
		local rechargeTime = (2 - fuel/100 * 2)

		if self.MouseDown then timer = 0 return end

		timer += 1

		if timer == 3 then
			timer = 0
			while self.Fuel ~= self.MaxFuel do
				if self.MouseDown then break end
				
				self.Fuel += 1
				Fill.Size.Y.Scale = self.Fuel/self.MaxFuel

				task.wait(rechargeTime/100)
			end
		end

		task.wait(1)
	end)
end

function FlamethrowerClient:Clean() -- cleans until player uses the class again

	for _, connection: RBXScriptConnection in pairs(self.Connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
			connection = nil
		end
	end

	self.Connections = {}
end

return FlamethrowerClient
