local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local locale = mjrequire "common/locale"

local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local eventManager = mjrequire "mainThread/eventManager"


local tribeUI = mjrequire "mainThread/ui/manageUI/tribeUI"
local roleUI = mjrequire "mainThread/ui/manageUI/roleUI"
local tribeStatsUI = mjrequire "mainThread/ui/manageUI/tribeStatsUI"
local tribeNotificationsUI = mjrequire "mainThread/ui/manageUI/tribeNotificationsUI"
local resourcesUI = mjrequire "mainThread/ui/manageUI/resourcesUI"

local tribeCollection = {}

local tabSize = uiStandardButton.standardTabSize
local tabPadding = uiStandardButton.standardTabPadding

local currentModeIndex = nil

local modeTypes = mj:enum {
    "tribe",
    "role",
    "resources",
    "stats",
    "notifications",
}

local tabCount = #modeTypes

tribeCollection.modeTypes = modeTypes

local modeInfos = {
    [modeTypes.tribe] = {
        title = locale:get("tribe_ui_tribe"),
        icon = "icon_tribe2",
    },
    [modeTypes.role] = {
        title = locale:get("tribe_ui_roles"),
        icon = "icon_tasks",
    },
    [modeTypes.resources] = {
        title = locale:get("tribe_ui_resources"),
        icon = "icon_store",
    },
    [modeTypes.stats] = {
        title = locale:get("tribe_ui_stats"),
        icon = "icon_tribe2",
    },
    [modeTypes.notifications] = {
        title = locale:get("tribe_ui_notifications"),
        icon = "icon_warning",
    },
}

local uiObjectsByModeType = {
    [modeTypes.tribe] = tribeUI,
    [modeTypes.role] = roleUI,
    [modeTypes.resources] = resourcesUI,
    [modeTypes.stats] = tribeStatsUI,
    [modeTypes.notifications] = tribeNotificationsUI,
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
        switchTabs(modeTypes.tribe)
        return true
    end
    return false
end

function tribeCollection:tabSelectionShortcut(selectionIndex)
    if selectionIndex and uiObjectsByModeType[selectionIndex] then
        switchTabs(selectionIndex)
    end
end

function tribeCollection:show(contextOrNil)
    if not setupDefaultViewIfNeeded() then
        uiObjectsByModeType[currentModeIndex]:update()
    end
    uiObjectsByModeType[currentModeIndex]:show(contextOrNil)
end

function tribeCollection:popUI()
    if currentModeIndex then
        return uiObjectsByModeType[currentModeIndex]:popUI()
    end
    return false
end

function tribeCollection:hide()
    if currentModeIndex then
        uiObjectsByModeType[currentModeIndex]:hide()
    end
end

function tribeCollection:update()
    setupDefaultViewIfNeeded()
    uiObjectsByModeType[currentModeIndex]:update()
end


function tribeCollection:uiIsHidden(uiObject)
    if currentModeIndex == nil then
        return true
    end

    local currentUIObject = uiObjectsByModeType[currentModeIndex]
    return currentUIObject ~= uiObject
end

function tribeCollection:init(gameUI, world_, manageUI, hubUI_, contentView, logicInterface)
    
    local tribeContentView = View.new(contentView)
    tribeContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    tribeContentView.size = vec2(contentView.size.x, contentView.size.y)
    tribeContentView.hidden = true
    tribeUI:init(gameUI, world_, manageUI, hubUI_, tribeContentView)
    modeInfos[modeTypes.tribe].contentView = tribeContentView
    
    local roleContentView = View.new(contentView)
    roleContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    roleContentView.size = vec2(contentView.size.x, contentView.size.y)
    roleContentView.hidden = true
    roleUI:init(gameUI, world_, manageUI, hubUI_, roleContentView)
    modeInfos[modeTypes.role].contentView = roleContentView
    
    local resourcesContentView = View.new(contentView)
    resourcesContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    resourcesContentView.size = vec2(contentView.size.x, contentView.size.y)
    resourcesContentView.hidden = true
    resourcesUI:init(gameUI, world_, manageUI, hubUI_, resourcesContentView)
    modeInfos[modeTypes.resources].contentView = resourcesContentView
    
    local statsContentView = View.new(contentView)
    statsContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    statsContentView.size = vec2(contentView.size.x, contentView.size.y)
    statsContentView.hidden = true
    tribeStatsUI:init(gameUI, world_, manageUI, hubUI_, statsContentView)
    modeInfos[modeTypes.stats].contentView = statsContentView
    
    local notificationsContentView = View.new(contentView)
    notificationsContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    notificationsContentView.size = vec2(contentView.size.x, contentView.size.y)
    notificationsContentView.hidden = true
    tribeNotificationsUI:init(gameUI, world_, manageUI, hubUI_, notificationsContentView, logicInterface)
    modeInfos[modeTypes.notifications].contentView = notificationsContentView


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
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuRightBumper", function(isDown)
        if isDown and (not manageUI:uiIsHidden(tribeCollection)) then
            if currentModeIndex and currentModeIndex < tabCount then
                switchTabs(currentModeIndex + 1)
                return true
            end
        end
        return false
    end)
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuLeftBumper", function(isDown)
        if isDown and (not manageUI:uiIsHidden(tribeCollection)) then
            if currentModeIndex and currentModeIndex > 1 then
                switchTabs(currentModeIndex - 1)
                return true
            end
        end
        return false
    end)

end

return tribeCollection