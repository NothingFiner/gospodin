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

    -- Load music
    Assets.music.theme = love.audio.newSource("assets/music/gospodintheme.wav", "stream")
    Assets.music.theme:setVolume(0.5)

end

return Assets