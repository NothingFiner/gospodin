-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/assets.lua

local Assets = {
    fonts = {
        astlochTitleFont = nil,
        astlochMenuFont = nil,
        hostGroteskRegular = nil,
        -- This was missing, but is used in GameOver and Victory states.
        astlochBodyFont = nil 
    },
    sprites = {},
    music = {},
    shaders = {}
}

function Assets.load()
    -- Load fonts
    Assets.fonts.astlochTitleFont = love.graphics.newFont("assets/fonts/Astloch/Astloch-Bold.ttf", 64)
    Assets.fonts.astlochMenuFont = love.graphics.newFont("assets/fonts/Astloch/Astloch-Regular.ttf", 32)
    Assets.fonts.astlochBodyFont = love.graphics.newFont("assets/fonts/Astloch/Astloch-Regular.ttf", 32) -- Using regular for body text
    Assets.fonts.hostGroteskRegular = love.graphics.newFont("assets/fonts/Host_Grotesk/static/HostGrotesk-Regular.ttf", 16)
    -- Load character sprites
    Assets.sprites.player = love.graphics.newImage("assets/sprites/characters/player.png")

    -- Load tile sprites
    Assets.sprites.manor_stairs_up = love.graphics.newImage("assets/tiles/manor-stairs-up.png")
    Assets.sprites.manor_stairs_down = love.graphics.newImage("assets/tiles/manor-stairs-down.png")
    Assets.sprites.village_floor = love.graphics.newImage("assets/tiles/village-floor.png")
    Assets.sprites.village_floor_1 = love.graphics.newImage("assets/tiles/village-floor-1.png")
    Assets.sprites.village_floor_2 = love.graphics.newImage("assets/tiles/village-floor-2.png")
    Assets.sprites.village_floor_3 = love.graphics.newImage("assets/tiles/village-floor-3.png")
    Assets.sprites.village_to_sewers = love.graphics.newImage("assets/tiles/village-to-sewers.png")

    -- Load decorative sprites
    local rugAtlas = love.graphics.newImage("assets/sprites/rugs-2x.png")
    Assets.sprites.rug_atlas = rugAtlas

    -- Original 1x coordinates for the 256x256 sheet
    local rugCoords1x = {
        rug_1 = {1, 1, 96, 126},
        rug_2 = {97, 1, 62, 96},
        rug_3 = {161, 1, 67, 46},
        runner_1 = {230, 1, 20, 71},
        rug_5_circ = {97, 97, 63, 30},
        rug_6_circ = {161, 49, 68, 65}, -- Slightly reduced dimensions for better fitting
        rug_7 = {1, 128, 63, 87},
        rug_8 = {65, 130, 69, 67},
        runner_2 = {137, 128, 25, 103},
        rug_10 = {162, 129, 66, 69},
    }

    Assets.sprites.rugs = {}
    local scale = 2 -- The new atlas is 2x the size
    local border = 1 * scale -- The border is also scaled

    for name, coords in pairs(rugCoords1x) do
        local x, y, w, h = unpack(coords)
        Assets.sprites.rugs[name] = love.graphics.newQuad(
            (x * scale) + border, 
            (y * scale) + border, 
            (w * scale) - (border * 2), 
            (h * scale) - (border * 2), 
            rugAtlas:getDimensions()
        )
    end

    -- Load manor hardwood floor atlas and create individual tile quads
    local hardwoodAtlas = love.graphics.newImage("assets/tiles/manor-hardwood.png")
    Assets.sprites.manor_hardwood_atlas = hardwoodAtlas
    Assets.sprites.manor_hardwood_tiles = {}
    local tile_size = 32
    local atlas_width, atlas_height = hardwoodAtlas:getDimensions()
    for y = 0, (atlas_height / tile_size) - 1 do
        for x = 0, (atlas_width / tile_size) - 1 do
            local quad = love.graphics.newQuad(x * tile_size, y * tile_size, tile_size, tile_size, atlas_width, atlas_height)
            table.insert(Assets.sprites.manor_hardwood_tiles, quad)
        end
    end

    -- Load music
    Assets.music.theme = love.audio.newSource("assets/music/gospodintheme.wav", "stream")
    Assets.music.theme:setVolume(0.5)

    -- Load shaders
    Assets.shaders.fog = love.graphics.newShader("assets/shaders/fog.glsl")

end

return Assets