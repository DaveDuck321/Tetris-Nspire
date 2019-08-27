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
        for y = 1, gridSize do
            if(pieces[pieceID][y][x+1] ~= 0) then
                gc:fillRect(offsetX + (x+sizeOffset)*blockWidth + 1, ((gridSize-y)+sizeOffset)*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
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
        for y = 1, 20 do
            local drop = board.dropping
            local dropX = x-drop.offsetX + 1
            local dropY = y-drop.offsetY
            if(dropX > 0 and dropX <= drop.gridSize and dropY > 0 and dropY <= drop.gridSize) then
                if(drop.grid[dropY][dropX] ~= 0) then
                    local color = pieceColors[drop.grid[dropY][dropX]]
                    gc:setColorRGB(color[1], color[2], color[3])
                    gc:fillRect(offsetX + x*blockWidth + 1, (20-y)*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
                end
            end
            if(board.grid[y][x+1] ~= 0) then
                local color = pieceColors[board.grid[y][x+1]]
                gc:setColorRGB(color[1], color[2], color[3])
                gc:fillRect(offsetX + x*blockWidth + 1, (20-y)*blockWidth + offsetY + 1, blockWidth-1, blockWidth-1)
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