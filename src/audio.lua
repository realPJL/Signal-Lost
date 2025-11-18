Audio = {}

function Audio.init()
    -- Generate procedural static noise
    Audio.staticSource = Audio.generateStatic()
    Audio.staticSource:setLooping(true)
    Audio.staticSource:setVolume(0.3)
    Audio.staticSource:play()
    
    Audio.baseVolume = 0.3
end

function Audio.update()
    -- Adjust static volume based on signal strength
    local signalStrength = Game.state.signalStrength
    local volume = Audio.baseVolume * (1 - signalStrength * 0.8)
    Audio.staticSource:setVolume(volume)
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

return Audio