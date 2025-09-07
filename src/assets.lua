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

    -- Load music
    Assets.music.theme = love.audio.newSource("assets/music/gospodintheme.wav", "stream")
    Assets.music.theme:setVolume(0.5)

end

return Assets