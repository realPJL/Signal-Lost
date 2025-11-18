Effects = {}

function Effects.init()
    -- Create canvas for post-processing
    Effects.canvas = love.graphics.newCanvas(800, 600)
    
    -- Scanline settings
    Effects.scanlineIntensity = 0.15
    Effects.scanlineSpeed = 2
    Effects.scanlineOffset = 0
    
    -- Glitch settings
    Effects.glitchTimer = 0
    Effects.glitchDuration = 0
    Effects.glitchIntensity = 0
    Effects.nextGlitchTime = math.random(3, 8)
    
    -- CRT curvature shader
    Effects.crtShader = love.graphics.newShader([[
        extern number time;
        extern number glitchIntensity;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = texture_coords;
            
            // CRT curvature
            vec2 center = uv - 0.5;
            float dist = length(center);
            float curvature = 0.15;
            vec2 offset = center * dist * dist * curvature;
            uv = uv + offset;
            
            // Vignette effect
            float vignette = smoothstep(0.7, 0.3, dist);
            
            // Check if UV is out of bounds (black edges from curvature)
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                return vec4(0.05, 0.05, 0.08, 1.0);
            }
            
            // Sample texture
            vec4 texColor = Texel(texture, uv);
            
            // Scanlines
            float scanline = sin(uv.y * 600.0 + time * 2.0) * 0.04 + 0.96;
            
            // RGB shift for glitch effect
            if (glitchIntensity > 0.0) {
                float shift = glitchIntensity * 0.01;
                float r = Texel(texture, uv + vec2(shift, 0.0)).r;
                float g = Texel(texture, uv).g;
                float b = Texel(texture, uv - vec2(shift, 0.0)).b;
                texColor = vec4(r, g, b, texColor.a);
            }
            
            // Apply effects
            texColor.rgb *= scanline * vignette;
            
            // Phosphor glow (slight bloom on bright areas)
            texColor.rgb += texColor.rgb * 0.1;
            
            return texColor * color;
        }
    ]])
    
    -- Noise overlay for additional texture
    Effects.noiseTimer = 0
    Effects.noiseOpacity = 0.02
end

function Effects.update(dt)
    -- Update scanline animation
    Effects.scanlineOffset = Effects.scanlineOffset + Effects.scanlineSpeed * dt
    
    -- Update glitch effect
    Effects.glitchTimer = Effects.glitchTimer + dt
    
    if Effects.glitchDuration > 0 then
        Effects.glitchDuration = Effects.glitchDuration - dt
        Effects.glitchIntensity = math.random() * 3
    else
        Effects.glitchIntensity = 0
        
        -- Trigger random glitches
        if Effects.glitchTimer >= Effects.nextGlitchTime then
            Effects.glitchTimer = 0
            Effects.nextGlitchTime = math.random(3, 8)
            Effects.glitchDuration = math.random() * 0.1 + 0.05
        end
    end
    
    -- Add glitch when tuning (based on signal strength)
    if Game.state.signalStrength < 0.5 and math.random() < 0.1 then
        Effects.glitchDuration = 0.05
    end
    
    Effects.noiseTimer = Effects.noiseTimer + dt
end

function Effects.beginDraw()
    -- Start drawing to canvas
    love.graphics.setCanvas(Effects.canvas)
    love.graphics.clear()
end

function Effects.endDraw()
    -- Stop drawing to canvas
    love.graphics.setCanvas()
    
    -- Apply shader and draw canvas to screen
    love.graphics.setShader(Effects.crtShader)
    Effects.crtShader:send("time", Effects.scanlineOffset)
    Effects.crtShader:send("glitchIntensity", Effects.glitchIntensity)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Effects.canvas, 0, 0)
    
    -- Add screen glitch horizontal lines
    if Effects.glitchDuration > 0 then
        Effects.drawGlitchLines()
    end
    
    -- Add film grain/noise
    Effects.drawNoise()
    
    love.graphics.setShader()
end

function Effects.drawGlitchLines()
    love.graphics.setColor(0.2, 0.9, 0.3, 0.3)
    
    -- Random horizontal displacement lines
    for i = 1, 3 do
        local y = math.random(0, 600)
        local height = math.random(1, 5)
        local offset = (math.random() - 0.5) * Effects.glitchIntensity * 10
        
        love.graphics.rectangle("fill", offset, y, 800, height)
    end
end

function Effects.drawNoise()
    -- Draw random noise pixels for film grain effect
    love.graphics.setColor(1, 1, 1, Effects.noiseOpacity)
    
    for i = 1, 50 do
        local x = math.random(0, 800)
        local y = math.random(0, 600)
        love.graphics.points(x, y)
    end
end

function Effects.triggerGlitch(duration)
    -- Manually trigger a glitch effect
    Effects.glitchDuration = duration or 0.1
end

return Effects