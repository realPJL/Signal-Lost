Audio = {}

function Audio.init()
    -- Master volume control (0.0 to 1.0)
    Audio.masterVolume = 0.3

    -- Generate procedural static noise
    Audio.staticSource = Audio.generateStatic()
    Audio.staticSource:setLooping(true)
    Audio.staticSource:setVolume(0.3 * Audio.masterVolume)
    Audio.staticSource:play()

    Audio.baseVolume = 0.3
    
    -- Proximity beep system
    Audio.beepTimer = 0
    Audio.beepInterval = 1.0
    Audio.lastSignalStrength = 0
    Audio.beepsEnabled = true
    
    -- Morse code system
    Audio.morseQueue = {}
    Audio.morseTimer = 0
    Audio.morseIsPlaying = false
    Audio.currentMorseElement = 1
    
    -- Morse code alphabet (in timing units)
    -- 1 = dit (short), 3 = dah (long)
    Audio.morseAlphabet = {
        A = {1, 3},              -- .-
        B = {3, 1, 1, 1},        -- -...
        C = {3, 1, 3, 1},        -- -.-.
        D = {3, 1, 1},           -- -..
        E = {1},                 -- .
        F = {1, 1, 3, 1},        -- ..-.
        G = {3, 3, 1},           -- --.
        H = {1, 1, 1, 1},        -- ....
        I = {1, 1},              -- ..
        J = {1, 3, 3, 3},        -- .---
        K = {3, 1, 3},           -- -.-
        L = {1, 3, 1, 1},        -- .-..
        M = {3, 3},              -- --
        N = {3, 1},              -- -.
        O = {3, 3, 3},           -- ---
        P = {1, 3, 3, 1},        -- .--.
        Q = {3, 3, 1, 3},        -- --.-
        R = {1, 3, 1},           -- .-.
        S = {1, 1, 1},           -- ...
        T = {3},                 -- -
        U = {1, 1, 3},           -- ..-
        V = {1, 1, 1, 3},        -- ...-
        W = {1, 3, 3},           -- .--
        X = {3, 1, 1, 3},        -- -..-
        Y = {3, 1, 3, 3},        -- -.--
        Z = {3, 3, 1, 1},        -- --..
        ["0"] = {3, 3, 3, 3, 3}, -- -----
        ["1"] = {1, 3, 3, 3, 3}, -- .----
        ["2"] = {1, 1, 3, 3, 3}, -- ..---
        ["3"] = {1, 1, 1, 3, 3}, -- ...--
        ["4"] = {1, 1, 1, 1, 3}, -- ....-
        ["5"] = {1, 1, 1, 1, 1}, -- .....
        ["6"] = {3, 1, 1, 1, 1}, -- -....
        ["7"] = {3, 3, 1, 1, 1}, -- --...
        ["8"] = {3, 3, 3, 1, 1}, -- ---..
        ["9"] = {3, 3, 3, 3, 1}, -- ----.
    }
    
    -- Generate tone beeps at different pitches
    Audio.beepLow = Audio.generateTone(300, 0.05)
    Audio.beepMid = Audio.generateTone(500, 0.05)
    Audio.beepHigh = Audio.generateTone(800, 0.05)
    Audio.beepLock = Audio.generateTone(1200, 0.1)
    
    -- Morse code tones
    Audio.morseDit = Audio.generateTone(800, 0.04)  -- Short beep
    Audio.morseDah = Audio.generateTone(800, 0.12)  -- Long beep
end

function Audio.setMasterVolume(volume)
    Audio.masterVolume = math.max(0, math.min(1, volume))

    -- Update static source volume
    local signalStrength = Game.state.signalStrength
    local staticVolume = Audio.baseVolume * (1 - signalStrength * 0.8)
    Audio.staticSource:setVolume(staticVolume * Audio.masterVolume)
end

function Audio.update(dt)
    dt = dt or 0  -- Safety check

    -- Adjust static volume based on signal strength
    local signalStrength = Game.state.signalStrength
    local volume = Audio.baseVolume * (1 - signalStrength * 0.8)
    Audio.staticSource:setVolume(volume * Audio.masterVolume)

    -- Proximity beep system
    Audio.updateProximityBeeps(dt, signalStrength)

    -- Morse code playback
    Audio.updateMorsePlayback(dt)
end

function Audio.updateProximityBeeps(dt, signalStrength)
    -- Don't play proximity beeps if they're disabled (e.g., during morse playback)
    if not Audio.beepsEnabled then
        Audio.beepTimer = 0
        return
    end

    Audio.beepTimer = Audio.beepTimer + dt

    -- Calculate beep interval based on signal strength
    -- Closer to signal = faster beeps
    if signalStrength > 0.1 then
        Audio.beepInterval = 1.5 - (signalStrength * 1.3)
        Audio.beepInterval = math.max(0.15, Audio.beepInterval)

        if Audio.beepTimer >= Audio.beepInterval then
            Audio.beepTimer = 0
            Audio.playProximityBeep(signalStrength)
        end
    else
        Audio.beepTimer = 0
    end

    -- Play lock-on sound when newly locked
    if Game.state.lockedOn and Audio.lastSignalStrength < 0.9 then
        local source = Audio.beepLock:clone()
        source:setVolume(Audio.masterVolume)
        source:play()
    end

    Audio.lastSignalStrength = signalStrength
end

function Audio.playProximityBeep(strength)
    -- Choose beep pitch based on signal strength
    local beep
    if strength > 0.7 then
        beep = Audio.beepHigh
    elseif strength > 0.4 then
        beep = Audio.beepMid
    else
        beep = Audio.beepLow
    end

    -- Clone and play (allows overlapping sounds)
    local source = beep:clone()
    source:setVolume((0.3 + strength * 0.3) * Audio.masterVolume)
    source:play()
end

-- Convert text to morse code and play it
function Audio.playMorseCode(text)
    text = string.upper(text)
    Audio.morseQueue = {}

    for i = 1, #text do
        local char = text:sub(i, i)

        if char == " " then
            -- Word space (7 units total, but we already have 3 from letter gap)
            table.insert(Audio.morseQueue, {type = "wordspace", duration = 0.4})
        else
            local pattern = Audio.morseAlphabet[char]
            if pattern then
                -- Add each dit/dah
                for _, timing in ipairs(pattern) do
                    if timing == 1 then
                        table.insert(Audio.morseQueue, {type = "dit", duration = 0.08})
                    elseif timing == 3 then
                        table.insert(Audio.morseQueue, {type = "dah", duration = 0.24})
                    end
                    -- Add space between elements (1 unit)
                    table.insert(Audio.morseQueue, {type = "space", duration = 0.08})
                end
                -- Add space between letters (3 units total, we have 1 already)
                table.insert(Audio.morseQueue, {type = "letterspace", duration = 0.16})
            end
        end
    end

    Audio.morseIsPlaying = true
    Audio.currentMorseElement = 1
    Audio.morseTimer = 0
end

-- Stop morse code playback immediately
function Audio.stopMorseCode()
    Audio.morseIsPlaying = false
    Audio.morseQueue = {}
    Audio.currentMorseElement = 1
    Audio.morseTimer = 0
end

function Audio.updateMorsePlayback(dt)
    if not Audio.morseIsPlaying or #Audio.morseQueue == 0 then
        return
    end
    
    if Audio.currentMorseElement > #Audio.morseQueue then
        -- Finished playing
        Audio.morseIsPlaying = false
        Audio.morseQueue = {}
        Audio.currentMorseElement = 1
        Audio.morseTimer = 0
        return
    end
    
    local element = Audio.morseQueue[Audio.currentMorseElement]
    
    -- Wait for the current element to start
    if Audio.morseTimer == 0 then
        -- Play sound at the start (not for spaces)
        if element.type == "dit" then
            local source = Audio.morseDit:clone()
            source:setVolume(Audio.masterVolume)
            source:play()
        elseif element.type == "dah" then
            local source = Audio.morseDah:clone()
            source:setVolume(Audio.masterVolume)
            source:play()
        end
    end
    
    Audio.morseTimer = Audio.morseTimer + dt
    
    -- Check if element duration is complete
    if Audio.morseTimer >= element.duration then
        -- Move to next element
        Audio.currentMorseElement = Audio.currentMorseElement + 1
        Audio.morseTimer = 0
    end
end

function Audio.generateStatic()
    local sampleRate = 44100
    local duration = 2
    local samples = sampleRate * duration
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local value = (math.random() - 0.5) * 0.3
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

function Audio.generateTone(frequency, duration)
    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Sine wave with envelope to prevent clicks
        local envelope = 1.0
        local fadeIn = 0.005
        local fadeOut = 0.01
        
        if t < fadeIn then
            envelope = t / fadeIn
        elseif t > duration - fadeOut then
            envelope = (duration - t) / fadeOut
        end
        
        local value = math.sin(2 * math.pi * frequency * t) * 0.3 * envelope
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData)
end

function Audio.playDecodeSound()
    -- Special sound when decoding a message
    local decodeBeep = Audio.generateTone(1000, 0.2)
    decodeBeep:setVolume(Audio.masterVolume)
    decodeBeep:play()
end

return Audio