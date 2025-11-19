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

        -- Draw journal overlay if open
        if Game.journalOpen then
            UI.drawJournal()
        end

        -- Draw band unlock notification if recent
        UI.drawBandUnlockNotification()
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
        "Tune to find signals...\n\nArrows/A & D - Tune | Q & E - Switch Bands\nTAB/J - Journal | Lock onto signals to decode",
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
    love.graphics.printf("CONTROLS:", 100, 410, 600, "center")

    love.graphics.setColor(Config.colors.white)
    love.graphics.printf("Arrow Keys / A & D - Tune Frequency\nQ & E - Switch Bands | 1-5 - Select Band\nSPACE - Decode Message | J/TAB - Journal\nUP/DOWN - Volume | ESC - Quit", 100, 430, 600, "center")

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

function UI.drawBandUnlockNotification()
    if not Game.lastUnlockedBand then return end

    -- Show notification for 4 seconds
    local elapsed = love.timer.getTime() - Game.lastUnlockedBand.time
    if elapsed > 4 then
        Game.lastUnlockedBand = nil
        return
    end

    -- Fade in/out effect
    local alpha = 1.0
    if elapsed < 0.3 then
        alpha = elapsed / 0.3
    elseif elapsed > 3.5 then
        alpha = (4 - elapsed) / 0.5
    end

    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7 * alpha)
    love.graphics.rectangle("fill", 150, 200, 500, 200)

    -- Border with band color
    local band = Game.bands[Game.lastUnlockedBand.index]
    if band then
        love.graphics.setColor(band.color[1], band.color[2], band.color[3], alpha)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", 150, 200, 500, 200)
        love.graphics.setLineWidth(1)
    end

    -- Title
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.green[1], Config.colors.green[2], Config.colors.green[3], alpha)
    love.graphics.printf("BAND UNLOCKED", 150, 220, 500, "center")

    -- Band name
    love.graphics.setFont(UI.fonts.title)
    if band then
        love.graphics.setColor(band.color[1], band.color[2], band.color[3], alpha)
        love.graphics.printf(band.name, 150, 260, 500, "center")
    end

    -- Description
    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.white[1], Config.colors.white[2], Config.colors.white[3], alpha)
    if band then
        love.graphics.printf(band.description, 150, 300, 500, "center")
    end

    -- Hint
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim[1], Config.colors.greenDim[2], Config.colors.greenDim[3], alpha)
    love.graphics.printf("Press " .. Game.lastUnlockedBand.index .. " or Q/E to switch", 150, 350, 500, "center")
end

function UI.drawJournal()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Journal panel
    local panelX = 50
    local panelY = 40
    local panelWidth = 700
    local panelHeight = 520

    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)

    -- Border
    love.graphics.setColor(Config.colors.green)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)

    -- Title
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.green)
    love.graphics.printf("TRANSMISSION LOG", panelX, panelY + 10, panelWidth, "center")

    -- Instructions
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("Press J or TAB to close | ESC to close", panelX, panelY + 40, panelWidth, "center")

    -- Separator line
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.line(panelX + 20, panelY + 65, panelX + panelWidth - 20, panelY + 65)

    -- List decoded messages
    local yOffset = panelY + 80
    local entryHeight = 85
    local decodedCount = 0

    for i, msg in ipairs(Game.messages) do
        if msg.decoded then
            decodedCount = decodedCount + 1

            -- Entry background
            love.graphics.setColor(Config.colors.background)
            love.graphics.rectangle("fill", panelX + 20, yOffset, panelWidth - 40, entryHeight)

            -- Entry border
            love.graphics.setColor(Config.colors.greenDim)
            love.graphics.rectangle("line", panelX + 20, yOffset, panelWidth - 40, entryHeight)

            -- Frequency
            love.graphics.setFont(UI.fonts.message)
            love.graphics.setColor(Config.colors.yellow)
            love.graphics.printf(
                string.format("%.1f MHz", msg.frequency),
                panelX + 30, yOffset + 5, 150, "left"
            )

            -- Morse code
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(Config.colors.green)
            love.graphics.printf(
                "MORSE: " .. (msg.morse or "N/A"),
                panelX + 200, yOffset + 8, panelWidth - 220, "left"
            )

            -- Message text
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(Config.colors.white)
            love.graphics.printf(
                msg.text,
                panelX + 30, yOffset + 28, panelWidth - 60, "left"
            )

            yOffset = yOffset + entryHeight + 10

            -- Stop if we run out of space
            if yOffset > panelY + panelHeight - 50 then
                break
            end
        end
    end

    -- Show message if no decoded messages yet
    if decodedCount == 0 then
        love.graphics.setFont(UI.fonts.message)
        love.graphics.setColor(Config.colors.greenDim)
        love.graphics.printf(
            "No transmissions decoded yet.\n\nTune the radio and lock onto signals\nto decode messages.",
            panelX, panelY + 200, panelWidth, "center"
        )
    end
end

return UI