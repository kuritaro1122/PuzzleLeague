pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

vec2d = {
    __add=function(a,b)
        return {x=a.x+b.x, y=a.y+b.y}
    end
}

--
block = { 1, 2, 3, 4, 5, 6, 7 }
airblock = 16
blockSize = 8
beginPos = { x=127 / 2 - blockSize * (6 / 2 + 1), y=127 } setmetatable(beginPos, vec2d)
boardxsize = 6
boardysize = 13
board = {}
--
elapsedflame = 0
breaking = false
breakingtime = 0.5
last = 0
span = 4
--
blockkinds = 3
select = { x=0, y=0 } setmetatable(select, vec2d)
select2offset = { x=1, y=0 } setmetatable(select2offset, vec2d)
selectblock = 16
--
score = 0
play = true
--

function _init()
    for i = 1, boardxsize do
	    board[i] = {}
	    for k = 1, boardysize do
            board[i][k] = { color=0,remaintime=0.5,chain=false }
	    end
    end
    score = 0
    play = true
    last = time()
    updatelevel()
    for i = 1, 1 do
        generateblock()
    end
end

function _update()
    updatelevel()
    elapsedflame += 1
    if play then
        controller()
        if breaking == false then
            fallblock()
            removechainblock()
            if time() - last > span then
                generateblock()
                select.y = min(select.y + 1, boardysize - 1)
                last = time()
            end
        end
        updatebreakblock()
    else
        if btnp(5) then
            _init()
        end
    end
end

function updatelevel()
    span = 4 - 0.1 * flr(score / 100)
    span = max(span, 2)
    blockkinds = 3 + flr(score / 200)
    blockkinds = min(blockkinds, #block)
end

function _draw()
    cls()
    print("Score:"..score, 10)
    print("blockKinds:"..blockkinds, 7)
    print("span:"..span, 7)
    --print(span - (time() - last), 7)
    for i = 1, #board do
        for k = 1, boardysize - 1 do
            local _pos = getpos({x=i, y=k})
            local color = board[i][k].color
            if board[i][k].chain then
                if elapsedflame % 2 == 0 then
                    color += 16
                else
                    color += 32
                end
            end
            spr(color, _pos.x, _pos.y)
            --print(board[i][k].color, _pos.x, _pos.y, 1)
        end
    end
    local _pos = getpos(select)
    spr(selectblock, _pos.x, _pos.y)
    local _pos2 = getpos(select + select2offset)
    spr(selectblock, _pos2.x, _pos.y)
    if play == false then
        print("GameOver", 127 / 2 - 16, 16)
    end
end

function controller()
    if btnp(0) then
        select.x -= 1
    end
    if btnp(1) then
        select.x += 1
    end
    if btnp(2) then
        select.y += 1
    end
    if btnp(3) then
        select.y -= 1
    end
    select.x = clamp(select.x, 1, boardxsize - 1)
    select.y = clamp(select.y, 1, boardysize)
    if btnp(4) then
        switchblock()
    end
end

function clamp(value, _min, _max)
    value = min(value, _max)
    value = max(value, _min)
    return value
end

function switchblock()
    local pos1 = {x=select.x,y=select.y} setmetatable(pos1, vec2d)
    local pos2 = {x=0,y=0} setmetatable(pos2, vec2d)
    pos2 = pos1 + select2offset
    local board1 = board[pos1.x][pos1.y]
    local board2 = board[pos2.x][pos2.y]
    if board1.chain or board2.chain then
        return
    end
    sfx(1)
    local temp = { color=board1.color,remaintime=board1.remaintime,chain=board1.chain }
    board[pos1.x][pos1.y] = { color=board2.color,remaintime=board2.remaintime,chain=board2.chain }
    board[pos2.x][pos2.y] = { color=temp.color,remaintime=temp.remaintime,chain=temp.chain }
end

function removechainblock()
    removechainblockx()
    removechainblocky()
end
function removechainblocky()
    for i = 1, boardxsize do
        local color = 0
        local beginindex = 1
        local endindex = 1
        for k = 1, boardysize do
            if board[i][k].color ~= 0 then
                if board[i][k].color ~= color then
                    beginindex = k
                    endindex = k
                    color = board[i][k].color
                else
                    endindex = k
                end
            else
                color = 0
            end
            if endindex - beginindex + 1 >= 3 and (k == boardysize or board[i][k + 1].color ~= color) then
                for m = beginindex, endindex do
                    if board[i][m].color ~= 0 and board[i][m].chain == false then
                        board[i][m].chain = true
                        sfx(0)
                    end
                end
            end
        end
    end
end
function removechainblockx()
    for i = 1, boardysize do
        local color = 0
        local beginindex = 1
        local endindex = 1
        for k = 1, boardxsize do
            if board[k][i].color ~= 0 then
                if board[k][i].color ~= color then
                    beginindex = k
                    endindex = k
                    color = board[k][i].color
                else
                    endindex = k
                end
            else
                color = 0
            end
            if endindex - beginindex + 1 >= 3 and (k == boardxsize or board[k + 1][i].color ~= color) then
                for m = beginindex, endindex do
                    if board[m][i].color ~= 0 and board[m][i].chain == false then
                        board[m][i].chain = true
                        sfx(0)
                    end
                end
            end
        end
    end
end

beginbreaktime = 0

function updatebreakblock()
    if breaking then
        breaking = false
    end
    for i = 1, #board do
        for k = 1, #board[i] do
            element = board[i][k]
            if element.chain then
                if element.remaintime > 0 then
                    breaking = true
                    beginbreaktime = time()
                    element.remaintime -= breakingtime * 1 / 30
                else
                    board[i][k] = { color=0,remaintime=0.5,chain=false }
                    score += 1
                end
            end
        end
    end
end

function fallblock()
    for i = 1, #board do
        local beginindex = 1
        local count = 0
        for k = 1, #board[i] do
            local air = board[i][k].color == 0
            if count < 1 then
                if air then
                    beginindex = k
                    count = 1
                end
            else
                if air then
                    count += 1
                else
                    break
                end
            end
        end
        for m = beginindex, #board[i] do
            if m + count > #board[i] then
                board[i][m] = { color=0,remaintime=0.5,chain=false }
            else
                board[i][m] = { color=board[i][m + count].color,remaintime=0.5,chain=false }
            end
        end
    end
end

function generateblock()
    for i = 1, #board do
        for k = 1, #board[i] do
            local index = #board[i] - k + 1
            if board[i][#board[i]].color ~= 0 then
                play = false
            end
            if index > 1 then
                board[i][index] = { color=board[i][index-1].color,remaintime=0.5,chain=false }
            else
                local color = flr(rnd(min(blockkinds, #block))) + 1
                if i > 2 and board[i-1][index].color == color and board[i-2][index].color == color then
                    color = (color + 1) % min(blockkinds, #block) + 1
                end
                if board[i][index+1].color == color and board[i][index+2].color == color then
                    color = (color + 1) % min(blockkinds, #block) + 1
                end
                board[i][index] = { color=color,remaintime=0.5,chain=false }
            end
        end
    end
end

function getpos(p)
    local pos = { x=0, y=0 }
    pos.x = beginPos.x + blockSize * p.x
    pos.y = beginPos.y - blockSize * p.y
    return pos
end
