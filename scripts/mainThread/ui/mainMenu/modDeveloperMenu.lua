local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local steam = mjrequire "common/utility/steam"

--local modManager = mjrequire "common/modManager"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local clientGameSettings = mjrequire "mainThread/clientGameSettings"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local locale = mjrequire "common/locale"
local alertPanel = mjrequire "mainThread/ui/alertPanel"

local modDeveloperMenu = {}


--local controller = nil
local currentModInfo = nil
local currentWorkshopID = nil

local notAddedToWorkshopString = locale:get("mods_notAddedToWorkshop")
local addedToWorkshopString = locale:get("mods_addedToWorkshop")

function modDeveloperMenu:init(mainMenu)
    
    local backgroundSize = subMenuCommon.size
    
    local mainView = ModelView.new(mainMenu.mainView)
    modDeveloperMenu.mainView = mainView
    
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
    titleTextView.baseOffset = vec3(0,-50, 0)
    titleTextView:setText(locale:get("mods_modDeveloperTools"), material.types.standardText.index)

    
    local modTitleTextView = ModelTextView.new(mainView)
    modTitleTextView.font = Font(uiCommon.fontName, 24)
    modTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    modTitleTextView.relativeView = titleTextView
    modTitleTextView.baseOffset = vec3(0,-20, 0)

    modDeveloperMenu.modTitleTextView = modTitleTextView

    subMenuCommon:init(mainMenu, modDeveloperMenu, mainMenu.mainView.size)

    local buttonSize = vec2(200, 40)

    local uploadButton = nil

    local statusTextView = TextView.new(mainView)
    modDeveloperMenu.statusTextView = statusTextView
    statusTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    statusTextView.relativeView = modTitleTextView
    statusTextView.wrapWidth = mainView.size.x - 80
    statusTextView.baseOffset = vec3(0, -60, 0)
    statusTextView.font = Font(uiCommon.fontName, 18)
    statusTextView.color = vec4(1.0,1.0,1.0,1.0)
    
    local addToSteamButton = uiStandardButton:create(mainView, buttonSize)
    modDeveloperMenu.addToSteamButton = addToSteamButton
    addToSteamButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    addToSteamButton.baseOffset = vec3(0, -10, 0)
    addToSteamButton.relativeView = statusTextView

    local function showSteamOverlayAlert()
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
    
    statusTextView.text = notAddedToWorkshopString
    uiStandardButton:setText(addToSteamButton, locale:get("mods_AddToSteamWorkshop"))
    uiStandardButton:setClickFunction(addToSteamButton, function()
        uiStandardButton:setDisabled(addToSteamButton, true)
        statusTextView.text = locale:get("mods_ContactingSteam") .. "..."
        steam:createWorkshopID(function(newIDOrNil, failureReasonText, needsToAcceptAgreement)
            if newIDOrNil then
                local steamTable = {
                    publishedFileID = newIDOrNil,
                }
                local savePath = currentModInfo.directory .. "/workshop.mjl"
                if fileUtils.serializeToFile(steamTable, savePath) then
                    currentWorkshopID = newIDOrNil
                    if needsToAcceptAgreement then
                        statusTextView.text = locale:get("mods_acceptAgreement")
                    else
                        statusTextView.text = locale:get("mods_idReceived")
                    end
                    uiStandardButton:setDisabled(uploadButton, false)

                    if needsToAcceptAgreement then
                        if not steam:openURL("https://steamcommunity.com/sharedfiles/workshoplegalagreement") then
                            showSteamOverlayAlert()
                        end
                    end
                else
                    statusTextView.text = locale:get("mods_failedToSaveID") .. ":" .. savePath
                    uiStandardButton:setDisabled(addToSteamButton, false)
                end
            else
                statusTextView.text = locale:get("mods_failedToAddToSteam") .. " " .. failureReasonText
                uiStandardButton:setDisabled(addToSteamButton, false)
            end
        end)
    end)


    local function addToggleButton(parentView, toggleButtonTitle, toggleValue, changedFunction)

        local toggleContainerView = View.new(parentView)
        
        local textView = TextView.new(toggleContainerView)
        textView.font = Font(uiCommon.fontName, 18)
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        textView.baseOffset = vec3(0, 0, 0)
        textView.text = toggleButtonTitle

        local toggleButtonSize = 26
    
        local toggleButton = uiStandardButton:create(toggleContainerView, vec2(toggleButtonSize,toggleButtonSize), uiStandardButton.types.toggle)
        toggleButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        toggleButton.baseOffset = vec3(4, 2, 0)
        toggleButton.relativeView = textView
        uiStandardButton:setToggleState(toggleButton, toggleValue)

        
        uiStandardButton:setClickFunction(toggleButton, function()
            changedFunction(uiStandardButton:getToggleState(toggleButton))
        end)

        toggleContainerView.size = vec2(textView.size.x + 4 + toggleButtonSize, math.max(textView.size.y, toggleButtonSize + 4))

        return toggleContainerView
    end

    local toggleContainerView = addToggleButton(mainView, locale:get("mods_replaceDescription") .. ":", clientGameSettings.values.modDevelopment_replaceDescription, function(newValue) 
        clientGameSettings:changeSetting("modDevelopment_replaceDescription", newValue)
    end)
    toggleContainerView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    toggleContainerView.relativeView = addToSteamButton
    toggleContainerView.baseOffset = vec3(0, -20, 0)
    
    uploadButton = uiStandardButton:create(mainView, buttonSize)
    modDeveloperMenu.uploadButton = uploadButton
    uploadButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    uploadButton.baseOffset = vec3(0, -10, 0)
    uploadButton.relativeView = toggleContainerView--addToSteamButton
    uiStandardButton:setDisabled(uploadButton, true)

    local function progressUpdateFunction(statusText, percentComplete)
        if percentComplete and percentComplete > 0 then
            statusTextView.text = statusText .. " " .. mj:tostring(percentComplete) .. "%"
        else
            statusTextView.text = statusText .. "..."
        end
    end
    
    uiStandardButton:setText(uploadButton, locale:get("mods_UploadToSteam"))
    uiStandardButton:setClickFunction(uploadButton, function()
        if currentWorkshopID then
            uiStandardButton:setDisabled(uploadButton, true)
            statusTextView.text = locale:get("mods_ContactingSteam") .. "..."
            steam:uploadMod(currentWorkshopID, currentModInfo, clientGameSettings.values.modDevelopment_replaceDescription, progressUpdateFunction, function(success, failureReasonText)
                uiStandardButton:setDisabled(uploadButton, false)
                if success then
                    statusTextView.text = locale:get("mods_Uploadcomplete")
                    local workshopIDDecimalString = string.format("%d", tonumber(currentWorkshopID, 16))
                    --mj:log("currentWorkshopID:", currentWorkshopID, " decimal:", workshopIDDecimalString)
                    steam:openURL("steam://url/CommunityFilePage/" .. workshopIDDecimalString)
                    --steam:openURL("steam://url/CommunityFilePage/" .. currentWorkshopID) --should work but doesn't work
                    --steam:openURL("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. string.format("%d", tonumber(currentWorkshopID))) --causes absolute chaos
                else
                    statusTextView.text = locale:get("mods_failedToUploadToSteam") .. " " .. failureReasonText
                end
            end)
        end
    end)
    
    
    
    --[[local doneButton = uiStandardButton:create(mainView, buttonSize)
    doneButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    doneButton.baseOffset = vec3(0,60, 0)
    uiStandardButton:setText(doneButton, "Done")
    uiStandardButton:setClickFunction(doneButton, function()
        modDeveloperMenu:hide()
    end)]]

    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        modDeveloperMenu:hide()
    end)

end

function modDeveloperMenu:show(controller_, mainMenu, modInfo)
    if not modDeveloperMenu.mainView then
        --controller = controller_
        modDeveloperMenu:init(mainMenu)
    end

    currentModInfo = modInfo
    local modTitleTextView = modDeveloperMenu.modTitleTextView
    local addToSteamButton = modDeveloperMenu.addToSteamButton
    local uploadButton = modDeveloperMenu.uploadButton

    modTitleTextView:setText(modInfo.name, material.types.standardText.index)

    local workshopFile = currentModInfo.directory .. "/workshop.mjl"
    local workshopTable = fileUtils.unserializeFromFile(workshopFile)
    if workshopTable then
        currentWorkshopID = workshopTable.publishedFileID
        mj:log("currentWorkshopID:", currentWorkshopID)
        modDeveloperMenu.statusTextView.text = addedToWorkshopString
        uiStandardButton:setDisabled(addToSteamButton, true)
        uiStandardButton:setDisabled(uploadButton, false)
    else
        currentWorkshopID = nil
        modDeveloperMenu.statusTextView.text = notAddedToWorkshopString
        uiStandardButton:setDisabled(addToSteamButton, false)
        uiStandardButton:setDisabled(uploadButton, true)
    end

    subMenuCommon:slideOn(modDeveloperMenu, 1.0)
end

function modDeveloperMenu:hide()
    if modDeveloperMenu.mainView and (not modDeveloperMenu.mainView.hidden) then
        subMenuCommon:slideOff(modDeveloperMenu)
        return true
    end
    return false
end

function modDeveloperMenu:backButtonClicked()
    modDeveloperMenu:hide()
end

function modDeveloperMenu:hidden()
    return not (modDeveloperMenu.mainView and (not modDeveloperMenu.mainView.hidden))
end

return modDeveloperMenu