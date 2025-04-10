local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
--local steam = mjrequire "common/utility/steam"
--local bugReporting = mjrequire "mainThread/bugReporting"

local enableModsWarning = {}
local confirmFunction = nil

function enableModsWarning:init(mainMenu)
    
    local backgroundSize = vec2(subMenuCommon.size.x, 400.0)

    local mainView = ModelView.new(mainMenu.mainView)
    enableModsWarning.mainView = mainView

    local sizeToUse = backgroundSize
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.size = backgroundSize
    mainView.hidden = true

    subMenuCommon:init(mainMenu, enableModsWarning, mainMenu.mainView.size)
    
    local titleTextView = ModelTextView.new(mainView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,0, 0)
    titleTextView:setText(locale:get("mods_cautionCaps"), material.types.warning.index)

    local infoTextView = TextView.new(mainView)
    infoTextView.baseOffset = vec3(20, -100, 0)
    infoTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    infoTextView.font = Font(uiCommon.fontName, 16)
    infoTextView.color = vec4(1.0,1.0,1.0,1.0)
    infoTextView.wrapWidth = mainView.size.x - 40
    infoTextView.text = locale:get("mods_cautionInfo")

    local buttonSize = vec2(220, 40)
    
    local cancelButton = uiStandardButton:create(mainView, buttonSize)
    cancelButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    cancelButton.relativeView = infoTextView
    cancelButton.baseOffset = vec3(-buttonSize.x * 0.5 - 10,-50, 0)
    uiStandardButton:setText(cancelButton, locale:get("ui_action_cancel"))
    uiStandardButton:setClickFunction(cancelButton, function()
        enableModsWarning:hide()
    end)

    local submitButton = uiStandardButton:create(mainView, buttonSize)
    submitButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    submitButton.relativeView = infoTextView
    submitButton.baseOffset = vec3(buttonSize.x * 0.5 + 10,-50, 0)
    uiStandardButton:setText(submitButton, locale:get("mods_enableMods"))
    uiStandardButton:setClickFunction(submitButton, function()
        confirmFunction()
    end)
    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        enableModsWarning:hide()
    end)

end

function enableModsWarning:show(mainMenu, delay, confirmFunction_)
    --controller = controller_

    confirmFunction = confirmFunction_

    if not enableModsWarning.mainView then
        --controller = controller_
        enableModsWarning:init(mainMenu)
    end

    subMenuCommon:slideOn(enableModsWarning, delay)
end

function enableModsWarning:hide()
    if enableModsWarning.mainView and (not enableModsWarning.mainView.hidden) then
        subMenuCommon:slideOff(enableModsWarning)
        return true
    end
    return false
end

function enableModsWarning:hidden()
    return not (enableModsWarning.mainView and (not enableModsWarning.mainView.hidden))
end

function enableModsWarning:backButtonClicked()
    enableModsWarning:hide()
end

return enableModsWarning