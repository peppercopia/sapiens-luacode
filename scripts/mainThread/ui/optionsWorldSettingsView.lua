local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4

--local model = mjrequire "common/model"
--local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

--local gameConstants = mjrequire "common/gameConstants"
--local eventManager = mjrequire "mainThread/eventManager"
--local keyMapping = mjrequire "mainThread/keyMapping"
local logicInterface = mjrequire "mainThread/logicInterface"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"

local optionsWorldSettingsView = {}

--"getWorldSettings"

local tribeSpawnButton = nil
local autoRoleAssignmentToggleButton = nil
local world = nil

function optionsWorldSettingsView:update()
    if tribeSpawnButton then
        local function setUIDisabled(disabled)
            uiStandardButton:setDisabled(tribeSpawnButton, disabled)
        end

        setUIDisabled(true)

        logicInterface:callServerFunction("getWorldSettings", nil, function(result)

            --mj:log("optionsWorldSettingsView result:", result)
            uiStandardButton:setToggleState(tribeSpawnButton, (not result.disableTribeSpawns))

            setUIDisabled(false)
        end)
        uiStandardButton:setToggleState(autoRoleAssignmentToggleButton, world:getAutoRoleAssignmentEnabled())
    end
end

function optionsWorldSettingsView:create(world_, mainParentView, elementYOffset)
    world = world_

    local yOffsetBetweenElements = 35
    local elementTitleX = -mainParentView.size.x * 0.5 - 10
    local elementControlX = mainParentView.size.x * 0.5

    local function addToggleButton(parentView, toggleButtonTitle, tipText, toggleValue, changedFunction)
        local toggleButton = uiStandardButton:create(parentView, vec2(26,26), uiStandardButton.types.toggle)
        toggleButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        toggleButton.baseOffset = vec3(elementControlX, elementYOffset, 0)
        uiStandardButton:setToggleState(toggleButton, toggleValue)
        
        local textView = TextView.new(parentView)
        textView.font = Font(uiCommon.fontName, 16)
        textView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
        textView.baseOffset = vec3(elementTitleX,elementYOffset - 4, 0)
        textView.text = toggleButtonTitle

        if tipText then
            uiToolTip:add(toggleButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), tipText, nil, vec3(0,-8,10), nil, toggleButton, parentView)
        end
    
        uiStandardButton:setClickFunction(toggleButton, function()
            changedFunction(uiStandardButton:getToggleState(toggleButton))
        end)

        elementYOffset = elementYOffset - yOffsetBetweenElements
        
        uiSelectionLayout:addView(parentView, toggleButton)
        return toggleButton
    end


    tribeSpawnButton = addToggleButton(mainParentView, locale:get("worldSettings_tribeSpawns") .. ":", locale:get("worldSettings_tribeSpawns_tip"), true, function(newValue)
        logicInterface:callServerFunction("changeWorldSetting", 
        {
            key = "disableTribeSpawns",
            value = (not newValue),
        })
    end)



    autoRoleAssignmentToggleButton = addToggleButton(mainParentView, locale:get("ui_roles_assignAutomatically") .. ":", locale:get("ui_roles_assignAutomatically_toolTip"), true, function(newValue)
        world:setAutoRoleAssignmentEnabled(uiStandardButton:getToggleState(autoRoleAssignmentToggleButton))
    end)

end

return optionsWorldSettingsView