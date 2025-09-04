function love.conf(t)
    -- Basic game info
    t.title = "Gospodin"              -- Window title (shows in title bar)
    t.author = "Skeinguard Gameworks"               -- Author name (for metadata)
    t.url = "https://your-website.com"   -- Website URL (optional)
    t.identity = "gosopdin"           -- Save directory name (important for save files!)
    t.version = "11.4"                   -- Love2D version this game targets
    t.console = true                   -- Enable console window (Windows only, useful for debugging)
    t.accelerometerjoystick = true       -- Enable accelerometer on mobile
    t.externalstorage = false            -- Enable external storage on Android
    t.gammacorrect = false               -- Enable gamma-correct rendering
    
    -- Window settings
    t.window.title = "Catch///Release"       -- Window title (can be different from t.title)
    t.window.icon = nil                  -- Window icon file path (e.g., "assets/images/icon.png")
    t.window.width = 1024                -- Window width in pixels
    t.window.height = 768                -- Window height in pixels
    t.window.borderless = false          -- Remove window borders
    t.window.resizable = true            -- Allow window resizing
    t.window.minwidth = 800              -- Minimum window width
    t.window.minheight = 600             -- Minimum window height
    t.window.fullscreen = false          -- Start in fullscreen mode
    t.window.fullscreentype = "desktop"  -- "desktop" or "exclusive"
    t.window.vsync = 1                   -- Enable vsync (0=off, 1=on, -1=adaptive)
    t.window.msaa = 0                    -- Multisample anti-aliasing samples (0, 2, 4, 8, 16)
    t.window.depth = nil                 -- Depth buffer bits (8, 16, 24)
    t.window.stencil = nil               -- Stencil buffer bits (8)
    t.window.display = 1                 -- Monitor to display on (1=primary)
    t.window.highdpi = false             -- Enable high-DPI mode
    t.window.usedpiscale = true          -- Enable automatic DPI scaling
    t.window.x = nil                     -- Window x position (nil=centered)
    t.window.y = nil                     -- Window y position (nil=centered)
    
    -- Module configuration
    -- Set to false to disable modules you don't need (can improve startup time)
    t.modules.audio = true               -- Audio system (music and sound effects)
    t.modules.data = true                -- Data module (Base64, compression, etc.)
    t.modules.event = true               -- Event handling (required)
    t.modules.font = true                -- Font rendering
    t.modules.graphics = true            -- Graphics rendering (required for visual games)
    t.modules.image = true               -- Image loading
    t.modules.joystick = true            -- Gamepad/joystick support
    t.modules.keyboard = true            -- Keyboard input
    t.modules.math = true                -- Math utilities
    t.modules.mouse = true               -- Mouse input
    t.modules.physics = true             -- Box2D physics (set to false if not using physics)
    t.modules.sound = true               -- Sound system
    t.modules.system = true              -- System information
    t.modules.thread = true              -- Threading support (useful for loading)
    t.modules.timer = true               -- Timer functions (delta time, etc.)
    t.modules.touch = true               -- Touch input (mobile)
    t.modules.video = true               -- Video playback (set to false if not using videos)
    t.modules.window = true              -- Window management (required)
    
    -- Development settings (you might want to change these during development)
    if love.filesystem.getInfo("DEBUG") then
        t.console = true                 -- Show console in debug mode
        t.window.vsync = 0               -- Disable vsync for better debugging
    end
end