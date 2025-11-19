Config = {}

function Config.init()
    -- Color palette
    Config.colors = {
        background = {0.05, 0.05, 0.08},
        panel = {0.1, 0.12, 0.15},
        green = {0.2, 0.9, 0.3},
        greenDim = {0.1, 0.4, 0.15},
        red = {0.9, 0.2, 0.2},
        yellow = {0.9, 0.8, 0.2},
        white = {1, 1, 1}
    }
    
    -- Frequency settings
    Config.frequency = {
        min = 80.0,
        max = 120.0,
        tuningSpeed = 0.1
    }
    
    -- Signal detection
    Config.signal = {
        lockThreshold = 0.9,
        unlockThreshold = 0.7,
        detectionRange = 2.0
    }
    
    -- Messages
    Config.messages = {
        {
            frequency = 83.2,
            text = "...is anyone out there? This is Station ...\nIf you can ..., please respond.\nThe waves... they're not na...\nREPEAT NOT....",
            morse = "SOS SOS",
            decoded = false
        },
        {
            frequency = 95.5,
            text = "Final transmission Station ...: If you're hearing this,\nwe're already gone. The waves carry something.\nSomething ancient. Don't listen too long.",
            morse = "GOODBYE",
            decoded = false
        },
        {
            frequency = 102.3,
            text = "Day 47: The interference is getting stronger.\nWe've lost contact with ....\nThe pattern repeats every ... hours.",
            morse = "DAY 47",
            decoded = false
        },
        {
            frequency = 107.8,
            text = "URGENT: Do not approach the shoreline.\nThe sound... it's calling them.\nWe were wrong about everything.",
            morse = "DANGER",
            decoded = false
        },
        {
            frequency = 115.1,
            text = "... REPEAT RECON TEAM DELTA UNDER HEAVY FIRE ...",
            morse = "SOS",
            decoded = false
        }
    }
    
    -- UI layout
    Config.ui = {
        panelY = 80,
        panelHeight = 180,
        messageY = 280,
        messageHeight = 280
    }
end

return Config