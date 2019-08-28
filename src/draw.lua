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

function drawPieceBox(gc, index, pieceID, blockWidth, offsetX, top, enabled)
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

    if(not enabled) then
        gc:setColorRGB(100, 100, 100)
        gc:fillRect(offsetX+width*0.2, offsetY + 1.5*blockWidth, blockWidth*2.5, blockWidth)
        return
    end
    if(pieceID==0 or pauseState.pauseActive) then return end

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
    drawPieceBox(gc, 0, board.next[1], blockWidth, offsetX + width + 10, offsetY, options.enableNext)
    drawPieceBox(gc, 1, board.next[2], blockWidth, offsetX + width + 10, offsetY, options.enableNext)
    drawPieceBox(gc, 2, board.next[3], blockWidth, offsetX + width + 10, offsetY, options.enableNext)
    drawPieceBox(gc, 3, board.next[4], blockWidth, offsetX + width + 10, offsetY, options.enableNext)

    --Hold
    local UIOffset = offsetX - blockWidth * 4 - 10
    drawPieceBox(gc, 0.35, board.hold.holdID, blockWidth, UIOffset,  offsetY, options.enableHold)

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
                if(ghostY > 0 and ghostY <= drop.gridSize and options.enableGhost) then
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