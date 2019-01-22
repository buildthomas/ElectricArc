# Electric Arcs

This is an implementation of an electric arc effect for Roblox games.

Courtesy of user @AllYourBlox for the original implementation of the algorithm that produces the line segments for the arcs ([click here](https://devforum.roblox.com/t/electric-arc-demo-with-rbxls/35433)). The original code has been modularized and optimized for ease of use and more widely applicable use.

The original code manipulated many neon parts every frame which was not optimal due to the work it takes for the engine to update the position and size of baseparts. This version draws the line segments that represent the arcs through ImageHandleAdornments with the texture of a glowing line segment. Please note that this is still somewhat on the performance-heavy side and may be an overkill kind of implementation for such an electricity effect, but the library does include auto-throttling and other tricks to make sure the frame rate stays as high as possible and no effort is wasted updating effects that are far away compared to those closeby.

# Showcase

See here for a visual example:

https://gfycat.com/ConcernedPersonalHammerkop

## Downloads

A model file and example place can be downloaded through the following Developer Forum thread (if you would prefer not to work from source):

https://devforum.roblox.com/t/release-electric-arcs-effect/228413

# Usage

The following listing shows how some of the most important API is used to make the effects happen in a game.

```lua

local Arc = require(game.(...).Arc)

-- Make an arc between two static points with default colors:
local arc1 = Arc.new(
    Vector3.new(10, 10, 0),
    Vector3.new(-10, 10, 0)
)

-- Make a dynamic arc linked between two (moving) attachments:
local arc2 = Arc.link(
    workspace.ArcStart.Attachment,
    workspace.ArcEnd.Attachment
)

-- Make an arc that is green:
local arc3 = Arc.new(
    Vector3.new(10, 10, 0),
    Vector3.new(-10, 10, 0),
    Color3.new(0, 1, 0)
)

-- Make a blue one with 12 arcs (instead of default 6) with segments that are half as wide as normal:
local arc4 = Arc.new(
    Vector3.new(10, 10, 0),
    Vector3.new(-10, 10, 0),
    Color3.new(.5, .5, 1)       -- cyan
    Color3.new(1, 1, 1),        -- top color (not important here)
    12,                         -- number of arcs
    0.5                         -- fatness multiplier (half of normal)
)

-- Change various properties while it is running:
arc1:SetColor(Color3.new(1, 0, 0)) -- make it red
arc1:SetRange(Vector3.new(20, 10, 0), Vector3.new(-20, 10, 0)) -- update points
arc2:SetEnabled(false) -- toggle off temporarily
arc3:SetCFrame(arc3:GetCFrame() + Vector3.new(0, 5, 0)) -- move up by 5 studs
arc4:SetFatnessMultiplier(2) -- twice as fat as default now

-- Cleanup arcs:
arc1:Destroy()
arc2:Destroy()
arc3:Destroy()
arc4:Destroy()
```

# API Listing

This section lists the entire API that is available through this library.

## Constructors

These methods will return an Arc object that can be manipulated further with the rest of the API.

```text
<ArcObject> Arc.new(
    Vector3 source = Vector3.new(),       -- start
    Vector3 drain = Vector3.new(),        -- end
    Color3 basisColor = DEFAULT_COLOR,    -- darkest color
    Color3 topColor = DEFAULT_TOP_COLOR,  -- brightest color
    number numArcs = DEFAULT_NUM_ARCS,    -- amount of separate arcs at once
    number fatnessMultiplier = 1,         -- make the segments of this arc thinner/thicker
    bool enabled = DEFAULT_ENABLED        -- start out enabled?
)

Arc.New => Alias for Arc.new
```

```text
<ArcObject> Arc.link(
    Attachment source,            -- static or moving attachment for start
    Attachment sink,              -- static or moving attachment for end
    Color3 basisColor = DEFAULT_COLOR,
    Color3 topColor = DEFAULT_TOP_COLOR,
    number numArcs = DEFAULT_NUM_ARCS,
    number fatnessMultiplier = 1,
    bool enabled = DEFAULT_ENABLED
)

Arc.Link => Alias for Arc.link
```

## Updating properties of Arc objects

```text
<bool> ArcObject:GetEnabled()

Whether effect is visible.
```

```text
ArcObject:SetEnabled(
    bool enabled
)

Set visibility of the effect.
```

```text
<CFrame> ArcObject:GetCFrame()

Get orientation of source (= start) of the effect.
```

```text
ArcObject:SetCFrame(
    CFrame cframe
)

Set orientation of source (= start) of an effect created through Arc.new (not Arc.link).
```

```text
<Vector3, Vector3> ArcObject:GetRange()

Returns the two current points that the effect is between.
```

```text
ArcObject:SetRange(
    Vector3 source,
    Vector3 drain
)

Updates an effect created through Arc.new (not Arc.link) to be between the two given points.
```

```text
<Color3> ArcObject:GetColor()
```

```text
ArcObject:SetColor(
    Color3 color
)
```

```text
<Color3> ArcObject:GetTopColor()
```

```text
ArcObject:SetTopColor(
    Color3 topColor
)
```

```text
<number> ArcObject:GetNumberOfArcs()
```

```text
<number> ArcObject:GetFatnessMultiplier()
```

```text
ArcObject:SetFatnessMultiplier(
    number topColor
)
```

## Destructor

```text
ArcObject:Destroy()

Will stop and clean up the effect.
```

# License

This library is freely available for use in your projects under the MIT license.

Credit to @AllYourBlox for open-sourcing the algorithm that produces the line segments for the arcs, which was edited and optimized for this implementation.