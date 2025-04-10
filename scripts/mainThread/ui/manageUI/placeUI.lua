local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local constructable = mjrequire "common/constructable"
local gameObject = mjrequire "common/gameObject"
--local skill = mjrequire "common/skill"
local model = mjrequire "common/model"
--local material = mjrequire "common/material"
local locale = mjrequire "common/locale"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local keyMapping = mjrequire "mainThread/keyMapping"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local buildModeInteractUI = mjrequire "mainThread/ui/buildModeInteractUI"
local constructableUIHelper = mjrequire "mainThread/ui/constructableUIHelper"
--local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local uiObjectGrid = mjrequire "mainThread/ui/uiCommon/uiObjectGrid"
local eventManager = mjrequire "mainThread/eventManager"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiKeyImage = mjrequire "mainThread/ui/uiCommon/uiKeyImage"

local placeUI = {}

placeUI.itemList = {}
local manageUI = nil
local world = nil


local leftPaneView = nil
local objectGridView = nil
--local selectedGridButton = nil

local rightPaneView = nil
local selectedTitleTextView = nil
local selectedSummaryTextView = nil


local requiredResourcesView = nil
local requiredResourcesScrollView = nil
local useOnlyScrollView = nil
local requiredResourcesScrollViewHasFocus = false


local confirmButton = nil
local confirmFunction = nil
local selectedObjectImageView = nil

local prevSelectionGridIndex = nil

local useOnlyTitleTextView = nil
local requiredResourcesTitleTextView = nil

local useOnlyHasFocus = false
local mainViewHasFocus = false


local keyMap = {
    [keyMapping:getMappingIndex("game", "confirm")] = function(isDown, isRepeat) 
        if isDown and not isRepeat then 
            if confirmFunction then
                confirmFunction()
            end
        end 
        return true 
    end,
}

local function keyChanged(isDown, code, modKey, isRepeat)
    if keyMap[code]  then
		return keyMap[code](isDown, isRepeat)
	end
end

local function setMainViewHasFocus(newMainViewHasFocus)
    if mainViewHasFocus ~= newMainViewHasFocus then
        mainViewHasFocus = newMainViewHasFocus
        if mainViewHasFocus then
            uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_place"), "game", "confirm", eventManager.controllerSetIndexMenu, "menuSelect")
        else
            uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_place"), "game", "confirm", eventManager.controllerSetIndexMenu, "menuCancel")
        end
    end
end


local function updateMainViewFocus()
    local newMainViewHasFocus = (not requiredResourcesScrollViewHasFocus)
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

local function selectButton(buttonInfo)

    if buttonInfo.gridButtonData then
        local constructableTypeIndex = buttonInfo.gridButtonData.constructableTypeIndex
        local constructableType = constructable.types[constructableTypeIndex]
        
        --uiStandardButton:setTextWithShortcut(confirmButton, locale:get("ui_action_place"), "game", "confirm", eventManager.controllerSetIndexMenu, "menuSpecial")
        selectedTitleTextView.text = constructableType.name
        selectedSummaryTextView.text = constructableType.summary or locale:get("misc_no_summary_available")

        
        confirmFunction = function()
            buildModeInteractUI:show(constructableTypeIndex, false, false)
            manageUI:hide()
        end
        uiStandardButton:setClickFunction(confirmButton, confirmFunction)

        uiStandardButton:setDisabled(confirmButton, false)

        local function allObjectsForAnyResourceUncheckedChanged(hasAllObjectsForAnyResourceUnchecked)
            uiStandardButton:setDisabled(confirmButton, hasAllObjectsForAnyResourceUnchecked)
        end
        
        local restrictedObjectsChangedFunction = function()
            local restrictedObjectTypes = world:getConstructableRestrictedObjectTypes(constructableTypeIndex, false)
            local seenResourceObjectTypes = world:getSeenResourceObjectTypes()
            local objectTypeIndexToUse = constructable:getDisplayGameObjectType(constructableTypeIndex, restrictedObjectTypes, seenResourceObjectTypes)
            uiGameObjectView:setObject(selectedObjectImageView, {objectTypeIndex = objectTypeIndexToUse}, restrictedObjectTypes, world:getSeenResourceObjectTypes())
        end

        constructableUIHelper:updateRequiredResources(requiredResourcesScrollView, useOnlyScrollView, constructableType, allObjectsForAnyResourceUncheckedChanged, restrictedObjectsChangedFunction)
        restrictedObjectsChangedFunction()

        prevSelectionGridIndex = uiObjectGrid:getSelectedButtonGridIndex(objectGridView)
    end
    
end

function placeUI:show()
    uiObjectGrid:assignLayoutSelection(objectGridView)
    
    local selectedInfo = uiObjectGrid:getSelectedInfo(objectGridView)
    if selectedInfo then
        rightPaneView.hidden = false
        selectButton(selectedInfo)
    else
        rightPaneView.hidden = true
    end
    
    setMainViewHasFocus(true)
end

function placeUI:hide()
    uiObjectGrid:removeLayoutSelection(objectGridView)
    uiSelectionLayout:removeActiveSelectionLayoutView(requiredResourcesScrollView)
    setResourcesScrollViewFocus(false)
end

function placeUI:popUI()
    if requiredResourcesScrollViewHasFocus then
        if not constructableUIHelper:popControllerFocus(requiredResourcesScrollView, useOnlyScrollView) then
            setResourcesScrollViewFocus(false)
            uiSelectionLayout:removeActiveSelectionLayoutView(requiredResourcesScrollView)
            uiObjectGrid:assignLayoutSelection(objectGridView)
        end
        return true
    end
    return false
end

function placeUI:update()
    local gridData = {}

    for i, constructableTypeIndex in ipairs(placeUI.itemList) do

        local constructableType = constructable.types[constructableTypeIndex]

        --mj:log(constructableType)

        local gameObjectTypeKey = constructableType.inProgressGameObjectTypeKey
        local gameObjectType = gameObject.types[gameObjectTypeKey]
        --mj:log(gameObjectType)

        local hasSeenRequiredResources = constructableUIHelper:checkHasSeenRequiredResourcesIncludingVariations(constructableType, nil)
        local newUnlocked =  hasSeenRequiredResources

        gridData[i] = {
            constructableTypeIndex = constructableTypeIndex,

            gameObjectTypeIndex = gameObjectType.index,
            name = constructableType.name,
            disabledToolTipText = constructableUIHelper:getDisabledToolTipText(true, hasSeenRequiredResources, true),
            enabled = newUnlocked,
        }
    end

    uiObjectGrid:updateButtons(objectGridView, gridData, prevSelectionGridIndex)
end

function placeUI:init(gameUI, world_, manageUI_, contentView)

    placeUI.itemList = constructable.orderedPlaceTypeIndexesForDisplayInPlaceUI

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
    --requiredResourcesView.color = vec4(0.1,0.1,0.1,0.1)
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
    
    local gridBackgroundViewSize = vec2(leftPaneView.size.x - 40, leftPaneView.size.y - 60)
    objectGridView = uiObjectGrid:create(leftPaneView, gridBackgroundViewSize, function(selectedButtonInfo)
        selectButton(selectedButtonInfo)
    end)
    objectGridView.baseOffset = vec3(10,30, 0)
    uiObjectGrid:setDisableControllerSelection(objectGridView, true) --this allows the "menuSelect" callback to be called below, otherwise it will just act like the player is clicking on the object grid, and the below function will not get called


    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuSelect", function(isDown)
        if isDown and (not manageUI:uiIsHidden(placeUI)) then
            if mainViewHasFocus and confirmFunction then
                confirmFunction()
                return true
            end
        end
        return false
    end)
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuOther", function(isDown)
        if isDown and not manageUI:uiIsHidden(placeUI) then
            setResourcesScrollViewFocus(true)
            uiSelectionLayout:setActiveSelectionLayoutView(requiredResourcesScrollView)
            return true
        end
    end)
end


return placeUI