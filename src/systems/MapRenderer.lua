-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/MapRenderer.lua
-- This module is responsible for all world-rendering logic.

local Game = require('src.Game')
local config = require('src.config')
local Assets = require('src.assets')

local MapRenderer = {}

-- === Map Drawing Dispatch Tables ===
-- This data-driven approach replaces complex if/else chains in the draw loop.

local defaultMapDrawer = {
    drawFloor = function(colors, visibility, screenX, screenY)
        local r, g, b = unpack(colors.floor)
        love.graphics.setColor(r * visibility, g * visibility, b * visibility)
        love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
    end,
    drawWall = function(colors, visibility, screenX, screenY)
        local r, g, b = unpack(colors.wall)
        love.graphics.setColor(r * visibility, g * visibility, b * visibility)
        love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
    end,
    drawDownStair = function(colors, visibility, screenX, screenY, tileData, getCenteredOffsets)
        local char = ">"
        local ox, oy = getCenteredOffsets(char)
        love.graphics.setColor(visibility, visibility, visibility)
        love.graphics.print(char, screenX + ox, screenY + oy)
    end,
    drawUpStair = function(colors, visibility, screenX, screenY, tileData, getCenteredOffsets)
        local char = "<"
        local ox, oy = getCenteredOffsets(char)
        love.graphics.setColor(visibility, visibility, visibility)
        love.graphics.print(char, screenX + ox, screenY + oy)
    end
}

local manorMapDrawer = {
    drawFloor = function(colors, visibility, screenX, screenY, tileData)
        local tileSprite = Assets.sprites.manor_hardwood_tiles[tileData.variant]
        if tileSprite then
            love.graphics.setColor(visibility, visibility, visibility)
            love.graphics.draw(Assets.sprites.manor_hardwood_atlas, tileSprite, screenX, screenY)
        else
            defaultMapDrawer.drawFloor(colors, visibility, screenX, screenY)
        end
    end,
    drawWall = defaultMapDrawer.drawWall, -- Manor uses default walls
    drawDownStair = function(colors, visibility, screenX, screenY, tileData)
        local rotation = (type(tileData) == "table" and tileData.rotation) or 0
        love.graphics.setColor(visibility, visibility, visibility)
        love.graphics.draw(Assets.sprites.manor_stairs_down, screenX + 16, screenY + 16, rotation, 1, 1, 16, 16)
    end,
    drawUpStair = function(colors, visibility, screenX, screenY, tileData)
        local rotation = (type(tileData) == "table" and tileData.rotation) or 0
        love.graphics.setColor(visibility, visibility, visibility)
        love.graphics.draw(Assets.sprites.manor_stairs_up, screenX + 16, screenY + 16, rotation, 1, 1, 16, 16)
    end
}

local villageMapDrawer = {
    drawFloor = function(colors, visibility, screenX, screenY, tileData)
        local tileSprite
        if tileData.variant == 1 then tileSprite = Assets.sprites.village_floor
        elseif tileData.variant == 2 then tileSprite = Assets.sprites.village_floor_1
        elseif tileData.variant == 3 then tileSprite = Assets.sprites.village_floor_2
        elseif tileData.variant == 4 then tileSprite = Assets.sprites.village_floor_3
        end
        if tileSprite then
            love.graphics.setColor(visibility, visibility, visibility)
            love.graphics.draw(tileSprite, screenX, screenY)
        else
            defaultMapDrawer.drawFloor(colors, visibility, screenX, screenY)
        end
    end,
    drawWall = defaultMapDrawer.drawWall, -- Village uses default walls
    drawDownStair = function(colors, visibility, screenX, screenY, tileData)
        love.graphics.setColor(visibility, visibility, visibility)
        love.graphics.draw(Assets.sprites.village_to_sewers, screenX, screenY)
    end,
    drawUpStair = defaultMapDrawer.drawUpStair -- Village uses default up stairs
}

local groundsMapDrawer = {
    drawFloor = defaultMapDrawer.drawFloor, -- Grounds uses default floor
    drawFloor = function(colors, visibility, screenX, screenY, tileData)
        local tileSprite = Assets.sprites.grounds_floor_tiles[tileData.variant]
        if tileSprite then
            love.graphics.setColor(visibility, visibility, visibility)
            love.graphics.draw(Assets.sprites.grounds_atlas, tileSprite, screenX, screenY)
        else
            defaultMapDrawer.drawFloor(colors, visibility, screenX, screenY)
        end
    end,
    drawWall = function(colors, visibility, screenX, screenY, tileData)
        local hedgeSprite = Assets.sprites.grounds_hedge_tiles[tileData.variant]
        if hedgeSprite then
            love.graphics.setColor(visibility, visibility, visibility)
            love.graphics.draw(Assets.sprites.grounds_atlas, hedgeSprite, screenX, screenY)
        else
            defaultMapDrawer.drawWall(colors, visibility, screenX, screenY)
        end
    end
}
-- Grounds uses the default stair drawing functions
groundsMapDrawer.drawDownStair, groundsMapDrawer.drawUpStair = defaultMapDrawer.drawDownStair, defaultMapDrawer.drawUpStair

local sewerMapDrawer = {
    drawFloor = function(colors, visibility, screenX, screenY, tileData)
        local tileSprite = Assets.sprites.sewers_floor_tiles[tileData.variant]
        if tileSprite then
            love.graphics.setColor(visibility, visibility, visibility)
            love.graphics.draw(Assets.sprites.sewers_atlas, tileSprite, screenX, screenY)
        else
            defaultMapDrawer.drawFloor(colors, visibility, screenX, screenY)
        end
    end,
    drawWall = function(colors, visibility, screenX, screenY, tileData)
        local tileSprite = Assets.sprites.sewers_wall_tiles[tileData.variant]
        if tileSprite then
            love.graphics.setColor(visibility, visibility, visibility)
            love.graphics.draw(Assets.sprites.sewers_atlas, tileSprite, screenX, screenY)
        else
            defaultMapDrawer.drawWall(colors, visibility, screenX, screenY)
        end
    end
}
sewerMapDrawer.drawDownStair, sewerMapDrawer.drawUpStair = defaultMapDrawer.drawDownStair, defaultMapDrawer.drawUpStair

function MapRenderer.draw(playingState, mapX, mapY)
    local font = love.graphics.getFont()
    local function getCenteredOffsets(char)
        local charWidth = font:getWidth(char)
        local charHeight = font:getHeight()
        local offsetX = (Game.tileSize - charWidth) / 2
        local offsetY = (Game.tileSize - charHeight) / 2
        return offsetX, offsetY
    end

	-- 1. Draw the world (map and entities)
	if Game.floors[Game.currentFloor] then
		-- Existing Tile-Based Rendering Path
		local map = Game.floors[Game.currentFloor].map
		local floorInfo = config.floorData[Game.currentFloor]

		-- Select the correct drawing table based on the level's generator
		local activeMapDrawer = defaultMapDrawer
		if floorInfo.generator == "manor" then activeMapDrawer = manorMapDrawer
		elseif floorInfo.generator == "village" then activeMapDrawer = villageMapDrawer
		elseif floorInfo.generator == "grounds" then activeMapDrawer = groundsMapDrawer
		elseif floorInfo.generator == "sewers" then activeMapDrawer = sewerMapDrawer
		end

		-- This table maps tile types to the function that should draw them.
		local tileDrawers = {
			[0] = activeMapDrawer.drawWall,
			[1] = activeMapDrawer.drawFloor,
			[2] = activeMapDrawer.drawDownStair,
			[3] = activeMapDrawer.drawUpStair,
			[4] = function(colors, visibility, screenX, screenY, tileData) -- Special case for Town Square
				local r, g, b = unpack(colors.town_square or colors.floor)
				love.graphics.setColor(r * visibility, g * visibility, b * visibility)
				love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
			end
		}

		-- Draw map tiles
		for y = 1, Game.mapHeight do
			for x = 1, Game.mapWidth do
				local isExplored = Game.floors[Game.currentFloor].exploredMap[y] and Game.floors[Game.currentFloor].exploredMap[y][x]
				
				if isExplored then
					local screenX = mapX + (x - Game.camera.x) * Game.tileSize
					local screenY = mapY + (y - Game.camera.y) * Game.tileSize
					local visibility = (Game.fovEnabled and Game.fovMap[y] and Game.fovMap[y][x]) or 1
					
					local floorColors = (config.floorData[Game.currentFloor] and config.floorData[Game.currentFloor].colors) or {floor = require('src.colors').default_floor, wall = require('src.colors').default_wall}

					local tileData = map[y][x]
					local tileType = type(tileData) == "table" and tileData.type or tileData

					-- Use the lookup table to call the correct drawing function
					local drawFunc = tileDrawers[tileType]
					if drawFunc then
						-- Pass getCenteredOffsets for the fallback stair drawers
						drawFunc(floorColors, visibility, screenX, screenY, tileData, getCenteredOffsets)
					end
				end
			end
		end
		-- Draw large props (doodads)
		local largeProps = Game.floors[Game.currentFloor].largeProps or {}
		for _, prop in ipairs(largeProps) do
			-- Check if it's a rug/runner
			local isRug = prop.sprite:find("rug") or prop.sprite:find("runner")
			local propQuad = isRug and Assets.sprites.rugs[prop.sprite]
			local propAtlas = isRug and Assets.sprites.rug_atlas

			if propQuad and propAtlas then
				local screenX, screenY
				if prop.isPixelCoords then
					screenX = mapX + (prop.x - Game.camera.x * Game.tileSize)
					screenY = mapY + (prop.y - Game.camera.y * Game.tileSize)
				else -- Fallback for any old props that might use tile coords
					screenX = mapX + (prop.x - Game.camera.x) * Game.tileSize
					screenY = mapY + (prop.y - Game.camera.y) * Game.tileSize
				end
				local rotation = prop.rotation or 0
				-- To rotate around the center, we need to calculate the origin offset
				local ox, oy = 0, 0
				if rotation ~= 0 then
                        local _, _, quadWidth, quadHeight = propQuad:getViewport()
						ox, oy = quadWidth / 2, quadHeight / 2
				end

				-- Determine visibility of the prop's location by checking its corners
				local _, _, quadWidth, quadHeight = propQuad:getViewport()
				local corners = {
					{x = prop.x, y = prop.y}, -- Top-left
					{x = prop.x + quadWidth, y = prop.y}, -- Top-right
					{x = prop.x, y = prop.y + quadHeight}, -- Bottom-left
					{x = prop.x + quadWidth, y = prop.y + quadHeight} -- Bottom-right
				}

				local isAnyCornerVisible = false
				local maxVisibility = 0

				for _, corner in ipairs(corners) do
					local tileX = math.floor(corner.x / Game.tileSize) + 1
					local tileY = math.floor(corner.y / Game.tileSize) + 1
					if Game.floors[Game.currentFloor].exploredMap[tileY] and Game.floors[Game.currentFloor].exploredMap[tileY][tileX] then
						isAnyCornerVisible = true
						local cornerVisibility = (Game.fovEnabled and Game.fovMap[tileY] and Game.fovMap[tileY][tileX]) or 0
						if cornerVisibility > maxVisibility then maxVisibility = cornerVisibility end
					end
				end

				if isAnyCornerVisible then
					local finalVisibility = (maxVisibility > 0) and maxVisibility or 0.3
					love.graphics.setColor(finalVisibility, finalVisibility, finalVisibility)
					love.graphics.draw(propAtlas, propQuad, screenX + ox, screenY + oy, rotation, 1, 1, ox, oy)
				end
			end
		end

		-- Draw entities
		for _, entity in ipairs(Game.entities) do
			local visibility = (Game.fovEnabled and Game.fovMap[entity.y] and Game.fovMap[entity.y][entity.x]) or 1
			if visibility > 0 then
				local screenX = mapX + (entity.x - Game.camera.x) * Game.tileSize
				local screenY = mapY + (entity.y - Game.camera.y) * Game.tileSize
				if entity.sprite then
					love.graphics.setColor(visibility, visibility, visibility)
					love.graphics.draw(entity.sprite, screenX, screenY)
				else
					local ox, oy = getCenteredOffsets(entity.char or ' ')
					love.graphics.setColor(entity.color[1] * visibility, entity.color[2] * visibility, entity.color[3] * visibility)
					love.graphics.print(entity.char, screenX + ox, screenY + oy)
				end
			end
		end
	end
end

return MapRenderer