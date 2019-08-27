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

local board = {
    grid = {},
    next = {},
    hold = {
        holdID = 0,
        canHold = true
    },
    dropping = {
        dropTime = 0,
        rotation = 0,

        offsetX = 0,
        offsetY = 0,
        ghostOffsetY = 0,
        
        grid = {},
        gridSize = 0,

        goundTimer = 500
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

function setNextPiece()
    local pieceID = table.remove(board.next, 1)
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

    for y = 1, board.dropping.gridSize do
        table.insert(board.dropping.grid, {})
        for x = 1, board.dropping.gridSize do
            table.insert(board.dropping.grid[y], pieces[pieceID][y][x])
        end
    end
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
            return
        end
    end
end

function attemptMove(drop, directionX, directionY)
    if(pieceOffsetLegal(drop.grid, drop.gridSize, drop.offsetX+directionX, drop.offsetY+directionY)) then
        drop.offsetX = drop.offsetX + directionX
        drop.offsetY = drop.offsetY + directionY
        drop.goundTimer = 500
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
    setNextPiece()
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

function Init()
    for y = 1, 28 do
        table.insert(board.grid, {})
        for x = 1, 10 do
            table.insert(board.grid[y], 0)
        end
    end
    pieceRandomizer()
    setNextPiece()
end

function Update(deltaTime, key)
    local drop = board.dropping
    --Movement speed unavoidably changes based on framerate/ autorepeat frequency
    if(key=="right")    then attemptMove(drop, 1, 0)
    elseif(key=="left") then attemptMove(drop, -1, 0)
    elseif(key=="down") then attemptMove(drop, 0, -1)
    elseif(key=="up")   then hardDrop(drop)
    elseif(key=="1")    then attemptRotate(drop, -1)
    elseif(key=="2")    then attemptRotate(drop, 1)
    end

    local onGround = not pieceOffsetLegal(drop.grid, drop.gridSize, drop.offsetX, drop.offsetY - 1)

    drop.dropTime = drop.dropTime - deltaTime
    if(drop.dropTime < 0) then
        --Drop piece
        drop.dropTime = dropTime(progress.level)
        if(not onGround) then
            drop.offsetY = drop.offsetY - 1
        end
    end

    if(onGround) then
        drop.goundTimer = drop.goundTimer - deltaTime
        if(drop.goundTimer < 0) then
            lockDropping(drop)
        end
    end

    setGhostOffset(drop)

    FPS.frames = FPS.frames + 1
    FPS.totalTime = FPS.totalTime + deltaTime
    if FPS.frames % 10 == 0 then
        FPS.FPS = FPS.frames/FPS.totalTime * 1000
        FPS.frames = 0
        FPS.totalTime = 0
    end
end