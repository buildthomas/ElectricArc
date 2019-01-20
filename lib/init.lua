local Arc = {}
Arc.__index = Arc

local Util = require(script.Util)
local Constants = require(script.Constants)
local System = require(script.System)

local ERROR_TYPE_FORMAT = "bad argument #%d to '%s' (%s expected, got %s)" -- Error format for type errors
local ERROR_BAD_ARGUMENT = "bad argument #%d to '%s' (%s)" -- Generic bad argument error format

-- Shorthands
local cframe = CFrame.new
local color3 = Color3.new
local colorBlack = color3(0, 0, 0)
local cross = Vector3.new().Cross

function Arc:SetEnabled(value)
	if value then
		System.add(self)
	else
		System.remove(self)
	end
end

function Arc:SetCFrame(cfr)
    self.cframe = cfr
    self.changed = true
end

function Arc:GetCFrame()
    return self.cframe
end

function Arc:Translate(vector)
    self.cframe = self.cframe + vector
    self.changed = true
end

function Arc:Transform(transformation)
    self.cframe = self.cframe * transformation
    self.changed = true
end

function Arc:GetRange()
    return self.cframe.p, self.cframe * Vector3.new(self.length, 0, 0)
end

function Arc:SetRange(source, drain)
    local axis = drain - source
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

function Arc:Destroy()
    -- Remove self from system
    System.remove(self)

    -- Destroying instances
    self.partFolder:Destroy()
    self.segmentsFolder:Destroy()
end

function Arc:RealignToCamera()
    local relativeCamPos = self.cframe:inverse() * workspace.CurrentCamera.CFrame.p
    for _, v in pairs(self.segments) do
        local c = v.CFrame
        local po = c.p
        local up = c.upVector
        local lf = cross(relativeCamPos - po, up).unit
        local fr = cross(lf, up).unit
        v.CFrame = cframe(po.x, po.y, po.z, lf.x, up.x, fr.x, lf.y, up.y, fr.y, lf.z, up.z, fr.z)
    end
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
    elseif numArcs < 1 then
        error(ERROR_BAD_ARGUMENT:format(5, "new", "the number of arcs should be >= 1"), 2)
	elseif enabled ~= nil and type(enabled) ~= "boolean" then
        error(ERROR_TYPE_FORMAT:format(6, "new", "boolean", typeof(enabled)), 2)
	end

	source = source or Constants.DEFAULT_SOURCE_POS
	drain = drain or Constants.DEFAULT_DRAIN_POS
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
	emitterPart.CFrame = cframe((drain + source) / 2, source)
	emitterPart.Parent = self.partFolder

	local emitterEffect = Instance.new("ParticleEmitter")
	emitterEffect.Name = "ParticleEmitter"
	emitterEffect.Color = ColorSequence.new(colorBlack:lerp(color, Constants.PARTICLE_COLOR_MODIFIER))
	emitterEffect.LightEmission = Constants.PARTICLE_LIGHT_EMISSION
	emitterEffect.LightInfluence = Constants.PARTICLE_LIGHT_INFLUENCE
	emitterEffect.Size = NumberSequence.new(self.length * Constants.PARTICLE_SIZE_MODIFIER)
	emitterEffect.Texture = Constants.PARTICLE_TEXTURE
	emitterEffect.Transparency = NumberSequence.new(Constants.PARTICLE_TRANSPARENCY)
	emitterEffect.Parent = emitterPart

	local emitterLight = Instance.new("PointLight")
	emitterLight.Name = "PointLight"
	emitterLight.Brightness = 10
	emitterLight.Color = colorBlack:lerp(color, Constants.LIGHT_COLOR_MODIFIER)
	emitterLight.Range = 60
	emitterLight.Shadows = false
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

Arc.New = Arc.new -- Alias

return Arc