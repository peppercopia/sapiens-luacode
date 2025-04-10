local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local locale = mjrequire "common/locale"

local crashPrompt = {}

local controller = nil
local bugReportMenu = nil

local submitButton = nil

function crashPrompt:init(mainMenu)
    
   -- local backgroundSize = subMenuCommon.size

    local mainView = View.new(mainMenu.mainView)
    crashPrompt.mainView = mainView
    mainView.hidden = true
    mainView.size = mainMenu.mainView.size
    
    local backgroundView = ModelView.new(mainView)
   -- mainView:setRenderTargetBacked(true)
    local sizeToUse = vec2(480, 240)
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    backgroundView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    backgroundView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
    backgroundView.size = sizeToUse

    
    local titleTextView = ModelTextView.new(backgroundView)
    titleTextView.font = Font(uiCommon.titleFontName, 24)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,-20, 0)
    titleTextView:setText(locale:get("reporting_sendCrashReport"), material.types.standardText.index)

    local infoTextView = TextView.new(backgroundView)
    infoTextView.baseOffset = vec3(20, -60, 0)
    infoTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    infoTextView.font = Font(uiCommon.fontName, 16)
    infoTextView.color = vec4(1.0,1.0,1.0,1.0)
    infoTextView.wrapWidth = backgroundView.size.x - 40
    infoTextView.text = locale:get("reporting_crashNotification")




    local statusTextView = TextView.new(backgroundView)
    statusTextView.baseOffset = vec3(0, -60, 0)
    statusTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    statusTextView.relativeView = infoTextView
    statusTextView.font = Font(uiCommon.fontName, 16)
    statusTextView.color = vec4(1.0,1.0,1.0,1.0)

    local buttonSize = vec2(180, 40)
    
    submitButton = uiStandardButton:create(backgroundView, buttonSize)
    submitButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    submitButton.relativeView = infoTextView
    submitButton.baseOffset = vec3(0,-20, 0)
    uiStandardButton:setText(submitButton, locale:get("reporting_sendCrashReport"))
    uiStandardButton:setClickFunction(submitButton, function()
        crashPrompt:hide()
        if bugReportMenu:hidden() then
            local delay = 0.0
            if mainMenu:hideCurrentMenu() then
                delay = 1.0
            end
            bugReportMenu:show(controller, mainMenu, delay, true)
            mainMenu:setCurrentVisibleSubmenu(bugReportMenu)
        end
    end)

    
    
    local closeButton = uiStandardButton:create(backgroundView, vec2(30,30), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    closeButton.baseOffset = vec3(-10, -10, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        crashPrompt:hide()
    end)

end

function crashPrompt:show(controller_, bugReportMenu_, mainMenu, delay)
    controller = controller_
    bugReportMenu = bugReportMenu_

    if not crashPrompt.mainView then
        --controller = controller_
        crashPrompt:init(mainMenu)
    end

    crashPrompt.mainView.hidden = false
end

function crashPrompt:hide()
    if crashPrompt.mainView and (not crashPrompt.mainView.hidden) then
        crashPrompt.mainView.hidden = true
        return true
    end
    return false
end

function crashPrompt:hidden()
    return not (crashPrompt.mainView and (not crashPrompt.mainView.hidden))
end

return crashPrompt