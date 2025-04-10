local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4

local gameObject = mjrequire "common/gameObject"
local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local resource = mjrequire "common/resource"
local plan = mjrequire "common/plan"

--local uiAnimation = mjrequire "mainThread/ui/uiAnimation"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
--local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
--local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local evolvingObject = mjrequire "common/evolvingObject"

local inspectCraftPanel = mjrequire "mainThread/ui/inspect/inspectCraftPanel"
local inspectStoragePanel = mjrequire "mainThread/ui/inspect/inspectStoragePanel"
local inspectUsePanel = mjrequire "mainThread/ui/inspect/inspectUsePanel"
local inspectRebuildPanel = mjrequire "mainThread/ui/inspect/inspectRebuildPanel"

local hubUIUtilities = mjrequire "mainThread/ui/hubUIUtilities"

--local storageObjectMoveUI = mjrequire "mainThread/ui/storageObjectMoveUI"

--local logicInterface = mjrequire "mainThread/logicInterface"
--local playerStorageObjects = mjrequire "mainThread/playerStorageObjects"

local maxContainedResourceViewCount = 4
local containedResourceInfos = {}

local inspectStorageUI = {}

local inspectUI = nil
--local gameUI = nil
local world = nil
local inspectObjectUI = nil


local storageObjectDetailView = nil

function inspectStorageUI:updateObjectInfo()

    --mj:log("inspectStorageUI:updateObjectInfo")
    local object = inspectUI.baseObjectOrVertInfo
    local sharedState = object.sharedState

    
    if inspectUI.selectedObjectOrVertInfoCount > 1 then
        local objectName = mj:tostring(inspectUI.selectedObjectOrVertInfoCount) .. " " .. gameObject.types[object.objectTypeIndex].plural
        inspectUI:setTitleText(objectName, false)

        storageObjectDetailView.hidden = true
    else
    
        local gameObjectType = gameObject.types[object.objectTypeIndex]
        local objectName = gameObjectType.name
        if object.sharedState and object.sharedState.name then
            objectName = object.sharedState.name
        end
        inspectUI.objectName = objectName

        if inspectUI:canChangeName() then
            if not uiTextEntry:isEditing(inspectUI.nameTextEntry) then
                inspectUI:setTitleText(objectName, true)
            end
        else
            inspectUI:setTitleText(objectName, false)
        end

        
        storageObjectDetailView.hidden = false

        local inventory = sharedState.inventory

        local resourceInfos = {}
        local orderedResourceInfos = {}

        if inventory and inventory.objects then
            for i,objectInfo in ipairs(inventory.objects) do
                local resourceTypeIndex = gameObject.types[objectInfo.objectTypeIndex].resourceTypeIndex
                local resourceInfo = resourceInfos[resourceTypeIndex]

                if not resourceInfo then
                    resourceInfo = {
                        count = 0,
                        totalDegraded = 0.0,
                        totalEvolutionTimeRemaining = 0.0,
                        resourceTypeIndex = resourceTypeIndex,
                        objectTypeIndex = objectInfo.objectTypeIndex,
                        portionCount = 0,
                    }
                    resourceInfos[resourceTypeIndex] = resourceInfo
                    table.insert(orderedResourceInfos, resourceInfo)
                end

                local fractionDegraded =  0.0
                
                    
                local evolution = evolvingObject.evolutions[resourceInfo.objectTypeIndex]
                if evolution and objectInfo.fractionDegraded then
                    local worldTime = world:getWorldTime()
                    fractionDegraded = hubUIUtilities:getTrueFractionDegraded(objectInfo.fractionDegraded, objectInfo.degradeReferenceTime, worldTime, evolution, sharedState.covered)
                    local evolutionDuration = evolvingObject:getEvolutionDuration(resourceInfo.objectTypeIndex, fractionDegraded, objectInfo.degradeReferenceTime, worldTime, sharedState.covered)
                    resourceInfo.totalEvolutionTimeRemaining = resourceInfo.totalEvolutionTimeRemaining + evolutionDuration
                end

                resourceInfo.count = resourceInfo.count + 1
                resourceInfo.totalDegraded = resourceInfo.totalDegraded + fractionDegraded
                local foodPortionCount = resource:getFoodPortionCount(objectInfo.objectTypeIndex)
                if foodPortionCount then
                    resourceInfo.portionCount = resourceInfo.portionCount + (foodPortionCount - (objectInfo.usedPortionCount or 0))
                end

            end
        end

        
        local function sortResource(a,b)
            return a.count > b.count
        end

        table.sort(orderedResourceInfos, sortResource)

        local maxWidth = 0
        local visibleCount = 0
        for i=1,maxContainedResourceViewCount do
            if i <= #orderedResourceInfos then
                local lineWidth = 0.0
                visibleCount = visibleCount + 1
                containedResourceInfos[i].view.hidden = false
                local resourceInfo = orderedResourceInfos[i]
                
                uiGameObjectView:setObject(containedResourceInfos[i].gameObjectView, {
                    objectTypeIndex = resourceInfo.objectTypeIndex
                }, nil, nil)

                local textString = resource:stringForResourceTypeAndCount(resourceInfo.resourceTypeIndex, resourceInfo.count)

                if resourceInfo.portionCount ~= 0 then
                    textString = textString .. ": " .. locale:get("ui_portionCount", {portionCount = resourceInfo.portionCount})
                end

                containedResourceInfos[i].textView.text = textString

                lineWidth = lineWidth + containedResourceInfos[i].textView.size.x

                local usageIcon = containedResourceInfos[i].usageIcon
                local usageProgressIcon = containedResourceInfos[i].usageProgressIcon

                local fractionDegraded = 0.0

                if resourceInfo.totalDegraded > 0.0001 then
                    fractionDegraded = resourceInfo.totalDegraded / resourceInfo.count
                    usageIcon.hidden = false
                    usageProgressIcon.hidden = false
                    usageProgressIcon:setRadialMaskFraction(fractionDegraded)
                    
                    lineWidth = lineWidth + usageProgressIcon.size.x + 10
                else
                    usageIcon.hidden = true
                    usageProgressIcon.hidden = true
                end

                local evolution = evolvingObject.evolutions[resourceInfo.objectTypeIndex]
                if evolution then
                    local averageEvolutionTime = resourceInfo.totalEvolutionTimeRemaining / resourceInfo.count
                    local evolutionBucket = evolvingObject:getEvolutionBucket(averageEvolutionTime)

                    containedResourceInfos[i].coveredTextView.text = ""
                    
                    --uiToolTip:addColoredTitleText(usageIcon, evolvingObject.categories[evolution.categoryIndex].actionName, evolvingObject.categories[evolution.categoryIndex].color)
                    containedResourceInfos[i].coveredTextView:addColoredText(evolvingObject.categories[evolution.categoryIndex].actionName, evolvingObject.categories[evolution.categoryIndex].color)
                    containedResourceInfos[i].coveredTextView:addColoredText(" " .. evolvingObject:getName(resourceInfo.objectTypeIndex, evolutionBucket), mj.textColor)
                    
                    --local text = evolvingObject.categories[evolution.categoryIndex].actionName .. " " .. evolvingObject.descriptionThresholdsHours[evolutionBucket].name
                    
                    --containedResourceInfos[i].coveredTextView.text = text
                    if sharedState.covered then
                        local color = mjm.vec4(0.5,1.0,0.5, 1.0)
                        containedResourceInfos[i].coveredTextView:addColoredText(" " .. locale:get("misc_inside"), color)
                    else
                        containedResourceInfos[i].coveredTextView:addColoredText(" " .. locale:get("misc_outside"), evolvingObject.categories[evolution.categoryIndex].color)
                    end

                    containedResourceInfos[i].coveredTextView.hidden = false

                    usageProgressIcon:setModel(model:modelIndexForName("icon_circle_thic"), {
                        default = evolvingObject.categories[evolution.categoryIndex].material
                    })
                    
                    lineWidth = lineWidth + containedResourceInfos[i].coveredTextView.size.x + 12
                else
                    containedResourceInfos[i].coveredTextView.hidden = true

                    usageProgressIcon:setModel(model:modelIndexForName("icon_circle_thic"), {
                        default = material.types.ui_red.index
                    })
                end

                maxWidth = math.max(maxWidth, lineWidth)
            else
                containedResourceInfos[i].view.hidden = true
            end
        end

        local height = 24 * visibleCount
        local width = 0.0
        if visibleCount > 0 then
            width = math.max(maxWidth - 180.0, 0)
        end

        inspectUI.contentExtraHeight = height
        inspectUI.contentExtraWidth = width
        

        if not inspectObjectUI.manageStorageContainerView.hidden then
            inspectStoragePanel:updateObjectInfo(object)
        end
    end
    
end

function inspectStorageUI:load(gameUI_, inspectUI_, world_, inspectObjectUI_)

    inspectUI = inspectUI_
    --gameUI = gameUI_
    world = world_
    inspectObjectUI = inspectObjectUI_

    local containerView = inspectUI.containerView

    storageObjectDetailView = View.new(containerView)
    storageObjectDetailView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    storageObjectDetailView.hidden = true

    for i = 1,maxContainedResourceViewCount do
        local resourceView = View.new(storageObjectDetailView)
        resourceView.size = vec2(200.0,24.0)
        resourceView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBelow)
        resourceView.relativeView = inspectUI.nameTextEntry
        resourceView.baseOffset = vec3(0,-(i - 1)*resourceView.size.y, 0)
        resourceView.hidden = true

        
        local contentsViewItemObjectImageViewSize = vec2(20.0, 20.0)
        local gameObjectView = uiGameObjectView:create(resourceView, contentsViewItemObjectImageViewSize, uiGameObjectView.types.backgroundCircle)
        gameObjectView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        --gameObjectView.baseOffset = vec3(0,-10, 2)
        
        local resourceTextView = TextView.new(resourceView)
        resourceTextView.font = Font(uiCommon.fontName, 16)
        resourceTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        resourceTextView.relativeView = gameObjectView
        resourceTextView.baseOffset = vec3(0,-2, 0)
       -- resourceTextView.baseOffset = vec3(0,0, 0)
        resourceTextView.color = mj.textColor

        
        --[[local usageIcon = ModelView.new(resourceView)
        usageIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        usageIcon.relativeView = resourceTextView
        usageIcon.baseOffset = vec3(8,1,2)
        usageIcon:setModel(model:modelIndexForName("icon_circle_filled"), {
            default = material.types.ui_background_dark.index
        })]]

        local iconHalfSize = 8
        --usageIcon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
       --usageIcon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
        
        local usageProgressIcon = ModelView.new(resourceView)
        usageProgressIcon.masksEvents = false
        usageProgressIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        usageProgressIcon.relativeView = resourceTextView
        usageProgressIcon.baseOffset = vec3(10,2,2)
        usageProgressIcon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
        usageProgressIcon.size = vec2(iconHalfSize,iconHalfSize) * 2.0

        
        local coveredTextView = TextView.new(resourceView)
        coveredTextView.font = Font(uiCommon.fontName, 16)
        coveredTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        coveredTextView.relativeView = resourceTextView
        coveredTextView.color = mj.textColor
        coveredTextView.baseOffset = vec3(4 + 8 + iconHalfSize * 2.0, 0, 0)

        containedResourceInfos[i] = {
            view = resourceView,
            gameObjectView = gameObjectView,
            textView = resourceTextView,
            usageIcon = usageProgressIcon,
            usageProgressIcon = usageProgressIcon,
            coveredTextView = coveredTextView,
        }
    end

end

function inspectStorageUI:showNext(storageObject)
    inspectUI:setIconForObject(storageObject)
    --local animationInstance = uiAnimation:getUIAnimationInstance(storageObjectConstants:getAnimationGroupKey(storageObject.sharedState))
    --uiCommon:setGameObjectViewObject(inspectUI.objectImageView, storageObject, animationInstance)
    inspectStorageUI:updateObjectInfo()
end


function inspectStorageUI:showInspectPanelForActionUISelectedPlanType(planTypeIndex)
    if planTypeIndex == plan.types.craft.index then
        inspectCraftPanel:show(inspectUI.baseObjectOrVertInfo)
        inspectUI:showModalPanelView(inspectObjectUI.inspectCraftContainerView, inspectCraftPanel)
    elseif planTypeIndex == plan.types.manageStorage.index then
        inspectStoragePanel:show(inspectUI.baseObjectOrVertInfo)
        inspectUI:showModalPanelView(inspectObjectUI.manageStorageContainerView,inspectStoragePanel)
    elseif planTypeIndex == plan.types.constructWith.index then
        inspectUsePanel:show(inspectUI.baseObjectOrVertInfo)
        inspectUI:showModalPanelView(inspectObjectUI.inspectUseContainerView, inspectUsePanel)
    elseif planTypeIndex == plan.types.rebuild.index then
        inspectRebuildPanel:show(inspectUI.baseObjectOrVertInfo)
        inspectUI:showModalPanelView(inspectObjectUI.inspectRebuildContainerView, inspectRebuildPanel)
    end
end

function inspectStorageUI:show(baseObject, allObjects)

    --mj:log("inspectStorageUI:show")
    
    inspectStorageUI:updateObjectInfo()
    
    inspectUI:setIconForObject(baseObject)

end

function inspectStorageUI:hide()
    storageObjectDetailView.hidden = true
end


return inspectStorageUI