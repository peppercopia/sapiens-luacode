local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

local modManager = mjrequire "common/modManager"
local steam = mjrequire "common/utility/steam"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local alertPanel = mjrequire "mainThread/ui/alertPanel"
--local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"

local modsMenu = {}

local changes = {}
local controller = nil
local mainMenu = nil
local showModDeveloperMenuFunc = nil
local worldModSelectionCreationStateToPreserve = nil


local selectedIndex = -1
local tableViewItemInfos = {}
local hoverColor = mj.highlightColor * 0.8
local mouseDownColor = mj.highlightColor * 0.6
local selectedColor = mj.highlightColor * 0.6

local iconSize = vec2(120.0,120.0)
local buttonSize = vec2(180, 40)

local rightPane = nil
local selectedModIconView = nil
local selectedModTitleTextView = nil
local selectedModDescriptionTextView = nil
local selectedModVersionTextView = nil
local selectedModDeveloperTextView = nil
local selectedModWebsiteButton = nil
local selectedModOpenFilesButton = nil
local selectedModSteamPageButton = nil

local developerUploadButton = nil

local leftPane = nil
local applyButton = nil
local modListView = nil
local isWorldModSelection = false

local enabledWorldMods = {}
local enabledWorldModsApplied = {}

local titleTextView = nil
local descriptionTextA = nil
--local descriptionTextB = nil

local function updateButtonColors(buttonView, baseColor)
    buttonView.color = baseColor
    buttonView.hoverStart = function ()
        buttonView.color = hoverColor
    end

    buttonView.hoverEnd = function ()
        buttonView.color = baseColor
    end

    buttonView.mouseDown = function (buttonIndex)
        if buttonIndex == 0 then
            buttonView.color = mouseDownColor
        end
    end

    buttonView.mouseUp = function (buttonIndex)
        if buttonIndex == 0 then
            buttonView.color = baseColor
        end
    end
end

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
local function getModDescription(modInfo)
    if modInfo and modInfo.description then 
        return modInfo.description
    end
    return locale:get("mods_descriptionDefault")
end
local function getModVersion(modInfo)
    if modInfo and modInfo.version then 
        return locale:get("mods_version") .. ": " .. modInfo.version
    end
    return locale:get("mods_versionDefault")
end

local function getModDeveloper(modInfo)
    if modInfo and modInfo.developer then 
        return locale:get("mods_developer") .. ": " .. modInfo.developer
    end
    return locale:get("mods_developerDefault")
end
local function getModWebsite(modInfo)
    if modInfo and modInfo.website then 
        return modInfo.website
    end
    return nil
end
local function getModSteamURL(modInfo)
    if modInfo and modInfo.steamURL then 
        return modInfo.steamURL
    end
    return nil
end

local function updateSelectedIndex(newIndex)
    if newIndex ~= selectedIndex then
        if selectedIndex and selectedIndex > 0 then
            local tableViewItemInfo = tableViewItemInfos[selectedIndex]
            updateButtonColors(tableViewItemInfo.backgroundView, tableViewItemInfo.defaultColor)
        end

        selectedIndex = newIndex

        local modInfo = nil
        if selectedIndex then
            rightPane.hidden = false
            local tableViewItemInfo = tableViewItemInfos[selectedIndex]
            if tableViewItemInfo then
                updateButtonColors(tableViewItemInfo.backgroundView, selectedColor)
                modInfo = tableViewItemInfo.modInfo
            end

            selectedModIconView.imageTexture = getImageTexture(modInfo)
            selectedModTitleTextView.text = getModName(modInfo)
            selectedModDescriptionTextView.text = getModDescription(modInfo)
            selectedModVersionTextView.text = getModVersion(modInfo)
            selectedModDeveloperTextView.text = getModDeveloper(modInfo)
            local website = getModWebsite(modInfo)
            if website then
                selectedModWebsiteButton.hidden = false
                uiStandardButton:resize(selectedModWebsiteButton, buttonSize)
                uiStandardButton:setClickFunction(selectedModWebsiteButton, function()
                    if not steam:openURL(website) then
                        alertPanel:show(mainMenu.mainView, locale:get("ui_name_steamOverlayDisabled"), locale:get("ui_info_steamOverlayDisabled"), {
                            {
                                isDefault = true,
                                name = locale:get("ui_action_OK"),
                                action = function()
                                    alertPanel:hide()
                                end
                            },
                        })
                    end
                end)
            else
                selectedModWebsiteButton.hidden = true
                uiStandardButton:resize(selectedModWebsiteButton, vec2(0,0))
            end
            local steamURL = getModSteamURL(modInfo)
            if steamURL then
                selectedModSteamPageButton.hidden = false
                uiStandardButton:resize(selectedModSteamPageButton, buttonSize)
                uiStandardButton:setClickFunction(selectedModSteamPageButton, function()
                    if not steam:openURL(steamURL) then
                        alertPanel:show(mainMenu.mainView, locale:get("ui_name_steamOverlayDisabled"), locale:get("ui_info_steamOverlayDisabled"), {
                            {
                                isDefault = true,
                                name = locale:get("ui_action_OK"),
                                action = function()
                                    alertPanel:hide()
                                end
                            },
                        })
                    end
                end)
            else
                selectedModSteamPageButton.hidden = true
                uiStandardButton:resize(selectedModSteamPageButton, vec2(0,0))
            end
            
            if modInfo then
                uiStandardButton:resize(selectedModOpenFilesButton, buttonSize)
                uiStandardButton:setClickFunction(selectedModOpenFilesButton, function()
                    fileUtils.openFile(modInfo.directory)
                end)
            end

            if modInfo and modInfo.isLocal then
                developerUploadButton.hidden = false
                uiStandardButton:resize(developerUploadButton, buttonSize)
                uiStandardButton:setClickFunction(developerUploadButton, function()
                    showModDeveloperMenuFunc(modInfo)
                end)
            else
                developerUploadButton.hidden = true
                uiStandardButton:resize(developerUploadButton, vec2(0,0))
            end
        else
            rightPane.hidden = true
            developerUploadButton.hidden = true
        end
    end
end

local function updateApplyButtonState()
    uiStandardButton:setDisabled(applyButton, next(changes) == nil)
end

local function updateList()

    if modListView then
        leftPane:removeSubview(modListView)
        modListView = nil
    end
    
    local modListViewSize = vec2(leftPane.size.x - 10.0, leftPane.size.y - 10.0)
    modListView = uiScrollView:create(leftPane, modListViewSize, MJPositionInnerLeft)
   --modListView.size = modListViewSize
    modListView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)

    local function modIsEnabled(dirName, isApp)
        if isApp then
            return controller:appModIsEnabled(dirName)
        else
            return enabledWorldMods[dirName]
        end
    end

    local function setModEnabled(dirName, isApp, enabled)
        if not isApp then
            --controller:changeAppModEnabled(dirName, enabled)
        --else
            if enabled then
                enabledWorldMods[dirName] = true
            else
                enabledWorldMods[dirName] = nil
            end
        end
        if not changes[dirName] then
            changes[dirName] = {
                enabled = enabled
            }
        else
            changes[dirName] = nil
        end
        updateApplyButtonState()
    end

    local paddingCounter = 1
    local listItemCounter = 1


    local function addListTitle(title)
        
        local backgroundView = View.new(modListView)
        backgroundView.size = vec2(modListView.size.x - 22, 30)
        backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
        --backgroundView.baseOffset = vec3(0,(-paddingCounter + 1) * 30,0)

        uiScrollView:insertRow(modListView, backgroundView, nil)

        local modTextView = TextView.new(backgroundView)
        modTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        modTextView.font = Font(uiCommon.fontName, 16)

        modTextView.color = vec4(1.0,1.0,1.0,1.0)
        modTextView.text = title

        paddingCounter = paddingCounter + 1
    end

    local function addModEntries(modInfosByDirName, orderedDirNames, isApp)
        for i,dirName in ipairs(orderedDirNames) do
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

            modTextView.color = vec4(1.0,1.0,1.0,1.0)
            modTextView.text = getModName(modInfo)

            local itemIndex = listItemCounter
            uiMenuItem:makeMenuItemBackground(backgroundView, nil, listItemCounter, hoverColor, mouseDownColor, function(wasClick)
                updateSelectedIndex(itemIndex)
            end)

            local typeIcon = ImageView.new(backgroundView)
            typeIcon.size = vec2(20,20)
            typeIcon.relativeView = modTextView
            typeIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            typeIcon.baseOffset = vec3(10,0,1)
            --typeIcon.materialIndex = material.types.ui_standard.index

            
            if isWorldModSelection or isApp then
                local toggleButton = uiStandardButton:create(backgroundView, vec2(26,26), uiStandardButton.types.toggle)
                toggleButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
                toggleButton.baseOffset = vec3(-10, 0, 0)
                uiStandardButton:setToggleState(toggleButton, modIsEnabled(dirName, isApp))
            
                uiStandardButton:setClickFunction(toggleButton, function()
                    setModEnabled(dirName, isApp, uiStandardButton:getToggleState(toggleButton))
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

            
            tableViewItemInfos[listItemCounter] = {
                backgroundView = backgroundView,
                defaultColor = defaultColor,
                modInfo = modInfo,
            }
        
            paddingCounter = paddingCounter + 1
            listItemCounter = listItemCounter + 1
        end
    end

    local modInfosByTypeByDirName = modManager.modInfosByTypeByDirName
    if not isWorldModSelection then
        if modInfosByTypeByDirName.app and next(modInfosByTypeByDirName.app) then
            addListTitle(locale:get("mods_gameMods") .. " - " .. locale:get("mods_gameMods_info"))

            local modInfos = modInfosByTypeByDirName.app
            
            local orderedDirNames = {}
            for k,v in pairs(modInfos) do
                table.insert(orderedDirNames, k)
            end
            local function sortByName(a,b)
                return modInfos[a].name < modInfos[b].name
            end

            table.sort(orderedDirNames, sortByName)

            addModEntries(modInfos, orderedDirNames, true)
            paddingCounter = paddingCounter + 1
        end
    end
    if modInfosByTypeByDirName.world and next(modInfosByTypeByDirName.world) then
        if not isWorldModSelection then
            addListTitle(locale:get("mods_worldMods") .. " - " .. locale:get("mods_worldMods_info"))
        end
        
        local modInfos = modInfosByTypeByDirName.world
            
        local orderedDirNames = {}
        for k,v in pairs(modInfos) do
            table.insert(orderedDirNames, k)
        end
        local function sortByName(a,b)
            return modInfos[a].name < modInfos[b].name
        end
        table.sort(orderedDirNames, sortByName)

        addModEntries(modInfosByTypeByDirName.world, orderedDirNames, false)
    end

    selectedIndex = -1
    if tableViewItemInfos[1] then
        updateSelectedIndex(1)
    else
        updateSelectedIndex(nil)
    end
end

--[[

function mainMenu:showSteamWorkshopInfo()
    steamWorkshopInfo:show(mainMenu, 1.0)
    currentVisibleSubMenu = steamWorkshopInfo
end

function mainMenu:hideSteamWorkshopInfo()
    if not steamWorkshopInfo:hidden() then
        steamWorkshopInfo:hide()
        currentVisibleSubMenu = nil
        return true
    end
    return false
end
]]

local function updateText()
    local titleText = nil
    local subTitleText = nil
    if isWorldModSelection then
        titleText = locale:get("mods_configureWorldMods")
        subTitleText = locale:get("mods_configureWorldMods_info")
    else
        titleText = locale:get("mods_configureGameMods")
        subTitleText = locale:get("mods_configureGameMods_info")
    end
    titleTextView:setText(titleText, material.types.standardText.index)

    descriptionTextA.text = subTitleText
end


function modsMenu:init()
    local backgroundSize = subMenuCommon.size

    local mainView = ModelView.new(mainMenu.mainView)
    modsMenu.mainView = mainView

    
    local sizeToUse = backgroundSize
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.size = backgroundSize
    mainView.hidden = true

    
    --uiSelectionLayout:createForView(mainView)

    
    titleTextView = ModelTextView.new(mainView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,0, 0)

    subMenuCommon:init(mainMenu, modsMenu, mainMenu.mainView.size)

    
    descriptionTextA = TextView.new(mainView)
    descriptionTextA.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    descriptionTextA.baseOffset = vec3(0,-20,0)
    descriptionTextA.relativeView = titleTextView
    descriptionTextA.wrapWidth = mainView.size.x - 80
    descriptionTextA.font = Font(uiCommon.fontName, 16)

    local longButtonSize = buttonSize + vec2(40.0,0.0)

    local steamWorkshopButton = uiStandardButton:create(mainView, longButtonSize)
    steamWorkshopButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    steamWorkshopButton.relativeView = descriptionTextA
    uiStandardButton:setText(steamWorkshopButton, locale:get("mods_findMods"))
    steamWorkshopButton.baseOffset = vec3(-longButtonSize.x * 0.5 - 10, -20, 0)
    uiStandardButton:setClickFunction(steamWorkshopButton, function()
        modsMenu:hide()
        mainMenu:showSteamWorkshopInfo()
    end)
    
    local documentationButton = uiStandardButton:create(mainView, longButtonSize)
    documentationButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    documentationButton.relativeView = descriptionTextA
    uiStandardButton:setText(documentationButton, locale:get("mods_makeMods"))
    documentationButton.baseOffset = vec3(longButtonSize.x * 0.5 + 10, -20, 0)
    uiStandardButton:setClickFunction(documentationButton, function()
        local url = "https://github.com/Majic-Jungle/sapiens-mod-creation/wiki/Getting-Started"
        if not steam:openURL(url) then
            alertPanel:show(mainMenu.mainView, locale:get("ui_name_steamOverlayDisabled"), locale:get("ui_info_steamOverlayDisabled"), {
                {
                    isDefault = true,
                    name = locale:get("ui_action_OK"),
                    action = function()
                        alertPanel:hide()
                    end
                },
            })
        end
    end)

    
    local contentView = View.new(mainView)
    contentView.size = vec2(mainView.size.x - 80, mainView.size.y - 200.0 - 140.0)
    contentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    contentView.baseOffset = vec3(0,-20 - 180.0, 0)
    contentView.relativeView = titleTextView

    leftPane = ModelView.new(contentView)
    leftPane:setModel(model:modelIndexForName("ui_inset_lg_1x1"))
    leftPane.size = vec2(contentView.size.x / 5.0 * 3.0 - 10.0, contentView.size.y)
    local scaleToUsePaneX = leftPane.size.x * 0.5
    local scaleToUsePaneY = leftPane.size.y * 0.5 
    leftPane.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    leftPane.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    
    rightPane = View.new(contentView)
    rightPane.size = vec2(contentView.size.x / 5.0 * 2.0 - 10.0, contentView.size.y)
    rightPane.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)

    --selected
    local modIconBackground = ModelView.new(rightPane)
    modIconBackground:setModel(model:modelIndexForName("ui_inset_sm_1x1"))
    modIconBackground.size = iconSize + vec2(4.0,4.0)
    local modIconScaleToUsePaneX = modIconBackground.size.x * 0.5
    modIconBackground.scale3D = vec3(modIconScaleToUsePaneX,modIconScaleToUsePaneX,modIconScaleToUsePaneX)
    modIconBackground.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

    selectedModIconView = ImageView.new(modIconBackground)
    selectedModIconView.size = iconSize
    selectedModIconView.baseOffset = vec3(0,0,2)
    
    selectedModTitleTextView = TextView.new(rightPane)
    selectedModTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedModTitleTextView.baseOffset = vec3(0,-10,0)
    selectedModTitleTextView.relativeView = modIconBackground
    selectedModTitleTextView.font = Font(uiCommon.fontName, 24)

    selectedModDescriptionTextView = TextView.new(rightPane)
    selectedModDescriptionTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedModDescriptionTextView.baseOffset = vec3(0,0,0)
    selectedModDescriptionTextView.relativeView = selectedModTitleTextView
    selectedModDescriptionTextView.wrapWidth = rightPane.size.x - 40
    selectedModDescriptionTextView.font = Font(uiCommon.fontName, 16)

    selectedModVersionTextView = TextView.new(rightPane)
    selectedModVersionTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedModVersionTextView.baseOffset = vec3(0,-10,0)
    selectedModVersionTextView.relativeView = selectedModDescriptionTextView
    selectedModVersionTextView.font = Font(uiCommon.fontName, 16)

    selectedModDeveloperTextView = TextView.new(rightPane)
    selectedModDeveloperTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedModDeveloperTextView.relativeView = selectedModVersionTextView
    selectedModDeveloperTextView.font = Font(uiCommon.fontName, 16)

    selectedModWebsiteButton = uiStandardButton:create(rightPane, buttonSize)
    selectedModWebsiteButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedModWebsiteButton.relativeView = selectedModDeveloperTextView
    uiStandardButton:setText(selectedModWebsiteButton, locale:get("mods_websiteLink"))
    selectedModWebsiteButton.baseOffset = vec3(0, -20, 0)

    selectedModSteamPageButton = uiStandardButton:create(rightPane, buttonSize)
    selectedModSteamPageButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedModSteamPageButton.relativeView = selectedModWebsiteButton
    uiStandardButton:setText(selectedModSteamPageButton, locale:get("mods_steamLink"))
    
    selectedModOpenFilesButton = uiStandardButton:create(rightPane, buttonSize)
    selectedModOpenFilesButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedModOpenFilesButton.relativeView = selectedModSteamPageButton
    uiStandardButton:setText(selectedModOpenFilesButton, locale:get("mods_filesLink"))
   -- selectedModSteamPageButton.baseOffset = vec3(0, -10, 0)
    
    developerUploadButton = uiStandardButton:create(rightPane, buttonSize)
    developerUploadButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    developerUploadButton.relativeView = selectedModOpenFilesButton
    uiStandardButton:setText(developerUploadButton, locale:get("mods_UploadToSteam"))
    --developerUploadButton.baseOffset = vec3(0, -10, 0)
    developerUploadButton.hidden = true

    

    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        modsMenu:hide()
    end)

    applyButton = uiStandardButton:create(mainView, buttonSize)
    applyButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    applyButton.baseOffset = vec3(0,40, 0)
    uiStandardButton:setDisabled(applyButton, true)
    uiStandardButton:setText(applyButton, locale:get("ui_action_apply"))
    uiStandardButton:setClickFunction(applyButton, function()
        local dataToPreserve = nil
        if isWorldModSelection then
            dataToPreserve = {
                worldCreationState = worldModSelectionCreationStateToPreserve,
                enabledWorldMods = enabledWorldMods,
            }
        end

        local confirmFunction = function()
            if not isWorldModSelection then
                for dirName,info in pairs(changes) do
                    controller:changeAppModEnabled(dirName, info.enabled)
                end
            end
            controller:reloadAll(dataToPreserve)
        end

        local modsEnabled = false
        if isWorldModSelection then
            modsEnabled = enabledWorldMods and next(enabledWorldMods)
        else
            for dirName,info in pairs(changes) do
                if info.enabled then
                    modsEnabled = true
                    break
                end
            end
        end

        if modsEnabled then
            modsMenu:hide()
            mainMenu:showEnableModsWarning(confirmFunction)
        else
            confirmFunction()
        end
    end)

    

end

function modsMenu:loadPreservedEnabledMods(controller_)
    controller = controller_
    local preservedEnabledWorldModsState = nil
    if controller.preservedState then
        preservedEnabledWorldModsState = controller.preservedState.enabledWorldMods
    end
    if preservedEnabledWorldModsState then
        enabledWorldMods = preservedEnabledWorldModsState
        enabledWorldModsApplied = mj:cloneTable(enabledWorldMods)
    end
end

function modsMenu:show(controller_, mainMenu_, showModDeveloperMenuFunc_, delay, isWorldModSelection_, worldModSelectionCreationStateToPreserve_)
    selectedIndex = nil
    isWorldModSelection = isWorldModSelection_
    worldModSelectionCreationStateToPreserve = worldModSelectionCreationStateToPreserve_
    if not modsMenu.mainView then
        controller = controller_
        mainMenu = mainMenu_
        modsMenu:init()
    end
    changes = {}
    updateList()
    updateText()
    updateApplyButtonState()
    showModDeveloperMenuFunc = showModDeveloperMenuFunc_
    subMenuCommon:slideOn(modsMenu, delay)
end

function modsMenu:hide()
    if modsMenu.mainView and (not modsMenu.mainView.hidden) then
        enabledWorldMods = mj:cloneTable(enabledWorldModsApplied)
        subMenuCommon:slideOff(modsMenu)
        return true
    end
    return false
end

function modsMenu:getWorldModsListForWorldCreation()
    return enabledWorldModsApplied
end

function modsMenu:backButtonClicked()
    modsMenu:hide()
end

function modsMenu:hidden()
    return not (modsMenu.mainView and (not modsMenu.mainView.hidden))
end

return modsMenu