local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local model = mjrequire "common/model"

local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"

local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"

local bugReportView = mjrequire "mainThread/ui/bugReportView"

local bugReportMenu = {}


function bugReportMenu:init(controller_, mainMenu)
    local backgroundSize = subMenuCommon.size
    
    local mainView = ModelView.new(mainMenu.mainView)
    bugReportMenu.mainView = mainView
   
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
    titleTextView:setText(locale:get("reporting_sendBugReport"), material.types.standardText.index)
    
    subMenuCommon:init(mainMenu, bugReportMenu, mainMenu.mainView.size)

    bugReportView:load(controller_, mainView, true)

    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        bugReportMenu:hide()
    end)
end

function bugReportMenu:show(controller_, mainMenu, delay, isCrash)
    
    if not bugReportMenu.mainView then
        bugReportMenu:init(controller_, mainMenu)
    end
    if isCrash then
        bugReportView:populateCrashTitle()
    end
    subMenuCommon:slideOn(bugReportMenu, delay)
    bugReportView:parentBecameVisible()
end

function bugReportMenu:hide()
    
    if bugReportMenu.mainView and (not bugReportMenu.mainView.hidden) then
        subMenuCommon:slideOff(bugReportMenu, nil, nil)
        bugReportView:parentBecameHidden()
        return true
    end
    return false
end

function bugReportMenu:backButtonClicked()
    bugReportMenu:hide()
end

function bugReportMenu:cleanup()
    bugReportView:cleanup()
end

function bugReportMenu:hidden()
    return not (bugReportMenu.mainView and (not bugReportMenu.mainView.hidden))
end

return bugReportMenu