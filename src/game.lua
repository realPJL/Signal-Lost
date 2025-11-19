Game = {}

function Game.init()
    Game.state = {
        currentFrequency = 90.0,
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
        -- If unlocking, stop any morse playback and re-enable beeps
        if Game.state.lockedOn then
            if Audio then
                Audio.stopMorseCode()
                Audio.beepsEnabled = true
            end
        end
        Game.state.lockedOn = false
        Game.state.messageRevealed = false
    end
end

function Game.decodeCurrentMessage()
    if Game.state.lockedOn then
        -- First press: reveal the message
        if not Game.state.messageRevealed then
            Game.state.messageRevealed = true
            return
        end
        
        -- Second press: decode and mark as complete
        if Game.state.messageRevealed then
            local currentMsg = Game.messages[Game.state.currentMessage]
            currentMsg.decoded = true
            Game.state.lockedOn = false
            Game.state.messageRevealed = false
            
            -- Trigger glitch effect on decode
            if Effects then
                Effects.triggerGlitch(0.2)
            end
            
            -- Play decode sound and morse code
            if Audio then
                Audio.playDecodeSound()
                
                -- Play morse code for this message if it has one
                if currentMsg.morse then
                    Audio.playMorseCode(currentMsg.morse)
                end
            end
            
            -- Check if all messages decoded
            if Game.allMessagesDecoded() then
                Game.showVictoryMessage()
            end
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
    Game.messages[1].text = "ALL TRANSMISSIONS DECODED\n\nThe mystery deepens...\nWhat lies beneath the waves?\n\nThanks for playing!\nCode: Claude & Paul\nStory & Idea: Paul"
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
        if not Game.state.lockedOn then return end

        local idx = Game.state.currentMessage
        local msg = Game.messages[idx]
        if not msg then return end

        -- First SPACE press: Reveal message and play morse code
        if not Game.state.messageRevealed and not msg.decoded then
            Game.state.messageRevealed = true

            -- Disable proximity beeps while morse code plays
            if Audio then
                Audio.beepsEnabled = false
            end

            -- Play morse code for this message
            if Audio and Audio.playMorseCode then
                Audio.playMorseCode(msg.morse or "")
            end

            -- Trigger glitch effect
            if Effects then
                Effects.triggerGlitch(0.2)
            end

        -- Second SPACE press: Save and decode the message
        elseif Game.state.messageRevealed and not msg.decoded then
            msg.decoded = true
            msg.saved = true

            -- Stop morse code playback
            if Audio then
                Audio.stopMorseCode()
                Audio.beepsEnabled = true  -- Re-enable proximity beeps
                Audio.playDecodeSound()
            end

            -- Reset state for next message
            Game.state.lockedOn = false
            Game.state.messageRevealed = false

            -- Check if all messages decoded
            if Game.allMessagesDecoded() then
                Game.showVictoryMessage()
            end
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

return Game