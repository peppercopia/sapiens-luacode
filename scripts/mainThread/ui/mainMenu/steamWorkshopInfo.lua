local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local alertPanel = mjrequire "mainThread/ui/alertPanel"
local steam = mjrequire "common/utility/steam"
--local bugReporting = mjrequire "mainThread/bugReporting"

local steamWorkshopInfo = {}

function steamWorkshopInfo:init(mainMenu)
    
    local backgroundSize = vec2(subMenuCommon.size.x, 400.0)

    local mainView = ModelView.new(mainMenu.mainView)
    steamWorkshopInfo.mainView = mainView

    local sizeToUse = backgroundSize
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.size = backgroundSize
    mainView.hidden = true

    subMenuCommon:init(mainMenu, steamWorkshopInfo, mainMenu.mainView.size)
    
    local titleTextView = ModelTextView.new(mainView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,-20, 0)
    titleTextView:setText(locale:get("mods_steamWorkshop"), material.types.standardText.index)


    local infoTextView = TextView.new(mainView)
    infoTextView.baseOffset = vec3(20, -100, 0)
    infoTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    infoTextView.font = Font(uiCommon.fontName, 16)
    infoTextView.color = vec4(1.0,1.0,1.0,1.0)
    infoTextView.wrapWidth = mainView.size.x - 40
    infoTextView.text = locale:get("mods_steamWorkshop_info")


    local buttonSize = vec2(220, 40)
    
    local submitButton = uiStandardButton:create(mainView, buttonSize)
    submitButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    submitButton.relativeView = infoTextView
    submitButton.baseOffset = vec3(0,-50, 0)
    uiStandardButton:setText(submitButton, locale:get("mods_visitSteamWorkshopLink"))
    uiStandardButton:setClickFunction(submitButton, function()
        steamWorkshopInfo:hide()
        
        if not steam:openURL("https://steamcommunity.com/workshop/browse/?appid=1060230") then
            alertPanel:show(mainMenu.mainView, locale:get("ui_name_steamOverlayDisabled"), locale:get("ui_info_steamOverlayDisabled"), {
                {
                    isDefault = true,
                    name = locale:get("ui_action_OK"),
                    action = function()
                        alertPanel:hide()
                    end
                },
            })
        end
    end)
    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        steamWorkshopInfo:hide()
    end)

end

function steamWorkshopInfo:show(mainMenu, delay)
    --controller = controller_

    if not steamWorkshopInfo.mainView then
        --controller = controller_
        steamWorkshopInfo:init(mainMenu)
    end

    subMenuCommon:slideOn(steamWorkshopInfo, delay)
end

function steamWorkshopInfo:hide()
    if steamWorkshopInfo.mainView and (not steamWorkshopInfo.mainView.hidden) then
        subMenuCommon:slideOff(steamWorkshopInfo)
        return true
    end
    return false
end

function steamWorkshopInfo:hidden()
    return not (steamWorkshopInfo.mainView and (not steamWorkshopInfo.mainView.hidden))
end

function steamWorkshopInfo:backButtonClicked()
    steamWorkshopInfo:hide()
end

return steamWorkshopInfo