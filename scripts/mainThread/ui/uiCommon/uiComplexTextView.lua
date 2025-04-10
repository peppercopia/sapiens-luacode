local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local eventManager = mjrequire "mainThread/eventManager"
--local audio = mjrequire "mainThread/audio"

local model = mjrequire "common/model"
--local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiKeyImage = mjrequire "mainThread/ui/uiCommon/uiKeyImage"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"

local uiComplexTextView = {}

local keyImageSize = 20.0

function uiComplexTextView:update(complexView, elementArray)
    local userDataTable = complexView.userData

    for i,subview in ipairs(userDataTable.views) do
        complexView:removeSubview(subview)
    end
    userDataTable.views = {}

    local xOffset = 0.0
    local yOffset = 0.0
    local maxWidth = 0.0

    local addArray = nil

    local function updateOffsets(incomingView, incomingWidth, incomingPadding, additionalOffsetOrNil)
        if userDataTable.wrapWidthOrNil then
            if xOffset + incomingWidth > userDataTable.wrapWidthOrNil and xOffset > 0 then
                xOffset = 0
                yOffset = yOffset - 20
            end
        end
        
        local combinedOffset = vec3(xOffset,yOffset,0)
        if additionalOffsetOrNil then
            combinedOffset = combinedOffset + additionalOffsetOrNil
        end
        incomingView.baseOffset = combinedOffset
        
        xOffset = xOffset + incomingWidth + incomingPadding
        maxWidth = math.max(maxWidth,xOffset)
    end

    
    local function addText(text)
        local textView = TextView.new(complexView)
        table.insert(userDataTable.views, textView)
        textView.font = Font(uiCommon.fontName, 16)
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        textView.text = text
        updateOffsets(textView, textView.size.x, 5, nil)

        --textView.baseOffset = vec3(xOffset,yOffset,0)
        --xOffset = xOffset + textView.size.x + 5
    end
    
    local function addColoredText(textTable)
        local textView = TextView.new(complexView)
        table.insert(userDataTable.views, textView)
        textView.font = Font(uiCommon.fontName, 16)
        textView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        textView:addColoredText(textTable.text, textTable.color)

        updateOffsets(textView, textView.size.x, 5, nil)

        --textView.baseOffset = vec3(xOffset,yOffset,0)
        --xOffset = xOffset + textView.size.x + 5
    end
    
    local function addKeyImage(keyTable)
        local keyImage = uiKeyImage:create(complexView, keyImageSize, keyTable.groupKey, keyTable.mappingKey, nil, nil, nil)
        table.insert(userDataTable.views, keyImage)
        local keyImageWidth = keyImage.size.x
        keyImage.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        
        updateOffsets(keyImage, keyImageWidth, 5, vec3(0.0,1.0,0.0))

        --keyImage.baseOffset = vec3(xOffset, 1.0 + yOffset, 0.0)
        --xOffset = xOffset + keyImageWidth + 5.0
    end

    local function addIcon(iconModelName)
        local iconHalfSize = keyImageSize * 0.5
        local icon = ModelView.new(complexView)
        table.insert(userDataTable.views, icon)
        icon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
       -- icon.baseOffset = vec3(xOffset - 2,2 + yOffset,0.5)
        icon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
        icon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
        icon:setModel(model:modelIndexForName(iconModelName))
        
        updateOffsets(icon, keyImageSize, 1, vec3(-2.0,2.0,0.5))

        --xOffset = xOffset + keyImageSize + 1
    end
    
    local function addGameObject(objectInfo)
        local iconHalfSize = keyImageSize * 0.5
        local objectView = uiGameObjectView:create(complexView, vec2(iconHalfSize,iconHalfSize) * 2.0, uiGameObjectView.types.standard)
        table.insert(userDataTable.views, objectView)
        objectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        objectView.size = vec2(iconHalfSize,iconHalfSize) * 2.0
        uiGameObjectView:setObject(objectView, objectInfo, nil, nil)
        
        updateOffsets(objectView, keyImageSize - 4, 1, vec3(-2.0,-1.0,0.5))
    end

    local function addElement(element)
        if element.text then
            addText(element.text)
        elseif element.coloredText then
            addColoredText(element.coloredText)
        elseif element.keyImage then
            addKeyImage(element.keyImage)
        elseif element.icon then
            addIcon(element.icon)
        elseif element.gameObject then
            addGameObject(element.gameObject)
        elseif element.keyboardController then
            if eventManager.controllerIsPrimary then
                addArray(element.keyboardController.controller)
            else
                addArray(element.keyboardController.keyboard)
            end
        end
    end
    
    addArray = function(array)
        if array and type(array) == "table" then
            if array[1] then
                for i, element in ipairs(array) do
                    addElement(element)
                end
            else
                addElement(array)
            end
        end
    end

    addArray(elementArray)

    local width = maxWidth
    --[[if wrapWidthOrNil then
        width = math.max(width, wrapWidthOrNil)
    end]]

    complexView.size = vec2(width, 20 - yOffset)
end

function uiComplexTextView:create(parentView, elementArray, wrapWidthOrNil) -- Note on wrapWidth: this doesn't support wrapping long text elements. Too difficult.
    
    local userDataTable = {
        wrapWidthOrNil = wrapWidthOrNil,
        views = {},
    }

    local contentView = View.new(parentView)
    contentView.userData = userDataTable
    --contentView.color = mjm.vec4(0.0,0.0,0.5,0.5)

    uiComplexTextView:update(contentView, elementArray)

    return contentView
end

return uiComplexTextView
