local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local audio = mjrequire "mainThread/audio"
local model = mjrequire "common/model"
local steam = mjrequire "common/utility/steam"
--local material = mjrequire "common/material"
local eventManager = mjrequire "mainThread/eventManager"
local keyMapping = mjrequire "mainThread/keyMapping"

local uiTextEntry = {}

--local controller = nil

local function resize(buttonTable, size)

    buttonTable.view.size = size
    local backgroundView = buttonTable.backgroundView
    if buttonTable.hasModelBackground then
        local scaleToUseX = size.x * 0.5
        local scaleToUseY = size.y * 0.5 / buttonTable.backgroundHeightMultiplier
        backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    end
    backgroundView.size = size
end

local function updateVisuals(buttonTable)
    if buttonTable.textView then
        if buttonTable.text then
            buttonTable.textView.text = buttonTable.text
        else
            buttonTable.textView.text = ""
        end

        local desiredBackgroundSize = buttonTable.textView.size.x + 12
        if buttonTable.promptTextView then
            desiredBackgroundSize = desiredBackgroundSize + buttonTable.promptTextView.size.x
        end

        if desiredBackgroundSize > buttonTable.backgroundView.size.x then
            local newSize = vec2(desiredBackgroundSize, buttonTable.backgroundView.size.y)
            resize(buttonTable, newSize)
        elseif desiredBackgroundSize < buttonTable.backgroundView.size.x then
            local newWidth = math.max(desiredBackgroundSize, buttonTable.minWidth)
            local newSize = vec2(newWidth, buttonTable.backgroundView.size.y)
            resize(buttonTable, newSize)
        end

        if buttonTable.disabled then
            buttonTable.textView.color = mj.textColor
            --buttonTable.textView:setText(buttonTable.text, material.types.disabledText.index)
        else
            if buttonTable.selected or buttonTable.editing then
                buttonTable.textView.color = mj.highlightColor
                --buttonTable.textView:setText(buttonTable.text, material.types.selectedText.index)

                --[[
                    nil, nil, function(materialIndexToRemap)
                                if materialIndexToRemap == material.types.warning.index then
                                    return materialToUse
                                end
                                return materialIndexToRemap
                            end
                    ]]
            else
                buttonTable.textView.color = mj.textColor
                --buttonTable.textView:setText(buttonTable.text, material.types.standardText.index)
            end
        end
    end
end

uiTextEntry.types = mj:enum {
    "standard_10x3",
    "wide",
    "multiLine",
    "chatInput",
}

local function updateCursorPosition(buttonTable)
    local rect = buttonTable.textView:getRectForCharAtIndex(-1 + (buttonTable.cursorOffset or 0))
    --mj:log("index:", -1 + (buttonTable.cursorOffset or 0), " rect:", rect)
    buttonTable.cursorView.baseOffset = vec3(rect.x + rect.z + 1,rect.y + 1,0)
end

local function updateText(buttonTable, newText)
    uiTextEntry:setText(buttonTable.view, newText)

    if buttonTable.editing then
        buttonTable.cursorView.hidden = false
        buttonTable.cursorTimer = 0.0

        updateCursorPosition(buttonTable)
    end
    
    if buttonTable.textEntryChangedContinuousFunction then
        buttonTable.textEntryChangedContinuousFunction(buttonTable.text)
    end
end

local function finishEditing(buttonTable, confirmChanges)
    if buttonTable.editing then
        buttonTable.view.keyChanged = nil
        buttonTable.editing = false
        buttonTable.backgroundView.update = nil
        buttonTable.cursorView.hidden = true
        updateVisuals(buttonTable)
        eventManager:removeTextEntryListener(buttonTable.textEntryListenerID)
        buttonTable.textEntryListenerID = nil

        if (not buttonTable.text) or string.len(buttonTable.text) == 0 then
            if buttonTable.allowsEmpty then
                buttonTable.textEntryFinishedFunction("")
            else
                updateText(buttonTable, buttonTable.editStartTextValue)
            end
        else
            if buttonTable.textEntryFinishedFunction then
                buttonTable.textEntryFinishedFunction(buttonTable.text, confirmChanges)
            end
        end
    end
end

local function showCursorAndResetTimerIfEditingForCursorChanged(buttonTable)
    if buttonTable.editing then
        buttonTable.cursorView.hidden = false
        buttonTable.cursorTimer = 0.0
        updateCursorPosition(buttonTable)
    end
end

local function cursorChanged(buttonTable, horizontalOffset, verticalOffset)
    if buttonTable.text then
        local textLength = string.len(buttonTable.text)
        if textLength > 0 then
            if horizontalOffset then
                buttonTable.cursorOffset = (buttonTable.cursorOffset or 0) + horizontalOffset
                buttonTable.textView:resetVerticalCursorMovementAnchors()
            elseif verticalOffset then
                buttonTable.cursorOffset = buttonTable.textView:getCursorOffsetForVerticalCursorMovement(buttonTable.cursorOffset or 0, verticalOffset)
            end
            buttonTable.cursorOffset = mjm.clamp(buttonTable.cursorOffset, -textLength, 0)
            showCursorAndResetTimerIfEditingForCursorChanged(buttonTable)
        end
    end
end

function uiTextEntry:create(parentView, size, typeOrNilFor10x3, horizontalAlignmentOrNilForCentered, descriptionTextOrNil) --descriptionTextOrNil is displayed when editing text in the Steam overlay keyboard
    
    local horizontalAlignment = horizontalAlignmentOrNilForCentered or MJPositionCenter
    
    local buttonTable = {
        horizontalAlignment = horizontalAlignment,
        isUiTextEntry = true,
        selected = false,
        mouseDown = false,
        editing = false,
        text = nil,
        fontSize = 16,
        fontName = uiCommon.fontName,
        textOffset = nil,
        cursorView = nil,
        editStartTextValue = nil,
        cursorTimer = 0.0,
        minWidth = size.x,
        descriptionText = descriptionTextOrNil,
    }

    local buttonView = View.new(parentView)
    buttonTable.view = buttonView
    buttonView.size = size

    local backgroundHeightMultiplier = 0.3
    local modelName = "ui_inset_10x3"
    local backgroundColor = nil
    local verticalAlignment = MJPositionCenter
    local allowWrapping = false


    local yOffset = -1
    local xOffset = 0
    
    if verticalAlignment == MJPositionTop then
        yOffset = -7
    end
    if buttonTable.textOffset then
        yOffset = yOffset + buttonTable.textOffset
    end
    if horizontalAlignment == MJPositionInnerLeft then
        xOffset = 4
    end

    if typeOrNilFor10x3 == uiTextEntry.types.multiLine then
        modelName = "ui_inset_lg_4x3"
        backgroundHeightMultiplier = 0.75
        verticalAlignment = MJPositionTop
        allowWrapping = true
        buttonTable.mutliLine = true
    elseif typeOrNilFor10x3 == uiTextEntry.types.wide then
        modelName = "ui_inset_20x1"
        backgroundHeightMultiplier = 0.05
    elseif typeOrNilFor10x3 == uiTextEntry.types.chatInput then
        buttonTable.fontSize = 13
        buttonTable.fontName = uiCommon.consoleFontName
        modelName = nil
        backgroundColor = vec4(0.0,0.0,0.0,0.8)
        --xOffset = xOffset - 4
    end

    buttonTable.verticalAlignment = verticalAlignment
    buttonTable.backgroundHeightMultiplier = backgroundHeightMultiplier
    
    local backgroundView = nil
    if modelName then
        backgroundView = ModelView.new(buttonView)
        backgroundView:setModel(model:modelIndexForName(modelName))
        local scaleToUseX = size.x * 0.5
        local scaleToUseY = size.y * 0.5 / backgroundHeightMultiplier
        backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
        buttonTable.hasModelBackground = true
    elseif backgroundColor then
        backgroundView = ColorView.new(buttonView)
        backgroundView.color = backgroundColor
    else
        backgroundView = View.new(buttonView)
    end

    backgroundView.size = size
    buttonTable.backgroundView = backgroundView

    local cursorView = ImageView.new(buttonView)
    cursorView.imageTexture = MJCache:getTexture("img/white8.png")
    cursorView.color = vec4(1.0,1.0,1.0,1.0)
    cursorView.hidden = true
    cursorView.size = vec2(1,18)
    cursorView.relativePosition = ViewPosition(MJPositionInnerLeft, verticalAlignment)
    cursorView.baseOffset = vec3(2,1,0)
    buttonTable.cursorView = cursorView

    
    local textView = TextView.new(buttonView)
    textView.size = vec2(1, buttonView.size.y) --hack to set a default for cursor to be offset from, otherwise undefined position.
    textView.font = Font(buttonTable.fontName, buttonTable.fontSize)
    textView.relativePosition = ViewPosition(horizontalAlignment, verticalAlignment)
    if allowWrapping then
        textView.wrapWidth = buttonView.size.x - 20
    end


    textView.baseOffset = vec3(xOffset,yOffset,0)
    buttonTable.initialOffset = textView.baseOffset

    buttonTable.textView = textView
    buttonTable.cursorView.relativeView = textView

    local function updateCursorFunction(dt)
        buttonTable.cursorTimer = buttonTable.cursorTimer + dt
        if buttonTable.cursorTimer > 0.5 then
            buttonTable.cursorTimer = buttonTable.cursorTimer - 0.5
            if buttonTable.cursorTimer > 0.5 then
                buttonTable.cursorTimer = 0.0
            end
            cursorView.hidden = (not cursorView.hidden)
        end
    end

    buttonView.hoverStart = function ()
        if not buttonTable.selected then
            if not buttonTable.disabled then
                buttonTable.selected = true
                audio:playUISound(uiCommon.hoverSoundFile)
                updateVisuals(buttonTable)
            end
        end
    end

    buttonView.hoverEnd = function ()
        if buttonTable.selected then
            buttonTable.selected = false
            buttonTable.mouseDown = false
            updateVisuals(buttonTable)
        end
    end

    buttonView.mouseDown = function (buttonIndex)
        if buttonIndex == 0 then
            if not buttonTable.mouseDown then
                if not buttonTable.disabled then
                    buttonTable.mouseDown = true
                    updateVisuals(buttonTable)
                    audio:playUISound(uiCommon.clickDownSoundFile)
                end
            end
        end
    end

    buttonView.mouseUp = function (buttonIndex)
        if buttonIndex == 0 then
            if buttonTable.mouseDown then
                buttonTable.mouseDown = false
                updateVisuals(buttonTable)
                audio:playUISound(uiCommon.clickReleaseSoundFile)
            end
        end
    end

    local textViewClickFunction = function(mouseLoc)
        if not buttonTable.disabled then
            if buttonTable.clickFunction then
                buttonTable.clickFunction()
            end
            if buttonTable.editing then
                if buttonTable.text then
                    local textViewLoc = buttonView:locationRelativeToView(mouseLoc, buttonTable.textView)

                    local charIndex = buttonTable.textView:getCharIndexForPos(textViewLoc)
                    local textLength = string.len(buttonTable.text)
                    if textLength > 0 then
                        charIndex = mjm.clamp(charIndex, 0, textLength)
                        buttonTable.cursorOffset = charIndex - textLength
                        buttonTable.cursorView.hidden = false
                        buttonTable.cursorTimer = 0.0
                        updateCursorPosition(buttonTable)
                        buttonView.userData.textView:resetVerticalCursorMovementAnchors()
                    end
                end
                --mj:log("mouseLoc:", mouseLoc - vec2(textView.baseOffset.x, textView.baseOffset.y), " charIndex:", charIndex)
            else
                buttonTable.editing = true
                buttonView.userData.textView:resetVerticalCursorMovementAnchors()
                buttonTable.editStartTextValue = buttonTable.text
                cursorView.hidden = false
                buttonTable.cursorTimer = 0.0
                buttonTable.cursorOffset = 0
                backgroundView.update = updateCursorFunction
                updateVisuals(buttonTable)
                updateCursorPosition(buttonTable)
                
                local keyMap = {
                    [keyMapping:getMappingIndex("textEntry", "send")] = function(isDown, isRepeat)
                        if isDown and (not isRepeat) then
                            finishEditing(buttonTable, true)
                        end
                        return true 
                    end,
                    [keyMapping:getMappingIndex("textEntry", "newline")] = function(isDown, isRepeat)
                        if isDown then
                            local newText = buttonTable.text .. "\n"
                            updateText(buttonTable, newText)
                        end
                        return true 
                    end,
                    [keyMapping:getMappingIndex("textEntry", "backspace")] = function(isDown, isRepeat)
                        if isDown then
                            if buttonTable.text and string.len(buttonTable.text) > 0 then
                                local newText = ""
                                if buttonTable.cursorOffset and buttonTable.cursorOffset ~= 0 then
                                    local textLength = string.len(buttonTable.text)
                                    if textLength > 0 then
                                        local removeBeforePos = math.max(textLength + buttonTable.cursorOffset, 0) + 1
                                        if removeBeforePos > 1 then
                                            newText = buttonTable.text:sub(1,removeBeforePos - 2) .. buttonTable.text:sub(removeBeforePos,-1)
                                        else
                                            return 
                                        end
                                    else
                                        return
                                    end
                                else
                                    newText = buttonTable.text:sub(1, -2)
                                end

                                updateText(buttonTable, newText)
                            end
                        end
                        return true
                    end,
                    [keyMapping:getMappingIndex("textEntry", "delete")] = function(isDown, isRepeat)
                        if isDown then
                            if buttonTable.text and string.len(buttonTable.text) > 0 then

                                local newText = ""
                                if buttonTable.cursorOffset and buttonTable.cursorOffset ~= 0 then
                                    local textLength = string.len(buttonTable.text)
                                    if textLength > 0 then
                                        local removeAfterPos = math.max(textLength + buttonTable.cursorOffset, 0) + 1
                                        if removeAfterPos > 0 and removeAfterPos < textLength then
                                            newText = buttonTable.text:sub(1,removeAfterPos - 1) .. buttonTable.text:sub(removeAfterPos + 1,-1)
                                            buttonTable.cursorOffset = buttonTable.cursorOffset + 1
                                        else
                                            return 
                                        end
                                    else
                                        return
                                    end
                                else
                                    newText = buttonTable.text:sub(1, -2)
                                end

                                updateText(buttonTable, newText)
                            end
                        end
                        return true
                    end,
                    [keyMapping:getMappingIndex("game", "escape")] = function(isDown, isRepeat)
                        if isDown and (not isRepeat) then
                            finishEditing(buttonTable, false)
                        end
                        return true 
                    end,
                    [keyMapping:getMappingIndex("textEntry", "cursorLeft")] = function(isDown, isRepeat) if isDown then cursorChanged(buttonTable, -1, nil) end return true end,
                    [keyMapping:getMappingIndex("textEntry", "cursorRight")] = function(isDown, isRepeat) if isDown then cursorChanged(buttonTable, 1, nil) end return true end,
                    [keyMapping:getMappingIndex("textEntry", "prevCommand")] = function(isDown, isRepeat) if isDown then cursorChanged(buttonTable, nil, 1) end return true end,
                    [keyMapping:getMappingIndex("textEntry", "nextCommand")] = function(isDown, isRepeat) if isDown then cursorChanged(buttonTable, nil, -1) end return true end,
                }

                local keyChanged = function(isDown, mapIndexes, isRepeat)
                    for i,mapIndex in ipairs(mapIndexes) do
                        if keyMap[mapIndex] then
                            return keyMap[mapIndex](isDown, isRepeat)
                        end
                    end
                    return true 
                end

                local function stringInsert(str1, str2, pos)
                    return str1:sub(1,pos)..str2..str1:sub(pos+1)
                end

                local function textEntry(text)
                    local newText = text
                    if buttonTable.text then
                        if buttonTable.cursorOffset and buttonTable.cursorOffset < 0 then
                            local textLength = string.len(buttonTable.text)
                            if textLength > 0 then
                                local insertAfterPos = math.max(textLength + buttonTable.cursorOffset, 0)
                                newText = stringInsert(buttonTable.text, text, insertAfterPos)
                            end
                        else
                            newText = buttonTable.text .. text
                        end
                    end
                    updateText(buttonTable, newText)
                end
                
                buttonTable.textEntryListenerID = eventManager:setTextEntryListener(textEntry, keyChanged)
            end
        end
    end

    buttonTable.textViewClickFunction = textViewClickFunction
    buttonView.click = textViewClickFunction
    
    buttonView.clickDownOutside = function()
        finishEditing(buttonTable, false)
    end

    --

    --buttonView.update = uiCommon:createButtonUpdateFunction(buttonTable, buttonView)

    buttonView.userData = buttonTable

    return buttonView
end

function uiTextEntry:setFunction(buttonView, func)
    buttonView.userData.textEntryFinishedFunction = func
end

function uiTextEntry:setAllowsEmpty(buttonView, allowsEmpty) --defaults to not allowing empty strings
    buttonView.userData.allowsEmpty = allowsEmpty
end

function uiTextEntry:setChangedContinuousFunction(buttonView, func)
    buttonView.userData.textEntryChangedContinuousFunction = func
end

function uiTextEntry:setSelected(buttonView, selected)
    if selected ~= buttonView.userData.selected then
        buttonView.userData.selected = selected
        updateVisuals(buttonView.userData)
    end
end

function uiTextEntry:setDisabled(buttonView, disabled)
    if disabled ~= buttonView.userData.disabled then
        buttonView.userData.disabled = disabled
        updateVisuals(buttonView.userData)
    end
end

function uiTextEntry:isEditing(buttonView)
    return buttonView.userData.editing
end

function uiTextEntry:callClickFunction(buttonView)
    buttonView.userData.textViewClickFunction()
    if eventManager.controllerIsPrimary then
        local buttonTable = buttonView.userData
        local function textEntryCallback(submitted, inputText)
            if buttonView.userData.editing then
                if submitted then
                    updateText(buttonTable, inputText)
                end
                finishEditing(buttonTable, true)
            end
        end

        steam:showGamepadTextInput(textEntryCallback, buttonView.userData.maxChars or 1000, buttonView.userData.text, buttonView.userData.descriptionText or "", buttonView.userData.mutliLine, false)
    end
end

function uiTextEntry:finishEditing(buttonView, confirmChanges)
    finishEditing(buttonView.userData, confirmChanges)
end

function uiTextEntry:setText(buttonView, text_)
    local textToUse = text_
    if not textToUse then
        textToUse = ""
    elseif type(textToUse) ~= "string" then
        textToUse = mj:tostring(textToUse)
    end

    if buttonView.userData.maxChars and textToUse and string.len(textToUse) > buttonView.userData.maxChars then
        textToUse = string.sub(textToUse, 1, buttonView.userData.maxChars)
    end
    buttonView.userData.text = textToUse
    if not buttonView.userData.editing then
        buttonView.userData.cursorOffset = 0
    else
        if textToUse then
            if buttonView.userData.cursorOffset < -string.len(textToUse) then
                buttonView.userData.cursorOffset = -string.len(textToUse)
            end
        else
            buttonView.userData.cursorOffset = 0
        end
    end
    
    updateVisuals(buttonView.userData)
    buttonView.userData.textView:resetVerticalCursorMovementAnchors()
    showCursorAndResetTimerIfEditingForCursorChanged(buttonView.userData)
end

function uiTextEntry:clearText(buttonView)
    uiTextEntry:setText(buttonView, "")
end

function uiTextEntry:setMaxChars(buttonView, maxChars)
    buttonView.userData.maxChars = maxChars
end

function uiTextEntry:getText(buttonView)
    return buttonView.userData.text
end

function uiTextEntry:setPromptText(buttonView, promptText, promptColor)
    local buttonTable = buttonView.userData
    if buttonView.userData.promptTextView then
        buttonView:removeSubview(buttonView.userData.promptTextView)
    end

    if promptText and promptText ~= "" then

        local promptTextView = TextView.new(buttonView)
        promptTextView.font = Font(buttonTable.fontName, buttonTable.fontSize)
        promptTextView.relativePosition = ViewPosition(buttonTable.horizontalAlignment, buttonTable.verticalAlignment)
        promptTextView.baseOffset = buttonTable.initialOffset

        promptTextView:addColoredText(promptText, promptColor)
    
        buttonView.userData.promptTextView = promptTextView

        buttonTable.textView.baseOffset = buttonTable.initialOffset + vec3(promptTextView.size.x,0,0) --todo this only supports left alignment
    end
end

function uiTextEntry:init(controller_)
    --controller = controller_
end

return uiTextEntry