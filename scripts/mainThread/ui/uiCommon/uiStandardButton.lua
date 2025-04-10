local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4
local approxEqual = mjm.approxEqual

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiKeyImage = mjrequire "mainThread/ui/uiCommon/uiKeyImage"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local audio = mjrequire "mainThread/audio"
local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiStandardButton = {}

local standardTextColor = mj.textColor
local linkTextColor = (mj.textColor + mj.highlightColor) * 0.5
local selectedTextColor = mj.highlightColor
local disabledTextColor = mj.disabledTextColor

local orderMarkerWarningBackgroundScale = 1.1
local orderMarkerWarningIconScale = 0.8
local orderMarkerWarningIconYOffset = -0.2

local iconZOffsetMultiplier = 0.04

uiStandardButton.standardTabSize = vec2(180.0, 55.0)
uiStandardButton.standardTabPadding = 10.0


uiStandardButton.types = mj:enum {
    "standard_10x3",
    "title_10x3",
    "slim_1x1",
    "slim_1x1_bordered",
    "slim_1x1_bordered_dark",
    "toggle",
    "markerLike",
    "markerLikeSmall",
    "timeControl",
    "orderMarker",
    "orderMarkerSmall",
    "slim_4x1",
    "tabTitle",
    "tabInset",
    "tabInsetTitle",
    "tab_1x1",
    "link",
    "linkSmall",
    "circleIcon",
    "filterToggle",
    "favor_10x3",
    "popUpButton",
}

uiStandardButton.toggleMixedState = 2

local function updateVisuals(buttonTable)
    if buttonTable.textView then
        local overrideMaterialIndex = buttonTable.textMaterial
        if buttonTable.disabled then
            if buttonTable.embossedFont then
                buttonTable.textView:setText(buttonTable.text, overrideMaterialIndex or material.types.disabledText.index)
            else
                buttonTable.textView.text = buttonTable.text
                buttonTable.textView.color = disabledTextColor
            end
        else
            if buttonTable.selected or buttonTable.hover then
                if buttonTable.embossedFont then
                    buttonTable.textView:setText(buttonTable.text, overrideMaterialIndex or material.types.selectedText.index)
                else
                    buttonTable.textView.text = buttonTable.text
                    buttonTable.textView.color = buttonTable.selectedTextColor or selectedTextColor
                end
            else
                if buttonTable.embossedFont then
                    buttonTable.textView:setText(buttonTable.text, overrideMaterialIndex or material.types.standardText.index)
                else
                    buttonTable.textView.text = buttonTable.text
                    if buttonTable.isLink then
                        buttonTable.textView.color = linkTextColor
                    else
                        buttonTable.textView.color = standardTextColor
                    end
                end
            end
        end

        if buttonTable.textColor then
            buttonTable.textView.color = buttonTable.textColor
        end

        if buttonTable.objectView or buttonTable.icon then

            local iconViewToUse = buttonTable.objectView
            if not buttonTable.objectView then
                iconViewToUse = buttonTable.icon
            end
            local iconOffset = buttonTable.iconOffset
            
            iconViewToUse.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            buttonTable.textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)

            if buttonTable.centerIconAndText then
                local textPaddingX = 4
                local combinedWidth = iconViewToUse.size.x + textPaddingX + buttonTable.textView.size.x + 2 --add a little extra to allow for a bit of hidden padding in the icon
                local iconInnerLeft = buttonTable.initialSize.x * 0.5 - combinedWidth * 0.5
                
                iconViewToUse.baseOffset = vec3(iconInnerLeft + iconOffset.x,iconOffset.y,0.1 * buttonTable.iconHalfSize)

                local textOffset = iconInnerLeft + iconViewToUse.size.x + textPaddingX
                if buttonTable.textOffset then
                    buttonTable.textView.baseOffset = vec3(textOffset,buttonTable.textOffset,0)
                else
                    buttonTable.textView.baseOffset = vec3(textOffset,0,0)
                end

            else
                local objectPaddingX = 14
                local textOffset = iconViewToUse.size.x + objectPaddingX

                if buttonTable.textOffset then
                    buttonTable.textView.baseOffset = vec3(textOffset,buttonTable.textOffset,0)
                else
                    buttonTable.textView.baseOffset = vec3(textOffset,0,0)
                end

                iconViewToUse.baseOffset = vec3(objectPaddingX + iconOffset.x - 4,iconOffset.y,0.1 * buttonTable.iconHalfSize)
            end
        end
    end
    
    if buttonTable.isMarker then
        local baseSize = buttonTable.initialSize.x
        if buttonTable.type == uiStandardButton.types.orderMarker and (not buttonTable.orderMarkerCanCompleteState) then
            baseSize = baseSize * orderMarkerWarningBackgroundScale
        end

        local baseScale = 0.5
        local fullScale = 0.6
        
        if buttonTable.type ~= uiStandardButton.types.orderMarker then

            local circleMaterial = material.types.ui_standard.index

            if buttonTable.type == uiStandardButton.types.timeControl then
                fullScale = 0.7

                if buttonTable.disabled then
                    circleMaterial = material.types.ui_background.index
                elseif buttonTable.selected then
                    circleMaterial = buttonTable.selectionCircleMaterial or material.types.ui_standard.index --this is set directly in timeControls
                else
                    if buttonTable.secondarySelected then
                        circleMaterial = material.types.ui_standard.index

                        buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), {
                            [material.types.ui_standard.index] = circleMaterial
                        })
                    else
                        circleMaterial = material.types.ui_background.index
                    end
                end
            elseif buttonTable.selected then
                circleMaterial = material.types.ui_selected.index
            end

            buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), {
                [material.types.ui_standard.index] = circleMaterial
            })
        end

           --[[ backgroundMaterialRemapTable = {
                [material.types.ui_standard.index] = material.types.ui_background.index
            }]]

        if buttonTable.mouseDown or buttonTable.rightMouseDown then
            buttonTable.goalSize = baseSize * fullScale * 0.9
        else
            if buttonTable.selected or buttonTable.hover then
                buttonTable.goalSize = baseSize * fullScale
            else
                buttonTable.goalSize = baseSize * baseScale
            end
        end

        --mj:log("update:", buttonTable)

    end
    
    if buttonTable.type == uiStandardButton.types.timeControl then
        if buttonTable.icon then
            local iconMaterial = material.types.ui_standard.index
            
            if buttonTable.disabled then
                iconMaterial = material.types.ui_disabled.index
            elseif buttonTable.selected then
                iconMaterial = buttonTable.selectionCircleMaterial or material.types.ui_standard.index
            elseif buttonTable.hover then
                iconMaterial = material.types.selectedText.index
            end

            buttonTable.icon:setModel(model:modelIndexForName(buttonTable.iconModelName), {
                default = iconMaterial
            })
        end
    else
        if buttonTable.icon and buttonTable.type ~= uiStandardButton.types.orderMarker then
            local shouldUseSelectMaterial = false
            if buttonTable.selected or buttonTable.hover then
                shouldUseSelectMaterial = true
            end

            if (shouldUseSelectMaterial and not buttonTable.usingSelectedMaterial) or (not shouldUseSelectMaterial and buttonTable.usingSelectedMaterial) then
                buttonTable.usingSelectedMaterial = shouldUseSelectMaterial
                if shouldUseSelectMaterial then
                    buttonTable.icon:setModel(model:modelIndexForName(buttonTable.iconModelName), {
                        default = material.types.selectedText.index
                    })
                else
                    buttonTable.icon:setModel(model:modelIndexForName(buttonTable.iconModelName), buttonTable.iconBackgroundMaterialRemapTable)
                end
            end
        end
    end

    if buttonTable.type == uiStandardButton.types.slim_1x1_bordered or buttonTable.type == uiStandardButton.types.slim_1x1_bordered_dark or buttonTable.type == uiStandardButton.types.slim_1x1 then
        if buttonTable.disabled then
            buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), {
                default = material.types.ui_background_inset.index
            })

            if buttonTable.icon then
                buttonTable.icon:setModel(model:modelIndexForName(buttonTable.iconModelName), {
                    default = material.types.ui_disabled.index
                })
            end

        else
            if buttonTable.selected or buttonTable.hover then
                if buttonTable.type == uiStandardButton.types.slim_1x1_bordered_dark then
                    buttonTable.backgroundView:setModel(model:modelIndexForName("ui_button_slim_1x1_bordered"), {
                        [material.types.ui_background.index] = material.types.ui_background_dark.index
                    })
                else
                    buttonTable.backgroundView:setModel(model:modelIndexForName("ui_button_slim_1x1_bordered"))
                end
            else
                if buttonTable.type == uiStandardButton.types.slim_1x1_bordered_dark then
                    buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), {
                        default = material.types.ui_background_dark.index
                    })
                else
                    buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName))
                end
            end

            if buttonTable.icon then
                buttonTable.icon:setModel(model:modelIndexForName(buttonTable.iconModelName))
            end
        end
    elseif buttonTable.type == uiStandardButton.types.slim_4x1 then
        
        local backgroundMaterialTable = {}
        if buttonTable.backgroundMaterialRemapTable then
            for k,v in pairs(buttonTable.backgroundMaterialRemapTable) do
                backgroundMaterialTable[k] = v
            end
        end

        if buttonTable.selected or buttonTable.hover then
            backgroundMaterialTable[material.types.ui_selected.index] = material.types.ui_selected.index
            buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), backgroundMaterialTable)
        else
            buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), backgroundMaterialTable)
        end
    elseif buttonTable.type == uiStandardButton.types.tabInset then

        local backgroundMaterialTable = {}
        if buttonTable.activated then
            backgroundMaterialTable = {
                [material.types.ui_background.index] = material.types.ui_background_inset.index
            }
        end
        buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), backgroundMaterialTable)
    elseif buttonTable.type == uiStandardButton.types.tabInsetTitle then
        local backgroundMaterialTable = {}
        if buttonTable.activated then
            backgroundMaterialTable = {
                [material.types.ui_background.index] = material.types.ui_background_inset_lighter.index
            }
        else
            backgroundMaterialTable = {
                [material.types.ui_background.index] = material.types.ui_background_inset.index
            }
        end
        buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), backgroundMaterialTable)
    end
    
    --return material.types.ui_background_blue.index

    if buttonTable.secondaryHoverIcon then
        if buttonTable.selected or buttonTable.hover then
            buttonTable.secondaryHoverIcon.hidden = false
        else
            buttonTable.secondaryHoverIcon.hidden = true
        end
    end

    if buttonTable.isToggle then
        local selectedMaterialIndex = nil
        local standardMaterialIndex = buttonTable.toggleButtonHighlightMaterial or nil
        local modelName = buttonTable.modelName
        if buttonTable.toggleState then

            if buttonTable.toggleState == uiStandardButton.toggleMixedState then
                modelName = "ui_button_toggleMixed"
            end

            if buttonTable.disabled then
                selectedMaterialIndex = material.types.ui_disabled.index
            else
                if buttonTable.selected or buttonTable.hover then
                    selectedMaterialIndex = material.types.selectedText.index
                else
                    if buttonTable.toggleState == uiStandardButton.toggleMixedState then
                        selectedMaterialIndex = material.types.warning.index
                    else
                        selectedMaterialIndex = buttonTable.toggleButtonHighlightMaterial or material.types.ui_standard.index
                    end
                end
            end
        else
            selectedMaterialIndex = material.types.ui_background.index
            if buttonTable.type == uiStandardButton.types.filterToggle then
                standardMaterialIndex = material.types.ui_disabled.index
            end
        end
        
        if buttonTable.disabled then
            standardMaterialIndex = material.types.ui_disabled.index
        elseif buttonTable.selected or buttonTable.hover then
            standardMaterialIndex = material.types.selectedText.index
        end

        buttonTable.backgroundView:setModel(model:modelIndexForName(modelName), {
            [material.types.ui_selected.index] = selectedMaterialIndex,
            [material.types.ui_standard.index] = standardMaterialIndex,
        })
    end

    if buttonTable.keyImage then
        uiKeyImage:setDisabled(buttonTable.keyImage, buttonTable.disabled)
    end
end

local function updateScales(buttonTable)
    local scaleToUse = buttonTable.currentHalfSize
    buttonTable.backgroundView.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse)
    buttonTable.backgroundView.size = vec2(scaleToUse, scaleToUse) * 2.0
    if buttonTable.icon then
        local logoHalfSize = buttonTable.iconHalfSize
        if buttonTable.type == uiStandardButton.types.orderMarker and (not buttonTable.orderMarkerCanCompleteState) then
            logoHalfSize = logoHalfSize * orderMarkerWarningIconScale
        elseif buttonTable.type == uiStandardButton.types.circleIcon then
            logoHalfSize = logoHalfSize * 1.3
        end


        buttonTable.icon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
        buttonTable.icon.size = vec2(logoHalfSize,logoHalfSize) * 2.0

        local iconYOffset = buttonTable.icon.baseOffset.y
        buttonTable.icon.baseOffset = vec3(0,iconYOffset,iconZOffsetMultiplier * logoHalfSize)
    end
    if buttonTable.objectView then
        local logoHalfSize = buttonTable.iconHalfSize
        if buttonTable.type == uiStandardButton.types.orderMarker and (not buttonTable.orderMarkerCanCompleteState) then
            logoHalfSize = logoHalfSize * orderMarkerWarningIconScale
        end
        if buttonTable.type == uiStandardButton.types.orderMarkerSmall or 
        buttonTable.type == uiStandardButton.types.markerLikeSmall or
        buttonTable.type == uiStandardButton.types.timeControl then
            logoHalfSize = buttonTable.iconHalfSize * 1.5 
        end
        uiGameObjectView:setSize(buttonTable.objectView, vec2(logoHalfSize,logoHalfSize) * 2.0)
        --buttonTable.objectView.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
       -- buttonTable.objectView.size = vec2(logoHalfSize,logoHalfSize) * 2.0
    end
    if buttonTable.secondaryHoverIcon then
        local logoHalfSize = buttonTable.iconHalfSize
        if buttonTable.type == uiStandardButton.types.orderMarker and (not buttonTable.orderMarkerCanCompleteState) then
            logoHalfSize = logoHalfSize * orderMarkerWarningIconScale
        end
        buttonTable.secondaryHoverIcon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
        buttonTable.secondaryHoverIcon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
    end
end


function uiStandardButton:create(parentView, size, typeOrNilFor10x3, backgroundMaterialRemapTableOrNil)
    local buttonTable = {
        uiStandardButton = true,
        selected = false,
        hover = false,
        mouseDown = false,
        rightMouseDown = false,
        initialSize = size,
        fontSize = 16,
        fontName = uiCommon.fontName,
        currentHalfSize = size.y * 0.5,
        iconHalfSize = size.y * 0.4,
        iconOffset = vec2(0.0,0.0),
        textOffset = nil,
        isToggle = false,
        toggleState = false,
        isMarker = false,
        isLink = false,
        type = typeOrNilFor10x3 or uiStandardButton.types.standard_10x3
    }

    local buttonView = View.new(parentView)
    buttonView.userData = buttonTable
    buttonTable.view = buttonView
    buttonView.size = size

    local buttonHoverZOffset = nil --default declared in uiCommon, probably 2.0

    local backgroundMaterialRemapTable = backgroundMaterialRemapTableOrNil

    local heightMultiplier = 0.3
    local modelName = "ui_button_10x3"
    local modelZScale = nil

    if typeOrNilFor10x3 == uiStandardButton.types.slim_1x1 then
        buttonHoverZOffset = 1.2
        heightMultiplier = 1.0
        modelName = "ui_button_slim_1x1"
    elseif typeOrNilFor10x3 == uiStandardButton.types.slim_1x1_bordered or typeOrNilFor10x3 == uiStandardButton.types.slim_1x1_bordered_dark then
        buttonHoverZOffset = 1.2
        heightMultiplier = 1.0
        modelName = "ui_button_slim_1x1"
    elseif typeOrNilFor10x3 == uiStandardButton.types.slim_4x1 then
        buttonHoverZOffset = 1.2
        heightMultiplier = 0.3
        modelName = "ui_panel_10x3_bordered"
    elseif typeOrNilFor10x3 == uiStandardButton.types.title_10x3 then
        buttonTable.fontSize = 28
        buttonTable.fontName = uiCommon.titleFontName
        buttonTable.textOffset = 4.0
        buttonTable.embossedFont = true
        buttonTable.iconHalfSize = size.y * 0.28
        buttonTable.iconOffset = vec2(0.0,size.y * 0.05)
    elseif typeOrNilFor10x3 == uiStandardButton.types.tabTitle then
        buttonTable.fontSize = 28
        buttonTable.fontName = uiCommon.titleFontName
        buttonTable.textOffset = 2.0
        buttonTable.embossedFont = true
        buttonTable.iconHalfSize = size.y * 0.2
        buttonTable.iconOffset = vec2(-4.0,0.0)
        buttonTable.centerIconAndText = true
        buttonTable.disableHoverWhenSelected = true
        modelName = "ui_button_tab"
        modelZScale = 500.0
    elseif typeOrNilFor10x3 == uiStandardButton.types.tabInset then
        buttonTable.fontSize = 18
        buttonTable.fontName = uiCommon.fontName
        buttonTable.textOffset = 2.0
        buttonTable.embossedFont = false
        --buttonTable.selectedTextColor = standardTextColor
       -- buttonTable.iconHalfSize = size.y * 0.16
        --buttonTable.iconOffset = vec2(0.0,2.0)
        --buttonTable.centerIconAndText = true
        buttonTable.disableHoverWhenSelected = true
        modelName = "ui_button_tab"
        modelZScale = 500.0
    elseif typeOrNilFor10x3 == uiStandardButton.types.tabInsetTitle then
        buttonTable.fontSize = 24
        buttonTable.fontName = uiCommon.titleFontName
        buttonTable.textOffset = 2.0
        buttonTable.embossedFont = true
        --buttonTable.selectedTextColor = standardTextColor
       -- buttonTable.iconHalfSize = size.y * 0.16
        --buttonTable.iconOffset = vec2(0.0,2.0)
        --buttonTable.centerIconAndText = true
        buttonTable.disableHoverWhenSelected = true
        modelName = "ui_button_tab"
        modelZScale = 500.0
    elseif typeOrNilFor10x3 == uiStandardButton.types.tab_1x1 then
        buttonTable.fontSize = 28
        buttonTable.fontName = uiCommon.titleFontName
        buttonTable.textOffset = 2.0
        buttonTable.textXOffset = -4.0
        buttonTable.embossedFont = true
        buttonTable.iconHalfSize = size.y * 0.16
        buttonTable.iconOffset = vec2(0.0,2)
        --buttonTable.centerIconAndText = true
        buttonTable.disableHoverWhenSelected = true
        modelName = "ui_button_tab_1x1"
        modelZScale = 500.0
        heightMultiplier = 1.0
    elseif buttonTable.type == uiStandardButton.types.standard_10x3 then
        buttonTable.iconHalfSize = size.y * 0.28
        buttonTable.iconOffset = vec2(0.0,size.y * 0.05)
    elseif buttonTable.type == uiStandardButton.types.favor_10x3 then
        buttonTable.iconHalfSize = size.y * 0.28
        buttonTable.iconOffset = vec2(0.0,size.y * 0.05)
        modelName = "ui_button_favorEdge_10x3"
        buttonTable.selectedTextColor = mj.highlightColorFavor
        backgroundMaterialRemapTable = {
            [material.types.ui_background_button.index] = material.types.ui_background_inset_lighter.index,
        }
    elseif typeOrNilFor10x3 == uiStandardButton.types.toggle then
        buttonHoverZOffset = 1.2
        heightMultiplier = 1.0
        modelName = "ui_button_toggle"
        buttonTable.isToggle = true
    elseif typeOrNilFor10x3 == uiStandardButton.types.filterToggle then
        buttonHoverZOffset = 1.2
        heightMultiplier = 1.0
        modelName = "ui_button_filterToggle"
        buttonTable.isToggle = true
        buttonTable.useSmallToggleTickOverlay = true
        buttonTable.iconHalfSize = size.y * 0.25
    elseif typeOrNilFor10x3 == uiStandardButton.types.markerLike or typeOrNilFor10x3 == uiStandardButton.types.orderMarker then
        heightMultiplier = 1.0
        modelName = "ui_order"
        buttonTable.currentHalfSize = size.y * 0.4
        buttonTable.goalSize = size.y * 0.5
        buttonTable.differenceVelocity = 0.0
        buttonTable.isMarker = true
        if buttonTable.type == uiStandardButton.types.orderMarker then
            buttonTable.orderMarkerCanCompleteState = true
            backgroundMaterialRemapTable = {
                [material.types.ui_standard.index] = material.types.ok.index
            }
        end
    elseif typeOrNilFor10x3 == uiStandardButton.types.markerLikeSmall or typeOrNilFor10x3 == uiStandardButton.types.orderMarkerSmall then
        heightMultiplier = 1.0
        modelName = "ui_orderSmall"
        buttonTable.currentHalfSize = size.y * 0.4
        buttonTable.goalSize = size.y * 0.5
        buttonTable.differenceVelocity = 0.0
        buttonTable.isMarker = true
    elseif typeOrNilFor10x3 == uiStandardButton.types.timeControl then
        heightMultiplier = 1.0
        modelName = "ui_orderSmall"
        buttonTable.currentHalfSize = size.y * 0.4
        buttonTable.goalSize = size.y * 0.5
        buttonTable.differenceVelocity = 0.0
        buttonTable.isMarker = true
        backgroundMaterialRemapTable = {
            [material.types.ui_standard.index] = material.types.ui_background.index
        }
    elseif typeOrNilFor10x3 == uiStandardButton.types.circleIcon then
        heightMultiplier = 1.0
        modelName = "ui_order"
        buttonTable.currentHalfSize = size.y * 0.4
        buttonTable.goalSize = size.y * 0.5
        buttonTable.differenceVelocity = 0.0
        buttonTable.isMarker = true
        backgroundMaterialRemapTable = {
            [material.types.ui_standard.index] = material.types.ui_background.index
        }
    elseif typeOrNilFor10x3 == uiStandardButton.types.link or typeOrNilFor10x3 == uiStandardButton.types.linkSmall then
        modelName = nil
        buttonTable.isLink = true
        if typeOrNilFor10x3 == uiStandardButton.types.linkSmall then
            buttonTable.fontSize = 14
        end
    elseif typeOrNilFor10x3 == uiStandardButton.types.popUpButton then
        modelName = "ui_button_popup_10x3"
        buttonTable.iconHalfSize = size.y * 0.24
    end

    buttonTable.modelName = modelName
    buttonTable.backgroundMaterialRemapTable = backgroundMaterialRemapTable

    local backgroundView = nil
    if modelName then
        backgroundView = ModelView.new(buttonView)
        if backgroundMaterialRemapTable then
            backgroundView:setModel(model:modelIndexForName(modelName), backgroundMaterialRemapTable)
        else
            backgroundView:setModel(model:modelIndexForName(modelName))
        end
        local scaleToUseX = size.x * 0.5
        local scaleToUseY = size.y * 0.5 / heightMultiplier
        backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,modelZScale or scaleToUseX)
        
        if buttonTable.isMarker then
            backgroundView:setUsesModelHitTest(true)
        end
    else
        backgroundView = View.new(buttonView)
        backgroundView.masksEvents = true
    end
    backgroundView.size = size
    buttonTable.backgroundView = backgroundView


    if buttonTable.isToggle then
        uiStandardButton:setToggleState(buttonView, false)
    end


    backgroundView.hoverStart = function ()
        if not buttonTable.hover then
            if not buttonTable.disabled and ((not buttonTable.disableHoverWhenSelected) or (not buttonTable.selected)) then
               -- mj:log("hover start:", buttonTable.view)
                buttonTable.hover = true
                audio:playUISound(uiCommon.hoverSoundFile)
                updateVisuals(buttonTable)
            end
        end
    end

    backgroundView.hoverEnd = function ()
        if buttonTable.hover then
           -- mj:log("hover end:", buttonTable.view)
            buttonTable.hover = false
            buttonTable.mouseDown = false
            buttonTable.rightMouseDown = false
            updateVisuals(buttonTable)
        end
    end

    backgroundView.mouseDown = function (buttonIndex)
        if buttonIndex == 0 then
            if not buttonTable.mouseDown then
                if not buttonTable.disabled and ((not buttonTable.disableHoverWhenSelected) or (not buttonTable.selected)) then
                    buttonTable.mouseDown = true
                    updateVisuals(buttonTable)
                    audio:playUISound(uiCommon.clickDownSoundFile)
                end
            end
        elseif buttonIndex == 1 and buttonTable.rightClickFunction then
            if not buttonTable.rightMouseDown then
                if not buttonTable.disabled and ((not buttonTable.disableHoverWhenSelected) or (not buttonTable.selected)) then
                    buttonTable.rightMouseDown = true
                    updateVisuals(buttonTable)
                    audio:playUISound(uiCommon.clickDownSoundFile)
                end
            end
        end
    end

    backgroundView.mouseUp = function (buttonIndex)
        if buttonIndex == 0 then
            if buttonTable.mouseDown then
                buttonTable.mouseDown = false
                updateVisuals(buttonTable)
                audio:playUISound(uiCommon.clickReleaseSoundFile)
            end
        elseif buttonIndex == 1 then
            if buttonTable.rightMouseDown then
                buttonTable.rightMouseDown = false
                updateVisuals(buttonTable)
                audio:playUISound(uiCommon.clickReleaseSoundFile)
            end
        end
    end

    backgroundView.click = function()
        if not buttonTable.disabled and ((not buttonTable.disableHoverWhenSelected) or (not buttonTable.selected)) then
            if buttonTable.isToggle  then
                uiStandardButton:toggle(buttonView)
            end

            if buttonTable.clickFunction then
                buttonTable.clickFunction()
            end
        end
    end

    backgroundView.rightClick = function()
        if not buttonTable.disabled and ((not buttonTable.disableHoverWhenSelected) or (not buttonTable.selected)) then
            if buttonTable.rightClickFunction then
                buttonTable.rightClickFunction()
            end
        end
    end

    if buttonTable.isMarker then
        backgroundView.update = function(dt)
            if (not approxEqual(buttonTable.goalSize, buttonTable.currentHalfSize)) or (not approxEqual(buttonTable.differenceVelocity, 0.0)) then
                local difference = buttonTable.goalSize - buttonTable.currentHalfSize
                local clampedDT = mjm.clamp(dt * 40.0, 0.0, 1.0)
                buttonTable.differenceVelocity = buttonTable.differenceVelocity * math.max(1.0 - dt * 20.0, 0.0) + (difference * clampedDT)
                buttonTable.currentHalfSize = buttonTable.currentHalfSize + buttonTable.differenceVelocity * dt * 12.0
                buttonTable.iconHalfSize = buttonTable.currentHalfSize * 0.5

                updateScales(buttonTable)
            end
        end
    else
        backgroundView.update = uiCommon:createButtonUpdateFunction(buttonTable, buttonView, buttonHoverZOffset)
    end

    updateVisuals(buttonTable)
    
    return buttonView
end

function uiStandardButton:setOrderMarkerCanComplete(buttonView, newCanComplete)
    
    local buttonTable = buttonView.userData
    if buttonTable.type == uiStandardButton.types.orderMarker and buttonTable.orderMarkerCanCompleteState ~= newCanComplete then
        buttonTable.orderMarkerCanCompleteState = newCanComplete
        local newSize = buttonTable.initialSize.x * 0.5
        local iconYOffset = 0.0
        if not newCanComplete then
            newSize = newSize * orderMarkerWarningBackgroundScale
            buttonTable.backgroundView:setModel(model:modelIndexForName("ui_order_warning"))
            iconYOffset = newSize * 0.8 * orderMarkerWarningIconYOffset
        else
            buttonTable.backgroundView:setModel(model:modelIndexForName("ui_order"), {
                [material.types.ui_standard.index] = material.types.ok.index
            })
        end

        buttonTable.goalSize = newSize
        buttonTable.currentHalfSize = newSize * 0.5
        buttonTable.iconHalfSize = buttonTable.currentHalfSize * 0.5

        if buttonTable.icon then
            buttonTable.icon.baseOffset = vec3(0,iconYOffset,iconZOffsetMultiplier * buttonTable.currentHalfSize)
        end
        if buttonTable.secondaryHoverIcon then
            buttonTable.secondaryHoverIcon.baseOffset = vec3(0,iconYOffset * 1.5,iconZOffsetMultiplier * buttonTable.currentHalfSize)
        end
        
        updateScales(buttonTable)
    end

end

function uiStandardButton:setToggleState(buttonView, toggleState)
    if toggleState ~= buttonView.userData.toggleState then
        buttonView.userData.toggleState = toggleState
        updateVisuals(buttonView.userData)
    end
end

function uiStandardButton:toggle(buttonView)
    uiStandardButton:setToggleState(buttonView, (not uiStandardButton:getToggleState(buttonView)))
end

function uiStandardButton:getToggleState(buttonView)
    return buttonView.userData.toggleState
end

function uiStandardButton:reloadBackgroundModelView(buttonView, backgroundMaterialRemapTableOrNil)
    local buttonTable = buttonView.userData
    buttonTable.backgroundMaterialRemapTable = backgroundMaterialRemapTableOrNil
    if backgroundMaterialRemapTableOrNil then
        buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName), backgroundMaterialRemapTableOrNil)
    else
        buttonTable.backgroundView:setModel(model:modelIndexForName(buttonTable.modelName))
    end
end

function uiStandardButton:setClickFunction(buttonView, clickFunction)
    buttonView.userData.clickFunction = clickFunction
end

function uiStandardButton:callClickFunction(buttonView)
    local buttonTable = buttonView.userData
    if not buttonTable.disabled then
        if buttonTable.isToggle  then
            uiStandardButton:toggle(buttonView)
        end

        if buttonTable.clickFunction then
            buttonTable.clickFunction()
        end
    end
end

function uiStandardButton:setRightClickFunction(buttonView, rightClickFunction)
    buttonView.userData.rightClickFunction = rightClickFunction
end

function uiStandardButton:setSelected(buttonView, selected)
    if selected ~= buttonView.userData.selected then
        buttonView.userData.selected = selected
        if buttonView.userData.selectionChangedCallbackFunction then
            buttonView.userData.selectionChangedCallbackFunction(selected)
        end
        if selected and buttonView.userData.disableHoverWhenSelected then
            buttonView.userData.hover = false
            buttonView.userData.mouseDown = false
            buttonView.userData.rightMouseDown = false
        end
        updateVisuals(buttonView.userData)
    end
end

function uiStandardButton:setSecondarySelected(buttonView, secondarySelected)
    if secondarySelected ~= buttonView.userData.secondarySelected then
        buttonView.userData.secondarySelected = secondarySelected
        updateVisuals(buttonView.userData)
    end
end

function uiStandardButton:setActivated(buttonView, activated)
    if activated ~= buttonView.userData.activated then
        buttonView.userData.activated = activated
        updateVisuals(buttonView.userData)
    end
end

function uiStandardButton:setSelectionChangedCallbackFunction(buttonView, callbackFunction)
    buttonView.userData.selectionChangedCallbackFunction = callbackFunction
end

function uiStandardButton:setDisabled(buttonView, disabled)
    if disabled ~= buttonView.userData.disabled then
        buttonView.userData.disabled = disabled
        updateVisuals(buttonView.userData)
    end
end

function uiStandardButton:getDisabled(buttonView)
    return buttonView.userData.disabled
end

function uiStandardButton:resetAnimationState(buttonView)
    local info = buttonView.userData
    if info.isMarker then
        updateVisuals(info)
        info.currentHalfSize = info.goalSize
        info.iconHalfSize = info.currentHalfSize * 0.5
        info.differenceVelocity = 0.0
        local scaleToUse = info.currentHalfSize
        info.backgroundView.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse)
        info.backgroundView.size = vec2(info.currentHalfSize, info.currentHalfSize)
        if info.icon then
            local logoHalfSize = info.iconHalfSize
            info.icon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
            info.icon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
        end
    end
end

function uiStandardButton:resize(buttonView, size)
    buttonView.size = size
    local scaleToUseX = size.x * 0.5
    local scaleToUseY = size.y * 0.5 / 0.3
    local backgroundView = buttonView.userData.backgroundView
    backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    backgroundView.size = size
end

local function createTextViewIfNeeded(buttonView)
    if not buttonView.userData.textView then
        local buttonTable = buttonView.userData

        local textView = nil
        if buttonTable.embossedFont then
            textView = ModelTextView.new(buttonView)
        else
            textView = TextView.new(buttonView)
        end
        textView.font = Font(buttonTable.fontName, buttonTable.fontSize)
        textView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        local xOffset = buttonTable.textXOffset or 0
        local yOffset = buttonTable.textOffset or 0
        textView.baseOffset = vec3(xOffset,yOffset,0)
        buttonTable.textView = textView
    end
end

function uiStandardButton:setText(buttonView, text)
    if text then
        createTextViewIfNeeded(buttonView)
    end
    local buttonTable = buttonView.userData
    buttonTable.text = text

    updateVisuals(buttonTable)

    if buttonTable.type == uiStandardButton.types.link or buttonTable.type == uiStandardButton.types.linkSmall then
        local newSize = buttonTable.textView.size
        buttonView.size = newSize
        local backgroundView = buttonTable.backgroundView
        backgroundView.size = newSize
    end
end

function uiStandardButton:setTextMaterial(buttonView, textMaterial)
    buttonView.userData.textMaterial = textMaterial
    updateVisuals(buttonView.userData)
end

function uiStandardButton:setTextColor(buttonView, textColor)
    buttonView.userData.textColor = textColor
    updateVisuals(buttonView.userData)
end

function uiStandardButton:setTextWithShortcut(buttonView, text, groupKey, mappingKey, controllerSetIndex, controllerActionName)

    --[[if not (controllerSetIndex and controllerActionName) then
        mj:warn("No controller mapping for button with keyboard shortcut:\"", text, "\" key groupKey:", groupKey, " key mappingKey:", mappingKey, " traceback:", debug.traceback())
    end]]

    local buttonTable = buttonView.userData
    if text then
        createTextViewIfNeeded(buttonView)
    end
    --local textChanged = buttonTable.text ~= text
    buttonTable.text = text
    buttonTable.textView.text = buttonTable.text

    local keyImagePadding = 4
    local keyImageWidth = 18--buttonView.size.y * 0.6

    local function updateKeyImageSize(uiKeyImageView)
        local textXOffset = -(uiKeyImageView.size.x + keyImagePadding) * 0.5
        buttonTable.textView.baseOffset = vec3(textXOffset, buttonTable.textView.baseOffset.y, buttonTable.textView.baseOffset.z)
        --mj:log("keyImage.baseOffset a:", uiKeyImageView.baseOffset)
        uiKeyImageView.baseOffset = vec3(buttonTable.textView.size.x * 0.5 + keyImagePadding, 1, 0)
        --mj:log(uiKeyImageView.baseOffset)
    end

    if buttonTable.keyImage then
        buttonView:removeSubview(buttonTable.keyImage)
        buttonTable.keyImage = nil
    end

    --if not buttonTable.keyImage then
        local keyImage = uiKeyImage:create(buttonView, keyImageWidth, groupKey, mappingKey, controllerSetIndex, controllerActionName, updateKeyImageSize)
        buttonTable.keyImage = keyImage
        uiKeyImage:setDisabled(keyImage, buttonTable.disabled)
    --[[else
        if textChanged then
            updateKeyImageSize(buttonTable.keyImage)
        end
    end]]
    
    updateVisuals(buttonView.userData)
    

end

function uiStandardButton:setObjectIcon(buttonView, objectInfo)
    if objectInfo then
        local buttonTable = buttonView.userData
        if not buttonTable.objectView then
            
            local iconHalfSize = buttonTable.iconHalfSize / 0.8 --uiGameObjectView scales down the icon by 0.8, so this accounts for that for consistency
            local gameObjectView = uiGameObjectView:create(buttonView, vec2(iconHalfSize * 2.0,iconHalfSize * 2.0), uiGameObjectView.types.standard)
            --uiGameObjectView:setBackgroundAlpha(gameObjectView, 0.6)
            gameObjectView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
            uiGameObjectView:setObject(gameObjectView, objectInfo, nil, nil)
            gameObjectView.masksEvents = false

            buttonTable.objectView = gameObjectView
        else
            uiGameObjectView:setObject(buttonTable.objectView, objectInfo, nil, nil)
            --mj:log("update:", objectInfo)
        end
    elseif buttonView.userData.objectView then
        buttonView:removeSubview(buttonView.userData.objectView)
        buttonView.userData.objectView = nil
    end
    updateVisuals(buttonView.userData)
end

function uiStandardButton:setImage(buttonView, imagePath)
    local imageView = ImageView.new(buttonView)
    imageView.imageTexture = MJCache:getTexture(imagePath)
    imageView.size = buttonView.userData.view.size - vec2(4,4)
    imageView.color = standardTextColor
    buttonView.userData.imageView = imageView
    updateVisuals(buttonView.userData)
end

function uiStandardButton:setCenterIconAndText(buttonView, centerIconAndText)
    if buttonView.userData.centerIconAndText ~= centerIconAndText then
        buttonView.userData.centerIconAndText = centerIconAndText
        updateVisuals(buttonView.userData)
    end
end

function uiStandardButton:setIconModel(buttonView, modelName, backgroundMaterialRemapTableOrNil)
    local buttonTable = buttonView.userData

    if buttonTable.icon then
        buttonView:removeSubview(buttonTable.icon)
        buttonTable.icon = nil
    end

    if modelName then

        local backgroundMaterialRemapTable = backgroundMaterialRemapTableOrNil
        buttonTable.iconBackgroundMaterialRemapTable = backgroundMaterialRemapTableOrNil

        local icon = ModelView.new(buttonView)
        icon.masksEvents = false

        local logoHalfSize = buttonTable.iconHalfSize
        local iconYOffset = 0.0

        if buttonTable.type == uiStandardButton.types.orderMarker then
            local materialToUse = material.types.ok.index
            if not buttonTable.orderMarkerCanCompleteState then
                materialToUse = material.types.warning.index
                logoHalfSize = logoHalfSize * orderMarkerWarningIconScale
                iconYOffset = buttonTable.currentHalfSize * orderMarkerWarningIconYOffset
            end
            if not backgroundMaterialRemapTable then
                backgroundMaterialRemapTable = {
                    default = materialToUse
                }
            end
        end

        if backgroundMaterialRemapTable then
            icon:setModel(model:modelIndexForName(modelName), backgroundMaterialRemapTable)
        else
            icon:setModel(model:modelIndexForName(modelName))
        end
        
        icon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
        icon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
        icon.baseOffset = vec3(0,iconYOffset,iconZOffsetMultiplier * logoHalfSize)

        buttonTable.icon = icon
        buttonTable.iconModelName = modelName
        buttonTable.usingSelectedMaterial = false
    else
        buttonTable.icon = nil
        buttonTable.iconModelName = nil
        buttonTable.usingSelectedMaterial = false
    end

    updateVisuals(buttonTable)
end

function uiStandardButton:setToggleButtonHighlightMaterial(buttonView, materialIndex)
    local buttonTable = buttonView.userData
    buttonTable.toggleButtonHighlightMaterial = materialIndex
    updateVisuals(buttonTable)
end

function uiStandardButton:setSelectedTextColor(buttonView, selectedTextColor_)
    local buttonTable = buttonView.userData
    buttonTable.selectedTextColor = selectedTextColor_
    updateVisuals(buttonTable)
end

function uiStandardButton:setSecondaryHoverIconModel(buttonView, modelName, backgroundMaterialRemapTableOrNil)
    local buttonTable = buttonView.userData

    if (not modelName) and (not buttonTable.secondaryHoverIcon) then
        return
    end

    if buttonTable.secondaryHoverIcon then
        buttonView:removeSubview(buttonTable.secondaryHoverIcon)
        buttonTable.secondaryHoverIcon = nil
    end

    if modelName then

        local secondaryIcon = ModelView.new(buttonView)
        secondaryIcon.masksEvents = false

        local logoHalfSize = buttonTable.iconHalfSize
        local iconYOffset = 0.0

        if buttonTable.type == uiStandardButton.types.orderMarker then
            if not buttonTable.orderMarkerCanCompleteState then
                logoHalfSize = logoHalfSize * orderMarkerWarningIconScale
                iconYOffset = buttonTable.currentHalfSize * orderMarkerWarningIconYOffset
            end
        end

        if backgroundMaterialRemapTableOrNil then
            secondaryIcon:setModel(model:modelIndexForName(modelName), backgroundMaterialRemapTableOrNil)
        else
            secondaryIcon:setModel(model:modelIndexForName(modelName))
        end
        
        secondaryIcon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
        secondaryIcon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
        secondaryIcon.baseOffset = vec3(0,iconYOffset * 1.5,iconZOffsetMultiplier * logoHalfSize * 1.5)

        secondaryIcon.hidden = true

        buttonTable.secondaryHoverIcon = secondaryIcon
    end

    updateVisuals(buttonTable)
end

function uiStandardButton:addAdditionalHoverFunctions(buttonView, hoverStarted, hoverEnded)
    local buttonTable = buttonView.userData

    if hoverStarted then
        local prevHoverStartFunction = buttonTable.backgroundView.hoverStart
        buttonTable.backgroundView.hoverStart = function()
            prevHoverStartFunction()
            hoverStarted()
        end
    end
    
    if hoverEnded then
        local prevHoverEndFunction = buttonTable.backgroundView.hoverEnd
        buttonTable.backgroundView.hoverEnd = function()
            prevHoverEndFunction()
            hoverEnded()
        end
    end
end

return uiStandardButton