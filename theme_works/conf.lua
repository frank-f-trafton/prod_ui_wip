--jit.off()

function love.conf(t)
    t.console = false

    t.modules.audio = false
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = false
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = false
    t.modules.math = false
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = false
end
