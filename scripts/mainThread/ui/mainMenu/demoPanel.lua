local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local steam = mjrequire "common/utility/steam"
local locale = mjrequire "common/locale"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"

local demoPanel = {}

local mainTitleString = "Sapiens Demo"
local mainText = [[
Thank you for trying the Sapiens demo!

In this demo, you can play for the first two in-game days, in as many worlds as you like.

In the full version, you can play for many years. Discover complex tools, build wood and mudbrick structures, play musical instruments, hunt mammoths and much more. Your tribe can grow to over 100 sapiens and span many generations.

The worlds you start in this demo will still load in the full version when it releases into early access, so you can keep the progress you make now.

Sapiens will go into early access in a few weeks, so add it to your wishlist now!
]]


local completionTitleString = "Demo time limit reached"
local completionText = [[
The demo time limit of two in-game days has been reached in this world.

You can still create more new worlds and play the first two days again, and once the full version is out, you can continue any worlds you have started.

Sapiens will go into early access in a few weeks, so add it to your wishlist now!
]]


function demoPanel:init(mainMenu, controller)
    
    local backgroundSize = subMenuCommon.size
    
    local mainView = ModelView.new(mainMenu.mainView)
    demoPanel.mainView = mainView
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.hidden = true

    local titleTextView = ModelTextView.new(mainView)
    demoPanel.titleTextView = titleTextView
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,-50, 0)

    subMenuCommon:init(mainMenu, demoPanel, mainMenu.mainView.size)
    
    local contentTextView = TextView.new(mainView)
    demoPanel.contentTextView = contentTextView
    contentTextView.font = Font(uiCommon.fontName, 18)
    contentTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    contentTextView.baseOffset = vec3(0,-120, 0)
    contentTextView.wrapWidth = backgroundSize.x - 80

    local wishlistButton = uiStandardButton:create(mainView, vec2(200,40), uiStandardButton.types.standard_10x3)
    wishlistButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    wishlistButton.relativeView = contentTextView
    wishlistButton.baseOffset = vec3(0,-10,0)
    uiStandardButton:setText(wishlistButton, locale:get("ui_action_wishlist"))
    uiStandardButton:setClickFunction(wishlistButton, function()
        steam:openURL("https://store.steampowered.com/app/1060230/Sapiens/")
    end)



    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    closeButton.baseOffset = vec3(-20, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        demoPanel:hide()
    end)

    
    

end

function demoPanel:show(controller_, mainMenu, delay, isCompletion)
    if not demoPanel.mainView then
        --controller = controller_
        demoPanel:init(mainMenu, controller_)
    end

    if isCompletion then
        demoPanel.titleTextView:setText(completionTitleString, material.types.standardText.index)
        demoPanel.contentTextView.text = completionText
    else
        demoPanel.titleTextView:setText(mainTitleString, material.types.standardText.index)
        demoPanel.contentTextView.text = mainText
    end
    
    local backgroundSize = subMenuCommon.size
    local sizeToUse = vec2(backgroundSize.x, backgroundSize.y)
    sizeToUse.y = demoPanel.contentTextView.size.y + 260
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    
    demoPanel.mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    demoPanel.mainView.size = sizeToUse

    subMenuCommon:slideOn(demoPanel, delay)
end

function demoPanel:hide()
    if demoPanel.mainView and (not demoPanel.mainView.hidden) then
        subMenuCommon:slideOff(demoPanel)
        return true
    end
    return false
end

function demoPanel:backButtonClicked()
    demoPanel:hide()
end

function demoPanel:hidden()
    return not (demoPanel.mainView and (not demoPanel.mainView.hidden))
end

return demoPanel