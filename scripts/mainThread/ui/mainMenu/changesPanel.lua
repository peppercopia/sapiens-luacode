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
local alertPanel = mjrequire "mainThread/ui/alertPanel"

local changesPanel = {
    displayReleaseNotesVersionIdentifier = "0.6.0", -- will display release notes on launch if haven't yet for this unique string. Does not need to match actual version string, and this string should not be displayed anywhere
    displayReleaseNotesMinorVersionIdentifier = "0.6.0",

    releaseNotesMajorVersionHumanReadable = "0.6",
    releaseNotesMinorVersionHumanReadable = "0.6.0",

    shouldDisplayMinorNotesOnStartup = true
}

-- NOTE don't forget to change releaseNotesMajorVersionHumanReadable
local titleString = "Fish - Update 0.6"

local changesText = [[This update adds seven different breeds of fish! It also brings new detailed textures and shaders, improves all animal models and behaviors, adds a range of colors for alpacas and woolskins, and contains a number of bug fixes and balancing tweaks.

Fish can only be caught via spears at the moment, which can be thrown from the water. Fish hunting and canoes in general still need some more work, and angling will be added within the next couple of updates. However fish are already a nice addition and a valuable food source.

In other news, Majic Jungle has an employee now, it's finally not just me! Paddy has been working on all of the new models for this update, and we'll be continuing to refine these new models, as well as improving a lot of the other models, textures and animations. 

And this is just a start, there is a lot of new content in the pipeline.

New in 0.6:
- Adds fish
- Improves Alpaca, chicken, mammoth models and animations
- New detailed textures and shaders for all objects
- New lighting model improving consistency, especially when moving between indoors and outdoors
- Adds a variety of alpaca wool colors
- Improved mob spawning, migrating, and general behaviors
- Improves water rendering, with major improvements for both high and low quality
- Fixes for multiplayer, making it easier and more reliable to invite and connect to Steam friends
- The role assignment UI now shows sapien age and distance, and allows sorting
- Adds option to invert mouse movement horizontally
- Adds option to disable chat notifications in multiplayer
- Removes the need to research every type of cooked food individually
- Gather, store, and transfer plans can now all be completed in the dark
- Canoes now correctly require wood working and not wood building
- Fixes bugs where they got stuck delivering or picking up resources
- Fixes bug where send/receive orders could get forgotten when your tribe hibernates
- Reduced birth rate, especially if food levels are low
- Faster spear hunting and baking research speeds
]]

-- NOTE don't forget to change releaseNotesMinorVersionHumanReadable
--local minorVersionChangesText = nil --set to nil to disable minor notes
local minorVersionChangesText = [[
0.6.0 fixes a few last bugs, and all going well this will be the final build before the public relase of 0.6.

Thank you to everyone who has been playing on the beta branch, submitting bugs and providing feedback!

New in 0.6.0:
- Adds option to disable chat notifications in multiplayer
- Adds cancel button when hovering over roles in the main sapien list panel
- Fixes issue where carcasses would go missing when hunting
- Fixes issue where changing settings on storage areas didn't immediately change the colors of the pegs/status markers
- Increases spawn rates of fish and mobs in coastal areas where they were too rare before
- Fixes issue where you couldn't build woolskin beds unless you had discovered hay
- Improvements to textures for urns, bowls, coconut logs, fur clothing, and more
- Fixes missing icons
]]

--[[Example:
local minorVersionChangesText = [[
0.4.2.3/0.2.3.4: Hot fixes for crashes on world creation. 
0.4.2.2: Minor update which fixes a couple of remaining AI issues from 0.4.2, including where sapiens could get stuck while hungry or at a compost heap. This update also adds a new zoom feature to the stats graph panel, to allow you to see the entire history of your tribe.
0.4.2: Major overhaul of the AI and order prioritization system. Your tribes will now function much more efficiently, and if they still don't quite do what you want, you now have a lot more control by prioritizing orders.

New in 0.4.2:
AI and fixes:
- You can now prioritize any order at any time. Sapiens will tend to choose prioritized orders to complete first.
- You can then deprioritize orders again to restore them to the default prioritization level
- Different plan types are now prioritized differently by default, so idle sapiens are much more likely to choose a recruit or hunt order than a store order.
- The outputs of prioritized orders retain the prioritization, so if you prioritize a gather order on an apple tree, then the store orders for the apples will also be prioritized
- If you manually assign sapiens to an order, they will drop everything and are much more likely to continue to work on that order.
- Sapiens are now a lot more likely to continue a single task to completion. Hunting in particular is much improved.
- Taking a required tool to an order site now requires the order's role, instead of the general labor role. This improves efficiency as that sapien can then complete the order, and it stops tools getting stuck lying around waiting for the right sapien.
- Telling a sapien to stop, or manually assigning a sapien to an order now causes them to drop what they were carrying
- More Fixes, optimizations, and UI improvements
    
Balancing changes in 0.4.2:
- More visitor tribes in the early stages of the game
- Visiting sapiens tend to stay longer
- Crucibles now degrade when used
- Reduced quantity of manure produced, as it was excessive and degraded performance
- Reduced quantity of sapien vocals when time is fast forwarded
]]

local releaseNotesInfoDefault = "For more information and news, visit the Sapiens News Hub on Steam:"
local releaseNotesInfoBeta = "For more information please join the Discord:"

local urlDefault = "https://store.steampowered.com/news/app/1060230"
local urlBeta = "https://discord.gg/VAkYw2r"

local backgroundSize = nil
local extraYBottomPadding = 120

local mainView = nil
local changesTextView = nil
local versionNumberTextView = nil
local versionNotesToggleLinkView = nil

local showingMinorNotes = false

local function getNotesToggleLinkString()
    if showingMinorNotes then
        return string.format(" show %s release notes", changesPanel.releaseNotesMajorVersionHumanReadable)
    end
    return string.format(" show %s release notes", changesPanel.releaseNotesMinorVersionHumanReadable)
end

local function updatePanelSize()
    local sizeToUse = vec2(backgroundSize.x, backgroundSize.y)
    sizeToUse.y = changesTextView.size.y + extraYBottomPadding

    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    
    mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    mainView.size = sizeToUse

    if versionNotesToggleLinkView then
        versionNumberTextView.baseOffset = vec3((versionNumberTextView.size.x + versionNotesToggleLinkView.size.x) * -0.5 + versionNumberTextView.size.x * 0.5, 0.0, 0.0)
        versionNotesToggleLinkView.baseOffset = vec3((versionNumberTextView.size.x + versionNotesToggleLinkView.size.x) * 0.5 - versionNotesToggleLinkView.size.x * 0.5, 0.0, 0.0)
    end
end

local function toggleMinorNotes()
    if showingMinorNotes then
        showingMinorNotes = false
        changesTextView.text = changesText
    else
        showingMinorNotes = true
        changesTextView.text = minorVersionChangesText
    end
    uiStandardButton:setText(versionNotesToggleLinkView, getNotesToggleLinkString())

    updatePanelSize()
end

function changesPanel:init(mainMenu, controller)
    
    backgroundSize = subMenuCommon.size

    mainView = ModelView.new(mainMenu.mainView)
    changesPanel.mainView = mainView
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.hidden = true

    local isBetaBranch = false
    local currentBetaName = steam:getCurrentBetaName()
    if currentBetaName and currentBetaName == "public-beta-unstable" or currentBetaName == "private-beta" then
        isBetaBranch = true
    end

    local versionTextString = "Version " .. controller:getVersionString()
    if controller:getIsDemo() then
        versionTextString = versionTextString .. string.format(" (%s)", locale:get("misc_demo"))
    elseif isBetaBranch then
        versionTextString = versionTextString .. string.format(" (%s)", currentBetaName)
    end
    
    local titleTextView = ModelTextView.new(mainView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,0, 0)
    titleTextView:setText(titleString, material.types.standardText.index)

    if minorVersionChangesText then
        versionNotesToggleLinkView = uiStandardButton:create(mainView, vec2(200,20), uiStandardButton.types.link)
        versionNotesToggleLinkView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
        versionNotesToggleLinkView.relativeView = titleTextView
        uiStandardButton:setText(versionNotesToggleLinkView, getNotesToggleLinkString())
        uiStandardButton:setClickFunction(versionNotesToggleLinkView, function()
            if minorVersionChangesText then
                toggleMinorNotes()
            end
        end)
    end

    versionNumberTextView = TextView.new(mainView)
    versionNumberTextView.font = Font(uiCommon.fontName, 16)
    versionNumberTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    versionNumberTextView.relativeView = titleTextView
    versionNumberTextView.text = versionTextString


    subMenuCommon:init(mainMenu, changesPanel, mainMenu.mainView.size)
    
    changesTextView = TextView.new(mainView)
    changesTextView.font = Font(uiCommon.fontName, 18)
    changesTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    changesTextView.textAlignment = MJHorizontalAlignmentLeft
    changesTextView.baseOffset = vec3(0,-120, 0)
    changesTextView.wrapWidth = backgroundSize.x - 80

    changesTextView.text = changesText

    local releaseNotesInfo = releaseNotesInfoDefault
    local url = urlDefault
    if isBetaBranch then
        releaseNotesInfo = releaseNotesInfoBeta
        url = urlBeta
    end

    
    if releaseNotesInfo then
        local releaseNotesInfoTextView = TextView.new(mainView)
        releaseNotesInfoTextView.font = Font(uiCommon.fontName, 18)
        releaseNotesInfoTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
        releaseNotesInfoTextView.relativeView = changesTextView
        releaseNotesInfoTextView.baseOffset = vec3(0,-10, 0)
        
        releaseNotesInfoTextView.text = releaseNotesInfo


        extraYBottomPadding = extraYBottomPadding + 100
        local releaseNotesButton = uiStandardButton:create(mainView, vec2(200,20), uiStandardButton.types.link)
        releaseNotesButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
        releaseNotesButton.relativeView = releaseNotesInfoTextView
        releaseNotesButton.baseOffset = vec3(0,0,0)
        uiStandardButton:setText(releaseNotesButton, url)
        uiStandardButton:setClickFunction(releaseNotesButton, function()
            if isBetaBranch then
                fileUtils.openFile(url)
            else
                if not steam:openURL(url) then
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
            end
        end)
    end

    
    local closeButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    closeButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionAbove)
    closeButton.baseOffset = vec3(30, -20, 0)
    uiStandardButton:setIconModel(closeButton, "icon_cross")
    uiStandardButton:setClickFunction(closeButton, function()
        changesPanel:hide()
    end)

    updatePanelSize()

end

function changesPanel:show(controller_, mainMenu, delay, showMajorNotes)
    if not changesPanel.mainView then
        --controller = controller_
        changesPanel:init(mainMenu, controller_)
    end

    if minorVersionChangesText and showMajorNotes ~= (not showingMinorNotes) then
        toggleMinorNotes()
    end

    subMenuCommon:slideOn(changesPanel, delay)
end

function changesPanel:hide()
    if changesPanel.mainView and (not changesPanel.mainView.hidden) then
        subMenuCommon:slideOff(changesPanel)
        return true
    end
    return false
end

function changesPanel:backButtonClicked()
    changesPanel:hide()
end

function changesPanel:hidden()
    return not (changesPanel.mainView and (not changesPanel.mainView.hidden))
end

return changesPanel