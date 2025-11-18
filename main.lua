-- Signal Lost - A Radio Wave Mystery Game

function love.load()
    -- Window setup
    love.window.setTitle("Signal Lost - Radio Wave Mystery")
    love.window.setMode(800, 600)

    -- Game state
    gameState = {
        currentFrequency = 88.0,
        targetFrequency = 95.5,
        lockedOn = false,
        signalStrength = 0,
        staticVolume = 0.3,
        messageRevealed = false,
        currentMessage = 1,
        tuningSpeed = 0.1
    }

    -- Messages
    messages = {
        {
            frequency = 95.5,
            text = "...is anyone out there? This is Station Alpha...\nIf you ..., please respond.\nThe waves... they're not natural.",
            decoded = false
        },
        {
            frequency = 102.3,
            text = "Day 47: The interference is getting stronger.\nWe've lost contact with the mainland.\nThe pattern repeats every 6 hours.",
            decoded = false
        },
        {
            frequency = 107.8,
            text = "URGENT BROADCAST: Do not approach the shoreline.\nThe sound is calling them.\nWe were wrong about everything.",
            decoded = false
        },
        {
            frequency = 91.5,
            text = "Final transmission from Station Bravo: If you're hearing this,\nwe're already gone. The waves carry something.\nSomething ancient. Don't listen too long.",
            decoded = false
        }
    }

    -- Procedural static noise
    staticSource = love.audio.newSource("generate_static", "static")
    staticSource:setLooping(true)
    staticSource:setVolume(gameState.staticVolume)
    staticSource:play()

    -- Visual settings
    waveformPoints = {}
    for i = 1, 100 do
        waveformPoints[i] = 0
    end

    -- Fonts
    titleFont = love.graphics.newFont(24)
    smallFont = love.graphics.newFont(12)
    messageFont = love.graphics.newFont(16)

    -- Colors
    colors = {
        background = {0.05, 0.05, 0.08},
        green = {0.2, 0.9, 0.3},
        panel = {0.1, 0.12, 0.15},
        yellow = {0.9, 0.8, 0.2},
        greenDim = {0.1, 0.4, 0.15},
        white = {1, 1, 1},
        red = {0.9, 0.2, 0.2}
    }
end

function love.update(dt)
    -- Tuning controls
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        gameState.currentFrequency = gameState.currentFrequency + gameState.tuningSpeed
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        gameState.currentFrequency = gameState.currentFrequency - gameState.tuningSpeed
    end
    
    -- Clamp frequency to FM range
    gameState.currentFrequency = math.max(88.0, math.min(108.0, gameState.currentFrequency))
    
    -- Find nearest signal
    local nearestDistance = 999
    local nearestSignal = nil
    
    for i, msg in ipairs(messages) do
        if not msg.decoded then
            local distance = math.abs(gameState.currentFrequency - msg.frequency)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestSignal = msg
                gameState.targetFrequency = msg.frequency
                gameState.currentMessage = i
            end
        end
    end
    
    -- Calculate signal strength
    if nearestSignal then
        local distance = math.abs(gameState.currentFrequency - nearestSignal.frequency)
        gameState.signalStrength = math.max(0, 1 - (distance / 2.0))
    else
        gameState.signalStrength = 0
    end
    
    -- Lock on if close enough
    if gameState.signalStrength > 0.9 and not gameState.lockedOn then
        gameState.lockedOn = true
        gameState.messageRevealed = false
    elseif gameState.signalStrength < 0.7 then
        gameState.lockedOn = false
        gameState.messageRevealed = false
    end
    
    -- Static volume based on signal strength
    gameState.staticVolume = 0.3 * (1 - gameState.signalStrength * 0.8)
    staticSource:setVolume(gameState.staticVolume)
    
    -- Reveal message when locked
    if gameState.lockedOn then
        gameState.messageRevealed = true
    end
    
    -- Update waveform
    for i = #waveformPoints, 2, -1 do
        waveformPoints[i] = waveformPoints[i - 1]
    end
    
    local noiseAmount = (1 - gameState.signalStrength) * 40
    local signalWave = math.sin(love.timer.getTime() * 10 * gameState.signalStrength) * gameState.signalStrength * 30
    waveformPoints[1] = signalWave + (math.random() - 0.5) * noiseAmount
end

function love.draw()
    -- Background
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    
    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(colors.green)
    love.graphics.printf("SIGNAL LOST", 0, 20, 800, "center")

    -- Radio panel
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", 50, 80, 700, 180)

    -- Frequency display
    love.graphics.setFont(titleFont)
    love.graphics.setColor(colors.yellow)
    love.graphics.printf(string.format("%.1f MHz", gameState.currentFrequency), 50, 100, 700, "center")

    -- Frequency bar
    local barX = 100
    local barY = 150
    local barWidth = 600
    local barHeight = 30

    love.graphics.setColor(colors.greenDim)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    -- Current frequency indicator
    local freqPercent = (gameState.currentFrequency - 88.0) / 20.0
    local indicatorX = barX + (barWidth * freqPercent)

    love.graphics.setColor(colors.green)
    love.graphics.rectangle("fill", indicatorX - 2, barY, 4, barHeight)

    -- Signal markers
    for i, msg in ipairs(messages) do
        if not msg.decoded then
            if gameState.lockedOn and gameState.currentMessage == i then
                local signalPercent = (msg.frequency - 88.0) / 20.0
                local signalX = barX + (barWidth * signalPercent)
                love.graphics.setColor(colors.red)
                love.graphics.circle("fill", signalX, barY + barHeight / 2, 5)
            end
        end
    end

    -- Signal strength meter
    love.graphics.setFont(smallFont)
    love.graphics.setColor(colors.white)
    love.graphics.print("SIGNAL STRENGTH", 100, 200)
    
    local meterWidth = 200
    love.graphics.setColor(colors.greenDim)
    love.graphics.rectangle("fill", 100, 220, meterWidth, 20)

    local signalColor = gameState.signalStrength > 0.9 and colors.green or 
                        gameState.signalStrength > 0.5 and colors.yellow or colors.red
    love.graphics.setColor(signalColor)
    love.graphics.rectangle("fill", 100, 220, meterWidth * gameState.signalStrength, 20)

    -- Lock indicator
    if gameState.lockedOn then
        love.graphics.setColor(colors.green)
        love.graphics.print("LOCKED", 320, 220)
    end
    
    -- Waveform visualization
    love.graphics.setColor(colors.green)
    for i = 1, #waveformPoints - 1 do
        local x1 = 400 + i * 3
        local y1 = 220 + waveformPoints[i]
        local x2 = 400 + (i + 1) * 3
        local y2 = 220 + waveformPoints[i + 1]
        love.graphics.line(x1, y1, x2, y2)
    end

    -- Message display
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", 50, 280, 700, 280)

    if gameState.messageRevealed and messages[gameState.currentMessage] then
        love.graphics.setFont(messageFont)
        love.graphics.setColor(colors.green)
        love.graphics.printf(
            messages[gameState.currentMessage].text,
            70, 300, 660, "left"
        )
        
        -- Decode button
        love.graphics.setFont(smallFont)
        love.graphics.setColor(colors.greenDim)
        love.graphics.rectangle("fill", 325, 520, 150, 30)
        love.graphics.setColor(colors.green)
        love.graphics.printf("DECODE [SPACE]", 325, 527, 150, "center")
    else
        love.graphics.setFont(messageFont)
        love.graphics.setColor(colors.greenDim)
        love.graphics.printf(
            "Tune to find signals...\n\nUse arrow keys or A/D to adjust frequency\nLock onto signals to receive transmissions",
            70, 320, 660, "center"
        )
    end


    -- Status bar
    love.graphics.setFont(smallFont)
    love.graphics.setColor(colors.greenDim)
    local decodedCount = 0
    for _, msg in ipairs(messages) do
        if msg.decoded then decodedCount = decodedCount + 1 end
    end
    love.graphics.printf(
        string.format("Messages Decoded: %d/%d", decodedCount, #messages),
        0, 570, 800, "center"
    )
end


function love.keypressed(key)
    -- Decode message
    if key == "space" and gameState.lockedOn and gameState.messageRevealed then
        messages[gameState.currentMessage].decoded = true
        gameState.lockedOn = false
        gameState.messageRevealed = false
        
        -- Check if all messages decoded
        local allDecoded = true
        for _, msg in ipairs(messages) do
            if not msg.decoded then
                allDecoded = false
                break
            end
        end
        
        if allDecoded then
            -- Game complete!
            messages[1].text = "ALL TRANSMISSIONS DECODED\n\nThe mystery deepens...\nWhat lies beneath the waves?\n\nThanks for playing!"
            messages[1].decoded = false
            gameState.currentMessage = 1
        end
    end
    
    -- Quit
    if key == "escape" then
        love.event.quit()
    end
end

-- Generate static noise audio
local _original_newSource = love.audio.newSource
function love.audio.newSource(arg1, arg2)
    if arg1 == "generate_static" then
        local sampleRate = 44100
        local duration = 2
        local samples = sampleRate * duration
        local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
        
        for i = 0, samples - 1 do
            local value = (math.random() - 0.5) * 0.3
            soundData:setSample(i, value)
        end
        
        return _original_newSource(soundData)
    end

    return _original_newSource(arg1, arg2)
end