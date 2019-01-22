--[[	Arc.lua
		Implementation of the main Arc class of this library that the user interacts.
		This module is licensed under MIT, refer to the LICENSE file or:
		https://github.com/buildthomas/ElectricArc/blob/master/LICENSE
]]

local Arc = {}
Arc.__index = Arc

local Util = require(script.Util)
local Constants = require(script.Constants)
local System = require(script.System)

-- Error format strings
local ERROR_TYPE_FORMAT = "bad argument #%d to '%s' (%s expected, got %s)"
local ERROR_BAD_ARGUMENT = "bad argument #%d to '%s' (%s)"

function Arc:GetEnabled()
	return System.contains(self)
end

function Arc:SetEnabled(value)
	if value then
		System.add(self)
	else
		System.remove(self)
	end
end

function Arc:GetCFrame()
	return self.cframe
end

function Arc:SetCFrame(cfr)
    self.cframe = cfr
    self.changed = true
end

function Arc:GetRange()
    return self.cframe.p, self.cframe * Vector3.new(self.length, 0, 0)
end

function Arc:SetRange(source, drain)
	local axis = drain - source
	if axis.magnitude < 0.001 then
		axis = Vector3.new(0, 0, -0.001)
	end
    self.length = axis.magnitude
	self.cframe = Util.makeOrientation(source, axis)
    self.changed = true
end

function Arc:GetColor()
    return self.color
end

function Arc:SetColor(color)
    self.color = color
end

function Arc:GetTopColor()
    return self.topColor
end

function Arc:SetTopColor(topColor)
    self.topColor = topColor
end

function Arc:GetNumArcs()
	return self.numArcs
end

function Arc:Destroy()
    -- Remove self from system
    System.remove(self)

    -- Destroying instances
    self.part:Destroy()
    self.segmentsFolder:Destroy()
end

function Arc:GetFatnessMultiplier()
	return self.fatnessMultiplier
end

function Arc:SetFatnessMultiplier(fatnessMultiplier)
	self.fatnessMultiplier = fatnessMultiplier
end

function Arc.new(source, drain, color, topColor, numArcs, fatnessMultiplier, enabled)
    if source ~= nil and typeof(source) ~= "Vector3" then
        error(ERROR_TYPE_FORMAT:format(1, "new", "Vector3", typeof(source)), 2)
    elseif drain ~= nil and typeof(drain) ~= "Vector3" then
        error(ERROR_TYPE_FORMAT:format(2, "new", "Vector3", typeof(drain)), 2)
    elseif color ~= nil and typeof(color) ~= "Color3" then
        error(ERROR_TYPE_FORMAT:format(3, "new", "Color3", typeof(color)), 2)
    elseif topColor ~= nil and typeof(topColor) ~= "Color3" then
        error(ERROR_TYPE_FORMAT:format(4, "new", "Color3", typeof(topColor)), 2)
    elseif numArcs ~= nil and type(numArcs) ~= "number" then
        error(ERROR_TYPE_FORMAT:format(5, "new", "number", typeof(numArcs)), 2)
    elseif numArcs ~= nil and numArcs < 1 then
		error(ERROR_BAD_ARGUMENT:format(5, "new", "number of arcs should be >= 1"), 2)
	elseif fatnessMultiplier ~= nil and type(fatnessMultiplier) ~= "number" then
        error(ERROR_TYPE_FORMAT:format(6, "new", "number", typeof(fatnessMultiplier)), 2)
    elseif fatnessMultiplier ~= nil and fatnessMultiplier < 0 then
        error(ERROR_BAD_ARGUMENT:format(6, "new", "multiplier should be >= 0"), 2)
	elseif enabled ~= nil and type(enabled) ~= "boolean" then
        error(ERROR_TYPE_FORMAT:format(6, "new", "boolean", typeof(enabled)), 2)
	end

	source = source or Vector3.new()
	drain = drain or Vector3.new()
	color = color or Constants.DEFAULT_COLOR
	topColor = topColor or Constants.DEFAULT_TOP_COLOR
	numArcs = numArcs or Constants.DEFAULT_NUM_ARCS
	fatnessMultiplier = fatnessMultiplier or 1

    local self = setmetatable({}, Arc)

    -- Helper variable, vector offset from source to drain
    local axis = (drain - source)

    self.id = Util.getGlobalId()
    self.cframe = Util.makeOrientation(source, axis) -- Orientation (rotation + position) of source of effect
    self.length = axis.magnitude -- Length of effect between its end points
    self.color = color -- Basis color of the effect
    self.topColor = topColor -- Brightest color that will appear
    self.arc = 1 -- Which arc is being animated (loops)
    self.numArcs = numArcs -- Number of arcs at any time inside the effect
	self.arcRenderAmount = 0 -- Number of arcs left to render in next heartbeat (can be a real value)
	self.fatnessMultiplier = fatnessMultiplier -- multiply the computed fatnesses by this number for this arc
    self.visible = true -- Whether effect is on-screen

	-- Part that all effects are attached to, with a light in it
	local sourcePart = Instance.new("Part")
	sourcePart.Name = Constants.PART_NAME_TEMPLATE:format(self.id)
	sourcePart.Anchored = true
	sourcePart.CanCollide = false
	sourcePart.Locked = true
	sourcePart.Archivable = false
	sourcePart.Transparency = 1
	sourcePart.TopSurface = Enum.SurfaceType.Smooth
	sourcePart.BottomSurface = Enum.SurfaceType.Smooth
	sourcePart.Size = Vector3.new(0.05, 0.05, 0.05)
    sourcePart.CFrame = self.cframe
	self.part = sourcePart

	local emitter = Instance.new("Attachment")
	emitter.Name = "Emitter"
	emitter.CFrame = CFrame.new(self.length/2, 0, 0)
	emitter.Parent = sourcePart

	local emitterLight = Instance.new("PointLight")
	emitterLight.Name = "PointLight"
	emitterLight.Brightness = 5
	emitterLight.Color = Color3.new(0, 0, 0):lerp(color, Constants.LIGHT_COLOR_MODIFIER)
	emitterLight.Range = 0
	emitterLight.Shadows = true
	emitterLight.Enabled = Constants.USE_POINTLIGHT
	emitterLight.Parent = emitter

    -- Preparing a pool of particles to be used for the effect
    self.segments = {}
    self.segmentsFolder = Instance.new("Folder")
    self.segmentsFolder.Name = Constants.SEGMENT_FOLDER_NAME_TEMPLATE:format(self.id)
    for i = 1, (numArcs * Constants.SEGMENT_PER_ARC_MAX) do
        local segment = Instance.new("ImageHandleAdornment", self.segmentsFolder)
        segment.Name = Constants.SEGMENT_NAME_TEMPLATE:format(i)
        segment.Image = Constants.ARC_TEXTURE
        segment.Adornee = self.part
        segment.Size = Vector2.new(0, 0)
        segment.ZIndex = 0
        self.segments[i] = segment
    end

    -- Initialize tables that hold the definitions of the individual (animated) arcs
    self.step = {}
    self.amountSegments = {}
    self.totalSteps = {}
    self.path = {}
	self.brightness = {}

    -- Arc paths
    self.axisKeyPoints0 = {}
    self.axisKeyPoints1 = {}
    self.pathT0 = {}
    self.pathT1 = {}
    for arc = 1, numArcs do
        self.pathT0[arc] = {} -- Starting path t=0
        self.pathT1[arc] = {} -- Ending path t=1
        self.step[arc] = 0
        self.amountSegments[arc] = -1 -- Initially the arc has no defined segment count
    end

	if enabled or (enabled == nil and Constants.DEFAULT_ENABLED) then
		-- Add to system if enabled at creation
		System.add(self)
	end

    return self
end

function Arc.link(source, drain, color, topColor, numArcs, fatnessMultiplier, enabled)
	if typeof(source) ~= "Instance" or not source:IsA("Attachment") then
        error(ERROR_TYPE_FORMAT:format(1, "attach", "Attachment", typeof(source)), 2)
    elseif typeof(drain) ~= "Instance" or not drain:IsA("Attachment") then
        error(ERROR_TYPE_FORMAT:format(2, "attach", "Attachment", typeof(drain)), 2)
    elseif color ~= nil and typeof(color) ~= "Color3" then
        error(ERROR_TYPE_FORMAT:format(3, "attach", "Color3", typeof(color)), 2)
    elseif topColor ~= nil and typeof(topColor) ~= "Color3" then
        error(ERROR_TYPE_FORMAT:format(4, "attach", "Color3", typeof(topColor)), 2)
    elseif numArcs ~= nil and type(numArcs) ~= "number" then
        error(ERROR_TYPE_FORMAT:format(5, "attach", "number", typeof(numArcs)), 2)
    elseif numArcs ~= nil and numArcs < 1 then
        error(ERROR_BAD_ARGUMENT:format(5, "attach", "the number of arcs should be >= 1"), 2)
	elseif enabled ~= nil and type(enabled) ~= "boolean" then
        error(ERROR_TYPE_FORMAT:format(6, "attach", "boolean", typeof(enabled)), 2)
	end

	local self = Arc.new(
		source.WorldPosition,
		drain.WorldPosition,
		color,
		topColor,
		numArcs,
		fatnessMultiplier,
		false
	)
	self.dynamic = true
	self.source = source
	self.drain = drain

	if enabled or (enabled == nil and Constants.DEFAULT_ENABLED) then
		-- Add to system if enabled at creation now that self.dynamic is set
		System.add(self)
	end

	return self
end

-- Aliases
Arc.New = Arc.new
Arc.Link = Arc.link

return Arc