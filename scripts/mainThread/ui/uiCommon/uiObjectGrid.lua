local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local gameObject = mjrequire "common/gameObject"
local model = mjrequire "common/model"
local material = mjrequire "common/material"
--local locale = mjrequire "common/locale"

--local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"

local uiObjectGrid = {}

local function addButton(gridView)
    local userTable = gridView.userData
    userTable.buttonCount = userTable.buttonCount + 1
    local index = userTable.buttonCount

    
    local gridWidth = userTable.gridWidth
    local itemsPerRow = userTable.itemsPerRow
    local itemSize = userTable.itemSize

    userTable.buttonInfos[index] = {}

    local gridX = (index - 1) % itemsPerRow
    local gridY = math.floor((index - 1) / itemsPerRow)

    local rowView = userTable.rowViews[gridY]
    if not rowView then
        rowView = View.new(userTable.scrollView)
        userTable.rowViews[gridY] = rowView
        rowView.size = vec2(gridWidth, itemSize)
        rowView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        
        uiScrollView:insertRow(userTable.scrollView, rowView, nil)

        userTable.buttonGrid[gridY] = {}
    end


    local button = uiStandardButton:create(rowView, vec2(itemSize,itemSize), uiStandardButton.types.slim_1x1_bordered_dark)
    button.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    button.baseOffset = vec3(gridX * itemSize, 0, 0)
    local buttonUserData = button.userData
    buttonUserData.buttonIndex = index
    
    userTable.buttonGrid[gridY][gridX] = button
    uiSelectionLayout:addView(gridView, button)

    uiStandardButton:setDisabled(button, true)
    
    uiStandardButton:setClickFunction(button, function()
        uiSelectionLayout:setSelection(gridView, button)
    end)
    uiToolTip:add(button.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionAbove), nil, nil, nil, nil, nil)

    
    uiStandardButton:setSelectionChangedCallbackFunction(button, function(isSelected)
        if isSelected then
            userTable.clickFunction(userTable.buttonInfos[index])
        end
    end)

    --uiSelectionLayout:addView(gridView, button)


    userTable.buttonInfos[index] = {
        button = button,
    }
end

local function customConnectionsCreationFunction(gridView)
    local connections = {}
    local userTable = gridView.userData
    local itemsPerRow = userTable.itemsPerRow
    for y=0,99 do
        local gridRow = userTable.buttonGrid[y]
        if not gridRow then
            break
        end
        local aboveRow = userTable.buttonGrid[y-1]
        local belowRow = userTable.buttonGrid[y+1]
        for x=0,itemsPerRow - 1 do
            local button = gridRow[x]
            if not button then
                break
            end
            local thisButtonConnections = {}
            connections[button] = thisButtonConnections

            local leftView = gridRow[x - 1]
            if leftView then
                thisButtonConnections[uiSelectionLayout.directions.left] = {
                    view = leftView
                }
            else
                if aboveRow then
                    local aboveLastView = aboveRow[itemsPerRow - 1]
                    if aboveLastView then
                        thisButtonConnections[uiSelectionLayout.directions.left] = {
                            view = aboveLastView
                        }
                    end
                end
            end

            local rightView = gridRow[x + 1]
            if rightView then
                thisButtonConnections[uiSelectionLayout.directions.right] = {
                    view = rightView
                }
            else
                if belowRow then
                    local belowFirstView = belowRow[0]
                    if belowFirstView then
                        thisButtonConnections[uiSelectionLayout.directions.right] = {
                            view = belowFirstView
                        }
                    end
                end
            end

            if aboveRow then
                local aboveView = aboveRow[x]
                if aboveView then
                    thisButtonConnections[uiSelectionLayout.directions.up] = {
                        view = aboveView
                    }
                end
            end
            if belowRow then
                local belowView = belowRow[x]
                if belowView then
                    thisButtonConnections[uiSelectionLayout.directions.down] = {
                        view = belowView
                    }
                end
            end
            
        end
    end
    return connections
end

function uiObjectGrid:create(parentView, size, clickFunction)
    local userTable = {
        buttonCount = 0,
        buttonInfos = {},
        rowViews = {},
        buttonGrid = {},
        clickFunction = clickFunction
    }

    local insetView = ModelView.new(parentView)
    insetView:setModel(model:modelIndexForName("ui_inset_lg_1x1"))
    local scaleToUsePaneX = size.x * 0.5-- * (3.0 / 2.0)
    local scaleToUsePaneY = size.y * 0.5 
    insetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    insetView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    insetView.size = size
    insetView.userData = userTable
    
    local scrolllViewSize = vec2(size.x - 10, size.y - 10)
    local scrollView = uiScrollView:create(insetView, scrolllViewSize, MJPositionInnerLeft)
    scrollView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    scrollView.baseOffset = vec3(6,-5, 4)
    userTable.scrollView = scrollView
    
    
    local gridWidth = userTable.scrollView.size.x - 20
    local itemsPerRow = math.floor(gridWidth / 60)
    local itemSize = gridWidth / itemsPerRow

    userTable.gridWidth = gridWidth
    userTable.itemsPerRow = itemsPerRow
    userTable.itemSize = itemSize
    
    --[[local gridContentView = View.new(gridView)
    gridContentView.size = vec2(size.x - 10, size.y - 20)
    gridContentView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    gridContentView.baseOffset = vec3(4,-6, 0)
    userTable.gridContentView = gridContentView]]

    --uiSelectionLayout:createForView(gridView)
    
    local function customConnectionsCreationFunctionForThisGrid(scrollView_)
        return customConnectionsCreationFunction(insetView)
    end
    
    uiSelectionLayout:createForView(insetView, customConnectionsCreationFunctionForThisGrid)

    return insetView
end


function uiObjectGrid:setDisableControllerSelection(gridView, disableControllerSelection)
    uiSelectionLayout:setDisableControllerSelection(gridView, disableControllerSelection)
end

function uiObjectGrid:getSelectedInfo(gridView)
    local selectedButton = uiSelectionLayout:getSelection(gridView)
    if selectedButton then
        local userTable = gridView.userData
        return userTable.buttonInfos[selectedButton.userData.buttonIndex]
    end
    return nil
end

--[[function uiObjectGrid:selectButtonAtIndex(gridView, selectionIndex) --needs to be re-implemented to use gridObjectIndex probably, if needed
    local userTable = gridView.userData
    uiSelectionLayout:setSelection(gridView, userTable.buttonInfos[selectionIndex].button)
end]]

function uiObjectGrid:getSelectedButtonGridIndex(gridView)
    local selectedButton = uiSelectionLayout:getSelection(gridView)
    if selectedButton then
        return selectedButton.userData.objectGridIndex
    end
    return nil
end

function uiObjectGrid:assignLayoutSelection(gridView)
    uiSelectionLayout:setActiveSelectionLayoutView(gridView)
end

function uiObjectGrid:removeLayoutSelection(gridView)
    uiSelectionLayout:removeActiveSelectionLayoutView(gridView)
end

function uiObjectGrid:updateButtons(gridView, gridData, selectGridItemIndexOrNil)
    uiSelectionLayout:removeAllViews(gridView)

    local userTable = gridView.userData

    local function updateButton(buttonIndex, gridButtonData, objectGridIndex)
        if buttonIndex > userTable.buttonCount then
            addButton(gridView)
        end

        local buttonInfo = userTable.buttonInfos[buttonIndex]
        buttonInfo.gridButtonData = gridButtonData
        buttonInfo.button.hidden = false
        buttonInfo.button.userData.objectGridIndex = objectGridIndex


        if not buttonInfo.gameObjectView then
            buttonInfo.gameObjectView = uiGameObjectView:create(buttonInfo.button, buttonInfo.button.size - vec2(4,4), uiGameObjectView.types.standard)
            buttonInfo.gameObjectView.baseOffset = vec3(0,0,1)
        end

        if gridButtonData.gameObjectTypeIndex then
            local gameObjectType = gameObject.types[gridButtonData.gameObjectTypeIndex]
            uiGameObjectView:setObject(buttonInfo.gameObjectView, {objectTypeIndex = gameObjectType.index}, nil, nil)
        else
            uiGameObjectView:setModelName(buttonInfo.gameObjectView, gridButtonData.iconName, nil)
        end

        uiGameObjectView:setDisabled(buttonInfo.gameObjectView, (not gridButtonData.enabled))

        if gridButtonData.enabled then
            if not buttonInfo.unlocked then
                buttonInfo.unlocked = true
                uiStandardButton:setDisabled(buttonInfo.button, false)
                
                if buttonInfo.lockIcon then
                    buttonInfo.button:removeSubview(buttonInfo.lockIcon)
                    buttonInfo.lockIcon = nil
                end
            end

            uiToolTip:updateText(buttonInfo.button.userData.backgroundView, gridButtonData.name, nil, false)
        else
            if buttonInfo.unlocked then
                buttonInfo.unlocked = nil
                uiStandardButton:setDisabled(buttonInfo.button, true)
            end
            if not buttonInfo.lockIcon then
                local icon = ModelView.new(buttonInfo.button)
                icon:setModel(model:modelIndexForName("icon_lock"), {
                    default = material.types.ui_disabled.index
                })
                icon.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
                icon.baseOffset = vec3(-6, -8, 1)
                local scaleToUse = buttonInfo.button.size.x * 0.15
                icon.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse)
                icon.size = vec2(scaleToUse,scaleToUse)
                buttonInfo.lockIcon = icon
                icon.masksEvents = false
            end
            
            uiToolTip:updateText(buttonInfo.button.userData.backgroundView, gridButtonData.disabledToolTipText, nil, true)
        end
    end

    local foundEnabledButton = false
    local buttonIndex = 1
    local buttonIndexToSelect = nil
    for i=1,#gridData do
        if gridData[i].enabled then
            foundEnabledButton = true
            updateButton(buttonIndex, gridData[i], i)
            if selectGridItemIndexOrNil == i then
                buttonIndexToSelect = buttonIndex
            end
            buttonIndex = buttonIndex + 1
        end
    end

    userTable.hasEnabledButton = foundEnabledButton

    for i=1,#gridData do
        if not gridData[i].enabled then
            updateButton(buttonIndex, gridData[i], i)
            buttonIndex = buttonIndex + 1
        end
    end

    for i=buttonIndex,userTable.buttonCount do
        local buttonInfo = userTable.buttonInfos[i]
        buttonInfo.button.hidden = true
    end

    if userTable.hasEnabledButton then
        if buttonIndexToSelect then
            uiSelectionLayout:setSelection(gridView, userTable.buttonInfos[buttonIndexToSelect].button)
        elseif not uiSelectionLayout:getSelection(gridView) then
            if userTable.buttonInfos[1] and userTable.buttonInfos[1].unlocked then
                uiSelectionLayout:setSelection(gridView, userTable.buttonInfos[1].button)
            end
        end
    else
        uiSelectionLayout:setSelection(gridView, nil)
    end
end

return uiObjectGrid