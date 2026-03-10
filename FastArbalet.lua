script_name("{e6953e}FastArbalet {ffffff}by yargoff")
script_author('yargoff')

local font_flag = require('moonloader').font_flag
local tag = '{c99732}[FastArbalet by yargoff]{ffffff}'
local base_color = 0xFFe69f35

function json(filePath)
    local filePath = getWorkingDirectory()..'\\config\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
    local class = {}
    if not doesDirectoryExist(getWorkingDirectory()..'\\config') then
        createDirectory(getWorkingDirectory()..'\\config')
    end
    
    function class:Save(tbl)
        if tbl then
            local F = io.open(filePath, 'w')
            F:write(encodeJson(tbl) or {})
            F:close()
            return true, 'ok'
        end
        return false, 'table = nil'
    end

    function class:Load(defaultTable)
        if not doesFileExist(filePath) then
            class:Save(defaultTable or {})
        end
        local F = io.open(filePath, 'r+')
        local TABLE = decodeJson(F:read() or {})
        F:close()
        for def_k, def_v in next, defaultTable do
            if TABLE[def_k] == nil then
                TABLE[def_k] = def_v
            end
        end
        return TABLE
    end

    return class
end

local settings = json('FastArbalet.json'):Load({
    slotArbalet = '0',
    slotZamena = '0',
    typeInv = '0',
    id_bind = 0x35
})

local number = {

    ['0x04'] = 'скм',
	['0x05'] = 'км1',
	['0x06'] = 'км2',
    ['0x30'] = '0',
    ['0x31'] = '1',
    ['0x32'] = '2',
    ['0x33'] = '3',
    ['0x34'] = '4',
    ['0x35'] = '5',
    ['0x36'] = '6',
    ['0x37'] = '7',
    ['0x38'] = '8',
    ['0x39'] = '9',
    ['0x41'] = 'A',
    ['0x42'] = 'B',
    ['0x43'] = 'C',
    ['0x44'] = 'D',
    ['0x45'] = 'E',
    ['0x46'] = 'F',
    ['0x47'] = 'G',
    ['0x48'] = 'H',
    ['0x49'] = 'I',
    ['0x4A'] = 'J',
    ['0x4B'] = 'K',
    ['0x4C'] = 'L',
    ['0x4D'] = 'M',
    ['0x4E'] = 'N',
    ['0x4F'] = 'O',
    ['0x50'] = 'P',
    ['0x51'] = 'Q',
    ['0x52'] = 'R',
    ['0x53'] = 'S',
    ['0x54'] = 'T',
    ['0x55'] = 'U',
    ['0x56'] = 'V',
    ['0x57'] = 'W',
    ['0x58'] = 'X',
    ['0x59'] = 'Y',
    ['0x5A'] = 'Z',
    ['0xDB'] = '[',
    ['0xBA'] = ':',
    ['0xDD'] = ']',
    ['0xDE'] = '"',
    ['0xDC'] = '|',

}

local arb = false
local checkZamena = false

local timerActive = false
local timerStartTime = 0
local timerDuration = 120
local timerScreenX = 100
local timerScreenY = 730
local font = renderCreateFont('IMPACT', 12, font_flag.BORDER)

function main()
    while not isSampAvailable() do wait(0) end

    sampAddChatMessage(tag..' Скрипт загружен!', base_color)

    sampRegisterChatCommand('arb', iziarbaletic)
    sampRegisterChatCommand('timerarb', startTwoMinuteTimer)

    sampRegisterChatCommand('arbkey', function(arg)
        local found = false -- детект совпадения

        for i, v in pairs(number) do
            if v == arg then
                settings.id_bind = i
                json('FastArbalet.json'):Save(settings)
                sampAddChatMessage(tag..' Изменил клавишу бинда!', base_color)
                found = true
                break
            end
        end

        -- Если ничего не нашли, выводим сообщение об ошибке
        if not found then
            sampAddChatMessage(tag .. ' Этой клавиши нету в базе...', base_color)
        end
    end)
        
    while true do
        wait(0)

        if isKeyJustPressed(settings.id_bind) and not sampIsCursorActive() then
            iziarbaletic()
        end
        
        drawTimerOnScreen()
    end
end

function iziarbaletic()
    arb = true
    sampSendChat('/invent')
end

addEventHandler('onReceivePacket', function (id, bs)
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)

            local typeInv, slot = str:match('type":(%d+),"items":%[{"slot":(%d+),"available":1,"blackout":0,"item":8167')
            if typeInv then
                settings.typeInv = typeInv
                local status, code = json('FastArbalet.json'):Save(settings)
            end
            if slot then
                settings.slotArbalet = slot
                local status, code = json('FastArbalet.json'):Save(settings)
            end

            if arb then
                local isCorrectEvent = str:find('event%.inventory%.playerInventory')
                local hasDontbackPattern = str:find('"type":1,"items":%[{"slot":%d+,"available":1,"blackout":0}')


                if isCorrectEvent and hasDontbackPattern then
                    dontback = true
                    checkZamena = false
                    arb = false
                    return false
                else
                    dontback = false

                    local hasSlot5Pattern = str:find('"type":2,"items":%[{"slot":5,"available":1,"blackout":0,"item":8167')
                    local hasSlot11Pattern = str:find('"type":2,"items":%[{"slot":11,"available":1,"blackout":0,"item":8167')

                    if isCorrectEvent and (hasSlot5Pattern or hasSlot11Pattern) then
                        checkZamena = true
                    end

                    if checkZamena then
                        local zamena, id = str:match('"type":1,"items":%[{"slot":(%d+),"available":1,"blackout":0,"item":(%d+)')
                        if zamena and id then
                            checkZamena = false
                            settings.slotZamena = zamena
                            local status, code = json('FastArbalet.json'):Save(settings)
                        end
                    end
                end
            end

            if dontback then
                return false
            end

            if str:find('event.setActiveView') and str:find('Inventory') then

                if not arb then
                    return
                end

                if settings.slotArbalet == '5' and settings.typeInv == '2' then
                    sendCEF('clickOnButton|{"type": 2,"slot": 5, "action": 1}')
                    startTwoMinuteTimer()
                    arb = false
                    sendCEF('inventoryClose')
                    return false
                elseif settings.slotArbalet == '11' and settings.typeInv == '2' then
                    sendCEF('clickOnButton|{"type": 2,"slot": 11, "action": 1}')
                    startTwoMinuteTimer()
                    arb = false
                    sendCEF('inventoryClose')
                    return false
                else

                    lua_thread.create(function()
                        sendCEF('inventory.moveItemForce|{"slot": ' .. settings.slotArbalet .. ', "type": 1, "amount": 1}')
                        wait(300)
                        sendCEF('clickOnButton|{"type": 2,"slot": ' .. settings.slotArbalet .. ', "action": 1}')
                        startTwoMinuteTimer()
                        if not dontback then
                            sendCEF('inventory.moveItem|{"from":{"slot":' .. settings.slotArbalet .. ',"type":2,"amount":1},"to":{"slot":' .. settings.slotZamena .. ',"type":1}}')
                        end
                        arb = false
                        sendCEF('inventoryClose')
                    end)
                    return false
                end
            end
        end
    end
end)

sendCEF = function(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

-- Функция запуска таймера
function startTwoMinuteTimer()
    if timerActive then
        return false 
    end

    timerActive = true
    timerStartTime = os.time()
    return true
end

-- Функция отрисовки таймера
function drawTimerOnScreen()
    if not timerActive then
        return
    end

    local elapsed = os.time() - timerStartTime
    local remaining = timerDuration - elapsed

    if remaining <= 0 then
        timerActive = false
        return
    end

    local minutes = math.floor(remaining / 60)
    local seconds = remaining % 60
    local timeText = string.format("%02d:%02d", minutes, seconds)

    if font then
        renderFontDrawText(
            font,
            timeText,
            timerScreenX,
            timerScreenY,
            0xFFFFFFFF,
            true
        )
    end
end