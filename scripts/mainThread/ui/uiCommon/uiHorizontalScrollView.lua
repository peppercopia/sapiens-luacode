local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local audio = mjrequire "mainThread/audio"

local uiHorizontalScrollView = {}

local knobZOffset = 8

local function updateXOffsets(scrollView, columnStartIndex)
    local userTable = scrollView.userData
    for i=columnStartIndex, #userTable.columnInfos do
        local columnInfo = userTable.columnInfos[i]
        local prevColumnInfo = userTable.columnInfos[i - 1]
        if prevColumnInfo then
            columnInfo.xOffsetFromLeft = prevColumnInfo.xOffsetFromLeft + prevColumnInfo.columnView.size.x
        else
            columnInfo.xOffsetFromLeft = 0
        end
    end
end


local function updateBackgroundViews(scrollView)
    local userTable = scrollView.userData
    if userTable.backgroundViews and userTable.scrollXOffset then
        for i, backgroundView in ipairs(userTable.backgroundViews) do
            local prevOffset = backgroundView.baseOffset
            backgroundView.baseOffset = vec3(userTable.scrollXOffset, prevOffset.y, prevOffset.z)
        end
    end
end

local function updateScrollGoal(userTable, newScrollGoalIndex)
    userTable.scrollXIndex = mjm.clamp(newScrollGoalIndex, 0, userTable.scrollXIndexMax)
    local columnInfo = userTable.columnInfos[userTable.scrollXIndex + 1]
    columnInfo.columnView.hidden = false
    userTable.goalX = -columnInfo.xOffsetFromLeft
end

function uiHorizontalScrollView:create(parentView, size)
    local userTable = {
        columnInfos = {},
        contentWidth = 0.0,
        scrollXIndex = 0,
        scrollXIndexMax = 0,
        scrollXOffset = 0.0,
        goalX = 0,
    }
    local scrollView = View.new(parentView)
    scrollView.userData = userTable
    scrollView:setClipChildren(true)

    scrollView.size = size;

    local knobSize = vec2(30.0, 30.0)
    local backgroundHeight = 20.0
    
    local baseItemView = View.new(scrollView)
    baseItemView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    baseItemView.size = vec2(0,0)
    userTable.baseItemView = baseItemView
    
    local scrollerBackgroundView = ModelView.new(scrollView)
    scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg"))
    local scaleToUse = size.x * 0.5
    scrollerBackgroundView.scale3D = vec3(scaleToUse, backgroundHeight / 0.1,scaleToUse)
    scrollerBackgroundView.size = vec2(size.x, backgroundHeight)
    scrollerBackgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)

    local knobView = ModelView.new(parentView)
    knobView:setModel(model:modelIndexForName("ui_slider_knob"))
    local knobScaleToUse = knobSize.x * 0.5
    knobView.scale3D = vec3(knobScaleToUse,knobScaleToUse,knobScaleToUse)
    knobView.size = knobSize
    knobView.masksEvents = false
    knobView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    knobView.relativeView = scrollerBackgroundView
    knobView.baseOffset = vec3(0, 0, knobZOffset)


    local function updatePositionsAndVisibilities()
        for i=1, #userTable.columnInfos do
            local columnInfo = userTable.columnInfos[i]
            if columnInfo.xOffsetFromLeft + columnInfo.columnView.size.x + userTable.scrollXOffset <= 0 then
                columnInfo.columnView.hidden = true
            else
                if columnInfo.xOffsetFromLeft + userTable.scrollXOffset >= scrollView.size.x then
                    columnInfo.columnView.hidden = true
                else
                    columnInfo.columnView.hidden = false
                end
            end
        end
        
        local fraction = -userTable.scrollXOffset / userTable.scrollXWidth
        local knobX = size.x * fraction
        knobView.baseOffset = vec3(knobX - fraction * knobSize.x, 0, knobZOffset)
        
        updateBackgroundViews(scrollView)
    end

    local function recreateDerivedData()
        userTable.scrollXIndexMax = 0
        for i=1, #userTable.columnInfos do
            local columnInfo = userTable.columnInfos[i]
            if columnInfo.xOffsetFromLeft + columnInfo.columnView.size.x > scrollView.size.x + 0.5 then
                userTable.scrollXIndexMax = userTable.scrollXIndexMax + 1
            end
        end
        userTable.scrollXWidth = 0
        for i=1, userTable.scrollXIndexMax do
            local columnInfo = userTable.columnInfos[i]
            userTable.scrollXWidth = userTable.scrollXWidth + columnInfo.columnView.size.x
        end
        
        if userTable.scrollXIndexMax == 0 then
            scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg"), {
                [material.types.ui_standard.index] = material.types.ui_disabled.index
            })
            knobView.hidden = true
        else
            scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg"))
            knobView.hidden = false
        end
        updateScrollGoal(userTable, userTable.scrollXIndex)
        updatePositionsAndVisibilities()
    end

    local function updateKnobPos(rawX, isMouseUpEvent)
        if userTable.scrollXIndexMax > 0 then
            if userTable.dirty then
                recreateDerivedData()
                userTable.dirty = false
            end
            local fraction = (rawX - knobSize.x * 0.5) / (size.x - knobSize.x)
            fraction = mjm.clamp(fraction, 0.0, 0.999)
            local newValue = math.floor(fraction * userTable.scrollXIndexMax + 0.5)
            if newValue == userTable.mouseDownValue then
               -- mj:log("userTable:", userTable)
                --mj:log("fraction:", fraction)
                local mouseDownFraction = userTable.mouseDownValue / userTable.scrollXIndexMax
                if fraction > mouseDownFraction + ((knobSize.x * 0.5) / size.x) then
                    newValue = newValue + 1
                elseif fraction < mouseDownFraction - ((knobSize.x * 0.5) / size.x) then
                    newValue = newValue - 1
                end
            end
            updateScrollGoal(userTable, newValue)
        end
    end
    

    scrollerBackgroundView.mouseDown = function(buttonIndex, mouseLoc)
        if not userTable.disabled and userTable.scrollXIndexMax ~= 0 then
            userTable.mouseDownValue = userTable.scrollXIndex
            updateKnobPos(mouseLoc.x, false)
        end
    end
    
    scrollerBackgroundView.mouseDragged = function(mouseLoc)
        if not userTable.disabled and userTable.scrollXIndexMax ~= 0 then
            updateKnobPos(mouseLoc.x, false)
        end
    end
    
   --[[ scrollerBackgroundView.mouseUp = function(mouseLoc)
        if not userTable.disabled and userTable.scrollXIndexMax ~= 0 then
            updateKnobPos(mouseLoc.x, true)
        end
    end]]
    
    scrollerBackgroundView.hoverStart = function ()
        if not userTable.hover then
            if not userTable.disabled and userTable.scrollXIndexMax ~= 0 then
                userTable.hover = true
                audio:playUISound(uiCommon.hoverSoundFile)
                knobView:setModel(model:modelIndexForName("ui_slider_knob"), {
                    [material.types.ui_standard.index] = material.types.ui_selected.index
                })
                scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg"), {
                   [ material.types.ui_standard.index] = material.types.ui_selected.index
                })
            end
        end
    end

    scrollerBackgroundView.hoverEnd = function ()
        if userTable.hover then
            userTable.hover = false
            userTable.mouseDown = false
            knobView:setModel(model:modelIndexForName("ui_slider_knob"))
            scrollerBackgroundView:setModel(model:modelIndexForName("ui_slider_horizontal_bg"))
        end
    end

    scrollView.update = function(dt)
        if userTable.dirty then
            recreateDerivedData()
            userTable.dirty = false
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
            updatePositionsAndVisibilities()
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
        updateScrollGoal(userTable, newX)
    end

    return scrollView
end


function uiHorizontalScrollView:scrollerIsVisible(scrollView)
    local userTable = scrollView.userData
    return (userTable.scrollXIndexMax ~= 0)
end

function uiHorizontalScrollView:scrollToVisible(scrollView, itemListIndex, viewToVerifyMatch)
    local userTable = scrollView.userData
    if (userTable.scrollXIndexMax ~= 0) then
        local columnInfo = userTable.columnInfos[itemListIndex]
        if columnInfo and columnInfo.columnView == viewToVerifyMatch then
           -- mj:log("userTable.scrollYIndex:", userTable.scrollYIndex, " scrollView.size:", scrollView.size, " userTable.goalY:", userTable.goalY, " rowInfo.yOffsetFromTop:", rowInfo.yOffsetFromTop)
            if userTable.scrollXIndex > itemListIndex - 2 then
                updateScrollGoal(userTable, itemListIndex - 2)
            elseif userTable.goalX < columnInfo.xOffsetFromLeft - scrollView.size.x + columnInfo.columnView.size.x * 2.0 then-- - scrollView.size.y + rowInfo.rowView.size.y * 2.0 then
                updateScrollGoal(userTable, itemListIndex - 2)
            end
        end
    end
end

function uiHorizontalScrollView:insertColumn(scrollView, insertColumnView, columnIndexOrNil)
    local userTable = scrollView.userData
    local insertIndex = columnIndexOrNil
    if (not insertIndex) or insertIndex > #userTable.columnInfos then
        insertIndex = #userTable.columnInfos + 1
    end

    local addedColumnWidth = insertColumnView.size.x

    local oldColumnInfoAtThisPos = userTable.columnInfos[insertIndex]
    local prevColumnInfo = userTable.columnInfos[insertIndex - 1]

    if prevColumnInfo then
        insertColumnView.relativeView = prevColumnInfo.columnView
        insertColumnView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
    else
        insertColumnView.relativeView = userTable.baseItemView
        insertColumnView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    end

    if oldColumnInfoAtThisPos then
        oldColumnInfoAtThisPos.columnView.relativeView = insertColumnView
    end

    local columnInfo = {
        columnView = insertColumnView,
    }

    table.insert(userTable.columnInfos, insertIndex, columnInfo)


    userTable.contentWidth = userTable.contentWidth + addedColumnWidth

    updateXOffsets(scrollView, insertIndex)

    userTable.dirty = true

end


function uiHorizontalScrollView:removeAllColumns(scrollView)
    local userTable = scrollView.userData
    userTable.columnInfos = {}
    userTable.contentWidth = 0.0
    userTable.scrollXIndexMax = 0
    userTable.dirty = true
end

function uiHorizontalScrollView:removeColumn(scrollView, columnIndexOrNil)
    mj:error("uiHorizontalScrollView:removeColumn not implemented")
end

function uiHorizontalScrollView:addBackgroundView(scrollView, backgroundView)
    local userTable = scrollView.userData
    if not userTable.backgroundViews then
        userTable.backgroundViews = {}
    end
    table.insert(userTable.backgroundViews, backgroundView)
    if userTable.scrollXOffset ~= nil then
        updateBackgroundViews(scrollView)
    end
end

return uiHorizontalScrollView