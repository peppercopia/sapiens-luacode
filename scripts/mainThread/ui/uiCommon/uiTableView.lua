local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local audio = mjrequire "mainThread/audio"


local standardTextColor = mj.textColor
local hoverTextColor = mj.highlightColor
local disabledTextColor = vec4(mj.textColor.x, mj.textColor.y, mj.textColor.z, 0.5)

local standardImage = "img/ui/uiBoxSmallLight.png"
local hoverImage = "img/ui/uiBoxSmall.png"
local clickImage = "img/ui/uiBoxSmallDarkInner.png"
local selectedImage = "img/ui/uiBoxSmallSelected.png"
local selectedHoverImage = "img/ui/uiBoxSmallSelectedDarker.png"
local disabledImage = "img/ui/uiBoxSmallVeryLight.png"

local uiTableView = {}

local rowHeight = 30


local function updateVisuals(rowInfo)
    local function changeBackground(imageName)
        uiCommon:changeBackgroundViewImage(rowInfo.backgroundView, imageName)
    end

    local function updateTextColor(color)
        for i,textView in ipairs(rowInfo.textViews) do
            textView.color = color
        end
    end

    if rowInfo.disabled then
        updateTextColor(disabledTextColor)
        changeBackground(disabledImage)
    else
        if rowInfo.hover then
            updateTextColor(hoverTextColor)
            if rowInfo.mouseDown then
                changeBackground(clickImage)
            else
                if rowInfo.selected then
                    changeBackground(selectedHoverImage)
                else
                    changeBackground(hoverImage)
                end
            end
        else
            if rowInfo.selected then
                updateTextColor(hoverTextColor)
                changeBackground(selectedImage)
            else
                updateTextColor(standardTextColor)
                changeBackground(standardImage)
            end
        end
    end
end

function uiTableView:updateData(tableView, data)
    local tableInfo = tableView.userData

    if tableInfo.contentView then
        tableView:removeSubview(tableInfo.contentView)
    end

    local contentView = View.new(tableView)
    contentView.size = tableView.size
    tableInfo.contentView = contentView
    local rowInfos = {}
    tableInfo.rowInfos = rowInfos
    local columnWidths = tableInfo.columnWidths

    for i,row in ipairs(data) do
        local rowBackgroundView = uiCommon:createBackgroundView(contentView, standardImage, 4.0)
        uiCommon:resizeBackgroundView(rowBackgroundView, vec2(contentView.size.x - 4, rowHeight))
        rowBackgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
        rowBackgroundView.baseOffset = vec3(0, -2 - ((i - 1) * rowHeight), 0)


        local rowInfo = {
            backgroundView = rowBackgroundView,
            textViews = {}
        }
        rowInfos[i] = rowInfo

        rowBackgroundView.hoverStart = function ()
            if not rowInfo.hover then
                if not rowInfo.disabled then
                    rowInfo.hover = true
                    audio:playUISound(uiCommon.hoverSoundFile)
                    updateVisuals(rowInfo)
                end
            end
        end
    
        rowBackgroundView.hoverEnd = function ()
            if rowInfo.hover then
                rowInfo.hover = false
                rowInfo.mouseDown = false
                updateVisuals(rowInfo)
            end
        end
    
        rowBackgroundView.mouseDown = function (buttonIndex)
            if buttonIndex == 0 then
                if not rowInfo.mouseDown then
                    if not rowInfo.disabled then
                        rowInfo.mouseDown = true
                        updateVisuals(rowInfo)
                        audio:playUISound(uiCommon.clickDownSoundFile)
                    end
                end
            end
        end
    
        rowBackgroundView.mouseUp = function (buttonIndex)
            if buttonIndex == 0 then
                if rowInfo.mouseDown then
                    rowInfo.mouseDown = false
                    updateVisuals(rowInfo)
                    audio:playUISound(uiCommon.clickReleaseSoundFile)
                end
            end
        end
    
        rowBackgroundView.click = function()
            if not rowInfo.disabled then
                rowInfo.hover = false
                uiTableView:selectRowAtIndex(tableView, i)
            end
        end


        local xOffset = 0
        for j,column in ipairs(row) do
            local textView = TextView.new(rowBackgroundView)
            textView.font = Font(uiCommon.fontName, 16)
            textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            textView.color = standardTextColor
            textView.text = column
            textView.baseOffset = vec3(xOffset + 4, 0, 0)

            rowInfos[i].textViews[j] = textView

            if j > #columnWidths then
                mj:log("ERROR: data contains more columns than columnWidths supplied to table view")
                break
            end
            xOffset = xOffset + columnWidths[j]
        end
    end
end

function uiTableView:create(parentView, size, columnWidths)
    local mainView = View.new(parentView)
    mainView.size = size
    
    local backgroundView = uiCommon:createBackgroundView(mainView, "img/ui/uiBoxSmallInnerBevelOnly.png", 4.0)
    uiCommon:resizeBackgroundView(backgroundView, size)

    mainView.userData = {
        columnWidths = columnWidths
    }

    return mainView
end

function uiTableView:selectRowAtIndex(tableView, newSelection)
    local tableInfo = tableView.userData
    if tableInfo.selectedRowIndex ~= newSelection then
        if tableInfo.selectedRowIndex and tableInfo.selectedRowIndex > 0 and tableInfo.selectedRowIndex <= #tableInfo.rowInfos then
            tableInfo.rowInfos[tableInfo.selectedRowIndex].selected = false
            updateVisuals(tableInfo.rowInfos[tableInfo.selectedRowIndex])
        end

        tableInfo.selectedRowIndex = newSelection

        if newSelection > 0 and newSelection <= #tableInfo.rowInfos then
            tableInfo.rowInfos[newSelection].selected = true
            updateVisuals(tableInfo.rowInfos[newSelection])
        end

        if tableInfo.selectionChangedFunction then 
            tableInfo.selectionChangedFunction(newSelection)
        end
    end
end

function uiTableView:selectedRowIndex(tableView)
    return tableView.userData.selectedRowIndex
end

function uiTableView:setSelectionChangedFunction(tableView, func)
    local tableInfo = tableView.userData
    tableInfo.selectionChangedFunction = func
end

return uiTableView