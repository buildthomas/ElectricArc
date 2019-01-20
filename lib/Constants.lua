return {

	DEFAULT_SOURCE_POS = Vector3.new(-5, 0, 0);     -- Starting position of arcs
	DEFAULT_DRAIN_POS = Vector3.new(5, 0, 0);       -- Ending position of arcs
	DEFAULT_COLOR = Color3.new(0.4, 0.8, 1);        -- The darkest color of arcs
	DEFAULT_TOP_COLOR = Color3.new(1, 1, 1);        -- The brightest color of arcs
	DEFAULT_NUM_ARCS = 6;                           -- Default number of arcs
	DEFAULT_ENABLED = true;                         -- Whether enabled at creation

	ARC_TEXTURE = "rbxassetid://750609714";         -- White texture of an arc segment (glowing line)

	PARTICLE_LIGHT_EMISSION = 1;                    -- Background particle beam properties
	PARTICLE_LIGHT_INFLUENCE = 0;
	PARTICLE_SIZE_MODIFIER = 0.15;
	PARTICLE_COLOR_MODIFIER = 0.15;
	PARTICLE_TEXTURE = "rbxassetid://712446122";
	PARTICLE_TRANSPARENCY = 0.98;

	LIGHT_COLOR_MODIFIER = 0.8;                     -- Background light properties

	SPARKS_MAIN_FOLDER = "SparksParticles";         -- Name of particle and basepart storage in PlayerGui/workspace

	PARTFOLDER_NAME_TEMPLATE = "sparks_%05d";       -- Name format of storage of parts
	SEGMENT_NAME_TEMPLATE = "segment_%05d";         -- Name format of individual particles

	AUTO_THROTTLE_FRAME_INTERVAL = 0.500;           -- Interval in seconds over which FPS is calculated for auto-throttling
	AUTO_THROTTLE_INCREMENT = 0.05;                 -- Increment of arc update rate per up/down-throttle
	AUTO_THROTTLE_TARGET = 55;                      -- FPS to target for auto-throttling

	THROTTLE_DISTANCE_MODIFIER_MIN = 20;            -- Minimum for throttle distance modifier
	THROTTLE_DISTANCE_MODIFIER_MAX = 100;           -- Maximum for throttle distance modifier
	-- Lower value = faster drop-off on update rate depending on distance = better performance

	SEGMENT_PER_ARC_MIN = 4;                        -- Minimum number of segments per arc
	SEGMENT_PER_ARC_MAX = 20;                       -- Maximum number of segments per arc

	SEGMENT_THROTTLING_DISTANCE = 100;              -- Distance after which # of segments per arc will start throttling

	MAX_DISTANCE = 1000;                            -- Distance from camera after which no further updating occurs

	ARCS_PER_UPDATE = 2;                            -- How many arcs to update per sparks instance

	TWEEN_STEPS_MIN = 2;                            -- Minimum number of tween steps. Cannot be less than 2
	TWEEN_STEPS_MAX = 4;                            -- When an arc has >2 steps, it lerps between path1 and path2

	SEGMENT_MINMAX_RATIO = 24;                      -- Range of arc segment length, as ratio max:min
	                                                -- (ratio is actually this + 1, so 25)

	SEGMENT_ANGULAR_CHANGE_MAX = 0.15 * math.pi;    -- How much an arc segment can rotate about the axis from start to end

	RARE_CHANCE = 0.025;                            -- Chance of an arc being a very long duration, extra fat wandering arc
	RARE_CHANCE_DURATION_MULT = 3;                  -- How much longer rare fat arcs last compared to typical duration

}