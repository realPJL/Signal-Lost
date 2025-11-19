UI = {}

function UI.init()
    -- Fonts
    UI.fonts = {
        title = love.graphics.newFont(24),
        message = love.graphics.newFont(16),
        small = love.graphics.newFont(12)
    }
    
    -- Waveform visualization data
    UI.waveformPoints = {}
    for i = 1, 100 do
        UI.waveformPoints[i] = 0
    end
end

function UI.update(dt)
    UI.updateWaveform()
end

function UI.updateWaveform()
    -- Shift waveform points
    for i = #UI.waveformPoints, 2, -1 do
        UI.waveformPoints[i] = UI.waveformPoints[i - 1]
    end
    
    -- Generate new point
    local signalStrength = Game.state.signalStrength
    local noiseAmount = (1 - signalStrength) * 40
    local signalWave = math.sin(love.timer.getTime() * 10 * signalStrength) * signalStrength * 30
    UI.waveformPoints[1] = signalWave + (math.random() - 0.5) * noiseAmount
end

function UI.draw()
    UI.drawBackground()

    -- Show start screen or gameplay
    if Game.gameState == "start" then
        UI.drawStartScreen()
    else
        UI.drawTitle()
        UI.drawRadioPanel()
        UI.drawMessagePanel()
        UI.drawStatusBar()
    end
end

function UI.drawBackground()
    love.graphics.setColor(Config.colors.background)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
end

function UI.drawTitle()
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.green)
    love.graphics.printf("SIGNAL LOST", 0, 20, 800, "center")
end

function UI.drawRadioPanel()
    -- Panel background
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", 50, Config.ui.panelY, 700, Config.ui.panelHeight)
    
    -- Frequency display
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.yellow)
    love.graphics.printf(
        string.format("%.1f MHz", Game.state.currentFrequency),
        50, 100, 700, "center"
    )
    
    UI.drawFrequencyBar()
    UI.drawSignalMeter()
    UI.drawWaveform()
end

function UI.drawFrequencyBar()
    local barX = 100
    local barY = 150
    local barWidth = 600
    local barHeight = 30
    
    -- Bar background
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- Current frequency indicator
    local freqPercent = (Game.state.currentFrequency - Config.frequency.min) / 
                        (Config.frequency.max - Config.frequency.min)
    local indicatorX = barX + (barWidth * freqPercent)
    
    love.graphics.setColor(Config.colors.green)
    love.graphics.rectangle("fill", indicatorX - 2, barY, 4, barHeight)
    
    -- Signal markers (only show when messages exist and player is locked onto that message)
    if Game.messages then
        for i, msg in ipairs(Game.messages) do
            if not msg.decoded then
                if Game.state.lockedOn and Game.state.currentMessage == i then
                    local signalPercent = (msg.frequency - Config.frequency.min) / 
                                          (Config.frequency.max - Config.frequency.min)
                    local signalX = barX + (barWidth * signalPercent)
                    love.graphics.setColor(Config.colors.red)
                    love.graphics.circle("fill", signalX, barY + barHeight / 2, 5)
                end
            end
        end
    end
end

function UI.drawSignalMeter()
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.white)
    love.graphics.print("SIGNAL STRENGTH", 100, 200)
    
    local meterWidth = 200
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.rectangle("fill", 100, 220, meterWidth, 20)
    
    -- Signal strength fill
    local signalColor = Game.state.signalStrength > 0.9 and Config.colors.green or 
                        Game.state.signalStrength > 0.5 and Config.colors.yellow or 
                        Config.colors.red
    love.graphics.setColor(signalColor)
    love.graphics.rectangle("fill", 100, 220, meterWidth * Game.state.signalStrength, 20)
    
    -- Lock indicator
    if Game.state.lockedOn then
        love.graphics.setColor(Config.colors.green)
        love.graphics.print("LOCKED", 320, 220)
    end
end

function UI.drawWaveform()
    love.graphics.setColor(Config.colors.green)
    for i = 1, #UI.waveformPoints - 1 do
        local x1 = 400 + i * 3
        local y1 = 220 + UI.waveformPoints[i]
        local x2 = 400 + (i + 1) * 3
        local y2 = 220 + UI.waveformPoints[i + 1]
        love.graphics.line(x1, y1, x2, y2)
    end
end

function UI.drawMessagePanel()
    -- Panel background
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", 50, Config.ui.messageY, 700, Config.ui.messageHeight)
    
    if Game.state.lockedOn and not Game.state.messageRevealed then
        -- Show "MESSAGE FOUND" when locked but not yet decoded
        UI.drawMessageFound()
    elseif Game.state.messageRevealed and Game.messages[Game.state.currentMessage] then
        -- Show actual message after pressing SPACE
        UI.drawMessage()
    else
        -- Show instructions when not locked
        UI.drawInstructions()
    end
end

function UI.drawMessage()
    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.green)
    love.graphics.printf(
        Game.messages[Game.state.currentMessage].text,
        70, 300, 660, "left"
    )
    
    -- Show decode button
    UI.drawDecodeButton()
end

function UI.drawDecodeButton()
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.rectangle("fill", 325, 520, 150, 30)
    love.graphics.setColor(Config.colors.green)
    love.graphics.printf("SAVE MSG [SPACE]", 325, 527, 150, "center")
end

function UI.drawMessageFound()
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.green)
    
    -- Blinking effect
    local blink = math.sin(love.timer.getTime() * 3) > 0
    if blink then
        love.graphics.printf(">>> MESSAGE FOUND <<<", 50, 350, 700, "center")
    end
    
    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf(
        "\n\n\n\nPress SPACE to decode transmission",
        50, 350, 700, "center"
    )
end

function UI.drawInstructions()
    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf(
        "Tune to find signals...\n\nUse arrow keys or A/D to adjust frequency\nLock onto signals to receive transmissions",
        70, 320, 660, "center"
    )
end

function UI.drawStatusBar()
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf(
        string.format("Messages Decoded: %d/%d", Game.getDecodedCount(), #Game.messages),
        0, 570, 800, "center"
    )
end

function UI.drawStartScreen()
    -- Title
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.green)
    love.graphics.printf("SIGNAL LOST", 0, 80, 800, "center")

    -- Subtitle with blinking effect
    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("A Radio Wave Mystery", 0, 120, 800, "center")

    -- Story text
    local storyText = [[
Something is wrong with the airwaves.

Strange transmissions have been detected
across the frequency spectrum.

Your mission: Tune the radio receiver,
lock onto the signals, and decode
the mysterious messages.

But be warned...
Some secrets are better left buried
beneath the static.
]]

    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.white)
    love.graphics.printf(storyText, 100, 180, 600, "center")

    -- Volume control
    UI.drawVolumeControl()

    -- Controls
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("CONTROLS:", 100, 420, 600, "center")

    love.graphics.setColor(Config.colors.white)
    love.graphics.printf("Arrow Keys / A & D - Tune Frequency\nSPACE - Decode Message\nArrow Keys / W & S - Adjust Volume\nESC - Quit", 100, 440, 600, "center")

    -- Start prompt with blinking effect
    local blink = math.sin(love.timer.getTime() * 3) > 0
    if blink then
        love.graphics.setFont(UI.fonts.title)
        love.graphics.setColor(Config.colors.green)
        love.graphics.printf(">>> PRESS SPACE TO BEGIN <<<", 0, 530, 800, "center")
    end
end

function UI.drawVolumeControl()
    local volumeBarX = 720
    local volumeBarY = 200
    local volumeBarWidth = 30
    local volumeBarHeight = 250

    -- Label (rotated text effect by placing it above)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("VOLUME", volumeBarX - 15, volumeBarY - 25, 60, "center")

    -- Volume bar background
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.rectangle("fill", volumeBarX, volumeBarY, volumeBarWidth, volumeBarHeight)

    -- Volume bar fill (from bottom up)
    local volumePercent = Audio.masterVolume
    local fillHeight = volumeBarHeight * volumePercent
    love.graphics.setColor(Config.colors.green)
    love.graphics.rectangle("fill", volumeBarX, volumeBarY + volumeBarHeight - fillHeight, volumeBarWidth, fillHeight)

    -- Volume percentage text
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.white)
    love.graphics.printf(string.format("%d%%", math.floor(volumePercent * 100)), volumeBarX - 15, volumeBarY + volumeBarHeight + 10, 60, "center")

    -- Up/Down arrows indicator
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("▲", volumeBarX - 15, volumeBarY - 45, 60, "center")
    love.graphics.printf("▼", volumeBarX - 15, volumeBarY + volumeBarHeight + 30, 60, "center")
end

return UI