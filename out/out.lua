----------------------------
----- GENERATED ASSETS -----
_R = {}
_R.IMG = {}
----- GENERATED ASSETS -----
----------------------------



----------------------------
----- '.\src\main.lua' -----
local lastPressed = ""
local screenInvalid = true
local lastFrameTime = 0

local screen = platform.window

--Events
function on.construction()
    on.create()
end

function on.create()
    lastFrameTime = timer.getMilliSecCounter()
    Init()
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

function on.enterKey()
    lastPressed = "enter"
    on.timer()
end

function on.escapeKey()
    lastPressed = "esc"
    on.timer()
end

function on.getFocus()
    on.timer()
end
----- '.\src\main.lua' -----
----------------------------
----------------------------
----- '.\src\game.lua' -----
local pieceGridSizes = {4, 3, 3, 2, 3, 3, 3}

local pieces = {{
    {0, 0, 0, 0}, {0, 0, 0 ,0}, {1, 1, 1, 1}, {0, 0, 0, 0}},
    {{0, 0, 0}, {2, 2, 2}, {2, 0, 0}},
    {{0, 0, 0}, {3, 3, 3}, {0, 0, 3}},
    {{4, 4}, {4, 4}},
    {{0, 0, 0}, {5, 5, 0}, {0, 5, 5}},
    {{0, 0, 0}, {6, 6, 6}, {0, 6, 0}},
    {{0, 0, 0}, {0, 7, 7}, {7, 7, 0}}
}

--Adapted from https://tetris.fandom.com/wiki/SRS
local normKickChecks = {
    --Anticlockwise
    {
        {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
        {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
        {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
        {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}}
    },
    --Clockwise
    {
        {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
        {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
        {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
        {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}}
    }
}
local lineKickChecks = {
    --Anticlockwise
    {
        {{0, 0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}},
        {{0, 0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -2}},
        {{0, 0}, {1, 0}, {-2, 0}, {1, -2}, {-2, 1}},
        {{0, 0}, {-2, 0}, {1, 0}, {-2, -1}, {1, 2}}
    },
    --Clockwise
    {
        {{0, 0}, {-2, 0}, {1, 0}, {-2, -1}, {1, 2}},
        {{0, 0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}},
        {{0, 0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -2}},
        {{0, 0}, {1, 0}, {-2, 0}, {1, -2}, {-2, 1}}
    }
}

local scores = {0, 100, 300, 500, 800}

local board = {
    grid = {},
    next = {},
    animation = {
        rows = {},
        frame = 10
    },
    hold = {
        holdID = 0,
        canHold = true
    },
    dropping = {
        dropTime = 0,
        rotation = 0,
        pieceID = 0,

        offsetX = 0,
        offsetY = 0,
        ghostOffsetY = 0,
        
        grid = {},
        gridSize = 0,

        goundTimer = 500
    }
}

local progress = {
    backToBack = false,
    score = 0,
    lines = 0,
    level = 0
}

local pauseState = {
    pauseActive = false,
    unpausing = false,
    unpauseDelay = 1800
}

local FPS = {
    frames = 0,
    totalTime = 0,
    FPS = 30
}

function dropTime(level)
    return math.pow(0.8 - level*0.007, level) * 1000
end

function pieceOffsetLegal(piece, gridSize, offsetX, offsetY)
    for y = 1, gridSize do
        local yPos = y + offsetY
        for x = 1, gridSize do
            local xPos = x + offsetX
            if(piece[y][x] ~= 0) then --continue
                if(xPos <= 0 or xPos > 10 or yPos <= 0) then
                    return false
                end
                if(board.grid[yPos][xPos] ~= 0) then
                    return false
                end
            end
        end
    end
    return true
end

function setNextPiece(pieceID)
    local offsetY = 21 - pieceGridSizes[pieceID]
    local offsetX = 5 - math.ceil(pieceGridSizes[pieceID]/2)

    board.dropping.grid = {}
    board.dropping.gridSize = pieceGridSizes[pieceID]
    board.dropping.offsetX = offsetX
    board.dropping.offsetY = offsetY
    board.dropping.rotation = 0
    board.dropping.dropTime = 0
    board.dropping.goundTimer = 500
    board.dropping.onGround = false
    board.dropping.pieceID = pieceID

    for y = 1, board.dropping.gridSize do
        table.insert(board.dropping.grid, {})
        for x = 1, board.dropping.gridSize do
            table.insert(board.dropping.grid[y], pieces[pieceID][y][x])
        end
    end
    screenInvalid = true
    pieceRandomizer()
    return pieceOffsetLegal(board.dropping.grid, pieceGridSizes[pieceID], offsetX, offsetY)
end

function attemptRotate(drop, direction)
    if(drop.gridSize == 2) then return end
    local newRotation = {}
    local center = (drop.gridSize+1)/2
    for y = 1, drop.gridSize do
        table.insert(newRotation, {})
        local offsetY = y - center
        for x = 1, drop.gridSize do
            local offsetX = x - center

            local otherX = center - offsetY * direction
            local otherY = center + offsetX * direction
            table.insert(newRotation[y], drop.grid[otherY][otherX])
        end
    end
    local kickChecks = normKickChecks
    if(drop.gridSize == 4) then kickChecks = lineKickChecks end

    local kicks = kickChecks[(direction+3)/2][drop.rotation + 1]
    for i = 1, 5 do
        local newOffsetX = drop.offsetX + kicks[i][1]
        local newOffsetY = drop.offsetY + kicks[i][2]
        if(pieceOffsetLegal(newRotation, drop.gridSize, newOffsetX, newOffsetY)) then
            drop.grid = newRotation
            drop.offsetX = newOffsetX
            drop.offsetY = newOffsetY
            drop.rotation = (drop.rotation + direction) % 4
            drop.goundTimer = 500
            screenInvalid = true
            return
        end
    end
end

function attemptMove(drop, directionX, directionY)
    if(pieceOffsetLegal(drop.grid, drop.gridSize, drop.offsetX+directionX, drop.offsetY+directionY)) then
        drop.offsetX = drop.offsetX + directionX
        drop.offsetY = drop.offsetY + directionY
        drop.goundTimer = 500
        screenInvalid = true
    end
end

function updateBoardRows()
    local rowsCleared = 0
    local multiplier = progress.level + 1
    for y = 1, 28 do
        local shouldClear = true
        for x = 1, 10 do
            if(board.grid[y][x] == 0) then
                shouldClear = false
                break
            end
        end
        if(shouldClear) then
            rowsCleared = rowsCleared + 1
            table.insert(board.animation.rows, y)
            board.animation.frame = 10
        end
    end
    if(rowsCleared == 4) then
        if(progress.backToBack) then
            multiplier = multiplier*1.5
        end
        progress.backToBack = true
    elseif(rowsCleared ~= 0) then
        progress.backToBack = false
    end
    progress.score = progress.score + scores[rowsCleared + 1] * multiplier
    progress.lines = progress.lines + rowsCleared
    progress.level = math.floor(progress.lines/10)
    screenInvalid = true
end

function deleteClearedRows(rows)
    for i = #rows, 1, -1 do
        table.remove(board.grid, rows[i])
        table.insert(board.grid, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    end
end

function attemptHold(drop, hold)
    if(hold.canHold) then
        if(hold.holdID == 0) then
            hold.holdID = drop.pieceID
            setNextPiece(table.remove(board.next, 1))
        else
            local fallingPieceID = drop.pieceID
            setNextPiece(hold.holdID)
            hold.holdID = fallingPieceID
        end
        hold.canHold = false
    end
end

function lockDropping(drop)
    for y = 1, drop.gridSize do
        for x = 1, drop.gridSize do
            if(drop.grid[y][x] ~= 0) then
                board.grid[y + drop.offsetY][x + drop.offsetX] = drop.grid[y][x]
            end
        end
    end
    board.hold.canHold = true
    updateBoardRows()
    setNextPiece(table.remove(board.next, 1))
end

function hardDrop(drop)
    setGhostOffset(drop)
    drop.offsetY = drop.ghostOffsetY
    lockDropping(drop)
end

function pieceRandomizer()
    if(#board.next<7) then
        local allPieces = {1, 2, 3, 4, 5, 6, 7}
        for i = 1, 7 do
            table.insert(board.next, table.remove(allPieces, math.random(#allPieces)))
        end
    end
end

function setGhostOffset(drop)
    for offsetY = drop.offsetY, -4, -1 do
        if(not pieceOffsetLegal(drop.grid, drop.gridSize, drop.offsetX, offsetY)) then
            drop.ghostOffsetY = offsetY+1
            return
        end
    end
end

function pauseGame()
    pauseState.pauseActive = true
    pauseState.unpausing = false
    pauseState.unpauseDelay = 1800
end

function updateFPS(deltaTime)
    FPS.frames = FPS.frames + 1
    FPS.totalTime = FPS.totalTime + deltaTime
    if FPS.frames % 10 == 0 then
        FPS.FPS = FPS.frames/FPS.totalTime * 1000
        FPS.frames = 0
        FPS.totalTime = 0
    end
end

function pauseUpdate(deltaTime, key)
    screenInvalid = true
    if(key=="enter") then
        pauseState.unpausing = true
    end
    if(pauseState.unpausing) then
        pauseState.unpauseDelay = pauseState.unpauseDelay - deltaTime
        if(pauseState.unpauseDelay<0) then
            pauseState.pauseActive = false
        end
    end
end

function animationUpdate(drop)
    screenInvalid = true
    board.animation.frame = board.animation.frame-1
    if(board.animation.frame == 0) then
        deleteClearedRows(board.animation.rows)
        setGhostOffset(drop)
        board.animation.rows = {}
    end
end

function gameUpdate(deltaTime, key, drop)
    --Movement speed unavoidably changes based on framerate/ autorepeat frequency
    if(key=="right")    then attemptMove(drop, 1, 0)
    elseif(key=="left") then attemptMove(drop, -1, 0)
    elseif(key=="down") then attemptMove(drop, 0, -1)
    elseif(key=="up")   then hardDrop(drop)
    elseif(key=="1")    then attemptRotate(drop, -1)
    elseif(key=="2")    then attemptRotate(drop, 1)
    elseif(key=="c")    then attemptHold(drop, board.hold)
    elseif(key=="esc")  then
        pauseGame()
        return --When automatically paused deltaTime can be too large, need to avoid
    end

    local onGround = not pieceOffsetLegal(drop.grid, drop.gridSize, drop.offsetX, drop.offsetY - 1)

    drop.dropTime = drop.dropTime - deltaTime
    if(drop.dropTime < 0) then
        --Drop piece
        drop.dropTime = dropTime(progress.level)
        if(not onGround) then
            drop.offsetY = drop.offsetY - 1
            screenInvalid = true
        end
    end

    if(onGround) then
        drop.goundTimer = drop.goundTimer - deltaTime
        if(drop.goundTimer < 0) then
            lockDropping(drop)
        end
    end

    setGhostOffset(drop)
end

function Init()
    for y = 1, 28 do
        table.insert(board.grid, {})
        for x = 1, 10 do
            table.insert(board.grid[y], 0)
        end
    end
    pieceRandomizer()
    setNextPiece(table.remove(board.next, 1))
end

function Update(deltaTime, key)
    updateFPS(deltaTime)
    if(pauseState.pauseActive) then
        pauseUpdate(deltaTime, key)
        return
    end

    --Dont update while animating
    if(board.animation.frame ~= 0) then
        animationUpdate(board.dropping)
        return
    end

    gameUpdate(deltaTime, key, board.dropping)
end
----- '.\src\game.lua' -----
----------------------------
----------------------------
----- '.\src\draw.lua' -----
local pieceColors = {{9, 253, 248}, {0, 0, 253}, {255, 169, 0}, {255, 255, 92}, {0, 255, 0}, {151, 2, 255}, {253, 0, 0}}

function arrayContains(array, thing)
    for i = 1, #array do
        if(array[i] == thing) then
            return true
        end
    end
    return false
end

function drawFPS(gc)
    gc:setFont("sansserif", "b", 7)
    gc:setColorRGB(255, 0, 0)
    gc:drawString(math.floor(FPS.FPS*10)/10, 10, 5) --1 dp
end

function drawPieceBox(gc, index, pieceID, blockWidth, offsetX, top)
    local offsetY = top + index * (blockWidth * 4 + 10)
    local width = blockWidth * 4
    gc:setColorRGB(50, 50, 50)
    gc:fillRect(offsetX, offsetY, width, width)

    gc:setColorRGB(90, 90, 90)
    for x = 0, 4 do
        gc:fillRect(offsetX+x*blockWidth, offsetY, 1, width)
    end
    for y = 0, 4 do
        gc:fillRect(offsetX, y*blockWidth + offsetY, width, 1)
    end

    if(pieceID==0) then return end
    if(pauseState.pauseActive) then return end

    local color = pieceColors[pieceID]
    gc:setColorRGB(color[1], color[2], color[3])

    local gridSize = pieceGridSizes[pieceID]
    local sizeOffset = 1
    if(gridSize == 4) then sizeOffset = 0 end

    for x = 0, gridSize-1 do
        for y = 1, gridSize do
            if(pieces[pieceID][y][x+1] ~= 0) then
                gc:fillRect(offsetX + (x+sizeOffset)*blockWidth + 1, ((gridSize-y)+sizeOffset)*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
            end
        end
    end
end

function drawBlock(gc, x, y, offsetX, offsetY, blockWidth, id, fill)
    if(id == 0) then return end
    local color = pieceColors[id]
    gc:setColorRGB(color[1], color[2], color[3])
    if(fill) then
        gc:fillRect(offsetX + x*blockWidth + 1, (20-y)*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
        return
    end
    gc:drawRect(offsetX + x*blockWidth + 1, (20-y)*blockWidth + offsetY + 1, blockWidth-2, blockWidth-2)
end

function drawStringCentered(gc, string, x, y)
    local stringWidth = gc:getStringWidth(string)
    gc:drawString(string, x-stringWidth/2, y)
end

function drawPauseUI(gc, centerX, centerY)
    local width = 80
    local height = 40
    gc:setColorRGB(150, 150, 150)
    gc:fillRect(centerX-width/2, centerY-height/2, width, height)

    gc:setColorRGB(0, 0, 0)
    if(pauseState.unpausing) then
        local time = math.ceil(pauseState.unpauseDelay/600)
        gc:setFont("sansserif", "b", 12)
        drawStringCentered(gc, time, centerX, centerY-height/2 + 8)
        return
    end
    gc:setFont("sansserif", "b", 11)
    drawStringCentered(gc, "PAUSED", centerX, centerY-height/2)
    gc:setFont("sansserif", "b", 7)
    drawStringCentered(gc, "Press ENTER", centerX, centerY-height/2 + 20)
end

function drawBoard(gc, screenWidth, screenHeight)
    local blockWidth = math.floor(screenHeight/20)
    local width = blockWidth * 10
    local offsetX = (screenWidth-width)/2
    local offsetY = (screenHeight - width*2)/2
    local height = width*2

    --Grid
    gc:setColorRGB(50, 50, 50)
    gc:fillRect(offsetX, offsetY, width, height)

    gc:setColorRGB(90, 90, 90)
    for x = 0, 10 do
        gc:fillRect(offsetX+x*blockWidth, offsetY, 1, height)
    end
    for y = 0, 20 do
        gc:fillRect(offsetX, y*blockWidth + offsetY, width, 1)
    end
    --Next pieces
    drawPieceBox(gc, 0, board.next[1], blockWidth, offsetX + width + 10, offsetY)
    drawPieceBox(gc, 1, board.next[2], blockWidth, offsetX + width + 10, offsetY)
    drawPieceBox(gc, 2, board.next[3], blockWidth, offsetX + width + 10, offsetY)
    drawPieceBox(gc, 3, board.next[4], blockWidth, offsetX + width + 10, offsetY)

    --Hold
    local UIOffset = offsetX - blockWidth * 4 - 10
    drawPieceBox(gc, 0.35, board.hold.holdID, blockWidth, UIOffset,  offsetY)

    --Text UI
    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", "b", 9)
    gc:drawString("HOLD", UIOffset+4, offsetY)
    gc:drawString("SCORE", UIOffset, offsetY + blockWidth*8)
    gc:drawString("LEVEL", UIOffset, offsetY + blockWidth*12)
    gc:drawString("LINES", UIOffset, offsetY + blockWidth*16)

    gc:setFont("sansserif", "b", 7)
    gc:drawString(progress.score, UIOffset, offsetY + blockWidth*9.7)
    gc:drawString(progress.level + 1, UIOffset, offsetY + blockWidth*13.7)
    gc:drawString(progress.lines, UIOffset, offsetY + blockWidth*17.7)

    --If paused dont show pieces
    if(pauseState.pauseActive) then
        drawPauseUI(gc, offsetX + width/2, offsetY+height/2)
        return
    end
    --Board
    for y = 1, 20 do
        local continue = board.animation.frame%2==0 and arrayContains(board.animation.rows, y)
        for x = 0, 9 do
            if(continue) then break end -- budget continue statement

            local drop = board.dropping
            local dropX = x-drop.offsetX + 1
            local dropY = y-drop.offsetY
            local ghostY = y-drop.ghostOffsetY

            if(dropX > 0 and dropX <= drop.gridSize) then
                if(ghostY > 0 and ghostY <= drop.gridSize) then
                    drawBlock(gc, x, y, offsetX, offsetY, blockWidth, drop.grid[ghostY][dropX], false)
                end
                if(dropY > 0 and dropY <= drop.gridSize) then
                    drawBlock(gc, x, y, offsetX, offsetY, blockWidth, drop.grid[dropY][dropX], true)
                end
            end
            drawBlock(gc, x, y, offsetX, offsetY, blockWidth, board.grid[y][x+1], true)
        end
    end
end

function Draw(gc, width, height)
    gc:setColorRGB(255, 255, 255)
    gc:fillRect(0, 0, width, height)
    drawBoard(gc, width, height)
    drawFPS(gc)
end
----- '.\src\draw.lua' -----
----------------------------
