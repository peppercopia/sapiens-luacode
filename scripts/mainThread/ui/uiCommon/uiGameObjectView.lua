local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4
local mat3Identity = mjm.mat3Identity
--local approxEqual = mjm.approxEqual

local gameObject = mjrequire "common/gameObject"
local sapienConstants = mjrequire "common/sapienConstants"
local modelPlaceholder = mjrequire "common/modelPlaceholder"
local material = mjrequire "common/material"
local model = mjrequire "common/model"

local uiAnimation = mjrequire "mainThread/ui/uiAnimation"

local uiGameObjectView = {}


uiGameObjectView.types = mj:enum {
    "standard",
    "backgroundCircle",
    "backgroundCircleBordered",
    "backgroundCircleBorderedLargeOutline",
}

function uiGameObjectView:create(parentView, size, type)
    local view = View.new(parentView)
    view.size = size
    local info = {
        type = type,
        renderTargetSizeToUse = size
    }
    view.userData = info

    if type == uiGameObjectView.types.backgroundCircle or type == uiGameObjectView.types.backgroundCircleBordered or type == uiGameObjectView.types.backgroundCircleBorderedLargeOutline then
        local backgroundView = ModelView.new(view)
        local backgroundScaleToUse = size.y * 0.5
        if type == uiGameObjectView.types.backgroundCircleBordered then
            backgroundView:setModel(model:modelIndexForName("icon_circle"))
        elseif type == uiGameObjectView.types.backgroundCircleBorderedLargeOutline then
            backgroundView:setModel(model:modelIndexForName("ui_circleBackgroundLargeOutline"))
            backgroundScaleToUse = backgroundScaleToUse * 1.05
        else
            backgroundView:setModel(model:modelIndexForName("ui_insetCircle"))
        end
        backgroundView.scale3D = vec3(backgroundScaleToUse,backgroundScaleToUse,backgroundScaleToUse)
        backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        backgroundView.size = size
        backgroundView.masksEvents = false
        info.backgroundView = backgroundView
    end

    return view
end

function uiGameObjectView:setBackgroundMasksEvents(view, masksEvents) --defaults to false
    local info = view.userData
    if info.backgroundView then
        info.backgroundView.masksEvents = masksEvents
    end
end


local function updateVisuals(view)
    local info = view.userData
    local gameObjectView = info.gameObjectView
    if gameObjectView then
        gameObjectView.greyScale = info.disabled
        if info.disabled then
            gameObjectView.color = vec4(0.5,0.5,0.5,0.5)
        else
            gameObjectView.color = vec4(1.0,1.0,1.0,1.0)
        end
        if info.type == uiGameObjectView.types.backgroundCircleBordered then
            if info.disabled then
                info.backgroundView:setModel(model:modelIndexForName("icon_circle"), {
                    default = material.types.ui_background_inset.index
                })
            else
                if info.warning then
                    local materialIndex = material.types.warning.index
                    if info.selected then
                        materialIndex = material.types.warning_selected.index
                    end
                    info.backgroundView:setModel(model:modelIndexForName("icon_circle"), {
                        default = materialIndex
                    })
                else
                    if info.selected then
                        info.backgroundView:setModel(model:modelIndexForName("icon_circle"), {
                            default = material.types.selectedText.index
                        })
                    else
                        info.backgroundView:setModel(model:modelIndexForName("icon_circle"))
                    end
                end
            end
        end
    else
        if info.iconView and info.currentModelName then
            if info.disabled then 
                info.iconView:setModel(model:modelIndexForName(info.currentModelName), {
                    default = material.types.ui_disabled.index
                })
            else
                info.iconView:setModel(model:modelIndexForName(info.currentModelName), info.currentRemapTable)
            end
        end
    end
end

local function setObjectOrModelName(view, object, modelName, iconModelMaterialRemapTable, subObjectTypesBlackListOrNil, subObjectTypesWhiteListOrNil)

    local info = view.userData

    local function removeCurrentView()
        if info.iconView then
            view:removeSubview(info.iconView)
            info.iconView = nil
        end
        if info.gameObjectView then
            view:removeSubview(info.gameObjectView)
            info.gameObjectView = nil
        end
    end

    local function updateGameObjectView(objectToUse)
        local gameObjectModelIndex = gameObject:modelIndexForGameObjectAndLevel(objectToUse, mj.SUBDIVISIONS - 1, nil)
        if not gameObjectModelIndex then
            removeCurrentView()
            return
        end

        local gameObjectView = info.gameObjectView

        local getNextAnimationFrame = nil

        local animationInstance = nil
        local animationModelTypeIndex = nil
        
        if objectToUse.objectTypeIndex == gameObject.types.sapien.index then
            animationInstance = uiAnimation:getUIAnimationInstance(sapienConstants:getAnimationGroupKey(objectToUse.sharedState))
        end

        if animationInstance then
            animationModelTypeIndex = animationInstance.modelTypeIndex
            getNextAnimationFrame = function()
                return uiAnimation:getNextAnimationFrame(animationInstance)
            end
        end

      --  mj:log(debug.traceback())

      --mj:log("objectToUse:", objectToUse, " gameObjectModelIndex:", gameObjectModelIndex)
        
        gameObjectView:setModel(gameObjectModelIndex,
            function (modelIndex, placeholderName)
                local placeholderInfo = modelPlaceholder:placeholderInfoForModelAndPlaceholderKey(modelIndex, placeholderName)
                if not placeholderInfo or placeholderInfo.hiddenOnBuildComplete then
                    return nil
                end
                local subModelIndex = placeholderInfo.defaultModelIndex
                if subObjectTypesBlackListOrNil or subObjectTypesWhiteListOrNil then
                    subModelIndex = modelPlaceholder:getPlaceholderModelIndexWithRestrictedObjectTypes(placeholderInfo, subObjectTypesBlackListOrNil, subObjectTypesWhiteListOrNil, nil)
                end
                return {subModelIndex, placeholderInfo.scale or 1.0}
            end,
            getNextAnimationFrame,
            animationModelTypeIndex
        )

        local rotation = mat3Identity
        local rotationFunction = gameObject.types[objectToUse.objectTypeIndex].objectViewRotationFunction
        if rotationFunction then
            rotation = rotationFunction(objectToUse)
        end
        gameObjectView.objectRotation = rotation

        local viewOffset = vec3(0.0,0.0,0.0)
        local objectViewOffsetFunction = gameObject.types[objectToUse.objectTypeIndex].objectViewOffsetFunction
        if objectViewOffsetFunction then
            viewOffset = objectViewOffsetFunction(objectToUse)
        end
        gameObjectView.viewOffset = viewOffset

        local cameraOffset = vec3(0.0,0.0,1.0)
        local objectViewCameraOffsetFunction = gameObject.types[objectToUse.objectTypeIndex].objectViewCameraOffsetFunction
        if objectViewCameraOffsetFunction then
            cameraOffset = objectViewCameraOffsetFunction(objectToUse)
        end

        gameObjectView.cameraDirection = cameraOffset
    end
    
    local function updateIconView(modelNameToUse, remapTableToUse)
        
        info.currentModelName = modelNameToUse
        info.currentRemapTable = remapTableToUse

        if info.disabled then 
            info.iconView:setModel(model:modelIndexForName(modelNameToUse), {
                default = material.types.ui_background_inset.index
            })
        else
            info.iconView:setModel(model:modelIndexForName(modelNameToUse), remapTableToUse)
        end
    end

    local function createGameObjectView(objectToUse)
        local renderTargetSize = info.renderTargetSizeToUse
        local renderSize = view.size
        if info.type == uiGameObjectView.types.backgroundCircleBordered then
            renderTargetSize = vec2(renderTargetSize.x * 0.8, renderTargetSize.y * 0.8)
            renderSize = vec2(renderSize.x * 0.8, renderSize.y * 0.8)
        end

        local objectImageView = GameObjectView.new(view, renderTargetSize)
        objectImageView.size = renderSize

        objectImageView.masksEvents = false
        if info.maskTexture then
            objectImageView:setMaskTexture(info.maskTexture)
        end

        info.gameObjectView = objectImageView
        updateGameObjectView(objectToUse)
    end

    local function createIconView(modelNameToUse, remapTableToUse)
        local objectIconView = ModelView.new(view)
        objectIconView.masksEvents = false
        info.iconView = objectIconView
        local iconSize = view.size.x * 0.8
        objectIconView.size = vec2(iconSize,iconSize)
        local iconViewScale = iconSize * 0.5
        objectIconView.scale3D = vec3(iconViewScale,iconViewScale,0.0)
        objectIconView.baseOffset = vec3(0,0,iconViewScale * 0.00001)
        updateIconView(modelNameToUse, remapTableToUse)
    end

    if object then
        local sourceObjectGameObjectType = gameObject.types[object.objectTypeIndex]
        if not sourceObjectGameObjectType then
            mj:error("uiGameObjectView attempting to display invalid game object type:", object.objectTypeIndex)
            for key,v in pairs(gameObject.typeIndexMap) do
                if v == object.objectTypeIndex then
                    mj:log("problem is:", key)
                end
            end
            error()
        else
            if not sourceObjectGameObjectType.iconIsUniquePerObject and info.objectTypeIndex == object.objectTypeIndex and info.gameObjectView and not sourceObjectGameObjectType.modelComposite then
                local function compareListSame(currentList, newList)
                    if currentList then
                        if newList then
                            local same = true
                            for k,v in pairs(currentList) do
                                if v ~= newList[k] then
                                    same = false
                                    break
                                end
                            end
                            if same then
                                for k,v in pairs(newList) do
                                    if v ~= currentList[k] then
                                        same = false
                                        break
                                    end
                                end
                            end
                            if same then
                                return true
                            end
                        end
                    else
                        if not newList then
                            return true
                        end
                    end
                    return false
                end

                if compareListSame(info.subObjectTypesBlackList, subObjectTypesBlackListOrNil) then
                    if compareListSame(info.subObjectTypesWhiteList, subObjectTypesWhiteListOrNil) then
                        return
                    end
                end
                
            end
            info.objectTypeIndex = object.objectTypeIndex
            info.subObjectTypesBlackList = mj:cloneTable(subObjectTypesBlackListOrNil)
            info.subObjectTypesWhiteList = mj:cloneTable(subObjectTypesWhiteListOrNil)

            local objectToUse = object
            local iconOverrideIconModelName = sourceObjectGameObjectType.iconOverrideIconModelName
            local iconModelMaterialRemapTableToUse = iconModelMaterialRemapTable
            

            if sourceObjectGameObjectType.iconOverrideFunction then
                local result = sourceObjectGameObjectType.iconOverrideFunction(object)
                if result then
                    if result.object then
                        objectToUse = result.object
                        local displayGameObjectType = gameObject.types[objectToUse.objectTypeIndex]
                        iconOverrideIconModelName = displayGameObjectType.iconOverrideIconModelName
                        if displayGameObjectType.iconOverrideMaterialRemapTableFunction then
                            iconModelMaterialRemapTableToUse = displayGameObjectType.iconOverrideMaterialRemapTableFunction(subObjectTypesBlackListOrNil, subObjectTypesWhiteListOrNil)
                        end
                    elseif result.iconModelName then
                        iconOverrideIconModelName = result.iconModelName
                        iconModelMaterialRemapTableToUse = result.iconModelMaterialRemapTable
                    end
                end
            end

            if sourceObjectGameObjectType.iconOverrideMaterialRemapTableFunction then
                iconModelMaterialRemapTableToUse = sourceObjectGameObjectType.iconOverrideMaterialRemapTableFunction(subObjectTypesBlackListOrNil, subObjectTypesWhiteListOrNil)
            end

            info.displayObjectTypeIndex = objectToUse.objectTypeIndex
            info.iconOverrideIconModelName = iconOverrideIconModelName
            info.iconModelMaterialRemapTable = iconModelMaterialRemapTableToUse


            if iconOverrideIconModelName then
                if info.iconView then
                    updateIconView(iconOverrideIconModelName, iconModelMaterialRemapTableToUse)
                else
                    removeCurrentView()
                    createIconView(iconOverrideIconModelName, iconModelMaterialRemapTableToUse)
                end
            else
                if info.gameObjectView then
                    updateGameObjectView(objectToUse)
                else
                    removeCurrentView()
                    createGameObjectView(objectToUse)
                end
            end
            
            updateVisuals(view)
        end
    elseif modelName then
        if info.iconView then
            updateIconView(modelName, iconModelMaterialRemapTable)
        else
            removeCurrentView()
            createIconView(modelName, iconModelMaterialRemapTable)
        end
    else
        removeCurrentView()
    end

end

function uiGameObjectView:setModelName(view, modelName, iconModelMaterialRemapTable)
    setObjectOrModelName(view, nil, modelName, iconModelMaterialRemapTable, nil)
end


function uiGameObjectView:setObject(view, object, restrictedSubObjectTypesOrNil, seenObjectTypesOrNil)
    setObjectOrModelName(view, object, nil, nil, restrictedSubObjectTypesOrNil, seenObjectTypesOrNil)
end

function uiGameObjectView:setMask(view, maskTexture) --only supported with the object type for now
    local info = view.userData
    if info.maskTexture ~= maskTexture then
        info.maskTexture = maskTexture
        if info.gameObjectView then
            info.gameObjectView:setMaskTexture(maskTexture)
        end
    end
end

function uiGameObjectView:setSize(view, newSize) --doesn't resize the render target for the gameObjectView, so will get blury if upscaled. Need to create a new uiGameObjectView if you want higher/lower detail
    view.size = newSize
    local info = view.userData
    if info.gameObjectView then
        if info.type == uiGameObjectView.types.backgroundCircleBordered then
            info.gameObjectView.size = vec2(view.size.x * 0.8, view.size.y * 0.8)
        else
            info.gameObjectView.size = view.size
        end
    elseif info.iconView then
        local iconViewScale = newSize.x * 0.5
        info.iconView.size = newSize
        info.iconView.scale3D = vec3(iconViewScale,iconViewScale,0.0)
    end

    if type == uiGameObjectView.types.backgroundCircle or type == uiGameObjectView.types.backgroundCircleBordered then
        local backgroundScaleToUse = view.size.y * 0.5
        info.backgroundView.scale3D = vec3(backgroundScaleToUse,backgroundScaleToUse,backgroundScaleToUse)
        info.backgroundView.size = view.size
    end
end

function uiGameObjectView:setBackgroundAlpha(view, alpha)
    local info = view.userData
    if info.backgroundView then
        info.backgroundView.alpha = alpha
    end
end

function uiGameObjectView:setDisabled(view, disabled)
    local info = view.userData
    if info.disabled ~= disabled then
        info.disabled = disabled
        updateVisuals(view)
    end
end

function uiGameObjectView:setWarning(view, warning)
    local info = view.userData
    if info.warning ~= warning then
        info.warning = warning
        updateVisuals(view)
    end
end

function uiGameObjectView:setSelected(view, selected)
    local info = view.userData
    if info.selected ~= selected then
        info.selected = selected
        updateVisuals(view)
    end
end

return uiGameObjectView