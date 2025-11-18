-- Signal Lost - A Radio Wave Mystery Game

function love.load()
    -- Window setup
    love.window.setTitle("Signal Lost - Radio Wave Mystery")
    love.window.setMode(800, 600)

    -- Fonts
    titleFont = love.graphics.newFont(24)
    smallFont = love.graphics.newFont(12)

    -- Colors
    colors = {
        background = {0.05, 0.05, 0.08},
        green = {0.2, 0.9, 0.3},
        panel = {0.1, 0.12, 0.15},
        yellow = {0.9, 0.8, 0.2},
        greenDim = {0.1, 0.4, 0.15},
        white = {1, 1, 1}
    }
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
    love.graphics.printf(string.format("%.1f MHz", -1), 50, 100, 700, "center") -- TODO: Change Frequency

    -- Frequency bar
    local barX = 100
    local barY = 150
    local barWidth = 600
    local barHeight = 30

    love.graphics.setColor(colors.greenDim)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    -- Signal strength meter
    love.graphics.setFont(smallFont)
    love.graphics.setColor(colors.white)
    love.graphics.print("SIGNAL STRENGTH", 100, 200)
    
    local meterWidth = 200
    love.graphics.setColor(colors.greenDim)
    love.graphics.rectangle("fill", 100, 220, meterWidth, 20)

    -- Message display
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", 50, 280, 700, 280)
end