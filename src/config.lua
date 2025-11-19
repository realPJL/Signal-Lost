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
        white = {1, 1, 1},
        orange = {0.9, 0.5, 0.2},
        cyan = {0.2, 0.8, 0.9},
        purple = {0.7, 0.3, 0.9},
        blue = {0.3, 0.5, 0.9}
    }
    
    -- Frequency settings (global range)
    Config.frequency = {
        min = 80.0,
        max = 140.0,
        tuningSpeed = 0.1
    }
    
    -- Signal detection
    Config.signal = {
        lockThreshold = 0.9,
        unlockThreshold = 0.7,
        detectionRange = 2.0
    }
    
    -- Frequency Bands
    Config.bands = {
        {
            id = "civilian",
            name = "CIVILIAN",
            description = "Public broadcasts and distress calls",
            color = Config.colors.orange,
            colorDim = {0.4, 0.2, 0.1},
            minFreq = 80.0,
            maxFreq = 92.0,
            unlocked = true,
            messages = {
                {
                    frequency = 83.2,
                    text = "...is anyone out there? This is Station Alpha...\nIf you can hear this, please respond.\nThe waves... they're not natural...\nREPEAT NOT NATURAL.",
                    morse = "SOS SOS",
                    decoded = false
                },
                {
                    frequency = 87.5,
                    text = "This is civilian broadcast station... We've been\nevacuated from the coast. Strange signals interfering\nwith all communications. If anyone can hear this...",
                    morse = "HELP US",
                    decoded = false
                },
                {
                    frequency = 90.8,
                    text = "My family and I are trapped in the lighthouse.\nWe can see them in the water. They're not...human.\nPlease, someone respond. Battery dying.",
                    morse = "TRAPPED",
                    decoded = false
                }
            }
        },
        {
            id = "emergency",
            name = "EMERGENCY",
            description = "Emergency services and evacuations",
            color = Config.colors.yellow,
            colorDim = {0.4, 0.3, 0.1},
            minFreq = 92.0,
            maxFreq = 104.0,
            unlocked = true,
            messages = {
                {
                    frequency = 95.5,
                    text = "URGENT: Do not approach the shoreline.\nThe sound... it's calling them.\nWe were wrong about everything.\nEvacuation protocol FAILED.",
                    morse = "DANGER",
                    decoded = false
                },
                {
                    frequency = 99.2,
                    text = "All emergency services evacuate immediately.\nRepeat: EVACUATE. The coastal zone is lost.\nDo not attempt rescue operations.",
                    morse = "EVACUATE",
                    decoded = false
                },
                {
                    frequency = 102.3,
                    text = "Day 47: The interference is getting stronger.\nWe've lost contact with the mainland.\nThe pattern repeats every 6 hours.\nGod help us all.",
                    morse = "DAY 47",
                    decoded = false
                }
            }
        },
        {
            id = "military",
            name = "MILITARY",
            description = "Tactical military communications",
            color = Config.colors.green,
            colorDim = Config.colors.greenDim,
            minFreq = 104.0,
            maxFreq = 116.0,
            unlocked = false,
            unlockHint = "Decode all EMERGENCY messages",
            messages = {
                {
                    frequency = 107.8,
                    text = "RECON TEAM DELTA UNDER HEAVY FIRE.\nThey're not in the water anymore. They're HERE.\nRequesting immediate air support. RESPOND!",
                    morse = "MAYDAY",
                    decoded = false
                },
                {
                    frequency = 110.5,
                    text = "Command, this is FOB Sierra. We've established\na perimeter but the sounds... they're affecting\nour troops. Request permission to fall back.",
                    morse = "SIERRA",
                    decoded = false
                },
                {
                    frequency = 113.9,
                    text = "All units retreat to Rally Point Gamma.\nOperation Lighthouse is a failure. I repeat: FAILURE.\nDo not engage the entities. Fall back NOW.",
                    morse = "RETREAT",
                    decoded = false
                }
            }
        },
        {
            id = "research",
            name = "RESEARCH",
            description = "Scientific research stations",
            color = Config.colors.cyan,
            colorDim = {0.1, 0.3, 0.4},
            minFreq = 116.0,
            maxFreq = 128.0,
            unlocked = false,
            unlockHint = "Decode all MILITARY messages",
            messages = {
                {
                    frequency = 118.3,
                    text = "Research Station Theta: The signal originates from\n2000 meters below the surface. It's been there for...\ncalculations show... thousands of years.",
                    morse = "THETA",
                    decoded = false
                },
                {
                    frequency = 122.7,
                    text = "Dr. Morrison's log: The frequency modulation matches\nno known natural phenomenon. It's communicating.\nIt's BEEN communicating. We just never listened.",
                    morse = "ANCIENT",
                    decoded = false
                },
                {
                    frequency = 125.4,
                    text = "Final entry: We translated part of the signal.\nIt's not a message. It's a song. A lullaby.\nAnd now we understand. God forgive us.",
                    morse = "SONG",
                    decoded = false
                }
            }
        },
        {
            id = "unknown",
            name = "UNKNOWN",
            description = "Unidentified signal source",
            color = Config.colors.purple,
            colorDim = {0.3, 0.1, 0.4},
            minFreq = 128.0,
            maxFreq = 140.0,
            unlocked = false,
            unlockHint = "Decode all RESEARCH messages",
            messages = {
                {
                    frequency = 130.2,
                    text = "T̴H̴E̴Y̴ ̴S̴L̴E̴E̴P̴ ̴B̴E̴N̴E̴A̴T̴H̴ ̴T̴H̴E̴ ̴W̴A̴V̴E̴S̴\nWAITING... LISTENING... SINGING...\nTHE DEPTHS CALL. THE SONG SPREADS.\nJ̵O̵I̵N̵ ̵U̵S̵.",
                    morse = "JOIN US",
                    decoded = false
                },
                {
                    frequency = 134.8,
                    text = "...transmission received from Station Alpha...\nFinal transmission: If you're hearing this,\nwe're already gone. The waves carry something.\nSomething ancient. Don't listen too long.",
                    morse = "GOODBYE",
                    decoded = false
                }
            }
        }
    }

    -- Legacy messages array (for backward compatibility)
    -- This will be populated from bands in Game.init()
    Config.messages = {}
    
    -- UI layout
    Config.ui = {
        panelY = 80,
        panelHeight = 180,
        messageY = 280,
        messageHeight = 280
    }
end

return Config