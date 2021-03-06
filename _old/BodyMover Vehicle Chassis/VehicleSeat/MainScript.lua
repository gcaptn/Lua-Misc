local RunService = game:GetService("RunService")
local Main = script.Parent.Main.Value 
local Seat = Main.Parent.VehicleSeat
local Settings = Seat.SETTINGS

local maxThrottle = Settings.MaxSpeed.Value
local maxYawSpeed = Settings.MaxSteerVelocity.Value
local throttleDiff = Settings.ThrottleDifferential.Value
local yawDiff = Settings.SteerDifferential.Value
local gravity = 9.8
local gravityLeeway = 0.1
local antiGravity = Settings.AntiGravity.Value

local bVelocity = Instance.new("BodyVelocity")
local maxForceY = antiGravity and math.huge or 0
bVelocity.MaxForce = Vector3.new(math.huge,maxForceY,math.huge)
bVelocity.Velocity = Vector3.new(0,0,0)
bVelocity.Parent = Main 

local bAngularVYaw = Instance.new("BodyAngularVelocity")
bAngularVYaw.AngularVelocity = Vector3.new(0,0,0)
local maxTorqueAngular = antiGravity and math.huge or 0
bAngularVYaw.MaxTorque = Vector3.new(maxTorqueAngular,math.huge,maxTorqueAngular)
bAngularVYaw.Parent = Main

local bGyro = Instance.new("BodyGyro")
bGyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)

-- written by g_captain

function heightFromGround()
	local result = workspace:Raycast(Main.Position, Vector3.new(0,-100,0))
	if result then return Main.Position.Y - result.Position.Y else return 10 end
end

local regularYHeight = heightFromGround() + gravityLeeway


function correctMax(valInstance, max)
	valInstance:GetPropertyChangedSignal("Value"):Connect(function()
		if valInstance.Value > max then valInstance.Value = max
		elseif valInstance.Value < -max then valInstance.Value = -max end
	end)
end


--- THROTTLE UP/DOWN

local throttle = script.Throttle
correctMax(throttle, maxThrottle)


Seat:GetPropertyChangedSignal("Throttle"):Connect(function()
	repeat wait()
		if Seat.Throttle == 1 and throttle.Value < maxThrottle then
			wait() throttle.Value = throttle.Value + throttleDiff
		elseif  Seat.Throttle == -1 and throttle.Value >  -maxThrottle then
			wait() throttle.Value = throttle.Value - throttleDiff
		end
	until Seat.Throttle == 0
	throttle.Value = 0 
end)


--- YAW


local yaw = script.Yaw

Seat:GetPropertyChangedSignal("Steer"):Connect(function()

	repeat wait()
		if Seat.Steer == -1 and yaw.Value < maxYawSpeed then	
			wait(.1) yaw.Value = yaw.Value + yawDiff
		elseif  Seat.Steer == 1 and yaw.Value >  -maxYawSpeed then
			wait(.1) yaw.Value = yaw.Value - yawDiff
		end
	until Seat.Steer == 0 
	if Seat.Steer == 0 then 
		yaw.Value = 0 bAngularVYaw.AngularVelocity = Vector3.new(0,0,0)  
	end
end)

correctMax(yaw, maxYawSpeed)



-- GYRO

script.GyroEv.OnServerEvent:Connect(function()
	bGyro.Parent = Main wait(1)
	bGyro.Parent = nil 

end)


---- FUNCTIONS ---

function correctMax(valInstance, max)
	valInstance:GetPropertyChangedSignal("Value"):Connect(function()
		print (valInstance.Name, valInstance.Value)
		if valInstance.Value > max then valInstance.Value = max
		elseif valInstance.Value < -max then valInstance.Value = -max end
	end)
end



RunService.Heartbeat:Connect(function() 
	local velZ = Main.CFrame.lookVector.Z*throttle.Value
	local velX = Main.CFrame.LookVector.X*throttle.Value
	local velY = Main.CFrame.LookVector.Y*throttle.Value 
	if heightFromGround() > regularYHeight and antiGravity then velY =  Main.CFrame.LookVector.Y*throttle.Value - gravity end
	
	bVelocity.Velocity = Vector3.new(velX,velY,velZ)
	bAngularVYaw.AngularVelocity = Vector3.new(0,yaw.Value,0) 
end)
