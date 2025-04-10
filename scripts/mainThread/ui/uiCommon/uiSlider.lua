local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local audio = mjrequire "mainThread/audio"

local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiSlider = {}


function uiSlider:setValue(sliderView, value)
    local buttonTable = sliderView.userData
    local knobView = buttonTable.knobView
    buttonTable.value = value

    local fraction = (value - buttonTable.min) / (buttonTable.max - buttonTable.min)
    local knobX = buttonTable.backgroundSize.x * fraction
    knobView.baseOffset = vec3(knobX, 0, 1)

end

local function updateVisuals(buttonTable)
    local newBlueHighlight = ((not buttonTable.disabled) and (buttonTable.mouseDown or buttonTable.hover or buttonTable.selected))

    local function setBackgroundSelectedMaterial(materialTypeIndex)
        buttonTable.knobView:setModel(model:modelIndexForName("ui_slider_knob"), {
            [material.types.ui_standard.index] = materialTypeIndex
        })
        
        buttonTable.backgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg_short"), {
            [material.types.ui_standard.index] = materialTypeIndex
        })
    end

    if newBlueHighlight then
        buttonTable.knobView.hidden = false
        setBackgroundSelectedMaterial(material.types.ui_selected.index)
    elseif buttonTable.disabled then
        buttonTable.knobView.hidden = true
        setBackgroundSelectedMaterial(material.types.ui_background_inset.index)
    else
        buttonTable.knobView.hidden = false
        buttonTable.knobView:setModel(model:modelIndexForName("ui_slider_knob"))
        buttonTable.backgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg_short"))
    end
end

function uiSlider:create(parentView, size, min, max, value, options, changeFunction)
    local buttonTable = {
        uiSlider = true,
        hover = false,
        mouseDown = false,
        selected = false,
        min = min,
        max = max,
        mouseDownValue = value,
        value = value,
        changeFunction = changeFunction,
    }

    local mainView = View.new(parentView)
    buttonTable.view = mainView
    mainView.size = size

    local knobSize = vec2(size.y * 1.0, size.y * 1.0)
    local backgroundSize = vec2(size.x - knobSize.x, size.y)
    buttonTable.backgroundSize = backgroundSize
    
    local backgroundView = ModelView.new(mainView)
    buttonTable.backgroundView = backgroundView
    backgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg_short"))
    local scaleToUseX = backgroundSize.x * 0.5
    local scaleToUseY = backgroundSize.y * 0.5 / 0.1
    backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    backgroundView.size = backgroundSize
    --backgroundView.baseOffset = vec3(knobSize.x * 0.5, 0.0, 0.0)

    local fraction = (value - min) / (max - min)
    local knobX = backgroundSize.x * fraction

    local continuous = false
    local releasedFunction = nil
    if options then
        continuous = options.continuous
        releasedFunction = options.releasedFunction
        buttonTable.releasedFunction = releasedFunction
        buttonTable.controllerIncrement = options.controllerIncrement
    end
    
    local knobView = ModelView.new(mainView)
    knobView:setModel(model:modelIndexForName("ui_slider_knob"))
    local knobScaleToUseX = knobSize.x * 0.5
    local knobScaleToUseY = knobSize.y * 0.5
    knobView.scale3D = vec3(knobScaleToUseX,knobScaleToUseY,knobScaleToUseY)
    knobView.size = knobSize
    buttonTable.knobView = knobView
    knobView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    knobView.baseOffset = vec3(knobX, 0, 1)
    knobView.masksEvents = false

    local function updateKnobPos(rawX)
        fraction = (rawX - knobSize.x * 0.5) / (size.x - knobSize.x)
        fraction = mjm.clamp(fraction, 0.0, 1.0)
        local newValue = math.floor(min + fraction * ((max - min)) + 0.5)
        newValue = math.min(newValue, max)
        if newValue ~= buttonTable.value then
            buttonTable.value = newValue
            fraction = (buttonTable.value - min) / (max - min)
            knobX = backgroundSize.x * fraction
            knobView.baseOffset = vec3(knobX, 0, 1)
           -- uiCommon:resizeBackgroundView(selectedBackgroundView, vec2(knobX, size.y))
           if continuous then
                changeFunction(buttonTable.value)
           end
        end
    end


    mainView.mouseDown = function(buttonIndex, mouseLoc)
        if not buttonTable.disabled then
            if buttonIndex == 0 then
                buttonTable.mouseDownValue = buttonTable.value
                buttonTable.mouseDown = true
                updateKnobPos(mouseLoc.x)
                updateVisuals(buttonTable)
            end
        end
    end
    
    mainView.mouseDragged = function(mouseLoc)
        if buttonTable.mouseDown then
            updateKnobPos(mouseLoc.x)
        end
    end
    
    backgroundView.hoverStart = function ()
        if not buttonTable.hover then
            if not buttonTable.disabled then
                buttonTable.hover = true
                audio:playUISound(uiCommon.hoverSoundFile)
                updateVisuals(buttonTable)
            end
        end
    end

    backgroundView.hoverEnd = function ()
        if buttonTable.hover then
            buttonTable.hover = false
            updateVisuals(buttonTable)
        end
    end
    
    mainView.mouseUp = function (buttonIndex)
        if not buttonTable.disabled then
            local shouldSendValue = false
            if buttonIndex == 0 then
                if buttonTable.mouseDownValue ~= buttonTable.value then
                    shouldSendValue = true
                end
            end
            if shouldSendValue then
                if not continuous then
                    changeFunction(buttonTable.value)
                end
                if releasedFunction then
                    releasedFunction(buttonTable.value)
                end
            end
        end
        buttonTable.mouseDown = false
        updateVisuals(buttonTable)
    end

    
    mainView.mouseWheel = function(position, scrollChange)
        local range = math.max((max - min), 1)
        local offset = (scrollChange.y) / 100 * range
        --mj:log("range:", range, " scrollChange:", scrollChange.y, " offset:", offset)

        if offset > 0 then
            offset = math.max(math.floor(offset), 1)
        elseif offset < 0 then
            offset = math.min(math.ceil(offset), -1)
        else
            return
        end

        local newValue = buttonTable.value + offset
        newValue = math.min(newValue, max)
        newValue = math.max(newValue, min)
        if newValue ~= buttonTable.value then
            buttonTable.value = newValue
            fraction = (buttonTable.value - min) / (max - min)
            knobX = backgroundSize.x * fraction
            knobView.baseOffset = vec3(knobX, 0, 1)
           -- uiCommon:resizeBackgroundView(selectedBackgroundView, vec2(knobX, size.y))
            changeFunction(buttonTable.value)
            if releasedFunction then
                releasedFunction(buttonTable.value)
            end
        end
    end

    mainView.userData = buttonTable

    return mainView
end

function uiSlider:addDueToControllerButton(sliderView, increment)
    local buttonTable = sliderView.userData
    local knobView = buttonTable.knobView
    local newValue = nil
    if buttonTable.controllerIncrement then
        newValue = buttonTable.value + increment * buttonTable.controllerIncrement
        newValue = mjm.clamp(newValue, buttonTable.min, buttonTable.max)
    else
        local currentFraction = (buttonTable.value - buttonTable.min) / (buttonTable.max - buttonTable.min)
        local newFractionBase = currentFraction + 0.05 * increment
        newFractionBase = mjm.clamp(newFractionBase, 0.0, 1.0)
        newValue = math.floor(buttonTable.min + newFractionBase * ((buttonTable.max - buttonTable.min)) + 0.5)
        newValue = math.min(newValue, buttonTable.max)
        if newValue == buttonTable.value then
            newValue = buttonTable.value + increment
            newValue = mjm.clamp(newValue, buttonTable.min, buttonTable.max)
        end
    end
    if newValue ~= buttonTable.value then
        buttonTable.value = newValue
        local newFraction = (buttonTable.value - buttonTable.min) / (buttonTable.max - buttonTable.min)
        local knobX = buttonTable.backgroundSize.x * newFraction
        knobView.baseOffset = vec3(knobX, 0, 1)
        buttonTable.changeFunction(buttonTable.value)

        if buttonTable.releasedFunction then
            buttonTable.releasedFunction(buttonTable.value)
        end
    end
end

function uiSlider:setDisabled(sliderView, disabled)
    if disabled ~= sliderView.userData.disabled then
        sliderView.userData.disabled = disabled
        updateVisuals(sliderView.userData)
    end
end

function uiSlider:setSelected(buttonView, selected)
    if selected ~= buttonView.userData.selected then
        buttonView.userData.selected = selected
        updateVisuals(buttonView.userData)
    end
end

return uiSlider