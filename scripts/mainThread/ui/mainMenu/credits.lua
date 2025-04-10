local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"

local credits = {}

local yOffset = 60
local lowerTextYOffset = -80

function credits:init(mainMenu)
    
    local backgroundSize = subMenuCommon.size
    
    local mainView = ModelView.new(mainMenu.mainView)
    credits.mainView = mainView
    
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
    titleTextView:setText(locale:get("ui_action_credits"), material.types.standardText.index)

    subMenuCommon:init(mainMenu, credits, mainMenu.mainView.size)

    
    local creditsLargerTextView = TextView.new(mainView)
    creditsLargerTextView.font = Font(uiCommon.fontName, 24)
    creditsLargerTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    creditsLargerTextView.baseOffset = vec3(0,-130 + yOffset, 0)
    creditsLargerTextView.wrapWidth = backgroundSize.x - 80
    creditsLargerTextView.textAlignment = MJHorizontalAlignmentCenter
    creditsLargerTextView.text = locale:get("creditsText_dave")
    
    local url = "https://majicjungle.com"
    local urlButton = uiStandardButton:create(mainView, vec2(200,20), uiStandardButton.types.link)
    urlButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    urlButton.relativeView = creditsLargerTextView
    urlButton.baseOffset = vec3(0,-10,0)
    uiStandardButton:setText(urlButton, url)
    uiStandardButton:setClickFunction(urlButton, function()
        fileUtils.openFile(url)
    end)
    
    local creditsMusicTextView = TextView.new(mainView)
    creditsMusicTextView.font = Font(uiCommon.fontName, 24)
    creditsMusicTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    creditsMusicTextView.relativeView = urlButton
    creditsMusicTextView.baseOffset = vec3(0,-10,0)
    creditsMusicTextView.wrapWidth = backgroundSize.x - 80
    creditsMusicTextView.textAlignment = MJHorizontalAlignmentCenter
    creditsMusicTextView.text = locale:get("creditsText_music")
    
    local musicUrl = "https://bit.ly/3mUG3vs"
    local musicUrlButton = uiStandardButton:create(mainView, vec2(200,20), uiStandardButton.types.link)
    musicUrlButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    musicUrlButton.relativeView = creditsMusicTextView
    musicUrlButton.baseOffset = vec3(0,-10,0)
    uiStandardButton:setText(musicUrlButton, locale:get("creditsText_soundtrackLinkText"))
    uiStandardButton:setClickFunction(musicUrlButton, function()
        fileUtils.openFile(musicUrl)
    end)

    
    local creditsTextView = TextView.new(mainView)
    creditsTextView.font = Font(uiCommon.fontName, 18)
    creditsTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    creditsTextView.baseOffset = vec3(0,-220 + yOffset + lowerTextYOffset, 0)
    creditsTextView.wrapWidth = backgroundSize.x - 80
    creditsTextView.text = locale:get("creditsText")

    
    local logo = ModelView.new(mainView)
   -- logo:setRenderTargetBacked(true)
    logo:setModel(model:modelIndexForName("hand"))
    local logoHalfSize = 80
    logo.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
    logo.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    logo.size = vec2(logoHalfSize,logoHalfSize) * 2.0
    logo.baseOffset = vec3(-200, -260 + yOffset + lowerTextYOffset, 0)
    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        credits:hide()
    end)
end

function credits:show(controller_, mainMenu, delay)
    if not credits.mainView then
        --controller = controller_
        credits:init(mainMenu)
    end
    subMenuCommon:slideOn(credits, delay)
end

function credits:hide()
    if credits.mainView and (not credits.mainView.hidden) then
        subMenuCommon:slideOff(credits)
        return true
    end
    return false
end

function credits:backButtonClicked()
    credits:hide()
end

function credits:hidden()
    return not (credits.mainView and (not credits.mainView.hidden))
end

return credits