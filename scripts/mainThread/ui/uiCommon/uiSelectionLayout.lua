local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local length2D2 = mjm.length2D2

local keyMapping = mjrequire "mainThread/keyMapping"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiSlider = mjrequire "mainThread/ui/uiCommon/uiSlider"
local uiPopUpButton = mjrequire "mainThread/ui/uiCommon/uiPopUpButton"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"

local uiSelectionLayout = {}

local activeSelectionLayoutView = nil

local directions = mj:enum {
    "left",
    "right",
    "down",
    "up"
}

uiSelectionLayout.directions = directions

local function getOppositeDirection(inDirection)
    if inDirection == directions.left then
        return directions.right
    elseif inDirection == directions.right then
        return directions.left
    elseif inDirection == directions.down then
        return directions.up
    else
        return directions.down
    end
end

local function viewIsAllowedToBeSelected(foundView)
    if (not foundView) or (not foundView.userData) then
        return false
    end
    return not ((foundView.hidden and (not foundView.userData.isMenuItemBackground)) or (foundView.userData.disabled and not foundView.userData.selectionLayoutAllowsDisabledSelection))
end


local function changeSelection(direction)
    if activeSelectionLayoutView then
        local userData = activeSelectionLayoutView.userData
        
        local function updateConnections()
            local connections = {}

            local function getDirectionInfo(viewA, viewB)

                local posA = viewA:localPointToWindow(vec3(viewA.size.x * 0.5,viewA.size.y * 0.5,0.0))
                local posB = viewB:localPointToWindow(vec3(viewB.size.x * 0.5,viewB.size.y * 0.5,0.0))

                local distanceX = posB.x - posA.x
                local distanceY = posB.y - posA.y

                --[[if viewA.userData and viewA.userData.debugName and viewB.userData and viewB.userData.debugName then
                    mj:log(viewA.userData.debugName, " -> ", viewB.userData.debugName, " distanceX:", distanceX, " distanceY:", distanceY, " sizeA:", viewA.size, " sizeB:", viewB.size)
                end]]

                local overlapDistanceX = math.abs(distanceX) - viewA.size.x * 0.5 - viewB.size.x * 0.5
                local overlapDistanceY = math.abs(distanceY) - viewA.size.y * 0.5 - viewB.size.y * 0.5

                if overlapDistanceX > overlapDistanceY then
                    if distanceX > 0 then
                        return {
                            direction = directions.right,
                            distance = length2D2(vec2(distanceX, distanceY))
                        }
                    else
                        return {
                            direction = directions.left,
                            distance = length2D2(vec2(distanceX, distanceY))
                        }
                    end
                else
                    if distanceY > 0 then
                        return {
                            direction = directions.up,
                            distance = length2D2(vec2(distanceX, distanceY))
                        }
                    else
                        return {
                            direction = directions.down,
                            distance = length2D2(vec2(distanceX, distanceY))
                        }
                    end
                end
            end

            local function assignDirectionInfo(viewA, viewB, directionInfo)
                local connectionsA = connections[viewA]
                if not connectionsA then
                    connectionsA = {}
                    connections[viewA] = connectionsA
                end
                local connectionsB = connections[viewB]
                if not connectionsB then
                    connectionsB = {}
                    connections[viewB] = connectionsB
                end

                local oppositeDirection = getOppositeDirection(directionInfo.direction)

                if not connectionsA[directionInfo.direction] and not connectionsB[oppositeDirection] then
                    connectionsA[directionInfo.direction] = {
                        view = viewB,
                        distance = directionInfo.distance,
                    }
                    connectionsB[oppositeDirection] = {
                        view = viewA,
                        distance = directionInfo.distance,
                    }
                    
                    --[[if viewA.userData and viewA.userData.debugName and viewB.userData and viewB.userData.debugName then
                        mj:log("assigning connection between:", viewA.userData.debugName, " <-> ", viewB.userData.debugName, " direction:", directionInfo.direction)
                    end]]
                elseif ((not connectionsA[directionInfo.direction]) or connectionsA[directionInfo.direction].distance > directionInfo.distance) and 
                ((not connectionsB[oppositeDirection]) or connectionsB[oppositeDirection].distance > directionInfo.distance) then
                    

                    if connectionsA[directionInfo.direction] then
                        local prevView = connectionsA[directionInfo.direction].view
                        connections[prevView][oppositeDirection] = nil
                        
                        --[[if viewA.userData and viewA.userData.debugName and prevView.userData and prevView.userData.debugName then
                            mj:log("A removing connection between:", viewA.userData.debugName, " -> ", prevView.userData.debugName, " direction:", directionInfo.direction)
                        end]]
                    end
                    if connectionsB[oppositeDirection] then
                        local prevView = connectionsB[oppositeDirection].view
                        connections[prevView][directionInfo.direction] = nil
                        --[[if viewA.userData and viewA.userData.debugName and prevView.userData and prevView.userData.debugName then
                            mj:log("B removing connection between:", viewA.userData.debugName, " -> ", prevView.userData.debugName, " direction:", oppositeDirection)
                        end]]
                    end
                    connectionsA[directionInfo.direction] = {
                        view = viewB,
                        distance = directionInfo.distance,
                    }
                    connectionsB[oppositeDirection] = {
                        view = viewA,
                        distance = directionInfo.distance,
                    }
                    
                    --[[if viewA.userData and viewA.userData.debugName and viewB.userData and viewB.userData.debugName then
                        mj:log("replacing connection between:", viewA.userData.debugName, " <-> ", viewB.userData.debugName, " direction:", directionInfo.direction)
                    end]]
                    
                end

                
            end

            for i = 1,#userData.selectionLayoutViews do
                for j=i+1, #userData.selectionLayoutViews do
                    local viewA = userData.selectionLayoutViews[i]
                    local viewB = userData.selectionLayoutViews[j]
                    local directionInfo = getDirectionInfo(viewA, viewB)
                    assignDirectionInfo(viewA, viewB, directionInfo)
                end
            end
            
            userData.selectionLayoutConnections = connections
            userData.selectionLayoutConnectionsAssigned = true
        end

        if not userData.selectionLayoutConnectionsAssigned then
            if userData.customConnectionsCreationFunction then
                userData.selectionLayoutConnections = userData.customConnectionsCreationFunction(activeSelectionLayoutView)
                userData.selectionLayoutConnectionsAssigned = true
            else
                updateConnections()
            end
        end

        local connections = userData.selectionLayoutConnections
        local selectedView = userData.selectionLayoutSelectedView

        if connections then
            if not selectedView then
                uiSelectionLayout:setSelection(activeSelectionLayoutView, userData.selectionLayoutViews[1])
            else
                local function getConnectedView(inView)
                    
                    local inViewUserData = inView.userData
                    if inViewUserData.selectionLayoutDirectionOverrides and inViewUserData.selectionLayoutDirectionOverrides[direction] then
                        return inViewUserData.selectionLayoutDirectionOverrides[direction]
                    end

                    if connections[inView] and connections[inView][direction] then
                        return connections[inView][direction].view
                    end
                    return nil
                end

                local parentView = selectedView
                for i=1,10 do
                    local foundView = getConnectedView(parentView)
                    if foundView then
                        if not viewIsAllowedToBeSelected(foundView) then
                            parentView = foundView
                        else
                            uiSelectionLayout:setSelection(activeSelectionLayoutView, foundView)
                            break
                        end
                    else
                        break
                    end
                end
            end
        end
        
        if selectedView and selectedView.userData.uiSlider then
            if direction == directions.left then
                uiSlider:addDueToControllerButton(selectedView, -1)
            elseif direction == directions.right then
                uiSlider:addDueToControllerButton(selectedView, 1)
            end
        end
    end
end

function uiSelectionLayout:addDirectionOverride(view, relativeView, direction, bidirectional)
    --mj:log("addDirectionOverride view:", view, " relativeView:", relativeView)
    if not view.userData then
        view.userData = {}
    end
    if not view.userData.selectionLayoutDirectionOverrides then
        view.userData.selectionLayoutDirectionOverrides = {}
    end

    view.userData.selectionLayoutDirectionOverrides[direction] = relativeView
    
    if bidirectional then
        if not relativeView.userData then
            relativeView.userData = {}
        end
        if not relativeView.userData.selectionLayoutDirectionOverrides then
            relativeView.userData.selectionLayoutDirectionOverrides = {}
        end
        relativeView.userData.selectionLayoutDirectionOverrides[getOppositeDirection(direction)] = view
    end
end

function uiSelectionLayout:clickSelectedView()
    if activeSelectionLayoutView then
        local userData = activeSelectionLayoutView.userData
        local selectedView = userData.selectionLayoutSelectedView
        if selectedView then
            local selectedViewUserData = selectedView.userData
            if selectedViewUserData.uiStandardButton then
                uiStandardButton:callClickFunction(selectedView)
            elseif selectedViewUserData.uiPopUpButton then
                uiPopUpButton:callClickFunction(selectedView)
            elseif selectedViewUserData.isMenuItemBackground then
                uiMenuItem:callMenuItemClickFunction(selectedView)
            elseif selectedViewUserData.isUiTextEntry then
                uiTextEntry:callClickFunction(selectedView)
            end
            
            if selectedViewUserData.selectionClickedFunction then
                selectedViewUserData.selectionClickedFunction()
            end
            return true
        end
    end
    return false
end

function uiSelectionLayout:setSelectionClickedFunction(view, func)
    local userData = view.userData
    if not userData then
        userData = {}
        view.userData = userData
    end
    userData.selectionClickedFunction = func
end

local keyMap = {
    [keyMapping:getMappingIndex("menu", "up")] = function(isDown, isRepeat)
        if isDown then
            changeSelection(directions.up)
        end
    end,
    [keyMapping:getMappingIndex("menu", "down")] = function(isDown, isRepeat)
        if isDown then
            changeSelection(directions.down)
        end
    end,
    [keyMapping:getMappingIndex("menu", "left")] = function(isDown, isRepeat)
        if isDown then
            changeSelection(directions.left)
        end
    end,
    [keyMapping:getMappingIndex("menu", "right")] = function(isDown, isRepeat)
        if isDown then
            changeSelection(directions.right)
        end
    end,
    [keyMapping:getMappingIndex("menu", "select")] = function(isDown, isRepeat)
        if isDown then
            uiSelectionLayout:clickSelectedView()
        end
    end,
}

keyMap[keyMapping:getMappingIndex("menu", "selectAlt")] = keyMap[keyMapping:getMappingIndex("menu", "select")]

local function keyChanged(isDown, mapIndexes, isRepeat)
    if activeSelectionLayoutView and not activeSelectionLayoutView.hidden then
        for i,mapIndex in ipairs(mapIndexes) do
            if keyMap[mapIndex]  then
                if keyMap[mapIndex](isDown, isRepeat) then
                    return true
                end
            end
        end
    end
    return false
end

function uiSelectionLayout:createForView(selectionLayoutView, customConnectionsCreationFunctionOrNil)
    local userData = selectionLayoutView.userData
    if not userData then
        userData = {}
        selectionLayoutView.userData = userData
    end
    userData.selectionLayoutViews = {}
    userData.selectionLayoutConnections = {}
    userData.customConnectionsCreationFunction = customConnectionsCreationFunctionOrNil
end

function uiSelectionLayout:setSelectionLayoutViewActiveChangedFunction(selectionLayoutView, func)
    local userData = selectionLayoutView.userData
    if not userData then
        userData = {}
        selectionLayoutView.userData = userData
    end
    userData.activeChangedFunction = func
end

function uiSelectionLayout:setActiveSelectionLayoutView(selectionLayoutView)
    if activeSelectionLayoutView ~= selectionLayoutView then
        --mj:error("uiSelectionLayout:setActiveSelectionLayoutView(selectionLayoutView):", selectionLayoutView)
        uiSelectionLayout:removeActiveSelectionLayoutView(activeSelectionLayoutView)
    end
    activeSelectionLayoutView = selectionLayoutView
    if activeSelectionLayoutView then
        if not selectionLayoutView.userData.removeActiveSelectionViewWhenViewRemovedSet then
            selectionLayoutView.userData.removeActiveSelectionViewWhenViewRemovedSet = true
            local prevWasRemoved = selectionLayoutView.wasRemoved
            selectionLayoutView.wasRemoved = function()
                if activeSelectionLayoutView == selectionLayoutView then
                    uiSelectionLayout:removeActiveSelectionLayoutView(selectionLayoutView)
                end
                if prevWasRemoved then
                    prevWasRemoved()
                end
            end
        end

        uiSelectionLayout:restorePreviousSelection(selectionLayoutView)
        if activeSelectionLayoutView.userData.activeChangedFunction then
            activeSelectionLayoutView.userData.activeChangedFunction(true)
        end
    end
end

function uiSelectionLayout:removeActiveSelectionLayoutView(selectionLayoutView)
   -- mj:log("uiSelectionLayout:removeActiveSelectionLayoutView:")
    if selectionLayoutView and activeSelectionLayoutView == selectionLayoutView then
        uiSelectionLayout:setSelection(selectionLayoutView, nil)
        if activeSelectionLayoutView.userData.activeChangedFunction then
            activeSelectionLayoutView.userData.activeChangedFunction(false)
        end
        activeSelectionLayoutView = nil
    end
end

function uiSelectionLayout:removeAnyActiveSelectionLayoutView()
    if activeSelectionLayoutView then
        uiSelectionLayout:setSelection(activeSelectionLayoutView, nil)
        if activeSelectionLayoutView.userData.activeChangedFunction then
            activeSelectionLayoutView.userData.activeChangedFunction(false)
        end
        activeSelectionLayoutView = nil
    end
end

function uiSelectionLayout:isActiveSelectionLayoutView(selectionLayoutView)
    return selectionLayoutView and activeSelectionLayoutView == selectionLayoutView
end

function uiSelectionLayout:addView(selectionLayoutView, subView)
    local userData = selectionLayoutView.userData
    table.insert(userData.selectionLayoutViews, subView)
    
end

function uiSelectionLayout:removeAllViews(selectionLayoutView)
    uiSelectionLayout:setSelection(selectionLayoutView, nil) --added 1/23, otherwise variations grid view keeps bad selections
    local userData = selectionLayoutView.userData
    userData.selectionLayoutViews = {}
    userData.selectionLayoutConnections = {}
    userData.selectionLayoutConnectionsAssigned = false
    userData.selectionLayoutSelectedView = nil
    userData.mostRecentSelection = nil
end

function uiSelectionLayout:setSelection(selectionLayoutView, selectedView, dontCallSelectionFunction)

    --mj:log("uiSelectionLayout:setSelection:", selectedView)
    if not viewIsAllowedToBeSelected(selectedView) then
        selectedView = nil
        --mj:error("selection is not allowed to be selected:")
        --[[if selectedView then
            mj:log(selectedView.userData)
        end]]
    end
    local userData = selectionLayoutView.userData
    local oldSelectedView = userData.selectionLayoutSelectedView
    local function updateSelection(viewToUpdate, newValue)
        local viewToUpdateUserData = viewToUpdate.userData
        if viewToUpdateUserData then
            if viewToUpdateUserData.uiStandardButton then
                uiStandardButton:setSelected(viewToUpdate, newValue)
            elseif viewToUpdateUserData.uiSlider then
                uiSlider:setSelected(viewToUpdate, newValue)
            elseif viewToUpdateUserData.uiPopUpButton then
                uiPopUpButton:setSelected(viewToUpdate, newValue)
            elseif viewToUpdateUserData.isMenuItemBackground then
            -- mj:log("isMenuItemBackground:", selectedView)
                uiMenuItem:setMenuItemBackgroundSelected(viewToUpdate, newValue)
            elseif viewToUpdateUserData.isUiTextEntry then
                uiTextEntry:setSelected(viewToUpdate, newValue)
                --uiMenuItem:setMenuItemBackgroundSelected(viewToUpdate, newValue)
            end
            
            if viewToUpdateUserData.selectionLayoutSelectionChangedFunction then
                viewToUpdateUserData.selectionLayoutSelectionChangedFunction(newValue)
            end
        end
    end
    if selectedView ~= oldSelectedView then
        --mj:log("selectedView ~= oldSelectedView")
        if oldSelectedView then
            updateSelection(oldSelectedView, false)
        end
        userData.selectionLayoutSelectedView = selectedView
        if selectedView then
            userData.mostRecentSelection = selectedView
            updateSelection(selectedView, true)

            if activeSelectionLayoutView == selectionLayoutView and (not dontCallSelectionFunction) and selectedView.userData and selectedView.userData.itemSelectedFunction then
                --mj:error("call itemSelectedFunction")
                selectedView.userData.itemSelectedFunction()
            end
        end
    end

end

function uiSelectionLayout:setSelectionChangedFunction(view, func)
    local userData = view.userData
    if not userData then
        userData = {}
        view.userData = userData
    end
    userData.selectionLayoutSelectionChangedFunction = func
end

function uiSelectionLayout:setItemSelectedFunction(selectionLayoutViewSubItem, itemSelectedFunction)
    local userData = selectionLayoutViewSubItem.userData
    if not userData then
        userData = {}
        selectionLayoutViewSubItem.userData = userData
    end
    userData.itemSelectedFunction = itemSelectedFunction
end

function uiSelectionLayout:restorePreviousSelection(selectionLayoutView)
    local userData = selectionLayoutView.userData
    if userData then
        if userData.mostRecentSelection then
            uiSelectionLayout:setSelection(selectionLayoutView, userData.mostRecentSelection, true)
        else
            uiSelectionLayout:setSelection(selectionLayoutView, userData.selectionLayoutViews[1], true)
        end
    end
end

function uiSelectionLayout:getSelection(selectionLayoutView)
    local userData = selectionLayoutView.userData
    if userData then
        return userData.selectionLayoutSelectedView
    end
    return nil
end

function uiSelectionLayout:setDisableControllerSelection(selectionLayoutView, disableControllerSelection)
    local userData = selectionLayoutView.userData
    if not userData then
        userData = {}
        selectionLayoutView.userData = userData
    end
    userData.disableControllerSelection = disableControllerSelection
end

function uiSelectionLayout:init(eventManager)
    activeSelectionLayoutView = nil

    uiPopUpButton:setUISelectionLayout(uiSelectionLayout)

    eventManager:addEventListenter(keyChanged, eventManager.keyChangedListeners)
    

    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuSelect", function(isDown)
        if isDown and activeSelectionLayoutView and (not activeSelectionLayoutView.hidden) then
            
            local userData = activeSelectionLayoutView.userData
            if userData.disableControllerSelection then
                return false
            end
            --mj:log("uiSelectionLayout:", activeSelectionLayoutView)
            return uiSelectionLayout:clickSelectedView()
        end
        return false
    end)
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuUp", function(isDown)
        if isDown and activeSelectionLayoutView and (not activeSelectionLayoutView.hidden) then
            changeSelection(directions.up)
            return true
        end
        return false
    end)
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuDown", function(isDown)
        if isDown and activeSelectionLayoutView and (not activeSelectionLayoutView.hidden) then
            changeSelection(directions.down)
            return true
        end
        return false
    end)
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuLeft", function(isDown)
        if isDown and activeSelectionLayoutView and (not activeSelectionLayoutView.hidden) then
            changeSelection(directions.left)
            return true
        end
        return false
    end)
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuRight", function(isDown)
        if isDown and activeSelectionLayoutView and (not activeSelectionLayoutView.hidden) then
            changeSelection(directions.right)
            return true
        end
        return false
    end)

    local released = true
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, false, "radialMenuDirection", function(pos)
        if activeSelectionLayoutView and (not activeSelectionLayoutView.hidden) then
            local posLength2 = length2D2(pos)
            if posLength2 > 0.98 then
                if released then
                    local direction = nil
                    if math.abs(pos.x) > math.abs(pos.y) then
                        if pos.x > 0 then
                            direction = directions.right
                        else
                            direction = directions.left
                        end
                    else
                        if pos.y > 0 then
                            direction = directions.up
                        else
                            direction = directions.down
                        end
                    end
                    changeSelection(direction)
                    released = false
                end
            else
                released = true
            end
        else
            released = true
        end
    end)

end

return uiSelectionLayout