local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local timer = mjrequire "common/timer"
--local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local eventManager = mjrequire "mainThread/eventManager"
local keyMapping = mjrequire "mainThread/keyMapping"

local uiPopUpButton = {}

local uiSelectionLayout = nil

local hoverColor = mj.highlightColor * 0.8
local mouseDownColor = mj.highlightColor * 0.6
--local selectedColor = mj.highlightColor * 0.6

local function resetForNewItemList(button)
    local buttonTable = button.userData
    local itemSizeCount = 1
    if buttonTable.itemList then
        itemSizeCount = #buttonTable.itemList
    end
    local contentHeight = mjm.min(itemSizeCount * 30, buttonTable.popUpMenuSize.y)
    local newContentSize = vec2(buttonTable.popUpMenuSize.x, contentHeight)
    local newBackgroundSize = newContentSize-- + vec2(20.0, 20.0)
    
    buttonTable.listViewBackground.size = newBackgroundSize
    local scaleToUsePaneX = newBackgroundSize.x * 0.5
    local scaleToUsePaneY = newBackgroundSize.y * 0.5 
    buttonTable.listViewBackground.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    
    if buttonTable.listView then
        uiSelectionLayout:removeActiveSelectionLayoutView(buttonTable.listView)
        buttonTable.listViewBackground:removeSubview(buttonTable.listView)
    end
    local listView = uiScrollView:create(buttonTable.listViewBackground, newContentSize, MJPositionInnerLeft)
    buttonTable.listView = listView
    uiSelectionLayout:createForView(listView)
    listView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    listView.baseOffset = vec3(0.0, 0.0, 2.0)
end

local timerID = nil
local currentSearchText = nil

local function startKeyboardCapture(button)
    local userData = button.userData

    local function selectAdjacent(increment)
        if userData.itemList then
            local newIndex = userData.selectedItemIndex + increment

            if newIndex > 0 and newIndex <= #userData.itemList then
                userData.selectedItemIndex = newIndex
                uiSelectionLayout:setSelection(userData.listView, userData.backgroundViews[userData.selectedItemIndex])
            end
        end
    end

    local keyMap = {

        [keyMapping:getMappingIndex("textEntry", "prevCommand")] = function(isDown, isRepeat)
            if isDown then
                selectAdjacent(-1)
            end
            return true 
        end,

        [keyMapping:getMappingIndex("textEntry", "nextCommand")] = function(isDown, isRepeat)
            if isDown then
                selectAdjacent(1)
            end
            return true 
        end,
        
        [keyMapping:getMappingIndex("textEntry", "send")] = function(isDown, isRepeat)
            if isDown and (not isRepeat) then
                uiSelectionLayout:clickSelectedView()
            end
            return true 
        end,

        [keyMapping:getMappingIndex("game", "escape")] = function(isDown, isRepeat)
            if isDown and (not isRepeat) then
                uiPopUpButton:hidePopupMenu(button)
            end
            return true 
        end,
    }
    
    local function keyChanged(isDown, mapIndexes, isRepeat)
        --mj:log("keyChanged keyMap:", keyMap)
        for i,mapIndex in ipairs(mapIndexes) do
            if keyMap[mapIndex] then
                return keyMap[mapIndex](isDown, isRepeat)
            end
        end
        return true 
    end

    local function textEntry(text)
        if currentSearchText then
            currentSearchText = currentSearchText .. string.lower(text)
        else
            currentSearchText = string.lower(text)
        end
        local itemList = userData.itemList
        --mj:log("currentSearchText:", currentSearchText)

        if itemList then
            local isTable = (type(itemList[1]) == "table")
            for i,itemInfo in ipairs(itemList) do
                local titleString = itemInfo
                local disabled = false
                if isTable then
                    titleString = itemInfo.name
                    disabled = itemInfo.disabled
                end

                titleString = string.lower(titleString)

                if not disabled then
                    local startIndex = string.find(titleString, currentSearchText)
                    if startIndex == 1 then
                        --mj:log("found:", titleString, " currentSearchText:", currentSearchText)
                        userData.selectedItemIndex = i
                        uiSelectionLayout:setSelection(userData.listView, userData.backgroundViews[userData.selectedItemIndex])
                        break
                    end
                end
            end
        end


        timerID = timer:addCallbackTimer(1.0, function(callbackTimerID)
            if callbackTimerID == timerID then
                currentSearchText = nil
            end
        end)
    end
    
    userData.textEntryListenerID = eventManager:setTextEntryListener(textEntry, keyChanged)
end

local function endKeyboardCapture(button)
    local buttonTable = button.userData
    eventManager:removeTextEntryListener(buttonTable.textEntryListenerID)
    buttonTable.textEntryListenerID = nil
end

function uiPopUpButton:create(parentView, popOversView, buttonSize, popUpMenuSize, onHideFunction)
    local popUpButtonTable = {
        uiPopUpButton = true,
        popUpMenuSize = popUpMenuSize,
        itemList = nil,
        selectedItemIndex = nil,
        onHideFunction = onHideFunction,
    }
    local popUpButtonView = View.new(parentView)
    popUpButtonView.userData = popUpButtonTable
    popUpButtonTable.view = popUpButtonView
    popUpButtonView.size = buttonSize
    popUpButtonTable.buttonView = uiStandardButton:create(popUpButtonView, buttonSize, uiStandardButton.types.popUpButton)


    local downArrow = ModelView.new(popUpButtonTable.buttonView)
    downArrow:setModel(model:modelIndexForName("icon_down"))
    downArrow.size = vec2(15,15)
    local downArrowscaleToUseX = downArrow.size.x * 0.5
    local downArrowscaleToUseY = downArrow.size.y * 0.5 
    downArrow.scale3D = vec3(downArrowscaleToUseX,downArrowscaleToUseY,downArrowscaleToUseX)
    downArrow.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    downArrow.baseOffset = vec3(-16.0, 0.0, 2.0)
    downArrow.masksEvents = false

    local listViewBackground = ModelView.new(popOversView)
    listViewBackground:setModel(model:modelIndexForName("ui_popup_background"))
    listViewBackground.size = vec2(popUpMenuSize.x, popUpMenuSize.y)
    local scaleToUsePaneX = listViewBackground.size.x * 0.5
    local scaleToUsePaneY = listViewBackground.size.y * 0.5 
    listViewBackground.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    listViewBackground.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    listViewBackground.relativeView = popUpButtonView
    listViewBackground.baseOffset = vec3(0.0, 0.0, 8.0)
    listViewBackground.hidden = true

    popUpButtonTable.listViewBackground = listViewBackground
    
    
    listViewBackground.clickDownOutside = function()
        uiPopUpButton:hidePopupMenu(popUpButtonView)
    end

    uiStandardButton:setClickFunction(popUpButtonTable.buttonView, function()
        listViewBackground.hidden = false
        uiSelectionLayout:setActiveSelectionLayoutView(popUpButtonTable.listView)
        if popUpButtonTable.selectedItemIndex then
            uiSelectionLayout:setSelection(popUpButtonTable.listView, popUpButtonTable.backgroundViews[popUpButtonTable.selectedItemIndex])
        end
        startKeyboardCapture(popUpButtonView)
    end)

    return popUpButtonView
end

function uiPopUpButton:setItems(button, itemList)


    button.userData.itemList = itemList
    button.userData.backgroundViews = {}

    resetForNewItemList(button)

    if itemList and itemList[1] then

        local listView = button.userData.listView

        local isTable = (type(itemList[1]) == "table")

        local counter = 1
        for i,itemInfo in pairs(itemList) do
            local backgroundView = ColorView.new(listView)
            
            local defaultColor = vec4(0.0,0.0,0.0,0.5)
            if counter % 2 == 1 then
                defaultColor = vec4(0.03,0.03,0.03,0.5)
            end

            backgroundView.color = defaultColor

            backgroundView.size = vec2(listView.size.x - 22, 30)
            backgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)

            uiScrollView:insertRow(listView, backgroundView, nil)
            table.insert(button.userData.backgroundViews, backgroundView)
            --backgroundView.baseOffset = vec3(0,(-counter + 1) * 30,0)

            local titleString = itemInfo
            local disabled = false
            if isTable then
                titleString = itemInfo.name
                disabled = itemInfo.disabled
            end

            if not disabled then
                uiMenuItem:makeMenuItemBackground(backgroundView, listView, counter, hoverColor, mouseDownColor, function(wasClick)
                    uiStandardButton:setText(button.userData.buttonView, titleString)
                    
                    if isTable then
                        if itemInfo.iconObjectTypeIndex then
                            uiStandardButton:setObjectIcon(button.userData.buttonView, {
                                objectTypeIndex = itemInfo.iconObjectTypeIndex
                            })
                            uiStandardButton:setIconModel(button.userData.buttonView, nil, nil)
                        elseif itemInfo.iconModelName then
                            uiStandardButton:setIconModel(button.userData.buttonView, itemInfo.iconModelName, itemInfo.iconModelMaterialRemapTable)
                            uiStandardButton:setObjectIcon(button.userData.buttonView, nil)
                        end
                    end

                    uiPopUpButton:hidePopupMenu(button)

                    if button.userData.selectionChangedFunction then
                        button.userData.selectedItemIndex = i
                        button.userData.selectionChangedFunction(i, itemInfo)
                    end
                    --updateSelectedIndex(button.userData, i)
                end)
            end

            
            uiSelectionLayout:addView(listView, backgroundView)
            
            local nameTextView = TextView.new(backgroundView)

            if isTable then
                if itemInfo.iconObjectTypeIndex or itemInfo.iconModelName then
                    local gameObjectView = uiGameObjectView:create(backgroundView, vec2(30,30), uiGameObjectView.types.standard)
                    --uiGameObjectView:setBackgroundAlpha(gameObjectView, 0.6)
                    gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                    gameObjectView.baseOffset = vec3(4,0,0)
                    if itemInfo.iconObjectTypeIndex then
                       -- mj:log("itemInfo.iconObjectTypeIndex:", itemInfo.iconObjectTypeIndex)
                        uiGameObjectView:setObject(gameObjectView, {
                            objectTypeIndex = itemInfo.iconObjectTypeIndex
                        }, nil, nil)
                    else
                        uiGameObjectView:setModelName(gameObjectView, itemInfo.iconModelName, itemInfo.iconModelMaterialRemapTable)
                    end
                    gameObjectView.masksEvents = false
                    if disabled then
                        uiGameObjectView:setDisabled(gameObjectView, true)
                    end
                    --uiStandardButton:setIconModel(button.userData.buttonView, itemInfo.iconModelName, nil)
                end
                
                nameTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                nameTextView.baseOffset = vec3(38,0,0)
            else
                nameTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
                nameTextView.baseOffset = vec3(0,0,0)
            end
            nameTextView.font = Font(uiCommon.fontName, 16)

            if disabled then
                nameTextView.color = mj.disabledTextColor
            else
                nameTextView.color = vec4(1.0,1.0,1.0,1.0)
            end
            nameTextView.text = titleString

            counter = counter + 1
        end
    end
end

function uiPopUpButton:setSelection(button, selectedItemIndex)
    
    local userData = button.userData
    local itemInfo = userData.itemList[selectedItemIndex]
    if not itemInfo then
        uiStandardButton:setText(userData.buttonView, "")
        userData.selectedItemIndex = nil
        --mj:error("uiPopUpButton:setSelection called with index:", selectedItemIndex, " beyond the number of menu items:", #userData.itemList)
        return
    end
    local titleString = itemInfo
    if type(itemInfo) == "table" then
        titleString = itemInfo.name
        if itemInfo.iconObjectTypeIndex then
            uiStandardButton:setObjectIcon(userData.buttonView, {
                objectTypeIndex = itemInfo.iconObjectTypeIndex
            })
            uiStandardButton:setIconModel(userData.buttonView, nil, nil)
        elseif itemInfo.iconModelName then
            uiStandardButton:setIconModel(userData.buttonView, itemInfo.iconModelName, itemInfo.iconModelMaterialRemapTable)
            uiStandardButton:setObjectIcon(userData.buttonView, nil)
        end
    end

    uiStandardButton:setText(userData.buttonView, titleString)
    userData.selectedItemIndex = selectedItemIndex
end

function uiPopUpButton:getSelectedIndex(button)
    return button.userData.selectedItemIndex
end

function uiPopUpButton:setSelectionFunction(button, clickFunction)
    button.userData.selectionChangedFunction = clickFunction
end

function uiPopUpButton:setDisabled(button, disabled)
    uiStandardButton:setDisabled(button.userData.buttonView, disabled)
end

function uiPopUpButton:setSelected(button, selected)
    uiStandardButton:setSelected(button.userData.buttonView, selected)
end

function uiPopUpButton:callClickFunction(button)
    uiStandardButton:callClickFunction(button.userData.buttonView)
end

function uiPopUpButton:setUISelectionLayout(uiSelectionLayout_)
    uiSelectionLayout = uiSelectionLayout_
end

function uiPopUpButton:popupMenuVisible(button)
    local userData = button.userData
    if not userData.listViewBackground.hidden then
        return true
    end
    return false
end

function uiPopUpButton:hidePopupMenu(button)
    local userData = button.userData
    if not userData.listViewBackground.hidden then
        userData.listViewBackground.hidden = true
        endKeyboardCapture(button)
        uiSelectionLayout:removeActiveSelectionLayoutView(userData.listView)
        if userData.onHideFunction then
            userData.onHideFunction()
        end
    end
end

return uiPopUpButton