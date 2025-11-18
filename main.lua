-- Signal Lost - A Radio Wave Mystery Game

function love.load()
    -- Window setup
    love.window.setTitle("Signal Lost - Radio Wave Mystery")
    love.window.setMode(800, 600)

    -- Fonts
    titleFont = love.graphics.newFont(24)

    -- Colors
    colors = {
        background = {0.05, 0.05, 0.08},
        green = {0.2, 0.9, 0.3}
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
end