local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local audio = mjrequire "mainThread/audio"
local locale = mjrequire "common/locale"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"
local uiSlider = mjrequire "mainThread/ui/uiCommon/uiSlider"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local eventManager = mjrequire "mainThread/eventManager"

local worldNameGenerator = mjrequire "mainThread/ui/mainMenu/worldNameGenerator"
local rng = mjrequire "common/randomNumberGenerator"
local keyMapping = mjrequire "mainThread/keyMapping"

--[[note: scale vales are expected in the range 0-1, with 0.5 being the default, 0-1 being the guidance for range. Negative values and values above 1 should be OK but might produce game breaking results.
it's used as follows:
if(scales[i] < 0.5)
{
    double baseValueZeroToOne = -(scales[i] - 0.5) * 2.0;
    scales[i] = scales[i] * (1.0 + baseValueZeroToOne * scaleFactor);
}
else
{
    double baseValueZeroToOne = (scales[i] - 0.5) * 2.0;
    scales[i] = scales[i] / (1.0 + baseValueZeroToOne * scaleFactor);
}
]]

-- Note to modders, customOptions supports an extra 4 userData vec4s userDataA,userDataB,userDataC, and userDataD, which can then be used in an SPHeight C mod
-- it also supports a userDataP value, which must be a lua string, and is available as a void* in SPHeight. This can be used to store any data (within certain size limits).
-- The userDataP string could be a serialized C struct, which could be created using LuaJIT's FFI
-- example:
-- customOptions.userDataA = mjm.vec4(1.0,2.0,3.0,4.0)
-- globeView:setCustomValue("userDataA", customOptions.userDataA)
-- customOptions.userDataP = "test"
-- globeView:setCustomValue("userDataP", customOptions.userDataP)


local worldCreation = {}

local controller = nil
local mainView = nil
local loaded = false
local modsMenu = nil
local mainMenu = nil
local modDeveloperMenu = nil

local mainBanner = nil
local confirmButton = nil
local worldNameTextEntry = nil
local seedTextEntry = nil

local globeView = nil
local cancelFunction = nil

--local bannerXOffsetFromRight = -40
local mainBannerBasePosTopLeft = vec2(140,-100)

local function generateRandomSeed()
    local randomValue = (os.time() + rng:randomInteger(21357623))
    return string.format("%x", randomValue % 1048576)
end

local seedText = generateRandomSeed()
local worldName = worldNameGenerator:getRandomName()
local customOptions = {}

--[[local function slideOn()
    mainBanner.baseOffset = vec3(bannerXOffsetFromRight, -40 - mainBanner.size.y, 0)
    local mainBannerAnimateOnTimer = 0.0
    mainBanner.hidden = false
    audio:playUISound("audio/sounds/ui/stone.wav")
    mainBanner.update = function(dt_)
        mainBannerAnimateOnTimer = mainBannerAnimateOnTimer + dt_
        local fraction = mainBannerAnimateOnTimer * 2.0
        fraction = math.pow(fraction, 0.6)
        if fraction < 1.0 then
            mainBanner.baseOffset = vec3(bannerXOffsetFromRight, -40 - mainBanner.size.y * (1.0 - fraction), 0)
        else
            mainBanner.baseOffset = vec3(bannerXOffsetFromRight, -40, 0)
            mainBanner.update = nil
        end
    end
end]]

local hasSlidOn = false
local mainBannerAnimateOnTimer = 0.0
local mainBannerAnimateOffTimer = 0.0


local function slideOn()
    if not hasSlidOn then
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
                mainBanner.update = nil
            end
        end
        uiSelectionLayout:setActiveSelectionLayoutView(mainBanner)

        --[[mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y - mainBanner.size.y, 0)
        local mainBannerAnimateOnTimer = 0.0
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
                mainBanner.update = nil
            end
        end]]
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
                if finishedFunction then
                    finishedFunction()
                end
                hasSlidOn = false
            end
        end
        uiSelectionLayout:removeActiveSelectionLayoutView(mainBanner)
    end
end

local delegateConfirmFunction = nil

local function confirmAction()
    uiTextEntry:finishEditing(worldNameTextEntry, true)
    uiTextEntry:finishEditing(seedTextEntry, true)
    local customOptionsToUse = nil
    if customOptions and next(customOptions) then
        customOptionsToUse = customOptions
    end 
    delegateConfirmFunction({
        seed = seedText,
        worldName = worldName,
        customOptions = customOptionsToUse,
        enabledWorldMods = modsMenu:getWorldModsListForWorldCreation(),
    })
end

local function cancelAction()
    if not modsMenu:hidden() then
        mainMenu:hideSteamWorkshopInfo()
        mainMenu:hideEnableModsWarning()
        modsMenu:hide()
    elseif not mainMenu:hideSteamWorkshopInfo() and not mainMenu:hideEnableModsWarning() then
        slideOff(cancelFunction)
    end
end

local keyMap = {
    [keyMapping:getMappingIndex("menu", "back")] = function(isDown, isRepeat) 
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

function worldCreation:init(controller_, modsMenu_, mainMenu_, modDeveloperMenu_)
    controller = controller_
    modsMenu = modsMenu_
    mainMenu = mainMenu_
    modDeveloperMenu = modDeveloperMenu_

    mainView = View.new(controller.mainView)
    mainView.size = controller.mainView.size
    mainView.hidden = true
    mainView.keyChanged = keyChanged

    --[[local titleText = TextView.new(mainView)
    titleText.font = Font(uiCommon.titleFontName, 144)
    titleText.text = string.upper(mj.gameName)]]

    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuStart", function(isDown)
        if hasSlidOn and isDown then
            confirmAction()
            return true
        end
    end)


    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuCancel", function(isDown)
        if hasSlidOn then
            cancelAction()
            return true
        end
    end)

end

function worldCreation:hide()
    mainView.hidden = true
end

local controlUpdateInfos = {}

local function addSlider(title, relativeView, min, max, initialValue, extraOffset, updateFunction, resetControlFunction)
    local sliderTitleText = TextView.new(mainBanner)
    sliderTitleText.font = Font(uiCommon.fontName, 16)
    sliderTitleText.text = title .. ":"
    sliderTitleText.baseOffset = vec3(0, -20, 0) + extraOffset
    sliderTitleText.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBelow)
    sliderTitleText.relativeView = relativeView

    local options = nil

    local sliderView = uiSlider:create(mainBanner, vec2(200, 20), min, max, initialValue, options, updateFunction)
    sliderView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    sliderView.baseOffset = vec3(5, 0, 0)
    sliderView.relativeView = sliderTitleText

    table.insert(controlUpdateInfos, {
        sliderView = sliderView,
        resetControlFunction = resetControlFunction,
    })

    return {
        titleView = sliderTitleText,
        sliderView = sliderView,
    }

end

function worldCreation:loadViews()
--[[local background = ImageView.new(mainView)
    background.imageTexture = MJCache:getTexture("img/starBackground.jpg")
    background.size = mainView.size * 4.0
    background.baseOffset = vec3(0,0,-1000)]]

    
    
    mainBanner = ModelView.new(mainView)
    mainBanner:setModel(model:modelIndexForName("ui_bg_monolith"))
    uiSelectionLayout:createForView(mainBanner)
    
    local scaleToUse = 540
    local mainBannerWidth = scaleToUse * 0.8
    mainBanner.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse)
    mainBanner.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    mainBanner.size = vec2(mainBannerWidth,scaleToUse * 2.0)
    mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y, 0)

    local titleText = ModelTextView.new(mainBanner)
    titleText.font = Font(uiCommon.titleFontName, 36)
    titleText:setText(locale:get("menu_createWorld"), material.types.standardText.index)
    titleText.baseOffset = vec3(0, -200, 0)
    titleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

    local logo = ModelView.new(mainBanner)
    -- logo:setRenderTargetBacked(true)
    logo:setModel(model:modelIndexForName("hand"))
    local logoHalfSize = 60
    logo.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
    logo.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)
    logo.size = vec2(logoHalfSize,logoHalfSize) * 2.0
    logo.baseOffset = vec3(0, 20, 0)
    logo.relativeView = titleText

    --[[local bannerSize = vec2(mainView.size.y * 0.4, mainView.size.y)
    local scaleToUse = bannerSize.y * 0.5
    mainBanner.scale3D = vec3(scaleToUse * 1.2,scaleToUse,scaleToUse)
    mainBanner.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    mainBanner.size = bannerSize]]

    
    --[[globeView = GlobeView.new(mainView)
    local globeViewSize = mainView.size.y * 0.8
    globeView.size = vec2(globeViewSize,globeViewSize)
    globeView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    globeView.baseOffset = vec3((mainView.size.x - bannerSize.x + bannerXOffsetFromRight) * 0.5 - globeViewSize * 0.5 + 100,0,-globeViewSize * 0.1)
    globeView:setSeedString(seedText)]]
    

    local textEntrySize = vec2(200.0,24.0)

    local worldNameTitleText = TextView.new(mainBanner)
    worldNameTitleText.font = Font(uiCommon.fontName, 16)
    worldNameTitleText.text = locale:get("menu_worldName") .. ":"
    worldNameTitleText.baseOffset = vec3(-mainBanner.size.x * 0.5 - 80, -280, 0)
    worldNameTitleText.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    

    worldNameTextEntry = uiTextEntry:create(mainBanner, textEntrySize, uiTextEntry.types.standard_10x3, nil, locale:get("menu_worldName"))
    uiTextEntry:setMaxChars(worldNameTextEntry, 30)
    worldNameTextEntry.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    worldNameTextEntry.relativeView = worldNameTitleText
    worldNameTextEntry.baseOffset = vec3(8, 0, 0)
    uiTextEntry:setText(worldNameTextEntry, worldName)
    uiTextEntry:setFunction(worldNameTextEntry, function(newWorldName)
        worldName = newWorldName
    end)
    
    uiSelectionLayout:addView(mainBanner, worldNameTextEntry)
    worldNameTextEntry.userData.debugName = "worldNameTextEntry"

    local randomWorldNameButton = uiStandardButton:create(mainBanner, vec2(textEntrySize.y, textEntrySize.y), uiStandardButton.types.slim_1x1_bordered)
    randomWorldNameButton.relativeView = worldNameTextEntry
    randomWorldNameButton.baseOffset = vec3(8, 0, 0)
    randomWorldNameButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    uiStandardButton:setIconModel(randomWorldNameButton, "icon_random")
    uiStandardButton:setClickFunction(randomWorldNameButton, function()
        worldName = worldNameGenerator:getRandomName()
        uiTextEntry:setText(worldNameTextEntry, worldName)
    end)
    uiSelectionLayout:addView(mainBanner, randomWorldNameButton)
    randomWorldNameButton.userData.debugName = "randomWorldNameButton"
    

    local seedTitleText = TextView.new(mainBanner)
    seedTitleText.font = Font(uiCommon.fontName, 16)
    seedTitleText.text = locale:get("menu_seed") .. ":"
    seedTitleText.baseOffset = vec3(0, -20, 0)
    seedTitleText.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBelow)
    seedTitleText.relativeView = worldNameTitleText

    seedTextEntry = uiTextEntry:create(mainBanner, textEntrySize, uiTextEntry.types.standard_10x3, nil, locale:get("menu_seed"))
    uiTextEntry:setMaxChars(seedTextEntry, 20)
    seedTextEntry.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    seedTextEntry.relativeView = seedTitleText
    seedTextEntry.baseOffset = vec3(8, 0, 0)
    uiTextEntry:setText(seedTextEntry, seedText, false)
    uiTextEntry:setFunction(seedTextEntry, function(newSeed)
        seedText = newSeed
        globeView:setSeedString(seedText)
    end)
    uiSelectionLayout:addView(mainBanner, seedTextEntry)
    seedTextEntry.userData.debugName = "seedTextEntry"
    

    local randomSeedButton = uiStandardButton:create(mainBanner, vec2(textEntrySize.y, textEntrySize.y), uiStandardButton.types.slim_1x1_bordered)
    randomSeedButton.relativeView = seedTextEntry
    randomSeedButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    randomSeedButton.baseOffset = vec3(8, 0, 0)
    uiStandardButton:setIconModel(randomSeedButton, "icon_random")
    uiStandardButton:setClickFunction(randomSeedButton, function()
        seedText = generateRandomSeed()
        uiTextEntry:setText(seedTextEntry, seedText)
        globeView:setSeedString(seedText)
    end)
    uiSelectionLayout:addView(mainBanner, randomSeedButton)
    randomSeedButton.userData.debugName = "randomSeedButton"

    
    local sliderInfo = addSlider(locale:get("menu_seaLevel"), seedTitleText, 0, 100, 50, vec3(40,0,0), 
    function(value)
        local heightOffset = (value - 50) * -0.000002
        customOptions.heightOffset = heightOffset
        globeView:setCustomValue("heightOffset", heightOffset)
    end,
    function()
        if not customOptions.heightOffset then
            return 50
        end
        globeView:setCustomValue("heightOffset", customOptions.heightOffset)
        return 50 + (customOptions.heightOffset / -0.000002)
    end)
    uiSelectionLayout:addView(mainBanner, sliderInfo.sliderView)
    sliderInfo.sliderView.userData.debugName = "seaLevelSlider"

    
    uiSelectionLayout:addDirectionOverride(randomSeedButton, sliderInfo.sliderView, uiSelectionLayout.directions.down, false)
    
    sliderInfo = addSlider(locale:get("menu_rainfall"), sliderInfo.titleView, 0, 100, 50, vec3(0,0,0), function(value)
        local fraction = value / 100.0
        customOptions.rainfall = fraction
        globeView:setCustomValue("rainfall", fraction)
    end,
    function()
        if not customOptions.rainfall then
            return 50
        end
        globeView:setCustomValue("rainfall", customOptions.rainfall)
        return customOptions.rainfall * 100.0
    end)
    uiSelectionLayout:addView(mainBanner, sliderInfo.sliderView)
    
    sliderInfo = addSlider(locale:get("menu_temperature"), sliderInfo.titleView, 0, 100, 50, vec3(0,0,0), function(value)
        local fraction = value / 100.0
        customOptions.temperatureOffset = fraction
        globeView:setCustomValue("temperatureOffset", fraction)
    end,
    function()
        if not customOptions.temperatureOffset then
            return 50
        end
        globeView:setCustomValue("temperatureOffset", customOptions.temperatureOffset)
        return customOptions.temperatureOffset * 100.0
    end)
    uiSelectionLayout:addView(mainBanner, sliderInfo.sliderView)
    
    --[[prevSliderInfo = addSlider("Feature Scale", prevSliderInfo.titleView, 0, 100, 50, function(value)
        local fraction = value / 100.0
        customOptions.noiseScale = fraction
        globeView:setCustomValue("noiseScale", fraction)
    end)]]

    sliderInfo = addSlider(locale:get("menu_continentSize"), sliderInfo.titleView, 0, 100, 50, vec3(0,0,0), function(value)
        local fraction = value / 100.0
        if not customOptions.scales then
            customOptions.scales = vec3(0.5,0.5,0.5)
        end
        customOptions.scales.x = fraction
        globeView:setCustomValue("scales", customOptions.scales)
    end,
    function()
        if not customOptions.scales then
            customOptions.scales = vec3(0.5,0.5,0.5)
        end
        globeView:setCustomValue("scales", customOptions.scales)
        return customOptions.scales.x * 100.0
    end)
    uiSelectionLayout:addView(mainBanner, sliderInfo.sliderView)

    sliderInfo = addSlider(locale:get("menu_continentHeight"), sliderInfo.titleView, 0, 100, 50, vec3(0,0,0), function(value)
        local fraction = value / 100.0
        if not customOptions.influences then
            customOptions.influences = vec3(0.5,0.5,0.5)
        end
        customOptions.influences.x = fraction
        globeView:setCustomValue("influences", customOptions.influences)
    end,
    function()
        if not customOptions.influences then
            customOptions.influences = vec3(0.5,0.5,0.5)
        end
        globeView:setCustomValue("influences", customOptions.influences)
        return customOptions.influences.x * 100.0
    end)
    uiSelectionLayout:addView(mainBanner, sliderInfo.sliderView)

    sliderInfo = addSlider(locale:get("menu_featureSize"), sliderInfo.titleView, 0, 100, 50, vec3(0,0,0), function(value)
        local fraction = (100 - value) / 100.0
        if not customOptions.scales then
            customOptions.scales = vec3(0.5,0.5,0.5)
        end
        customOptions.scales.y = fraction * 1.25 - 0.25
        mj:log("set feature size:", customOptions.scales.y)
        globeView:setCustomValue("scales", customOptions.scales)
    end,
    function()
        if not customOptions.scales then
            customOptions.scales = vec3(0.5,0.5 * 1.25 - 0.25,0.5)
        end
        globeView:setCustomValue("scales", customOptions.scales)
        return 100.0 - (((customOptions.scales.y + 0.25) / 1.25) * 100.0)
    end)
    uiSelectionLayout:addView(mainBanner, sliderInfo.sliderView)

    sliderInfo = addSlider(locale:get("menu_featureHeight"), sliderInfo.titleView, 0, 100, 50, vec3(0,0,0), function(value)
        local fraction = value / 100.0
        if not customOptions.influences then
            customOptions.influences = vec3(0.5,0.5,0.5)
        end
        customOptions.influences.y = fraction
        globeView:setCustomValue("influences", customOptions.influences)
    end,
    function()
        if not customOptions.influences then
            customOptions.influences = vec3(0.5,0.5,0.5)
        end
        globeView:setCustomValue("influences", customOptions.influences)
        return customOptions.influences.y * 100.0
    end)
    uiSelectionLayout:addView(mainBanner, sliderInfo.sliderView)
    
    local buttonSize = vec2(220.0,50.0)

    local backButton = uiStandardButton:create(mainBanner, buttonSize, uiStandardButton.types.title_10x3)
    backButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    backButton.baseOffset = vec3(0,280,0)
    uiStandardButton:setText(backButton, locale:get("ui_action_cancel"))
    
    uiStandardButton:setClickFunction(backButton, function()
        if not modsMenu:hidden() then
            modsMenu:hide()
        end
        slideOff(cancelFunction)
    end)
    uiSelectionLayout:addView(mainBanner, backButton)

    
    local modsButton = uiStandardButton:create(mainBanner, buttonSize, uiStandardButton.types.title_10x3)
    modsButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    modsButton.relativeView = backButton
    modsButton.baseOffset = vec3(0,-20,0)
    uiStandardButton:setText(modsButton, locale:get("menu_mods"))
    
    local function showModDeveloperMenuFunc(modInfo)
        modsMenu:hide()
        modDeveloperMenu:show(controller, mainMenu, modInfo)
    end

    
    modsMenu:loadPreservedEnabledMods(controller)
    
    uiStandardButton:setClickFunction(modsButton, function()
        if modsMenu:hidden() then
            uiTextEntry:finishEditing(worldNameTextEntry, true)
            uiTextEntry:finishEditing(seedTextEntry, true)
            local delay = 0.0
            
            local customOptionsToUse = nil
            if customOptions and next(customOptions) then
                customOptionsToUse = customOptions
            end 
            local stateToPreserve = {
                seed = seedText,
                worldName = worldName,
                customOptions = customOptionsToUse,
            }
            modsMenu:show(controller, mainMenu, showModDeveloperMenuFunc, delay, true, stateToPreserve)
        end
    end)
    uiSelectionLayout:addView(mainBanner, modsButton)
    
    
    confirmButton = uiStandardButton:create(mainBanner, buttonSize, uiStandardButton.types.title_10x3)
    confirmButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    confirmButton.relativeView = modsButton
    confirmButton.baseOffset = vec3(0,-20,0)
    uiStandardButton:setText(confirmButton, locale:get("menu_createWorld"))
    uiSelectionLayout:addView(mainBanner, confirmButton)
    
    --mod support

    worldCreation.mainBanner = mainBanner
    worldCreation.customOptions = customOptions
    worldCreation.confirmButton = confirmButton
    worldCreation.worldNameTextEntry = worldNameTextEntry
    worldCreation.seedTextEntry = seedTextEntry

    worldCreation.addSlider = addSlider
    worldCreation.lastSliderInfo = sliderInfo
end

function worldCreation:loadUIForRestoredCustomOptions()
    for i, controlUpdateInfo in ipairs(controlUpdateInfos) do
        uiSlider:setValue(controlUpdateInfo.sliderView, controlUpdateInfo.resetControlFunction())
    end
end

function worldCreation:display(confirmFunction_, cancelFunction_, globeView_, preservedWorldCreationState, enabledWorldMods)
    globeView = globeView_
    cancelFunction = cancelFunction_
    delegateConfirmFunction = confirmFunction_

    if not loaded then
        worldCreation:loadViews()
        loaded = true
    end

    if preservedWorldCreationState then
        seedText = preservedWorldCreationState.seed
        uiTextEntry:setText(seedTextEntry, seedText, false)
        worldName = preservedWorldCreationState.worldName
        uiTextEntry:setText(worldNameTextEntry, worldName)
        customOptions = preservedWorldCreationState.customOptions
        mj:log("preservedWorldCreationState:", preservedWorldCreationState)
        if customOptions then
            worldCreation:loadUIForRestoredCustomOptions()
        else
            customOptions = {}
        end
    end

    if not customOptions.scales then
        mj:log("setting options")
        customOptions.scales = vec3(0.5,0.5 * 1.25 - 0.25,0.5)
    end
    
    globeView:setEnabledWorldMods(enabledWorldMods)
    globeView:setSeedString(seedText)
    globeView:setCustomValue("scales", customOptions.scales)

    
    uiStandardButton:setClickFunction(confirmButton, confirmAction)

    mainBanner.baseOffset = vec3(mainBannerBasePosTopLeft.x, mainBannerBasePosTopLeft.y - mainBanner.size.y, 0)
    mainBanner.hidden = true

    mainView.hidden = false
    

    slideOn()
    

end



return worldCreation