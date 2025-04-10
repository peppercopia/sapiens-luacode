local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local locale = mjrequire "common/locale"

local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local eventManager = mjrequire "mainThread/eventManager"


local buildUI = mjrequire "mainThread/ui/manageUI/buildUI"
local placeUI = mjrequire "mainThread/ui/manageUI/placeUI"
local plantUI = mjrequire "mainThread/ui/manageUI/plantUI"
local pathUI = mjrequire "mainThread/ui/manageUI/pathUI"

local buildCollection = {}

--local manageUI = nil
--local world = nil

local tabSize = uiStandardButton.standardTabSize
local tabPadding = uiStandardButton.standardTabPadding

local currentModeIndex = nil

local modeTypes = mj:enum {
    "build",
    "place",
    "plant",
    "path",
}

local tabCount = #modeTypes

buildCollection.modeTypes = modeTypes

local modeInfos = {
    [modeTypes.build] = {
        title = locale:get("build_ui_build"),
        icon = "icon_hammer",
    },
    [modeTypes.place] = {
        title = locale:get("build_ui_place"),
        icon = "icon_hand",
    },
    [modeTypes.plant] = {
        title = locale:get("build_ui_plant"),
        icon = "icon_plant",
    },
    [modeTypes.path] = {
        title = locale:get("build_ui_path"),
        icon = "icon_path",
    },
}

local uiObjectsByModeType = {
    [modeTypes.build] = buildUI,
    [modeTypes.place] = placeUI,
    [modeTypes.plant] = plantUI,
    [modeTypes.path] = pathUI,
}

local function updateCurrentView()
    uiObjectsByModeType[currentModeIndex]:update()
    uiObjectsByModeType[currentModeIndex]:show()
end

local function switchTabs(modeIndex)
    if currentModeIndex ~= modeIndex then
        if currentModeIndex then
            local currentInfo = modeInfos[currentModeIndex]
            currentInfo.contentView.hidden = true

            uiObjectsByModeType[currentModeIndex]:hide()

            uiStandardButton:setSelected(currentInfo.tabButton, false)
            local prevOffset = currentInfo.tabButton.baseOffset
            currentInfo.tabButton.baseOffset = vec3(prevOffset.x, prevOffset.y, uiCommon.unSelectedTabZOffset)

        end

        currentModeIndex = modeIndex

        local currentInfo = modeInfos[currentModeIndex]
        currentInfo.contentView.hidden = false
        
        uiStandardButton:setSelected(currentInfo.tabButton, true)
        local prevOffset = currentInfo.tabButton.baseOffset
        currentInfo.tabButton.baseOffset = vec3(prevOffset.x, prevOffset.y, uiCommon.selectedTabZOffset)
        
        updateCurrentView()

    end
end

local function setupDefaultViewIfNeeded()
    if currentModeIndex == nil then
        switchTabs(modeTypes.build)
        return true
    end
    return false
end

function buildCollection:tabSelectionShortcut(selectionIndex)
    if selectionIndex and uiObjectsByModeType[selectionIndex] then
        switchTabs(selectionIndex)
    end
end

function buildCollection:show(contextOrNil)
    if not setupDefaultViewIfNeeded() then
        uiObjectsByModeType[currentModeIndex]:update()
    end
    uiObjectsByModeType[currentModeIndex]:show(contextOrNil)
end

function buildCollection:popUI()
    if currentModeIndex then
        return uiObjectsByModeType[currentModeIndex]:popUI()
    end
    return false
end

function buildCollection:hide()
    if currentModeIndex then
        uiObjectsByModeType[currentModeIndex]:hide()
    end
end

function buildCollection:update()
    setupDefaultViewIfNeeded()
    uiObjectsByModeType[currentModeIndex]:update()
end

function buildCollection:uiIsHidden(uiObject)
    if currentModeIndex == nil then
        return true
    end

    local currentUIObject = uiObjectsByModeType[currentModeIndex]
    return currentUIObject ~= uiObject
end

function buildCollection:init(gameUI, world_, manageUI, contentView)
    
    local buildContentView = View.new(contentView)
    buildContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    buildContentView.size = vec2(contentView.size.x, contentView.size.y)
    buildContentView.hidden = true
    buildUI:init(gameUI, world_, manageUI, buildContentView)
    
    local placeContentView = View.new(contentView)
    placeContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    placeContentView.size = vec2(contentView.size.x, contentView.size.y)
    placeContentView.hidden = true
    placeUI:init(gameUI, world_, manageUI, placeContentView)

    local plantContentView = View.new(contentView)
    plantContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    plantContentView.size = vec2(contentView.size.x, contentView.size.y)
    plantContentView.hidden = true
    plantUI:init(gameUI, world_, manageUI, plantContentView)

    local pathContentView = View.new(contentView)
    pathContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    pathContentView.size = vec2(contentView.size.x, contentView.size.y)
    pathContentView.hidden = true
    pathUI:init(gameUI, world_, manageUI, pathContentView)


    local function addTabButton(buttonIndex, modeInfo)
        local tabButton = uiStandardButton:create(contentView, tabSize, uiStandardButton.types.tabTitle, nil)
        tabButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)

        local xOffset = (tabCount * -0.5 + (buttonIndex - 1) + 0.5) * (tabSize.x + tabPadding)
        local zOffset = uiCommon.unSelectedTabZOffset
        if buttonIndex == 1 then
            zOffset = uiCommon.selectedTabZOffset
            uiStandardButton:setSelected(tabButton, true)
        end

        tabButton.baseOffset = vec3(xOffset, 0, zOffset)
        uiStandardButton:setText(tabButton, modeInfo.title)
        uiStandardButton:setIconModel(tabButton, modeInfo.icon)
        
        uiStandardButton:setClickFunction(tabButton, function()
            switchTabs(buttonIndex)
        end)

        modeInfo.tabButton = tabButton
    end

    for i,v in ipairs(modeTypes) do
        addTabButton(i, modeInfos[i])
    end


    modeInfos[modeTypes.build].contentView = buildContentView
    modeInfos[modeTypes.place].contentView = placeContentView
    modeInfos[modeTypes.plant].contentView = plantContentView
    modeInfos[modeTypes.path].contentView = pathContentView

    
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuRightBumper", function(isDown)
        if isDown and (not manageUI:uiIsHidden(buildCollection)) then
            if currentModeIndex and currentModeIndex < tabCount then
                switchTabs(currentModeIndex + 1)
                return true
            end
        end
        return false
    end)
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuLeftBumper", function(isDown)
        if isDown and (not manageUI:uiIsHidden(buildCollection)) then
            if currentModeIndex and currentModeIndex > 1 then
                switchTabs(currentModeIndex - 1)
                return true
            end
        end
        return false
    end)

end

return buildCollection