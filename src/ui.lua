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

    -- Show start screen, ending screen, or gameplay
    if Game.gameState == "start" then
        UI.drawStartScreen()
    elseif Game.gameState == "ending" then
        UI.drawEndingScreen()
    else
        -- Playing state
        UI.drawTitle()
        UI.drawBandSelector()
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

function UI.drawBandSelector()
    local selectorY = 52
    local selectorHeight = 24
    local bandWidth = 140
    local spacing = 10
    local startX = (800 - (bandWidth * 5 + spacing * 4)) / 2

    -- Draw each band
    for i, band in ipairs(Game.bands) do
        local x = startX + (i - 1) * (bandWidth + spacing)
        local isCurrent = (i == Game.currentBandIndex)

        -- Background
        if band.unlocked then
            if isCurrent then
                -- Current band - bright colored background
                love.graphics.setColor(band.color[1], band.color[2], band.color[3], 0.3)
                love.graphics.rectangle("fill", x, selectorY, bandWidth, selectorHeight)
            else
                -- Unlocked but not current - dim background
                love.graphics.setColor(band.colorDim[1], band.colorDim[2], band.colorDim[3], 0.2)
                love.graphics.rectangle("fill", x, selectorY, bandWidth, selectorHeight)
            end
        else
            -- Locked band - very dim
            love.graphics.setColor(0.1, 0.1, 0.1, 0.3)
            love.graphics.rectangle("fill", x, selectorY, bandWidth, selectorHeight)
        end

        -- Border
        if isCurrent then
            -- Current band - thick bright border
            love.graphics.setLineWidth(2)
            love.graphics.setColor(band.color)
            love.graphics.rectangle("line", x, selectorY, bandWidth, selectorHeight)
            love.graphics.setLineWidth(1)
        else
            -- Other bands - thin border
            if band.unlocked then
                love.graphics.setColor(band.colorDim)
            else
                love.graphics.setColor(0.2, 0.2, 0.2)
            end
            love.graphics.rectangle("line", x, selectorY, bandWidth, selectorHeight)
        end

        -- Band name and number
        love.graphics.setFont(UI.fonts.small)
        if band.unlocked then
            if isCurrent then
                love.graphics.setColor(band.color)
            else
                love.graphics.setColor(band.colorDim)
            end
            love.graphics.printf(i .. ". " .. band.name, x, selectorY + 6, bandWidth, "center")
        else
            -- Locked indicator
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.printf(i .. ". LOCKED", x, selectorY + 6, bandWidth, "center")
        end
    end

    -- Navigation hints
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.print("Q", startX - 20, selectorY + 6)
    love.graphics.print("E", startX + (bandWidth * 5 + spacing * 4) + 10, selectorY + 6)
end

function UI.drawRadioPanel()
    -- Panel background
    love.graphics.setColor(Config.colors.panel)
    love.graphics.rectangle("fill", 50, Config.ui.panelY, 700, Config.ui.panelHeight)

    -- Get current band for theming
    local currentBand = Game.getCurrentBand()

    -- Frequency display (use current band color)
    love.graphics.setFont(UI.fonts.title)
    if currentBand then
        love.graphics.setColor(currentBand.color)
    else
        love.graphics.setColor(Config.colors.yellow)
    end
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

    -- Draw band sections
    local totalRange = Config.frequency.max - Config.frequency.min

    for i, band in ipairs(Game.bands) do
        local bandStart = band.minFreq
        local bandEnd = band.maxFreq
        local startPercent = (bandStart - Config.frequency.min) / totalRange
        local endPercent = (bandEnd - Config.frequency.min) / totalRange

        local sectionX = barX + (barWidth * startPercent)
        local sectionWidth = barWidth * (endPercent - startPercent)

        -- Current band - brighter, others - dimmer
        local isCurrent = (i == Game.currentBandIndex)

        if band.unlocked then
            if isCurrent then
                -- Current band - bright colored background
                love.graphics.setColor(band.color[1], band.color[2], band.color[3], 0.4)
            else
                -- Other unlocked bands - dim colored background
                love.graphics.setColor(band.colorDim[1], band.colorDim[2], band.colorDim[3], 0.3)
            end
        else
            -- Locked bands - very dim
            love.graphics.setColor(0.15, 0.15, 0.15, 0.5)
        end

        love.graphics.rectangle("fill", sectionX, barY, sectionWidth, barHeight)

        -- Draw band boundaries
        love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
        love.graphics.setLineWidth(1)
        love.graphics.line(sectionX, barY, sectionX, barY + barHeight)
    end

    -- Current frequency indicator (bright and visible)
    local freqPercent = (Game.state.currentFrequency - Config.frequency.min) / totalRange
    local indicatorX = barX + (barWidth * freqPercent)

    love.graphics.setColor(Config.colors.white)
    love.graphics.setLineWidth(3)
    love.graphics.line(indicatorX, barY - 5, indicatorX, barY + barHeight + 5)
    love.graphics.setLineWidth(1)

    -- Signal markers (only show when messages exist and player is locked onto that message)
    if Game.messages then
        for i, msg in ipairs(Game.messages) do
            if not msg.decoded then
                if Game.state.lockedOn and Game.state.currentMessage == i then
                    local signalPercent = (msg.frequency - Config.frequency.min) / totalRange
                    local signalX = barX + (barWidth * signalPercent)
                    love.graphics.setColor(Config.colors.red)
                    love.graphics.circle("fill", signalX, barY + barHeight / 2, 5)
                end
            end
        end
    end

    -- Bar border
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
end

function UI.drawSignalMeter()
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.white)
    love.graphics.print("SIGNAL STRENGTH", 100, 200)

    local meterWidth = 200
    local currentBand = Game.getCurrentBand()

    -- Meter background (use current band's dim color)
    if currentBand then
        love.graphics.setColor(currentBand.colorDim)
    else
        love.graphics.setColor(Config.colors.greenDim)
    end
    love.graphics.rectangle("fill", 100, 220, meterWidth, 20)

    -- Signal strength fill (use current band's color when locked)
    if Game.state.signalStrength > 0.9 then
        if currentBand then
            love.graphics.setColor(currentBand.color)
        else
            love.graphics.setColor(Config.colors.green)
        end
    elseif Game.state.signalStrength > 0.5 then
        love.graphics.setColor(Config.colors.yellow)
    else
        love.graphics.setColor(Config.colors.red)
    end
    love.graphics.rectangle("fill", 100, 220, meterWidth * Game.state.signalStrength, 20)

    -- Lock indicator (use current band's color)
    if Game.state.lockedOn then
        if currentBand then
            love.graphics.setColor(currentBand.color)
        else
            love.graphics.setColor(Config.colors.green)
        end
        love.graphics.print("LOCKED", 320, 220)
    end
end

function UI.drawWaveform()
    -- Use current band's color for waveform
    local currentBand = Game.getCurrentBand()
    if currentBand then
        love.graphics.setColor(currentBand.color)
    else
        love.graphics.setColor(Config.colors.green)
    end

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

    -- Get current band info
    local band = Game.getCurrentBand()
    if band then
        -- Show current band name and progress
        love.graphics.setColor(band.color)
        local bandProgress = string.format("%s: %d/%d", band.name, Game.getDecodedCount(), #Game.messages)
        love.graphics.print(bandProgress, 20, 570)
    end

    -- Show total progress across all bands
    local totalDecoded = 0
    local totalMessages = 0
    for _, b in ipairs(Game.bands) do
        for _, msg in ipairs(b.messages) do
            totalMessages = totalMessages + 1
            if msg.decoded then
                totalDecoded = totalDecoded + 1
            end
        end
    end

    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf(
        string.format("Total: %d/%d", totalDecoded, totalMessages),
        0, 570, 780, "right"
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

function UI.drawEndingScreen()
    -- Title
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.green)
    love.graphics.printf("SIGNAL LOST", 0, 60, 800, "center")

    -- Victory subtitle
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(Config.colors.cyan)
    love.graphics.printf("ALL TRANSMISSIONS DECODED", 0, 110, 800, "center")

    -- Story conclusion text
    local endingText = [[
You have listened to all the transmissions.
The pieces of the puzzle are now clear.

Something ancient sleeps beneath the waves.
Something that has been singing for millennia.
A lullaby from the depths, calling...

The coastal zone is lost.
The signals continue to spread.
And now you understand why some secrets
are better left buried beneath the static.

The waves remember.
The waves call.
The waves sing.]]

    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.white)
    love.graphics.printf(endingText, 100, 170, 600, "center")

    -- Credits
    love.graphics.setFont(UI.fonts.message)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("Thanks for playing!", 0, 470, 800, "center")

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("Code: Claude & Paul | Story & Idea: Paul", 0, 490, 800, "center")

    -- Options with blinking effect for restart
    local blink = math.sin(love.timer.getTime() * 3) > 0
    if blink then
        love.graphics.setFont(UI.fonts.message)
        love.graphics.setColor(Config.colors.green)
        love.graphics.printf(">>> PRESS SPACE TO RESTART <<<", 0, 510, 800, "center")
    end

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.printf("ESC - Quit", 0, 550, 800, "center")
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
    love.graphics.printf("W/S or UP/DOWN to scroll | J/TAB/ESC to close", panelX, panelY + 40, panelWidth, "center")

    -- Separator line
    love.graphics.setColor(Config.colors.greenDim)
    love.graphics.line(panelX + 20, panelY + 65, panelX + panelWidth - 20, panelY + 65)

    -- List messages grouped by band
    local contentStartY = panelY + 75
    local yOffset = contentStartY - Game.journalScrollOffset  -- Apply scroll offset
    local entryHeight = 70
    local bandHeaderHeight = 25
    local totalDecoded = 0
    local viewportTop = contentStartY
    local viewportBottom = panelY + panelHeight - 20
    local totalContentHeight = 0  -- Track total content height for scroll clamping

    -- Enable scissor for clipping content to viewport
    love.graphics.setScissor(panelX + 20, viewportTop, panelWidth - 40, viewportBottom - viewportTop)

    for bandIndex, band in ipairs(Game.bands) do
        -- Count decoded messages in this band
        local bandDecoded = 0
        for _, msg in ipairs(band.messages) do
            if msg.decoded then
                bandDecoded = bandDecoded + 1
                totalDecoded = totalDecoded + 1
            end
        end

        -- Show band if it has decoded messages OR if it's unlocked
        if bandDecoded > 0 or band.unlocked then
            -- Band header
            love.graphics.setColor(band.color[1], band.color[2], band.color[3], 0.3)
            love.graphics.rectangle("fill", panelX + 20, yOffset, panelWidth - 40, bandHeaderHeight)

            love.graphics.setColor(band.color)
            love.graphics.rectangle("line", panelX + 20, yOffset, panelWidth - 40, bandHeaderHeight)

            love.graphics.setFont(UI.fonts.message)
            love.graphics.setColor(band.color)
            love.graphics.printf(
                string.format("%s (%d/%d)", band.name, bandDecoded, #band.messages),
                panelX + 30, yOffset + 5, panelWidth - 60, "left"
            )

            yOffset = yOffset + bandHeaderHeight + 5

            -- Show decoded messages from this band
            if bandDecoded > 0 then
                for _, msg in ipairs(band.messages) do
                    if msg.decoded then
                        -- Entry background
                        love.graphics.setColor(Config.colors.background)
                        love.graphics.rectangle("fill", panelX + 30, yOffset, panelWidth - 60, entryHeight)

                        -- Entry border
                        love.graphics.setColor(band.colorDim)
                        love.graphics.rectangle("line", panelX + 30, yOffset, panelWidth - 60, entryHeight)

                        -- Frequency and Morse code on same line
                        love.graphics.setFont(UI.fonts.small)
                        love.graphics.setColor(band.color)
                        love.graphics.printf(
                            string.format("%.1f MHz | MORSE: %s", msg.frequency, msg.morse or "N/A"),
                            panelX + 40, yOffset + 5, panelWidth - 80, "left"
                        )

                        -- Message text
                        love.graphics.setFont(UI.fonts.small)
                        love.graphics.setColor(Config.colors.white)
                        love.graphics.printf(
                            msg.text,
                            panelX + 40, yOffset + 22, panelWidth - 80, "left"
                        )

                        yOffset = yOffset + entryHeight + 5
                    end
                end
            elseif band.unlocked and bandDecoded == 0 then
                -- Show hint for unlocked but empty bands
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(Config.colors.greenDim)
                love.graphics.printf(
                    "No messages decoded yet.",
                    panelX + 40, yOffset + 5, panelWidth - 80, "left"
                )
                yOffset = yOffset + 25
            end

            yOffset = yOffset + 5  -- Spacing between bands
        elseif not band.unlocked then
            -- Show locked band with unlock hint
            -- Locked band header
            love.graphics.setColor(0.2, 0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", panelX + 20, yOffset, panelWidth - 40, bandHeaderHeight)

            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("line", panelX + 20, yOffset, panelWidth - 40, bandHeaderHeight)

            love.graphics.setFont(UI.fonts.message)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.printf(
                band.name .. " - LOCKED",
                panelX + 30, yOffset + 5, panelWidth - 60, "left"
            )

            yOffset = yOffset + bandHeaderHeight + 5

            -- Unlock hint
            if band.unlockHint then
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(Config.colors.greenDim)
                love.graphics.printf(
                    "Unlock: " .. band.unlockHint,
                    panelX + 40, yOffset, panelWidth - 80, "left"
                )
                yOffset = yOffset + 25
            end
        end
    end

    -- Calculate total content height
    totalContentHeight = (yOffset + Game.journalScrollOffset) - contentStartY

    -- Disable scissor
    love.graphics.setScissor()

    -- Clamp scroll offset to valid range
    local maxScroll = math.max(0, totalContentHeight - (viewportBottom - viewportTop))
    Game.journalScrollOffset = math.min(Game.journalScrollOffset, maxScroll)

    -- Show scroll indicators
    if totalContentHeight > (viewportBottom - viewportTop) then
        -- Can scroll down
        if Game.journalScrollOffset < maxScroll then
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(Config.colors.green)
            love.graphics.printf("▼ MORE ▼", panelX, viewportBottom, panelWidth, "center")
        end

        -- Can scroll up
        if Game.journalScrollOffset > 0 then
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(Config.colors.green)
            love.graphics.printf("▲ MORE ▲", panelX, viewportTop - 15, panelWidth, "center")
        end
    end

    -- Show message if no decoded messages yet
    if totalDecoded == 0 then
        love.graphics.setFont(UI.fonts.message)
        love.graphics.setColor(Config.colors.greenDim)
        love.graphics.printf(
            "No transmissions decoded yet.\n\nTune the radio and lock onto signals\nto decode messages.",
            panelX, panelY + 200, panelWidth, "center"
        )
    end
end

return UI