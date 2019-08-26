----------------------------
----- GENERATED ASSETS -----
_R = {}
_R.IMG = {}
----- GENERATED ASSETS -----
----------------------------



----------------------------
----- '.\src\main.lua' -----
local lastPressed = ""
local lastFrameTime = 0

local screen = platform.window

--Events
function on.construction()
    on.create()
end

function on.create()
    Init()
    on.timer()
end

function on.paint(gc, x, y, width, height)
    Draw(gc, screen:width(), screen:height())
end

function on.timer(gc)
    local time = timer.getMilliSecCounter()

    Update(time-lastFrameTime, lastPressed)
    screen:invalidate()

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
----- '.\src\main.lua' -----
----------------------------
----------------------------
----- '.\src\game.lua' -----
local pieceGridSizes = {4, 3, 3, 2, 3, 3, 3}

local pieces = {{
    {0, 0, 0, 0}, {1, 1, 1, 1}, {0, 0, 0 ,0}, {0, 0, 0, 0}},
    {{2, 0, 0}, {2, 2, 2}, {0, 0, 0}},
    {{0, 0, 3}, {3, 3, 3}, {0, 0, 0}},
    {{4, 4}, {4, 4}},
    {{0, 5, 5}, {5, 5, 0}, {0, 0, 0}},
    {{0, 6, 0}, {6, 6, 6}, {0, 0, 0}},
    {{7, 7, 0}, {0, 7, 7}, {0, 0, 0}}
}

local board = {
    grid = {},
    next = {},
    dropping = {
        offsetX = 0,
        offsetY = 0,
        gridSize = 0,
        grid = {}
    }   
}

local progress = {
    score = 0,
    lines = 0,
    level = 0
}

local FPS = {
    frames = 0,
    totalTime = 0,
    FPS = 30
}

function setNextPiece()
    local newPiece = {}
    local pieceID = table.remove(board.next, #board.next)
    board.dropping.grid = {}
    board.dropping.gridSize = pieceGridSizes[pieceID]
    for y = 1, board.dropping.gridSize do
        table.insert(board.dropping.grid, {})
        for x = 1, board.dropping.gridSize do
            table.insert(board.dropping.grid[y], pieces[pieceID][y][x])
        end
    end
    board.dropping.offsetY = -1
    board.dropping.offsetX = 5-math.ceil(board.dropping.gridSize/2)

    pieceRandomizer()
end

function pieceRandomizer()
    if(#board.next<7) then
        local allPieces = {1, 2, 3, 4, 5, 6, 7}
        for i=1, 7 do
            table.insert(board.next, table.remove(allPieces, math.random(#allPieces)))
        end
    end
end

function Init()
    for y = 1, 20 do
        table.insert(board.grid, {})
        for x = 1, 10 do
            table.insert(board.grid[y], 0)
        end
    end
    board.grid[20][4] = 1
    pieceRandomizer()
    setNextPiece()
end

function Update(deltaTime, key)
    FPS.frames = FPS.frames + 1
    FPS.totalTime = FPS.totalTime + deltaTime
    if FPS.frames % 10 == 0 then
        FPS.FPS = FPS.frames/FPS.totalTime * 1000
        FPS.frames = 0
        FPS.totalTime = 0
    end
end
----- '.\src\game.lua' -----
----------------------------
----------------------------
----- '.\src\draw.lua' -----
local pieceColors = {{9, 253, 248}, {0, 0, 253}, {255, 169, 0}, {255, 255, 92}, {0, 255, 0}, {151, 2, 255}, {253, 0, 0}}

function drawFPS(gc)
    gc:setColorRGB(255, 0, 0)
    gc:drawString(math.floor(FPS.FPS*10)/10, 10, 5) --1 dp
end

function drawNextBox(gc, index, blockWidth, offsetX, top)
    local pieceID = board.next[index+1]
    local offsetY = top + index * (blockWidth * 4 + 10)
    local width = blockWidth * 4
    gc:setColorRGB(50, 50, 50)
    gc:fillRect(offsetX, offsetY, width, width)

    gc:setColorRGB(200, 200, 200)
    for x = 0, 4 do
        gc:fillRect(offsetX+x*blockWidth, offsetY, 1, width)
    end
    for y = 0, 4 do
        gc:fillRect(offsetX, y*blockWidth + offsetY, width, 1)
    end

    local color = pieceColors[pieceID]
    gc:setColorRGB(color[1], color[2], color[3])

    local gridSize = pieceGridSizes[pieceID]
    local sizeOffset = 1
    if(gridSize == 4) then sizeOffset = 0 end

    for x = 0, gridSize-1 do
        for y = 0, gridSize-1 do
            if(pieces[pieceID][y+1][x+1] ~= 0) then
                gc:fillRect(offsetX + (x+sizeOffset)*blockWidth + 1, (y+sizeOffset)*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
            end
        end
    end
end

function drawBoard(gc, screenWidth, height)
    local blockWidth = math.floor(height/20)
    local width = blockWidth * 10
    local offsetX = (screenWidth-width)/2
    local offsetY = (height - width*2)/2
    height = width*2

    gc:setColorRGB(50, 50, 50)
    gc:fillRect(offsetX, offsetY, width, height)

    gc:setColorRGB(200, 200, 200)
    for x = 0, 10 do
        gc:fillRect(offsetX+x*blockWidth, offsetY, 1, height)
    end
    for y = 0, 20 do
        gc:fillRect(offsetX, y*blockWidth + offsetY, width, 1)
    end
    for x = 0, 9 do
        for y = 0, 19 do
            local drop = board.dropping
            local dropX = x-drop.offsetX + 1
            local dropY = y-drop.offsetY + 1
            if(dropX > 0 and dropX <= drop.gridSize and dropY > 0 and dropY <= drop.gridSize) then
                if(drop.grid[dropY][dropX] ~= 0) then
                    local color = pieceColors[drop.grid[dropY][dropX]]
                    gc:setColorRGB(color[1], color[2], color[3])
                    gc:fillRect(offsetX + x*blockWidth + 1, y*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
                end
            end
            if(board.grid[y+1][x+1] ~= 0) then
                local color = pieceColors[board.grid[y+1][x+1]]
                gc:setColorRGB(color[1], color[2], color[3])
                gc:fillRect(offsetX + x*blockWidth + 1, y*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
            end
        end
    end

    drawNextBox(gc, 0, blockWidth, offsetX + width + 10, offsetY)
    drawNextBox(gc, 1, blockWidth, offsetX + width + 10, offsetY)
    drawNextBox(gc, 2, blockWidth, offsetX + width + 10, offsetY)
    drawNextBox(gc, 3, blockWidth, offsetX + width + 10, offsetY)
end

function Draw(gc, width, height)
    gc:setColorRGB(255, 255, 255)
    gc:fillRect(0, 0, width, height)
    drawBoard(gc, width, height)
    drawFPS(gc)
end
----- '.\src\draw.lua' -----
----------------------------
