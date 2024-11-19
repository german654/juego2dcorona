-----------------------------------------------------------------------------------------
--
-- main.lua
-- Juego de Globo Mejorado
-----------------------------------------------------------------------------------------

-- Variables globales
local tapCount = 0
local score = 0
local lives = 3
local combo = 0
local maxCombo = 0
local isGameOver = false

-- Variables para almacenar referencias a objetos de la UI
local ui = {}
local gameObjects = {}

-- Declaración anticipada de funciones
local gameOver
local updateScore
local updateCombo
local loseLife
local setupUI
local setupGame
local init

-- Sistema de puntuación
updateScore = function(points)
    score = score + (points * (1 + math.floor(combo / 5)))
    ui.scoreText.text = "Score: " .. score
    
    -- Animación de puntuación
    transition.to(ui.scoreText, {
        time = 100,
        xScale = 1.2,
        yScale = 1.2,
        onComplete = function()
            transition.to(ui.scoreText, {
                time = 100,
                xScale = 1,
                yScale = 1
            })
        end
    })
end

-- Sistema de combos
updateCombo = function(reset)
    if reset then
        combo = 0
        ui.comboText.alpha = 0
    else
        combo = combo + 1
        maxCombo = math.max(maxCombo, combo)
        ui.comboText.text = "Combo: x" .. combo
        ui.comboText.alpha = 1
        
        -- Animación de combo
        transition.to(ui.comboText, {
            time = 200,
            xScale = 1.3,
            yScale = 1.3,
            onComplete = function()
                transition.to(ui.comboText, {
                    time = 200,
                    xScale = 1,
                    yScale = 1
                })
            end
        })
    end
end

-- Game Over
gameOver = function()
    isGameOver = true
    
    local gameOverText = display.newText({
        text = "Game Over!\nScore: " .. score .. "\nMax Combo: x" .. maxCombo,
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = native.systemFont,
        fontSize = 40,
        align = "center"
    })
    gameOverText:setFillColor(1, 0, 0)
    
    -- Botón de reinicio
    local restartButton = display.newRect(
        display.contentCenterX,
        display.contentCenterY + 100,
        200,
        50
    )
    restartButton:setFillColor(0, 0.7, 0)
    
    local restartText = display.newText({
        text = "Jugar de nuevo",
        x = restartButton.x,
        y = restartButton.y,
        font = native.systemFont,
        fontSize = 24
    })
    
    restartButton:addEventListener("tap", function()
        -- Limpiar la pantalla
        display.remove(gameOverText)
        display.remove(restartButton)
        display.remove(restartText)
        
        -- Reiniciar variables
        score = 0
        lives = 3
        combo = 0
        maxCombo = 0
        isGameOver = false
        
        -- Reiniciar el juego
        init()
    end)
end

-- Sistema de vidas
loseLife = function()
    lives = lives - 1
    if lives >= 0 and ui.hearts[lives + 1] then
        transition.to(ui.hearts[lives + 1], {
            time = 300,
            alpha = 0,
            xScale = 0.1,
            yScale = 0.1
        })
    end
    
    if lives <= 0 then
        gameOver()
    end
end

-- Configuración de la interfaz
setupUI = function()
    local background = display.newImageRect("background.png", 360, 570)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    -- Puntuación
    ui.scoreText = display.newText({
        text = "Score: " .. score,
        x = 100,
        y = 20,
        font = native.systemFont,
        fontSize = 24
    })
    ui.scoreText:setFillColor(1, 1, 1)

    -- Vidas
    ui.heartsGroup = display.newGroup()
    ui.hearts = {}
    
    for i = 1, lives do
        local heart = display.newImageRect(ui.heartsGroup, "heart.png", 30, 30)
        heart.x = display.contentWidth - (35 * i)
        heart.y = 20
        ui.hearts[i] = heart
    end

    -- Combo
    ui.comboText = display.newText({
        text = "Combo: x" .. combo,
        x = display.contentCenterX,
        y = 50,
        font = native.systemFont,
        fontSize = 20
    })
    ui.comboText:setFillColor(1, 0.8, 0)
    ui.comboText.alpha = 0
end

-- Configuración del juego
setupGame = function()
    local physics = require("physics")
    physics.start()
    physics.setGravity(0, 9.8)

    -- Plataforma
    gameObjects.platform = display.newImageRect("platform.png", 300, 50)
    gameObjects.platform.x = display.contentCenterX
    gameObjects.platform.y = display.contentHeight - 25
    physics.addBody(gameObjects.platform, "static")

    -- Globo
    gameObjects.balloon = display.newImageRect("balloon.png", 112, 112)
    gameObjects.balloon.x = display.contentCenterX
    gameObjects.balloon.y = display.contentCenterY
    gameObjects.balloon.alpha = 0.8
    physics.addBody(gameObjects.balloon, "dynamic", {
        radius = 50,
        bounce = 0.3
    })

    -- Límite superior
    gameObjects.ceiling = display.newRect(display.contentCenterX, -10, display.contentWidth, 20)
    gameObjects.ceiling.alpha = 0
    physics.addBody(gameObjects.ceiling, "static")

    -- Evento de toque del globo
    function gameObjects.balloon:tap()
        if not isGameOver then
			-- Aplicar impulso lineal hacia arriba
            self:applyLinearImpulse(0, -0.75, self.x, self.y)
            updateScore(1)
            updateCombo(false)
        end
        return true
    end
    gameObjects.balloon:addEventListener("tap")
end

-- Inicialización principal
init = function()
    -- Limpiar objetos existentes si los hay
    if gameObjects.balloon then
        if gameObjects.balloon.removeSelf then
            gameObjects.balloon:removeSelf()
            gameObjects.balloon = nil
        end
    end

    if gameObjects.platform then
        if gameObjects.platform.removeSelf then
            gameObjects.platform:removeSelf()
            gameObjects.platform = nil
        end
    end

    if gameObjects.ceiling then
        if gameObjects.ceiling.removeSelf then
            gameObjects.ceiling:removeSelf()
            gameObjects.ceiling = nil
        end
    end

    -- Configurar la interfaz y el juego nuevamente
    setupUI()
    setupGame()

    -- Colisión con el suelo
    local function onCollision(event)
        if event.phase == "began" then
            if (event.object1 == gameObjects.platform and event.object2 == gameObjects.balloon) or
               (event.object1 == gameObjects.balloon and event.object2 == gameObjects.platform) then
                updateCombo(true)
                loseLife()
            end
        end
    end

    Runtime:addEventListener("collision", onCollision)
end

-- Iniciar el juego
init()
