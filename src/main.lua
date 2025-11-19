-- Signal Lost - A Radio Wave Mystery Game

require("config")
require("audio")
require("ui")
require("game")
require("effects")

function love.load()
    love.window.setTitle("Signal Lost - Radio Wave Mystery")
    love.window.setMode(800, 600)
    
    -- Initialize systems
    Config.init()
    Audio.init()
    UI.init()
    Game.init()
    Effects.init()
end

function love.update(dt)
    Game.update(dt)
    Audio.update(dt)
    UI.update(dt)
    Effects.update(dt)
end

function love.draw()
    Effects.beginDraw()
    UI.draw()
    Effects.endDraw()
end

function love.keypressed(key)
    Game.keypressed(key)
end