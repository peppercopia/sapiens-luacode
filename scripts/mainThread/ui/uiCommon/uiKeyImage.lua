local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local vec2 = mjm.vec2
local approxEqual = mjm.approxEqual

local eventManager = mjrequire "mainThread/eventManager"
local keyMapping = mjrequire "mainThread/keyMapping"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local material = mjrequire "common/material"
local model = mjrequire "common/model"

local uiKeyImage = {}

local allImages = {}

local textZOffset = 0.1
local textYOffset = 0.05

local function createImageView(uiKeyImageView)
    local userTable = uiKeyImageView.userData
    if not userTable.imageView then
        
        if userTable.keyView then
            userTable.keyView.hidden = true
        end

        if (not userTable.controllerSetIndex) or (not userTable.controllerActionName) then
            --mj:warn("createImageView missing controllerSetIndex or controllerActionName userTable:", userTable, " uiKeyImageView:", uiKeyImageView)
            uiKeyImageView.size = vec2(0, userTable.sizeY)
            
            if userTable.updateKeyImageSizeFunc then
                userTable.updateKeyImageSizeFunc(uiKeyImageView)
            end
            return
        end

        local imageView = ImageView.new(uiKeyImageView)
        imageView.masksEvents = false
        userTable.imageView = imageView
        imageView.size = vec2(userTable.sizeY, userTable.sizeY) * userTable.geometryScale
        local imagePath = eventManager:getPathForActionIconImage(userTable.controllerSetIndex, userTable.controllerActionName)
        if imagePath then
            imageView.imageTexture = MJCache:getTextureAbsolute(imagePath, false, false, true)
        end
    
        uiKeyImageView.size = imageView.size

        if userTable.updateKeyImageSizeFunc then
            userTable.updateKeyImageSizeFunc(uiKeyImageView)
        end
    end
end

local function createTextView(uiKeyImageView)
    local userTable = uiKeyImageView.userData
    if not userTable.keyView then
        
        if userTable.imageView then
            userTable.imageView.hidden = true
        end
        
        if (not userTable.groupKey) or (not userTable.mappingKey) then
            --mj:warn("createImageView missing groupKey or mappingKey userTable:", userTable, " uiKeyImageView:", uiKeyImageView)
            uiKeyImageView.size = vec2(0, userTable.sizeY)
            
            if userTable.updateKeyImageSizeFunc then
                userTable.updateKeyImageSizeFunc(uiKeyImageView)
            end
            return
        end

        local keyView = ModelView.new(uiKeyImageView)
        userTable.keyView = keyView
        keyView.masksEvents = false

        if userTable.disabled then
            keyView:setModel(model:modelIndexForName("ui_key"), {
                default = material.types.ui_disabled.index
            })
        else
            keyView:setModel(model:modelIndexForName("ui_key"))
        end

        
        local textView = TextView.new(keyView)
        userTable.textView = textView
        textView.font = Font(uiCommon.titleFontName, math.floor(userTable.sizeY * 0.75))
        textView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        textView.text = keyMapping:getLocalizedString(userTable.groupKey, userTable.mappingKey) or "??"
        textView.baseOffset = vec3(-userTable.sizeY * 0.1,userTable.sizeY * textYOffset,userTable.sizeY * textZOffset)
        textView.color = vec4(0.1,0.1,0.1,1.0)
        textView.masksEvents = false
        textView:setDepthTestEnabled(true)

        if not approxEqual(userTable.geometryScale, 1.0) then
            textView.fontGeometryScale = userTable.geometryScale
            textView.baseOffset = vec3(0,0,userTable.sizeY * textZOffset) * userTable.geometryScale
        end

        local width = textView.size.x + userTable.sizeY * 0.5
        width = math.max(width, userTable.sizeY)
        
        keyView.size = vec2(width, userTable.sizeY) * userTable.geometryScale

        local keyScaleToUseX = keyView.size.x * 0.5
        local keyScaleToUseY = keyView.size.y * 0.5
        keyView.scale3D = vec3(keyScaleToUseX,keyScaleToUseY,keyScaleToUseY)
        
        uiKeyImageView.size = keyView.size


        if userTable.updateKeyImageSizeFunc then
            userTable.updateKeyImageSizeFunc(uiKeyImageView)
        end
    end
end
    
function uiKeyImage:setGeometryScale(keyImage, newScale)
    local userTable = keyImage.userData
    if not approxEqual(userTable.geometryScale, newScale) then
        userTable.geometryScale = newScale
        if userTable.keyView then
            local keyView = userTable.keyView
            local textView = userTable.textView

            textView.fontGeometryScale = userTable.geometryScale
            textView.baseOffset = vec3(0,0,userTable.sizeY * textZOffset) * userTable.geometryScale

            local width = textView.size.x / userTable.geometryScale + userTable.sizeY * 0.5
            width = math.max(width, userTable.sizeY)

            keyView.size = vec2(width, userTable.sizeY) * userTable.geometryScale
            local keyScaleToUseX = keyView.size.x * 0.5
            local keyScaleToUseY = keyView.size.y * 0.5
            keyView.scale3D = vec3(keyScaleToUseX,keyScaleToUseY,keyScaleToUseY)
            keyImage.size = keyView.size
        end
        
        if userTable.imageView then
            local imageView = userTable.imageView
            imageView.size = vec2(userTable.sizeY, userTable.sizeY) * userTable.geometryScale
            keyImage.size = imageView.size
        end
        
        if userTable.updateKeyImageSizeFunc then
            userTable.updateKeyImageSizeFunc(keyImage)
        end
    end
end

function uiKeyImage:create(parentView, sizeY, groupKey, mappingKey, controllerSetIndex, controllerActionName, updateKeyImageSizeFunc)
    local userTable = {
        sizeY = sizeY,
        groupKey = groupKey,
        mappingKey = mappingKey,
        controllerSetIndex = controllerSetIndex,
        controllerActionName = controllerActionName,
        updateKeyImageSizeFunc = updateKeyImageSizeFunc,
        geometryScale = 1.0,
    }

    local containerView = View.new(parentView)
    containerView.userData = userTable

    if eventManager.controllerIsPrimary then
        --if controllerSetIndex then
            createImageView(containerView)
       --end
    else
       -- if mappingKey then
            createTextView(containerView)
       -- end
    end

    allImages[containerView] = containerView
    
    --mj:error("uiKeyImage:create userTable:", userTable, " uiKeyImageView:", containerView)

    local prevWasRemoved = containerView.wasRemoved
    containerView.wasRemoved = function()
        uiKeyImage:remove(containerView)
        if prevWasRemoved then
            prevWasRemoved()
        end
    end


    return containerView
end

function uiKeyImage:remove(uiKeyImageView)
    allImages[uiKeyImageView] = nil
end

function uiKeyImage:setDisabled(uiKeyImageView, newDisabled)
    if not newDisabled then
        newDisabled = nil
    end

    local userTable = uiKeyImageView.userData
    if userTable.disabled ~= newDisabled then
        userTable.disabled = newDisabled
        if newDisabled then
            userTable.keyView:setModel(model:modelIndexForName("ui_key"), {
                default = material.types.ui_disabled.index
            })
        else
            userTable.keyView:setModel(model:modelIndexForName("ui_key"))
        end
    end
end

local function updateViewForControllerChange(uiKeyImageView, newControllerIsPrimary)
    local userTable = uiKeyImageView.userData
    if not userTable then
        mj:error("no userTable:", uiKeyImageView)
    end
    if newControllerIsPrimary then
        if userTable.keyView then
            userTable.keyView.hidden = true
        end

        if userTable.imageView then
            userTable.imageView.hidden = false
            uiKeyImageView.size = userTable.imageView.size
        else
            createImageView(uiKeyImageView)
        end
    else
        if userTable.imageView then
            userTable.imageView.hidden = true
        end

        if userTable.keyView then
            userTable.keyView.hidden = false
            uiKeyImageView.size = userTable.keyView.size
        else
            createTextView(uiKeyImageView)
        end
    end

    if userTable.updateKeyImageSizeFunc then
        userTable.updateKeyImageSizeFunc(uiKeyImageView)
    end
end

function uiKeyImage:init()
    table.insert(eventManager.controllerPrimaryChangedListeners, function(newControllerIsPrimary)
        for k,v in pairs(allImages) do
            updateViewForControllerChange(k, newControllerIsPrimary)
        end
    end)
end

return uiKeyImage