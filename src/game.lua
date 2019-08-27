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
    local offsetY = 21 - pieceGridSizes[pieceID]
    local offsetX = 5 - math.ceil(pieceGridSizes[pieceID]/2)
    local canDrop = true

    board.dropping.grid = {}
    board.dropping.gridSize = pieceGridSizes[pieceID]
    board.dropping.offsetX = offsetX

    for y = 1, board.dropping.gridSize do
        table.insert(board.dropping.grid, {})
        for x = 1, board.dropping.gridSize do
            table.insert(board.dropping.grid[y], pieces[pieceID][y][x])
            if(pieces[pieceID][y][x] ~= 0) then
                if(board.grid[y+offsetY][x+offsetX] ~= 0) then
                    return false
                end
                if(board.grid[y+offsetY-1][x+offsetX] ~= 0) then
                    canDrop = false
                end
            end
        end
    end

    if(canDrop) then
        board.dropping.offsetY = offsetY-1
    else
        board.dropping.offsetY = offsetY
    end
    pieceRandomizer()
    return true
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
    for y = 1, 28 do
        table.insert(board.grid, {})
        for x = 1, 10 do
            table.insert(board.grid[y], 0)
        end
    end
    board.grid[1][4] = 1
    board.grid[19][6] = 1
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