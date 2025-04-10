local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"
local modManager = mjrequire "common/modManager"
local modUtility = mjrequire "common/modUtility"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiTribeView = mjrequire "mainThread/ui/uiCommon/uiTribeView"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local alertPanel = mjrequire "mainThread/ui/alertPanel"
--local clientGameSettings = mjrequire "mainThread/clientGameSettings"

local loadMenu = {}

local controller = nil
local mainMenu = nil
local worldList = nil
local worldNameTextEntry = nil
local worldNameTitleText = nil
local lastPlayedTextView = nil
local createdTextView = nil
local worldTimeTextView = nil
local versionTextView = nil
local seedTextView = nil

local worldListView = nil
--local tribesListViewContainer = nil
local tribesListInsetView = nil
local tribeListView = nil
local rightPane = nil
local selectedTribeView = nil

local selectedTribeTitleTextView = nil
local selectedTribePopulationTextView = nil

local newTribeButton = nil
local loadButton = nil
local deleteButton = nil
local openFilesButton = nil

local modListView = nil

local tabSize = vec2(180.0, 45.0)
local tabPadding = 10.0

local currentTabIndex = nil

local selectedTabZOffset = -2.0
local unSelectedTabZOffset = -4.0

local tabTypes = mj:enum {
    "manage",
    "mods",
}

local tabCount = #tabTypes

local tabInfos = {
    [tabTypes.manage] = {
        title = locale:get("ui_name_manageWorld"),
    },
    [tabTypes.mods] = {
        title = locale:get("menu_mods"),
    },
}

local selectedIndex = nil
local worldListTableViewItemInfos = {}
local hoverColor = mj.highlightColor * 0.8
local mouseDownColor = mj.highlightColor * 0.6
--local selectedColor = mj.highlightColor * 0.6

local menuIsActiveForCurrentSelection = false
local manageOrModSelectionActive = false
--local selectionLayoutManageTabsViewIsSelected = false

local tribeListInfos = {}

local tribeSelectedRowIndex = nil
local tribeSapiensRenderGameObjectView = nil

local function updateInfoForSelectedTribe()
    if tribeSelectedRowIndex then
        selectedTribeView.hidden = false
        local detailedInfo = tribeListInfos[tribeSelectedRowIndex].detailedInfo
        if detailedInfo and detailedInfo.tribeName then
            selectedTribeTitleTextView.hidden = false
            selectedTribeTitleTextView:setText(locale:get("misc_tribeNameFormal", {tribeName = detailedInfo.tribeName}), material.types.standardText.index)

            if detailedInfo.population then
                selectedTribePopulationTextView.hidden = false
                selectedTribePopulationTextView.text = locale:get("tribeUI_population") .. ": " .. mj:tostring(detailedInfo.population)
            else
                selectedTribePopulationTextView.hidden = true
            end

            if detailedInfo.sapienInfos then
                tribeSapiensRenderGameObjectView.hidden = false
                uiTribeView:setTribe(tribeSapiensRenderGameObjectView, detailedInfo.tribeID, detailedInfo.sapienInfos)
            else
                tribeSapiensRenderGameObjectView.hidden = true
            end
        else
            selectedTribeTitleTextView.hidden = true
            selectedTribePopulationTextView.hidden = true
            tribeSapiensRenderGameObjectView.hidden = true
        end
    else
        selectedTribeView.hidden = true
    end
end

local function updateTribeSelectedIndex(thisIndex, wasClick)
    if tribeSelectedRowIndex ~= thisIndex then
        tribeSelectedRowIndex = thisIndex
        if tribeSelectedRowIndex == 0 then
            tribeSelectedRowIndex = nil
        end
        if tribeSelectedRowIndex then
            uiSelectionLayout:setSelection(tribeListView, tribeListInfos[tribeSelectedRowIndex].backgroundView)
        end
        updateInfoForSelectedTribe()
        return true
    end
    if not wasClick then
        uiSelectionLayout:setActiveSelectionLayoutView(tribeListView)
        updateInfoForSelectedTribe()
    end
    return false
end

local function updateTribesList()

    uiSelectionLayout:removeAllViews(tribeListView)
    uiScrollView:removeAllRows(tribeListView)
    tribeListInfos = {}

    if not selectedIndex or not worldList[selectedIndex] then
        return
    end

    local sessions = worldList[selectedIndex].sessions
    mj:log("sessions:", sessions)
    if sessions and sessions[1] then
        local rowIndex = 1
        for i,sessionInfo in ipairs(sessions) do
            local detailedInfo = controller:getDetailedWorldSessionInfo(worldList[selectedIndex].worldID, sessionInfo.sessionIndex, true)
            --mj:log("detailedInfo:", detailedInfo)
            if detailedInfo and detailedInfo.tribeID then

                local tribeListInfo = {
                    rowIndex = rowIndex,
                    sessionIndex = sessionInfo.sessionIndex,
                    detailedInfo = detailedInfo
                }
                table.insert(tribeListInfos, tribeListInfo)

                local tribeName = nil
                if detailedInfo.tribeName then
                    tribeName = locale:get("misc_tribeName", {tribeName = detailedInfo.tribeName})
                else
                    tribeName = locale:get("ui_name_startNewTribe")
                end

                local backgroundView = ColorView.new(tribeListView)
                tribeListInfo.backgroundView = backgroundView
                
                local defaultColor = vec4(0.0,0.0,0.0,0.5)
                if rowIndex % 2 == 1 then
                    defaultColor = vec4(0.03,0.03,0.03,0.5)
                end

                backgroundView.color = defaultColor

                backgroundView.size = vec2(tribeListView.size.x - 22, 30)
                backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
                --backgroundView.baseOffset = vec3(0,(-paddingCounter + 1) * 30,0)
            
                uiScrollView:insertRow(tribeListView, backgroundView, nil)

                local tribeTitleTextView = TextView.new(backgroundView)
                tribeTitleTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                tribeTitleTextView.baseOffset = vec3(10,0,0)
                tribeTitleTextView.font = Font(uiCommon.fontName, 16)
                tribeTitleTextView.color = vec4(1.0,1.0,1.0,1.0)
                tribeTitleTextView.text = tribeName


            -- uiSelectionLayout:addView(tribeListView, backgroundView)
                
                local indexCopy = rowIndex
                uiMenuItem:makeMenuItemBackground(backgroundView, tribeListView, rowIndex, hoverColor, mouseDownColor, function(wasClick)
                    mj:log("detailedInfo tribe:", detailedInfo and detailedInfo.tribeID, "\nsessionInfo:", sessionInfo)
                    updateTribeSelectedIndex(indexCopy, wasClick)
                end)
                rowIndex = rowIndex + 1
            end
        end

        --uiSelectionLayout:setActiveSelectionLayoutView(tribeListView)
        if tribeListInfos[1] then
            uiSelectionLayout:setSelection(tribeListView, tribeListInfos[1].backgroundView)
            updateTribeSelectedIndex(1, false)
        else
            updateTribeSelectedIndex(nil, false)
        end
    end

end

local function updateModsList()


    local containerView = tabInfos[tabTypes.mods].contentView

    if modListView then
        containerView:removeSubview(modListView)
        uiSelectionLayout:removeAllViews(containerView)
        modListView = nil
    end

    if not selectedIndex or not worldList[selectedIndex] then
        return
    end

    local worldID = worldList[selectedIndex].worldID

    local enabledModList = controller:getEnabledModListFromConfig(worldID)
    --mj:log("enabledModList:", enabledModList)

    local enabledWorldMods = {}
    if enabledModList then
        for i,modDir in ipairs(enabledModList) do
            enabledWorldMods[modDir] = true
        end
    end
    
    local modListViewSize = vec2(containerView.size.x - 10.0, containerView.size.y - 10.0)
    modListView = uiScrollView:create(containerView, modListViewSize, MJPositionInnerLeft)
   --modListView.size = modListViewSize
    modListView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)

    local function modIsEnabled(dirName)
        return enabledWorldMods[dirName]
    end

    local function setModEnabled(dirName, enabled)
        if enabled then
            enabledWorldMods[dirName] = true
        else
            enabledWorldMods[dirName] = nil
        end

        controller:setModEnabledForWorld(worldID, dirName, enabled)
    end

    local paddingCounter = 1
    local listItemCounter = 1

    local warnedAboutChangingMods = false


    local function getImageTexture(modInfo)
        if modInfo then 
            local previewName = modInfo.preview
            if previewName then
                local path = modInfo.directory .. "/" .. previewName
                if fileUtils.fileExistsAtPath(path) then
                    return MJCache:getTextureAbsolute(path, false, false, true)
                end
            end
        end
        return MJCache:getTexture("img/questionMark.png", false, false, true)
    end
    local function getModName(modInfo)
        if modInfo and modInfo.name then 
            return modInfo.name
        end
        return locale:get("mods_nameDefault")
    end

    local function getModVersion(dirName, modInfo)
        --mj:log("modInfo:", modInfo)
        local worldModPath = controller:getWorldSavePath(worldID, "mods/" .. dirName)
        local worldVersion = modUtility:getWorldModVersion(worldModPath)
        if worldVersion then
            return worldVersion
        end
        if modInfo and modInfo.version then 
            return modInfo.version
        end
        return nil
    end

    local function addModEntries(modInfosByDirName, orderedNames)
        for i,dirName in ipairs(orderedNames) do
            local modInfo = modInfosByDirName[dirName]
            local backgroundView = ColorView.new(modListView)
            
            
            local defaultColor = vec4(0.0,0.0,0.0,0.5)
            if listItemCounter % 2 == 1 then
                defaultColor = vec4(0.03,0.03,0.03,0.5)
            end
            
            backgroundView.color = defaultColor

            backgroundView.size = vec2(modListView.size.x - 22, 30)
            backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
            --backgroundView.baseOffset = vec3(0,(-paddingCounter + 1) * 30,0)
        
            uiScrollView:insertRow(modListView, backgroundView, nil)
            
            local modIconView = ImageView.new(backgroundView)
            modIconView.size = vec2(26,26)
            modIconView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            modIconView.imageTexture = getImageTexture(modInfo)
            modIconView.baseOffset = vec3(10,0,0)

            local modTextView = TextView.new(backgroundView)
            modTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            modTextView.baseOffset = vec3(4,-2,0)
            modTextView.relativeView = modIconView
            modTextView.font = Font(uiCommon.fontName, 16)

            local installedVersion = getModVersion(dirName, modInfo)

            modTextView.color = vec4(1.0,1.0,1.0,1.0)
            local modName = getModName(modInfo)
            modTextView.text = modName .. " " .. (installedVersion or "")

            --local itemIndex = listItemCounter
            --uiMenuItem:makeMenuItemBackground(backgroundView, nil, listItemCounter, hoverColor, mouseDownColor, function(wasClick)
                --updateSelectedIndex(itemIndex)
            --end)

            local typeIcon = ImageView.new(backgroundView)
            typeIcon.size = vec2(20,20)
            typeIcon.relativeView = modTextView
            typeIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            typeIcon.baseOffset = vec3(10,0,1)
            --typeIcon.materialIndex = material.types.ui_standard.index

            
            local toggleButton = uiStandardButton:create(backgroundView, vec2(26,26), uiStandardButton.types.toggle)
            toggleButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            toggleButton.baseOffset = vec3(-10, 0, 0)
            uiStandardButton:setToggleState(toggleButton, modIsEnabled(dirName))
        
            uiStandardButton:setClickFunction(toggleButton, function()
                if not warnedAboutChangingMods then
                    alertPanel:show(mainMenu.mainView, locale:get("ui_name_changeMods"), locale:get("ui_info_changeModAreYouSure", {worldName = worldList[selectedIndex].name}), {
                        {
                            isDefault = true,
                            name = locale:get("ui_action_continue"),
                            action = function()
                                warnedAboutChangingMods = true
                                setModEnabled(dirName, uiStandardButton:getToggleState(toggleButton))
                                alertPanel:hide()
                            end
                        },
                        {
                            isCancel = true,
                            name = locale:get("ui_action_cancel"),
                            action = function()
                                alertPanel:hide()
                                uiStandardButton:setToggleState(toggleButton, modIsEnabled(dirName))
                            end
                        }
                    })
                else
                   setModEnabled(dirName, uiStandardButton:getToggleState(toggleButton))
                end
            end)

            uiSelectionLayout:addView(containerView, toggleButton)

            if installedVersion ~= modInfo.version then
                --mj:log("modInfo.version:", modInfo.version)
                --mj:log("installedVersion:", installedVersion)
                local updateButton = uiStandardButton:create(backgroundView, vec2(80,26), uiStandardButton.types.standard_10x3)
                updateButton.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
                updateButton.relativeView = toggleButton
                updateButton.baseOffset = vec3(-2, 0, 0)
                uiStandardButton:setText(updateButton, locale:get("ui_action_update"))
                uiStandardButton:setClickFunction(updateButton, function()

                    --values.modName, values.newVersion, values.oldVersion
                    
                    alertPanel:show(mainMenu.mainView, 
                    locale:get("ui_name_updateMod"), 
                    locale:get("ui_info_updateModAreYouSure", {
                            modName = modName, 
                            newVersion = modInfo.version,
                            oldVersion = installedVersion,
                        }), 
                    {
                        {
                            isDefault = true,
                            name = locale:get("ui_name_updateMod"),
                            action = function()
                                controller:updateMod(worldID, dirName)
                                updateModsList()
                                alertPanel:hide()
                            end
                        },
                        {
                            isCancel = true,
                            name = locale:get("ui_action_cancel"),
                            action = function()
                                alertPanel:hide()
                            end
                        }
                    })
                end)
            end


            if modInfo.isLocal then
                --[[local uploadButton = uiStandardButton:create(backgroundView, vec2(26,26), uiStandardButton.types.slim_1x1)
                uploadButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
                uploadButton.baseOffset = vec3(-10, 0, 0)
                uiStandardButton:setClickFunction(uploadButton, function()
                    showModDeveloperMenuFunc(modInfo)
                end)]]
                typeIcon.imageTexture = MJCache:getTexture("img/icons/hd.png", false, false, true)
                --typeIcon:setTextures("img/icons/hd.png")
            else
                typeIcon.imageTexture = MJCache:getTexture("img/icons/steam.png", false, false, true)
                --typeIcon:setTextures("img/icons/steam.png")
            end

            
            --[[tableViewItemInfos[listItemCounter] = {
                backgroundView = backgroundView,
                defaultColor = defaultColor,
                modInfo = modInfo,
            }]]
        
            paddingCounter = paddingCounter + 1
            listItemCounter = listItemCounter + 1
        end
    end

    local modInfosByTypeByDirName = modManager.modInfosByTypeByDirName

    --mj:log("modInfosByTypeByDirName:", modInfosByTypeByDirName)

    if modInfosByTypeByDirName.world and next(modInfosByTypeByDirName.world) then
        local orderedDirNames = {}
        for k,v in pairs(modInfosByTypeByDirName.world) do
            table.insert(orderedDirNames, k)
        end
        local function sortByName(a,b)
            if enabledWorldMods[a] then
                if not enabledWorldMods[b] then
                    return true
                end
            else
                if enabledWorldMods[b] then
                    return false
                end
            end

            return modInfosByTypeByDirName.world[a].name < modInfosByTypeByDirName.world[b].name
        end

        table.sort(orderedDirNames, sortByName)

        addModEntries(modInfosByTypeByDirName.world, orderedDirNames)
    end

    --updateSelectedIndex(1)
end

local function switchTabs(tabIndex)
    if currentTabIndex ~= tabIndex then
        if currentTabIndex then
            local currentInfo = tabInfos[currentTabIndex]
            currentInfo.contentView.hidden = true

            --uiObjectsByModeType[currentModeIndex]:hide()

            uiStandardButton:setActivated(currentInfo.tabButton, false)
            local prevOffset = currentInfo.tabButton.baseOffset
            currentInfo.tabButton.baseOffset = vec3(prevOffset.x, prevOffset.y, unSelectedTabZOffset)

        end

        currentTabIndex = tabIndex

        local currentInfo = tabInfos[currentTabIndex]
        currentInfo.contentView.hidden = false
        
        uiStandardButton:setActivated(currentInfo.tabButton, true)
        local prevOffset = currentInfo.tabButton.baseOffset
        currentInfo.tabButton.baseOffset = vec3(prevOffset.x, prevOffset.y, selectedTabZOffset)
        
        if currentTabIndex == tabTypes.mods then
            updateModsList()
        end
        --updateCurrentView()

    end
end

local function updateSelectedIndex(newIndex)
    if newIndex ~= selectedIndex then
        if menuIsActiveForCurrentSelection then
            menuIsActiveForCurrentSelection = false
            uiSelectionLayout:setActiveSelectionLayoutView(worldListView)
        end
       -- if selectedIndex then
           -- local tableViewItemInfo = tableViewItemInfos[selectedIndex]
           -- updateButtonColors(tableViewItemInfo.backgroundView, tableViewItemInfo.defaultColor)
       -- end

        selectedIndex = newIndex

        if selectedIndex and worldList[selectedIndex] then
            rightPane.hidden = false
           -- local tableViewItemInfo = tableViewItemInfos[selectedIndex]
          --  updateButtonColors(tableViewItemInfo.backgroundView, selectedColor)

            uiTextEntry:setText(worldNameTextEntry, worldList[selectedIndex].name)
            worldNameTitleText:setText(locale:get("ui_name_world") .. " : " .. worldList[selectedIndex].name, material.types.standardText.index)

            local now = os.time()
            local lastPlayedString = locale:get("ui_name_notApplicable")
            local createdString = locale:get("ui_name_notApplicable")
            local versionString = worldList[selectedIndex].lastPlayedVersion
            local seedString = worldList[selectedIndex].seed

            local lastPlayedTime = worldList[selectedIndex].lastPlayedTime
            local timeSincePlayed = (now - lastPlayedTime)

            if timeSincePlayed >= 0 then
                local found = false
                if timeSincePlayed < 48 * 60 * 60 then
                    local currentTimeTable = os.date("*t", now)
                    local currentHour = currentTimeTable.hour
                    local currentMinute = currentTimeTable.min
                    if timeSincePlayed < (currentHour * 60 + currentMinute) * 60 then
                        lastPlayedString = locale:get("ui_name_today")
                        found = true
                    elseif timeSincePlayed < ((24 + currentHour) * 60 + currentMinute) * 60 then
                        lastPlayedString = locale:get("ui_name_yesterday")
                        found = true
                    end
                end
                if not found then
                    local count = math.floor(timeSincePlayed / (24 * 60 * 60))
                    if count < 2 then
                        count = 2
                    end
                    lastPlayedString = locale:get("ui_daysAgo", {count = count})
                end
            end

            
            local creationTimeTable = os.date("*t", worldList[selectedIndex].creationTime)

            createdString = mj:tostring(creationTimeTable.day) .. os.date(" %B %Y", worldList[selectedIndex].creationTime)
            
            lastPlayedTextView.text = lastPlayedString
            createdTextView.text = createdString
            versionTextView.text = versionString
            seedTextView.text = seedString

            local worldConfig = controller:getWorldConfigurationInfo(worldList[selectedIndex].worldID)
            if worldConfig and worldConfig.dayLength and worldConfig.dayLength > 0.0 then
                worldTimeTextView.text = string.format("%d", math.floor(worldList[selectedIndex].worldTime / worldConfig.dayLength))
            else
                worldTimeTextView.text = ""
            end

            uiSelectionLayout:setSelection(worldListView, worldListTableViewItemInfos[selectedIndex].backgroundView, true)

            updateTribesList()
            
            if currentTabIndex == tabTypes.mods then
                updateModsList()
            end
            
        else
            rightPane.hidden = true
        end
    else
        if not worldList[selectedIndex] then
            rightPane.hidden = true
        else
            if not menuIsActiveForCurrentSelection then
                menuIsActiveForCurrentSelection = true
                uiSelectionLayout:setActiveSelectionLayoutView(rightPane)
                uiSelectionLayout:setSelection(rightPane, loadButton)
            end
        end
    end
end

function loadMenu:loadWorldsList(worldList_)
    worldList = mj:cloneTable(worldList_)

    local function sortWorlds(a,b)
        return a.lastPlayedTime > b.lastPlayedTime
    end

    table.sort(worldList, sortWorlds)

    uiScrollView:removeAllRows(worldListView)
    uiSelectionLayout:removeAllViews(worldListView)

    local counter = 1

    for i,worldInfo in pairs(worldList) do
        local backgroundView = ColorView.new(worldListView)
        
        local defaultColor = vec4(0.0,0.0,0.0,0.5)
        if counter % 2 == 1 then
            defaultColor = vec4(0.03,0.03,0.03,0.5)
        end

        backgroundView.color = defaultColor

        backgroundView.size = vec2(worldListView.size.x - 20, 30)
        backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

        uiScrollView:insertRow(worldListView, backgroundView, nil)
        --backgroundView.baseOffset = vec3(0,(-counter + 1) * 30,0)

        uiMenuItem:makeMenuItemBackground(backgroundView, worldListView, counter, hoverColor, mouseDownColor, function(wasClick)
            --[[if menuIsActiveForCurrentSelection then
                menuIsActiveForCurrentSelection = false
                uiSelectionLayout:setActiveSelectionLayoutView(worldListView)
            end]]
            
            updateSelectedIndex(i)
        end)

        
        uiSelectionLayout:addView(worldListView, backgroundView)
        
        uiSelectionLayout:setItemSelectedFunction(backgroundView, function()
            updateSelectedIndex(i)
        end)

        local nameTextView = TextView.new(backgroundView)
        nameTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        nameTextView.baseOffset = vec3(6,0,0)
        nameTextView.font = Font(uiCommon.fontName, 16)

        nameTextView.color = vec4(1.0,1.0,1.0,1.0)

        local nameWithSession = worldInfo.name
        if worldInfo.sessionIndex then
            nameWithSession = nameWithSession .. string.format(" (%d)", worldInfo.sessionIndex)
        end

        nameTextView.text = worldInfo.name

        worldListTableViewItemInfos[i] = {
            backgroundView = backgroundView,
            nameTextView = nameTextView,
        }

        counter = counter + 1
    end

end

local function createCenteredTextPair(parentView, titleText, valueTextOrNil)
    local contentView = View.new(parentView)

    local titleView = TextView.new(contentView)
    titleView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    titleView.baseOffset = vec3(-parentView.size.x * 0.5 - 5,0,0)
    titleView.font = Font(uiCommon.fontName, 16)
    titleView.color = vec4(1.0,1.0,1.0,1.0)
    titleView.text = titleText

    local valueView = TextView.new(contentView)
    valueView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    valueView.baseOffset = vec3(parentView.size.x * 0.5 + 5,0,0)
    valueView.font = Font(uiCommon.fontName, 16)
    valueView.color = vec4(1.0,1.0,1.0,1.0)
    if valueTextOrNil then
        valueView.text = valueTextOrNil
    end
    
    contentView.size = vec2(parentView.size.x, titleView.size.y)

    return {
        view = contentView,
        titleView = titleView,
        valueView = valueView,
    }
    
end

function loadMenu:init(mainMenu_, worldList_, loadConfirmButtonFunc)

    mainMenu = mainMenu_
    local backgroundSize = subMenuCommon.size
    

    local mainView = ModelView.new(mainMenu.mainView)
    loadMenu.mainView = mainView
    
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
    titleTextView:setText(locale:get("ui_name_saves"), material.types.standardText.index)

    subMenuCommon:init(mainMenu, loadMenu, mainMenu.mainView.size)

    local buttonSize = vec2(180, 40)
    local thinButtonSize = vec2(180, 30)

    
    local leftPane = ModelView.new(mainView)
    leftPane:setModel(model:modelIndexForName("ui_inset_lg_1x1"))
    local sizeY = mainView.size.y - 80.0
    sizeY = math.floor(sizeY / 30.0) * 30.0
    local leftPaneInnerSize = vec2(mainView.size.x * 0.4 - 40, sizeY)
    leftPane.size = leftPaneInnerSize + vec2(10.0,10.0)
    local scaleToUsePaneX = leftPane.size.x * 0.5
    local scaleToUsePaneY = leftPane.size.y * 0.5 
    leftPane.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    leftPane.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    leftPane.baseOffset = vec3(20.0, -60.0, 0.0)

    worldListView = uiScrollView:create(leftPane, leftPaneInnerSize, MJPositionInnerLeft)
    worldListView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    
    uiSelectionLayout:createForView(worldListView)
    
    rightPane = View.new(mainView)
    rightPane.size = vec2(mainView.size.x * 0.6 - 30, leftPane.size.y)
    rightPane.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    rightPane.baseOffset = vec3(-20.0, -60.0, 0.0)
    
    uiSelectionLayout:createForView(rightPane)

    worldNameTitleText = ModelTextView.new(rightPane)
    worldNameTitleText.font = Font(uiCommon.titleFontName, 28)
    worldNameTitleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    worldNameTitleText.baseOffset = vec3(0,0, 0)

    

    local tribesViewContainer = ModelView.new(rightPane)
    tribesViewContainer:setModel(model:modelIndexForName("ui_inset_lg_1x1"))
    tribesViewContainer.size = vec2(rightPane.size.x, 220.0)
    local tribeContainerScaleToUsePaneX = tribesViewContainer.size.x * 0.5
    local tribeContainerScaleToUsePaneY = tribesViewContainer.size.y * 0.5 
    tribesViewContainer.scale3D = vec3(tribeContainerScaleToUsePaneX,tribeContainerScaleToUsePaneY,tribeContainerScaleToUsePaneX)
    tribesViewContainer.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    tribesViewContainer.baseOffset = vec3(0,-40, 0)


    local tribesListViewContainer = View.new(tribesViewContainer)
    tribesListViewContainer.size = vec2(rightPane.size.x * 0.5, 220.0)
    tribesListViewContainer.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    --tribesListViewContainer.color = vec4(0.2,0.3,0.6,0.5)

    newTribeButton = uiStandardButton:create(tribesListViewContainer, buttonSize)
    newTribeButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    newTribeButton.baseOffset = vec3(0,-10,0)
    uiStandardButton:setText(newTribeButton, locale:get("ui_name_startNewTribe"))
    uiStandardButton:setClickFunction(newTribeButton, function()
        loadMenu:hide()
        loadConfirmButtonFunc(worldList[selectedIndex].worldID, nil, true)
    end)

    uiSelectionLayout:addView(rightPane, newTribeButton)

    tribesListInsetView = ModelView.new(tribesListViewContainer)
    tribesListInsetView:setModel(model:modelIndexForName("ui_inset_lg_1x1"), {
        [material.types.ui_background_inset.index] = material.types.ui_background_inset_lighter.index,
    })
    local tribesListInsetViewSize = vec2(tribesListViewContainer.size.x - 10, tribesListViewContainer.size.y - 70)
    tribesListInsetView.size = tribesListInsetViewSize
    local tribesScaleToUsePaneX = tribesListInsetViewSize.x * 0.5
    local tribesScaleToUsePaneY = tribesListInsetViewSize.y * 0.5 
    tribesListInsetView.scale3D = vec3(tribesScaleToUsePaneX,tribesScaleToUsePaneY,tribesScaleToUsePaneX)
    tribesListInsetView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    tribesListInsetView.baseOffset = vec3(10,10, 0)


    local tribeListViewSize = vec2(tribesListInsetView.size.x, tribesListInsetView.size.y)
    tribeListView = uiScrollView:create(tribesListInsetView, tribeListViewSize, MJPositionInnerLeft)
   --modListView.size = modListViewSize
    tribeListView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)

    uiSelectionLayout:createForView(tribeListView)



    ------  start load selected tribe view ---------

    selectedTribeView = View.new(tribesViewContainer)
    selectedTribeView.size = vec2(rightPane.size.x * 0.5, 220.0)
    selectedTribeView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    --selectedTribeView.color = vec4(0.2,0.6,0.2,0.5)
    --selectedTribeView.baseOffset = vec3(0,-40, 0)


    local tribeSapiensRenderGameObjectViewSize = vec2(selectedTribeView.size.x - 20, 130)

    --[[local testView = ColorView.new(selectedTribeView)
    testView.size = tribeSapiensRenderGameObjectViewSize
    testView.color = vec4(0.2,0.6,0.2,0.5)
    testView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    testView.baseOffset = vec3(0,55, 0)]]

    tribeSapiensRenderGameObjectView = uiTribeView:create(selectedTribeView, tribeSapiensRenderGameObjectViewSize)
    tribeSapiensRenderGameObjectView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    tribeSapiensRenderGameObjectView.baseOffset = vec3(0,52, 0)

    selectedTribeTitleTextView = ModelTextView.new(selectedTribeView)
    selectedTribeTitleTextView.font = Font(uiCommon.titleFontName, 24)
    selectedTribeTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    selectedTribeTitleTextView.baseOffset = vec3(0,-15,0)
    selectedTribeTitleTextView.wrapWidth = selectedTribeView.size.x - 10

    selectedTribePopulationTextView = TextView.new(selectedTribeView)
    selectedTribePopulationTextView.font = Font(uiCommon.titleFontName, 16)
    selectedTribePopulationTextView.color = mj.textColor
    selectedTribePopulationTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedTribePopulationTextView.relativeView = selectedTribeTitleTextView
    selectedTribePopulationTextView.baseOffset = vec3(0,5,0)

    loadButton = uiStandardButton:create(selectedTribeView, buttonSize)
    loadButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    loadButton.baseOffset = vec3(0,10,0)
    uiStandardButton:setText(loadButton, locale:get("ui_name_load"))
    uiStandardButton:setClickFunction(loadButton, function()
        loadMenu:hide()
        local sessionIndex = 0
        if tribeSelectedRowIndex then
            sessionIndex = tribeListInfos[tribeSelectedRowIndex].sessionIndex
        end
        loadConfirmButtonFunc(worldList[selectedIndex].worldID, sessionIndex, false)
    end)

    uiSelectionLayout:addView(rightPane, loadButton)


    ------  end load selected tribe view ---------

    
    local rightDetailsPane = ModelView.new(rightPane)
    rightDetailsPane:setModel(model:modelIndexForName("ui_inset_lg_1x1"))
    local rightDetailsPaneSizeY = rightPane.size.y - 320.0
    rightDetailsPane.size = vec2(rightPane.size.x, rightDetailsPaneSizeY)
    local rightDetailsScaleToUsePaneX = rightDetailsPane.size.x * 0.5
    local rightDetailsScaleToUsePaneY = rightDetailsPane.size.y * 0.5 
    rightDetailsPane.scale3D = vec3(rightDetailsScaleToUsePaneX,rightDetailsScaleToUsePaneY,rightDetailsScaleToUsePaneX)
    rightDetailsPane.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    rightDetailsPane.baseOffset = vec3(0.0, 4.0, 6.0)
    
    local manageContentView = View.new(rightDetailsPane)
    manageContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    manageContentView.size = vec2(rightDetailsPane.size.x, rightDetailsPane.size.y)
    manageContentView.hidden = true
    tabInfos[tabTypes.manage].contentView = manageContentView
    
    uiSelectionLayout:createForView(manageContentView)
    
    local modsContentView = View.new(rightDetailsPane)
    modsContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    modsContentView.size = vec2(rightDetailsPane.size.x, rightDetailsPane.size.y)
    modsContentView.hidden = true
    tabInfos[tabTypes.mods].contentView = modsContentView

    uiSelectionLayout:createForView(modsContentView)

    local function addTabButton(buttonIndex, modeInfo)
        local tabButton = uiStandardButton:create(rightPane, tabSize, uiStandardButton.types.tabInset, nil)
        tabButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)
        tabButton.relativeView = rightDetailsPane

        local xOffset = (tabCount * -0.5 + (buttonIndex - 1) + 0.5) * (tabSize.x + tabPadding)
        local zOffset = unSelectedTabZOffset
        --[[if buttonIndex == 1 then
            zOffset = selectedTabZOffset
        end]]

        tabButton.baseOffset = vec3(xOffset, -10, zOffset)
        uiStandardButton:setText(tabButton, modeInfo.title)
        --uiStandardButton:setSelectedTextColor(tabButton, mj.textColor)

        local function doSelect(wasUserClick)
            uiSelectionLayout:setActiveSelectionLayoutView(rightPane)
            menuIsActiveForCurrentSelection = true

            if wasUserClick and currentTabIndex == buttonIndex then
                uiSelectionLayout:setActiveSelectionLayoutView(tabInfos[buttonIndex].contentView)
                manageOrModSelectionActive = true
            else
                switchTabs(buttonIndex)
            end

            uiSelectionLayout:setSelection(rightPane, tabButton, true)
        end
        
        uiStandardButton:setClickFunction(tabButton, function()
            doSelect(true)
        end)
        
        uiSelectionLayout:setItemSelectedFunction(tabButton, function()
            doSelect(false)
        end)

        modeInfo.tabButton = tabButton
        
        uiSelectionLayout:addView(rightPane, tabButton)
        uiSelectionLayout:addDirectionOverride(tabButton, loadButton, uiSelectionLayout.directions.up, false)
    end

    for i,v in ipairs(tabTypes) do
        addTabButton(i, tabInfos[i])
    end
    switchTabs(1)


    
    local textEntryContentView = View.new(manageContentView)

    local worldNameTextEntryTitleView = TextView.new(textEntryContentView)
    worldNameTextEntryTitleView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    worldNameTextEntryTitleView.baseOffset = vec3(-manageContentView.size.x * 0.5 - 5,0,0)
    worldNameTextEntryTitleView.font = Font(uiCommon.fontName, 16)
    worldNameTextEntryTitleView.color = vec4(1.0,1.0,1.0,1.0)
    worldNameTextEntryTitleView.text = locale:get("ui_action_editName") .. ":"
    

    local textEntrySize = vec2(200.0,24.0)
    worldNameTextEntry = uiTextEntry:create(textEntryContentView, textEntrySize, uiTextEntry.types.standard_10x3, MJPositionInnerLeft, locale:get("ui_action_editName"))
    uiTextEntry:setMaxChars(worldNameTextEntry, 50)
    worldNameTextEntry.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    worldNameTextEntry.baseOffset = vec3(manageContentView.size.x * 0.5 + 5,0,0)
    uiTextEntry:setFunction(worldNameTextEntry, function(newValue)
        if selectedIndex and newValue and string.len(newValue) > 0 then
            controller:renameWorld(worldList[selectedIndex].worldID, newValue)

            for i,worldInfo in pairs(worldList) do
                if worldInfo.worldID == worldList[selectedIndex].worldID then
                    worldListTableViewItemInfos[i].nameTextView.text = newValue
                    worldList[i].name = newValue
                end
            end

            worldNameTitleText:setText(locale:get("ui_name_world") .. " : " .. newValue, material.types.standardText.index)
        end
    end)
    
    uiSelectionLayout:addView(manageContentView, worldNameTextEntry)

    textEntryContentView.size = vec2(manageContentView.size.x, textEntrySize.y)
    textEntryContentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    textEntryContentView.baseOffset = vec3(0,-60,0)
    --uiSelectionLayout:addView(manageContentView, worldNameTextEntry)


    local createdPairInfo = createCenteredTextPair(manageContentView, locale:get("ui_name_created") .. ":", nil)
    createdPairInfo.view.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    createdPairInfo.view.relativeView = textEntryContentView
    createdPairInfo.view.baseOffset = vec3(0,-5,0)
    createdTextView = createdPairInfo.valueView
    
    local lastPlayedPairInfo = createCenteredTextPair(manageContentView, locale:get("ui_name_lastPlayed") .. ":", nil)
    lastPlayedPairInfo.view.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    lastPlayedPairInfo.view.relativeView = createdPairInfo.view
    lastPlayedPairInfo.view.baseOffset = vec3(0,-5,0)
    lastPlayedTextView = lastPlayedPairInfo.valueView
    
    local worldTimePairInfo = createCenteredTextPair(manageContentView, locale:get("ui_name_worldAge") .. ":", nil)
    worldTimePairInfo.view.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    worldTimePairInfo.view.relativeView = lastPlayedPairInfo.view
    worldTimePairInfo.view.baseOffset = vec3(0,-5,0)
    worldTimeTextView = worldTimePairInfo.valueView
    
    local versionPairInfo = createCenteredTextPair(manageContentView, locale:get("ui_name_lastPlayedVersion") .. ":", nil)
    versionPairInfo.view.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    versionPairInfo.view.relativeView = worldTimePairInfo.view
    versionPairInfo.view.baseOffset = vec3(0,-5,0)
    versionTextView = versionPairInfo.valueView
    
    local seedPairInfo = createCenteredTextPair(manageContentView, locale:get("ui_name_seed") .. ":", nil)
    seedPairInfo.view.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    seedPairInfo.view.relativeView = versionPairInfo.view
    seedPairInfo.view.baseOffset = vec3(0,-5,0)
    seedTextView = seedPairInfo.valueView

    openFilesButton = uiStandardButton:create(manageContentView, thinButtonSize)
    openFilesButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    openFilesButton.relativeView = seedPairInfo.view
    openFilesButton.baseOffset = vec3(0,-60, 0)
    uiStandardButton:setText(openFilesButton, locale:get("mods_filesLink"))
    uiStandardButton:setClickFunction(openFilesButton, function()
        fileUtils.openFile(worldList[selectedIndex].path)
    end)
    uiSelectionLayout:addView(manageContentView, openFilesButton)

    deleteButton = uiStandardButton:create(manageContentView, thinButtonSize)
    deleteButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    deleteButton.relativeView = openFilesButton
    deleteButton.baseOffset = vec3(0,-10, 0)
    uiStandardButton:setText(deleteButton, locale:get("ui_name_deleteWorld"))
    uiStandardButton:setClickFunction(deleteButton, function()
        alertPanel:show(mainMenu.mainView, locale:get("ui_name_deleteWorld"), locale:get("ui_info_deleteWorldAreYouSure", {worldName = worldList[selectedIndex].name}), {
            {
                isDefault = true,
                name = locale:get("ui_name_deleteWorld"),
                action = function()
                    controller:deleteWorld(worldList[selectedIndex].worldID)
                    alertPanel:hide()
                    mainMenu:worldWasDeleted()
                    uiSelectionLayout:setActiveSelectionLayoutView(worldListView)
                    updateSelectedIndex(1)
                    --uiSelectionLayout:setSelection(worldListView, tableViewItemInfos[1].backgroundView)
                end
            },
            {
                isCancel = true,
                name = locale:get("ui_action_cancel"),
                action = function()
                    alertPanel:hide()
                end
            }
        })
        --loadMenu:hide()
       -- loadConfirmButtonFunc(worldList[selectedIndex].worldID)
    end)
    uiSelectionLayout:addView(manageContentView, deleteButton)


    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        loadMenu:hide()
    end)

    

    loadMenu:loadWorldsList(worldList_)
    updateSelectedIndex(1)

end

function loadMenu:show(controller_, mainMenu_, worldList_, loadConfirmButtonFunc, delay)
    if not loadMenu.mainView then
        controller = controller_
        loadMenu:init(mainMenu_, worldList_, loadConfirmButtonFunc)
    end
    subMenuCommon:slideOn(loadMenu, delay)
    uiSelectionLayout:setActiveSelectionLayoutView(worldListView)
end

function loadMenu:hide()
    if loadMenu.mainView and (not loadMenu.mainView.hidden) then
        alertPanel:hide()
        subMenuCommon:slideOff(loadMenu)
        --uiSelectionLayout:removeActiveSelectionLayoutView(rightPane)
        uiSelectionLayout:removeActiveSelectionLayoutView(worldListView)
        return true
    end
    return false
end


function loadMenu:backButtonClicked()
    if manageOrModSelectionActive then
        manageOrModSelectionActive = false
        uiSelectionLayout:setActiveSelectionLayoutView(rightPane)
    elseif menuIsActiveForCurrentSelection then
        menuIsActiveForCurrentSelection = false
        uiSelectionLayout:setActiveSelectionLayoutView(worldListView)
    else
        loadMenu:hide()
    end
end

function loadMenu:hidden()
    return not (loadMenu.mainView and (not loadMenu.mainView.hidden))
end

return loadMenu