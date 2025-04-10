local mjm = mjrequire "common/mjm"
local vec4 = mjm.vec4
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local statistics = mjrequire "common/statistics"

local ffi = mjrequire("ffi")
local ffiCopy = ffi.copy

local numberType = ffi.typeof("double[1]")
local numberSize = ffi.sizeof("double")


local uiPopUpButton = mjrequire "mainThread/ui/uiCommon/uiPopUpButton"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiSlider = mjrequire "mainThread/ui/uiCommon/uiSlider"

local logicInterface = mjrequire "mainThread/logicInterface"
local clientGameSettings = mjrequire "mainThread/clientGameSettings"

local tribeStatsUI = {}

local world = nil

local settingKeys = {
    "statsGraphSelectionIndexA",
    "statsGraphSelectionIndexB",
    "statsGraphSelectionIndexC",
    "statsGraphSelectionIndexD",
    "statsGraphSelectionIndexE",
    "statsGraphSelectionIndexF",
}

local graphViewSize = nil

local graphCount = 6 --add colors and clientGameSettings ir increased

local thresholds = {
    {
        values = {0,1,2,3,4,5,6,7,8,9,10},
        max = 10
    },
    {
        values = {0,2,4,6,8,10,12,14,16,18,20},
        max = 20
    },
    {
        values = {0,5,10,15,20,25,30,35,40,45,50},
        max = 50
    },
}

local thresholdMultiplier = 10
for i=1,6 do 
    local function addThresholds(index)
        local table = {
            max = thresholds[index].max * thresholdMultiplier,
            values = {}
        }
        thresholds[i * 3 + index] = table
    
        for j,v in ipairs(thresholds[index].values) do
            table.values[j] = v * thresholdMultiplier
        end
    end

    addThresholds(1)
    addThresholds(2)
    addThresholds(3)

    thresholdMultiplier = thresholdMultiplier * 10
end

local insetView = nil
local axisView = nil
local backgroundLinesView = nil
local labelsView = nil
local xAxisLabelA = nil
local startIndex = 1

local dataInfos = {}

local itemList = {}

local function updateLabels(thresholdsToUse, maxValueOnThreshold)
    if labelsView then
        insetView:removeSubview(labelsView)
    end

    labelsView = View.new(insetView)
    labelsView.size = insetView.size

    
    for i,value in ipairs(thresholdsToUse.values) do
            local yPos = (value / maxValueOnThreshold) * axisView.size.y
            local yAxisLabel = TextView.new(labelsView)
            yAxisLabel.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionBottom)
            yAxisLabel.relativeView = axisView
            yAxisLabel.baseOffset = vec3(-8,yPos-8,0)
            yAxisLabel.font = Font(uiCommon.fontName, 16)
            yAxisLabel.color = vec4(1.0,1.0,1.0,1.0)
            yAxisLabel.text = mj:tostring(value)
        if value >= maxValueOnThreshold then
            break
        end
    end

end

--[[local function updateDescriptions(graphIndex)
    local statsTypeIndex = itemList[uiPopUpButton:getSelectedIndex(dataInfos[graphIndex].selectionButton)].statsTypeIndex
    local descriptionTextView = dataInfos[graphIndex].descriptionTextView
    if statsTypeIndex then
        descriptionTextView.text = statistics.types[statsTypeIndex].description
    else
        descriptionTextView.text = ""
    end
end]]

local maxPointCount = 8192
local lineBufferSize = maxPointCount * 2
local lineOutputBuffer = ffi.new("double[?]", lineBufferSize)

local function updateGraphs()
    local maxValue = -1
    for i=1,graphCount do
        if dataInfos[i].maxValue then
            maxValue = math.max(maxValue, dataInfos[i].maxValue)
        end
    end
    if maxValue < 1 then
        maxValue = 1
    end

    --mj:log("maxValue:", maxValue)
    
    local thresholdsToUse = thresholds[1]
    for i,threshold in ipairs(thresholds) do
        if threshold.max >= maxValue then
            thresholdsToUse = threshold
            break
        end
    end

    local maxValueOnThreshold = 0
    for i,value in ipairs(thresholdsToUse.values) do
        if value >= maxValue then
            maxValueOnThreshold = value
            break
        end
    end
    
    local gridLinePoints = {}
    for i,value in ipairs(thresholdsToUse.values) do
        local yPos = value / maxValueOnThreshold
        table.insert(gridLinePoints, vec2(0.0, yPos))
        table.insert(gridLinePoints, vec2(1.0, yPos))
        
        if value >= maxValueOnThreshold then
            break
        end
    end

    backgroundLinesView:setLines(gridLinePoints)

    for i=1,graphCount do
        if dataInfos[i].graphData then
            local pointCount = #dataInfos[i].graphData
            if pointCount > maxPointCount then
                mj:error("stats graph attempting to render too many lines:", pointCount / 2, " max:", maxPointCount / 2)
                dataInfos[i].graphView:setLines(nil)
            else
                --mj:log("stats graph line count:", pointCount / 2)
                --local scaledPoints = {}
                for j,point in ipairs(dataInfos[i].graphData) do

                    ffiCopy(lineOutputBuffer + ((j - 1) * 2 + 0), numberType(point.x), numberSize)
                    ffiCopy(lineOutputBuffer + ((j - 1) * 2 + 1), numberType(point.y / maxValueOnThreshold), numberSize)
                    --lineOutputBuffer[j * 2 + 0] = point.x
                    --lineOutputBuffer[j * 2 + 1] = point.y / maxValueOnThreshold
                    --table.insert(scaledPoints, vec2(point.x, point.y / maxValueOnThreshold))
                end

                dataInfos[i].graphView:setLineBuffer(lineOutputBuffer, math.floor(pointCount / 2))
            end
        else
            dataInfos[i].graphView:setLines(nil)
        end
    end

    updateLabels(thresholdsToUse, maxValueOnThreshold)
    
end

local function clearData(graphIndex)
    
    for i=1,graphCount do
        dataInfos[i].graphView:setLines(nil)
    end
    
    dataInfos[graphIndex].descriptionTextView.text = ""
end

local requestInProgress = {}
local queuedRequests = {}

local function showGraph(graphIndex, statisticsTypeIndex)
    if requestInProgress[graphIndex] then
        queuedRequests[graphIndex] = statisticsTypeIndex
        if statisticsTypeIndex then
            return
        else
            requestInProgress[graphIndex] = nil
        end
    end

    
    if statisticsTypeIndex then
        local currentStatsIndex = world:getStatsIndex()

        requestInProgress[graphIndex] = statisticsTypeIndex

        local startIndexForRequest = startIndex

        logicInterface:callServerFunction("getStatistics", { 
            statisticsTypeIndexes = {
                statisticsTypeIndex
            },
            startIndex = math.max(startIndexForRequest - 64,1),
        }, 
        function(result)
            if requestInProgress[graphIndex] == statisticsTypeIndex then
                requestInProgress[graphIndex] = nil
                if result then
                    --mj:log("result:", result)
                    local maxValue = 0
                    local rawStartIndex = startIndexForRequest
                    local startDayIndex = math.max(rawStartIndex, 1)


                    local populationResult = result[statisticsTypeIndex]
                    if populationResult then


                        local linePoints = {}
                        local startValue = nil
                        
                        local rollingAverageResults = nil
                        if statistics.types[statisticsTypeIndex].rollingAverage then
                            rollingAverageResults = {}
                            for dayIndex = startDayIndex - 1,currentStatsIndex do
                                local value = 0
                                for i=1,64 do
                                    local thisVaue = populationResult[dayIndex + 1 - i] or 0
                                    value = value + thisVaue
                                end

                                rollingAverageResults[dayIndex] = value
                            end
                        end

                        local function getSmoothedValue(dayIndex)
                            local thisValue = rollingAverageResults[dayIndex]
                            local averageSum = thisValue
                            local totalWeight = 1.0
                            local prevAbove = thisValue
                            local prevBelow = thisValue
                            local averageSlotCount = 4
                            for j=1,averageSlotCount do
                                local above = rollingAverageResults[dayIndex + j] or prevAbove
                                local below = rollingAverageResults[dayIndex - j] or prevBelow
                                
                                local weight = 1.0 - (j / (averageSlotCount + 1))
                                averageSum = averageSum + (above + below) * weight
                                totalWeight = totalWeight + weight * 2.0

                                prevBelow = below
                                prevAbove = above
                            end
                            return averageSum / totalWeight
                        end
                        
                        if statistics.types[statisticsTypeIndex].rollingAverage then
                            startValue = getSmoothedValue(startDayIndex - 1)
                        else
                            for i=startDayIndex - 1,1,-1 do
                                startValue = populationResult[i]
                                if startValue or i < startDayIndex - 64 then
                                    break
                                end
                            end
                        end

                        if not startValue then
                            startValue = 0
                        end
                        
                        local prevResult = startValue
                        local prevX = 0
                        
                        if startValue > maxValue then
                            maxValue = startValue
                        end

                        local maxDataFrameCount = 512
                        local spread = currentStatsIndex - startIndex
                        local step = 1 + math.floor(spread / maxDataFrameCount)
                        local stepCounter = step

                        local stepValueSum = 0
                        local stepValueCount = 0

                        for dayIndex = startDayIndex,currentStatsIndex do

                            local value = nil
                            if statistics.types[statisticsTypeIndex].rollingAverage then
                                value = getSmoothedValue(dayIndex)
                            else
                                value = populationResult[dayIndex]
                                if not value then
                                    value = prevResult
                                end
                            end

                            if value then
                                local skip = false
                                if dayIndex > startDayIndex and dayIndex < currentStatsIndex then
                                    if statistics.types[statisticsTypeIndex].rollingAverage then
                                        if step > 1 then
                                            stepValueSum = stepValueSum + value
                                            stepValueCount = stepValueCount + 1

                                            stepCounter = stepCounter + 1
                                            if stepCounter >= step then
                                                value = stepValueSum / stepValueCount
                                                
                                                stepCounter = 0
                                                stepValueSum = 0
                                                stepValueCount = 0
                                            else
                                                skip = true
                                            end
                                        end
                                    else
                                        if value == prevResult then
                                            local nextResult = populationResult[dayIndex + 1]
                                            if (not nextResult) or (nextResult == prevResult) then
                                                skip = true
                                            end
                                        end
                                    end
                                end

                                if not skip then
                                    if value > maxValue then
                                        maxValue = value
                                    end

                                    local xPosA = prevX
                                    local xPosB = (dayIndex - rawStartIndex + 1) / (currentStatsIndex - rawStartIndex + 1)
                                    local yPosA = prevResult
                                    local yPosB = value

                                    table.insert(linePoints, vec2(xPosA, yPosA))
                                    table.insert(linePoints, vec2(xPosB, yPosB))

                                    prevResult = value
                                    prevX = xPosB
                                end
                            end

                        end

                        
                        dataInfos[graphIndex].maxValue = maxValue

                        dataInfos[graphIndex].graphData = linePoints

                        
                        dataInfos[graphIndex].descriptionTextView.text = statistics:getDecriptionWithCurrentValue(statisticsTypeIndex, prevResult)

                    end
                end
                updateGraphs()
                if queuedRequests[graphIndex] then
                    local nextStatisticsTypeIndex = queuedRequests[graphIndex]
                    queuedRequests[graphIndex] = nil
                    showGraph(graphIndex, nextStatisticsTypeIndex)
                end
            end
        end)
    else
        clearData(graphIndex)
        dataInfos[graphIndex].maxValue = nil
        dataInfos[graphIndex].graphData = nil
        updateGraphs()
    end
end

local function updateTimeLabelText()
    local currentStatsIndex = world:getStatsIndex()
    local dayCount = (currentStatsIndex - startIndex) / 8
    dayCount = math.floor(dayCount)
    dayCount = mjm.clamp(dayCount, 1, math.floor(currentStatsIndex / 8))
    xAxisLabelA.text = locale:get("ui_stats_days_ago", {dayCount = dayCount})
end

local function updatePopupButtons()
    for i = 1,graphCount do
        if dataInfos[i] and dataInfos[i].selectionButton then
            uiPopUpButton:setItems(dataInfos[i].selectionButton, itemList)
        end
    end
end

local selectionIndexesByStatsType = {}

local function updateItemList()
    local newItemList = {}
    local newSelectionIndexesByStatsType = {}
    table.insert(newItemList, {
        name = locale:get("misc_noSelection"),
        iconModelName = "icon_cancel",
    })
    newSelectionIndexesByStatsType[0] = 1



    for i,statsTypeIndex in ipairs(statistics.orderedList) do
        local statsType = statistics.types[statsTypeIndex]
        local skip = false
        if statsType.resourceTypeIndex then
            if not world:tribeHasSeenResource(statsType.resourceTypeIndex) then
                skip = true
            end
        end
        if not skip then
            table.insert(newItemList, {
                name = statsType.name,
                iconObjectTypeIndex = statsType.iconObjectTypeIndex,
                iconModelName = statsType.iconModelName,
                iconModelMaterialRemapTable = statsType.iconModelMaterialRemapTable,
                statsTypeIndex = statsTypeIndex,
            })
            newSelectionIndexesByStatsType[statsTypeIndex] = #newItemList
        end
    end

    if #newItemList ~= #itemList then
        itemList = newItemList
        selectionIndexesByStatsType = newSelectionIndexesByStatsType
        updatePopupButtons()
    end

end

function tribeStatsUI:refreshAllGraphs()
    for i = 1,graphCount do
        showGraph(i, itemList[uiPopUpButton:getSelectedIndex(dataInfos[i].selectionButton)].statsTypeIndex)
    end
    updateTimeLabelText()
end

function tribeStatsUI:init(gameUI_, world_, manageUI_, hubUI_, parentView)
    world = world_
    
    local contentView = View.new(parentView)
    contentView.size = parentView.size

    local popOversView = View.new(parentView)
    popOversView.size = parentView.size

    local insetViewSize = vec2(contentView.size.x - 300, contentView.size.y - 20.0)

    updateItemList()

    insetView = ModelView.new(contentView)
    insetView:setModel(model:modelIndexForName("ui_inset_lg_4x3"))
    local scaleToUsePaneX = insetViewSize.x * 0.5
    local scaleToUsePaneY = insetViewSize.y * 0.5 / 0.75
    insetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    insetView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    insetView.size = insetViewSize
    insetView.baseOffset = vec3(-10,0,0)

    graphViewSize = vec2(insetView.size.x - 80 - 60, insetView.size.y - 80)

    axisView = LinesView.new(insetView)
    axisView.size = graphViewSize
    axisView.color = vec4(1.0,1.0,1.0,0.6)
    axisView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    axisView.baseOffset = vec3(-40,0,0)

    backgroundLinesView = LinesView.new(insetView)
    backgroundLinesView.size = graphViewSize
    backgroundLinesView.color = vec4(1.0,1.0,1.0,0.3)
    backgroundLinesView.relativePosition = axisView.relativePosition
    backgroundLinesView.baseOffset = axisView.baseOffset

    xAxisLabelA = TextView.new(insetView)
    xAxisLabelA.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
    xAxisLabelA.relativeView = axisView
    xAxisLabelA.baseOffset = vec3(0,-4,0)
    xAxisLabelA.font = Font(uiCommon.fontName, 16)
    xAxisLabelA.color = vec4(1.0,1.0,1.0,1.0)

    local sliderTitleText = TextView.new(insetView)
    sliderTitleText.font = Font(uiCommon.fontName, 16)
    sliderTitleText.text = locale:get("ui_action_zoom")
    sliderTitleText.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    sliderTitleText.relativeView = axisView

    local function updateStartIndex(fraction, reloadGraphs)
        local newStartIndex = nil
        if fraction <= 0.0015 then
            newStartIndex = 1
        else
            local currentStatsIndex = world:getStatsIndex()
            newStartIndex = math.floor(fraction * (currentStatsIndex - 8))
            newStartIndex = mjm.clamp(newStartIndex, 1, currentStatsIndex - 8)
        end

        if newStartIndex ~= startIndex then
            startIndex = newStartIndex
            if reloadGraphs then
                for i = 1,graphCount do
                    showGraph(i, itemList[uiPopUpButton:getSelectedIndex(dataInfos[i].selectionButton)].statsTypeIndex)
                end
                updateTimeLabelText()
            end
        end
    end

    local function sliderUpdate(value)
        local fraction = value / 1000
        updateStartIndex(fraction, true)
    end
    local function sliderRelease(value)
        local fraction = value / 1000
        clientGameSettings:changeSetting("statsZoomStartFraction", fraction)
    end

    local options = {
        continuous = true,
        releasedFunction = sliderRelease
    }
    local statsZoomStartFraction = clientGameSettings:getSetting("statsZoomStartFraction")
    local sliderValue = mjm.clamp(math.floor(statsZoomStartFraction * 1000), 1, 1000)
    local sliderView = uiSlider:create(insetView, vec2(200, 20), 1, 1000, sliderValue, options, sliderUpdate)
    sliderView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    sliderView.baseOffset = vec3(5, 0, 0)
    sliderView.relativeView = sliderTitleText
    
    sliderTitleText.baseOffset = vec3((-200 -5 - sliderTitleText.size.x) * 0.5, -4, 0)

    updateStartIndex(statsZoomStartFraction, false)
    insetView.mouseWheel = sliderView.mouseWheel

    local xAxisLabelC = TextView.new(insetView)
    xAxisLabelC.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBelow)
    xAxisLabelC.relativeView = axisView
    xAxisLabelC.baseOffset = vec3(0,-4,0)
    xAxisLabelC.font = Font(uiCommon.fontName, 16)
    xAxisLabelC.color = vec4(1.0,1.0,1.0,1.0)
    xAxisLabelC.text = locale:get("ui_stats_now")
    
    local popUpButtonSize = vec2(250.0, 40)
    local popUpMenuSize = vec2(popUpButtonSize.x + 20, 240)

    local colors = {
        vec4(0.3,1.0,0.3,0.8),
        vec4(0.3,1.0,1.0,0.8),
        vec4(1.0,0.3,1.0,0.8),
        vec4(1.0,1.0,0.3,0.8),
        vec4(1.0,0.3,0.3,0.8),
        vec4(0.3,0.3,1.0,0.8),
    }

    local yOffset = -20---contentView.size.y * 0.5 + 10 + 2 * (popUpButtonSize.y) + 20

    for i = 1,graphCount do 
        dataInfos[i] = {}

        local selectionButton = uiPopUpButton:create(contentView, popOversView, popUpButtonSize, popUpMenuSize)
        selectionButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        --restrictStorageTypeButton.relativeView = typeTextView
        selectionButton.baseOffset = vec3(10,yOffset, 0)
        uiPopUpButton:setItems(selectionButton, itemList)
        uiPopUpButton:setSelectionFunction(selectionButton, function(selectedIndex, selectedInfo)
            clearData(i)
            showGraph(i, selectedInfo.statsTypeIndex)
            --updateDescriptions(i)
            clientGameSettings:changeSetting(settingKeys[i], selectedInfo.statsTypeIndex or 0)
        end)

        yOffset = yOffset - popUpButtonSize.y - 5
        
        --yOffset = yOffset - 20

        local descriptionTextView = TextView.new(contentView)
        dataInfos[i].descriptionTextView = descriptionTextView
        descriptionTextView.font = Font(uiCommon.fontName, 16)
        descriptionTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        descriptionTextView.baseOffset = vec3(10,yOffset,0)
        descriptionTextView.wrapWidth = popUpButtonSize.x + 30

        yOffset = yOffset - 60

        dataInfos[i].selectionButton = selectionButton

        local selectionIndex = selectionIndexesByStatsType[clientGameSettings:getSetting(settingKeys[i])]
        if not selectionIndex then
            if i == 1 then
                selectionIndex = 2
            else
                selectionIndex = 1
            end
        end
        
        uiPopUpButton:setSelection(selectionButton, selectionIndex)
        --updateDescriptions(i)

        local graphView = LinesView.new(insetView)
        dataInfos[i].graphView = graphView
        graphView.size = graphViewSize
        graphView.color = colors[i]
        graphView.relativePosition = axisView.relativePosition
        graphView.baseOffset = axisView.baseOffset

        local colorView = ColorView.new(contentView)
        colorView.relativeView = selectionButton
        colorView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        colorView.size = vec2(10,10)
        colorView.baseOffset = vec3(4,0,0)
        colorView.color = colors[i]
    end

    axisView:setLines({
        vec2(0.0,0.0),
        vec2(0.0,1.0),
        vec2(1.0,0.0),
        vec2(1.0,1.0),
    })
    
end

function tribeStatsUI:update()
    --tribeStatsUI:refreshAllGraphs()
end

local refreshTimer = 0.0

function tribeStatsUI:show()
    refreshTimer = 0.0
    updateItemList()
    for i = 1,graphCount do
        local selectionIndex = selectionIndexesByStatsType[clientGameSettings:getSetting(settingKeys[i])]
        if not selectionIndex then
            if i == 1 then
                selectionIndex = 2
            else
                selectionIndex = 1
            end
        end
        
        uiPopUpButton:setSelection(dataInfos[i].selectionButton, selectionIndex)
        --local statsTypeIndex = uiPopUpButton:setSelection(selectionButton, clientGameSettings:getSetting(settingKeys[i]))
        clearData(i)
        showGraph(i, itemList[uiPopUpButton:getSelectedIndex(dataInfos[i].selectionButton)].statsTypeIndex)
    end
    updateTimeLabelText()

    insetView.update = function(dt)
        refreshTimer = refreshTimer + dt
        if refreshTimer >= 2.0 then
            refreshTimer = 0.0
            --mj:log("refreshing stats")
            tribeStatsUI:refreshAllGraphs()
        end
    end
end


function tribeStatsUI:hide()

end

function tribeStatsUI:popUI()
    return false
end

return tribeStatsUI