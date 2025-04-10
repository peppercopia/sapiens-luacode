local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local length2 = mjm.length2

local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
--local material = mjrequire "common/material"
local resource = mjrequire "common/resource"
local fuel = mjrequire "common/fuel"
local gameObject = mjrequire "common/gameObject"
local constructable = mjrequire "common/constructable"
local medicine = mjrequire "common/medicine"
local timer = mjrequire "common/timer"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"
local logicInterface = mjrequire "mainThread/logicInterface"
local constructableUIHelper = mjrequire "mainThread/ui/constructableUIHelper"
local eventManager = mjrequire "mainThread/eventManager"
local keyMapping = mjrequire "mainThread/keyMapping"


local resourcesUI = {}

local hoverColor = mj.highlightColor * 0.8
local mouseDownColor = mj.highlightColor * 0.6
local backgroundColors = {vec4(0.03,0.03,0.03,0.5), vec4(0.0,0.0,0.0,0.5)}

local manageUI = nil
local world = nil
local localPlayer = nil
local gameUI = nil

local resourcesListView = nil
local objectTypesListView = nil

--local resourceObjectCounts = nil
local resourceData = nil

local listViewItemHeight = 30.0
local listViewItemObjectImageViewSize = vec2(30.0, 30.0)

local resourceSelectedRowIndex = nil
local objectSelectedRowIndex = nil

local rightPaneView = nil
local selectedObjectImageView = nil
local selectedTitleTextView = nil
local selectedSummaryTextView = nil
local restrictResourcesScrollView = nil
local zoomButton = nil

local resourceListItems = {}
local objectTypeListItems = {}

local backgroundColorCounter = 1

local function createRowBackground(listView)
    local backgroundView = ColorView.new(listView)
    local defaultColor = backgroundColors[backgroundColorCounter % 2 + 1]

    backgroundView.color = defaultColor

    backgroundView.size = vec2(listView.size.x - 22, listViewItemHeight)
    backgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)

    uiScrollView:insertRow(listView, backgroundView, nil)

    backgroundColorCounter = backgroundColorCounter + 1
    return backgroundView
end

local orderedConstructableClassifications = {
    [constructable.classifications.fill.index] = 1,
    [constructable.classifications.path.index] = 2,
    [constructable.classifications.build.index] = 3,
    [constructable.classifications.plant.index] = 4,
    [constructable.classifications.craft.index] = 5,
    [constructable.classifications.place.index] = 6,
    [constructable.classifications.fertilize.index] = 7,
}

local restrictionTypes = mj:enum {
    "constructable",
    "fuel",
    "food",
    "medicine",
    "tool",
    "clothing",
}

local function updateUseList(objectRowInfo)
--[[

    else
        constructables = constructable.constructablesByResourceObjectTypeIndexes[currentObjectTypeIndex]
    end

    currentItemList = {}
    if constructables and constructables[1] then
        for i,constructableClassificationTypeIndex in ipairs(orderedConstructableClassifications) do
            for j,constructableTypeIndex in ipairs(constructables) do
                local constructableType = constructable.types[constructableTypeIndex]
                if constructableType.classification == constructableClassificationTypeIndex then
                    table.insert(currentItemList, constructableTypeIndex)
                end
            end
        end
    end
]]
    local constructablesSet = {}
    local orderedConstructables = {}
    
    local resourceRowInfo = resourceListItems[resourceSelectedRowIndex]
    local resourceType = resourceRowInfo.resourceType
    
    if objectRowInfo.objectTypeIndex then
        local constructables = constructable.constructablesByResourceObjectTypeIndexes[objectRowInfo.objectTypeIndex]
        if constructables then
            for i,constructableTypeIndex in ipairs(constructables) do
                if not constructablesSet[constructableTypeIndex] then
                    constructablesSet[constructableTypeIndex] = true
                    local constructableType = constructable.types[constructableTypeIndex]
                    if not constructableType.deprecated then
                        if orderedConstructableClassifications[constructableType.classification] then
                            table.insert(orderedConstructables, constructable.types[constructableTypeIndex])
                        end
                    end
                end
            end
        end
    else
        local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
        for i, gameObjectTypeIndex in ipairs(gameObjectTypes) do
            local constructables = constructable.constructablesByResourceObjectTypeIndexes[gameObjectTypeIndex]
            if constructables then
                for j,constructableTypeIndex in ipairs(constructables) do
                    if not constructablesSet[constructableTypeIndex] then
                        constructablesSet[constructableTypeIndex] = true
                        local constructableType = constructable.types[constructableTypeIndex]
                        if not constructableType.deprecated then
                            if orderedConstructableClassifications[constructableType.classification] then
                                table.insert(orderedConstructables, constructableType)
                            end
                        end
                    end
                end
            end
        end
    end

    uiScrollView:removeAllRows(restrictResourcesScrollView)
    uiSelectionLayout:removeAllViews(restrictResourcesScrollView)

    local resourceBlockLists = world:getResourceBlockLists()

    local function sortConstructables(a,b)
        if a.classification ~= b.classification then
            --mj:log("a:", a, " b:", b)
            return orderedConstructableClassifications[a.classification] < orderedConstructableClassifications[b.classification]
        end
        return a.plural < b.plural
    end
    
    if next(constructablesSet) then
        table.sort(orderedConstructables, sortConstructables)
    end

    backgroundColorCounter = 1

    local function addRow(titleString, restrictionType, constructableTypeIndexOrNil, fuelGroupIndexOrNil, discovered)
        local rowBackgroundView = createRowBackground(restrictResourcesScrollView)
        
        local toggleButton = uiStandardButton:create(rowBackgroundView, vec2(26,26), uiStandardButton.types.toggle)
        toggleButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        toggleButton.baseOffset = vec3(4, 0, 0)
        
        --uiSelectionLayout:addView(useOnlyScrollView, toggleButton)

        local function getToggleStateForList(list)
            local foundEnabled = false
            local foundDisabled = false
            if objectRowInfo.objectTypeIndex then
                if list[objectRowInfo.objectTypeIndex] then
                    foundDisabled = true
                else
                    foundEnabled = true
                end
            else
                local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
                for i, gameObjectTypeIndex in ipairs(gameObjectTypes) do
                    if list[gameObjectTypeIndex] then
                        foundDisabled = true
                    else
                        foundEnabled = true
                    end
                end
            end

            if foundDisabled then
                if foundEnabled then
                    return uiStandardButton.toggleMixedState
                else
                    return false
                end
            end
            return true
        end

        local toggleState = true
        if constructableTypeIndexOrNil then
            if resourceBlockLists.constructableLists then
                local constructableList = resourceBlockLists.constructableLists[constructableTypeIndexOrNil]
                if constructableList then
                    toggleState = getToggleStateForList(constructableList)
                end
            end
        elseif fuelGroupIndexOrNil then
            if resourceBlockLists.fuelLists then
                local list = resourceBlockLists.fuelLists[fuelGroupIndexOrNil]
                if list then
                    toggleState = getToggleStateForList(list)
                end
            end
        elseif restrictionType == restrictionTypes.food then
            local list = resourceBlockLists.eatFoodList
            if list then
                toggleState = getToggleStateForList(list)
            end
        elseif restrictionType == restrictionTypes.medicine then
            local list = resourceBlockLists.medicineList
            if list then
                toggleState = getToggleStateForList(list)
            end
        elseif restrictionType == restrictionTypes.tool then
            local list = resourceBlockLists.toolBlockList
            if list then
                toggleState = getToggleStateForList(list)
            end
        elseif restrictionType == restrictionTypes.clothing then
            local list = resourceBlockLists.wearClothingList
            if list then
                toggleState = getToggleStateForList(list)
            end
        end
        
        uiStandardButton:setToggleState(toggleButton, toggleState)
        
        uiStandardButton:setClickFunction(toggleButton, function()
            --mj:log("in toggle function:", constructableTypeIndexOrNil)
            local newValue = uiStandardButton:getToggleState(toggleButton)

            local serverUpdateData = {}

            local function updateValue(list, serverUpdateDataList)
                if objectRowInfo.objectTypeIndex then
                    if newValue then
                        list[objectRowInfo.objectTypeIndex] = nil
                        serverUpdateDataList[objectRowInfo.objectTypeIndex] = false
                    else
                        list[objectRowInfo.objectTypeIndex] = true
                        serverUpdateDataList[objectRowInfo.objectTypeIndex] = true
                    end
                else
                    local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
                    for i, gameObjectTypeIndex in ipairs(gameObjectTypes) do
                        if newValue then
                            list[gameObjectTypeIndex] = nil
                            serverUpdateDataList[gameObjectTypeIndex] = false
                        else
                            list[gameObjectTypeIndex] = true
                            serverUpdateDataList[gameObjectTypeIndex] = true
                        end
                    end
                end
            end

            if restrictionType == restrictionTypes.food then
                local eatFoodList = resourceBlockLists.eatFoodList

                if not eatFoodList then
                    eatFoodList = {}
                    resourceBlockLists.eatFoodList = eatFoodList
                end
                
                local thisFoodServerUpdateData = {}
                updateValue(eatFoodList, thisFoodServerUpdateData)
                serverUpdateData.food = thisFoodServerUpdateData
            elseif restrictionType == restrictionTypes.tool then
                local toolBlockList = resourceBlockLists.toolBlockList

                if not toolBlockList then
                    toolBlockList = {}
                    resourceBlockLists.toolBlockList = toolBlockList
                end
                
                local thisToolServerUpdateData = {}
                updateValue(toolBlockList, thisToolServerUpdateData)
                serverUpdateData.tools = thisToolServerUpdateData
            elseif restrictionType == restrictionTypes.medicine then
                local medicineList = resourceBlockLists.medicineList

                if not medicineList then
                    medicineList = {}
                    resourceBlockLists.medicineList = medicineList
                end
                
                local thisMedicineServerUpdateData = {}
                updateValue(medicineList, thisMedicineServerUpdateData)
                serverUpdateData.medicine = thisMedicineServerUpdateData
            elseif restrictionType == restrictionTypes.clothing then
                local wearClothingList = resourceBlockLists.wearClothingList

                if not wearClothingList then
                    wearClothingList = {}
                    resourceBlockLists.wearClothingList = wearClothingList
                end
                
                local thisServerUpdateData = {}
                updateValue(wearClothingList, thisServerUpdateData)
                serverUpdateData.clothing = thisServerUpdateData
            elseif constructableTypeIndexOrNil then
                local constructableLists = resourceBlockLists.constructableLists

                if not constructableLists then
                    constructableLists = {}
                    resourceBlockLists.constructableLists = constructableLists
                end
                local constructableList = constructableLists[constructableTypeIndexOrNil]
                if not constructableList then
                    constructableList = {}
                    constructableLists[constructableTypeIndexOrNil] = constructableList
                end

                local thisConstructableServerUpdateData = {}
                updateValue(constructableList, thisConstructableServerUpdateData)
                serverUpdateData.constructables = {
                    [constructableTypeIndexOrNil] = thisConstructableServerUpdateData
                }
            elseif fuelGroupIndexOrNil then
                
                local fuelLists = resourceBlockLists.fuelLists

                if not fuelLists then
                    fuelLists = {}
                    resourceBlockLists.fuelLists = fuelLists
                end
                local fuelList = fuelLists[fuelGroupIndexOrNil]
                if not fuelList then
                    fuelList = {}
                    fuelLists[fuelGroupIndexOrNil] = fuelList
                end
                
                local thisFuelGroupServerUpdateData = {}
                
                updateValue(fuelList, thisFuelGroupServerUpdateData)

                serverUpdateData.fuel = {
                    [fuelGroupIndexOrNil] = thisFuelGroupServerUpdateData
                }
            end

            logicInterface:callServerFunction("updateResourceBlockLists", serverUpdateData)
        end)

        
        local nameTextView = TextView.new(rowBackgroundView)

        local gameObjectView = uiGameObjectView:create(rowBackgroundView, vec2(30,30), uiGameObjectView.types.standard)
        gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        gameObjectView.baseOffset = vec3(30,0,2)
        if restrictionType == restrictionTypes.fuel then
            uiGameObjectView:setModelName(gameObjectView, "icon_fire", nil)
        elseif restrictionType == restrictionTypes.food then
            uiGameObjectView:setModelName(gameObjectView, "icon_food", nil)
        elseif restrictionType == restrictionTypes.tool then
            uiGameObjectView:setModelName(gameObjectView, "icon_hammer", nil)
        elseif restrictionType == restrictionTypes.medicine then
            uiGameObjectView:setModelName(gameObjectView, "icon_injury", nil)
        elseif restrictionType == restrictionTypes.clothing then
            uiGameObjectView:setModelName(gameObjectView, "icon_snow", nil)
        else
            local objectTypeWhiteList = nil
            if objectRowInfo.objectTypeIndex then
                objectTypeWhiteList = {[objectRowInfo.objectTypeIndex] = true}
            end

            local objectTypeIndexToUse = constructable:getDisplayGameObjectType(constructableTypeIndexOrNil, nil, objectTypeWhiteList)

            uiGameObjectView:setObject(gameObjectView, {
                objectTypeIndex = objectTypeIndexToUse
            }, nil, objectTypeWhiteList)
        end
            
        gameObjectView.masksEvents = false
    
        nameTextView.color = mj.textColor
        nameTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        nameTextView.baseOffset = vec3(60,0,0)
            
        nameTextView.font = Font(uiCommon.fontName, 16)

        nameTextView.text = titleString

        
        if not discovered then
            uiGameObjectView:setDisabled(gameObjectView, true)
            nameTextView.color = vec4(1.0,1.0,1.0,0.5)
        else
            nameTextView.color = mj.textColor
        end

    end

    if resourceType.foodValue then
        local titleString = locale:get("ui_resources_eating")
        addRow(titleString, restrictionTypes.food, nil, nil, true)
    end
    
    if resourceType.clothingInventoryLocation then
        local titleString = locale:get("ui_resources_clothing")
        addRow(titleString, restrictionTypes.clothing, nil, nil, true)
    end

    local fuelGroups = fuel.fuelGroupsByFuelResourceTypes[resourceType.index]
    if fuelGroups then
        for i,fuelGroup in ipairs(fuelGroups) do
            local titleString = fuelGroup.name
            addRow(titleString, restrictionTypes.fuel, nil, fuelGroup.index, true)
        end
    end
    
    if resourceType.isTool then
        local titleString = locale:get("ui_resources_tool")
        addRow(titleString, restrictionTypes.tool, nil, nil, true)
    end
    
    if medicine.medicinesByResourceType[resourceType.index] then
        local titleString = locale:get("ui_resources_medicine")
        addRow(titleString, restrictionTypes.medicine, nil, nil, true)
    end
    
    --[[if resourceType.compostValue then
        local titleString = locale:get("ui_resources_composting")
        addRow(titleString, restrictionTypes.composting, nil, nil, true)
    end

    if resource:groupOrResourceMatchesResource(resource.groups.fertilizer.index, resourceType.index) then
        local titleString = locale:get("ui_resources_mulching")
        addRow(titleString, restrictionTypes.mulching, nil, nil, true)
    end]]
    

    for i_,constructableType in ipairs(orderedConstructables) do
        local titleString = constructableType.plural
        
        local hasSeenRequiredResources = constructableUIHelper:checkHasSeenRequiredResources(constructableType, nil)
        local hasSeenRequiredTools = constructableUIHelper:checkHasSeenRequiredTools(constructableType, nil)
        local discoveryComplete = constructableUIHelper:checkHasRequiredDiscoveries(constructableType)

        local newUnlocked = discoveryComplete and hasSeenRequiredResources and hasSeenRequiredTools

        if newUnlocked then
            if constructableType.classification == constructable.classifications.place.index then
                titleString = locale:get("ui_resources_decorations")
            elseif constructableType.classification == constructable.classifications.plant.index then
                titleString = locale:get("ui_action_plant") .. " " .. titleString
            --[[elseif constructableType.classification == constructable.classifications.build.index or constructableType.classification == constructable.classifications.path.index then
                titleString = locale:get("ui_action_build") .. " " .. titleString
            elseif constructableType.classification == constructable.classifications.craft.index then
                titleString = locale:get("ui_action_craft") .. " " .. titleString]]
            elseif constructableType.classification == constructable.classifications.fill.index then
                titleString = locale:get("constructable_classification_fill")
            elseif constructableType.classification == constructable.classifications.fertilize.index then
                titleString = locale:get("constructable_classification_fertilize")
            end
        else
            titleString = locale:get("misc_undiscovered")
        end

        addRow(titleString, restrictionTypes.constructable, constructableType.index, nil, newUnlocked)
    end


end

local function updateInfoForSelectedObjectType()
    if resourceSelectedRowIndex and objectSelectedRowIndex then
        rightPaneView.hidden = false
        local objectRowInfo = objectTypeListItems[objectSelectedRowIndex]
        if objectRowInfo.objectTypeIndex then
            
            uiGameObjectView:setObject(selectedObjectImageView, {objectTypeIndex = objectRowInfo.objectTypeIndex}, nil, world:getSeenResourceObjectTypes())
            if objectRowInfo.hasSeen then
                selectedTitleTextView.text = gameObject.types[objectRowInfo.objectTypeIndex].plural
            else
                selectedTitleTextView.text = locale:get("misc_undiscovered")
            end
            selectedSummaryTextView.text = locale:get("ui_resources_storedCount", {storedCount = objectRowInfo.storedCount})
        else
            local resourceRowInfo = resourceListItems[resourceSelectedRowIndex]
            local resourceType = resourceRowInfo.resourceType

            uiGameObjectView:setObject(selectedObjectImageView, {objectTypeIndex = resourceType.displayGameObjectTypeIndex}, nil, world:getSeenResourceObjectTypes())
            
            selectedTitleTextView.text = locale:get("ui_resources_allResourceType", {resourceName = resourceType.plural})
            selectedSummaryTextView.text = locale:get("ui_resources_storedCount", {storedCount = objectRowInfo.storedCount})
        end
        updateUseList(objectRowInfo)

        if objectRowInfo.storedCount > 0 then
            uiStandardButton:setDisabled(zoomButton, false)
        else
            uiStandardButton:setDisabled(zoomButton, true)
        end
    else
        rightPaneView.hidden = true
    end
end


local function updateObjectSelectedIndex(thisIndex, wasClick)
    --if objectSelectedRowIndex ~= thisIndex then
        objectSelectedRowIndex = thisIndex
        if objectSelectedRowIndex == 0 then
            objectSelectedRowIndex = nil
        end
        if objectSelectedRowIndex then
            uiSelectionLayout:setSelection(objectTypesListView, objectTypeListItems[objectSelectedRowIndex].backgroundView)
        end
        updateInfoForSelectedObjectType()
       -- return true
  --  end
    --[[if not wasClick then
        uiSelectionLayout:setActiveSelectionLayoutView(objectTypesListView)
    end]]
  --  return false
end

local function updateInfoForSelectedResource()
    
    uiScrollView:removeAllRows(objectTypesListView)
    uiSelectionLayout:removeAllViews(objectTypesListView)
    objectTypeListItems = {}

    if resourceSelectedRowIndex then

        local resourceRowInfo = resourceListItems[resourceSelectedRowIndex]
        local resourceType = resourceRowInfo.resourceType
        local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]

        local seenResourceObjectTypes = world:getSeenResourceObjectTypes()
        
        local function sortGameObjects(a,b)
            local aFound = seenResourceObjectTypes[a]
            local bFound = seenResourceObjectTypes[b]
            if aFound ~= bFound then
                if aFound then
                    return true
                else
                    return false
                end
            end
            return gameObject.types[a].plural < gameObject.types[b].plural
        end

        local orderedGameObjectTypeIndexes = {}

        for i, gameObjectTypeIndex in ipairs(gameObjectTypes) do
            table.insert(orderedGameObjectTypeIndexes, gameObjectTypeIndex)
        end

        table.sort(orderedGameObjectTypeIndexes, sortGameObjects)

        backgroundColorCounter = 1

        local allRowBackgroundView = createRowBackground(objectTypesListView)
        local allGameObjectView = uiGameObjectView:create(allRowBackgroundView, listViewItemObjectImageViewSize, uiGameObjectView.types.standard)

        allGameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        --gameObjectView.baseOffset = vec3(0,-10, 2)
        local allObjectTitleTextView = TextView.new(allRowBackgroundView)
        allObjectTitleTextView.font = Font(uiCommon.fontName, 16)
        allObjectTitleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        allObjectTitleTextView.relativeView = allGameObjectView

        if resourceRowInfo.hasMultipleTypes then
            local allTypesString = string.format("%s (%d)", locale:get("ui_resources_allResourceType", {resourceName = resourceType.plural}), resourceRowInfo.storedCount)
            allObjectTitleTextView.text = allTypesString
            uiGameObjectView:setModelName(allGameObjectView, "icon_store", nil)
        else
            local textString = string.format("%s (%d)", resourceType.plural, resourceRowInfo.storedCount)
            allObjectTitleTextView.text = textString
            uiGameObjectView:setObject(allGameObjectView, {
                objectTypeIndex = resourceType.displayGameObjectTypeIndex
            }, nil, nil)
        end

        uiMenuItem:makeMenuItemBackground(allRowBackgroundView, objectTypesListView, 1, hoverColor, mouseDownColor, function(wasClick)
            updateObjectSelectedIndex(1, wasClick)
        end)
        objectTypeListItems[1] = {
            backgroundView = allRowBackgroundView,
            storedCount = resourceRowInfo.storedCount,
            hasSeen = true,
        }
        
        if not resourceRowInfo.hasMultipleTypes then
            objectTypeListItems[1].objectTypeIndex = resourceType.displayGameObjectTypeIndex
        end

        if resourceRowInfo.hasMultipleTypes then
            for i,gameObjectTypeIndex in ipairs(orderedGameObjectTypeIndexes) do

                local rowBackgroundView = createRowBackground(objectTypesListView)
                
                local gameObjectView = uiGameObjectView:create(rowBackgroundView, listViewItemObjectImageViewSize, uiGameObjectView.types.standard)
                gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                --gameObjectView.baseOffset = vec3(0,-10, 2)
                uiGameObjectView:setObject(gameObjectView, {
                    objectTypeIndex = gameObjectTypeIndex
                }, nil, nil)

                local objectTitleTextView = TextView.new(rowBackgroundView)
                objectTitleTextView.font = Font(uiCommon.fontName, 16)
                objectTitleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
                objectTitleTextView.relativeView = gameObjectView
                
                local hasSeen = seenResourceObjectTypes[gameObjectTypeIndex]
                local textString = nil
                local thisCount = resourceData[gameObjectTypeIndex] and resourceData[gameObjectTypeIndex].count
                local storedCount = (thisCount or 0)
                if hasSeen then
                    textString = string.format("%s (%d)", gameObject.types[gameObjectTypeIndex].plural, storedCount)
                else
                    textString = locale:get("misc_undiscovered")
                end


                objectTitleTextView.text = textString
                
                objectTypeListItems[i + 1] = {
                    backgroundView = rowBackgroundView,
                    objectTypeIndex = gameObjectTypeIndex,
                    hasSeen = hasSeen,
                    storedCount = storedCount,
                }
                
                uiSelectionLayout:addView(objectTypesListView, rowBackgroundView)
                
                uiMenuItem:makeMenuItemBackground(rowBackgroundView, objectTypesListView, i + 1, hoverColor, mouseDownColor, function(wasClick)
                    updateObjectSelectedIndex(i + 1, wasClick)
                end)

            end
        end

        
        updateObjectSelectedIndex(1, false)
        
    end

end

local function updateResourceSelectedIndex(thisIndex, wasClick)
    if resourceSelectedRowIndex ~= thisIndex then
        resourceSelectedRowIndex = thisIndex
        if resourceSelectedRowIndex == 0 then
            resourceSelectedRowIndex = nil
        end
        if resourceSelectedRowIndex then
            uiSelectionLayout:setSelection(resourcesListView, resourceListItems[resourceSelectedRowIndex].backgroundView)
        end
        updateInfoForSelectedResource()
        return true
    end
    if not wasClick then
        uiSelectionLayout:setActiveSelectionLayoutView(resourcesListView)
    end
    return false
end

local function zoomToStorageArea()
    local objectRowInfo = objectTypeListItems[objectSelectedRowIndex]
    if not objectRowInfo then
        return
    end

    local bestStorageObjectID = nil
    local bestStorageInfo = nil
    local closestDistance2 = 1.0

    local playerPos = localPlayer:getNormalModePos()

    local function checkObjectType(objectTypeIndex)
        local thisObjectTypeInfo = resourceData[objectTypeIndex]
        if thisObjectTypeInfo then
            for storageObjectID,storageInfo in pairs(thisObjectTypeInfo.storageAreas) do
                local distance2 = length2(storageInfo.pos - playerPos)
                if distance2 < closestDistance2 then
                    bestStorageInfo = storageInfo
                    bestStorageObjectID = storageObjectID
                    closestDistance2 = distance2
                end
            end
        end
    end

    if objectRowInfo.objectTypeIndex then
        checkObjectType(objectRowInfo.objectTypeIndex)
    else
        local resourceRowInfo = resourceListItems[resourceSelectedRowIndex]
        local resourceType = resourceRowInfo.resourceType
        local resourceGameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
        for i,gameObjectTypeIndex in ipairs(resourceGameObjectTypes) do
            checkObjectType(gameObjectTypeIndex)
        end
    end

    if bestStorageObjectID then
        logicInterface:callLogicThreadFunction("retrieveObject", bestStorageObjectID, function(result)
            if result and result.found then
                gameUI:followObject(result, false, {dismissAnyUI = true, showInspectUI = true})
            else
                gameUI:teleportToLookAtPos(bestStorageInfo.pos)
            end
        end)
    end
end


local timerID = nil
local currentSearchText = nil
local textEntryListenerID = nil

local function startKeyboardCapture()

    --local resourceRowInfo = resourceListItems[resourceSelectedRowIndex]
    --uiSelectionLayout:setSelection(resourcesListView, resourceListItems[resourceSelectedRowIndex].backgroundView)

    local function selectAdjacent(increment)
        local newIndex = resourceSelectedRowIndex + increment

        if newIndex > 0 and newIndex <= #resourceListItems then
            updateResourceSelectedIndex(newIndex, true)
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
                manageUI:hide()
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
        return false 
    end

    local function textEntry(text)
        if currentSearchText then
            currentSearchText = currentSearchText .. string.lower(text)
        else
            currentSearchText = string.lower(text)
        end

        for i,resourceListItem in ipairs(resourceListItems) do
            local titleString = resourceListItem.resourceType.plural
            local disabled = false

            titleString = string.lower(titleString)

            if not disabled then
                local startIndex = string.find(titleString, currentSearchText)
                if startIndex == 1 then
                    --mj:log("found:", titleString, " currentSearchText:", currentSearchText)
                    --userData.selectedItemIndex = i
                    --uiSelectionLayout:setSelection(userData.listView, userData.backgroundViews[userData.selectedItemIndex])
                    updateResourceSelectedIndex(i, true)
                    break
                end
            end
        end


        timerID = timer:addCallbackTimer(1.0, function(callbackTimerID)
            if callbackTimerID == timerID then
                currentSearchText = nil
            end
        end)
    end
    
    textEntryListenerID = eventManager:setTextEntryListener(textEntry, keyChanged, true)
end

local function endKeyboardCapture()
    eventManager:removeTextEntryListener(textEntryListenerID)
    textEntryListenerID = nil
end

local function update()
    
    uiScrollView:removeAllRows(resourcesListView)
    uiSelectionLayout:removeAllViews(resourcesListView)
    resourceListItems = {}
    
    world:getResourceObjectCountsFromServer(function(resourceData_)
        resourceData = resourceData_
        --[[

        local thisObjectTypeInfo = resourceData[objectTypeIndex]
        if not thisObjectTypeInfo then
            thisObjectTypeInfo = {
                count = 0,
                storageAreas = {}
            }
            infosByObjectTypeIndex[objectTypeIndex] = thisObjectTypeInfo
        end

        thisObjectTypeInfo.count = thisObjectTypeInfo.count + resourceState.count
        thisObjectTypeInfo.storageAreas[objectID] = {
            count = resourceState.count,
            pos = resourceState.object.pos
        }
        ]]
        
        local seenResourceObjectTypes = world:getSeenResourceObjectTypes()
        local resourceListViewInfos = {}


        for i,resourceType in ipairs(resource.alphabeticallyOrderedTypes) do
            local gameObjectTypes = gameObject.gameObjectTypeIndexesByResourceTypeIndex[resourceType.index]
            local hasSeen = false
            local storedCount = 0
            for j, gameObjectTypeIndex in ipairs(gameObjectTypes) do
                if seenResourceObjectTypes[gameObjectTypeIndex] then
                    hasSeen = true
                end
                local thisCount = resourceData[gameObjectTypeIndex] and resourceData[gameObjectTypeIndex].count
                storedCount = storedCount + (thisCount or 0)
            end

            if hasSeen then
                table.insert(resourceListViewInfos, {
                    resourceType = resourceType,
                    storedCount = storedCount,
                    hasMultipleTypes = #gameObjectTypes > 1
                })
            end
        end

        backgroundColorCounter = 1
        for i,resourceInfo in ipairs(resourceListViewInfos) do

            local rowBackgroundView = createRowBackground(resourcesListView)
            
            local gameObjectView = uiGameObjectView:create(rowBackgroundView, listViewItemObjectImageViewSize, uiGameObjectView.types.standard)
            gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            --gameObjectView.baseOffset = vec3(0,-10, 2)
            uiGameObjectView:setObject(gameObjectView, {
                objectTypeIndex = resourceInfo.resourceType.displayGameObjectTypeIndex
            }, nil, nil)

            local objectTitleTextView = TextView.new(rowBackgroundView)
            objectTitleTextView.font = Font(uiCommon.fontName, 16)
            objectTitleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            objectTitleTextView.relativeView = gameObjectView
            
            
            local textString = string.format("%s (%d)", resourceInfo.resourceType.plural, resourceInfo.storedCount)

            objectTitleTextView.text = textString
            
            resourceListItems[i] = {
                backgroundView = rowBackgroundView,
                resourceType = resourceInfo.resourceType,
                storedCount = resourceInfo.storedCount,
                hasMultipleTypes = resourceInfo.hasMultipleTypes,
            }
            
            uiSelectionLayout:addView(resourcesListView, rowBackgroundView)
            
            uiMenuItem:makeMenuItemBackground(rowBackgroundView, resourcesListView, i, hoverColor, mouseDownColor, function(wasClick)
                updateResourceSelectedIndex(i, wasClick)
            end)

        end
        

        local infoWasUpdated = false
        if (not resourceSelectedRowIndex) or (resourceSelectedRowIndex > #resourceListItems) then
            if resourceSelectedRowIndex and #resourceListItems > 0 then
                infoWasUpdated = updateResourceSelectedIndex(#resourceListItems, false)
            else
                if #resourceListItems > 0 then
                    infoWasUpdated = updateResourceSelectedIndex(1, false)
                else
                    infoWasUpdated = updateResourceSelectedIndex(nil, false)
                end
            end
        end

        if not infoWasUpdated then
            if resourceSelectedRowIndex then
                --mj:log("setting selection:", resourceSelectedRowIndex)
                uiSelectionLayout:setActiveSelectionLayoutView(resourcesListView)
                uiSelectionLayout:setSelection(resourcesListView, resourceListItems[resourceSelectedRowIndex].backgroundView)
            end
        end
        
    end)
end

function resourcesUI:init(gameUI_, world_, manageUI_, hubUI, contentView)
    manageUI = manageUI_
    world = world_
    gameUI = gameUI_

    local leftPaneWidth = contentView.size.x * 0.3

    local leftPaneViewSize = vec2(leftPaneWidth - 30, contentView.size.y - 40)
    local rightPaneViewSize = vec2(contentView.size.x - leftPaneWidth - 30, contentView.size.y - 40)

    local leftPaneView = View.new(contentView)
    leftPaneView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    leftPaneView.baseOffset = vec3(20,0.0, 0)
    leftPaneView.size = leftPaneViewSize
    
    rightPaneView = View.new(contentView)
    rightPaneView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    rightPaneView.baseOffset = vec3(-20,0.0, 0)
    rightPaneView.size = rightPaneViewSize
    rightPaneView.hidden = true
    
    local resourcesInsetViewSize = vec2(leftPaneView.size.x, leftPaneView.size.y * 0.67 - 10)
    local resourcesScrollViewSize = vec2(resourcesInsetViewSize.x - 10, resourcesInsetViewSize.y - 10)
    local resourcesInsetView = ModelView.new(leftPaneView)
    resourcesInsetView:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
    local scaleToUsePaneX = resourcesInsetViewSize.x * 0.5 / (2.0/3.0)
    local scaleToUsePaneY = resourcesInsetViewSize.y * 0.5
    resourcesInsetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    resourcesInsetView.size = resourcesInsetViewSize
    resourcesInsetView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    --insetView.baseOffset = vec3(0,-contentsTitleTextView.size.y + startYOffset - 10, 0)

    resourcesListView = uiScrollView:create(resourcesInsetView, resourcesScrollViewSize, MJPositionInnerLeft)
    resourcesListView.baseOffset = vec3(0, 0, 2)
    
    
    local objectTypesInsetViewSize = vec2(leftPaneView.size.x, leftPaneView.size.y * 0.33 - 10)
    local objectTypesScrollViewSize = vec2(objectTypesInsetViewSize.x - 10, objectTypesInsetViewSize.y - 10)
    local objectTypesInsetView = ModelView.new(leftPaneView)
    objectTypesInsetView:setModel(model:modelIndexForName("ui_inset_sm_4x3"))
    local objectTypesScaleToUsePaneX = objectTypesInsetViewSize.x * 0.5
    local objectTypesScaleToUsePaneY = objectTypesInsetViewSize.y * 0.5 / 0.75
    objectTypesInsetView.scale3D = vec3(objectTypesScaleToUsePaneX,objectTypesScaleToUsePaneY,objectTypesScaleToUsePaneX)
    objectTypesInsetView.size = objectTypesInsetViewSize
    objectTypesInsetView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    objectTypesInsetView.relativeView = resourcesInsetView
    objectTypesInsetView.baseOffset = vec3(0, -20, 0)
    --insetView.baseOffset = vec3(0,-contentsTitleTextView.size.y + startYOffset - 10, 0)

    objectTypesListView = uiScrollView:create(objectTypesInsetView, objectTypesScrollViewSize, MJPositionInnerLeft)
    objectTypesListView.baseOffset = vec3(0, 0, 2)

    selectedObjectImageView = uiGameObjectView:create(rightPaneView, vec2(180,180), uiGameObjectView.types.standard)
    selectedObjectImageView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    selectedObjectImageView.baseOffset = vec3(0,10, 0)

    selectedTitleTextView = TextView.new(rightPaneView)
    selectedTitleTextView.font = Font(uiCommon.fontName, 24)
    selectedTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedTitleTextView.relativeView = selectedObjectImageView
    selectedTitleTextView.baseOffset = vec3(0,10, 0)
    selectedTitleTextView.color = mj.textColor

    selectedSummaryTextView = TextView.new(rightPaneView)
    selectedSummaryTextView.font = Font(uiCommon.fontName, 18)
    selectedSummaryTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedSummaryTextView.relativeView = selectedTitleTextView
    selectedSummaryTextView.baseOffset = vec3(0,-5, 0)
    selectedSummaryTextView.wrapWidth = rightPaneView.size.x - 40
    selectedSummaryTextView.color = mj.textColor


    local zoomButtonSize = 22
    zoomButton = uiStandardButton:create(rightPaneView, vec2(zoomButtonSize,zoomButtonSize), uiStandardButton.types.slim_1x1)
    zoomButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    zoomButton.baseOffset = vec3(10, 0, 2)
    zoomButton.relativeView = selectedSummaryTextView
    uiStandardButton:setIconModel(zoomButton, "icon_inspect")
    uiStandardButton:setClickFunction(zoomButton, function()
        zoomToStorageArea()
    end)
    uiToolTip:add(zoomButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_zoom"), nil, vec3(0,-8,10), nil, zoomButton, rightPaneView)

    local restrictResourcesView = View.new(rightPaneView)
    --requiredResourcesView.color = vec4(0.1,0.1,0.1,0.1)
    restrictResourcesView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    restrictResourcesView.baseOffset = vec3(0,20, 0)
    restrictResourcesView.size = vec2(rightPaneViewSize.x, 320.0)

    local restrictResourcesTextView = TextView.new(restrictResourcesView)
    restrictResourcesTextView.font = Font(uiCommon.fontName, 16)
    restrictResourcesTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    restrictResourcesTextView.baseOffset = vec3(0,-10, 0)
    restrictResourcesTextView.text = locale:get("resources_ui_allowUse") .. ":"
    restrictResourcesTextView.color = mj.textColor

    
    local restrictResourcesInsetViewSize = vec2(restrictResourcesView.size.x * 0.75, restrictResourcesView.size.y - restrictResourcesTextView.size.y - 20)
    local restrictResourcesScrollViewSize = vec2(restrictResourcesInsetViewSize.x - 10, restrictResourcesInsetViewSize.y - 10)
    local restrictResourcesInsetView = ModelView.new(restrictResourcesView)
    restrictResourcesInsetView:setModel(model:modelIndexForName("ui_inset_sm_4x3"))
    local restrictScaleToUsePaneX = restrictResourcesInsetViewSize.x * 0.5
    local restrictScaleToUsePaneY = restrictResourcesInsetViewSize.y * 0.5 / 0.75
    restrictResourcesInsetView.scale3D = vec3(restrictScaleToUsePaneX,restrictScaleToUsePaneY,restrictScaleToUsePaneX)
    restrictResourcesInsetView.size = restrictResourcesInsetViewSize
    restrictResourcesInsetView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    restrictResourcesInsetView.baseOffset = vec3(0, 0, 0)

    restrictResourcesScrollView = uiScrollView:create(restrictResourcesInsetView, restrictResourcesScrollViewSize, MJPositionInnerLeft)
    restrictResourcesScrollView.baseOffset = vec3(0, 0, 2)
    
    uiSelectionLayout:createForView(restrictResourcesScrollView)

end

function resourcesUI:update()
    update()
end

function resourcesUI:show()
    --[[if resourceSelectedRowIndex then
        uiSelectionLayout:setActiveSelectionLayoutView(resourcesListView)
        uiSelectionLayout:setSelection(resourcesListView, resourceListItems[resourceSelectedRowIndex].backgroundView) --crashes
    end]]
    startKeyboardCapture()
end

function resourcesUI:hide()
    endKeyboardCapture()
end

function resourcesUI:popUI()
    return false
end

function resourcesUI:setLocalPlayer(localPlayer_)
    localPlayer = localPlayer_
end

return resourcesUI