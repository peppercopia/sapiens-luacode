local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiKeyImage = mjrequire "mainThread/ui/uiCommon/uiKeyImage"

local uiToolTip = {}

            
local keyImagePadding = 4
local keyImageWidth = 18
local keyImageTopOffset = -5

local function resizeBackground(tipBackgroundView, titleTextView, descriptionTextView, keyShortcutViewOrNil)

    local panelHeight = 28
    local width = math.max(80, titleTextView.size.x + 12)

    --mj:log("resizeBackground width:", width)

    if keyShortcutViewOrNil then
        width = math.max(80, width + keyShortcutViewOrNil.size.x + keyImagePadding)
        --mj:error("resizeBackground b width:", width, " keyShortcutViewOrNil.size.x:", keyShortcutViewOrNil.size.x)
    end

    if descriptionTextView then
        panelHeight = 32 + descriptionTextView.size.y
        width = math.max(width, descriptionTextView.size.x + 12)
    end

    
    local sizeToUse = vec2(width, panelHeight)
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / 0.2
    tipBackgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    tipBackgroundView.size = sizeToUse
end

local function loadDescriptionTextView(toolTipTable)
    local descriptionTextView = TextView.new(toolTipTable.tipBackgroundView)
    toolTipTable.descriptionTextView = descriptionTextView
    descriptionTextView.font = Font(uiCommon.fontName, 14)
    descriptionTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    descriptionTextView.baseOffset = vec3(0,-26,0)
    descriptionTextView:setDisableClipping(true)
end


local function createViewsIfNeeded(parentView, toolTipTable)
    if not toolTipTable.tipBackgroundView then
        local tipBackgroundView = ModelView.new(toolTipTable.addToView)
        if toolTipTable.relativeViewOrNil then
            tipBackgroundView.relativeView = toolTipTable.relativeViewOrNil
        else
            tipBackgroundView.relativeView = parentView
        end
        toolTipTable.tipBackgroundView = tipBackgroundView
        tipBackgroundView:setModel(model:modelIndexForName(toolTipTable.backgroundModelIndex or "ui_panel_10x2", toolTipTable.backgroundMaterialRemapTableOrNil))
        tipBackgroundView.hidden = true
        tipBackgroundView.relativePosition = toolTipTable.relativePosition
        tipBackgroundView:setDisableClipping(true)
        tipBackgroundView.baseOffset = vec3(0, 0, 4)
        if toolTipTable.offsetOrNil then
            tipBackgroundView.baseOffset = toolTipTable.offsetOrNil
        end

        local titleTextView = TextView.new(tipBackgroundView)
        toolTipTable.titleTextView = titleTextView
        titleTextView.font = Font(uiCommon.fontName, 16)
        titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
        titleTextView.baseOffset = vec3(0,-4,0)
        titleTextView:setDisableClipping(true)
    end
    

    local keyShortcutInfo = toolTipTable.keyShortcutInfo
    if keyShortcutInfo then
        local function updateKeyImageSize(uiKeyImageView)
            local textXOffset = -(uiKeyImageView.size.x + keyImagePadding) * 0.5
            toolTipTable.titleTextView.baseOffset = vec3(textXOffset, toolTipTable.titleTextView.baseOffset.y, toolTipTable.titleTextView.baseOffset.z)
            --mj:log("keyImage.baseOffset a:", uiKeyImageView.baseOffset)
            uiKeyImageView.baseOffset = vec3(toolTipTable.titleTextView.size.x * 0.5 + keyImagePadding, keyImageTopOffset, 0)
            --mj:log(uiKeyImageView.baseOffset)
            resizeBackground(toolTipTable.tipBackgroundView, toolTipTable.titleTextView, toolTipTable.descriptionTextView, toolTipTable.keyImage)
        end
        
        if toolTipTable.keyImage then
            toolTipTable.tipBackgroundView:removeSubview(toolTipTable.keyImage)
            toolTipTable.keyImage = nil
        end

       -- if not toolTipTable.keyImage then
            local keyImage = uiKeyImage:create(toolTipTable.tipBackgroundView, keyImageWidth, keyShortcutInfo.groupKey, keyShortcutInfo.mappingKey, keyShortcutInfo.controllerSetIndex, keyShortcutInfo.controllerActionName, updateKeyImageSize)
            --mj:log("created size:", keyImage.size.x)
            toolTipTable.keyImage = keyImage
            keyImage.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
            updateKeyImageSize(toolTipTable.keyImage)
      --  else
            --updateKeyImageSize(toolTipTable.keyImage)
       -- end
    else
        toolTipTable.titleTextView.baseOffset = vec3(0, toolTipTable.titleTextView.baseOffset.y, toolTipTable.titleTextView.baseOffset.z)
    end
end

local function doUpdateTextIfNeeded(parentView, toolTipTable)
    if toolTipTable.shouldBeDisplayed and toolTipTable.dirty then
        toolTipTable.dirty = false
        local tipBackgroundView = toolTipTable.tipBackgroundView
        local titleTextView = toolTipTable.titleTextView
    
        titleTextView.text = toolTipTable.title
    
        if toolTipTable.disabled then
            titleTextView.color = vec4(0.5,0.5,0.5,1.0)
        else
            titleTextView.color = vec4(1.0,1.0,1.0,1.0)
        end
    
        if toolTipTable.descriptionOrNil or (toolTipTable.coloredDescriptionTextArray and toolTipTable.coloredDescriptionTextArray[1]) then
            if not toolTipTable.descriptionTextView then
                loadDescriptionTextView(toolTipTable)
            end
            
            toolTipTable.descriptionTextView.text = (toolTipTable.descriptionOrNil or "")
    
            if toolTipTable.disabled then
                toolTipTable.descriptionTextView.color = vec4(0.5,0.5,0.5,1.0)
            else
                toolTipTable.descriptionTextView.color = vec4(1.0,1.0,1.0,1.0)
            end
        else
            if toolTipTable.descriptionTextView then
                toolTipTable.tipBackgroundView:removeSubview(toolTipTable.descriptionTextView)
                toolTipTable.descriptionTextView = nil
            end
        end

        if toolTipTable.coloredTextArray then
            for i, colorTextInfo in ipairs(toolTipTable.coloredTextArray) do
                titleTextView:addColoredText(colorTextInfo.text, colorTextInfo.color)
            end
        end

        if toolTipTable.coloredDescriptionTextArray then
            for i, colorTextInfo in ipairs(toolTipTable.coloredDescriptionTextArray) do
                toolTipTable.descriptionTextView:addColoredText(colorTextInfo.text, colorTextInfo.color)
            end
        end

        
        if toolTipTable.keyImage then
            toolTipTable.keyImage.baseOffset = vec3(toolTipTable.titleTextView.size.x * 0.5 + keyImagePadding, keyImageTopOffset, 0)
        end
    
        resizeBackground(tipBackgroundView, titleTextView, toolTipTable.descriptionTextView, toolTipTable.keyImage)
    end
end

function uiToolTip:updateText(parentView, title, descriptionOrNil, disabled)
    local toolTipTable = parentView.userData.toolTipTable
    toolTipTable.title = title
    toolTipTable.coloredTextArray = nil
    toolTipTable.descriptionOrNil = descriptionOrNil
    toolTipTable.coloredDescriptionTextArray = nil
    toolTipTable.disabled = disabled
    toolTipTable.dirty = true
    doUpdateTextIfNeeded(parentView, toolTipTable)
end


function uiToolTip:addColoredTitleText(parentView, titleText, color)
    local userData = parentView.userData
    local toolTipTable = userData.toolTipTable
    if not toolTipTable.coloredTextArray then 
        toolTipTable.coloredTextArray = {}
    end
    table.insert(toolTipTable.coloredTextArray, {
        text = titleText,
        color = color,
    })
    toolTipTable.dirty = true
    doUpdateTextIfNeeded(parentView, toolTipTable)
end

function uiToolTip:addColoredDescriptionText(parentView, descriptionText, color)
    local userData = parentView.userData
    local toolTipTable = userData.toolTipTable
    if not toolTipTable.coloredDescriptionTextArray then 
        toolTipTable.coloredDescriptionTextArray = {}
    end
    table.insert(toolTipTable.coloredDescriptionTextArray, {
        text = descriptionText,
        color = color,
    })
    toolTipTable.dirty = true
    doUpdateTextIfNeeded(parentView, toolTipTable)
end

function uiToolTip:addKeyboardShortcut(parentView, groupKey, mappingKey, controllerSetIndex, controllerActionName)
    local userData = parentView.userData
    local toolTipTable = userData.toolTipTable

    toolTipTable.keyShortcutInfo = {
        groupKey = groupKey,
        mappingKey= mappingKey,
        controllerSetIndex = controllerSetIndex,
        controllerActionName = controllerActionName,
    }
    toolTipTable.dirty = true
end

function uiToolTip:removeKeyboardShortcut(parentView)
    local userData = parentView.userData
    local toolTipTable = userData.toolTipTable
    if toolTipTable.keyShortcutInfo then
        toolTipTable.keyShortcutInfo = nil
        if toolTipTable.keyImage then
            toolTipTable.tipBackgroundView:removeSubview(toolTipTable.keyImage)
            toolTipTable.keyImage = nil
        end
    end
end

function uiToolTip:remove(parentView)
    local userData = parentView.userData
    if userData then
        local toolTipTable = userData.toolTipTable
        if toolTipTable then
            if toolTipTable.tipBackgroundView then
                toolTipTable.addToView:removeSubview(toolTipTable.tipBackgroundView)
                --mj:log("uiToolTip:remove from:", toolTipTable.addToView, " view:", toolTipTable.tipBackgroundView)
            end
            parentView.hoverStart = toolTipTable.prevHoverStart
            parentView.hoverEnd = toolTipTable.prevHoverEnd
            parentView.hiddenStateChanged = toolTipTable.prevHiddenStateChanged

            userData.toolTipTable = nil
        end
    end
end

function uiToolTip:setBackgroundModelIndex(parentView, backgroundModelIndex, backgroundMaterialRemapTableOrNil)
    local userData = parentView.userData
    if userData then
        local toolTipTable = userData.toolTipTable
        if toolTipTable then
            toolTipTable.backgroundModelIndex = backgroundModelIndex
            toolTipTable.backgroundMaterialRemapTableOrNil = backgroundMaterialRemapTableOrNil
            toolTipTable.tipBackgroundView:setModel(toolTipTable.backgroundModelIndex, toolTipTable.backgroundMaterialRemapTableOrNil)
        end
    end
end

function uiToolTip:add(parentView, relativePosition, title, descriptionOrNil, offsetOrNil, scaleOrNil, relativeViewOrNil, addToViewOrNil)
    parentView.masksEvents = true
    local userData = parentView.userData
    if not userData then
        userData = {}
        parentView.userData = userData
    end
    local toolTipTableInit = userData.toolTipTable
    if not toolTipTableInit then
        toolTipTableInit = {}
        userData.toolTipTable = toolTipTableInit
    end
    toolTipTableInit.shouldBeDisplayed = false
    toolTipTableInit.relativePosition = relativePosition
    toolTipTableInit.offsetOrNil = offsetOrNil
    toolTipTableInit.scaleOrNil = scaleOrNil
    toolTipTableInit.relativeViewOrNil = relativeViewOrNil
    toolTipTableInit.descriptionOrNil = descriptionOrNil
    toolTipTableInit.title = title
    toolTipTableInit.dirty = true
    toolTipTableInit.disabled = false
    toolTipTableInit.addToView = addToViewOrNil or parentView

    local prevHoverStart = parentView.hoverStart
    toolTipTableInit.prevHoverStart = prevHoverStart
    parentView.hoverStart = function()
        local toolTipTableReloaded = userData.toolTipTable
        if not toolTipTableReloaded.shouldBeDisplayed then
            toolTipTableReloaded.shouldBeDisplayed = true
            createViewsIfNeeded(parentView, toolTipTableReloaded)
            doUpdateTextIfNeeded(parentView, toolTipTableReloaded)
            toolTipTableReloaded.tipBackgroundView.hidden = false
        end
        if prevHoverStart then
            prevHoverStart()
        end
    end

    local prevHoverEnd = parentView.hoverEnd
    toolTipTableInit.prevHoverEnd = prevHoverEnd
    parentView.hoverEnd = function()
        local toolTipTableReloaded = userData.toolTipTable
        if toolTipTableReloaded.shouldBeDisplayed then
            toolTipTableReloaded.shouldBeDisplayed = false
            toolTipTableReloaded.tipBackgroundView.hidden = true
        end
        if prevHoverEnd then
            prevHoverEnd()
        end
    end

    local prevHiddenStateChanged = parentView.hiddenStateChanged
    toolTipTableInit.prevHiddenStateChanged = prevHiddenStateChanged
    parentView.hiddenStateChanged = function(newHiddenState)
        local toolTipTableReloaded = userData.toolTipTable
        if newHiddenState and toolTipTableReloaded.shouldBeDisplayed then
            toolTipTableReloaded.shouldBeDisplayed = false
            toolTipTableReloaded.tipBackgroundView.hidden = true
        end

        if prevHiddenStateChanged then
            prevHiddenStateChanged(newHiddenState)
        end
    end
end

return uiToolTip