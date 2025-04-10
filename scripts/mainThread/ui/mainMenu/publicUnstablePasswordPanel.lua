local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"



local mainTitleString = "Unstable branch now closed for new players until public release"
local mainText = [[
Thank you for checking out 0.5. Unfortunately this branch is now closed for new testers until after the update releases on the 19th July. You're welcome to join in with testing of new features again when work begins on the next update soon. 

Sorry for any inconvenience, please switch back to main branch, and the update will be installed as soon as it is publicly released.

If you have a password, you can enter it here:
]]


local publicUnstablePasswordPanel = {}

local controller = nil
local mainView = nil

function publicUnstablePasswordPanel:load(controller_, continueFunction)
    controller = controller_
    
    mainView = View.new(controller.mainView)
    mainView.size = controller.mainView.size

    local background = ImageView.new(mainView)
    background.imageTexture = MJCache:getTexture("img/loadingBackground_0.5.0.jpg")
    background.size = mainView.size
    background.color = vec4(0.17,0.17,0.17,1.0)

    local titleText = TextView.new(mainView)
    titleText.font = Font(uiCommon.fontName, 28)
    titleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    titleText.baseOffset = vec3(0,140,0)
    titleText.color = mj.textColor
    titleText.text = mainTitleString

    local descriptionText = TextView.new(mainView)
    descriptionText.font = Font(uiCommon.fontName, 22)
    descriptionText.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    descriptionText.relativeView = titleText
    descriptionText.color = mj.textColor
    descriptionText.baseOffset = vec3(0,-40,0)
    descriptionText.wrapWidth = 1000.0
    descriptionText.textAlignment = MJHorizontalAlignmentCenter
    descriptionText.text = mainText
    descriptionText.size = vec2(1000.0, descriptionText.size.y)

    local textEntrySize = vec2(200.0,24.0)
    local passwordTextEntry = uiTextEntry:create(mainView, textEntrySize, uiTextEntry.types.standard_10x3, MJPositionCenter, nil, "Password")
    uiTextEntry:setMaxChars(passwordTextEntry, 50)
    
    passwordTextEntry.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    passwordTextEntry.relativeView = descriptionText
    passwordTextEntry.baseOffset = vec3(0,-5,0)
    
    uiTextEntry:setFunction(passwordTextEntry, function(newValue)
        if newValue == "sapiens05multiplayer" then --if you found this, then well done, enjoy the game! Please look into the code more, it's easy to make mods!
            publicUnstablePasswordPanel:hide()
            continueFunction()
        end
    end)

end

function publicUnstablePasswordPanel:hide()
    controller.mainView:removeSubview(mainView)
    mainView = nil
end

return  publicUnstablePasswordPanel