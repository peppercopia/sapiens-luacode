local steam = {}

local bridge = nil

function steam:createWorkshopID(callbackFunc)
    bridge:createWorkshopID(callbackFunc)
end

function steam:openURL(url)
    return bridge:openURL(url)
end

function steam:openStorePage()
    --bridge:openStorePage() --unfortunatley seems to go to a DLC purchase page. So we use openURL instead
    return steam:openURL("https://store.steampowered.com/app/1060230/Sapiens/")
end

function steam:uploadMod(currentWorkshopID, currentModInfo, replaceDescription, progressFunc, callbackFunc)
    bridge:uploadMod(currentWorkshopID, currentModInfo, replaceDescription, progressFunc, callbackFunc)
end

function steam:getCurrentBetaName()
    return bridge:getCurrentBetaName()
end

function steam:showGamepadTextInput(textEntryCallback, maxLength, existingText, descriptionText, isMultiline, isPassword)
    return bridge:showGamepadTextInput(textEntryCallback, maxLength or 1000, existingText or "", descriptionText or "", isMultiline or false, isPassword or false) --should return false if not in big picture mode
end

function steam:getPlayerName()
    return bridge:getPlayerName()
end

function steam:getPlayerSteamID()
    return bridge:getPlayerSteamID()
end

function steam:inviteFriends(callbackFunc)
    return bridge:inviteFriends(callbackFunc)
end

steam.floatingGamepadTextInputModes = {
    singleLine = 0,
    multiLine = 1,
    email = 2,
    numeric = 3,
}

function steam:showFloatingGamepadTextInput(floatingGamepadTextInputMode, pos, size) --this doesn't seem to move the pop up out of the way for the given pos, no matter what pos you give it, always puts popup in top left. Use showGamepadTextInput instead
    return bridge:showFloatingGamepadTextInput(floatingGamepadTextInputMode, pos, size)
end

function steam:setBridge(bridge_)
    bridge = bridge_
end

return steam