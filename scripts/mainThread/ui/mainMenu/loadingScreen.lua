local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local vec4 = mjm.vec4

local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local material = mjrequire "common/material"


local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
--local uiTribeView = mjrequire "mainThread/ui/uiCommon/uiTribeView"
--local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"
local alertPanel = mjrequire "mainThread/ui/alertPanel"

local loadingScreen = {}

local controller = nil
local mainView = nil

local background = nil
local backgroundImageSize = nil


local loadingString = " "
local dotCount = 3
local dotCounter = 0.0
local animationTimer = 0.0
local backgroundFadeUp = 0.0

local loadingTextView = nil
local welcomeMessageTextView = nil

local hoverColor = mj.highlightColor * 0.8
local mouseDownColor = mj.highlightColor * 0.6

local loadState = nil
local loadStateUserData = nil


local function updateLoadString(newLoadStateString)
    loadingString = newLoadStateString
    loadingTextView.text = loadingString
    dotCount = 3
    dotCounter = 0.0
end

function loadingScreen:init(controller_)
    controller = controller_

    mainView = View.new(controller.mainView)
    mainView.size = controller.mainView.size
    mainView.hidden = true

    
    local screenRatio = controller.virtualSize.x / controller.virtualSize.y
    local imageRatio = (1920.0 / 1080.0)

    backgroundImageSize = mainView.size

    if imageRatio < screenRatio then
        backgroundImageSize.x = screenRatio * backgroundImageSize.y
        backgroundImageSize.y = backgroundImageSize.x / imageRatio
    else
        backgroundImageSize.y =  backgroundImageSize.x / screenRatio
        backgroundImageSize.x =  backgroundImageSize.y * imageRatio
    end

    --background = ColorView.new(mainView)
    --background.color = mjm.vec4(0.0,0.0,0.0,1.0)
    background = ImageView.new(mainView)
    background.imageTexture = MJCache:getTexture("img/loadingBackground_0.5.0.jpg")
    background.size = backgroundImageSize
    background.color = vec4(0.0,0.0,0.0,1.0)
    
    loadingTextView = TextView.new(mainView)
    loadingTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    loadingTextView.font = Font(uiCommon.fontName, 24)
    loadingTextView.text = loadingString
    loadingTextView.alpha = 0.0
    loadingTextView.color = vec4(1.0,1.0,1.0,1.0)

    welcomeMessageTextView = TextView.new(mainView)
    welcomeMessageTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    welcomeMessageTextView.relativeView = loadingTextView
    welcomeMessageTextView.font = Font(uiCommon.fontName, 18)
    welcomeMessageTextView.text = ""
    welcomeMessageTextView.alpha = 0.0
    welcomeMessageTextView.color = vec4(1.0,1.0,1.0,1.0)

    mainView.update = function(dt)
        local gameState = controller:getGameState()
        if gameState == GameStateLoadedRunning then
            loadingTextView.hidden = true
            welcomeMessageTextView.hidden = true
            --controller.mainView:removeSubview(mainView)
           -- mainView = nil
            animationTimer = animationTimer + dt * 2.0

            if animationTimer < 2.0 then
                --local brightness = animationTimer * 0.5
                --background.color = mjm.vec4(brightness,brightness,brightness,1.0)
                

                if animationTimer > 1.0 then
                    background.alpha = 1.0 - (animationTimer - 1.0)
                end
            else
                controller.mainView:removeSubview(mainView)
                mainView = nil
            end
        elseif gameState == GameStateLoading then
            --[[if loadingText.alpha < 1.0 then
                loadingText.alpha = loadingText.alpha + dt * 0.5
                if loadingText.alpha > 1.0 then
                    loadingText.alpha = 1.0
                end
            end]]
            if backgroundFadeUp < 1.0 then
                backgroundFadeUp = backgroundFadeUp + (1.0 - backgroundFadeUp) * dt * 0.1
                local backgroundFadeUpToUse = mjm.clamp(backgroundFadeUp - 0.1, 0.0, 1.0) * 0.67
                background.color = vec4(backgroundFadeUpToUse,backgroundFadeUpToUse,backgroundFadeUpToUse,1.0)
                background.size = backgroundImageSize * (1.0 + backgroundFadeUpToUse * 0.1)

                welcomeMessageTextView.alpha = mjm.clamp(backgroundFadeUpToUse * 2.0, 0.0, 1.0)
                loadingTextView.alpha = mjm.clamp(backgroundFadeUpToUse * 2.0, 0.0, 1.0)
            end
            dotCounter = dotCounter + dt
            if dotCounter > 1.0 then
                dotCounter = 0.0
                if dotCount == 0 then
                    dotCount = 1
                    loadingTextView.text = loadingString .. "."
                elseif dotCount == 1 then
                    dotCount = 2
                    loadingTextView.text = loadingString .. ".."
                elseif dotCount == 2 then
                    dotCount = 3
                    loadingTextView.text = loadingString .. "..."
                else
                    dotCount = 0
                    loadingTextView.text = loadingString
                end
            end
        end
    end

    if loadState then
        loadingScreen:setLoadState(loadState, loadStateUserData)
    end

end


function loadingScreen:display()
    mainView.hidden = false
end

local loadStateStrings = {
    connecting_to_server = locale:get("loading_connecting"),
    connected_to_server = locale:get("loading_connected"),
}

function loadingScreen:setLoadState(newLoadState, userData) --called by engine

    loadState = newLoadState
    loadStateUserData = userData

    if not loadingTextView then
        return
    end

    local loadStateString = loadStateStrings[newLoadState]
    if loadStateString then
        --mj:log("hi:", loadStateString)
        updateLoadString(loadStateString)
    else
        if newLoadState == "got_welcome_message" then
            --mj:log("got welcome messgae:", userData)
            updateLoadString(locale:get("loading_world"))
            welcomeMessageTextView.text = userData or ""
        elseif newLoadState == "downloading" then
            loadStateString = locale:get("loading_downloadingData")
            if userData.fileName then
                loadStateString = locale:get("loading_downloading") .. ": ".. userData.fileName .. " (" .. mj:tostring(userData.currentFileIndex + 1) .. "/" .. mj:tostring(userData.expectedFileCount) .. ")"
            end
            updateLoadString(loadStateString)
        else
            updateLoadString(locale:get("loading_loading"))
            mj:log("No string for load state:" .. mj:tostring(newLoadState))
        end
    end
end

function loadingScreen:modsToDownloadInfoReceived(modNamesAndVersions)
    --mj:log("got modsToDownloadInfoReceived:", modNamesAndVersions)

    local messageText = locale:get("mods_installListMessage") .. "\n\n"
    for i,modNameAndVersion in ipairs(modNamesAndVersions) do
        messageText = messageText .. modNameAndVersion.name .. ": " .. modNameAndVersion.version .. "\n"
    end

    messageText = messageText .. "\n" .. locale:get("mods_cautionInfo")

    local function userSelection(allowDownload)
        loadingTextView.hidden = false
        welcomeMessageTextView.hidden = false
        alertPanel:hide()
        controller:modInstallAuthorizationResponse(allowDownload)
    end

    alertPanel:show(mainView, locale:get("mods_installWarningTitle"), messageText, {
        {
            isDefault = true,
            name = locale:get("mods_installMods"),
            action = function()
                userSelection(true)
            end
        },
        {
            isCancel = true,
            name = locale:get("ui_action_cancel"),
            action = function()
                userSelection(false)
            end
        }
    }, {
        width = 960,
    })
end


function loadingScreen:joinInfoReceived(infos)
    local tribeListView = nil
    local selectedTribeView = nil
    local tribeSelectedRowIndex = nil
    local selectedTribeTitleTextView = nil
    local selectedTribePopulationTextView = nil
    local totalSessionCount = #infos

    local tribeListInfos = {}

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
            else
                selectedTribeTitleTextView.hidden = true
                selectedTribePopulationTextView.hidden = true
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

        for i,info in ipairs(infos) do
            tribeListInfos[i] = {
                detailedInfo = info,
                sessionIndex = i - 1,
            }
        end

        local function sortByLastPlayed(a,b)
            return a.detailedInfo.disconnectWorldTimeDelta < b.detailedInfo.disconnectWorldTimeDelta
        end

        table.sort(tribeListInfos, sortByLastPlayed)

        local rowIndex = 1
        for i,tribeListInfo in ipairs(tribeListInfos) do
            tribeListInfo.rowIndex = rowIndex
            local detailedInfo = tribeListInfo.detailedInfo

            local tribeName = locale:get("misc_tribeName", {tribeName = detailedInfo.tribeName})

            if detailedInfo.hibernationTimeDelta then
                tribeName = tribeName .. " (" .. locale:get("misc_hibernating") .. ")" 
            else
                tribeName = tribeName .. " (" .. locale:get("misc_active") .. ")" 
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
                --mj:log("detailedInfo tribe:", detailedInfo and detailedInfo.tribeID, "\nsessionInfo:", sessionInfo)
                updateTribeSelectedIndex(indexCopy, wasClick)
            end)
            rowIndex = rowIndex + 1
        end

        --uiSelectionLayout:setActiveSelectionLayoutView(tribeListView)
        if tribeListInfos[1] then
            uiSelectionLayout:setSelection(tribeListView, tribeListInfos[1].backgroundView)
            updateTribeSelectedIndex(1, false)
        else
            updateTribeSelectedIndex(nil, false)
        end

    end

    local panelSize = vec2(640.0, 360.0)
    local buttonSize = vec2(180, 40)
    --local thinButtonSize = vec2(180, 30)

    loadingTextView.hidden = true
    welcomeMessageTextView.hidden = true

    local backgroundView = ModelView.new(mainView)
    uiSelectionLayout:createForView(backgroundView)

    backgroundView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    backgroundView.size = panelSize
    local tribeContainerScaleToUsePaneX = backgroundView.size.x * 0.5
    local tribeContainerScaleToUsePaneY = backgroundView.size.y * 0.5  / (9.0/16.0)
    backgroundView.scale3D = vec3(tribeContainerScaleToUsePaneX,tribeContainerScaleToUsePaneY,tribeContainerScaleToUsePaneX)
    backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    backgroundView.baseOffset = vec3(0,-40, 0)


    local tribesListViewContainer = View.new(backgroundView)
    tribesListViewContainer.size = vec2(panelSize.x * 0.5, panelSize.y)
    tribesListViewContainer.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    --tribesListViewContainer.color = vec4(0.2,0.3,0.6,0.5)

    local newTribeButton = uiStandardButton:create(tribesListViewContainer, buttonSize)
    newTribeButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    newTribeButton.baseOffset = vec3(0,-10,0)
    uiStandardButton:setText(newTribeButton, locale:get("ui_name_startNewTribe"))
    uiStandardButton:setClickFunction(newTribeButton, function()
        controller:joinSessionWithIndex(totalSessionCount)
        loadingTextView.hidden = false
        welcomeMessageTextView.hidden = false
        mainView:removeSubview(backgroundView)
    end)

    uiSelectionLayout:addView(backgroundView, newTribeButton)

    local tribesListInsetView = ModelView.new(tribesListViewContainer)
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

    selectedTribeView = View.new(backgroundView)
    selectedTribeView.size = vec2(backgroundView.size.x * 0.5, 220.0)
    selectedTribeView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    --selectedTribeView.color = vec4(0.2,0.6,0.2,0.5)
    --selectedTribeView.baseOffset = vec3(0,-40, 0)


    --local tribeSapiensRenderGameObjectViewSize = vec2(selectedTribeView.size.x - 20, 130)

    --[[local testView = ColorView.new(selectedTribeView)
    testView.size = tribeSapiensRenderGameObjectViewSize
    testView.color = vec4(0.2,0.6,0.2,0.5)
    testView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    testView.baseOffset = vec3(0,55, 0)]]

    --[[local tribeSapiensRenderGameObjectView = uiTribeView:create(selectedTribeView, tribeSapiensRenderGameObjectViewSize)
    tribeSapiensRenderGameObjectView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    tribeSapiensRenderGameObjectView.baseOffset = vec3(0,52, 0)]]

    selectedTribeTitleTextView = ModelTextView.new(selectedTribeView)
    selectedTribeTitleTextView.font = Font(uiCommon.titleFontName, 24)
    selectedTribeTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    selectedTribeTitleTextView.baseOffset = vec3(0,-50,0)
    selectedTribeTitleTextView.wrapWidth = selectedTribeView.size.x - 10

    selectedTribePopulationTextView = TextView.new(selectedTribeView)
    selectedTribePopulationTextView.font = Font(uiCommon.titleFontName, 16)
    selectedTribePopulationTextView.color = mj.textColor
    selectedTribePopulationTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    selectedTribePopulationTextView.relativeView = selectedTribeTitleTextView
    selectedTribePopulationTextView.baseOffset = vec3(0,5,0)

    local loadButton = uiStandardButton:create(selectedTribeView, buttonSize)
    loadButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    loadButton.baseOffset = vec3(0,10,0)
    uiStandardButton:setText(loadButton, locale:get("ui_name_load"))
    uiStandardButton:setClickFunction(loadButton, function()
        local sessionIndex = 0
        if tribeSelectedRowIndex then
            sessionIndex = tribeListInfos[tribeSelectedRowIndex].sessionIndex or 0
        end
        controller:joinSessionWithIndex(sessionIndex)
        loadingTextView.hidden = false
        welcomeMessageTextView.hidden = false
        mainView:removeSubview(backgroundView)
    end)

    uiSelectionLayout:addView(backgroundView, loadButton)


    --local sessionInfos = infos --probably won't just pass the array like this, so lets use a local

    updateTribesList()

end

return loadingScreen