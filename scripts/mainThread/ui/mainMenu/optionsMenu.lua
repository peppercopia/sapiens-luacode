local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3

local model = mjrequire "common/model"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local optionsView = mjrequire "mainThread/ui/optionsView"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"

local optionsMenu = {}

local controller = nil
local mainMenu = nil

function optionsMenu:init()
    
    local backgroundSize = subMenuCommon.size

    local mainView = ModelView.new(mainMenu.mainView)
    optionsMenu.mainView = mainView
   -- mainView:setRenderTargetBacked(true)
   
    local sizeToUse = backgroundSize
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.size = backgroundSize
    mainView.hidden = true

    
    subMenuCommon:init(mainMenu, optionsMenu, mainMenu.mainView.size)

    
    optionsView:load(mainView, nil, nil, controller, nil, optionsMenu)

    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        optionsMenu:hide()
    end)

end

function optionsMenu:show(controller_, mainMenu_, delay)
    if not optionsMenu.mainView then
        controller = controller_
        mainMenu = mainMenu_
        optionsMenu:init()
    end
    subMenuCommon:slideOn(optionsMenu, delay)
    optionsView:parentBecameVisible()
end

function optionsMenu:hide()
    if optionsMenu.mainView and (not optionsMenu.mainView.hidden) then
        subMenuCommon:slideOff(optionsMenu)
        optionsView:parentBecameHidden()
        return true
    end
    return false
end


function optionsMenu:backButtonClicked()
    if not optionsView:backButtonClicked() then
        optionsMenu:hide()
    end
end

function optionsMenu:displayBugReportPanel()
    mainMenu:showBugReportMenu()
end

function optionsMenu:hidden()
    return not (optionsMenu.mainView and (not optionsMenu.mainView.hidden))
end

return optionsMenu