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
    self.partFolder:Destroy()
    self.segmentsFolder:Destroy()
end

function Arc.new(source, drain, color, topColor, numArcs, enabled)
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
        error(ERROR_BAD_ARGUMENT:format(5, "new", "the number of arcs should be >= 1"), 2)
	elseif enabled ~= nil and type(enabled) ~= "boolean" then
        error(ERROR_TYPE_FORMAT:format(6, "new", "boolean", typeof(enabled)), 2)
	end

	source = source or Vector3.new()
	drain = drain or Vector3.new()
	color = color or Constants.DEFAULT_COLOR
	topColor = topColor or Constants.DEFAULT_TOP_COLOR
	numArcs = numArcs or Constants.DEFAULT_NUM_ARCS

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
    self.visible = true -- Whether effect is on-screen

	-- Folder object in Camera to store part instances in
	self.partFolder = Instance.new("Model")
	self.partFolder.Name = Constants.PARTFOLDER_NAME_TEMPLATE:format(self.id)

	local sourcePart = Instance.new("Part")
	sourcePart.Name = "Source"
	sourcePart.Anchored = true
	sourcePart.CanCollide = false
	sourcePart.Locked = true
	sourcePart.Archivable = false
	sourcePart.Transparency = 1
	sourcePart.TopSurface = Enum.SurfaceType.Smooth
	sourcePart.BottomSurface = Enum.SurfaceType.Smooth
	sourcePart.Size = Vector3.new(0.05, 0.05, 0.05)
    sourcePart.CFrame = self.cframe
	sourcePart.Parent = self.partFolder

	local emitterPart = Instance.new("Part")
	emitterPart.Name = "Emitter"
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.Locked = true
	emitterPart.Archivable = false
	emitterPart.Transparency = 1
	emitterPart.TopSurface = Enum.SurfaceType.Smooth
	emitterPart.BottomSurface = Enum.SurfaceType.Smooth
	emitterPart.Size = Vector3.new(0.2, 0.2, self.length)
	emitterPart.CFrame = CFrame.new((drain + source) / 2, source)
	emitterPart.Parent = self.partFolder

	local emitterEffect = Instance.new("ParticleEmitter")
	emitterEffect.Name = "ParticleEmitter"
	emitterEffect.Color = ColorSequence.new(Color3.new(0, 0, 0):lerp(color, Constants.PARTICLE_COLOR_MODIFIER))
	emitterEffect.LightEmission = Constants.PARTICLE_LIGHT_EMISSION
	emitterEffect.LightInfluence = Constants.PARTICLE_LIGHT_INFLUENCE
	emitterEffect.Size = NumberSequence.new(self.length * Constants.PARTICLE_SIZE_MODIFIER)
	emitterEffect.Texture = Constants.PARTICLE_TEXTURE
	emitterEffect.Transparency = NumberSequence.new(Constants.PARTICLE_TRANSPARENCY)
	emitterEffect.Parent = emitterPart

	local emitterLight = Instance.new("PointLight")
	emitterLight.Name = "PointLight"
	emitterLight.Brightness = 5
	emitterLight.Color = Color3.new(0, 0, 0):lerp(color, Constants.LIGHT_COLOR_MODIFIER)
	emitterLight.Range = 0
	emitterLight.Shadows = true
	emitterLight.Enabled = Constants.USE_POINTLIGHT
	emitterLight.Parent = emitterPart

    -- Preparing a pool of particles to be used for the effect
    self.segments = {}
    self.segmentsFolder = Instance.new("Folder")
    self.segmentsFolder.Name = Constants.PARTFOLDER_NAME_TEMPLATE:format(self.id)
    for i = 1, (numArcs * Constants.SEGMENT_PER_ARC_MAX) do
        local segment = Instance.new("ImageHandleAdornment", self.segmentsFolder)
        segment.Name = Constants.SEGMENT_NAME_TEMPLATE:format(i)
        segment.Image = Constants.ARC_TEXTURE
        segment.Adornee = self.partFolder.Source
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

function Arc.link(source, drain, color, topColor, numArcs, enabled)
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

	local self = Arc.new(source.WorldPosition, drain.WorldPosition, color, topColor, numArcs, false)
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