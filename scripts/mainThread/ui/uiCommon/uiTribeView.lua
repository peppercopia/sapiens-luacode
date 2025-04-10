local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
--local vec2 = mjm.vec2
local mat3Rotate = mjm.mat3Rotate
local mat3Identity = mjm.mat3Identity
--local mat3LookAtInverse = mjm.mat3LookAtInverse
--local normalize = mjm.normalize
--local vec4 = mjm.vec4

--local animationGroups = mjrequire "common/animationGroups"
--local gameObject = mjrequire "common/gameObject"
--local model = mjrequire "common/model"
--local material = mjrequire "common/material"
local sapienConstants = mjrequire "common/sapienConstants"
local gameObject = mjrequire "common/gameObject"
local modelPlaceholder = mjrequire "common/modelPlaceholder"
local rng = mjrequire "common/randomNumberGenerator"
--local audio = mjrequire "mainThread/audio"

--local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiAnimation = mjrequire "mainThread/ui/uiAnimation"

local uiTribeView = {}


local standingAnimations = {
    {
        key = "stand",
    },
    {
        key = "standInspect",
    },
    {
        key = "stand",
    },
    {
        key = "standInspect",
    },
    {
        key = "stand",
    },
    {
        key = "standInspect",
    },
    {
        key = "wave",
    },
}

local sittingAnimations = {
    {
        key = "sit1",
    },
    {
        key = "sit1Wave",
    },
    {
        key = "sit2",
    },
    {
        key = "sit3",
    },
    {
        key = "sit4",
    },
}

function uiTribeView:setTribe(tribeView, tribeID, tribeSapienInfos, worldTimeOrNil)
    tribeView:removeModel()

    if tribeView.size.x < 0.001 or tribeView.size.y < 0.001 then
        mj:log("tribeView.size:", tribeView.size)
        mj:error("tribe view must have a non-zero size before setTribe is called")
        error()
    end


    local ratio = tribeView.size.x / tribeView.size.y
    local baseRatio = 1420.0/400.0

    local widthDifferenceMultiplier = ratio / baseRatio

    local maxSapiensInFirstRow = math.floor(8.5 * widthDifferenceMultiplier)
    --mj:log("maxSapiensInFirstRow:", maxSapiensInFirstRow)
    local orderedPosInfos = {}

    local function sortInfos(a,b)
        return a.sortValue < b.sortValue
    end

    local worldTimeSeed = math.floor((worldTimeOrNil or 0) / 10.0)

    for sapienID,sapienInfo in pairs(tribeSapienInfos) do
        if not sapienInfo.objectTypeIndex then --bit of a hack, in the main load menu, our sapien infos don't store the objectTypeIndex
            sapienInfo.objectTypeIndex = gameObject.types.sapien.index
        end
        table.insert(orderedPosInfos, {
            sapienID = sapienID,
            sapienInfo = sapienInfo,
            sortValue = sapienInfo.sharedState.lifeStageIndex + sapienInfo.sharedState.ageFraction + rng:valueForUniqueID(sapienID, 4385 + worldTimeSeed) * 2.0,
        })
    end

    table.sort(orderedPosInfos, sortInfos)

    local sapienCount = #orderedPosInfos
    local rows = {}
    if sapienCount > maxSapiensInFirstRow then
        local countThisRow = maxSapiensInFirstRow
        local totalCount = 0
        for rowIndex=1,99 do
            table.insert(rows, {
                count = countThisRow,
                rowZ = -(rowIndex - 1) * 4.0,
                width = 0.0,
                rowXOffset = (rng:valueForUniqueID(tribeID, 3742943 + rowIndex + worldTimeSeed) - 0.5) * (rowIndex - 1)
            })
            totalCount = totalCount + countThisRow
            if totalCount >= sapienCount then
                break
            end
            countThisRow = math.ceil(countThisRow * (1.05 + 0.1 * rng:valueForUniqueID(tribeID, 621664 + rowIndex + worldTimeSeed)))
            countThisRow = math.min(countThisRow, sapienCount - totalCount)
        end
    else
        table.insert(rows, {
            count = sapienCount,
            rowZ = 0.0,
            width = 0.0,
            rowXOffset = 0.0,
        })
    end

    --mj:log("sapienCount:", sapienCount, " rows:", rows)

    local sapienIndex = 1
    local groupIndex = 0
    for rowIndex,rowInfo in ipairs(rows) do
        local groupSize = nil
        local groupSapienIndex = 1
        local groupZOffset = 0
        local groupSitting = false

        local function loadGroup()
            groupIndex = groupIndex + 1
            groupSize = 2 + rng:integerForUniqueID(tribeID, 798993 + worldTimeSeed + rowIndex * 99 + sapienIndex, 4)
            groupSize = math.min(groupSize, rowInfo.count - rowIndex + 1)
            groupSapienIndex = 1
            groupZOffset = (rng:valueForUniqueID(tribeID, 62972 + worldTimeSeed + rowIndex) - 0.5) * 0.8
            groupSitting = (rng:integerForUniqueID(tribeID, 283422 + worldTimeSeed + rowIndex + groupIndex * 87, 2) > 0)
        end

        loadGroup()

        for withinRowIndex=1,rowInfo.count do

            local posInfo = orderedPosInfos[sapienIndex]
            local sapienInfo = posInfo.sapienInfo
            local sapienID = sapienInfo.uniqueID

            local spacingX = 0.6
            local isChild = sapienInfo.sharedState.lifeStageIndex == sapienConstants.lifeStages.child.index
            if isChild then
                spacingX = 0.4
            end
            local additionalSpacingX = (rng:valueForUniqueID(sapienID, 438543 + worldTimeSeed) - 0.5) * 0.5
            spacingX = spacingX + additionalSpacingX * 0.1

            if groupSapienIndex + 1 > groupSize then
                spacingX = spacingX + 1.0
            end

            local yRotation = 0.0--(rng:valueForUniqueID(sapienID, 394355) - 0.5)
            yRotation = yRotation - additionalSpacingX * 2.0

            local prevInfo = orderedPosInfos[sapienIndex - 1]
            if groupSapienIndex > 1 and prevInfo then
                yRotation = yRotation + prevInfo.additionalSpacingX * 2.0
            end

            if groupSize > 1 then
                if groupSapienIndex == 1 then
                    yRotation = yRotation + 0.6
                end

                if groupSapienIndex == groupSize then
                    yRotation = yRotation - 0.6
                end
            end


            --local sitting = false
            local animations = standingAnimations
            if groupSitting or (rowIndex == 1 and (isChild or rng:integerForUniqueID(sapienID, 2347 + worldTimeSeed, 2) == 1)) then
                animations = sittingAnimations
                --sitting = true
            end

            local randomAnimationTypeInfo = animations[rng:integerForUniqueID(sapienID, 53452 + worldTimeSeed, #animations) + 1]
            local zOffset = -rng:valueForUniqueID(sapienID, 43854334 + worldTimeSeed) * 0.1

            --[[if isChild or sitting then
                zOffset = zOffset + 0.2
            end]]

            zOffset = zOffset + math.abs(yRotation * 0.5)
            zOffset = zOffset + groupZOffset

            local rotationFractionAlongRow = (withinRowIndex - 1) / (rowInfo.count - 1)
            local rotationCurvedAlongRow = math.cos(rotationFractionAlongRow * math.pi)
            yRotation = yRotation + rotationCurvedAlongRow
            local offsetCurvedAlongRow = math.cos(rotationFractionAlongRow * math.pi * 2.0) * 0.5 + 0.5
            zOffset = zOffset + offsetCurvedAlongRow * 4.0 - 4.0
            
            posInfo.spacingX = spacingX
            posInfo.additionalSpacingX = additionalSpacingX
            posInfo.zOffset = zOffset + rowInfo.rowZ
            posInfo.randomAnimationFrameOffset = rng:integerForUniqueID(sapienID, 228553 + worldTimeSeed, 99)
            posInfo.yRotation = yRotation
            posInfo.randomAnimationTypeString = randomAnimationTypeInfo.key

            --local animationGroupIndex = sapienConstants:getAnimationGroupKey(sapienInfo.sharedState)

            --mj:log("added sapien additionalSpacingX:", additionalSpacingX, " zOffset:", zOffset, " yRotation:", 
            --yRotation, " isChild:", isChild, " sitting:", sitting, " animation:", randomAnimationTypeInfo.key, " group:", animationGroups.groups[animationGroupIndex].key)

            if withinRowIndex < rowInfo.count then
                rowInfo.width = rowInfo.width + spacingX
            end

            groupSapienIndex = groupSapienIndex + 1
            if groupSapienIndex > groupSize then
                loadGroup()
            end

            sapienIndex = sapienIndex + 1
        end
    end

    
    local xOffset = -rows[1].width * 0.5 + rows[1].rowXOffset
    local thisRowCount = 0
    local rowIndex = 1
    for i,orderedPosInfo in ipairs(orderedPosInfos) do
        thisRowCount = thisRowCount + 1
        if thisRowCount > rows[rowIndex].count then
            rowIndex = rowIndex + 1
            thisRowCount = 1
            xOffset = -rows[rowIndex].width * 0.5 + rows[rowIndex].rowXOffset
        end

        local sapienInfo = orderedPosInfo.sapienInfo
        local animationGroupKey = sapienConstants:getAnimationGroupKey(sapienInfo.sharedState)
        local animationInstance = uiAnimation:getUIAnimationInstance(animationGroupKey, orderedPosInfo.randomAnimationTypeString)
        --mj:log("animationInstance:", animationInstance)
        local gameObjectModelIndex = gameObject:modelIndexForGameObjectAndLevel(sapienInfo, mj.SUBDIVISIONS - 1, nil)
        if gameObjectModelIndex then
            local getNextAnimationFrame = nil
            if animationInstance then
                getNextAnimationFrame = function()
                    return uiAnimation:getNextAnimationFrame(animationInstance, orderedPosInfo.randomAnimationFrameOffset)
                end
            end

            local rotation = mat3Rotate(mat3Identity, orderedPosInfo.yRotation, vec3(0.0,1.0,0.0))
            
            tribeView:addModel(gameObjectModelIndex,
                function (modelIndex, placeholderName)
                    local placeholderInfo = modelPlaceholder:placeholderInfoForModelAndPlaceholderKey(modelIndex, placeholderName)
                    if not placeholderInfo or placeholderInfo.hiddenOnBuildComplete then
                        return nil
                    end
                    return {placeholderInfo.defaultModelIndex, placeholderInfo.scale or 1.0}
                end,
                getNextAnimationFrame,
                animationInstance.modelTypeIndex,
                rotation,
                vec3(xOffset,0.0,orderedPosInfo.zOffset)
            )
        end

       --uiCommon:addGameObjectViewObject(tribeSapiensRenderGameObjectView, sapienInfo, animationInstance, nil, baseOffset)
       xOffset = xOffset + orderedPosInfo.spacingX
    end
end

-- NOTE this is still very specific to its purpose of rendering banners. Will need more work to support other sizes.
function uiTribeView:create(parentView, size)
    local userTable = {
    }

    local tribeGameObjectView = GameObjectView.new(parentView, size)
    tribeGameObjectView.size = size
    tribeGameObjectView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    local camPos = vec3(0.0,1.2,18.0)
    local lookAtPos = (vec3(0.0,1.0,-1.0))
    tribeGameObjectView:setCameraTransformOverride(camPos, lookAtPos)
    tribeGameObjectView:setFOVYDegrees(8.0)
    tribeGameObjectView:setMaskTexture(nil)

    tribeGameObjectView.userData = userTable

    return tribeGameObjectView
end

return uiTribeView