-- Hide the status bar, so it doesn't cover game objects
display.setStatusBar(display.HiddenStatusBar)

-- Load and start physics
local physics = require("physics")
physics.start()

-- Heavier gravity means that the planes fall faster
physics.setGravity(0, 20)

-- Layers: similar to photoshop. Corona can also have layers
local gameLayer = display.newGroup()
local bulletsLayer = display.newGroup()
local enemiesLayer = display.newGroup()

-- All Variables
local gameIsActive = true
local scoreText
local sounds
local score = 0
local toRemove = {}
local background
local player
local halfPlayerWidth

-- put enemy textures into memory
local textureCache = {}
textureCache[1] = display.newImage("assets/graphics/enemy.png"); textureCache[1].isVisible = false;
textureCache[2] = display.newImage("assets/graphics/bullet.png"); textureCache[2].isVisible = false;
local halfEnemyWidth = textureCache[1].contentWidth * .5

-- volume adjust
audio.setMaxVolume( 0.85, { channel=1 } )

-- pre-load sounds
sounds = {
	pew = audio.loadSound("assets/sounds/pew.wav"),
	boom = audio.loadSound("assets/sounds/boom.wav"),
	gameOver = audio.loadSound("assets/sounds/gameOver.wav")
}

-- Blue background
background = display.newRect(0, 0, display.contentWidth, display.contentHeight)
background:setFillColor(21, 115, 193)
gameLayer:insert(background)

-- ordering the layers. later the player and the score will be added so that the score is always on top.
gameLayer:insert(bulletsLayer)
gameLayer:insert(enemiesLayer)

-- collisions
local function onCollision (self, event)
	if self.name == "bullet" and event.other.name == "enemy" and gameIsActive then
		score = score + 1
		scoreText.text = score

		--play boom sounds
		audio.play(sounds.boom)

		table.insert(toRemove, event.other)

	elseif self.name == "player" and event.other.name == "enemy" then
		audio.play(sounds.gameOver)

		local gameoverText = display.newText("Game Over!", 0, 0, "Comic Sans MS", 35)
		gameoverText:setTextColor(255, 0, 0)
		gameoverText.x = display.contentCenterX
		gameoverText.y = display.contentCenterY
		gameLayer:insert(gameoverText)

		-- Stop the game loog
		gameIsActive = false
	end
end

-- load and position the player
player = display.newImage("assets/graphics/player.png")
player.x = display.contentCenterX
player.y = display.contentHeight - player.contentHeight

-- adds a physics body that is kinematic and doesn't react to gravity
physics.addBody(player, "kinematic", {bounce = 0})

-- who is instigating the collisions?
player.name = "player"

-- Listen for the collisions
player.collision = onCollision
player:addEventListener("collision", player)

-- add player to the main layer
gameLayer:insert(player)

-- store half width, used in the game loop
halfPlayerWidth = player.contentWidth * .5

-- show the score
scoreText = display.newText(score, 0, 0, "Comic Sans MS", 35)
scoreText:setTextColor(255, 255, 255)
scoreText.x = 30
scoreText.y = 25
gameLayer:insert(scoreText)

-----------------------------------------------------
-- Game Loop
-----------------------------------------------------

local timeLastBullet, timeLastEnemy = 0, 0
local bulletInterval = 1000

local function gameLoop(event)
	if gameIsActive then
		-- remove collided enemy planes
		for i = 1, #toRemove do
			toRemove[i].parent:remove(toRemove[i])
			toRemove[i] = nil
		end

		-- check if it's time to spawn another enemy based on the random range and last spawn
		if event.time - timeLastEnemy >= math.random(600, 1000) then
			local enemy = display.newImage("assets/graphics/enemy.png")
			enemy.x = math.random(halfEnemyWidth, display.contentWidth - halfEnemyWidth)
			enemy.y = -enemy.contentHeight

			-- must be dynamic in order to react to gravity, making it fall to the bottom
			physics.addBody(enemy, "dynamic", {bounce = 0})
			enemy.name = "enemy"

			enemiesLayer:insert(enemy)
			timeLastEnemy = event.time
		end

		-- spawn bullets
		if event.time - timeLastBullet >= math.random(250, 300) then
			local bullet = display.newImage("assets/graphics/bullet.png")
			bullet.x = player.x
			bullet.y = player.y - halfPlayerWidth

			-- kinematic so it doesnt react to gravity
			physics.addBody(bullet, "kinematic", {bounce = 0})
			bullet.name = "bullet"

			-- listen for collisions
			bullet.collision = onCollision
			bullet:addEventListener("collision", bullet)

			bulletsLayer:insert(bullet)

			-- pew pew sound
			audio.play(sounds.pew)

			-- Move it to the top, when complete then remove itself
			transition.to(bullet, {time = 1000, y = -bullet.contentHeight,
				onComplete = function(self) self.parent:remove(self); self = nil; end
			})

			timeLastBullet = event.time
		end
	end
end

-- call the game Loop
Runtime:addEventListener("enterFrame", gameLoop)

-----------------------------------------------------
-- Basic Controls
-----------------------------------------------------

local function playerMovement(event)
	-- doesnt repond if the game is finished
	if not gameIsActive then return false end

	if event.x >= halfPlayerWidth and event.x <= display.contentWidth - halfPlayerWidth then
		player.x = event.x
	end
end
-- player will listen to touch
player:addEventListener("touch", playerMovement)
