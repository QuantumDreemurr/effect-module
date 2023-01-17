--made by scandalous

--PartCache made by Xan_TheDragon (edited, because the original is quite stinky)
--https://github.com/QuantumDreemurr/effect-module

local PartCacheStatic = {}
PartCacheStatic.__index = PartCacheStatic
local CF_REALLY_FAR_AWAY = CFrame.new(0, 10e8, 0)
local function keyOf(tbl, value)
	for index, obj in pairs(tbl) do
		if obj == value then
			return index
		end
	end
	return nil
end
local function indexOf(tbl, value)
	local fromFind = table.find(tbl, value)
	if fromFind then return fromFind end

	return keyOf(tbl, value)
end
local function MakeFromTemplate(template: BasePart, currentCacheParent: Instance): BasePart
	local part: BasePart = template:Clone()	
	part.CFrame = CF_REALLY_FAR_AWAY
	part.Anchored = true
	part.Parent = currentCacheParent
	return part
end
function PartCacheStatic.new(template: BasePart, currentCacheParent: Instance?)
	local newTemplate: BasePart = template:Clone()
	template = newTemplate
	local object = 	setmetatable({
		Open = {},
		InUse = {},
		CurrentCacheParent = currentCacheParent or workspace,
		Template = template,
		ExpansionSize = 10
	}, PartCacheStatic)
	for _ = 1, 15 do table.insert(object.Open, MakeFromTemplate(template, object.CurrentCacheParent)) end
	object.Template.Parent = nil
	return object
end
function PartCacheStatic:GetPart(): BasePart
	if #self.Open == 0 then
		for i = 1, self.ExpansionSize, 1 do
			table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
		end
	end
	local part = self.Open[#self.Open]
	self.Open[#self.Open] = nil
	table.insert(self.InUse, part)
	return part
end
function PartCacheStatic:ReturnPart(part: BasePart)
	local index = indexOf(self.InUse, part)
	if index ~= nil then
		table.remove(self.InUse, index)
		table.insert(self.Open, part)
		part.CFrame = CF_REALLY_FAR_AWAY
		part.Anchored = true
	end
end

local RunService = game:GetService("RunService")

local Render = {}

-- UTILITY

local Utility = {}

local Rad = math.rad(1)

Utility.Lerp = function(Start, Goal, Fraction)
	return Start + (Goal - Start) * Fraction
end


Utility.ApplyTemplate = function(Object)
	Object.Anchored = true 
	Object.CanQuery = false
	Object.CanCollide = false 
	Object.CanTouch = false
	Object.CastShadow = false
	Object.Size = Vector3.one
	Object.Transparency = 0
	Object.Material = Enum.Material.Neon
	Object.Shape = Enum.PartType.Block
	
	Object:ClearAllChildren()
	
	return Object
end

local CachePart = script:IsDescendantOf(workspace) and script or workspace.Terrain
local Cache = PartCacheStatic.new(Utility.ApplyTemplate(Instance.new("Part")), CachePart)

Utility.NewPart = function()
	return Utility.ApplyTemplate(Cache:GetPart())
end

Utility.Debris = function(Item : number, Lifetime : number)
	task.delay(Lifetime, function()
		Cache:ReturnPart(Item)
		Render[Item] = nil
	end)
end


-- EFFECTS

local Effects = {}

-- Particle
Effects.Particle = function(Data : {Acceleration : Vector3, GoalPosition : Vector3?, Shape : Enum.PartType? | string?, Size : Vector3?, GoalSize : Vector3?, Position : Vector3, Transparency : number?, Time : number?, GoalTransparency : number?, Rotation : Vector3?, GoalRotation : Vector3?, Color : Color3?, GoalColor : Color3?})
	local Cube = Utility.NewPart()
	Cube.Size = Data.Size or Vector3.one
	if Data.Rotation then
		Cube.CFrame = CFrame.Angles(Data.Rotation.X * Rad, Data.Rotation.Y * Rad, Data.Rotation.Z * Rad)
	else 
		Cube.CFrame = CFrame.new()
	end
	Cube.Position = Data.Position
	local OriginalRotation = Cube.CFrame
	
	local Time = Data.Time or 0.45
	local Tick = 0
	local Color = Data.Color or BrickColor.new("Medium stone grey").Color
	
	if Data.Shape == Enum.PartType.Ball or Data.Shape == "Ball" then
		local Mesh = Instance.new("SpecialMesh")
		Mesh.MeshType = Enum.MeshType.Sphere
		Mesh.Parent = Cube
	elseif Data.Shape ~= nil then
		Cube.Shape = Data.Shape
	end
	
	Cube.Color = Color	
	
	local Position = Cube.Position
	local Size = Cube.Size
	local Velocity = Vector3.new()
	
	Render[Cube] = function(DeltaTime)
		Tick += DeltaTime

		local Alpha = (Tick / Time)

		Cube.Size = Size:Lerp(Data.GoalSize or (Size * 2), Alpha)
		Cube.Transparency = Utility.Lerp(Data.Transparency or 0.25, Data.GoalTransparency or 1, Alpha)
		
		if Data.Acceleration then
			Velocity += Data.Acceleration * DeltaTime
			Position += Velocity
			Cube.Position = Position
		end
		
		if Data.GoalPosition then
			Cube.Position = Position:Lerp(Data.GoalPosition, Alpha)
		end
		
		if Data.GoalColor then
			Cube.Color = Color:Lerp(Data.GoalColor, Alpha)
		end
		
		if Data.GoalRotation then
			Cube.CFrame = OriginalRotation:Lerp(CFrame.Angles(Data.GoalRotation.X * Rad, Data.GoalRotation.Y * Rad, Data.GoalRotation.Z * Rad) + Cube.Position, Alpha)
		end
	end

	Utility.Debris(Cube, Time)
end

-- RENDER

RunService.Heartbeat:Connect(function(DeltaTime)
	for Object, Update in Render do 
		if not Object.Parent then Render[Object] = nil continue end
		Update(DeltaTime)
	end
end)

-- PROVIDER

return Effects
