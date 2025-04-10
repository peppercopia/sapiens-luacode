local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
--local gameConstants = mjrequire "common/gameConstants"
local eventManager = mjrequire "mainThread/eventManager"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local alertPanel = mjrequire "mainThread/ui/alertPanel"
local locale = mjrequire "common/locale"
local steam = mjrequire "common/utility/steam"

local transitionScreen = mjrequire "mainThread/ui/mainMenu/transitionScreen"
local loadingScreen = mjrequire "mainThread/ui/mainMenu/loadingScreen"
local worldCreation = mjrequire "mainThread/ui/mainMenu/worldCreation"
local modsMenu = mjrequire "mainThread/ui/mainMenu/modsMenu"
local joinMenu = mjrequire "mainThread/ui/mainMenu/joinMenu"
local loadMenu = mjrequire "mainThread/ui/mainMenu/loadMenu"
local credits = mjrequire "mainThread/ui/mainMenu/credits"
local changesPanel = mjrequire "mainThread/ui/mainMenu/changesPanel"
local developerReportsMenu = mjrequire "mainThread/ui/mainMenu/developerReportsMenu"
local optionsMenu = mjrequire "mainThread/ui/mainMenu/optionsMenu"
local modDeveloperMenu = mjrequire "mainThread/ui/mainMenu/modDeveloperMenu"
local bugReportMenu = mjrequire "mainThread/ui/mainMenu/bugReportMenu"
local crashPrompt = mjrequire "mainThread/ui/mainMenu/crashPrompt"
local steamWorkshopInfo = mjrequire "mainThread/ui/mainMenu/steamWorkshopInfo"
local enableModsWarning = mjrequire "mainThread/ui/mainMenu/enableModsWarning"

local bugReporting = mjrequire "mainThread/bugReporting"

local audio = mjrequire "mainThread/audio"
local keyMapping = mjrequire "mainThread/keyMapping"
local clientGameSettings = mjrequire "mainThread/clientGameSettings"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"

local mainMenu = {}

local mainView = nil
local mainBanner = nil
local globeView = nil
local controller = nil

local blackoutView = nil
local splashTitleText = nil
local fmodCreditView = nil
local continueButton = nil

local currentVisibleSubMenu = nil

local mainMenuButtonsView = nil

local mainBannerAnimateOnTimer = 0.0
local mainBannerAnimateOffTimer = 0.0

local mainBannerBasePosTopLeft = nil

local hasSlidOn = false
local hasDisplayedCrashPromptIfNeeded = false
local worldList = nil

--local publicUnstablePasswordPanel = nil

local function slideOn()
    if not hasSlidOn then
        
        if not hasDisplayedCrashPromptIfNeeded then
            if not bugReporting:exitedCleanlyLastRun() then
                crashPrompt:show(controller, bugReportMenu, mainMenu, 0.0)
            end
        end

        hasSlidOn = true
        mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y - mainBanner.size.y, 0)
        mainBannerAnimateOnTimer = 0.0
        mainBanner.hidden = false
        audio:playUISound("audio/sounds/ui/stone.wav")
        mainBanner.update = function(dt_)
            mainBannerAnimateOnTimer = mainBannerAnimateOnTimer + dt_
            local fraction = mainBannerAnimateOnTimer * 2.0
            fraction = math.pow(fraction, 0.6)
            if fraction < 1.0 then
                mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y - mainBanner.size.y * (1.0 - fraction), 0)
            else
                mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y, 0)
                uiSelectionLayout:setActiveSelectionLayoutView(mainMenuButtonsView)
                mainBanner.update = nil
            end
        end
    end
end

local function slideOff(finishedFunction)
    if hasSlidOn then
        mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y, 0)
        mainBannerAnimateOffTimer = 0.0
        mainBanner.hidden = false
        audio:playUISound("audio/sounds/ui/stone.wav")
        mainBanner.update = function(dt_)
            mainBannerAnimateOffTimer = mainBannerAnimateOffTimer + dt_
            local fraction = mainBannerAnimateOffTimer * 2.0
            fraction = math.pow(fraction, 0.6)
            if fraction < 1.0 then
                mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y - mainBanner.size.y * (fraction), 0)
            else
                mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y - mainBanner.size.y, 0)
                mainBanner.update = nil
                mainBanner.hidden = true
                uiSelectionLayout:removeActiveSelectionLayoutView(mainMenuButtonsView)
                if finishedFunction then
                    finishedFunction()
                end
            end
        end
    end
end

function mainMenu:hideCurrentMenu()
    if currentVisibleSubMenu then
        currentVisibleSubMenu:hide()
        return true
    end
    return false
end

function mainMenu:setCurrentVisibleSubmenu(newVisibleMenu)
    currentVisibleSubMenu = newVisibleMenu
end


local function showChangesPanel(showMajorNotes)
    if changesPanel:hidden() then
        local delay = 0.0
        if mainMenu:hideCurrentMenu() then
            delay = 1.0
        end
        changesPanel:show(controller, mainMenu, delay, showMajorNotes)
        currentVisibleSubMenu = changesPanel
    end
end

--[[local function showUnstableBetaClosedPanel()
    --local currentBetaName = steam:getCurrentBetaName()
    --if currentBetaName and currentBetaName == "public-beta-unstable" then
        if not publicUnstablePasswordPanel then
            publicUnstablePasswordPanel = mjrequire "mainThread/ui/mainMenu/publicUnstablePasswordPanel"
        end
        
        if publicUnstablePasswordPanel:hidden() then
            local delay = 0.0
            if mainMenu:hideCurrentMenu() then
                delay = 1.0
            end
            publicUnstablePasswordPanel:show(controller, mainMenu, delay)
            currentVisibleSubMenu = publicUnstablePasswordPanel
        end
        return true
    --end
   -- return false
end]]

local function showChangesPanelForLaunchIfNotSeen()
    if changesPanel.displayReleaseNotesVersionIdentifier then
        local notesKey = "hasDisplayedNotes_" .. changesPanel.displayReleaseNotesVersionIdentifier
        local minorNotesKey = "hasDisplayedMinorNotes_" .. changesPanel.displayReleaseNotesMinorVersionIdentifier
        if controller:getHasEverLoadedWorld() then
            local hasDisplayedNotes = controller.appDatabase:dataForKey(notesKey)
            if not hasDisplayedNotes then
                controller.appDatabase:setDataForKey(true, notesKey)
                controller.appDatabase:setDataForKey(true, minorNotesKey)
                showChangesPanel(true)
            elseif changesPanel.shouldDisplayMinorNotesOnStartup then
                local hasDisplayedMinorNotes = controller.appDatabase:dataForKey(minorNotesKey)
                if not hasDisplayedMinorNotes then
                    controller.appDatabase:setDataForKey(true, minorNotesKey)
                    showChangesPanel(false)
                end
            end
        else
            controller.appDatabase:setDataForKey(true, notesKey)
            controller.appDatabase:setDataForKey(true, minorNotesKey)
        end
    end
end

local function cancelAction()
    if mainBanner.hidden then 
        slideOn()
        --if (not showUnstableBetaClosedPanel()) then
            showChangesPanelForLaunchIfNotSeen()
       -- end
    else
        if currentVisibleSubMenu then
            currentVisibleSubMenu:backButtonClicked()
        end
    end
end

local keyMap = {
    [keyMapping:getMappingIndex("menu", "back")] = function(isDown, isRepeat) 
        if not alertPanel:hidden() then
            return false
        end
        if isDown and not isRepeat then 
            cancelAction()
        end
        return true 
    end,
}

local function keyChanged(isDown, code, modKey, isRepeat)
    if keyMap[code]  then
        return keyMap[code](isDown, isRepeat)
    end
end



local function worldCreationBackButtonFunc()
    --hideCreateUI()
    worldCreation:hide()
    hasSlidOn = false
    slideOn()
    globeView:setSeedString("test") --todo use seed from latest save
end

local function worldCreationConfirmButtonFunc(newWorldProperties)
    --mj:error("worldCreationConfirmButtonFunc:", newWorldProperties)
    transitionScreen:fadeIn(function()
        bugReportMenu:cleanup()
        controller:newWorld(newWorldProperties.worldName, newWorldProperties.seed, newWorldProperties.customOptions, newWorldProperties.enabledWorldMods)
        --loadingScreen:display()
        worldCreation:hide()
        transitionScreen:fadeOut(nil)
        controller.mainView:removeSubview(mainView)
        mainView = nil
    end)
end

local function reloadWorldList()
    
    local orderedWorlds = controller.appDatabase:dataForKey("orderedWorldInfos")
    local worldSaveFileListOutOfOrder =  controller:getWorldSaveFileList()
    worldList = {}
    local foundInfosByWorldID = {}

    if orderedWorlds then
        for i = 1, #orderedWorlds do
            local worldID = orderedWorlds[i].worldID
            local sessionIndex = orderedWorlds[i].sessionIndex

            for j = 1, #worldSaveFileListOutOfOrder do
                if worldID == worldSaveFileListOutOfOrder[j].worldID then
                    local foundInfo = foundInfosByWorldID[worldID]
                    if foundInfo then
                        table.insert(foundInfo.sessions, {
                            sessionIndex = sessionIndex or 0,
                        })
                    else
                        foundInfo = mj:cloneTable(worldSaveFileListOutOfOrder[j])
                        foundInfo.sessions = {
                            {
                                sessionIndex = sessionIndex or 0,
                            }
                        }
                        foundInfosByWorldID[worldID] = foundInfo
                        table.insert(worldList, foundInfo)
                    end
                end
            end
        end
    end

    for i=1,#worldSaveFileListOutOfOrder do
        if not foundInfosByWorldID[worldSaveFileListOutOfOrder[i].worldID] then
            local foundInfo = mj:cloneTable(worldSaveFileListOutOfOrder[i])
            foundInfo.sessions = {
                {
                    sessionIndex = 0,
                }
            }
            table.insert(worldList, foundInfo)
        end
    end

    if continueButton then
        if worldList[1] then
            uiStandardButton:setDisabled(continueButton, false)
        else
            uiStandardButton:setDisabled(continueButton, true)
        end
    end
end

local function joinConfirmButtonFunc()
    transitionScreen:fadeIn(function()
        bugReportMenu:cleanup()
        controller:joinWorld(clientGameSettings.values.joinWorldIP, clientGameSettings.values.joinWorldPort)
        controller:addToSavedIPConnectionsList(clientGameSettings.values.joinWorldIP, clientGameSettings.values.joinWorldPort, clientGameSettings.values.joinWorldServerName)
        loadingScreen:display()
        transitionScreen:fadeOut(nil)
        controller.mainView:removeSubview(mainView)
        mainView = nil
    end)
end

function mainMenu:hideForEngineWorldLoad()
    transitionScreen:fadeIn(function()
        bugReportMenu:cleanup()
        loadingScreen:display()
        transitionScreen:fadeOut(nil)
        controller.mainView:removeSubview(mainView)
        mainView = nil
    end)
end

local function loadMainMenuView()
    mainView = View.new(controller.mainView)
    mainMenu.mainView = mainView
    mainView.size = controller.mainView.size

    mainBannerBasePosTopLeft = vec2(mainView.size.x * 0.06,-100)
    
    subMenuCommon:initSizes(mainView.size)

    mainView.keyChanged = keyChanged

    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuCancel", function(isDown)
        if not alertPanel:hidden() then
            return false
        end
        if isDown then
            cancelAction()
            return true
        end
    end)

    --local sunGlowImage = nil

    fmodCreditView = View.new(mainView)
    mainMenu.fmodCreditView = fmodCreditView
    fmodCreditView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    fmodCreditView.baseOffset = vec3(-20,-20,0)
    fmodCreditView.size = vec2(200, 60)

    local fmodCreditText = TextView.new(fmodCreditView)
    mainMenu.fmodCreditText = fmodCreditText
    fmodCreditText.font = Font(uiCommon.fontName, 14)
    fmodCreditText.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    fmodCreditText.color = mj.textColor
    fmodCreditText.text = locale:get("misc_fmodCredit")

    local fmodImage = ImageView.new(fmodCreditView)
    mainMenu.fmodImage = fmodImage
    fmodImage.imageTexture = MJCache:getTexture("img/fmod.png")
    fmodImage.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    fmodImage.relativeView = fmodCreditText
    fmodImage.size = vec2(128,38)
    --fmodImage.baseOffset = vec3(-20,20,0)
    fmodImage.color = vec4(1.0,1.0,1.0,1.0)
    

    local backgroundFadeTimer = 0.0
    mainView.update = function(dt)
        backgroundFadeTimer = backgroundFadeTimer + dt
        --sunGlowImage.alpha = backgroundFadeTimer / 8.0
        --local offset = backgroundFadeTimer / 16.0
        --sunGlowImage.baseOffset = vec3(2600 + (1.0 - offset) * (1.0 - offset) * 800.0,500, 0)
        splashTitleText.baseOffset = splashTitleText.baseOffset + vec3(dt * -3.0,dt * -8.0,dt * 350.0)
        if not blackoutView.hidden and backgroundFadeTimer > 0.5 then
            blackoutView.alpha = blackoutView.alpha - dt * 0.25
            if blackoutView.alpha <= 0.0 then
                blackoutView.alpha = 0.0
                blackoutView.hidden = true
            end
        end

        if hasSlidOn then
            if not splashTitleText.hidden then
                splashTitleText.alpha = splashTitleText.alpha - dt * 16.0
                if splashTitleText.alpha <= 0.0 then
                    splashTitleText.alpha = 0.0
                    splashTitleText.hidden = true
                end
            end
        end

        if backgroundFadeTimer > 6.0 then
            splashTitleText.hidden = true

            if not fmodCreditView.hidden then
                fmodCreditView.alpha = fmodCreditView.alpha - dt * 0.5
                if fmodCreditView.alpha <= 0.0 then
                    fmodCreditView.hidden = true
                end
            end
            --mainView.update = nil
            if not hasSlidOn then
                slideOn()
                --if not showUnstableBetaClosedPanel() then
                    showChangesPanelForLaunchIfNotSeen()
                --end
            end


            if backgroundFadeTimer > 16.0 then
                mainView.update = nil
                fmodCreditView.hidden = true
            end
        end
    end

    --[[local screenRatio = controller.virtualSize.x / controller.virtualSize.y
    local imageRatio = (1920.0 / 1080.0)]]

    --[[local backgroundImageSize = mainView.size


    if imageRatio < screenRatio then
        backgroundImageSize.x = screenRatio * backgroundImageSize.y
        backgroundImageSize.y = backgroundImageSize.x / imageRatio
    else
        backgroundImageSize.y =  backgroundImageSize.x / screenRatio
        backgroundImageSize.x =  backgroundImageSize.y * imageRatio
    end]]


   --[[ local backgroundImage = ImageView.new(mainView)
    backgroundImage.imageTexture = MJCache:getTexture("img/mainMenuBackground.jpg")
    backgroundImage.size = backgroundImageSize
    backgroundImage.color = vec4(0.0,0.0,0.0,1.0)]]
    
    --[[local backgroundFadeTimer = 0.0

    backgroundImage.update = function(dt)
        backgroundFadeTimer = backgroundFadeTimer + dt

        if backgroundFadeTimer < 8.0 then
            local fraction = backgroundFadeTimer / 8.0
            fraction = 1.0 - (1.0 - fraction) * (1.0 - fraction)
            local brightness = fraction
            backgroundImage.color = vec4(brightness,brightness,brightness,1.0)
        else
            backgroundImage.color = vec4(1.0,1.0,1.0,1.0)
            if backgroundFadeTimer > 9.0 and mainBanner.hidden then
                slideOn()
                backgroundImage.update = nil
            end
        end
    end]]
    
        

    --[[sunGlowImage = ImageView.new(mainView)
    sunGlowImage.imageTexture = MJCache:getTexture("img/sunGlow.png")
    sunGlowImage.size = vec2(4000,4000)
    sunGlowImage.baseOffset = vec3(2800,500, 0)
    sunGlowImage.alpha = 0.0
    sunGlowImage.masksEvents = false]]

    globeView = GlobeView.new(mainView)
    mainMenu.globeView = globeView
    local globeViewSize = mainView.size.y * 2.2
    globeView.size = vec2(globeViewSize,globeViewSize)
    globeView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    globeView.baseOffset = vec3(mainView.size.x * 0.25,0,-globeViewSize * 0.6)
    globeView.initialOffsetSpeed = 0.3
    globeView:setSeedString("test") --todo use seed from latest save

    
    splashTitleText = ModelView.new(mainView)
    mainMenu.splashTitleText = splashTitleText
    splashTitleText:setModel(model:modelIndexForName("sapiensLogoTextWithIcon"))--, {
    --    default = material.types.ui_background.index
   -- })
    local splashTitleTextScaleToUse = 200
    splashTitleText.scale3D = vec3(splashTitleTextScaleToUse,splashTitleTextScaleToUse,splashTitleTextScaleToUse)
    splashTitleText.size = vec2(splashTitleTextScaleToUse * 2.0,splashTitleTextScaleToUse * 2.0)
    splashTitleText.baseOffset = vec3(0.0,0.0,-50.0)

    mainBanner = ModelView.new(mainView)
    mainMenu.mainBanner = mainBanner
    mainBanner:setModel(model:modelIndexForName("ui_bg_monolith"))
    local scaleToUse = 540
    local mainBannerWidth = scaleToUse * 0.8
    mainBanner.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse)
    mainBanner.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    mainBanner.size = vec2(mainBannerWidth,scaleToUse * 2.0)
    mainBanner.hidden = true
    mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y, 0)

    local titleText = ModelTextView.new(mainBanner)
    mainMenu.titleText = titleText
    titleText.font = Font(uiCommon.sapiensTitleFontName, 72)
    titleText:setText(string.lower(mj.gameName), material.types.standardText.index)
    titleText.baseOffset = vec3(0, -200, 0)
    titleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

    
    local versionButton = uiStandardButton:create(mainBanner, vec2(200,20), uiStandardButton.types.link)
    mainMenu.versionButton = versionButton
    versionButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    versionButton.relativeView = titleText
    versionButton.baseOffset = vec3(0,-10,0)
    local versionString = locale:get("misc_version") .. ": " .. controller:getVersionString()
    if controller:getIsDemo() then
        versionString = versionString .. string.format(" (%s)", locale:get("misc_demo"))
    end
    uiStandardButton:setText(versionButton, versionString)
    uiStandardButton:setClickFunction(versionButton, function()
        --if not showUnstableBetaClosedPanel(false) then
            showChangesPanel(false)
        --end
    end)


    local logo = ModelView.new(mainBanner)
    mainMenu.logo = logo
   -- logo:setRenderTargetBacked(true)
    logo:setModel(model:modelIndexForName("hand"))
    local logoHalfSize = 60
    logo.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
    logo.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)
    logo.size = vec2(logoHalfSize,logoHalfSize) * 2.0
    logo.baseOffset = vec3(0, -10, 0)
    logo.relativeView = titleText

    
    blackoutView = ColorView.new(mainView)
    mainMenu.blackoutView = blackoutView
    blackoutView.color = vec4(0.0,0.0,0.0,1.0)
    blackoutView.size = controller.screenSize
    blackoutView.masksEvents = false

    reloadWorldList()

    local function loadConfirmButtonFunc(worldIDToLoad, sessionIndex, createNewSession)
        transitionScreen:fadeIn(function()
            bugReportMenu:cleanup()
            if createNewSession then
                local sessionIndexKey = "sessionCounter_" .. worldIDToLoad
                local savedSessionIndex = controller.appDatabase:dataForKey(sessionIndexKey)
                sessionIndex = savedSessionIndex or 1
            end
            controller:loadWorld(worldIDToLoad, sessionIndex)
            loadingScreen:display()
            transitionScreen:fadeOut(nil)
            controller.mainView:removeSubview(mainView)
            mainView = nil
        end)
    end

    local function showModDeveloperMenuFunc(modInfo)
        modsMenu:hide()
        modDeveloperMenu:show(controller, mainMenu, modInfo)
        currentVisibleSubMenu = modDeveloperMenu
    end

    local hasLoadButton =  (worldList and #worldList > 0)
    mainMenu.hasLoadButton = hasLoadButton

    mainMenuButtonsView = View.new(mainBanner)
    mainMenu.mainMenuButtonsView = mainMenuButtonsView
    mainMenuButtonsView.relativeView = titleText
    mainMenuButtonsView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    mainMenuButtonsView.baseOffset = vec3(0,-60,0)
    uiSelectionLayout:createForView(mainMenuButtonsView)

    local buttonOffset = 0.0
    local buttonPadding = 4.0
    local buttonSize = vec2(220.0,50.0)

    
    mainMenu.buttons = {}

    local function addButton(title, clickFunction)
        local button = uiStandardButton:create(mainMenuButtonsView, buttonSize, uiStandardButton.types.title_10x3)
        table.insert(mainMenu.buttons, button)
        button.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
        button.baseOffset = vec3(0,buttonOffset,0)
        uiStandardButton:setText(button, title)
        uiStandardButton:setClickFunction(button, clickFunction)

        buttonOffset = buttonOffset - buttonSize.y - buttonPadding
        return button
    end


    if hasLoadButton then
        continueButton = addButton(locale:get("ui_action_continue"), function()
            if worldList[1] then
                local worldIDToLoad = worldList[1].worldID
                local sessionIndex = nil
                if worldList[1].sessions and worldList[1].sessions[1] then
                    sessionIndex = worldList[1].sessions[1].sessionIndex
                end
                transitionScreen:fadeIn(function()
                    transitionScreen:fadeOut(nil)
                    bugReportMenu:cleanup()
                    controller:loadWorld(worldIDToLoad, sessionIndex, false)
                    --loadingScreen:display()
                    transitionScreen:fadeOut(nil)
                    controller.mainView:removeSubview(mainView)
                    mainView = nil
                end)
            end
        end)

        uiSelectionLayout:addView(mainMenuButtonsView, continueButton)
        uiSelectionLayout:setSelection(mainMenuButtonsView, continueButton)
        --uiStandardButton:setSelected(button, true)
        
        local savesButton = addButton(locale:get("ui_name_saves"), function()
            if loadMenu:hidden() then
                --uiSelectionLayout:setSelection(mainMenuButtonsView, nil)
                local delay = 0.0
                if mainMenu:hideCurrentMenu() then
                    delay = 1.0
                end
                loadMenu:show(controller, mainMenu, worldList, loadConfirmButtonFunc, delay)
                currentVisibleSubMenu = loadMenu
            end
        end)
        uiSelectionLayout:addView(mainMenuButtonsView, savesButton)
    end
    
    local createWorldButton = addButton(locale:get("ui_action_createWorld"), function()
        mainMenu:hideCurrentMenu()
        slideOff(function()
            worldCreation:display(worldCreationConfirmButtonFunc, worldCreationBackButtonFunc, globeView, nil)
        end)
    end)

    uiSelectionLayout:addView(mainMenuButtonsView, createWorldButton)
    if not hasLoadButton then
        uiSelectionLayout:setSelection(mainMenuButtonsView, createWorldButton)
    end

    local joinButton = addButton(locale:get("ui_action_multiplayer"), function()
        if joinMenu:hidden() then
            local delay = 0.0
            if mainMenu:hideCurrentMenu() then
                delay = 1.0
            end
            joinMenu:show(controller, mainMenu, joinConfirmButtonFunc, delay)
            currentVisibleSubMenu = joinMenu
        end
    end)
    uiSelectionLayout:addView(mainMenuButtonsView, joinButton)

    local optionsButton = addButton(locale:get("settings_options"), function()
        if optionsMenu:hidden() then
            local delay = 0.0
            if mainMenu:hideCurrentMenu() then
                delay = 1.0
            end
            optionsMenu:show(controller, mainMenu, delay)
            currentVisibleSubMenu = optionsMenu
        end
    end)
    uiSelectionLayout:addView(mainMenuButtonsView, optionsButton)
    
    modsMenu:loadPreservedEnabledMods(controller)

    local modsButton = addButton(locale:get("menu_mods"), function()
        if modsMenu:hidden() then
            local delay = 0.0
            if mainMenu:hideCurrentMenu() then
                delay = 1.0
            end
            modsMenu:show(controller, mainMenu, showModDeveloperMenuFunc, delay, false, nil)
            currentVisibleSubMenu = modsMenu
        end
    end)
    uiSelectionLayout:addView(mainMenuButtonsView, modsButton)

    
    local creditsButton = addButton(locale:get("ui_action_credits"), function()
        if credits:hidden() then
            local delay = 0.0
            if mainMenu:hideCurrentMenu() then
                delay = 1.0
            end
            credits:show(controller, mainMenu, delay)
            currentVisibleSubMenu = credits
        end
    end)
    uiSelectionLayout:addView(mainMenuButtonsView, creditsButton)

    local exitButton = addButton(locale:get("ui_action_exit"), function()
        controller:exitToDesktop()
    end)
    uiSelectionLayout:addView(mainMenuButtonsView, exitButton)

    buttonOffset = buttonOffset - buttonSize.y - buttonPadding

    --[[local reportBugButton = addButton(locale:get("ui_action_sendFeedback"), function()
        if bugReportMenu:hidden() then
            local delay = 0.0
            if hideCurrentMenu() then
                delay = 1.0
            end
            bugReportMenu:show(controller, mainMenu, delay)
            currentVisibleSubMenu = bugReportMenu
        end
    end)
    uiSelectionLayout:addView(mainMenuButtonsView, reportBugButton)]]

    if controller:getIsDemo() then
        local wishlistButton = addButton(locale:get("ui_action_wishlistNow"), function()
            steam:openURL("https://store.steampowered.com/app/1060230/Sapiens/")
        end)
        uiSelectionLayout:addView(mainMenuButtonsView, wishlistButton)
    end

    if controller:getIsDevelopmentBuild() and (not controller:getIsDemo()) then
        local importReportsButton = addButton(locale:get("ui_action_importReports"), function()
            if developerReportsMenu:hidden() then
                local delay = 0.0
                if mainMenu:hideCurrentMenu() then
                    delay = 1.0
                end
                developerReportsMenu:show(controller, mainMenu, function(worldIDToLoad)
                    controller:getDetailedWorldSessionInfo(worldIDToLoad, 0, true) --trigger a migration of player ids
                    loadConfirmButtonFunc(worldIDToLoad, nil, false)
                end, delay)
                currentVisibleSubMenu = developerReportsMenu
            end
        end)
        uiSelectionLayout:addView(mainMenuButtonsView, importReportsButton)
    end

    buttonOffset = buttonOffset - buttonSize.y - buttonPadding

    local circleButtonSize = vec2(40,40)


    local discordButton = uiStandardButton:create(mainMenuButtonsView, circleButtonSize, uiStandardButton.types.circleIcon)
    mainMenu.discordButton = discordButton
    discordButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    discordButton.baseOffset = vec3(-22,buttonOffset,0)
    uiStandardButton:setIconModel(discordButton, "icon_discord")
    uiToolTip:add(discordButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_discord"), nil, nil, nil, discordButton)
    uiStandardButton:setClickFunction(discordButton, function()
        --steam:openURL("https://discord.gg/VAkYw2r")
        fileUtils.openFile("https://discord.gg/VAkYw2r")
    end)
    
    local redditButton = uiStandardButton:create(mainMenuButtonsView, circleButtonSize, uiStandardButton.types.circleIcon)
    mainMenu.redditButton = redditButton
    redditButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    redditButton.baseOffset = vec3(22,buttonOffset,0)
    uiStandardButton:setIconModel(redditButton, "icon_reddit")
    uiToolTip:add(redditButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("misc_reddit"), nil, nil, nil, redditButton)
    uiStandardButton:setClickFunction(redditButton, function()
        --steam:openURL("https://twitter.com/playsapiens")
        fileUtils.openFile("https://www.reddit.com/r/sapiens/")
    end)

    worldCreation:init(controller, modsMenu, mainMenu, modDeveloperMenu)
    loadingScreen:init(controller)
    transitionScreen:init(controller)

    
--[[
    local testMatrix = mjm.mat4Ortho(-100.0, 100.0, -50.0, 50.0, 0.0, 1.0)
    mj:log("ortho test:", testMatrix)

    local lookAtTest = mjm.mat4LookAt(vec3(0.0,2.0,1.0), vec3(0.0,1.0,0.5), vec3(0.325, 1.0, 0.23))
    mj:log("lookAtTest:", lookAtTest)

    
    local matMultiplyTest = testMatrix * lookAtTest
    mj:log("matMultiplyTest:", matMultiplyTest)

    local multiplyTest = mjm.vec4xMat4(vec4(1.0,2.0,3.0,1.0), lookAtTest)
    mj:log("multiplyTest:", multiplyTest)

    
    local modelViewMat = mjm.mat4LookAt(vec3(0.5,0,1), vec3(0.5,0,0), vec3(0,1,0))
    mj:log("modelViewMat:", modelViewMat)
    local testVec = vec3(0.5,0.5,0.5)
    local textResult = mjm.mat4xVec4(modelViewMat, vec4(testVec.x, testVec.y, testVec.z, 1.0))
    mj:log("textResult:", textResult)]]


end

function mainMenu:worldWasDeleted()
    reloadWorldList()
    loadMenu:loadWorldsList(worldList)
    --uiSelectionLayout:setActiveSelectionLayoutView(mainMenuButtonsView)
end

function mainMenu:load(controller_)
    controller = controller_
    if controller:getGameState() == GameStateLoading then
        loadingScreen:init(controller)
        loadingScreen:display()
    else
        loadMainMenuView()
        --mj:log("mainMenu:load")
        
        local currentBetaName = steam:getCurrentBetaName()
        if currentBetaName then
            mj:log("current beta:", currentBetaName)
        end

        if controller.preservedState then
            if controller.preservedState.worldCreationState then
                mainView.update = nil
                blackoutView.hidden = true
                splashTitleText.hidden = true
                fmodCreditView.hidden = true

                globeView.initialOffsetSpeed = 3.0

                worldCreation:display(worldCreationConfirmButtonFunc, worldCreationBackButtonFunc, globeView, controller.preservedState.worldCreationState, controller.preservedState.enabledWorldMods)
            elseif controller.preservedState.demoComplete then
                --mj:log("demoComplete")
                if mainBanner.hidden then 
                    slideOn()
                end
                --showDemoPanelIfIsDemo(true)
            end
        end
    end
end

function mainMenu:showBugReportMenu()
    if bugReportMenu:hidden() then
        local delay = 0.0
        if mainMenu:hideCurrentMenu() then
            delay = 1.0
        end
        bugReportMenu:show(controller, mainMenu, delay, false)
        currentVisibleSubMenu = bugReportMenu
    end
end

function mainMenu:restoreMenuSelection()
    uiSelectionLayout:setActiveSelectionLayoutView(mainMenuButtonsView)
    --uiSelectionLayout:restorePreviousSelection(mainMenuButtonsView)
end

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

function mainMenu:showEnableModsWarning(completionFunction)
    enableModsWarning:show(mainMenu, 1.0, completionFunction)
    currentVisibleSubMenu = enableModsWarning
end

function mainMenu:hideEnableModsWarning()
    if not enableModsWarning:hidden() then
        enableModsWarning:hide()
        currentVisibleSubMenu = nil
        return true
    end
    return false
end

function mainMenu:presentConnectionLostAlert(disconnectionWasConnected, disconnectionWasRejection, rejectionReason, rejectionContext)
    if mainBanner.hidden then 
        slideOn()
        local title = nil
        local message = nil

        if disconnectionWasRejection then
            if rejectionReason == "bad_player_name_or_id" then
                title = locale:get("serverRejectionTitle_bad_player_name_or_id")
                message = locale:get("serverRejectionMessage_bad_player_name_or_id")
            elseif rejectionReason == "client_too_old" then
                title = locale:get("serverRejectionTitle_client_too_old")
                message = locale:get("serverRejectionMessage_client_too_old", {requiredVersion=rejectionContext,localVersion=controller:getRawVersionString()})
            elseif rejectionReason == "steam_authentication_failed" then
                title = locale:get("serverRejectionTitle_steam_authentication_failed")
                message = locale:get("serverRejectionMessage_steam_authentication_failed")
            elseif rejectionReason == "server_authentication_failed" then
                title = locale:get("serverRejectionTitle_server_authentication_failed")
                message = locale:get("serverRejectionMessage_server_authentication_failed")
            elseif rejectionReason == "client_too_new" then
                title = locale:get("serverRejectionTitle_client_too_new")
                message = locale:get("serverRejectionMessage_client_too_new", {requiredVersion=rejectionContext,localVersion=controller:getRawVersionString()})
            else
                title = locale:get("serverRejectionTitle_generic")
                message = locale:get("serverRejectionMessage_generic", {rejectionReason=rejectionReason,rejectionContext=rejectionContext})
            end

            alertPanel:show(mainView, title, message, {
                {
                    isCancel = true,
                    name = locale:get("ui_action_cancel"),
                    action = function()
                        alertPanel:hide()
                    end
                }
            })
        else
            if not disconnectionWasConnected then
                title = locale:get("misc_serverNotFound")
                message = locale:get("misc_serverNotFound_info")
            else
                title = locale:get("misc_connectionLost")
                message = locale:get("misc_connectionLost_info")
            end

            alertPanel:show(mainView, title, message, {
                {
                    isDefault = true,
                    name = locale:get("ui_action_retry"),
                    action = function()
                        alertPanel:hide()
                        joinConfirmButtonFunc()
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
        end

    end
end

return mainMenu