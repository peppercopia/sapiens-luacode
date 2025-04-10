local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4

local constructable = mjrequire "common/constructable"
local gameObject = mjrequire "common/gameObject"
--local skill = mjrequire "common/skill"
local model = mjrequire "common/model"
--local resource = mjrequire "common/resource"
--local tool = mjrequire "common/tool"
--local material = mjrequire "common/material"
local locale = mjrequire "common/locale"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"

local eventManager = mjrequire "mainThread/eventManager"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local keyMapping = mjrequire "mainThread/keyMapping"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local buildModeInteractUI = mjrequire "mainThread/ui/buildModeInteractUI"
local constructableUIHelper = mjrequire "mainThread/ui/constructableUIHelper"
--local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local uiObjectGrid = mjrequire "mainThread/ui/uiCommon/uiObjectGrid"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiKeyImage = mjrequire "mainThread/ui/uiCommon/uiKeyImage"

local buildUI = {}

buildUI.itemList = {}

local manageUI = nil
local world = nil


local leftPaneView = nil
local objectGridView = nil
local variationGridView = nil

local rightPaneView = nil
local selectedTitleTextView = nil
local selectedSummaryTextView = nil

local variationsTitleTextView = nil

local requiredResourcesView = nil
local requiredResourcesScrollView = nil
local useOnlyScrollView = nil
local requiredResourcesScrollViewHasFocus = false

local useOnlyTitleTextView = nil
local requiredResourcesTitleTextView = nil

local useOnlyHasFocus = false
local variationsViewHasFocus = false
local mainViewHasFocus = false

local confirmButton = nil
local confirmFunction = nil
local selectedObjectImageView = nil
local prevSelectionGridIndex = nil

local variationsKeyImage = nil

local randomSlideshowIndex = 1
local randomSlideshowCounter = 0.0
local randomSlideshowDelay = 1.5

local currentSelectionHasVariations = false

--local selectedObjectIconOverrideView = nil

--local buttonInfos = {}

local keyMap = {
    [keyMapping:getMappingIndex("game", "confirm")] = function(isDown, isRepeat) 
        if isDown and not isRepeat then 
            if confirmFunction then
                confirmFunction()
            end
        end 
        return true 
    end,
    [keyMapping:getMappingIndex("game", "buildMenu2")] = function(isDown, isRepeat) 
        if isDown and not isRepeat then 
            manageUI:hide()
        end 
        return true 
    end,
}

local function keyChanged(isDown, code, modKey, isRepeat)
    if keyMap[code]  then
		return keyMap[code](isDown, isRepeat)
	end
end

function buildUI:createItemList()
    buildUI.itemList = {
        constructable.types.craftArea.index,
        constructable.types.storageArea.index,
        constructable.types.hayBed.index,
        constructable.types.campfire.index,
        constructable.types.torch.index,
        constructable.types.brickKiln.index,
        constructable.types.compostBin.index,
        constructable.types.splitLogSteps2x2.index,
        constructable.types.splitLogBench.index,
        constructable.types.splitLogShelf.index,
        constructable.types.splitLogToolRack.index,
        constructable.types.sled.index,
        constructable.types.canoe.index,

        constructable.types.thatchRoof.index,
        constructable.types.thatchWall.index,

        constructable.types.splitLogFloor.index,
        constructable.types.splitLogRoof.index,
        constructable.types.splitLogWall.index,
        
        constructable.types.mudBrickFloor2x2.index,
        constructable.types.mudBrickWall.index,
        constructable.types.mudBrickColumn.index,
        
        constructable.types.stoneBlockWall.index,
        constructable.types.stoneBlockColumn.index,

        constructable.types.brickWall.index,
        
        constructable.types.tileRoof.index,
        constructable.types.tileFloor2x2.index,
    }
end

local function setMainViewHasFocus(newMainViewHasFocus)
    if mainViewHasFocus ~= newMainViewHasFocus then
        mainViewHasFocus = newMainViewHasFocus
        if mainViewHasFocus then
            uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_build"), "game", "confirm", eventManager.controllerSetIndexMenu, "menuSelect")
        else
            uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_build"), "game", "confirm", eventManager.controllerSetIndexMenu, "menuCancel")
        end
    end
end


local function updateMainViewFocus()
    local newMainViewHasFocus = (not requiredResourcesScrollViewHasFocus) and (not variationsViewHasFocus)
    setMainViewHasFocus(newMainViewHasFocus)
end

local function setResourcesScrollViewFocus(newHasFocus)
    requiredResourcesScrollViewHasFocus = newHasFocus
    if requiredResourcesScrollViewHasFocus then
        if useOnlyHasFocus then
            requiredResourcesTitleTextView.color = mj.textColor
            useOnlyTitleTextView.color = mj.highlightColor
        else
            requiredResourcesTitleTextView.color = mj.highlightColor
            useOnlyTitleTextView.color = mj.textColor
        end
    else
        requiredResourcesTitleTextView.color = mj.textColor
        useOnlyTitleTextView.color = mj.textColor
    end
    updateMainViewFocus()
end

local function setUseOnlyHasFocus(newHasFocus)
    useOnlyHasFocus = newHasFocus
    setResourcesScrollViewFocus(requiredResourcesScrollViewHasFocus)
end

local function setVariationsViewFocus(newHasFocus)
    variationsViewHasFocus = newHasFocus
    if variationsViewHasFocus then
        variationsTitleTextView.color = mj.highlightColor
    else
        variationsTitleTextView.color = mj.textColor
    end
    updateMainViewFocus()
end


local function updateSelection()
    local baseConstructableTypeIndex = nil
    local constructableTypeIndex = nil
    local selectedInfo = uiObjectGrid:getSelectedInfo(objectGridView)
    if selectedInfo and selectedInfo.gridButtonData then
        if selectedInfo.gridButtonData then
            constructableTypeIndex = selectedInfo.gridButtonData.constructableTypeIndex
            baseConstructableTypeIndex = constructableTypeIndex
        end
    end


    if (not baseConstructableTypeIndex) and prevSelectionGridIndex then
        constructableTypeIndex = buildUI.itemList[prevSelectionGridIndex]
        baseConstructableTypeIndex = constructableTypeIndex
    end
    
    
    local variationInfo = uiObjectGrid:getSelectedInfo(variationGridView)
    if variationInfo and variationInfo.gridButtonData and variationInfo.gridButtonData.constructableTypeIndex then
        constructableTypeIndex = variationInfo.gridButtonData.constructableTypeIndex

        if baseConstructableTypeIndex then
            
            local settingKey = string.format("variation_%d", baseConstructableTypeIndex)
            local selectedIndex = uiObjectGrid:getSelectedButtonGridIndex(variationGridView)
            --mj:log("set settingKey:", settingKey, " selectedIndex:", selectedIndex)
            world:setClientWorldSetting(settingKey, selectedIndex)
        end
    end
    
    if not baseConstructableTypeIndex or not constructableTypeIndex then
        return
    end

    local useIndexedNaming = false
    if variationInfo and variationInfo.gridButtonData and variationInfo.gridButtonData.constructableTypeIndex then
        currentSelectionHasVariations = variationInfo.gridButtonData.hasVariations
        useIndexedNaming = variationInfo.gridButtonData.useIndexedNaming
    end

    --mj:log("variationInfo:", variationInfo)


    local constructableType = constructable.types[constructableTypeIndex]
    --uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_plant"), "game", "confirm", eventManager.controllerSetIndexMenu, "menuSelect")

    local isRandom = false
    selectedTitleTextView.text = constructableType.name
    if variationInfo and variationInfo.gridButtonData then
        if variationInfo.gridButtonData.randomVariation then
            isRandom = true
            selectedSummaryTextView.text = locale:get("misc_randomVariation") .. "\n" .. variationInfo.gridButtonData.summary
        else
            if useIndexedNaming then
                selectedSummaryTextView.text = variationInfo.gridButtonData.name .. "\n" .. variationInfo.gridButtonData.summary
            else
                selectedSummaryTextView.text = variationInfo.gridButtonData.summary
            end
        end
    else
        selectedSummaryTextView.text = ""
    end


    local function assignRandomSlideshow()
        local variations = constructable.variations[baseConstructableTypeIndex]
        if randomSlideshowIndex > #variations then
            randomSlideshowIndex = 1
        end
        local variationConstructableTypeIndex = variations[randomSlideshowIndex]
        local restrictedObjectTypes = world:getConstructableRestrictedObjectTypes(variationConstructableTypeIndex, false)
        local variationGameObjectTypeIndex = constructable:getDisplayGameObjectType(variationConstructableTypeIndex, nil, nil)--constructable.types[variationConstructableTypeIndex].inProgressGameObjectTypeKey
        --local variationGameObjectTypeIndex = gameObject.types[variationGameObjectTypeKey].index
        uiGameObjectView:setObject(selectedObjectImageView, {objectTypeIndex = variationGameObjectTypeIndex}, restrictedObjectTypes, world:getSeenResourceObjectTypes())
    end
    
    if isRandom then
        selectedObjectImageView.update = function(dt)
            randomSlideshowCounter = randomSlideshowCounter + dt
            if randomSlideshowCounter > randomSlideshowDelay then
                randomSlideshowCounter = 0.0
                randomSlideshowIndex = randomSlideshowIndex + 1
                
                assignRandomSlideshow()
            end
        end
    else
        selectedObjectImageView.update = nil
    end

    
    confirmFunction = function()
        buildModeInteractUI:show(constructableTypeIndex, isRandom, false)
        manageUI:hide()
    end
    uiStandardButton:setClickFunction(confirmButton, confirmFunction)

    uiStandardButton:setDisabled(confirmButton, false)

    local function updateGameObjectView()
        if isRandom then
            --mj:error("isRandom:", baseConstructableTypeIndex)
            assignRandomSlideshow()
        else
            local gameObjectTypeIndex = constructable:getDisplayGameObjectType(constructableTypeIndex, nil, nil)--constructableType.iconGameObjectType or constructableType.inProgressGameObjectTypeKey
            --local gameObjectTypeIndex = gameObject.types[gameObjectTypeKey].index
            local restrictedObjectTypes = world:getConstructableRestrictedObjectTypes(constructableTypeIndex, false)
            uiGameObjectView:setObject(selectedObjectImageView, {objectTypeIndex = gameObjectTypeIndex}, restrictedObjectTypes, world:getSeenResourceObjectTypes())
        end
    end

    local function allObjectsForAnyResourceUncheckedChanged(hasAllObjectsForAnyResourceUnchecked)
        uiStandardButton:setDisabled(confirmButton, hasAllObjectsForAnyResourceUnchecked)
    end
    
    local restrictedObjectsChangedFunction = function()
        updateGameObjectView()
    end

    constructableUIHelper:updateRequiredResources(requiredResourcesScrollView, useOnlyScrollView, constructableType, allObjectsForAnyResourceUncheckedChanged, restrictedObjectsChangedFunction)
    updateGameObjectView()

    if currentSelectionHasVariations then
        variationsKeyImage.hidden = false
    else
        variationsKeyImage.hidden = true
    end
    --updateMainViewFocus()
end


local function updateVariationGrid(baseConstructableTypeIndex)
    if not baseConstructableTypeIndex then
        return
    end

    local baseConstructableType = constructable.types[baseConstructableTypeIndex]

    --mj:log("updateVariationGrid:", baseConstructableTypeIndex)

    local variationGridData = {}
    local variationItemList = {baseConstructableTypeIndex}
    local variations = constructable.variations[baseConstructableTypeIndex]
    if variations then
        variationItemList = variations
    end

    if #variationItemList > 1 and baseConstructableType.variationsAllowRandom then
        table.insert(variationGridData, {
            constructableTypeIndex = baseConstructableTypeIndex,
            randomVariation = true,
            hasVariations = true,

            iconName = "icon_random",
            name = locale:get("misc_random"),
            summary = baseConstructableType.summary,
            disabledToolTipText = constructableUIHelper:getDisabledToolTipText(true, true, true),
            enabled = true,
        })
    end

    for i, constructableTypeIndex in ipairs(variationItemList) do

        local constructableType = constructable.types[constructableTypeIndex]

        local gameObjectTypeIndex = constructable:getDisplayGameObjectType(constructableTypeIndex, nil, nil)--constructableType.inProgressGameObjectTypeKey
        local gameObjectType = gameObject.types[gameObjectTypeIndex]

        local nameToUse = constructableType.name
        local hasVariations = false
        local useIndexedNaming = false
        if #variationItemList > 1 then
            if baseConstructableType.variationsAllowRandom then --todo variationsAllowRandom might not always be what we want here to prevent indexed naming
                nameToUse = constructableType.name .. string.format(" %d", i)
                useIndexedNaming = true
            end
            hasVariations = true
        end

        local hasSeenRequiredResources = constructableUIHelper:checkHasSeenRequiredResources(constructableType, nil)
        local hasSeenRequiredTools = constructableUIHelper:checkHasSeenRequiredTools(constructableType, nil)
        local discoveryComplete = constructableUIHelper:checkHasRequiredDiscoveries(constructableType)

        local newUnlocked = discoveryComplete and hasSeenRequiredResources and hasSeenRequiredTools

        table.insert(variationGridData, {
            constructableTypeIndex = constructableTypeIndex,
            hasVariations = hasVariations,
            useIndexedNaming = useIndexedNaming,
            gameObjectTypeIndex = gameObjectType.index,
            name = nameToUse,
            summary = constructableType.summary,
            disabledToolTipText = constructableUIHelper:getDisabledToolTipText(discoveryComplete, hasSeenRequiredResources, hasSeenRequiredTools),
            enabled = newUnlocked,
        })
    end

    local settingKey = string.format("variation_%d", baseConstructableTypeIndex)
    local selectionIndex = world:getClientWorldSetting(settingKey) or 1
    --mj:log("get Key:", settingKey, " selectionIndex:", selectionIndex)
    --uiObjectGrid:selectButtonAtIndex(variationGridView, selectionIndex)

    uiObjectGrid:updateButtons(variationGridView, variationGridData, selectionIndex)

    --local debugValue = uiObjectGrid:getSelectedButtonIndex(variationGridView)
    --mj:log("debugValue:", debugValue)
end




local function selectVariationGridButton(buttonInfo)
    updateSelection()
end

local function selectMainGridButton(buttonInfo)

    if buttonInfo.gridButtonData and (uiObjectGrid:getSelectedInfo(objectGridView) ~= nil) then
        local constructableTypeIndex = buttonInfo.gridButtonData.constructableTypeIndex
        
        prevSelectionGridIndex = uiObjectGrid:getSelectedButtonGridIndex(objectGridView)
        updateVariationGrid(constructableTypeIndex)
        updateSelection()
    end
end

--[[local function selectButton(buttonInfo)

    if buttonInfo.gridButtonData then
        local constructableTypeIndex = buttonInfo.gridButtonData.constructableTypeIndex
        local constructableType = constructable.types[constructableTypeIndex]
        
        --uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_build"), "game", "confirm", eventManager.controllerSetIndexMenu, "menuSpecial")
        selectedTitleTextView.text = constructableType.name
        selectedSummaryTextView.text = constructableType.summary or locale:get("misc_no_summary_available")

        local gameObjectTypeKey = constructableType.inProgressGameObjectTypeKey
        local gameObjectType = gameObject.types[gameObjectTypeKey]
        --uiGameObjectView:setObject(selectedObjectImageView, {objectTypeIndex = gameObjectType.index}, nil)

        
        confirmFunction = function()
            --mj:log("buildUI confirmFunction")
            buildModeInteractUI:show(constructableTypeIndex, false, false)
            manageUI:hide()
            world:setHasLoadedCraftOrStorageArea()
        end
        uiStandardButton:setClickFunction(confirmButton, confirmFunction)

        uiStandardButton:setDisabled(confirmButton, false)

        local function updateGameObjectView()
            local restrictedObjectTypes = world:getConstructableRestrictedObjectTypes(constructableTypeIndex, false)
            uiGameObjectView:setObject(selectedObjectImageView, {objectTypeIndex = gameObjectType.index}, restrictedObjectTypes, world:getSeenResourceObjectTypes())
        end

        local function allObjectsForAnyResourceUncheckedChanged(hasAllObjectsForAnyResourceUnchecked)
            uiStandardButton:setDisabled(confirmButton, hasAllObjectsForAnyResourceUnchecked)
        end
        
        local restrictedObjectsChangedFunction = function()
            updateGameObjectView()
        end

        constructableUIHelper:updateRequiredResources(requiredResourcesScrollView, useOnlyScrollView, constructableType, allObjectsForAnyResourceUncheckedChanged, restrictedObjectsChangedFunction)
        updateGameObjectView()

        prevSelectionGridIndex = uiObjectGrid:getSelectedButtonGridIndex(objectGridView)
    end
    
end]]



function buildUI:show()
    prevSelectionGridIndex = nil
    uiObjectGrid:assignLayoutSelection(objectGridView)
    
    local selectedInfo = uiObjectGrid:getSelectedInfo(objectGridView)
    if selectedInfo then
        rightPaneView.hidden = false
        variationsTitleTextView.hidden = false
        selectMainGridButton(selectedInfo)
    else
        rightPaneView.hidden = true
        variationsTitleTextView.hidden = true
    end
    setMainViewHasFocus(true)
end

function buildUI:hide()
    uiObjectGrid:removeLayoutSelection(objectGridView)
    uiObjectGrid:removeLayoutSelection(variationGridView)
    uiSelectionLayout:removeActiveSelectionLayoutView(requiredResourcesScrollView)
    setVariationsViewFocus(false)
    setResourcesScrollViewFocus(false)
end

--[[function buildUI:popUI()
    if requiredResourcesScrollViewHasFocus then
        if not constructableUIHelper:popControllerFocus(requiredResourcesScrollView, useOnlyScrollView) then
            setResourcesScrollViewFocus(false)
            uiSelectionLayout:removeActiveSelectionLayoutView(requiredResourcesScrollView)
            uiObjectGrid:assignLayoutSelection(objectGridView)
        end
        return true
    end
    return false
end]]

function buildUI:popUI()
    local function exitResourcesScrollViewFocus()
        if not constructableUIHelper:popControllerFocus(requiredResourcesScrollView, useOnlyScrollView) then
            setVariationsViewFocus(false)
            setResourcesScrollViewFocus(false)
            uiSelectionLayout:removeActiveSelectionLayoutView(requiredResourcesScrollView)
            uiObjectGrid:assignLayoutSelection(objectGridView)
        end
    end
    if requiredResourcesScrollViewHasFocus then
        exitResourcesScrollViewFocus()
        return true
    elseif variationsViewHasFocus then
        exitResourcesScrollViewFocus()
        return true
    end
    return false
end

function buildUI:update()
    local gridData = {}

    for i, constructableTypeIndex in ipairs(buildUI.itemList) do

        local constructableType = constructable.types[constructableTypeIndex]

        local gameObjectTypeKey = constructableType.inProgressGameObjectTypeKey
        local gameObjectType = gameObject.types[gameObjectTypeKey]

        local hasSeenRequiredResources = constructableUIHelper:checkHasSeenRequiredResources(constructableType, nil)
        local hasSeenRequiredTools = constructableUIHelper:checkHasSeenRequiredTools(constructableType, nil)
        local discoveryComplete = constructableUIHelper:checkHasRequiredDiscoveries(constructableType)

        local newUnlocked = discoveryComplete and hasSeenRequiredResources and hasSeenRequiredTools

        gridData[i] = {
            constructableTypeIndex = constructableTypeIndex,

            gameObjectTypeIndex = gameObjectType.index,
            name = constructableType.variationGroupName or constructableType.name,
            disabledToolTipText = constructableUIHelper:getDisabledToolTipText(discoveryComplete, hasSeenRequiredResources, hasSeenRequiredTools),
            enabled = newUnlocked,
        }
    end

    uiObjectGrid:updateButtons(objectGridView, gridData, prevSelectionGridIndex)
end

function buildUI:init(gameUI, world_, manageUI_, contentView)

    manageUI = manageUI_
    world = world_

    local paneViewSize = vec2(contentView.size.x * 0.5 - 20, contentView.size.y)

    leftPaneView = View.new(contentView)
    leftPaneView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    leftPaneView.baseOffset = vec3(20,0, 0)
    leftPaneView.size = paneViewSize
    
    leftPaneView.keyChanged = keyChanged --hmmm leftPaneView?
    
    rightPaneView = View.new(contentView)
    rightPaneView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    rightPaneView.baseOffset = vec3(-24,0, 0)
    rightPaneView.size = paneViewSize

    selectedObjectImageView = uiGameObjectView:create(rightPaneView, vec2(200,200), uiGameObjectView.types.standard)
    selectedObjectImageView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

    --selectedObjectImageView.baseOffset = vec3(0,-4, 0)

    selectedTitleTextView = TextView.new(rightPaneView)
    selectedTitleTextView.font = Font(uiCommon.fontName, 24)
    selectedTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedTitleTextView.relativeView = selectedObjectImageView
   -- selectedTitleTextView.baseOffset = vec3(0,0, 0)
    selectedTitleTextView.color = mj.textColor

    selectedSummaryTextView = TextView.new(rightPaneView)
    selectedSummaryTextView.font = Font(uiCommon.fontName, 16)
    selectedSummaryTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedSummaryTextView.relativeView = selectedTitleTextView
    selectedSummaryTextView.baseOffset = vec3(0,-5, 0)
    selectedSummaryTextView.wrapWidth = rightPaneView.size.x - 40
    selectedSummaryTextView.color = mj.textColor

    requiredResourcesView = View.new(rightPaneView)
    --requiredResourcesView.color = mjm.vec4(0.8,0.1,0.1,0.1)
    requiredResourcesView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    requiredResourcesView.baseOffset = vec3(0,70, 0)
    requiredResourcesView.size = vec2(paneViewSize.x, 200.0)

    requiredResourcesTitleTextView = TextView.new(requiredResourcesView)
    requiredResourcesTitleTextView.font = Font(uiCommon.fontName, 16)
    requiredResourcesTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    requiredResourcesTitleTextView.baseOffset = vec3(-requiredResourcesView.size.x * 0.25 - 5,-10, 0)
    requiredResourcesTitleTextView.text = locale:get("construct_ui_requires") .. ":"
    requiredResourcesTitleTextView.color = mj.textColor
    
    local requiredResourcesKeyImage = uiKeyImage:create(requiredResourcesView, 20, nil, nil, eventManager.controllerSetIndexMenu, "menuOther", nil)
    requiredResourcesKeyImage.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    requiredResourcesKeyImage.relativeView = requiredResourcesTitleTextView
    requiredResourcesKeyImage.baseOffset = vec3(4,0,0)

    useOnlyTitleTextView = TextView.new(requiredResourcesView)
    useOnlyTitleTextView.font = Font(uiCommon.fontName, 16)
    useOnlyTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    useOnlyTitleTextView.baseOffset = vec3(requiredResourcesView.size.x * 0.25 + 5,-10, 0)
    useOnlyTitleTextView.text = locale:get("construct_ui_acceptOnly") .. ":"
    useOnlyTitleTextView.color = mj.textColor

    
    local requiredResourcesInsetViewSize = vec2(requiredResourcesView.size.x * 0.5 - 10, requiredResourcesView.size.y - requiredResourcesTitleTextView.size.y - 20)
    local requiredResourcesScrollViewSize = vec2(requiredResourcesInsetViewSize.x - 10, requiredResourcesInsetViewSize.y - 10)
    local requiredResourcesInsetView = ModelView.new(requiredResourcesView)
    requiredResourcesInsetView:setModel(model:modelIndexForName("ui_inset_sm_4x3"))
    local restrictScaleToUsePaneX = requiredResourcesInsetViewSize.x * 0.5
    local restrictScaleToUsePaneY = requiredResourcesInsetViewSize.y * 0.5 / 0.75
    requiredResourcesInsetView.scale3D = vec3(restrictScaleToUsePaneX,restrictScaleToUsePaneY,restrictScaleToUsePaneX)
    requiredResourcesInsetView.size = requiredResourcesInsetViewSize
    requiredResourcesInsetView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    requiredResourcesInsetView.baseOffset = vec3(0, 0, 0)

    requiredResourcesScrollView = uiScrollView:create(requiredResourcesInsetView, requiredResourcesScrollViewSize, MJPositionInnerLeft)
    requiredResourcesScrollView.baseOffset = vec3(0, 0, 2)
    
    uiSelectionLayout:createForView(requiredResourcesScrollView)

    
    local useOnlyInsetView = ModelView.new(requiredResourcesView)
    useOnlyInsetView:setModel(model:modelIndexForName("ui_inset_sm_4x3"))
    useOnlyInsetView.scale3D = vec3(restrictScaleToUsePaneX,restrictScaleToUsePaneY,restrictScaleToUsePaneX)
    useOnlyInsetView.size = requiredResourcesInsetViewSize
    useOnlyInsetView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    useOnlyInsetView.baseOffset = vec3(0, 0, 0)

    useOnlyScrollView = uiScrollView:create(useOnlyInsetView, requiredResourcesScrollViewSize, MJPositionInnerLeft)
    useOnlyScrollView.baseOffset = vec3(0, 0, 2)

    uiSelectionLayout:createForView(useOnlyScrollView)
    uiSelectionLayout:setSelectionLayoutViewActiveChangedFunction(useOnlyScrollView, function(isSelected)
        setUseOnlyHasFocus(isSelected)
    end)


    confirmButton = uiStandardButton:create(rightPaneView, vec2(142,30))
    confirmButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    confirmButton.baseOffset = vec3(0,20, 0)

    buildUI:createItemList()
    
    local gridBackgroundViewSize = vec2(leftPaneView.size.x - 40, leftPaneView.size.y - 60 - 240)
    objectGridView = uiObjectGrid:create(leftPaneView, gridBackgroundViewSize, function(selectedButtonInfo)
        selectMainGridButton(selectedButtonInfo)
    end)
    objectGridView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    objectGridView.baseOffset = vec3(10,-30,0)
    uiObjectGrid:setDisableControllerSelection(objectGridView, true) --this allows the "menuSelect" callback to be called below, otherwise it will just act like the player is clicking on the object grid, and the below function will not get called

    local variationsContainerView = View.new(leftPaneView)
    --variationsContainerView.color = mjm.vec4(0.8,0.1,0.1,0.1)
    variationsContainerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    variationsContainerView.baseOffset = vec3(10,70, 0)
    variationsContainerView.size = vec2(paneViewSize.x - 10 - 30, 200.0)

    variationsTitleTextView = TextView.new(variationsContainerView)
    variationsTitleTextView.font = Font(uiCommon.fontName, 16)
    variationsTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    variationsTitleTextView.baseOffset = vec3(0,-10, 0)
    variationsTitleTextView.text = locale:get("misc_variations") .. ":"
    variationsTitleTextView.color = mj.textColor

    variationsKeyImage = uiKeyImage:create(variationsContainerView, 20, nil, nil, eventManager.controllerSetIndexMenu, "menuSpecial", nil)
    variationsKeyImage.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    variationsKeyImage.relativeView = variationsTitleTextView
    variationsKeyImage.baseOffset = vec3(4,0,0)
    variationsKeyImage.hidden = true

    variationGridView = uiObjectGrid:create(variationsContainerView, vec2(gridBackgroundViewSize.x, requiredResourcesInsetViewSize.y), function(selectedButtonInfo)
        selectVariationGridButton(selectedButtonInfo)
    end)
    variationGridView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
    variationGridView.baseOffset = vec3(0,0,0)
    uiObjectGrid:setDisableControllerSelection(variationGridView, true)

    

    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuSelect", function(isDown)
        if isDown and (not manageUI:uiIsHidden(buildUI)) then
            if variationsViewHasFocus then
                buildUI:popUI()
            --elseif requiredResourcesScrollViewHasFocus then

            elseif mainViewHasFocus and confirmFunction then
                confirmFunction()
                return true
            end
        end
        return false
    end)

    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuSpecial", function(isDown)
        if isDown and (not manageUI:uiIsHidden(buildUI)) then
            if currentSelectionHasVariations then
                setResourcesScrollViewFocus(false)
                setVariationsViewFocus(true)
                uiObjectGrid:assignLayoutSelection(variationGridView)
                return true
            end
        end
        return false
    end)
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuOther", function(isDown)
        if isDown and not manageUI:uiIsHidden(buildUI) then
            setVariationsViewFocus(false)
            setResourcesScrollViewFocus(true)
            uiSelectionLayout:setActiveSelectionLayoutView(requiredResourcesScrollView)
            return true
        end
        return false
    end)
    
   --[[ eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuSelect", function(isDown)
        if isDown and (not manageUI:uiIsHidden(buildUI)) then
            if mainViewHasFocus and confirmFunction then
                confirmFunction()
                return true
            end
        end
        return false
    end)
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuOther", function(isDown)
        if isDown and (not manageUI:uiIsHidden(buildUI)) then
            setResourcesScrollViewFocus(true)
            uiSelectionLayout:setActiveSelectionLayoutView(requiredResourcesScrollView)
            return true
        end
        return false
    end)]]
end




return buildUI