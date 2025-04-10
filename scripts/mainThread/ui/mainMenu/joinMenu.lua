local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"
local steamServerBrowser = mjrequire "common/utility/steamServerBrowser"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"
local clientGameSettings = mjrequire "mainThread/clientGameSettings"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local uiPopUpButton = mjrequire "mainThread/ui/uiCommon/uiPopUpButton"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"

local joinMenu = {}

--local controller = nil

local previousConnectionsPopUpButton = nil
local joinConfirmButtonFunc = nil
local ipTextEntry = nil
local portTextEntry = nil

local leftPane = nil
local leftInsetView = nil
local serverListView = nil


local hoverColor = mj.highlightColor * 0.8
local mouseDownColor = mj.highlightColor * 0.6

local paddingCounter = 1
local listItemCounter = 1
local selectedConnectionTitleTextView = nil


local function addHeaders()
    local backgroundView = ColorView.new(serverListView)
    
    local defaultColor = vec4(0.0,0.0,0.0,0.2)
    
    backgroundView.color = defaultColor
    backgroundView.size = vec2(serverListView.size.x - 22, 30)
    backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    --backgroundView.baseOffset = vec3(0,(-paddingCounter + 1) * 30,0)

    uiScrollView:insertRow(serverListView, backgroundView, nil)
    
    local serverNameTextView = TextView.new(backgroundView)
    serverNameTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    serverNameTextView.baseOffset = vec3(10,0,0)
    serverNameTextView.color = vec4(1.0,1.0,1.0,1.0)
    serverNameTextView.font = Font(uiCommon.fontName, 16)
    serverNameTextView.text = locale:get("ui_name_serverName")

    local playerCountTextView = TextView.new(backgroundView)
    playerCountTextView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    playerCountTextView.baseOffset = vec3(-10,0,0)
    playerCountTextView.color = vec4(1.0,1.0,1.0,1.0)
    playerCountTextView.font = Font(uiCommon.fontName, 16)
    playerCountTextView.text = locale:get("ui_name_playersOnline")

    paddingCounter = paddingCounter + 1
    listItemCounter = listItemCounter + 1
end

local function clearList()
    if serverListView then
        leftInsetView:removeSubview(serverListView)
        serverListView = nil
    end

    paddingCounter = 1
    listItemCounter = 1
    
    local listViewSize = vec2(leftInsetView.size.x - 10.0, leftInsetView.size.y - 10.0)
    serverListView = uiScrollView:create(leftInsetView, listViewSize, MJPositionInnerLeft)
    serverListView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    addHeaders()
end

local function addServer(serverInfo)
    local backgroundView = ColorView.new(serverListView)
    
    local defaultColor = vec4(0.0,0.0,0.0,0.5)
    if listItemCounter % 2 == 1 then
        defaultColor = vec4(0.03,0.03,0.03,0.5)
    end
    
    backgroundView.color = defaultColor

    backgroundView.size = vec2(serverListView.size.x - 22, 30)
    backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    --backgroundView.baseOffset = vec3(0,(-paddingCounter + 1) * 30,0)

    uiScrollView:insertRow(serverListView, backgroundView, nil)
    
    local serverNameTextView = TextView.new(backgroundView)
    serverNameTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    serverNameTextView.baseOffset = vec3(10,0,0)
    serverNameTextView.color = vec4(1.0,1.0,1.0,1.0)
    serverNameTextView.font = Font(uiCommon.fontName, 16)
    local serverFullTitleText = (serverInfo.serverName or "New Server")
    serverNameTextView.text = serverFullTitleText


    local playerCountTextView = TextView.new(backgroundView)
    playerCountTextView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    playerCountTextView.baseOffset = vec3(-10,0,0)
    playerCountTextView.color = vec4(1.0,1.0,1.0,1.0)
    playerCountTextView.font = Font(uiCommon.fontName, 16)
    playerCountTextView.text = mj:tostring(serverInfo.playerCount or 0)

    --local itemIndex = listItemCounter
    uiMenuItem:makeMenuItemBackground(backgroundView, nil, listItemCounter, hoverColor, mouseDownColor, function(wasClick)
        --updateSelectedIndex(itemIndex)
        local ipText = serverInfo.ip
        clientGameSettings:changeSetting("joinWorldIP", ipText)
        uiTextEntry:setText(ipTextEntry, ipText)

        local portText = mj:tostring(serverInfo.port)
        clientGameSettings:changeSetting("joinWorldPort", portText)
        uiTextEntry:setText(portTextEntry, portText)

        clientGameSettings:changeSetting("joinWorldServerName", serverFullTitleText)

        selectedConnectionTitleTextView:setText(serverFullTitleText, material.types.standardText.index)

        uiPopUpButton:setSelection(previousConnectionsPopUpButton, nil)
    end)

    
    --[[tableViewItemInfos[listItemCounter] = {
        backgroundView = backgroundView,
        defaultColor = defaultColor,
        modInfo = modInfo,
    }]]

    paddingCounter = paddingCounter + 1
    listItemCounter = listItemCounter + 1
end

function joinMenu:init(mainMenu)
    
    local backgroundSize = subMenuCommon.size
    
    local mainView = ModelView.new(mainMenu.mainView)
    joinMenu.mainView = mainView
    
    local sizeToUse = backgroundSize
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    
    mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.size = backgroundSize
    mainView.hidden = true
    
    local titleTextView = ModelTextView.new(mainView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,0, 0)
    titleTextView:setText(locale:get("ui_name_joinMultiplayer"), material.types.standardText.index)

    subMenuCommon:init(mainMenu, joinMenu, mainMenu.mainView.size)


    local descriptionText = TextView.new(mainView)
    descriptionText.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    descriptionText.baseOffset = vec3(0,-20,0)
    descriptionText.relativeView = titleTextView
    descriptionText.wrapWidth = mainView.size.x - 80
    descriptionText.font = Font(uiCommon.fontName, 16)
    descriptionText.text = locale:get("ui_info_joinMultiplayerDescription")

    

    local controlsContentView = View.new(mainView)
    controlsContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    controlsContentView.relativeView = descriptionText
    controlsContentView.size = vec2(mainView.size.x, mainView.size.y - descriptionText.size.y - titleTextView.size.y - 60)
    controlsContentView.baseOffset = vec3(0,-40, 0)

    local controlsPopOversView = View.new(mainView)
    controlsPopOversView.relativePosition = mainView.relativePosition
    controlsPopOversView.size = vec2(mainView.size.x - 20, mainView.size.y + 40)

    --yOffset = yOffset - restrictContentsTextView.size.y - 10

    --local itemList = ""

   -- local leftPane = View.new(controlsContentView)
   -- leftPane.size = vec2(controlsContentView.size.x * 0.5, controlsContentView.size.y)
   -- leftPane.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)

    leftPane = View.new(controlsContentView)
    leftPane.size = vec2(controlsContentView.size.x * 0.5 + 20, controlsContentView.size.y - 20)
    leftPane.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)

    local publicServerListTitleText = ModelTextView.new(leftPane)
    publicServerListTitleText.font = Font(uiCommon.fontName, 16)
    publicServerListTitleText:setText(locale:get("misc_publicServerList") .. ":", material.types.standardText.index)
    publicServerListTitleText.baseOffset = vec3(0, 0, 0)
    publicServerListTitleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

    leftInsetView = ModelView.new(leftPane)
    leftInsetView:setModel(model:modelIndexForName("ui_inset_lg_1x1"))
    leftInsetView.size = vec2(leftPane.size.x, leftPane.size.y - 30)
    local scaleToUsePaneX = leftInsetView.size.x * 0.5
    local scaleToUsePaneY = leftInsetView.size.y * 0.5 
    leftInsetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    leftInsetView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    leftInsetView.baseOffset = vec3(20,-30,0)


    local rightPane = View.new(controlsContentView)
    rightPane.size = vec2(controlsContentView.size.x * 0.5 - 40, controlsContentView.size.y)
    rightPane.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    
    local previousConnectionsTitleText = ModelTextView.new(rightPane)
    previousConnectionsTitleText.font = Font(uiCommon.fontName, 16)
    previousConnectionsTitleText:setText(locale:get("ui_name_previous") .. ":", material.types.standardText.index)
    previousConnectionsTitleText.baseOffset = vec3(0, 0, 0)
    previousConnectionsTitleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)


    local popUpButtonSize = vec2(440, 40)
    local popUpMenuSize = vec2(popUpButtonSize.x + 20, 300)
    previousConnectionsPopUpButton = uiPopUpButton:create(rightPane, controlsPopOversView, popUpButtonSize, popUpMenuSize)
    previousConnectionsPopUpButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    previousConnectionsPopUpButton.relativeView = previousConnectionsTitleText
    previousConnectionsPopUpButton.baseOffset = vec3(0, -10, 0)
    uiPopUpButton:setSelectionFunction(previousConnectionsPopUpButton, function(selectedIndex, selectedInfo)
        local ipText = selectedInfo.ip
        clientGameSettings:changeSetting("joinWorldIP", ipText)
        uiTextEntry:setText(ipTextEntry, ipText)

        local portText = mj:tostring(selectedInfo.port)
        clientGameSettings:changeSetting("joinWorldPort", portText)
        uiTextEntry:setText(portTextEntry, portText)

        clientGameSettings:changeSetting("joinWorldServerName", selectedInfo.serverName)

        selectedConnectionTitleTextView:setText(selectedInfo.serverName or "", material.types.standardText.index)
    end)
    

    local textEntrySize = vec2(200.0,24.0)
    local ipText = clientGameSettings.values.joinWorldIP

    ipTextEntry = uiTextEntry:create(rightPane, textEntrySize, uiTextEntry.types.standard_10x3, nil, locale:get("ui_name_ipAddress"))
    uiTextEntry:setMaxChars(ipTextEntry, 200)
    ipTextEntry.baseOffset = vec3(0, -40, 0)
    ipTextEntry.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    ipTextEntry.relativeView = previousConnectionsPopUpButton
    uiTextEntry:setText(ipTextEntry, ipText)
    uiTextEntry:setFunction(ipTextEntry, function(newValue)
        selectedConnectionTitleTextView:setText("", material.types.standardText.index)
        clientGameSettings:changeSetting("joinWorldIP", newValue)
        uiPopUpButton:setSelection(previousConnectionsPopUpButton, nil)
    end)
    
    local ipTitleText = ModelTextView.new(rightPane)
    ipTitleText.font = Font(uiCommon.fontName, 16)
    ipTitleText:setText(locale:get("ui_name_ipAddress") .. ":", material.types.standardText.index)
    ipTitleText.baseOffset = vec3(-10, 0, 0)
    ipTitleText.relativeView = ipTextEntry
    ipTitleText.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
    
    
    local portText = clientGameSettings.values.joinWorldPort

    portTextEntry = uiTextEntry:create(rightPane, textEntrySize, uiTextEntry.types.standard_10x3, nil, locale:get("ui_name_port"))
    uiTextEntry:setMaxChars(portTextEntry, 200)
    portTextEntry.baseOffset = vec3(0, -10, 0)
    portTextEntry.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    portTextEntry.relativeView = ipTextEntry
    uiTextEntry:setText(portTextEntry, portText)
    uiTextEntry:setFunction(portTextEntry, function(newValue)
        selectedConnectionTitleTextView:setText("", material.types.standardText.index)
        clientGameSettings:changeSetting("joinWorldPort", newValue)
        uiPopUpButton:setSelection(previousConnectionsPopUpButton, nil)
    end)
    
    local portTitleText = ModelTextView.new(rightPane)
    portTitleText.font = Font(uiCommon.fontName, 16)
    portTitleText:setText(locale:get("ui_name_port") .. ":", material.types.standardText.index)
    portTitleText.baseOffset = vec3(-10, 0, 0)
    portTitleText.relativeView = portTextEntry
    portTitleText.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
    

    
    selectedConnectionTitleTextView = ModelTextView.new(rightPane)
    selectedConnectionTitleTextView.font = Font(uiCommon.fontName, 16)
    selectedConnectionTitleTextView:setText(" ", material.types.standardText.index)
    selectedConnectionTitleTextView.relativeView = portTextEntry
    selectedConnectionTitleTextView.baseOffset = vec3(0,-20, 0)
    selectedConnectionTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)


    local buttonSize = vec2(180, 40)

    local joinButton = uiStandardButton:create(rightPane, buttonSize)
    joinButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    joinButton.relativeView = selectedConnectionTitleTextView
    joinButton.baseOffset = vec3(0,-20, 0)
    uiStandardButton:setText(joinButton, locale:get("ui_action_join"))
    uiStandardButton:setClickFunction(joinButton, function()
        joinMenu:hide()
        joinConfirmButtonFunc()
    end)

    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        joinMenu:hide()
    end)
end

local serverRefreshInProgress = false
function joinMenu:show(controller, mainMenu, joinConfirmButtonFunc_, delay)
    joinConfirmButtonFunc = joinConfirmButtonFunc_
    if not joinMenu.mainView then
        --controller = controller_
        joinMenu:init(mainMenu)
    end

    local savedConnections = controller:getSavedIPConnectionsList() or {}
    local itemList = {}
    for i,connection in ipairs(savedConnections) do
        local name = connection.ip
        if connection.serverName then
            name = connection.serverName
        else
            if connection.port and mj:tostring(connection.port) ~= "" then
                name = connection.ip .. ":" .. mj:tostring(connection.port)
            end
        end
        table.insert(itemList, {
            name = name,
            ip = connection.ip,
            port = mj:tostring(connection.port),
            serverName = connection.serverName,
        })
    end
    uiPopUpButton:setItems(previousConnectionsPopUpButton, itemList)
    if itemList[1] then
        uiPopUpButton:setSelection(previousConnectionsPopUpButton, 1)
    end

    subMenuCommon:slideOn(joinMenu, delay)

    if not serverRefreshInProgress then
        clearList()
        serverRefreshInProgress = true
        steamServerBrowser:refreshInternetServers(function(result)
            if result then
                mj:log("found server:", result)
                addServer(result)
            else
                serverRefreshInProgress = false
            end
        end)
    end
end

function joinMenu:hide()
    if joinMenu.mainView and (not joinMenu.mainView.hidden) then
        subMenuCommon:slideOff(joinMenu)
        return true
    end
    return false
end

function joinMenu:backButtonClicked()
    joinMenu:hide()
end

function joinMenu:hidden()
    return not (joinMenu.mainView and (not joinMenu.mainView.hidden))
end

return joinMenu