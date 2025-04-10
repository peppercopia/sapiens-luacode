local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4

local locale = mjrequire "common/locale"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local clientGameSettings = mjrequire "mainThread/clientGameSettings"

local updateDriverMenu = {}

local controller = nil
local mainView = nil

function updateDriverMenu:load(controller_, deviceName, downloadURL, downloadText, continueFunction)
    controller = controller_
    
    mainView = View.new(controller.mainView)
    mainView.size = controller.mainView.size

    local titleText = TextView.new(mainView)
    titleText.font = Font(uiCommon.fontName, 22)
    titleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    titleText.baseOffset = vec3(0,140,0)
    titleText.color = mj.textColor
    titleText.text = locale:get("gfx_updateRequiredTitle")

    local descriptionText = TextView.new(mainView)
    descriptionText.font = Font(uiCommon.fontName, 16)
    descriptionText.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    descriptionText.relativeView = titleText
    descriptionText.color = mj.textColor
    descriptionText.baseOffset = vec3(0,-40,0)
    descriptionText.wrapWidth = 800.0
    descriptionText.text = locale:get("gfx_updateRequired_info")

    local deviceNameText = TextView.new(mainView)
    deviceNameText.font = Font(uiCommon.fontName, 16)
    deviceNameText.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    deviceNameText.relativeView = descriptionText
    deviceNameText.baseOffset = vec3(0,-20,0)
    deviceNameText.color = mj.textColor
    deviceNameText.wrapWidth = 800.0
    deviceNameText.text = deviceName

    local toggleButton = uiStandardButton:create(mainView, vec2(26,26), uiStandardButton.types.toggle)
    toggleButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    toggleButton.relativeView = deviceNameText
    toggleButton.baseOffset = vec3(-70, -40, 0)
    
    uiStandardButton:setClickFunction(toggleButton, function()
        local value = uiStandardButton:getToggleState(toggleButton)
        clientGameSettings:changeSetting("disableDriverVersionWarning", value)
    end)

    
    local textView = TextView.new(mainView)
    textView.font = Font(uiCommon.fontName, 16)
    textView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    textView.relativeView = toggleButton
    textView.baseOffset = vec3(4,0, 0)
    textView.text = locale:get("ui_action_dontShowAgain")
    
    local buttonSize = vec2(240, 40)

    local downloadButton = uiStandardButton:create(mainView, buttonSize)
    downloadButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    downloadButton.relativeView = deviceNameText
    downloadButton.baseOffset = vec3(buttonSize.x * 0.5 + 10,-80, 0)
    uiStandardButton:setText(downloadButton, downloadText)
    uiStandardButton:setClickFunction(downloadButton, function()
        fileUtils.openFile(downloadURL)
        controller:exitToDesktop()
    end)

    local playAnywayButton = uiStandardButton:create(mainView, buttonSize)
    playAnywayButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    playAnywayButton.relativeView = deviceNameText
    playAnywayButton.baseOffset = vec3(-buttonSize.x * 0.5 - 10, -80, 0)
    uiStandardButton:setText(playAnywayButton, locale:get("ui_action_attemptToPlayAnyway"))
    uiStandardButton:setClickFunction(playAnywayButton, function()
        continueFunction()
    end)

end

function updateDriverMenu:hide()
    controller.mainView:removeSubview(mainView)
    mainView = nil
end

return  updateDriverMenu