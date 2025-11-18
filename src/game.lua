-- game.lua - Core game logic and state management

Game = {}

function Game.init()
    Game.state = {
        currentFrequency = 88.0,
        targetFrequency = 95.5,
        lockedOn = false,
        signalStrength = 0,
        messageRevealed = false,
        currentMessage = 1
    }
    
    Game.messages = Config.messages
end

function Game.update(dt)
    -- Tuning controls
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        Game.state.currentFrequency = Game.state.currentFrequency + Config.frequency.tuningSpeed
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        Game.state.currentFrequency = Game.state.currentFrequency - Config.frequency.tuningSpeed
    end
    
    -- Clamp frequency to FM range
    Game.state.currentFrequency = math.max(
        Config.frequency.min,
        math.min(Config.frequency.max, Game.state.currentFrequency)
    )
    
    -- Find nearest undecoded signal
    Game.findNearestSignal()
    
    -- Calculate signal strength
    Game.calculateSignalStrength()
    
    -- Handle lock-on state
    Game.updateLockState()
end

function Game.findNearestSignal()
    local nearestDistance = 999
    local nearestSignal = nil
    
    for i, msg in ipairs(Game.messages) do
        if not msg.decoded then
            local distance = math.abs(Game.state.currentFrequency - msg.frequency)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestSignal = msg
                Game.state.targetFrequency = msg.frequency
                Game.state.currentMessage = i
            end
        end
    end
end

function Game.calculateSignalStrength()
    local nearestMsg = Game.messages[Game.state.currentMessage]
    if nearestMsg and not nearestMsg.decoded then
        local distance = math.abs(Game.state.currentFrequency - nearestMsg.frequency)
        Game.state.signalStrength = math.max(0, 1 - (distance / Config.signal.detectionRange))
    else
        Game.state.signalStrength = 0
    end
end

function Game.updateLockState()
    -- Lock on if close enough
    if Game.state.signalStrength > Config.signal.lockThreshold and not Game.state.lockedOn then
        Game.state.lockedOn = true
        Game.state.messageRevealed = false
    elseif Game.state.signalStrength < Config.signal.unlockThreshold then
        Game.state.lockedOn = false
        Game.state.messageRevealed = false
    end
    
    -- Reveal message when locked
    if Game.state.lockedOn then
        Game.state.messageRevealed = true
    end
end

function Game.decodeCurrentMessage()
    if Game.state.lockedOn and Game.state.messageRevealed then
        Game.messages[Game.state.currentMessage].decoded = true
        Game.state.lockedOn = false
        Game.state.messageRevealed = false
        
        -- Check if all messages decoded
        if Game.allMessagesDecoded() then
            Game.showVictoryMessage()
        end
    end
end

function Game.allMessagesDecoded()
    for _, msg in ipairs(Game.messages) do
        if not msg.decoded then
            return false
        end
    end
    return true
end

function Game.showVictoryMessage()
    Game.messages[1].text = "ALL TRANSMISSIONS DECODED\n\nThe mystery deepens...\nWhat lies beneath the waves?\n\nThanks for playing!"
    Game.messages[1].decoded = false
    Game.state.currentMessage = 1
end

function Game.getDecodedCount()
    local count = 0
    for _, msg in ipairs(Game.messages) do
        if msg.decoded then count = count + 1 end
    end
    return count
end

function Game.keypressed(key)
    if key == "space" then
        Game.decodeCurrentMessage()
    elseif key == "escape" then
        love.event.quit()
    end
end

return Game