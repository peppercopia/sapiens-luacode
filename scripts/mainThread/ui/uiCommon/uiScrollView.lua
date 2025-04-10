local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local audio = mjrequire "mainThread/audio"

local uiScrollView = {}
local knobSize = vec2(30.0, 30.0)
local backgroundWidth = 20.0
local knobZOffset = 1

local function updateYOffsets(scrollView, rowStartIndex)
    local userTable = scrollView.userData
    for i=rowStartIndex, #userTable.rowInfos do
        local rowInfo = userTable.rowInfos[i]
        local aboveRowInfo = userTable.rowInfos[i - 1]
        if aboveRowInfo then
            rowInfo.yOffsetFromTop = aboveRowInfo.yOffsetFromTop + aboveRowInfo.rowView.size.y
        else
            rowInfo.yOffsetFromTop = 0--rowInfo.rowView.size.y
        end
    end
end


local function updateBackgroundViews(scrollView)
    local userTable = scrollView.userData
    if userTable.backgroundViews and userTable.scrollYOffset then
        for i, backgroundView in ipairs(userTable.backgroundViews) do
            local prevOffset = backgroundView.baseOffset
            backgroundView.baseOffset = vec3(prevOffset.x, userTable.scrollYOffset, prevOffset.z)
        end
    end
end

--[[


    

    scrollView.update = function(dt)
        if userTable.dirty then
            recreateDerivedData(scrollView)
        end
        
        if userTable.baseItemView.baseOffset.x ~= userTable.goalX then
            local newX = userTable.baseItemView.baseOffset.x + (userTable.goalX - userTable.baseItemView.baseOffset.x) * mjm.clamp(dt * 10.0, 0.0, 1.0)
            if math.abs(newX - userTable.goalX) < 0.5 then
                userTable.baseItemView.baseOffset = vec3(userTable.goalX,0,0)
                userTable.scrollXOffset = userTable.goalX
            else
                userTable.baseItemView.baseOffset = vec3(newX,0,0)
                userTable.scrollXOffset = newX
            end
            updatePositionsAndVisibilities(scrollView)
        end
    end

    scrollView.mouseWheel = function(position, scrollChange)
        local offset = 0
        if scrollChange.y >= 1 then
            offset = 1
        elseif scrollChange.y <= -1 then
            offset = -1
        end
        local newX = userTable.scrollXIndex - offset
        updateScrollGoal(newX)
    end

    return scrollView
end
]]


local function updateScrollGoal(userTable, newScrollGoalIndex)
   -- mj:debug("updateScrollGoal newScrollGoalIndex:", newScrollGoalIndex)
   -- mj:log("updateScrollGoal userTable:", userTable)
    userTable.scrollYIndex = mjm.clamp(newScrollGoalIndex, 0, userTable.scrollYIndexMax)
    local rowInfo = userTable.rowInfos[userTable.scrollYIndex + 1]
    if rowInfo then
        --[[if rowInfo.rowView then
            rowInfo.rowView.hidden = false
        end]]
        userTable.goalY = -rowInfo.yOffsetFromTop
    end
end



local function updatePositionsAndVisibilities(scrollView)
    local userTable = scrollView.userData
    for i=1, #userTable.rowInfos do
        local rowInfo = userTable.rowInfos[i]
        if rowInfo.yOffsetFromTop + rowInfo.rowView.size.y + userTable.scrollYOffset <= 0 then
            rowInfo.rowView.hidden = true
        else
            if rowInfo.yOffsetFromTop + userTable.scrollYOffset >= scrollView.size.y then
                rowInfo.rowView.hidden = true
            else
                rowInfo.rowView.hidden = false
            end
        end
    end
    
    local knobView = userTable.knobView
    local size = userTable.size

    local fraction = -userTable.scrollYOffset / userTable.scrollYHeight
    local knobY = size.y * fraction
    knobView.baseOffset = vec3(2, size.y - (knobY - fraction * knobSize.y) - knobSize.y, knobZOffset)
    
    updateBackgroundViews(scrollView)
end

local function recreateDerivedData(scrollView)
    local userTable = scrollView.userData
    userTable.scrollYIndexMax = 0
    for i=1, #userTable.rowInfos do
        local rowInfo = userTable.rowInfos[i]
        if rowInfo.yOffsetFromTop + rowInfo.rowView.size.y > scrollView.size.y + 0.5 then
            userTable.scrollYIndexMax = userTable.scrollYIndexMax + 1
        end
    end
    userTable.scrollYHeight = 0
    for i=1, userTable.scrollYIndexMax do
        local rowInfo = userTable.rowInfos[i]
        userTable.scrollYHeight = userTable.scrollYHeight + rowInfo.rowView.size.y
    end

    local scrollerBackgroundView = userTable.scrollerBackgroundView
    local knobView = userTable.knobView
    
    if userTable.scrollYIndexMax == 0 then
        scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_vertical_bg"), {
            [material.types.ui_standard.index] = material.types.ui_disabled.index
        })
        knobView.hidden = true
    else
        scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_vertical_bg"))
        knobView.hidden = false
    end
    updateScrollGoal(userTable, userTable.scrollYIndex)
    updatePositionsAndVisibilities(scrollView)
    userTable.dirty = false
end

function uiScrollView:create(parentView, size, contentHorizontalAlignmentOrNil)

    local userTable = {
        size = size,
        rowInfos = {},
        contentHeight = 0.0,
        scrollYIndex = 0,
        scrollYIndexMax = 0,
        scrollYOffset = 0.0,
        goalY = 0,
        contentHorizontalAlignment = MJPositionCenter,

        backgroundHover = false,
        knobHover = false,
    }

    if contentHorizontalAlignmentOrNil then
        userTable.contentHorizontalAlignment = contentHorizontalAlignmentOrNil
    end

    local scrollView = View.new(parentView)
    scrollView.userData = userTable
    scrollView:setClipChildren(true)

    scrollView.size = size;

    
    local baseItemView = View.new(scrollView)
    baseItemView.relativePosition = ViewPosition(userTable.contentHorizontalAlignment, MJPositionTop)
    baseItemView.size = vec2(0,0)
    userTable.baseItemView = baseItemView
    
    local scrollerBackgroundView = ModelView.new(scrollView)
    userTable.scrollerBackgroundView = scrollerBackgroundView
    scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_vertical_bg"))
    local scaleToUse = size.y * 0.5
    scrollerBackgroundView.scale3D = vec3(backgroundWidth / 0.1,scaleToUse,scaleToUse)
    scrollerBackgroundView.size = vec2(backgroundWidth, size.y)
    scrollerBackgroundView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)

    local knobView = ModelView.new(parentView)
    userTable.knobView = knobView
    knobView:setModel(model:modelIndexForName("ui_slider_knob"))
    local knobScaleToUse = knobSize.x * 0.5
    knobView.scale3D = vec3(knobScaleToUse,knobScaleToUse,knobScaleToUse)
    knobView.size = knobSize
    --knobView.masksEvents = false
    knobView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    knobView.relativeView = scrollerBackgroundView
    --knobView.baseOffset = vec3(0, size.y - knobSize.y, 3)
    knobView.baseOffset = vec3(2, 0, knobZOffset)

    

    

    local function updateKnobPos(rawY)
        if userTable.scrollYIndexMax > 0 then
            if userTable.dirty then
                recreateDerivedData(scrollView)
            end
            local fraction = (rawY - knobSize.y * 0.5) / (size.y - knobSize.y)
            fraction = mjm.clamp(fraction, 0.0, 0.999)
            local newValue = math.floor(fraction * (userTable.scrollYIndexMax) + 0.5)
            if newValue == userTable.mouseDownValue then
               -- mj:log("userTable:", userTable)
                --mj:log("fraction:", fraction)
                local mouseDownFraction = userTable.mouseDownValue / userTable.scrollYIndexMax
                if fraction > mouseDownFraction + ((knobSize.y * 0.5) / size.y) then
                    newValue = newValue + 1
                elseif fraction < mouseDownFraction - ((knobSize.y * 0.5) / size.y) then
                    newValue = newValue - 1
                end
            end
            updateScrollGoal(userTable, newValue)
        end
    end

    local function backgroundMouseDown(buttonIndex, mouseLoc)
        if not userTable.disabled and userTable.scrollYIndexMax ~= 0 then
            userTable.mouseDownValue = userTable.scrollYIndex
            updateKnobPos(size.y - mouseLoc.y)
        end
    end
    
    local function backgroundMouseDragged(mouseLoc)
        if not userTable.disabled and userTable.scrollYIndexMax ~= 0 then
            updateKnobPos(size.y - mouseLoc.y)
        end
    end


    scrollerBackgroundView.mouseDown = backgroundMouseDown
    scrollerBackgroundView.mouseDragged = backgroundMouseDragged
    
    knobView.mouseDown = function(buttonIndex, mouseLoc)
        local backgroundLoc = knobView:locationRelativeToView(mouseLoc, scrollerBackgroundView)
        backgroundMouseDown(buttonIndex, backgroundLoc)
    end

    knobView.mouseDragged = function(mouseLoc)
        local backgroundLoc = knobView:locationRelativeToView(mouseLoc, scrollerBackgroundView)
        backgroundMouseDragged(backgroundLoc)
    end

    local function hoverStart()
        if not userTable.hover then
            if userTable.backgroundHover or userTable.knobHover then
                if not userTable.disabled and userTable.scrollYIndexMax ~= 0 then
                    userTable.hover = true
                    audio:playUISound(uiCommon.hoverSoundFile)
                    knobView:setModel(model:modelIndexForName("ui_slider_knob"), {
                        [material.types.ui_standard.index] = material.types.ui_selected.index
                    })
                    scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_vertical_bg"), {
                        [material.types.ui_standard.index] = material.types.ui_selected.index
                    })
                end
            end
        end
    end

    local function hoverEnd()
        if userTable.hover then
            if (not userTable.backgroundHover) and (not userTable.knobHover) then
                userTable.hover = false
                userTable.mouseDown = false
                knobView:setModel(model:modelIndexForName("ui_slider_knob"))
                scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_vertical_bg"))
            end
        end
    end
    
    scrollerBackgroundView.hoverStart = function ()
        userTable.backgroundHover = true
        hoverStart()
    end

    scrollerBackgroundView.hoverEnd = function ()
        userTable.backgroundHover = false
        hoverEnd()
    end
    
    
    knobView.hoverStart = function ()
        userTable.knobHover = true
        hoverStart()
    end

    knobView.hoverEnd = function ()
        userTable.knobHover = false
        hoverEnd()
    end

    
    scrollView.update = function(dt)
        if userTable.dirty then
            recreateDerivedData(scrollView)
        end
        
        if userTable.scrollYOffset ~= userTable.goalY then
            local newY = userTable.scrollYOffset + (userTable.goalY - userTable.scrollYOffset) * mjm.clamp(dt * 20.0, 0.0, 1.0)
            if math.abs(newY - userTable.goalY) < 0.5 then
                userTable.scrollYOffset = userTable.goalY
                userTable.baseItemView.baseOffset = vec3(0, - userTable.scrollYOffset,0)
            else
                userTable.scrollYOffset = newY
                userTable.baseItemView.baseOffset = vec3(0, - userTable.scrollYOffset,0)
            end
            updatePositionsAndVisibilities(scrollView)
        end
    end

    scrollView.mouseWheel = function(position, scrollChange)
        local offset = scrollChange.y
        if scrollChange.y >= 1 then
            offset = math.floor(scrollChange.y)
        elseif scrollChange.y <= -1 then
            offset = math.ceil(scrollChange.y)
        end
        local newY = userTable.scrollYIndex - offset
        updateScrollGoal(userTable, newY)
    end

    uiScrollView:removeAllRows(scrollView)
    
    return scrollView
end


function uiScrollView:scrollerIsVisible(scrollView)
    local userTable = scrollView.userData
    return (userTable.scrollYIndexMax ~= 0)
end

function uiScrollView:scrollToVisible(scrollView, itemListIndex, viewToVerifyMatch)
    local userTable = scrollView.userData
    if userTable.dirty then
        recreateDerivedData(scrollView)
    end
    --mj:log("uiScrollView:scrollToVisible:", itemListIndex, " userTable.scrollYIndexMax:", userTable.scrollYIndexMax, " rowInfo:", userTable.rowInfos[itemListIndex])
    if (userTable.scrollYIndexMax ~= 0) then
        local rowInfo = userTable.rowInfos[itemListIndex]
        if rowInfo and rowInfo.rowView == viewToVerifyMatch then
            --mj:log("userTable.scrollYIndex:", userTable.scrollYIndex, " scrollView.size:", scrollView.size, " userTable.goalY:", userTable.goalY, " rowInfo.yOffsetFromTop:", rowInfo.yOffsetFromTop)
            if userTable.scrollYIndex > itemListIndex - 2 then
                updateScrollGoal(userTable, itemListIndex - 2)
            elseif -userTable.goalY < rowInfo.yOffsetFromTop - scrollView.size.y + rowInfo.rowView.size.y * 2.0 then
                updateScrollGoal(userTable, itemListIndex - 2)
            end
        end
    end
end

function uiScrollView:insertRow(scrollView, insertRowView, rowIndexOrNil)
    local userTable = scrollView.userData
    local insertIndex = rowIndexOrNil
    if (not insertIndex) or insertIndex > #userTable.rowInfos then
        insertIndex = #userTable.rowInfos + 1
    end

    local addedRowHeight = insertRowView.size.y

    local oldRowInfoAtThisPos = userTable.rowInfos[insertIndex]
    local aboveRowInfo = userTable.rowInfos[insertIndex - 1]

    if aboveRowInfo then
        insertRowView.relativeView = aboveRowInfo.rowView
        insertRowView.relativePosition = ViewPosition(userTable.contentHorizontalAlignment, MJPositionBelow)
    else
        insertRowView.relativeView = userTable.baseItemView
        insertRowView.relativePosition = ViewPosition(userTable.contentHorizontalAlignment, MJPositionTop)
    end

    if oldRowInfoAtThisPos then
        oldRowInfoAtThisPos.rowView.relativeView = insertRowView
    end

    
    insertRowView.allowViewMovementUnderCursorToTriggerHoverStartEvents = true

    local rowInfo = {
        rowView = insertRowView,
    }

    table.insert(userTable.rowInfos, insertIndex, rowInfo)


    userTable.contentHeight = userTable.contentHeight + addedRowHeight

    updateYOffsets(scrollView, insertIndex)

    userTable.dirty = true

end


function uiScrollView:removeAllRows(scrollView)
    local userTable = scrollView.userData
    --mj:debug("uiScrollView:removeAllRows table:", userTable)
    for j=#userTable.rowInfos,1,-1 do
        scrollView:removeSubview(userTable.rowInfos[j].rowView)
    end
    userTable.rowInfos = {}
    userTable.contentHeight = 0.0
    
    --userTable.scrollYIndex = 0
    --userTable.goalY = 0
    --userTable.scrollYOffset = userTable.goalY
    --userTable.baseItemView.baseOffset = vec3(0, - userTable.scrollYOffset,0)

    userTable.scrollYIndexMax = 0
    userTable.dirty = true

end

function uiScrollView:removeRowAtIndex(scrollView, rowIndex)
    local userTable = scrollView.userData
    if rowIndex and rowIndex > 0 and rowIndex <= #userTable.rowInfos then
        userTable.contentHeight = userTable.contentHeight - userTable.rowInfos[rowIndex].rowView.size.y
        local viewToRemove = userTable.rowInfos[rowIndex].rowView

        table.remove(userTable.rowInfos, rowIndex)

        local newCurrentPositionRowInfo = userTable.rowInfos[rowIndex]
        if newCurrentPositionRowInfo then
            local aboveRowInfo = userTable.rowInfos[rowIndex - 1]

            if aboveRowInfo then
                newCurrentPositionRowInfo.rowView.relativeView = aboveRowInfo.rowView
                newCurrentPositionRowInfo.rowView.relativePosition = ViewPosition(userTable.contentHorizontalAlignment, MJPositionBelow)
            else
                newCurrentPositionRowInfo.rowView.relativeView = userTable.baseItemView
                newCurrentPositionRowInfo.rowView.relativePosition = ViewPosition(userTable.contentHorizontalAlignment, MJPositionTop)
            end
        end

        scrollView:removeSubview(viewToRemove)
        updateYOffsets(scrollView, rowIndex)
        userTable.dirty = true
    end
end

function uiScrollView:removeRow(scrollView, rowView)
    local userTable = scrollView.userData
    for rowIndex,rowInfo in ipairs(userTable.rowInfos) do
        if rowInfo.rowView == rowView then
            uiScrollView:removeRowAtIndex(scrollView, rowIndex)
            return
        end
    end

end

return uiScrollView