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
    shaders = {},
    sounds = {}
}

function Assets.load()
    -- Load fonts
    Assets.fonts.astlochTitleFont = love.graphics.newFont("assets/fonts/Astloch/Astloch-Bold.ttf", 64)
    Assets.fonts.astlochMenuFont = love.graphics.newFont("assets/fonts/Astloch/Astloch-Regular.ttf", 32)
    Assets.fonts.astlochBodyFont = love.graphics.newFont("assets/fonts/Astloch/Astloch-Regular.ttf", 32) -- Using regular for body text
    Assets.fonts.hostGroteskRegular = love.graphics.newFont("assets/fonts/Host_Grotesk/static/HostGrotesk-Regular.ttf", 16)
    -- Load character sprites
    Assets.sprites.player = love.graphics.newImage("assets/sprites/characters/player.png")
    Assets.sprites.wild_canid = love.graphics.newImage("assets/sprites/characters/wild_canid.png")
    Assets.sprites.rat = love.graphics.newImage("assets/sprites/characters/rat.png")
    Assets.sprites.guard = love.graphics.newImage("assets/sprites/characters/guard.png")
    Assets.sprites.watchman = love.graphics.newImage("assets/sprites/characters/watchman.png")



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

    -- Load manor grounds atlas and create individual tile quads
    local groundsAtlas = love.graphics.newImage("assets/tiles/manor-grounds.png")
    Assets.sprites.grounds_atlas = groundsAtlas
    Assets.sprites.grounds_floor_tiles = {}
    Assets.sprites.grounds_hedge_tiles = {}
    local grounds_tile_size = 32
    -- First 12 tiles (row 1 and first 4 of row 2) are floors
    for i = 0, 11 do
        local x = (i % 8) * grounds_tile_size
        local y = math.floor(i / 8) * grounds_tile_size
        table.insert(Assets.sprites.grounds_floor_tiles, love.graphics.newQuad(x, y, grounds_tile_size, grounds_tile_size, groundsAtlas:getDimensions()))
    end
    -- Last 4 tiles of the second row are hedges
    for i = 0, 3 do
        table.insert(Assets.sprites.grounds_hedge_tiles, love.graphics.newQuad((4 + i) * grounds_tile_size, grounds_tile_size, grounds_tile_size, grounds_tile_size, groundsAtlas:getDimensions()))
    end

    -- Load sewers atlas and create individual tile quads
    local sewersAtlas = love.graphics.newImage("assets/tiles/sewers.png")
    Assets.sprites.sewers_atlas = sewersAtlas
    Assets.sprites.sewers_wall_tiles = {}
    Assets.sprites.sewers_floor_tiles = {}
    local sewers_tile_size = 32
    -- First 11 tiles are walls
    for i = 0, 10 do
        local x = (i % 7) * sewers_tile_size
        local y = math.floor(i / 7) * sewers_tile_size
        table.insert(Assets.sprites.sewers_wall_tiles, love.graphics.newQuad(x, y, sewers_tile_size, sewers_tile_size, sewersAtlas:getDimensions()))
    end
    -- The remaining 17 tiles are floors
    for i = 11, 27 do
        local x = (i % 7) * sewers_tile_size
        local y = math.floor(i / 7) * sewers_tile_size
        table.insert(Assets.sprites.sewers_floor_tiles, love.graphics.newQuad(x, y, sewers_tile_size, sewers_tile_size, sewersAtlas:getDimensions()))
    end

    -- Load music
    Assets.music.theme = love.audio.newSource("assets/music/gospodintheme.wav", "stream")
    Assets.music.theme:setVolume(0.5)
    Assets.music.village = love.audio.newSource("assets/music/gospodin-village.wav", "stream")
    Assets.music.village:setVolume(0)
    Assets.music.village:setLooping(true)
    Assets.music.sewers = love.audio.newSource("assets/music/gospodin-sewers.wav", "stream")
    Assets.music.sewers:setVolume(0)
    Assets.music.sewers:setLooping(true)
    -- You can add more level-specific tracks here
    -- Assets.music.manor = love.audio.newSource("assets/music/gospodin-manor.wav", "stream")

    -- Load shaders
    Assets.shaders.fog = love.graphics.newShader("assets/shaders/fog.glsl")

    -- Load sound effects
    Assets.sounds.bark = love.audio.newSource("assets/sounds/bark.wav", "static")
    Assets.sounds.daughter_attack = love.audio.newSource("assets/sounds/daughter-attack.wav", "static")
    Assets.sounds.dweller_attack = love.audio.newSource("assets/sounds/dweller-attack.wav", "static")
    Assets.sounds.patriarch_roar = love.audio.newSource("assets/sounds/patriarch-roar.wav", "static")
    Assets.sounds.chitter = love.audio.newSource("assets/sounds/chitter.wav", "static")
    Assets.sounds.masc_attack = love.audio.newSource("assets/sounds/masc-attack.wav", "static")
    Assets.sounds.masc_death = love.audio.newSource("assets/sounds/masc-death.wav", "static")
    Assets.sounds.long_death = love.audio.newSource("assets/sounds/long-death.wav", "static")
    Assets.sounds.creature_death = love.audio.newSource("assets/sounds/creature-death.wav", "static")

    -- Set initial volumes
    Assets.masterVolume = 0.5
    Assets.musicVolume = 0.5
    Assets.sfxVolume = 0.5

    love.audio.setVolume(Assets.masterVolume)

    Assets.setMusicVolume = function(volume)
        Assets.musicVolume = volume
        Assets.music.theme:setVolume(Assets.musicVolume * Assets.masterVolume)
        Assets.music.village:setVolume(Assets.musicVolume * Assets.masterVolume)
        Assets.music.sewers:setVolume(Assets.musicVolume * Assets.masterVolume)
    end

    Assets.setMasterVolume = function(volume)
        Assets.masterVolume = volume
        love.audio.setVolume(Assets.masterVolume)
        Assets.setMusicVolume(Assets.musicVolume) -- Update music volume based on master volume
        -- You might need to adjust individual sound effect volumes here if you want them relative to the master volume
    end

    Assets.setMusicVolume(Assets.musicVolume)


end

return Assets