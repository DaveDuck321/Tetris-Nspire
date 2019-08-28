local lastPressed = ""
local screenInvalid = true
local lastFrameTime = 0

local screen = platform.window
local options = {
    enableHold = true,
    enableGhost = true,
    enableNext = true
}

--Tool palette (might be a better way to do this)
function newGame()
    Init(0)
end
function newGame5()
    Init(4)
end
function newGame10()
    Init(9)
end
function newGame15()
    Init(14)
end

function toggleHold()
    options.enableHold = not options.enableHold
    screenInvalid = true
end
function toggleNext()
    options.enableNext = not options.enableNext
    screenInvalid = true
end
function toggleGhost()
    options.enableGhost = not options.enableGhost
    screenInvalid = true
end
local menu = {
    {"New Game",
        {"Level: 1", newGame},
        {"Level: 5", newGame5},
        {"Level: 10", newGame10},
        {"Level: 15", newGame15}
    },
    {"Options",
        {"Toggle next box", toggleNext},
        {"Toggle hold", toggleHold},
        {"Toggle ghost piece", toggleGhost}
    }
}

--Events
function on.construction()
    on.create()
end

function on.create()
    toolpalette.register(menu)
    lastFrameTime = timer.getMilliSecCounter()
    Init(0)
    on.timer()
end

function on.paint(gc, x, y, width, height)
    Draw(gc, screen:width(), screen:height())
end

function on.timer(gc)
    local time = timer.getMilliSecCounter()

    Update(time-lastFrameTime, lastPressed)
    if(screenInvalid) then
        screen:invalidate()
        screenInvalid = false
    end

    lastPressed = ""
    lastFrameTime = time
    timer.start(0.015)
end

function on.arrowKey(key)
    lastPressed = key
end

function on.charIn(char)
    lastPressed = char
end

function on.contextMenu() --Doesnt work
    lastPressed = "esc"
end

function on.enterKey()
    lastPressed = "enter"
    on.timer()
end

function on.escapeKey()
    lastPressed = "esc"
    on.timer()
end

function on.getFocus()
    lastPressed = "esc" --auto pause
    on.timer()
end