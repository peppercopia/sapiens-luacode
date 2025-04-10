local mjm = mjrequire "common/mjm"
local normalize = mjm.normalize
local dot = mjm.dot
local length = mjm.length
local length2 = mjm.length2
local createUpAlignedRotationMatrix = mjm.createUpAlignedRotationMatrix
--local mat3LookAtInverse = mjm.mat3LookAtInverse
local mat3GetRow = mjm.mat3GetRow
local cross = mjm.cross

local gameObject = mjrequire "common/gameObject"
local order = mjrequire "common/order"
local plan = mjrequire "common/plan"
local resource = mjrequire "common/resource"
local action = mjrequire "common/action"
local worldHelper = mjrequire "common/worldHelper"
local actionSequence = mjrequire "common/actionSequence"
local sapienTrait = mjrequire "common/sapienTrait"
local notification = mjrequire "common/notification"
local need = mjrequire "common/need"
local physicsSets = mjrequire "common/physicsSets"
local statusEffect = mjrequire "common/statusEffect"
local medicine = mjrequire "common/medicine"
local craftAreaGroup = mjrequire "common/craftAreaGroup"
local lookAtIntents = mjrequire "common/lookAtIntents"
local serverLogistics = mjrequire "server/serverLogistics"

local rng = mjrequire "common/randomNumberGenerator"
local skill = mjrequire "common/skill"
local skillLearning = mjrequire "common/skillLearning"
local constructable = mjrequire "common/constructable"
local sapienInventory = mjrequire "common/sapienInventory"
local gameConstants = mjrequire "common/gameConstants"
local sapienConstants = mjrequire "common/sapienConstants"
local desire = mjrequire "common/desire"
--local mood = mjrequire "common/mood"
local tool = mjrequire "common/tool"
local research = mjrequire "common/research"
local objectInventory = mjrequire "common/objectInventory"
local maintenance = mjrequire "common/maintenance"
local rock = mjrequire "common/rock"
local storage = mjrequire "common/storage"
--local harvestable = mjrequire "common/harvestable"
--local typeMaps = mjrequire "common/typeMaps"

local terrain = mjrequire "server/serverTerrain"
local serverStorageArea = mjrequire "server/serverStorageArea"
local serverCraftArea = mjrequire "server/serverCraftArea"
local serverResourceManager = mjrequire "server/serverResourceManager"
local planManager = mjrequire "server/planManager"
local serverSapienSkills = mjrequire "server/serverSapienSkills"
local serverCampfire = mjrequire "server/objects/serverCampfire"
local serverKiln = mjrequire "server/objects/serverKiln"
local serverTorch = mjrequire "server/objects/serverTorch"
local serverFlora = mjrequire "server/objects/serverFlora"
local serverLitObject = mjrequire "server/objects/serverLitObject"
local serverMob = mjrequire "server/objects/serverMob"
local serverSapienInventory = mjrequire "server/serverSapienInventory"
local findOrderAI = mjrequire "server/sapienAI/findOrderAI"
local serverTutorialState = mjrequire "server/serverTutorialState"
local serverStatusEffects = mjrequire "server/serverStatusEffects"
local serverCompostBin = mjrequire "server/objects/serverCompostBin"
local serverFuel = mjrequire "server/serverFuel"
local serverTribe = mjrequire "server/serverTribe"
local serverTribeAIPlayer = mjrequire "server/serverTribeAIPlayer"
local startOrderAI = mjrequire "server/sapienAI/startOrderAI"
local serverSeat = mjrequire "server/objects/serverSeat"
--local conversation = mjrequire "server/sapienAI/conversation"
local social = mjrequire "common/social"
--local pathCreator = mjrequire "server/pathCreator"

local multitask = mjrequire "server/sapienAI/multitask"


local serverSapienAI = nil
local serverSapien = nil
local serverGOM = nil
local serverWorld = nil
--local findOrderAI = nil

local activeOrderAI = {}

local debugAnimations = false

local function checkForReserachNearlyComplete(sapien, researchTypeIndex, checkDelay)

    local skillIncrease = checkDelay
    --[[local researchType = research.types[researchTypeIndex]
    if researchType.initialResearchSpeedLearnMultiplier then
        skillIncrease = skillIncrease * researchType.initialResearchSpeedLearnMultiplier
    end]]

    if serverSapienSkills:willHaveResearch(sapien, researchTypeIndex, nil, math.max(skillIncrease, 20.0)) then
        local clientID = serverWorld:clientIDForTribeID(sapien.sharedState.tribeID)
        local clientTransientState = serverWorld:getClientTransientState(clientID)
        if clientTransientState then
            if not clientTransientState.sentResearchNotifcations then
                clientTransientState.sentResearchNotifcations = {}
            end
            if not clientTransientState.sentResearchNotifcations[researchTypeIndex] then
                clientTransientState.sentResearchNotifcations[researchTypeIndex] = true 
                if not serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, researchTypeIndex) then
                    serverGOM:sendNotificationForObject(sapien, notification.types.researchNearlyDone.index, nil, sapien.sharedState.tribeID)
                end
            end
        end
    end
end

local function getAfterActionDelayForConstructable(sapien, orderObject, taughtSkillTypeIndex)
    local planState = planManager:getPlanSateForConstructionObject(orderObject, sapien.sharedState.tribeID)
    local moveInfo = serverGOM:getNextMoveInfoForBuildOrCraftObject(orderObject, planState)
    if moveInfo and moveInfo.resourceInfo then
        local afterAction = moveInfo.resourceInfo.afterAction
        if afterAction then
            if not skill:hasSkill(sapien, taughtSkillTypeIndex) then
                if afterAction.durationWithoutSkill then
                    return afterAction.durationWithoutSkill
                end
            end
            if afterAction.duration then
                return afterAction.duration
            end
        end
    end
    return 0.0
end

local function getPlanOrderIndexAndPriority(tribeID, orderObject, orderState)
    if orderObject and orderObject.sharedState and orderObject.sharedState.planStates then
        local planStatesForTribe = orderObject.sharedState.planStates[tribeID]
        if planStatesForTribe then
            for i,planState in ipairs(planStatesForTribe) do
                if orderState.context.planTypeIndex == planState.planTypeIndex then
                    return {
                        planOrderIndex = planState.planOrderIndex or planState.planID,
                        planPriorityOffset = planState.priorityOffset,
                        manuallyPrioritized = planState.manuallyPrioritized,
                        supressStoreOrders = planState.supressStoreOrders,
                    }
                end
            end
        end
    end
    return {}
end

local function getPlanOrderIndexAndPriorityForVert(tribeID, vertID, orderState)
    local planState = planManager:getPlanStateForVertForTerrainModification(vertID, orderState.context.planTypeIndex, tribeID, nil)
    if planState then
        return {
            planOrderIndex = planState.planOrderIndex or planState.planID,
            planPriorityOffset = planState.priorityOffset,
            manuallyPrioritized = planState.manuallyPrioritized,
        }
    end
    return {}
end

local function constructionCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)

    
    --[[local buildSequenceIndex = orderObject.sharedState.buildSequenceIndex or 1
    local currentBuildSequenceInfo = constructableType.buildSequence[buildSequenceIndex]
    if currentBuildSequenceInfo then
        if currentBuildSequenceInfo.constructableSequenceTypeIndex == constructable.sequenceTypes.actionSequence.index then
            --privateState.actionStateTimer

        end
    end]]

    if allowCompletion then
        --mj:log(debug.traceback())
        --mj:log("orderObject sharedstate:", orderObject.sharedState)
        local planState = planManager:getPlanSateForConstructionObject(orderObject, sapien.sharedState.tribeID)
       -- mj:log("planState:", planState)
        
        if (not planState) or (planState.planTypeIndex ~= plan.types.deconstruct.index and planState.planTypeIndex ~= plan.types.rebuild.index) then
            local skipRepeatsDueToSkillCompletion = false
            if orderState.context and orderState.context.researchTypeIndex then
                skipRepeatsDueToSkillCompletion = true
            end
            if planState then
                serverGOM:incrementBuildSequence(orderObject, sapien, planState, constructableType, skipRepeatsDueToSkillCompletion)
            end
        end

        
        --[[if complete and orderState.context.researchTypeIndex then
            serverSapienSkills:completeResearchImmediately(sapien, orderState.context.researchTypeIndex, orderState.context.discoveryCraftableTypeIndex or constructableType.index)
        end]]
    end
end

local function checkForFoodPoisoning(sapien, eatenResourceTypeIndex, contaminationResourceTypeIndexOrNil)
    local foodPoisoningChance = resource.types[contaminationResourceTypeIndexOrNil or eatenResourceTypeIndex].foodPoisoningChance
    if foodPoisoningChance then
        local traitImmunity = sapienTrait:getInfluence(sapien.sharedState.traits, sapienTrait.influenceTypes.immunity.index)
        if (traitImmunity < 0.5) then -- if strong immunity, then never gets it
            
            if contaminationResourceTypeIndexOrNil then
                foodPoisoningChance = foodPoisoningChance * 0.125
            end
            if traitImmunity > -0.5 then -- if weak immunity
                foodPoisoningChance = foodPoisoningChance * 4.0
            end
            
            local randomChance = 0
            randomChance = rng:randomInteger(math.floor(20 / mjm.clamp(foodPoisoningChance, 0.00001,1.0)))

            --mj:log("check for food poisoning:", sapien.uniqueID, " chance:", randomChance, " foodPoisoningChance:", foodPoisoningChance)
            if randomChance < 20 and 
            (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.foodPoisoningImmunity.index)) and
            (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.minorFoodPoisoning.index)) and 
            (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.majorFoodPoisoning.index)) and
            (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.criticalFoodPoisoning.index)) then
                serverStatusEffects:setTimedEffect(sapien.sharedState, statusEffect.types.minorFoodPoisoning.index, sapienConstants.foodPoisoningDuration)
                serverGOM:sendNotificationForObject(sapien, notification.types.minorFoodPoisoning.index, {
                    eatenResourceTypeIndex = eatenResourceTypeIndex,
                    contaminationResourceTypeIndex = contaminationResourceTypeIndexOrNil,
                }, sapien.sharedState.tribeID)
                planManager:addStandardPlan(sapien.sharedState.tribeID, plan.types.treatFoodPoisoning.index, sapien.uniqueID, nil, nil, nil, nil, nil, nil)
                if contaminationResourceTypeIndexOrNil then
                    serverTutorialState:sapienGotFoodPoisoningDueToContamination(sapien.sharedState.tribeID)
                end
            end
        end
    end
end

local function checkForBurn(sapien, craftingConstructableTypeIndexOrNil, researchingAtObjectTypeIndexOrNil, deliveringToObjectTypeIndexOrNil, riskMultiplier, allowMajorBurns)
    local randomChance = rng:randomInteger(math.floor(20 / mjm.clamp(riskMultiplier * sapienConstants.burnRiskMultiplier, 0.000001,1.0)))
    --mj:log("randomChance:", randomChance)
    if randomChance <= 20 and 
    (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.minorBurn.index)) and 
    (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.majorBurn.index)) and
    (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.criticalBurn.index)) then
        if randomChance < 12 then
            serverStatusEffects:setTimedEffect(sapien.sharedState, statusEffect.types.minorBurn.index, sapienConstants.burnDuration)
            serverGOM:sendNotificationForObject(sapien, notification.types.minorBurn.index, {
                craftingConstructableTypeIndex = craftingConstructableTypeIndexOrNil,
                researchingAtObjectTypeIndex = researchingAtObjectTypeIndexOrNil,
                deliveringToObjectTypeIndex = deliveringToObjectTypeIndexOrNil,
            }, sapien.sharedState.tribeID)
            planManager:addStandardPlan(sapien.sharedState.tribeID, plan.types.treatBurn.index, sapien.uniqueID, nil, nil, nil, nil, nil, nil)
            local interactionInfo = social:getExclamation(sapien, social.interactions.ouchMinor.index, nil)
            if interactionInfo then
                serverGOM:sendNotificationForObject(sapien, notification.types.social.index, interactionInfo, sapien.sharedState.tribeID)
            end
        elseif allowMajorBurns then
            if randomChance < 18 then
                serverStatusEffects:setTimedEffect(sapien.sharedState, statusEffect.types.majorBurn.index, sapienConstants.burnDuration)
                serverGOM:sendNotificationForObject(sapien, notification.types.majorBurn.index, {
                    craftingConstructableTypeIndex = craftingConstructableTypeIndexOrNil,
                    researchingAtObjectTypeIndex = researchingAtObjectTypeIndexOrNil,
                    deliveringToObjectTypeIndex = deliveringToObjectTypeIndexOrNil,
                }, sapien.sharedState.tribeID)
                local interactionInfo = social:getExclamation(sapien, social.interactions.ouchMajor.index, nil)
                if interactionInfo then
                    serverGOM:sendNotificationForObject(sapien, notification.types.social.index, interactionInfo, sapien.sharedState.tribeID)
                end
            else
                serverStatusEffects:setTimedEffect(sapien.sharedState, statusEffect.types.criticalBurn.index, sapienConstants.burnDuration)
                serverStatusEffects:setTimedEffect(sapien.sharedState, statusEffect.types.unconscious.index, 10.0)
                serverGOM:sendNotificationForObject(sapien, notification.types.criticalBurn.index, {
                    craftingConstructableTypeIndex = craftingConstructableTypeIndexOrNil,
                    researchingAtObjectTypeIndex = researchingAtObjectTypeIndexOrNil,
                    deliveringToObjectTypeIndex = deliveringToObjectTypeIndexOrNil,
                }, sapien.sharedState.tribeID)
                local interactionInfo = social:getExclamation(sapien, social.interactions.ouchCritical.index, nil)
                if interactionInfo then
                    serverGOM:sendNotificationForObject(sapien, notification.types.social.index, interactionInfo, sapien.sharedState.tribeID)
                end
            end
            planManager:addStandardPlan(sapien.sharedState.tribeID, plan.types.treatBurn.index, sapien.uniqueID, nil, nil, nil, nil, nil, nil)
        end
    end
end


local function checkForInjury(sapien, riskMultiplier) -- riskMultiplier is 0-1 fraction. 1=always, 0.5=50% chance
    local randomChance = rng:randomInteger(math.floor(20 / mjm.clamp(riskMultiplier, 0.000001,1.0)))
    --mj:log("randomChance:", randomChance)
    if randomChance < 20 and 
    (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.minorInjury.index)) and 
    (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.majorInjury.index)) and
    (not statusEffect:hasEffect(sapien.sharedState, statusEffect.types.criticalInjury.index)) then
        serverStatusEffects:setTimedEffect(sapien.sharedState, statusEffect.types.minorInjury.index, sapienConstants.injuryDuration)
        planManager:addStandardPlan(sapien.sharedState.tribeID, plan.types.treatInjury.index, sapien.uniqueID, nil, nil, nil, nil, nil, nil)
        serverGOM:sendNotificationForObject(sapien, notification.types.minorInjury.index, serverSapien:getOrderStatusUserDataForNotification(sapien), sapien.sharedState.tribeID)
        local interactionInfo = social:getExclamation(sapien, social.interactions.ouchMinor.index, nil)
        if interactionInfo then
            serverGOM:sendNotificationForObject(sapien, notification.types.social.index, interactionInfo, sapien.sharedState.tribeID)
        end
    end
end

local function fireStickCookOrSmeltMetalCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)

    local riskMultiplier = 0.01
    local allowMajorBurns = true
    if orderObject and gameObject.types[orderObject.objectTypeIndex].craftAreaGroupTypeIndex == craftAreaGroup.types.campfire.index then
        riskMultiplier = riskMultiplier * 0.25
        allowMajorBurns = false
    end

    local researchTypeIndex = nil
    if orderState.context then 
        researchTypeIndex = orderState.context.researchTypeIndex
    end

    if not requiredLearnComplete then
        if (not researchTypeIndex) then -- a bit harsh to get burned while researching too much
            riskMultiplier = riskMultiplier * 4.0
        end
    end

    local constructableTypeIndex = nil
    if constructableType then
        constructableTypeIndex = constructableType.index
    end
    local researchingAtObjectTypeIndex = nil
    if researchTypeIndex then
        constructableTypeIndex = nil
        researchingAtObjectTypeIndex = orderObject.objectTypeIndex
    end

    checkForBurn(sapien, constructableTypeIndex, researchingAtObjectTypeIndex, nil, riskMultiplier, allowMajorBurns)
    
    constructionCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
end

local function placeCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
    --disabled--mj:objectLog(sapien.uniqueID, "placeCompletionFunction")
    while sapienInventory:objectCount(sapien, sapienInventory.locations.held.index) > 0 do
        local objectInfo = serverSapienInventory:removeObject(sapien, sapienInventory.locations.held.index)
        if objectInfo then
            local orderTypeIndex = orderState.orderTypeIndex
            local shouldDrop = false
            if orderTypeIndex == order.types.deliverObjectToConstructionObject.index then
                --disabled--mj:objectLog(sapien.uniqueID, "orderTypeIndex == order.types.deliverObjectToConstructionObject.index")
                local objectInfoForAdditionToInventory = serverGOM:stripObjectInfoForAdditionToInventory(objectInfo)
                if serverGOM:addConstructionObjectComponent(orderObject, objectInfoForAdditionToInventory, sapien.sharedState.tribeID) then
                    serverTribeAIPlayer:addGrievanceIfNeededForObjectBeingBuilt(orderObject.pos, sapien.sharedState.tribeID, orderObject.objectTypeIndex)
                else
                    --disabled--mj:objectLog(sapien.uniqueID, "shouldDrop = true")
                    shouldDrop = true
                end
            elseif orderTypeIndex == order.types.deliverObjectToStorage.index or 
            orderTypeIndex == order.types.deliverObjectTransfer.index then

                --disabled--mj:objectLog(sapien.uniqueID, "orderTypeIndex == order.types.deliverObjectToStorage.index or orderTypeIndex == order.types.deliverObjectTransfer.index objectInfo:", objectInfo)

                local sapienLogisticsInfo = sapien.privateState.logisticsInfo
                if sapienLogisticsInfo then
                    if objectInfo.orderContext then
                        local heldObjectStorageAreaTransferInfo = objectInfo.orderContext.storageAreaTransferInfo
                        if heldObjectStorageAreaTransferInfo and heldObjectStorageAreaTransferInfo.routeID == sapienLogisticsInfo.routeID then
                            serverTutorialState:objectWasDeliveredForTransferRoute(sapien.sharedState.tribeID)
                        end
                    end
                end
                
                local objectInfoForAdditionToInventory = serverGOM:stripObjectInfoForAdditionToInventory(objectInfo)
                if not serverStorageArea:addObjectToStorageArea(orderObject.uniqueID, objectInfoForAdditionToInventory, sapien.sharedState.tribeID) then
                    shouldDrop = true
                end
            elseif orderTypeIndex == order.types.deliverPlanObjectForCraftingOrResearchElsewhere.index then
                if orderObject then
                    if orderObject.objectTypeIndex == gameObject.types.terrainModificationProxy.index then
                        terrain:startPlanWithDeliveredPlanObject(orderObject, objectInfo, sapien)
                    else
                        local orderObjectGameObjectType = gameObject.types[orderObject.objectTypeIndex]
                        local isCraftArea = orderObjectGameObjectType.isCraftArea
                        if isCraftArea then
                            serverCraftArea:startCraftWithDeliveredPlanObject(orderObject, objectInfo, sapien)
                        else
                            shouldDrop = true
                        end
                    end
                else
                    shouldDrop = true
                end
            elseif orderTypeIndex == order.types.deliverFuel.index then
                if not serverFuel:addFuel(orderObject, objectInfo, sapien.sharedState.tribeID) then
                    shouldDrop = true
                else
                    if orderObject.sharedState.isLit then
                        checkForBurn(sapien, nil, nil, orderObject.objectTypeIndex, 0.01, false)
                    end
                end
            elseif orderTypeIndex == order.types.deliverToCompost.index then
                local objectInfoForAdditionToInventory = serverGOM:stripObjectInfoForAdditionToInventory(objectInfo)
                if not serverCompostBin:deliverToCompost(orderObject, objectInfoForAdditionToInventory, sapien.sharedState.tribeID) then
                    shouldDrop = true
                end
            else --dispose or drop
                shouldDrop = true
            end

            
            if orderObject then
                local cooldowns = serverSapienAI.aiStates[sapien.uniqueID].cooldowns
                if cooldowns then
                    cooldowns["plan_" .. orderObject.uniqueID] = nil
                    cooldowns["m_" .. orderObject.uniqueID] = nil
                    ----disabled--mj:objectLog(sapien.uniqueID, "removed cooldown. cooldowns:", cooldowns)
                end
            end

            if shouldDrop then
                --disabled--mj:objectLog(sapien.uniqueID, "dropping")
                local dropPosNormal = nil
                
                if actionState.path then
                    local pathRoute = actionState.path.nodes
                    dropPosNormal = normalize(pathRoute[actionState.pathNodeIndex].pos)
                else
                    local offsetPos = sapien.pos + mat3GetRow(sapien.rotation, 2) * mj:mToP(0.1)
                    dropPosNormal = normalize(offsetPos)
                end

                local sapienPosLength = length(sapien.pos)
                local clampToSeaLevel = true
                local shiftedPos = worldHelper:getBelowSurfacePos(dropPosNormal * sapienPosLength, 1.0, physicsSets.walkable, nil, clampToSeaLevel)
                local shiftedPosLength = length(shiftedPos)
                local finalDropPos = dropPosNormal * (shiftedPosLength + mj:mToP(1.0))

                serverGOM:dropObject(objectInfo, finalDropPos, sapien.sharedState.tribeID, true)
                break
            end
        else
            break
        end
    end
end

local function takeOffClothingCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
    if orderState.context and orderState.context.inventoryLocation then
        local objectInfo = serverSapienInventory:removeObject(sapien, orderState.context.inventoryLocation)
        serverSapien:updateTemperature(sapien)
        serverGOM:sendNotificationForObject(sapien, notification.types.reloadModel.index, nil, sapien.sharedState.tribeID)
        if objectInfo then
            -- local lastHeldObjectInfo = sapienInventory:lastObjectInfo(sapien, sapienInventory.locations.held.index)
            -- if lastHeldObjectInfo then
                -- --disabled--mj:objectLog(sapien.uniqueID, "dropping take-off object as already holding something")
                local dropPosNormal = nil
                
                if actionState.path then
                    local pathRoute = actionState.path.nodes
                    dropPosNormal = normalize(pathRoute[actionState.pathNodeIndex].pos)
                else
                    local offsetPos = sapien.pos + mat3GetRow(sapien.rotation, 2) * mj:mToP(0.1)
                    dropPosNormal = normalize(offsetPos)
                end

                local sapienPosLength = length(sapien.pos)
                local clampToSeaLevel = true
                local shiftedPos = worldHelper:getBelowSurfacePos(dropPosNormal * sapienPosLength, 1.0, physicsSets.walkable, nil, clampToSeaLevel)
                local shiftedPosLength = length(shiftedPos)
                local finalDropPos = dropPosNormal * (shiftedPosLength + mj:mToP(1.0))

                serverGOM:dropObject(objectInfo, finalDropPos, sapien.sharedState.tribeID, true)
            -- else
            --     serverSapienInventory:addObjectFromInventory(sapien, objectInfo, sapienInventory.locations.held.index, nil)
            -- end
        end
    end
end

local function putOnClothingCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
    if orderState.context and orderState.context.inventoryLocation then
        local objectInfo = serverSapienInventory:removeObject(sapien, sapienInventory.locations.held.index)
        if objectInfo then
            local lastCurrentlyWornObjectInfo = sapienInventory:lastObjectInfo(sapien, orderState.context.inventoryLocation)
            if not lastCurrentlyWornObjectInfo then
                serverSapienInventory:addObjectFromInventory(sapien, objectInfo, orderState.context.inventoryLocation, nil)
                serverSapien:updateTemperature(sapien)
                serverGOM:sendNotificationForObject(sapien, notification.types.reloadModel.index, nil, sapien.sharedState.tribeID)
            end
        end
    end
end

local function throwProjectileCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
    if sapienInventory:objectCount(sapien, sapienInventory.locations.held.index) > 0 then
        local objectInfo = serverSapienInventory:removeObject(sapien, sapienInventory.locations.held.index)
        if objectInfo then
            local normalizedSapienPos = normalize(sapien.pos)
            local sapienEyePos = (sapien.pos + normalizedSapienPos * mj:mToP(1.5))
            
            local approximateHandOffset = mjm.vec3xMat3(mjm.vec3(mj:mToP(-0.5),0.0,0.0), mjm.mat3Inverse(sapien.rotation))
            local throwStartPos = sapienEyePos + approximateHandOffset

            local projectileAimHeightOffsetMeters = gameObject.types[orderObject.objectTypeIndex].projectileAimHeightOffsetMeters or 0.5

            local goalPos = orderObject.pos + normalize(orderObject.pos) * mj:mToP(projectileAimHeightOffsetMeters)

            if not allowCompletion then
                local throwDir = goalPos - throwStartPos
                local throwDistance = length(throwDir)
                local throwDistanceNormal = throwDir / throwDistance
                local perpVec = normalize(cross(normalize(goalPos), throwDistanceNormal))
                local missPos = goalPos + throwDistanceNormal * rng:randomValue() * throwDistance * 0.5
                local rightLeftMissDistance = (rng:randomValue() - 0.5)
                if rightLeftMissDistance > 0 then
                    rightLeftMissDistance = rightLeftMissDistance + 0.2
                else
                    rightLeftMissDistance = rightLeftMissDistance - 0.2
                end
                rightLeftMissDistance = rightLeftMissDistance * throwDistance * 0.5
                missPos = missPos + perpVec * rightLeftMissDistance
                local clampToSeaLevel = true
                missPos = worldHelper:getBelowSurfacePos(missPos, 0.3, physicsSets.walkable, nil, clampToSeaLevel)
                goalPos = missPos
            end

            
            local throwVelocityMeters = 15.0
            local heldObjectType = gameObject.types[objectInfo.objectTypeIndex]
            local toolUsages = heldObjectType.toolUsages
            if toolUsages then
                if toolUsages[tool.types.weaponSpear.index] then
                    throwVelocityMeters = 25.0
                end
            end
            
            sapien.sharedState:set("orderQueue", 1, "context", "throwStartPos", throwStartPos)
            sapien.sharedState:set("orderQueue", 1, "context", "throwEndPos", goalPos) 
            sapien.sharedState:set("orderQueue", 1, "context", "throwVelocity", mj:mToP(throwVelocityMeters))
            
            -- mj:log("throwStartPos - sapien.pos: ", mj:pToM(length(orderState.context.throwStartPos - sapien.pos)))
            -- mj:log("altitude orderObject.pos - sapien.pos: ", mj:pToM(length(orderObject.pos) - length(sapien.pos)))
            -- mj:log("altitude orderObject.pos:", mj:pToM(length(orderObject.pos) - 1.0))
            -- local terrainheight = terrain:getLoadedTerrainPointAtPoint(orderObject.pos)
            -- mj:log("orderObject.pos altitude offsetFromTerrain:", mj:pToM(length(orderObject.pos) - length(terrainheight)))

            local thrownObjectID = serverGOM:throwObjectAtGoal(objectInfo, orderState.context.throwStartPos, goalPos, orderState.context.throwVelocity)
            local directionVec = goalPos - orderState.context.throwStartPos
            local directionLength = length(directionVec)

            local unsavedState = serverGOM:getUnsavedPrivateState(sapien)
            unsavedState.preventUnnecessaryAutomaticOrderTimer = math.max(unsavedState.preventUnnecessaryAutomaticOrderTimer or 0.0, 2.0)

            if allowCompletion then
                serverMob:projectileHit(orderObject, thrownObjectID, sapien.uniqueID, directionLength / orderState.context.throwVelocity, (directionVec / directionLength), orderState.context.throwVelocity, sapien.sharedState.tribeID)
            else
                serverGOM:projectileMiss(thrownObjectID, sapien.uniqueID, orderObject.uniqueID, sapien.sharedState.tribeID, directionLength / orderState.context.throwVelocity, (directionVec / directionLength), orderState.context.throwVelocity, goalPos)
            end

            local researchTypeIndex = orderState.context.researchTypeIndex
            if researchTypeIndex then
                if orderState.context.researchTypeIndex and serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, orderState.context.researchTypeIndex) then
                    --mj:log("serverWorld:discoveryIsCompleteForTribe so removing hunt research plan state")
                    planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sapien.sharedState.tribeID)
                    serverGOM:removeTemporaryGameObjectForOrderCompleteIfNeeded(orderObject)
                    if serverGOM:getObjectWithID(orderObject.uniqueID) then
                        planManager:addPlanToObject(orderObject, sapien.sharedState.tribeID, plan.types.hunt.index, nil,nil,nil,nil,nil,nil,nil,nil)
                    end
                end
            end
        end
    end
end

local function applyMedicine(applyToSapien, objectTypeIndex)
    local resourceTypeIndex = gameObject.types[objectTypeIndex].resourceTypeIndex
    local appliedMedicineType = nil
    
   -- mj:log("applyMedicine a")
    local statusEffects = applyToSapien.sharedState.statusEffects
    for statusEffectTypeIndex, statusEffectInfo in pairs(statusEffects) do
        local statusEffectType = statusEffect.types[statusEffectTypeIndex]
        --mj:log("applyMedicine b:", statusEffectType)
        if statusEffectType.requiredMedicineTypeIndex then
            local medicineType = medicine.types[statusEffectType.requiredMedicineTypeIndex]
            --mj:log("applyMedicine c")
            if resource:groupOrResourceMatchesResource(medicineType.medicineResource, resourceTypeIndex) then
                --mj:log("applyMedicine d:", medicineType.treatmentStatusEffect)
                appliedMedicineType = medicineType
                serverStatusEffects:addEffect(applyToSapien.sharedState, medicineType.treatmentStatusEffect)
            end
        end
    end
    return appliedMedicineType
end

local function selfApplyMedicineCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
    if allowCompletion then
        local objectInfo = serverSapienInventory:removeObject(sapien, sapienInventory.locations.held.index)
        if objectInfo then
            local appliedMedicineType = applyMedicine(sapien, objectInfo.objectTypeIndex)
            
            local gameObjectType = gameObject.types[objectInfo.objectTypeIndex]
            if gameObjectType.usageByProducts then
                local lastOutputID = nil
                for i, byProductObjectTypeIndex in ipairs(gameObjectType.usageByProducts) do
                    lastOutputID = serverGOM:createOutput(sapien.pos, 1.0, byProductObjectTypeIndex, nil, sapien.sharedState.tribeID, plan.types.storeObject.index, getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState))
                end
                if lastOutputID then
                    local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                    if lastOutputObject then
                        serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                    end
                end
            end

            if appliedMedicineType then
                planManager:removePlanStateForObject(sapien, appliedMedicineType.treatmentPlanTypeIndex, nil, nil, sapien.sharedState.tribeID)
            end
        end
    end
end

local function otherApplyMedicineCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
    if allowCompletion then
        local objectInfo = serverSapienInventory:removeObject(sapien, sapienInventory.locations.held.index)
        if objectInfo then
            --mj:log("otherApplyMedicineCompletionFunction objectInfo:", objectInfo, " orderObject:", orderObject.uniqueID)
            local appliedMedicineType = applyMedicine(orderObject, objectInfo.objectTypeIndex)
            
            local gameObjectType = gameObject.types[objectInfo.objectTypeIndex]
            if gameObjectType.usageByProducts then
                local lastOutputID = nil
                for i, byProductObjectTypeIndex in ipairs(gameObjectType.usageByProducts) do
                    lastOutputID = serverGOM:createOutput(sapien.pos, 1.0, byProductObjectTypeIndex, nil, sapien.sharedState.tribeID, plan.types.storeObject.index, getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState))
                end
                if lastOutputID then
                    local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                    if lastOutputObject then
                        serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                    end
                end
            end
            if appliedMedicineType then
                planManager:removePlanStateForObject(orderObject, appliedMedicineType.treatmentPlanTypeIndex, nil, nil, sapien.sharedState.tribeID)
            end
        end
    end
end

local craftCheckFrequency = 4.0
local standardCheckFrequency = 12.0

activeOrderAI.updateInfos = {
    [action.types.place.index] = {
        checkFrequency = 0.35,
        addToSkillOverrideFunction = function(sapien, taughtSkillTypeIndex, researchTypeIndex, skillSpeedMultiplier, orderState, learningInfo)
            return 5.0 * skillSpeedMultiplier
        end,
        completionFunction = placeCompletionFunction,
    },
    [action.types.placeMultiFromHeld.index] = {
        checkFrequency = 0.15,
        addToSkillOverrideFunction = function(sapien, taughtSkillTypeIndex, researchTypeIndex, skillSpeedMultiplier, orderState, learningInfo)
            return 5.0 * skillSpeedMultiplier
        end,
        completionFunction = placeCompletionFunction,
    },
    [action.types.takeOffTorsoClothing.index] = {
        checkFrequency = 0.5,
        completionFunction = takeOffClothingCompletionFunction,
    },
    [action.types.putOnTorsoClothing.index] = {
        checkFrequency = 0.5,
        completionFunction = putOnClothingCompletionFunction,
    },
    [action.types.selfApplyTopicalMedicine.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = selfApplyMedicineCompletionFunction,
        defaultSkillIndex = skill.types.medicine.index,
        allowCompletionWithoutSkill = true,
        unskilledSpeedMultipler = 0.25,
    },
    [action.types.selfApplyOralMedicine.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = selfApplyMedicineCompletionFunction,
        defaultSkillIndex = skill.types.medicine.index,
        allowCompletionWithoutSkill = true,
        unskilledSpeedMultipler = 0.25,
    },
    [action.types.otherApplyTopicalMedicine.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = otherApplyMedicineCompletionFunction,
        defaultSkillIndex = skill.types.medicine.index,
        allowCompletionWithoutSkill = true,
        unskilledSpeedMultipler = 0.25,
    },
    [action.types.otherApplyOralMedicine.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = otherApplyMedicineCompletionFunction,
        defaultSkillIndex = skill.types.medicine.index,
        allowCompletionWithoutSkill = true,
        unskilledSpeedMultipler = 0.25,
    },
    [action.types.throwProjectile.index] = {
        checkFrequency = 0.35,
        completionInjuryRisk = 0.1,
        addToSkillOverrideFunction = function(sapien, taughtSkillTypeIndex, researchTypeIndex, skillSpeedMultiplier, orderState, learningInfo)
            --mj:log("in throwProjectile skill override function.")
            local baseIncrease = 10.0
            if learningInfo and learningInfo.baseIncrease then
                baseIncrease = learningInfo.baseIncrease
                --mj:log("learningInfo.baseIncrease:", learningInfo.baseIncrease)
            end
            --mj:log("baseIncrease:", baseIncrease, " skillSpeedMultiplier:", skillSpeedMultiplier)
            return baseIncrease * skillSpeedMultiplier
        end,
        completionFunction = throwProjectileCompletionFunction
    },
    [action.types.knap.index] = {
        checkFrequency = craftCheckFrequency,
        toolMultiplierTypeIndex = tool.types.knapping.index,
        completionFunction = constructionCompletionFunction,
    },
    [action.types.knapCrude.index] = {
        checkFrequency = craftCheckFrequency,
        toolMultiplierTypeIndex = tool.types.knappingCrude.index,
        completionFunction = constructionCompletionFunction,
    },
    [action.types.grind.index] = {
        checkFrequency = craftCheckFrequency,
        toolMultiplierTypeIndex = tool.types.grinding.index,
        completionFunction = constructionCompletionFunction,
    },
    [action.types.potteryCraft.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = constructionCompletionFunction
    },
    [action.types.smithHammer.index] = {
        checkFrequency = craftCheckFrequency,
        toolMultiplierTypeIndex = tool.types.hammering.index,
        completionFunction = constructionCompletionFunction
    },
    [action.types.toolAssembly.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = constructionCompletionFunction,
    },
    [action.types.spinCraft.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = constructionCompletionFunction
    },
    [action.types.thresh.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = constructionCompletionFunction,
    },
    [action.types.scrapeWood.index] = {
        checkFrequency = craftCheckFrequency,
        toolMultiplierTypeIndex = tool.types.carving.index,
        completionFunction = constructionCompletionFunction,
    },
    [action.types.butcher.index] = {
        defaultSkillIndex = skill.types.butchery.index,
        checkFrequency = craftCheckFrequency,
        toolMultiplierTypeIndex = tool.types.butcher.index,
        completionFunction  = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if constructableType then
                constructionCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            else
                if allowCompletion then
                    local orderObjectID = orderObject.uniqueID
                    local existingPlanContext = getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState)
                    serverGOM:removeFromHarvestingObject(orderObject, sapien, sapien.sharedState.tribeID, existingPlanContext.planOrderIndex, existingPlanContext.planPriorityOffset, existingPlanContext.manuallyPrioritized, gameObject.types[orderObject.objectTypeIndex].harvestableTypeIndex)
                    local researchTypeIndex = orderState.context.researchTypeIndex
                    if researchTypeIndex then
                        if orderState.context.researchTypeIndex and serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, orderState.context.researchTypeIndex) then
                            local objectReloaded = serverGOM:getObjectWithID(orderObjectID) --may have been removed with removeFromHarvestingObject
                            if objectReloaded then
                                planManager:removePlanStateForObject(objectReloaded, orderState.context.planTypeIndex, nil, nil, sapien.sharedState.tribeID)
                                serverGOM:removeTemporaryGameObjectForOrderCompleteIfNeeded(objectReloaded)
                                if serverGOM:getObjectWithID(orderObjectID) then
                                    planManager:addPlanToObject(objectReloaded, sapien.sharedState.tribeID, plan.types.butcher.index, nil,nil,nil,nil,nil,nil,nil,nil)
                                end
                            end
                        end
                    end
                end
            end
        end,
    },
    [action.types.fireStickCook.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = fireStickCookOrSmeltMetalCompletionFunction,
    },
    [action.types.smeltMetal.index] = {
        checkFrequency = craftCheckFrequency,
        toolMultiplierTypeIndex = tool.types.crucible.index,
        completionFunction = fireStickCookOrSmeltMetalCompletionFunction,
    },
    [action.types.patDown.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = constructionCompletionFunction
    },
    [action.types.inspect.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = constructionCompletionFunction
    },
    [action.types.light.index] = {
        --defaultSkillIndex = skill.types.fireLighting.index,
        checkFrequency = craftCheckFrequency,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if allowCompletion then

                planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, nil)

                
                if orderObject.objectTypeIndex == gameObject.types.campfire.index then
                    serverCampfire:setLit(orderObject, true, sapien.sharedState.tribeID)
                elseif orderObject.objectTypeIndex == gameObject.types.brickKiln.index then
                    serverKiln:setLit(orderObject, true, sapien.sharedState.tribeID)
                elseif orderObject.objectTypeIndex == gameObject.types.torch.index then
                    serverTorch:setLit(orderObject, true, sapien.sharedState.tribeID)
                else
                    if gameObject.types[orderObject.objectTypeIndex].resourceTypeIndex == resource.types.branch.index then
                        serverGOM:changeObjectType(orderObject.uniqueID, gameObject.types.burntBranch.index, false)
                        planManager:removeAllPlanStatesForObject(orderObject, orderObject.sharedState, nil)
                    end

                    serverLitObject:setLit(orderObject, true)
                end

                
                serverGOM:sendNotificationForObject(sapien, notification.types.fireLit.index, {
                    pos = orderObject.pos
                }, sapien.sharedState.tribeID)

                local interactionInfo = social:getExclamation(sapien, social.interactions.fireLit.index, nil)
                if interactionInfo then
                    serverGOM:sendNotificationForObject(sapien, notification.types.social.index, interactionInfo, sapien.sharedState.tribeID)
                end
            end
        end
    },
    [action.types.chop.index] = {
        defaultSkillIndex = skill.types.treeFelling.index,
        checkFrequency = standardCheckFrequency,
        toolMultiplierTypeIndex = tool.types.treeChop.index,
        injuryRisk = 1.0,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if allowCompletion then
                local addStoreOrders = true
                serverGOM:decreaseSoilFertilityForObjectHarvest(orderObject, 1)
                local existingPlanContext = getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState)
                if orderState.context.planTypeIndex == plan.types.chopReplant.index then
                    serverFlora:revertToPlantOrderAndDropInventoryForChopAndReplant(orderObject, sapien.sharedState.tribeID, addStoreOrders, sapien, existingPlanContext.planOrderIndex, existingPlanContext.planPriorityOffset, existingPlanContext.manuallyPrioritized)
                else
                    serverGOM:removeGameObjectAndDropInventory(orderObject.uniqueID, sapien.sharedState.tribeID, addStoreOrders, sapien, existingPlanContext.planOrderIndex, existingPlanContext.planPriorityOffset, existingPlanContext.manuallyPrioritized)
                end
                serverTutorialState:setChopTreeComplete(sapien.sharedState.tribeID)
                serverTribeAIPlayer:addGrievanceIfNeededForObjectDestruction(orderObject.sharedState.tribeID, sapien.sharedState.tribeID, orderObject.objectTypeIndex)
            end
        end
    },
    [action.types.buildMoveComponent.index] = {
        defaultSkillIndex = skill.types.basicBuilding.index,
        checkFrequency = craftCheckFrequency,
        checkForResourceAfterActionDelay = true,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            ----disabled--mj:objectLog(sapien.uniqueID, "buildMoveComponent completionFunction allowCompletion:", allowCompletion)
            if allowCompletion then
                local planState = planManager:getPlanSateForConstructionObject(orderObject, sapien.sharedState.tribeID)
                --mj:log("completeBuildMoveComponent:", planState)
                serverGOM:completeBuildMoveComponent(orderObject, sapien, planState)
                if (planState.planTypeIndex == plan.types.deconstruct.index or planState.planTypeIndex == plan.types.rebuild.index) then
                    serverTribeAIPlayer:addGrievanceIfNeededForObjectDestruction(orderObject.sharedState.tribeID, sapien.sharedState.tribeID, orderObject.objectTypeIndex)
                else
                    serverTribeAIPlayer:addGrievanceIfNeededForObjectBeingBuilt(orderObject.pos, sapien.sharedState.tribeID, orderObject.objectTypeIndex)
                end
            --else
               --[[ if craftableType.inProgressBuildModel and orderState.context and orderState.context.researchTypeIndex then
                    local planState = planManager:getPlanSateForConstructionObject(orderObject, sapien.sharedState.tribeID)
                        
                    local fractionComplete = skill:fractionLearned(sapien, taughtSkillTypeIndex)
                    local maxAllowedMoveCount = fractionComplete * craftableType.requiredResourceTotalCount + 1
    
                    local nextMoveIndex = (orderObject.sharedState.movedCount or 0) + 2
                    if nextMoveIndex <= maxAllowedMoveCount then
                        serverGOM:completeBuildMoveComponent(orderObject, sapien, planState)
                    end
                end]]
            end
        end,
    },
    [action.types.dig.index] = {
        defaultSkillIndex = skill.types.digging.index,
        checkFrequency = standardCheckFrequency * 0.25,
        toolMultiplierTypeIndex = tool.types.dig.index,
        injuryRisk = 1.0,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if allowCompletion then
                if constructableType then
                    constructionCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
                else
                    if not orderObject then
                        return
                    end
                    local vertID = orderObject.sharedState.vertID
                    local outputs = terrain:outputsForDigAtVertex(vertID, false)

                    local lastOutputID = nil
                    if outputs then
                        local scale = 1.0
                        local existingPlanContext = getPlanOrderIndexAndPriorityForVert(sapien.sharedState.tribeID, vertID, orderState)
                        for i,objectTypeKeyOrIndex in ipairs(outputs) do
                            lastOutputID = serverGOM:createOutput(sapien.pos, scale, gameObject.types[objectTypeKeyOrIndex].index, nil, sapien.sharedState.tribeID, plan.types.storeObject.index, existingPlanContext)
                        end
                    end

                    terrain:digVertex(vertID, sapien.sharedState.tribeID)

                   -- mj:log("in action.types.dig.index planManager:removePlanStateFromTerrainVertForTerrainModification orderState:", orderState, " trubeID:", sapien.sharedState.tribeID)

                    planManager:removePlanStateFromTerrainVertForTerrainModification(vertID, orderState.context.planTypeIndex, sapien.sharedState.tribeID, nil)
                    
                    if lastOutputID then
                        local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                        if lastOutputObject then
                            serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                        end
                    end
                end
            end
        end
    },
    [action.types.mine.index] = {
        defaultSkillIndex = skill.types.mining.index,
        checkFrequency = standardCheckFrequency,
        toolMultiplierTypeIndex = tool.types.mine.index,
        injuryRisk = 1.0,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if allowCompletion then
                if constructableType then
                    constructionCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
                else
                    if not orderObject then
                        return
                    end
                    local vertID = orderObject.sharedState.vertID
                    if vertID then
                        local outputs = terrain:outputsForDigAtVertex(vertID, false)

                        local lastOutputID = nil
                        if outputs then
                            local scale = 1.0
                            local existingPlanContext = getPlanOrderIndexAndPriorityForVert(sapien.sharedState.tribeID, vertID, orderState)

                            for i,objectTypeKeyOrIndex in ipairs(outputs) do
                                lastOutputID = serverGOM:createOutput(sapien.pos, scale, gameObject.types[objectTypeKeyOrIndex].index, nil, sapien.sharedState.tribeID, plan.types.storeObject.index, existingPlanContext)
                            end
                        end
                        
                        if lastOutputID then
                            local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                            if lastOutputObject then
                                serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                            end
                        end

                        terrain:digVertex(vertID, sapien.sharedState.tribeID)

                    -- mj:log("in action.types.mine.index planManager:removePlanStateFromTerrainVertForTerrainModification orderState:", orderState, " trubeID:", sapien.sharedState.tribeID)

                        planManager:removePlanStateFromTerrainVertForTerrainModification(vertID, orderState.context.planTypeIndex, sapien.sharedState.tribeID, nil)
                    else
                        if allowCompletion then
                            local isChisel = false
                            --mj:log("gameObject.types[orderObject.objectTypeIndex]:", gameObject.types[orderObject.objectTypeIndex])
                            local harvestableTypeIndex = rock:getLargeRockHarvestableTypeIndex(gameObject.types[orderObject.objectTypeIndex].rockTypeIndex, isChisel)
                            local existingPlanContext = getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState)
                            serverGOM:removeFromHarvestingObject(orderObject, sapien, sapien.sharedState.tribeID, existingPlanContext.planOrderIndex, existingPlanContext.planPriorityOffset, existingPlanContext.manuallyPrioritized, harvestableTypeIndex)
                            local researchTypeIndex = orderState.context.researchTypeIndex
                            if researchTypeIndex then
                                if orderState.context.researchTypeIndex and serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, orderState.context.researchTypeIndex) then
                                    planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sapien.sharedState.tribeID)
                                end
                            end
                        end
                    end
                end
            end
        end
    },
    [action.types.chiselStone.index] = {
        defaultSkillIndex = skill.types.chiselStone.index,
        checkFrequency = standardCheckFrequency,
        toolMultiplierTypeIndex = tool.types.softChiselling.index, --maybe a problem, as it could be a hard chisel, however hard chisels should also support soft chiselling with the same multiplier
        injuryRisk = 1.0,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if allowCompletion then
                if constructableType then
                    constructionCompletionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
                else
                    if not orderObject then
                        return
                    end
                    local vertID = orderObject.sharedState.vertID
                    if vertID then
                        local outputs = terrain:outputsForDigAtVertex(vertID, true)

                        local lastOutputID = nil
                        if outputs then
                            local existingPlanContext = getPlanOrderIndexAndPriorityForVert(sapien.sharedState.tribeID, vertID, orderState)
                            local scale = 1.0
                            for i,objectTypeKeyOrIndex in ipairs(outputs) do
                                if not gameObject.types[objectTypeKeyOrIndex] then
                                    mj:error("no game object of type:", objectTypeKeyOrIndex, " outputs:", outputs)
                                    
                                    local vert = terrain:getVertWithID(vertID)
                                    local terrainTypeIndex = vert.baseType
                                    local variations = vert:getVariations()
                                    mj:error("terrainTypeIndex:", terrainTypeIndex, " variations:", variations)
                                end
                                lastOutputID = serverGOM:createOutput(sapien.pos, scale, gameObject.types[objectTypeKeyOrIndex].index, nil, sapien.sharedState.tribeID, plan.types.storeObject.index, existingPlanContext)
                            end
                        end

                        terrain:digVertex(vertID, sapien.sharedState.tribeID)

                    -- mj:log("in action.types.mine.index planManager:removePlanStateFromTerrainVertForTerrainModification orderState:", orderState, " trubeID:", sapien.sharedState.tribeID)

                        planManager:removePlanStateFromTerrainVertForTerrainModification(vertID, orderState.context.planTypeIndex, sapien.sharedState.tribeID, nil)
                        
                        if lastOutputID then
                            local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                            if lastOutputObject then
                                serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                            end
                        end
                    else
                        if allowCompletion then
                            local isChisel = true
                            local harvestableTypeIndex = rock:getLargeRockHarvestableTypeIndex(gameObject.types[orderObject.objectTypeIndex].rockTypeIndex, isChisel)
                            local existingPlanContext = getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState)
                            serverGOM:removeFromHarvestingObject(orderObject, sapien, sapien.sharedState.tribeID, existingPlanContext.planOrderIndex, existingPlanContext.planPriorityOffset, existingPlanContext.manuallyPrioritized, harvestableTypeIndex)
                            local researchTypeIndex = orderState.context.researchTypeIndex
                            if researchTypeIndex then
                                if orderState.context.researchTypeIndex and serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, orderState.context.researchTypeIndex) then
                                    planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sapien.sharedState.tribeID)
                                end
                            end
                        end
                    end
                end
            end
        end
    },
    
    [action.types.playFlute.index] = {
        checkFrequency = 10.0,
        defaultSkillIndex = skill.types.flutePlaying.index,
    },
    [action.types.playDrum.index] = {
        checkFrequency = 10.0,
        defaultSkillIndex = skill.types.flutePlaying.index,
    },
    [action.types.playBalafon.index] = {
        checkFrequency = 10.0,
        defaultSkillIndex = skill.types.flutePlaying.index,
    },
    
    [action.types.clear.index] = {
        defaultSkillIndex = skill.types.gathering.index,
        checkFrequency = standardCheckFrequency * 0.25,
        --toolMultiplierTypeIndex = tool.types.mine.index,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if allowCompletion then
                local vertID = orderObject.sharedState.vertID
                if vertID then
                    local outputs = terrain:outputsForClearAtVertex(vertID)
                    --mj:log("outputs:", outputs)
    
                    terrain:removeVegetationForVertex(vertID)
                    terrain:removeSnowForVertex(vertID)
    
    
                    local tribeID = sapien.sharedState.tribeID
                    local lastOutputID = nil
                    if outputs then
                        local scale = 1.0
                        local foundGrassOrHayOutput = false
                        local existingPlanContext = getPlanOrderIndexAndPriorityForVert(tribeID, vertID, orderState)
                        for i,objectTypeKey in ipairs(outputs) do
                            --mj:log("create output:", objectTypeIndex)
                            lastOutputID = serverGOM:createOutput(sapien.pos, scale, gameObject.types[objectTypeKey].index, nil, tribeID, plan.types.storeObject.index, existingPlanContext)
    
                            if (not foundGrassOrHayOutput) and (objectTypeKey == "grass" or objectTypeKey == "hay") then
                                foundGrassOrHayOutput = true
                                terrain:partiallyDegradeSoilFertilityForVertex(vertID, 1)
                                serverTutorialState:addToGrassClearCount(tribeID, 1)
                            end
                        end
                    end
    
                    planManager:removePlanStateFromTerrainVertForTerrainModification(vertID, plan.types.clear.index, tribeID, nil)
                    
                    if lastOutputID then
                        local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                        if lastOutputObject then
                            serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                        end
                    end
                end
            end
        end
    },
    [action.types.extinguish.index] = {
        checkFrequency = craftCheckFrequency,
        completionFunction = function(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
            if allowCompletion then
                if orderObject.objectTypeIndex == gameObject.types.campfire.index then
                    serverCampfire:setLit(orderObject, false, sapien.sharedState.tribeID)
                elseif orderObject.objectTypeIndex == gameObject.types.torch.index then
                    serverTorch:setLit(orderObject, false, sapien.sharedState.tribeID)
                elseif orderObject.objectTypeIndex == gameObject.types.brickKiln.index then
                    serverKiln:setLit(orderObject, false, sapien.sharedState.tribeID)
                end
                
                planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sapien.sharedState.tribeID)
            end
        end
    },
}


local function updateStandardAction(sapien, actionState, dt, speedMultiplier, orderObject, orderState, updateInfo)
    local actionUpdateResult = {
        completed = false,
        cancel = false
    }
    local skillSpeedMultiplier = 1.0
    local requiredSkillTypeIndex = nil
    local optionalFallbackRequiredSkillTypeIndex = nil
    local taughtSkillTypeIndex = nil
    local constructableType = nil
    local constructableObject = nil
    local planState = nil --may remain nil for some objects, there often is no plan state eg. if this is a store held object order

    local researchTypeIndex = nil
    if orderState.context then
        researchTypeIndex = orderState.context.researchTypeIndex
    end

    local function setupFromObject(object)
        local objectSharedState = object.sharedState
        planState = planManager:getPlanSateForConstructionObject(object, sapien.sharedState.tribeID)
        if planState then
            optionalFallbackRequiredSkillTypeIndex = planState.optionalFallbackSkill
        end

        if objectSharedState.inProgressConstructableTypeIndex then
            constructableType = constructable.types[objectSharedState.inProgressConstructableTypeIndex]
        end

        if not constructableType then
            if planState then
                constructableType = constructable.types[planState.constructableTypeIndex]
            end
        end

        if constructableType then
            constructableObject = object
        end
    end

    if orderState.orderTypeIndex ~= order.types.deliverFuel.index then
        if orderObject then
            setupFromObject(orderObject)
        end
        if not constructableType then
            if orderState.context and orderState.context.planObjectID then
                local planObject = serverGOM:getObjectWithID(orderState.context.planObjectID)
                if planObject then
                    setupFromObject(planObject)
                end
            end
        end
    end

    local orderObjectTypeIndex = nil
    if orderObject then
        orderObjectTypeIndex = orderObject.objectTypeIndex
    end
    local learningInfo = skillLearning:getTaughtSkillInfo(orderState.orderTypeIndex, orderObjectTypeIndex)
    ----disabled--mj:objectLog(sapien.uniqueID, "updateStandardAction orderState.context:", orderState.context, " learningInfo:", learningInfo, " constructableType:", constructableType, " orderObject:", orderObject)

    if researchTypeIndex then
        requiredSkillTypeIndex = skill.types.researching.index
        taughtSkillTypeIndex = research.types[researchTypeIndex].skillTypeIndex
        ----disabled--mj:objectLog(sapien.uniqueID, "taughtSkillTypeIndex A:", taughtSkillTypeIndex)
    elseif orderState.orderTypeIndex == order.types.deliverFuel.index or 
    orderState.orderTypeIndex == order.types.throwProjectile.index or 
    orderState.orderTypeIndex == order.types.light.index then
        if learningInfo then
            requiredSkillTypeIndex = learningInfo.skillTypeIndex
            taughtSkillTypeIndex = learningInfo.skillTypeIndex
        end
    elseif orderState.orderTypeIndex == order.types.extinguish.index then
        requiredSkillTypeIndex = updateInfo.defaultSkillIndex
        taughtSkillTypeIndex = updateInfo.defaultSkillIndex
    elseif constructableType then
        --local planState = planManager:getPlanSateForConstructionObject(orderObject, sapien.sharedState.tribeID)
        if constructableType.skills then
            requiredSkillTypeIndex = constructableType.skills.required
            taughtSkillTypeIndex = constructableType.skills.required
        end
        
        local buildSequenceIndex = constructableObject.sharedState.buildSequenceIndex or 1
        local currentBuildSequenceInfo = constructableType.buildSequence[buildSequenceIndex]
        
        if currentBuildSequenceInfo then
            local constructableSequenceType = constructable.sequenceTypes[currentBuildSequenceInfo.constructableSequenceTypeIndex]
            if constructableSequenceType and constructableSequenceType.optionalFallbackSkill then
                optionalFallbackRequiredSkillTypeIndex = constructableSequenceType.optionalFallbackSkill
            end
        end

        ----disabled--mj:objectLog(sapien.uniqueID, "taughtSkillTypeIndex constructableType.skills.required:", taughtSkillTypeIndex)
    else
        requiredSkillTypeIndex = updateInfo.defaultSkillIndex
        taughtSkillTypeIndex = updateInfo.defaultSkillIndex
       -- --disabled--mj:objectLog(sapien.uniqueID, "taughtSkillTypeIndex defaultSkillIndex:", taughtSkillTypeIndex)
    end

    if requiredSkillTypeIndex then
        if skill:priorityLevel(sapien, requiredSkillTypeIndex) == 0 then
            if (not optionalFallbackRequiredSkillTypeIndex) or (skill:priorityLevel(sapien, optionalFallbackRequiredSkillTypeIndex) == 0) then
               -- mj:error("requiredSkillTypeIndex but not assigned:", requiredSkillTypeIndex) --this is fine, probably the sapien has had their roles changed, just cancel.
                actionUpdateResult.cancel = true
                return actionUpdateResult --cancel
            end
        else
            if skill.types[requiredSkillTypeIndex].noCapacityWithLimitedGeneralAbility then
                if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                    if (not optionalFallbackRequiredSkillTypeIndex) or (skill:priorityLevel(sapien, optionalFallbackRequiredSkillTypeIndex) == 0) then
                        --disabled--mj:objectLog(sapien.uniqueID, "cancelling due to limited general ability")
                        actionUpdateResult.cancel = true
                        return actionUpdateResult --cancel
                    end
                end
            end
        end
        skillSpeedMultiplier = skillLearning:getGeneralSkillSpeedMultiplier(sapien, sapien.sharedState, requiredSkillTypeIndex)
    end

    local toolMultiplier = 1.0
    if updateInfo.toolMultiplierTypeIndex then
        local function addToolMultiplier(toolObjectInfo)
            local heldObjectType = gameObject.types[toolObjectInfo.objectTypeIndex]
            local toolUsages = heldObjectType.toolUsages
            if toolUsages then
                local toolInfo = toolUsages[updateInfo.toolMultiplierTypeIndex]
                if toolInfo then
                    if toolInfo[tool.propertyTypes.speed.index] then
                        toolMultiplier = toolMultiplier * toolInfo[tool.propertyTypes.speed.index]
                    end
                end
            end
        end

        local lastHeldObjectInfo = sapienInventory:lastObjectInfo(sapien, sapienInventory.locations.held.index)
        if lastHeldObjectInfo then
            addToolMultiplier(lastHeldObjectInfo)
        elseif constructableType and orderObject then
            local toolObjectInfo = objectInventory:getNextMatch(orderObject.sharedState, objectInventory.locations.tool.index)
            if toolObjectInfo then
                addToolMultiplier(toolObjectInfo)
            end
        end
    end

    local unskilledSpeedMultipler = 1.0
    if updateInfo.unskilledSpeedMultipler and requiredSkillTypeIndex and (not skill:hasSkill(sapien, requiredSkillTypeIndex)) then
        unskilledSpeedMultipler = updateInfo.unskilledSpeedMultipler
        --mj:log("unskilledSpeedMultipler:", unskilledSpeedMultipler)
    end

    local privateState = sapien.privateState
    privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier * skillSpeedMultiplier * toolMultiplier * unskilledSpeedMultipler

    local afterActionDelay = 0.0
    if updateInfo.checkForResourceAfterActionDelay and constructableType then
        afterActionDelay = getAfterActionDelayForConstructable(sapien, constructableObject, taughtSkillTypeIndex)
    end

    local checkDelay = updateInfo.checkFrequency + afterActionDelay
    
   -- --disabled--mj:objectLog(sapien.uniqueID, "privateState.actionStateTimer:", privateState.actionStateTimer, " checkDelay:", checkDelay, " updateInfo:", updateInfo, " skillSpeedMultiplier:", skillSpeedMultiplier, " requiredSkillTypeIndex:", requiredSkillTypeIndex)

    if privateState.actionStateTimer > checkDelay then

        local isDelayingSkillLearnDueToNeedingConstructionCompletedForResearch = false
        local removeAnyPlansDueToJustCompletedResearch = false
        
       -- --disabled--mj:objectLog(sapien.uniqueID, "privateState.actionStateTimer > checkDelay:", privateState.actionStateTimer, " checkDelay:", checkDelay, " updateInfo:", updateInfo)
        if taughtSkillTypeIndex or researchTypeIndex then
            local skillIncrease = checkDelay / unskilledSpeedMultipler

            --[[if researchTypeIndex then
                local researchType = research.types[researchTypeIndex]
                if researchType.initialResearchSpeedLearnMultiplier then
                    skillIncrease = skillIncrease * researchType.initialResearchSpeedLearnMultiplier
                end
            end]]

            if updateInfo.addToSkillOverrideFunction then
                skillIncrease = updateInfo.addToSkillOverrideFunction(sapien, taughtSkillTypeIndex, researchTypeIndex, skillSpeedMultiplier, orderState, learningInfo)
            end

            if researchTypeIndex and orderState.context.discoveryCraftableTypeIndex then
                if skill:hasSkill(sapien, taughtSkillTypeIndex) then --this is designed to catch already-skilled sapiens who are researching a new discoveryCraftableTypeIndex, to provide a boost to research speed
                    skillIncrease = skillIncrease * 4.0
                end
            end
            
            --mj:log("researchTypeIndex:", researchTypeIndex, " constructableType:", constructableType)
            if researchTypeIndex and constructableType and constructableType.buildSequence then
                local buildSequenceIndex = constructableObject.sharedState.buildSequenceIndex or 1
                local currentBuildSequenceInfo = constructableType.buildSequence[buildSequenceIndex]
                --mj:log("buildSequenceIndex:", buildSequenceIndex)
                --mj:log("constructableType.buildSequence[buildSequenceIndex].constructableSequenceTypeIndex:", constructableType.buildSequence[buildSequenceIndex].constructableSequenceTypeIndex)
                --mj:log("constructable.sequenceTypes.moveComponents.index:", constructable.sequenceTypes.moveComponents.index)
                if buildSequenceIndex < #constructableType.buildSequence or (currentBuildSequenceInfo and currentBuildSequenceInfo.constructableSequenceTypeIndex == constructable.sequenceTypes.moveComponents.index) then
                   -- mj:log("checking will have research")
                    if serverSapienSkills:willHaveResearch(sapien, researchTypeIndex, orderState.context.discoveryCraftableTypeIndex, skillIncrease) then
                       -- mj:log("isDelayingSkillLearnDueToNeedingConstructionCompletedForResearch")
                        isDelayingSkillLearnDueToNeedingConstructionCompletedForResearch = true
                    end

                end
            end

            
            if not isDelayingSkillLearnDueToNeedingConstructionCompletedForResearch then
                --mj:log("calling addToSkill:", increase, " for sapien:", sapien.uniqueID, " taughtSkillTypeIndex:", taughtSkillTypeIndex, " researchTypeIndex:", researchTypeIndex)
                local discoveryCraftableTypeIndex = orderState.context.discoveryCraftableTypeIndex
                if not discoveryCraftableTypeIndex then
                    if constructableType and constructableType.disabledUntilCraftableResearched then
                        discoveryCraftableTypeIndex = constructableType.index
                    end
                end
                serverSapienSkills:addToSkill(sapien, taughtSkillTypeIndex, researchTypeIndex, discoveryCraftableTypeIndex, skillIncrease)

                if researchTypeIndex and (not orderState.context.discoveryCraftableTypeIndex) and serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, researchTypeIndex) then
                    removeAnyPlansDueToJustCompletedResearch = true
                end
            end
        end

        local allowCompletion = true

        local requiredLearnComplete = true
        if researchTypeIndex and (not serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, researchTypeIndex)) then
            requiredLearnComplete = false
        end
        if taughtSkillTypeIndex and (not skill:hasSkill(sapien, taughtSkillTypeIndex)) then
            requiredLearnComplete = false
        end

        if (not isDelayingSkillLearnDueToNeedingConstructionCompletedForResearch) and (not requiredLearnComplete) then
            
            if constructableType then
                local buildSequenceIndex = constructableObject.sharedState.buildSequenceIndex or 1
                local currentBuildSequenceInfo = constructableType.buildSequence[buildSequenceIndex]
               -- mj:log("currentBuildSequenceInfo:", currentBuildSequenceInfo)
                if currentBuildSequenceInfo then
                    if currentBuildSequenceInfo.disallowCompletionWithoutSkill then 
                        allowCompletion = false
                    elseif currentBuildSequenceInfo.constructableSequenceTypeIndex == constructable.sequenceTypes.moveComponents.index then
                        if actionState.sequenceTypeIndex == actionSequence.types.inspect.index then
                            allowCompletion = false
                        --else
                        -- mj:warn("currentBuildSequenceInfo.lowSkillActionSequenceTypeIndex ~= actionState.sequenceTypeIndex. actionState.sequenceTypeIndex:", actionState.sequenceTypeIndex, "currentBuildSequenceInfo.lowSkillActionSequenceTypeIndex:", currentBuildSequenceInfo.lowSkillActionSequenceTypeIndex)
                    -- if buildSequenceIndex >= #constructableType.buildSequence then -- If it's going to complete the entire sequence, don't complete if we downt have the skill. Otherwise OK.
                            --[[local fractionComplete = 0.0
                            if researchTypeIndex then
                                fractionComplete = serverWorld:discoveryCompletionFraction(sapien.sharedState.tribeID, researchTypeIndex)
                            else
                                fractionComplete = skill:fractionLearned(sapien, taughtSkillTypeIndex)
                            end
                            local maxAllowedMoveCount = fractionComplete * constructableType.requiredResourceTotalCount
                            local totalMovedCount = objectInventory:getTotalCount(orderObject.sharedState, objectInventory.locations.inUseResource.index)

                            mj:log("totalMovedCount:", totalMovedCount, " maxAllowedMoveCount:", maxAllowedMoveCount, " fractionComplete:", fractionComplete)

                            if totalMovedCount + 1 >= maxAllowedMoveCount then
                                allowCompletion = false
                            end]]
                        end
                    -- end
                    end
                end
            elseif not updateInfo.allowCompletionWithoutSkill then
               -- mj:log("allowCompletion = false, no constructableType")
                allowCompletion = false
            end
        end
        
        if allowCompletion and researchTypeIndex and orderState.context.discoveryCraftableTypeIndex and constructable.types[orderState.context.discoveryCraftableTypeIndex].disabledUntilCraftableResearched then
            if constructableType then
                local buildSequenceIndex = constructableObject.sharedState.buildSequenceIndex or 1
                if buildSequenceIndex >= #constructableType.buildSequence then
                    if serverWorld:discoveryIsCompleteForTribe(sapien.sharedState.tribeID, researchTypeIndex) then
                        if not serverWorld:craftableDiscoveryIsCompleteForTribe(sapien.sharedState.tribeID, orderState.context.discoveryCraftableTypeIndex) then
                            allowCompletion = false
                        end
                    end
                end
            end
        end

        local toolDegradeBaseRate = 0.02

        if updateInfo.toolMultiplierTypeIndex and (not researchTypeIndex) then --dont degrade tools if you are researching, as it sucks to nearly have a breakthrough then have the only tool break
            local function getToolDamageMultiplier(toolObjectInfo)
                local degradeIncrementMultiplier = 1.0
                local heldObjectType = gameObject.types[toolObjectInfo.objectTypeIndex]
                local toolUsages = heldObjectType.toolUsages
                if toolUsages then
                    local toolInfo = toolUsages[updateInfo.toolMultiplierTypeIndex]
                    if toolInfo then
                        if toolInfo[tool.propertyTypes.durability.index] then
                            degradeIncrementMultiplier = degradeIncrementMultiplier / toolInfo[tool.propertyTypes.durability.index]
                        end
                    end
                end
                return degradeIncrementMultiplier
            end

            local lastHeldObjectInfo = sapienInventory:lastObjectInfo(sapien, sapienInventory.locations.held.index)
            if lastHeldObjectInfo then
                local degradeIncrementMultiplier = getToolDamageMultiplier(lastHeldObjectInfo)
                local fractionDegraded = lastHeldObjectInfo.fractionDegraded or 0.0
                fractionDegraded = fractionDegraded + toolDegradeBaseRate * degradeIncrementMultiplier
                if fractionDegraded >= 1.0 then
                    serverSapienInventory:removeObject(sapien, sapienInventory.locations.held.index)
                    serverGOM:sendNotificationForObject(sapien, notification.types.toolBroke.index, {
                        pos = sapien.pos
                    }, sapien.sharedState.tribeID)
                else
                    serverSapienInventory:changeLastObjectState(sapien, sapienInventory.locations.held.index, "fractionDegraded", fractionDegraded)
                end
            elseif constructableType and (orderObject == constructableObject) then
                local toolObjectInfo = objectInventory:getNextMatch(orderObject.sharedState, objectInventory.locations.tool.index)
                if toolObjectInfo then
                    local degradeIncrementMultiplier = getToolDamageMultiplier(toolObjectInfo)
                    local fractionDegraded = toolObjectInfo.fractionDegraded or 0.0
                    fractionDegraded = fractionDegraded + toolDegradeBaseRate * degradeIncrementMultiplier
                    if fractionDegraded >= 1.0 then
                        objectInventory:removeAndGetInfo(orderObject.sharedState, objectInventory.locations.tool.index, toolObjectInfo.objectTypeIndex, nil)
                        planManager:updatePlanForConstructionObjectToolOrResourceChange(orderObject, sapien, constructableType, sapien.sharedState.tribeID)
                        serverGOM:sendNotificationForObject(sapien, notification.types.toolBroke.index, {
                            pos = sapien.pos
                        }, sapien.sharedState.tribeID)
                    else
                        objectInventory:changeInventoryObjectState(orderObject.sharedState, objectInventory.locations.tool.index, nil, nil, "fractionDegraded", fractionDegraded)
                    end
                end
            end
        end

        if allowCompletion and orderState.context and orderState.context.completionRepeatCount then --this is crude, they might keep their progress and use it elsewhere if interrupted. But the bug is in the player's favor, so it's OK for now.
            privateState.actionStateRepeatCounter = (privateState.actionStateRepeatCounter or 0) + 1
            if privateState.actionStateRepeatCounter < orderState.context.completionRepeatCount then
                allowCompletion = false
            end
        end

        if allowCompletion then
            privateState.actionStateRepeatCounter = nil
        end

        local planInjuryRisk = nil
        if orderState.context and orderState.context.planTypeIndex then
            planInjuryRisk = plan.types[orderState.context.planTypeIndex].injuryRisk
        end

        if updateInfo.injuryRisk or (updateInfo.completionInjuryRisk and allowCompletion) or planInjuryRisk then
            local injuryRisk = nil
            if allowCompletion and updateInfo.completionInjuryRisk then
                injuryRisk = updateInfo.completionInjuryRisk
            else
                injuryRisk = math.max(updateInfo.injuryRisk or 0.0, planInjuryRisk or 0.0)
                injuryRisk = injuryRisk * privateState.actionStateTimer * sapienConstants.generalInjuryRisk
            end

            checkForInjury(sapien, injuryRisk)
        end
        
        if updateInfo.completionFunction and (not debugAnimations) then
            updateInfo.completionFunction(allowCompletion, sapien, orderObject, orderState, actionState, constructableType, requiredLearnComplete)
        end

        if removeAnyPlansDueToJustCompletedResearch then -- this block was added to correctly stop playing a flute when researching it. Probbaly makes other code redundant, may cause issues
            if orderObject then
                planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, researchTypeIndex, sapien.sharedState.tribeID)
                serverGOM:removeTemporaryGameObjectForOrderCompleteIfNeeded(orderObject)
            else
                local removeHeldObjectOrderContext = true
                serverSapien:cancelOrderAtQueueIndex(sapien, 1, removeHeldObjectOrderContext)
            end
        end
        
        privateState.actionStateTimer = privateState.actionStateTimer - checkDelay
        if privateState.actionStateTimer > checkDelay then
            privateState.actionStateTimer = 0.0
        end

        if researchTypeIndex then
            if (not requiredLearnComplete) and (not allowCompletion) then
                checkForReserachNearlyComplete(sapien, researchTypeIndex, checkDelay)
            end
        end

        --mj:log("privateState.actionStateTimer:", privateState.actionStateTimer)
        
        actionUpdateResult.completed = true
    end

    return actionUpdateResult
end

local function addToResearch(sapien, actionState, dt, speedMultiplier, orderObject, orderState, researchTypeIndex, discoveryCraftableTypeIndex)
    --mj:error("addToResearch:", addToResearch)
    local privateState = sapien.privateState
    local sharedState = sapien.sharedState
    local researchProvidesSkillTypeIndex = research.types[researchTypeIndex].skillTypeIndex

    local skillSpeedMultiplier = skillLearning:getGeneralSkillSpeedMultiplier(sapien, sharedState, skill.types.researching.index)
    privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier * skillSpeedMultiplier

    if privateState.actionStateTimer > 10.0 then
        local baseIncrease = privateState.actionStateTimer
        local skillIncrease = baseIncrease

        privateState.actionStateTimer = 0.0
       --[[ local researchType = research.types[orderState.context.researchTypeIndex]
        if researchType.initialResearchSpeedLearnMultiplier then
            skillIncrease = baseIncrease * researchType.initialResearchSpeedLearnMultiplier
        end]]

        serverSapienSkills:addToSkill(sapien, researchProvidesSkillTypeIndex, researchTypeIndex, discoveryCraftableTypeIndex, skillIncrease)
        if skill:hasSkill(sapien, researchProvidesSkillTypeIndex) then
            --mj:error("removing plan states due to assumed research completion. This might not be correct behavior.")
            if orderObject then
                planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, researchTypeIndex, sharedState.tribeID)
                serverGOM:removeTemporaryGameObjectForOrderCompleteIfNeeded(orderObject)
            else
                local removeHeldObjectOrderContext = true
                serverSapien:cancelOrderAtQueueIndex(sapien, 1, removeHeldObjectOrderContext)
            end
        else
            checkForReserachNearlyComplete(sapien, researchTypeIndex, baseIncrease)
        end
        return true
    end
    return false
end

local function addToSkillForOrder(sapien, orderObject, orderTypeIndex)
    
    local taughtSkillInfo = skillLearning:getTaughtSkillInfo(orderTypeIndex, orderObject.objectTypeIndex)
    --mj:log("addToSkillForOrder taughtSkillInfo:", taughtSkillInfo)
    if taughtSkillInfo then
        local skillTypeIndex = taughtSkillInfo.skillTypeIndex
        local baseMultiplier = taughtSkillInfo.baseIncrease
        local skillSpeedMultiplier = skillLearning:getGeneralSkillSpeedMultiplier(sapien, sapien.sharedState, skillTypeIndex)
        --mj:log("baseMultiplier * skillSpeedMultiplier: sapien:", baseMultiplier * skillSpeedMultiplier, sapien)
        serverSapienSkills:addToSkill(sapien, skillTypeIndex, nil, nil, baseMultiplier * skillSpeedMultiplier)
    end
end

local maxGoalObjectMoveDistanceBeforePathRecalculation2 = mj:mToP(5.0) * mj:mToP(5.0)

function activeOrderAI:frequentUpdate(sapien, dt, speedMultiplier)
    if speedMultiplier < 0.0001 then
        return
    end
    local sharedState = sapien.sharedState
    local orderObject = nil
    local done = false
    local cancel = false
    local saveStateChange = false
    local orderState = sharedState.orderQueue[1]
    if not orderState then
        mj:warn("no order state")
        done = true
    else
        local requiresOrderObject = false
        if orderState.objectID then
            orderObject = serverSapien:checkObjectLoadedAndLoadIfNot(sapien, orderState.objectID, orderState.pos, 3, function() 
                --disabled--mj:objectLog(sapien.uniqueID,"cancel object not loaded. orderState.objectID:", orderState.objectID, " orderState.pos:", orderState.pos)--, " orderState:", orderState)
                cancel = true
            end)
            requiresOrderObject = true
            if orderObject and orderObject.sharedState then
                --local orderObjectState = orderObject.sharedState
                --if  (orderObjectState.assignedSapienID and orderObjectState.assignedSapienID ~= sapien.uniqueID) then --commented out because it cancels orders to carry resources to craft areas where a sapien is already crafting
                --    mj:log("cancel b:", sapien.uniqueID, "orderObjectState:", orderObjectState)
                --    cancel = true
               -- else
                    if orderState.context and orderState.context.planObjectID then
                        local planObject = serverGOM:getObjectWithID(orderState.context.planObjectID)
                        if planObject then
                            if orderState.orderTypeIndex ~= order.types.deliverPlanObjectForCraftingOrResearchElsewhere.index and 
                            orderState.orderTypeIndex ~= order.types.transferObject.index and
                            orderState.orderTypeIndex ~= order.types.haulMoveToObject.index and
                            orderState.orderTypeIndex ~= order.types.haulDragObject.index and
                            orderState.orderTypeIndex ~= order.types.haulRideObject.index then
                                if not planManager:hasPlanForObjectSapienAndType(sapien, planObject, orderState.context.planTypeIndex) then --todo this is all a bit messy and rough, could be targeted a lot better
                                    local maintenanceTypeIndex = maintenance:requiredMaintenanceTypeIndex(sharedState.tribeID, planObject, sapien.uniqueID)
                                    if not maintenanceTypeIndex or (orderState.context.planTypeIndex and (maintenance.types[maintenanceTypeIndex].planTypeIndex ~= orderState.context.planTypeIndex)) then
                                        --disabled--mj:objectLog(sapien.uniqueID, "cancel c planObject:", planObject.uniqueID, " orderState:", orderState, " maintenanceTypeIndex:", maintenanceTypeIndex)--, " orderState.context:", orderState.context) -- this happens a lot now, as other closer sapiens will often get assigned
                                        --[[if maintenanceTypeIndex then
                                            mj:log("maintenanceTypeIndex:", maintenanceTypeIndex, " maintenance.types[maintenanceTypeIndex].planTypeIndex:", maintenance.types[maintenanceTypeIndex].planTypeIndex, " orderState:", orderState)
                                        end]]
                                        cancel = true
                                    end
                                end
                            end
                        else
                            --disabled--mj:objectLog(sapien.uniqueID,"cancel due to plan object not loaded or missing:", sapien.uniqueID)
                            cancel = true
                        end
                    end

                    if not cancel then
                        if orderState.orderTypeIndex ~= order.types.deliverFuel.index and (not gameObject.types[orderObject.objectTypeIndex].isStorageArea) then
                            local planStates = planManager:getPlanStatesForObject(orderObject, sharedState.tribeID)
                            if planStates then
                                local orderPlanTypeIndex = nil
                                if orderState.context then
                                    orderPlanTypeIndex = orderState.context.planTypeIndex
                                end
                                local foundMatching = false
                                local foundNonMatching = false
                                for i, planState in ipairs(planStates) do
                                    if planState.planTypeIndex == orderPlanTypeIndex then
                                        foundMatching = true
                                        break
                                    elseif plan.types[planState.planTypeIndex].preventsResourceUseInOtherPlans then
                                        foundNonMatching = true
                                    end
                                end

                                if foundNonMatching and (not foundMatching) then
                                    --disabled--mj:objectLog(sapien.uniqueID,"cancel due to plan object having non-matching plan type index:", sapien.uniqueID, " orderState:", orderState, " orderObject.uniqueID", orderObject.uniqueID)--, " orderObject state:", orderObject.sharedState)
                                    cancel = true
                                end
                            end
                        end
                    end

                    if not cancel then
                        if orderState.orderTypeIndex == order.types.pickupObject.index and gameObject.types[orderObject.objectTypeIndex].isStorageArea then
                            if orderState.context then
                                local objectTypeIndex = orderState.context.objectTypeIndex
                                if objectTypeIndex then
                                    local tribeIDForPermissions = sharedState.tribeID
                                    --[[if orderState.context.planTypeIndex == plan.types.take.index then
                                        tribeIDForPermissions = nil
                                    end]]
                                    if not serverStorageArea:storageAreaHasObjectAvailable(orderObject.uniqueID, objectTypeIndex, tribeIDForPermissions) then
                                        --disabled--mj:objectLog(sapien.uniqueID,"cancel due to storage area no longer having available resource:", sapien.uniqueID, " orderState:", orderState, " orderObject.uniqueID", orderObject.uniqueID, " objectTypeIndex:", objectTypeIndex)--, " orderObject state:", orderObject.sharedState)
                                        cancel = true
                                    end
                                end
                            end
                        elseif orderState.orderTypeIndex == order.types.gather.index then--or orderState.orderTypeIndex == order.types.gatherBush.index then

                            if not gameObject.types[orderObject.objectTypeIndex].revertToSeedlingGatherResourceCounts then
                                local objectState = orderObject.sharedState
        
                                local objectCount = 0

                                local inventory = objectState.inventory
                                if inventory then
                                    local countsByObjectType = inventory.countsByObjectType
                                    local objectTypeIndex = orderState.context.objectTypeIndex
                                    if objectTypeIndex then
                                        if countsByObjectType[objectTypeIndex] then
                                            objectCount = countsByObjectType[objectTypeIndex]
                                        end
                                    else
                                        local gatherableTypes = gameObject.types[orderObject.objectTypeIndex].gatherableTypes
                                        if gatherableTypes then
                                            for i,gatherableObjectTypeIndex in ipairs(gatherableTypes) do
                                                local thisCount = countsByObjectType[gatherableObjectTypeIndex]
                                                if thisCount and thisCount > 0 then
                                                    objectCount = thisCount
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
        
                                if objectCount <= 0 then
                                    --disabled--mj:objectLog(sapien.uniqueID, "cancel due to gather object no longer having available resource:", sapien.uniqueID, " orderState:", orderState, " orderObject.uniqueID", orderObject.uniqueID, " objectTypeIndex:", orderState.context.objectTypeIndex)--, " orderObject state:", orderObject.sharedState)
                                    --planManager:removeBadPlanStateForGatherWithoutAvailableResource(orderObject, orderState.context.objectTypeIndex, sapien.sharedState.tribeID)
                                    cancel = true
                                end
                            end
                        end
                    end
                --end
            end
        end

        --if seat object then 

        --local orderType = order.types[orderState.orderTypeIndex]
        local actionState = sharedState.actionState
        local activeSequence = actionSequence.types[actionState.sequenceTypeIndex]

        
        if actionState.progressIndex > #activeSequence.actions then
            done = true
        end

        if not done then

            if not order.types[orderState.orderTypeIndex].allowToFinishEvenWhenVeryTired then
                if (not orderState.context) or (orderState.context.lookAtIntent ~= lookAtIntents.types.eat.index and orderState.context.lookAtIntent ~= lookAtIntents.types.putOnClothing.index) then
                    local sleepDesire = desire:getCachedSleep(sapien, sapien.temporaryPrivateState, function() 
                        return serverWorld:getTimeOfDayFraction(sapien.pos) 
                    end)
                    if sleepDesire >= desire.levels.strong then
                        --disabled--mj:objectLog(sapien.uniqueID, "cancel order due to sleep desire. orderType:", order.types[orderState.orderTypeIndex].name, " orderState:", orderState)
                        cancel = true
                    end
                end
            end
            

            if (not cancel) and ((not requiresOrderObject) or orderObject) then

                local actionCompleted = false

                local currentActionTypeIndex = activeSequence.actions[actionState.progressIndex]

                if (not cancel) then

                    local function removeTemporaryOrderObjectIfActionSequenceComplete()
                        if actionState.progressIndex >= #activeSequence.actions then
                            serverGOM:removeTemporaryGameObjectForOrderCompleteIfNeeded(orderObject)
                        end
                    end


                    local privateState = sapien.privateState
                    if not privateState.actionStateTimer then
                        privateState.actionStateTimer = 0.0
                    end
                    

                    local actionUpdateInfo = activeOrderAI.updateInfos[currentActionTypeIndex]

                    if actionUpdateInfo then
                        local actionUpdateResult = updateStandardAction(sapien, actionState, dt, speedMultiplier, orderObject, orderState, actionUpdateInfo)
                        if actionUpdateResult.cancel then
                            cancel = true
                        else
                            actionCompleted = actionUpdateResult.completed
                        end
                    elseif action.types[currentActionTypeIndex].isMovementAction then


                    --mj:log(sapien.uniqueID, " : ", dt)

                        local pathInfo = actionState.path
                        if not pathInfo then
                            --mj:error("no path info:", sapien.uniqueID, " sharedState:", sapien.sharedState, " actionState:", actionState, " order:", order.types[orderState.orderTypeIndex].name, " activeSequence:", activeSequence.key)
                            actionCompleted = true
                            removeTemporaryOrderObjectIfActionSequenceComplete()
                            serverGOM:testAndUpdateCoveredStatusIfNeeded(sapien)
                        else
                            local nodes = pathInfo.nodes

                            local function updateHaulObjectPos(snapToFinalPos)

                                if sapien.sharedState.seatObjectID == sapien.sharedState.haulingObjectID then -- don't update the canoe pos if we are riding it, that can be handled elsewhere
                                    return
                                end

                                local distanceMeters = 2.0
                                if snapToFinalPos then
                                    distanceMeters = 0.5
                                end
                                local distanceVec = orderObject.pos - sapien.pos
                                local len = length(distanceVec)

                                local directionNormal = nil
                                
                                if len > mj:mToP(0.0001) then
                                    directionNormal = distanceVec / len
                                else
                                    directionNormal = -mat3GetRow(sapien.rotation, 2)
                                end
                                
                                local newHaulObjectPos = sapien.pos + directionNormal * mj:mToP(distanceMeters)

                                local clampToSeaLevel = true
                                local wasClampedToSeaLevel = false
                                newHaulObjectPos, wasClampedToSeaLevel = worldHelper:getBelowSurfacePos(newHaulObjectPos, 1.0, physicsSets.walkable, nil, clampToSeaLevel)
                                local newHaulObjectPosLength = length(newHaulObjectPos)
                                local newPosNormal = newHaulObjectPos / newHaulObjectPosLength


                                local leftVector = normalize(cross(newPosNormal, directionNormal))
                                local terrrainNormal = newPosNormal
                                if wasClampedToSeaLevel then
                                    newHaulObjectPos = newPosNormal
                                    if gameObject.types[orderObject.objectTypeIndex].rideWaterPathFindingDifficulty  then
                                        orderObject.sharedState:set("waterRideable", true)
                                        serverGOM:addObjectToSet(orderObject, serverGOM.objectSets.waterRideableObjects)
                                    end
                                else
                                    terrrainNormal = worldHelper:getWalkableUpVector(newPosNormal)
                                    if gameObject.types[orderObject.objectTypeIndex].rideWaterPathFindingDifficulty  then
                                        orderObject.sharedState:remove("waterRideable")
                                        serverGOM:removeObjectFromSet(orderObject, serverGOM.objectSets.waterRideableObjects)
                                    end
                                end

                                --mj:log("set haul object rotation terrrainNormal:", terrrainNormal)

                                --orderObject.rotation = mat3LookAtInverse(leftVector, terrrainNormal)
                                orderObject.rotation = mjm.createUpAlignedRotationMatrix(terrrainNormal, leftVector)
                                --mj:log("orderObject.rotation:", orderObject.rotation)

                                --mj:log("set haul drag object pos:", newHaulObjectPos)
                                if snapToFinalPos then
                                    serverGOM:moveObjectIntoFormationWithOthersOfSameType(orderObject, newHaulObjectPos, true)
                                else
                                    serverGOM:setPos(orderObject.uniqueID, newHaulObjectPos, false)
                                end
                                
                                serverGOM:testAndUpdateCoveredStatusIfNeeded(orderObject)
                                serverResourceManager:updateResourcesForObject(orderObject)
                                if gameObject.types[orderObject.objectTypeIndex].isStorageArea then
                                    serverLogistics:updateMaintenceRequiredForConnectedObjects(orderObject.uniqueID)
                                end

                                if snapToFinalPos then
                                    serverGOM:sendSnapObjectMatrix(orderObject.uniqueID, true)
                                end
                            end

                            local function goalReached()
                                --disabled--mj:objectLog(sapien.uniqueID, "goal reached")
                                if not pathInfo.complete then
                                    local nodeCount = 0
                                    if nodes then
                                        nodeCount = #nodes
                                    end
                                    mj:log("Sapien has no complete path but has reached path end. Requesting again and waiting... :", sapien.uniqueID, " actionState.pathNodeIndex:", actionState.pathNodeIndex, " nodeCount:", nodeCount)
                                -- mj:log("nodes:", nodes)
                                -- mj:log(sapien.sharedState)

                                    serverSapien:requestPathUpdateIfNotRequested(sapien)
                                else
                                    --mj:log(sapien.uniqueID, ": g")
                                    actionCompleted = true
                                    removeTemporaryOrderObjectIfActionSequenceComplete()
                                    serverGOM:testAndUpdateCoveredStatusIfNeeded(sapien)

                                    if orderState.orderTypeIndex == order.types.haulMoveToObject.index then
                                        --if (not orderObject.sharedState.haulingSapienID) then
                                            serverSapien:setHaulDragingObject(sapien, orderObject)
                                        --end
                                    elseif orderState.orderTypeIndex == order.types.haulDragObject.index or orderState.orderTypeIndex == order.types.haulRideObject.index then
                                        serverSapien:setHaulDragingObject(sapien, nil)
                                        planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sharedState.tribeID)
                                        updateHaulObjectPos(true)
                                    end
                                end
                            end
                            
                            if actionState.pathNodeIndex > #nodes then
                                goalReached()
                            else

                                local newPos = sapien.pos
                                --local newPosNormal = normalize(newPos)
                                local node = nodes[actionState.pathNodeIndex]
                                if node.rideObjectID and node.rideObjectID == sapien.sharedState.seatObjectID then --offset our base pos to the riding object's position
                                    local rideObject = serverGOM:getObjectWithID(node.rideObjectID)
                                    newPos = rideObject.pos
                                end
                                local difficultySpeedMultiplier = 1.0 / node.difficulty
                                local distanceRemainingToTravel = sapienConstants:getWalkSpeed(sapien.sharedState) * difficultySpeedMultiplier * action:combinedMoveSpeedMultiplier(currentActionTypeIndex, sharedState.actionModifiers) * dt * speedMultiplier

                                --disabled--mj:objectLog(sapien.uniqueID, "dt:", dt, " actionState.pathNodeIndex:", actionState.pathNodeIndex, " difficultySpeedMultiplier:", difficultySpeedMultiplier, " distanceRemainingToTravel:", distanceRemainingToTravel)

                                local function cancelAndLookAtObject(otherObject)
                                    cancel = true

                                    if otherObject then
                                        local lookAtPos = gameObject:getSapienLookAtPointForObject(otherObject)
                                        serverSapien:setLookAt(sapien, otherObject.uniqueID, lookAtPos)
                                    end
                                end

                                local needsToUpdatePos = false
                                local function moveTowardsNode(sanityCounterOrNil)
                                    node = nodes[actionState.pathNodeIndex]
                                    local moveToPos = node.pos
                                    local routeVec = moveToPos - newPos
                                    local distance2 = length2(routeVec)

                                    if distance2 < distanceRemainingToTravel * distanceRemainingToTravel then
                                        --disabled--mj:objectLog(sapien.uniqueID, ": a - distanceRemainingToTravel:", distanceRemainingToTravel, " distance2:", distance2, " pos altitude:", mj:pToM(length(newPos) - 1.0), " move to altitude:", mj:pToM(length(moveToPos) - 1.0))
                                        newPos = moveToPos
                                        if mj:isNan(newPos.x) then
                                            mj:error("nan found A moveToPos:", moveToPos, " routeVec:", routeVec, " distanceRemainingToTravel:", distanceRemainingToTravel)
                                        end
                                        if actionState.pathNodeIndex < #nodes and #nodes > 0 then
                                        --  if distance2 ~= 0 then
                                                sharedState:set("actionState", "pathNodeIndex", actionState.pathNodeIndex + 1)

                                                --todo update multitask

                                                local shouldRequestPathUpdate = false
                                                if not pathInfo.complete and actionState.pathNodeIndex >= (#nodes - 1) then --changed from (#nodes - 5) as I believe that would cause jumps as it was. May cause issues.
                                                    shouldRequestPathUpdate = true
                                                else
                                                    if pathInfo.goalPos then
                                                        local orderStatePathCreationInfo = orderState.pathInfo
                                                        local goalPosInfo = serverSapien:getGoalPosInfoForPathInfo(orderStatePathCreationInfo, sapien)
                                                        if goalPosInfo.shouldCancel then
                                                            --disabled--mj:objectLog(sapien.uniqueID, "cancel due to goalPosInfo")
                                                            cancel = true
                                                        else
                                                            if goalPosInfo.goalPos and length2(pathInfo.goalPos - goalPosInfo.goalPos) > maxGoalObjectMoveDistanceBeforePathRecalculation2 then
                                                                --mj:log(sapien.uniqueID, ": requesting update to path due to goal object movement, updated goalPosInfo:", goalPosInfo, " distance:", mj:pToM(length(pathInfo.goalPos - goalPosInfo.goalPos)))
                                                                shouldRequestPathUpdate = true
                                                                --disabled--mj:objectLog(sapien.uniqueID, "requesting update to path due to goal object movement")
                                                            end
                                                        end
                                                    end

                                                end

                                                local rideObject = nil
                                                local cancelAnySeatDueToPathNodeWithNoRideObject = false

                                                local newNode = nodes[actionState.pathNodeIndex]

                                                --mj:log("newNode:", newNode)
                                                if newNode then
                                                    if newNode.rideObjectID then
                                                        rideObject = serverGOM:getObjectWithID(newNode.rideObjectID)
                                                        if rideObject then
                                                            --mj:log("calling serverSeat:assignToSapien:", newNode.rideObjectID)
                                                            if not serverSeat:assignToSapien(rideObject, sapien, nil) then
                                                                cancel = true
                                                            end
                                                        else
                                                            cancel = true
                                                        end
                                                    elseif (not action:hasModifier(sapien.sharedState.actionModifiers, action.modifierTypes.sit.index)) then
                                                        cancelAnySeatDueToPathNodeWithNoRideObject = true
                                                    end
                                                end

                                                if not cancel then
                                                    if (not rideObject) then 
                                                        if cancelAnySeatDueToPathNodeWithNoRideObject or (not action:hasModifier(sapien.sharedState.actionModifiers, action.modifierTypes.sit.index)) then
                                                            serverSeat:removeAnyNodeAssignmentForSapien(sapien)
                                                        end
                                                    end

                                                    if shouldRequestPathUpdate then 
                                                        -- request path update from path end
                                                        
                                                        local lastActionTypeIndex = activeSequence.actions[#activeSequence.actions]
                                                        if lastActionTypeIndex == action.types.place.index or lastActionTypeIndex == action.types.throwProjectile.index or lastActionTypeIndex == action.types.placeMultiFromHeld.index then
                                                            if not findOrderAI:checkForMatchingHeldObjectDisposalForCurrentOrder(sapien) then
                                                                --disabled--mj:objectLog(sapien.uniqueID, "checkForMatchingHeldObjectDisposalForCurrentOrder returned false in move order path extension")
                                                                cancel = true
                                                            end
                                                        end

                                                        if not cancel then
                                                            --mj:log("requestPathUpdateIfNotRequested sapien.sharedState:", sapien.sharedState)
                                                        -- mj:log("orderType:", order.types[orderState.orderTypeIndex])
                                                            serverSapien:requestPathUpdateIfNotRequested(sapien)
                                                        end

                                                    else
                                                        local distanceTravelledToNodePos = 0.0
                                                        if distance2 > 0.0 then
                                                            distanceTravelledToNodePos = math.sqrt(distance2)
                                                        end
                                                        distanceRemainingToTravel = distanceRemainingToTravel - distanceTravelledToNodePos
                                                        if distanceRemainingToTravel > 0.0 then
                                                            if sanityCounterOrNil and sanityCounterOrNil > 10 then
                                                                mj:warn("sanityCounter > 10 in moveTowardsNode, sapiendID:", sapien.uniqueID)--, " sharedState:", sapien.sharedState)
                                                                --mj:error("sanityCounter > 5 in moveTowardsNode. distanceRemainingToTravel:", distanceRemainingToTravel, " distance2:", distance2, "distanceTravelledToNodePos:", distanceTravelledToNodePos)
                                                            else
                                                                moveTowardsNode((1 + (sanityCounterOrNil or 0)))
                                                            end
                                                        end

                                                        
                                                        serverSapien:setLookAt(sapien, nil, nodes[#nodes].pos)
                                                    end
                                                end
                                                
                                                --serverGOM:testAndUpdateCoveredStatusIfNeeded(sapien) --commented out 0.4 as an optimization. This is expensive.

                                        -- end
                                        else
                                            goalReached()
                                        end
                                        --newPos = worldHelper:getBelowSurfacePos(newPos, physicsSets.walkable)

                                        if orderObject and (not cancel) then
                                            if (orderState.orderTypeIndex == order.types.deliverObjectToConstructionObject.index or orderState.orderTypeIndex == order.types.deliverFuel.index) then
                                                if sapienInventory:objectCount(sapien, sapienInventory.locations.held.index) > 0 then
                                                    local lastHeldObjectInfo = sapienInventory:lastObjectInfo(sapien, sapienInventory.locations.held.index)
                                                    local constructionPlanState = nil
                                                    if orderState.orderTypeIndex == order.types.deliverObjectToConstructionObject.index then
                                                        constructionPlanState = planManager:getPlanSateForConstructionObject(orderObject, sapien.sharedState.tribeID)
                                                    end
                                                    if not serverGOM:objectTypeIndexIsRequiredForPlanObject(orderObject, lastHeldObjectInfo.objectTypeIndex, constructionPlanState, sapien.sharedState.tribeID) then
                                                        if not serverGOM:objectTypeIndexIsRequiredForMaintenanceObject(orderObject, lastHeldObjectInfo.objectTypeIndex, sapien.sharedState.tribeID) then
                                                            --disabled--mj:objectLog(sapien.uniqueID, "cancel due to object not being required")
                                                            cancelAndLookAtObject(orderObject)
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            --[[if not cancel then
                                                local planObjectSapienAssignmentInfo = serverSapienAI:planObjectSapienAssignmentInfoForOrderObject(sapien, orderObject, orderState.context, nil)
                                                if otherSapienID  then
                                                    --disabled--mj:objectLog(sapien.uniqueID, "cancel due to other sapien being assigned (", otherSapienID, ")")
                                                    local otherSapien = serverGOM:getObjectWithID(otherSapienID)
                                                    cancelAndLookAtObject(otherSapien)
                                                end
                                            end]]
                                        end
                                        --serverGOM:setPos(sapien.uniqueID, newPos, false)
                                        needsToUpdatePos = true
                                    else
                                        --disabled--mj:objectLog(sapien.uniqueID, "b")
                                        if distanceRemainingToTravel > 0.0 then
                                            local directionNormal = normalize(moveToPos - newPos)
                                            --disabled--mj:objectLog(sapien.uniqueID, "distanceRemainingToTravel > 0, directionNormal:", directionNormal)
                                            local movement = directionNormal * distanceRemainingToTravel
                                            newPos = newPos + movement

                                            --[[if mj:isNan(newPos.x) then
                                                mj:error("nan found B moveToPos:", moveToPos, " directionNormal:", directionNormal, " distanceRemainingToTravel:", distanceRemainingToTravel, " routeVec:", routeVec)
                                            end]]
                                            --newPosNormal = normalize(newPosNormal + movement)
                                            --newPos = worldHelper:getBelowSurfacePos(newPosNormal * length(newPos), physicsSets.walkable)
                                            local sapienNormal = normalize(newPos)
                                            local dp = dot(sapienNormal, directionNormal)
                                            if dp > -0.9 and dp < 0.9 then
                                                local rotation = createUpAlignedRotationMatrix(sapienNormal, directionNormal)
                                                
                                               --[[ if mj:isNan(rotation.m0) then
                                                    mj:error("rotation is nan")
                                                    error()
                                                end
                                                if mjm.dot(mat3GetRow(rotation, 1), sapien.normalizedPos) < 0.99 then
                                                    mj:error("rotation is not up orientated")
                                                    error()
                                                end]]
                                                
                                                serverGOM:setRotation(sapien.uniqueID, rotation)
                                            end
                                            needsToUpdatePos = true
                                        end
                                        --sapien.pos = newPos
                                        --sapien.normalizedPos = normalize(newPos)
                                    end
                                end

                                moveTowardsNode()

                                if needsToUpdatePos then
                                    serverGOM:setPos(sapien.uniqueID, newPos, false)

                                    if orderState.orderTypeIndex == order.types.haulDragObject.index or orderState.orderTypeIndex == order.types.haulRideObject.index then
                                        updateHaulObjectPos(false)
                                    end

                                    if sharedState.seatObjectID then
                                        serverSeat:updateTransformForSeatObjectForRidingSapien(sapien)
                                    end
                                end
                                        
                                --[[local oldHeight = length(sapien.pos)
                                local newHeight = length(newPos)
                                local heightDifferenceMeters = mj:pToM(newHeight - oldHeight)
                                if heightDifferenceMeters > 0.5 then
                                    mj:error("setting height to > 0.5 meters above:", sapien.uniqueID, " sapien.sharedState:", sapien.sharedState, " sapien.pos:", sapien.pos, " newPos:", newPos)
                                end]]
                    
                                --serverGOM:setPos(sapien.uniqueID, newPos, false)
                            end
                        end
                    elseif currentActionTypeIndex == action.types.wave.index then
                        --disabled--mj:objectLog(sapien.uniqueID, "wave:", privateState.actionStateTimer, " orderObject:", orderObject)
                        local newTimerValue = privateState.actionStateTimer + dt * speedMultiplier
                        privateState.actionStateTimer = newTimerValue
                        if privateState.actionStateTimer > 1.5 then
                            --disabled--mj:objectLog(sapien.uniqueID, "wave complete")
                            actionCompleted = true
                        end
                    elseif currentActionTypeIndex == action.types.sleep.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 5.0 then

                            local traitState = sharedState.traits
                            local sleepTraitInfluence = sapienTrait:getInfluence(traitState, sapienTrait.influenceTypes.sleep.index)

                            local sleepNeedTraitMultiplier = math.pow(2.0, sleepTraitInfluence * sapienTrait.sleepInfluenceOnSleepNeedWhileSleepingDecrement)
                            
                            --disabled--mj:objectLog(sapien.uniqueID, "decreasing sleep need with sleepNeedTraitMultiplier:", sleepNeedTraitMultiplier)
                        
                            local newSleep = sharedState.needs[need.types.sleep.index] - ((privateState.actionStateTimer * sleepNeedTraitMultiplier) / (serverWorld:getDayLength() * 0.5))
                            privateState.actionStateTimer = privateState.actionStateTimer - 5.0
                            if newSleep < 0.01 then
                                newSleep = 0.0
                            end
                            sharedState:set("needs", need.types.sleep.index, newSleep)
                            
                            local wakeDesire = desire:getWake(sapien, serverWorld:getTimeOfDayFraction(sapien.pos))
                            if wakeDesire >= desire.levels.moderate then
                                --disabled--mj:objectLog(sapien.uniqueID, "sleep completed due to wake desire:", sapien.uniqueID)
                                actionCompleted = true

                                if orderState.objectID then
                                    serverSapien:offsetSapienOwnershipOfObject(sapien, orderState.objectID, 1.0)
                                end
                            end

                            saveStateChange = true
                        end
                    elseif currentActionTypeIndex == action.types.turn.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 0.5 then
                            actionCompleted = true
                        end
                    elseif currentActionTypeIndex == action.types.fall.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 4.0 then
                            actionCompleted = true
                            if orderState.context and orderState.context.targetPos then
                                serverGOM:setPos(sapien.uniqueID, orderState.context.targetPos, false)
                            end
                        else
                            local mixFraction = mjm.clamp(privateState.actionStateTimer, 0.0, 1.0)
                            if orderState.context and orderState.context.targetPos then
                                local newPos = mjm.mix(orderState.context.startPos, orderState.context.targetPos, mixFraction)
                                serverGOM:setPos(sapien.uniqueID, newPos, false)
                            end
                        end
                    elseif currentActionTypeIndex == action.types.destroyContents.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 1.0 then
                            actionCompleted = true
                            local objectInfo = serverStorageArea:destroyObjectInStorageArea(orderObject.uniqueID)
                            if objectInfo then
                                serverTribeAIPlayer:addGrievanceIfNeededForObjectDestruction(orderObject.sharedState.tribeID, sharedState.tribeID, objectInfo.objectTypeIndex)
                            end
                            --actionCompleted = true
                            --serverCampfire:setLit(orderObject, false, sapien.sharedState.tribeID)
                           -- planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sharedState.tribeID)
                        end
                    elseif currentActionTypeIndex == action.types.inspect.index then
                        if orderState.context.planTypeIndex == plan.types.research.index then --todo better animations and stuff
                            local discoveryCraftableTypeIndex = orderState.context.discoveryCraftableTypeIndex
                            if orderObject and not discoveryCraftableTypeIndex then
                                local objectSharedState = orderObject.sharedState
                                local constructableType = nil
                                if objectSharedState.inProgressConstructableTypeIndex then
                                    constructableType = constructable.types[objectSharedState.inProgressConstructableTypeIndex]
                                end

                                if constructableType and constructableType.disabledUntilCraftableResearched then
                                    discoveryCraftableTypeIndex = constructableType.index
                                end
                            end
                            actionCompleted = addToResearch(sapien, actionState, dt, speedMultiplier, orderObject, orderState, orderState.context.researchTypeIndex, discoveryCraftableTypeIndex)
                        end
                    elseif currentActionTypeIndex == action.types.pullOut.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 4.0 then
                            actionCompleted = true
                            local addStoreOrders = true
                            
                            local existingPlanContext = getPlanOrderIndexAndPriority(sharedState.tribeID, orderObject, orderState)
                            serverGOM:removeGameObjectAndDropInventory(orderObject.uniqueID, sharedState.tribeID, addStoreOrders, sapien, existingPlanContext.planOrderIndex, existingPlanContext.planPriorityOffset, existingPlanContext.manuallyPrioritized)
                            serverTribeAIPlayer:addGrievanceIfNeededForObjectDestruction(orderObject.sharedState.tribeID, sharedState.tribeID, orderObject.objectTypeIndex)
                        end
                    elseif currentActionTypeIndex == action.types.gather.index or currentActionTypeIndex == action.types.gatherBush.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 4.0 then
                            if not orderObject then
                                --disabled--mj:objectLog(sapien.uniqueID, "cancel due to no order object")
                                cancel = true
                            else
                                privateState.actionStateTimer = 0.0
                                saveStateChange = true


                                local objectState = orderObject.sharedState
                                local orderGameObjectType = gameObject.types[orderObject.objectTypeIndex]
                                local revertToSeedlingGatherResourceCounts = orderGameObjectType.revertToSeedlingGatherResourceCounts
                                if revertToSeedlingGatherResourceCounts then
                                    local lastOutputID = nil
                                   -- local firstObjectTypeIndex = gameObject.types[orderObject.objectTypeIndex].gatherableTypes[1]
                                    local existingPlanContext = getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState)
                                    local totalTakenCount = 0
                                    local lastObjectTypeIndex = nil

                                    for objectTypeIndex,count in pairs(revertToSeedlingGatherResourceCounts) do
                                        for i=1,count do
                                            lastOutputID = serverGOM:createOutput(sapien.pos, 1.0, objectTypeIndex, nil, sharedState.tribeID, plan.types.storeObject.index, existingPlanContext)
                                        end
                                        lastObjectTypeIndex = objectTypeIndex
                                        totalTakenCount = totalTakenCount + count
                                    end

                                    serverTribeAIPlayer:addGrievanceIfNeededForResourceTaken(orderObject.sharedState.tribeID, sapien.sharedState.tribeID, gameObject.types[lastObjectTypeIndex].resourceTypeIndex, lastObjectTypeIndex, totalTakenCount)

                                    
                                    serverGOM:decreaseSoilFertilityForObjectHarvest(orderObject, 0.5)
                                    actionCompleted = true
                                    planManager:removePlanStateForObject(orderObject, plan.types.gather.index, nil, nil, sharedState.tribeID)
                                    serverFlora:revertToSaplingForHarvest(orderObject)
                                    serverResourceManager:updateResourcesForObject(orderObject)
                                    
                                    if lastOutputID then
                                        local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                                        if lastOutputObject then
                                            serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                                        end
                                    end
                                else

                                    local objectTypeIndex = orderState.context.objectTypeIndex
                                    local inventory = objectState.inventory
                                    local countsByObjectType = inventory.countsByObjectType

                                    if not objectTypeIndex then
                                        local highestCount = 0

                                        local gatherableTypes = gameObject.types[orderObject.objectTypeIndex].gatherableTypes
                                        if gatherableTypes and gatherableTypes[1] then
                                            local randomStartOffset = 0
                                            if gatherableTypes[2] then
                                                randomStartOffset = rng:randomInteger(#gatherableTypes)
                                            end

                                            for i=1,#gatherableTypes do
                                                local offsetIndex = (((i - 1) + randomStartOffset) % #gatherableTypes) + 1
                                                local inventoryObjectTypeIndex = gatherableTypes[offsetIndex]
                                                local availableCount = countsByObjectType[inventoryObjectTypeIndex]
                                                if availableCount and availableCount > highestCount then
                                                    highestCount = availableCount
                                                    objectTypeIndex = inventoryObjectTypeIndex
                                                end
                                            end
                                        end

                                        --[[for inventoryObjectTypeIndex,inventoryCount in pairs(countsByObjectType) do
                                            if inventoryCount > 0 then
                                                if inventoryCount > highestCount or (inventoryCount == highestCount and rng:randomBool()) then --make it a little random
                                                    highestCount = inventoryCount
                                                    objectTypeIndex = inventoryObjectTypeIndex
                                                end
                                            end
                                        end]]
                                    end

                                    local resourceDepleted = false

                                    if countsByObjectType[objectTypeIndex] and countsByObjectType[objectTypeIndex] > 0 then
                                        local resourceCount = countsByObjectType[objectTypeIndex]

                                        local minQuantityToKeep = 0
                                        if orderGameObjectType.gatherKeepMinQuantity and orderGameObjectType.gatherKeepMinQuantity[objectTypeIndex] then
                                            minQuantityToKeep = orderGameObjectType.gatherKeepMinQuantity[objectTypeIndex]
                                        end

                                        --mj:log("minQuantityToKeep:", minQuantityToKeep, " orderGameObjectType.gatherKeepMinQuantity:", orderGameObjectType.gatherKeepMinQuantity)
                                        
                                        resourceCount = resourceCount - minQuantityToKeep

                                        if resourceCount > 0 then
                                            local existingPlanContext = getPlanOrderIndexAndPriority(sapien.sharedState.tribeID, orderObject, orderState)

                                            local objectInfo = serverGOM:removeGatherObjectFromInventory(orderObject, objectTypeIndex)
                                            serverResourceManager:updateResourcesForObject(orderObject)
                                            planManager:updateAnyPlansForInventoryGatherRemoval(orderObject)
                                            
                                            local lastOutputID = serverGOM:createOutput(sapien.pos, 1.0, objectInfo.objectTypeIndex, nil, sharedState.tribeID, plan.types.storeObject.index, existingPlanContext)


                                            if actionState.harvestCount then
                                                sharedState:set("actionState", "harvestCount", actionState.harvestCount + 1)
                                            else
                                                sharedState:set("actionState", "harvestCount", 1)
                                            end

                                            resourceCount = (countsByObjectType[objectTypeIndex] or 0) - minQuantityToKeep

                                            if resourceCount <= 0 then
                                                resourceDepleted = true
                                            else
                                                if not gameConstants.debugInfiniteGather then
                                                    if orderState.context.requiredCount and orderState.context.requiredCount <= actionState.harvestCount then
                                                        resourceDepleted = true
                                                    end
                                                end
                                            end
                                            
                                            serverGOM:decreaseSoilFertilityForObjectHarvest(orderObject, 0.25)
                                            
                                            if lastOutputID then
                                                local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                                                if lastOutputObject then
                                                    serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                                                end -- takenFromObjectTribeID, takerSapienTribeID, takenResourceTypeIndex, takenObjectTypeIndex, countTaken
                                                serverTribeAIPlayer:addGrievanceIfNeededForResourceTaken(orderObject.sharedState.tribeID, 
                                                sapien.sharedState.tribeID, 
                                                gameObject.types[objectInfo.objectTypeIndex].resourceTypeIndex, 
                                                objectInfo.objectTypeIndex,
                                                1)

                                            end
                                        else
                                            resourceDepleted = true
                                        end
                                    else
                                        resourceDepleted = true
                                    end

                                    if resourceDepleted then
                                        if orderState.context.objectTypeIndex then
                                            actionCompleted = true
                                        else
                                            local foundAnyResource = false
                                            local gatherableTypes = gameObject.types[orderObject.objectTypeIndex].gatherableTypes
                                            if gatherableTypes then
                                                for i,gatherableObjectTypeIndex in ipairs(gatherableTypes) do
                                                    local thisCount = countsByObjectType[gatherableObjectTypeIndex]
                                                    if thisCount then
                                                        if orderGameObjectType.gatherKeepMinQuantity and orderGameObjectType.gatherKeepMinQuantity[objectTypeIndex] then
                                                            local minQuantityToKeep = orderGameObjectType.gatherKeepMinQuantity[objectTypeIndex]
                                                            thisCount = thisCount - minQuantityToKeep
                                                        end
                                                        if thisCount > 0 then
                                                            foundAnyResource = true
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                            if not foundAnyResource then
                                                actionCompleted = true
                                            end
                                        end
                                    end


                                    if actionCompleted then
                                        planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, orderState.context.objectTypeIndex, nil, sharedState.tribeID)
                                    end
                                end
                            end

                        end
                    elseif currentActionTypeIndex == action.types.pickup.index or currentActionTypeIndex == action.types.pickupMultiCrouch.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 0.35 then
                            if not orderObject then
                                mj:error("no orderObject in pickup. sapien id:", sapien.uniqueID, " sapienSharedState:", sapien.sharedState)
                                cancel = true
                            else
                                local orderObjectID = orderObject.uniqueID

                                --disabled--mj:objectLog(sapien.uniqueID, "picking up item:", orderObjectID)

                                local planStateToSave = nil
                                if orderObject.sharedState and orderObject.sharedState.planStates then
                                    local planStatesForTribe = orderObject.sharedState.planStates[sharedState.tribeID]
                                    if planStatesForTribe then
                                        for i,planState in ipairs(planStatesForTribe) do
                                            if orderState.context.planTypeIndex == planState.planTypeIndex then
                                                planStateToSave = planState
                                            end
                                        end
                                    end
                                end

                                local objectOrderContext = {
                                    orderTypeIndex = orderState.orderTypeIndex,
                                    planState = planStateToSave,
                                }

                                if orderState.context then
                                    objectOrderContext.planObjectID = orderState.context.planObjectID
                                end

                                if gameObject.types[orderObject.objectTypeIndex].isStorageArea then

                                    --disabled--mj:objectLog(sapien.uniqueID, "picking up item from storage area")
                                    local storageAreaTransferInfo = orderState.context.storageAreaTransferInfo
                                    objectOrderContext.storageAreaTransferInfo = storageAreaTransferInfo

                                    local removeObjectTypeIndexOrNil = orderState.context.objectTypeIndex
                                    local tribeIDForPermissions = sharedState.tribeID
                                    local objectRemoved = false

                                    local maxCarryCount = 0
                                    local carryObjectTypeIndex = removeObjectTypeIndexOrNil
                                    --disabled--mj:objectLog(sapien.uniqueID, "removeObjectTypeIndexOrNil:", removeObjectTypeIndexOrNil, " orderState.context:", orderState.context)
                                    if not carryObjectTypeIndex then
                                        local objects = orderObject.sharedState.inventory and orderObject.sharedState.inventory.objects
                                        if objects[1] then
                                            carryObjectTypeIndex = objects[#objects].objectTypeIndex
                                        end
                                    end
                                    --disabled--mj:objectLog(sapien.uniqueID, "carryObjectTypeIndex:", carryObjectTypeIndex)
                                    if carryObjectTypeIndex then
                                        maxCarryCount = storage:maxCarryCountForResourceType(gameObject.types[carryObjectTypeIndex].resourceTypeIndex)
                                    end
                                    local heldObjectCount = sapienInventory:objectCount(sapien, sapienInventory.locations.held.index)
                                    
                                    --disabled--mj:objectLog(sapien.uniqueID, "gameObject.types[carryObjectTypeIndex].resourceTypeIndex:", gameObject.types[carryObjectTypeIndex].resourceTypeIndex)
                                    --disabled--mj:objectLog(sapien.uniqueID, "heldObjectCount:", heldObjectCount)
                                    --disabled--mj:objectLog(sapien.uniqueID, "maxCarryCount:", maxCarryCount)

                                    local pickedUpCount = 0
                                    if maxCarryCount > heldObjectCount then
                                        local pickupCount = maxCarryCount - heldObjectCount
                                        if not storageAreaTransferInfo then
                                            pickupCount = 1 --for now, only support picking up multiple at once for transfer orders. We could check here if build orders need more in the future.
                                        end

                                        --disabled--mj:objectLog(sapien.uniqueID, "pickupCount:", pickupCount)
                                        for i=1,pickupCount do
                                            local abortDueToNoLongerRequired = false
                                            if storageAreaTransferInfo then
                                                abortDueToNoLongerRequired = true
                                                local nextTransferInfo = serverStorageArea:storageAreaTransferInfoIfRequiresPickup(sharedState.tribeID, orderObject, sapien.uniqueID)
                                                if nextTransferInfo and 
                                                nextTransferInfo.resourceTypeIndex == storageAreaTransferInfo.resourceTypeIndex and 
                                                nextTransferInfo.destinationObjectID == storageAreaTransferInfo.destinationObjectID and 
                                                ((not nextTransferInfo.destinationCapacity) or (nextTransferInfo.destinationCapacity > pickedUpCount)) then
                                                    abortDueToNoLongerRequired = false
                                                end

                                                --[[if not serverStorageArea:storageAreaTransferInfoIfRequiresPickup(sharedState.tribeID, orderObject, sapien.uniqueID) then
                                                    abortDueToNoLongerRequired = true
                                                end]]
                                            end

    
                                            if not abortDueToNoLongerRequired then
    
                                                local objectInfo = serverStorageArea:removeObjectFromStorageArea(orderObjectID, removeObjectTypeIndexOrNil, tribeIDForPermissions) --calls serverTribeAIPlayer:addGrievanceIfNeeded
                                                --disabled--mj:objectLog(sapien.uniqueID, "objectInfo:", objectInfo)
                                                if objectInfo then
                                                    --disabled--mj:objectLog(sapien.uniqueID, "add object info:", objectInfo)
                                                    serverSapienInventory:addObjectFromInventory(sapien, objectInfo, sapienInventory.locations.held.index, objectOrderContext)
                                                    objectRemoved = true
                                                    pickedUpCount = pickedUpCount + 1
                                                end
                                            end
                                        end
                                    end

                                    local removePlanObjectState = false
                                    serverSapien:removeAssignedStatusFromObjectIfBelongingToSapien(orderObjectID, sapien, orderState, removePlanObjectState)

                                    if objectRemoved then
                                        if orderState.context.planObjectID == orderObjectID then
                                            local removed = false

                                            if (not orderObject.sharedState.inventory) or (not orderObject.sharedState.inventory.objects) or #orderObject.sharedState.inventory.objects == 0 then
                                                local deconstructPlanState = planManager:getPlanStateForObject(orderObject, plan.types.deconstruct.index, nil, nil, sharedState.tribeID, nil)
                                                if deconstructPlanState then
                                                    serverGOM:removeGameObject(orderObjectID)
                                                    removed = true
                                                end
                                            end

                                            if (not removed) and (orderState.context.planTypeIndex ~= plan.types.deconstruct.index) then
                                                planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, orderState.context.researchTypeIndex, sharedState.tribeID)
                                            end
                                        end
                                    end
                                elseif orderObject.objectTypeIndex == gameObject.types.compostBin.index then
                                    local objectInfo = serverCompostBin:removeObjectFromCompostBin(orderObjectID)
                                    if objectInfo then
                                        serverSapienInventory:addObjectFromInventory(sapien, objectInfo, sapienInventory.locations.held.index, objectOrderContext)
                                    end
                                    local removePlanObjectState = false
                                    serverSapien:removeAssignedStatusFromObjectIfBelongingToSapien(orderObjectID, sapien, orderState, removePlanObjectState)
                                    serverCompostBin:checkForEmptyAndUpdatePlans(orderObject)

                                    --[[if (not orderObject.sharedState.inventory) or (not orderObject.sharedState.inventory.objects) or #orderObject.sharedState.inventory.objects == 0 then
                                        if orderState.context.planTypeIndex == plan.types.deconstruct.index then
                                            planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, orderState.context.researchTypeIndex, sharedState.tribeID)
                                            planManager:addDeconstructPlanForEmptyConstructedObject(sharedState.tribeID, orderObject)
                                        elseif orderState.context.planTypeIndex == plan.types.rebuild.index then
                                            planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, orderState.context.researchTypeIndex, sharedState.tribeID)
                                            planManager:addRebuildPlanForEmptyConstructedObject(sharedState.tribeID, orderObject, objectOrderContext.planState.rebuildConstructableTypeIndex, 
                                            objectOrderContext.planState.rebuildRestrictedResourceObjectTypes, objectOrderContext.planState.rebuildRestrictedToolObjectTypes)
                                        end
                                    end]]

                                elseif gameObject.types[orderObject.objectTypeIndex].isCraftArea then
                                    local objectTypeIndex = orderState.context.objectTypeIndex
                                    local inventoryLocation = orderState.context.inventoryLocation
                                    local objectInfo = serverCraftArea:removeObjectFromCraftAreaWithObjectTypeIndex(orderObjectID, objectTypeIndex, inventoryLocation)
                                    if objectInfo then
                                        serverSapienInventory:addObjectFromInventory(sapien, objectInfo, sapienInventory.locations.held.index, objectOrderContext)
                                    end
                                    local removePlanObjectState = false
                                    serverSapien:removeAssignedStatusFromObjectIfBelongingToSapien(orderObjectID, sapien, orderState, removePlanObjectState)
                                elseif gameObject.types[orderObject.objectTypeIndex].isInProgressBuildObject then
                                    local objectTypeIndex = orderState.context.objectTypeIndex
                                    local inventoryLocation = orderState.context.inventoryLocation
                                    local objectInfo = serverGOM:removeObjectFromInProgressBuildObjectWithObjectTypeIndex(orderObjectID, objectTypeIndex, inventoryLocation)
                                    if objectInfo then
                                        serverSapienInventory:addObjectFromInventory(sapien, objectInfo, sapienInventory.locations.held.index, objectOrderContext)
                                        serverTribeAIPlayer:addGrievanceIfNeededForObjectDestruction(orderObject.sharedState.tribeID, sharedState.tribeID, orderObject.objectTypeIndex)
                                    end
                                    local removePlanObjectState = false
                                    serverSapien:removeAssignedStatusFromObjectIfBelongingToSapien(orderObjectID, sapien, orderState, removePlanObjectState)
                                else
                                    if orderObject.sharedState and orderObject.sharedState.orderContext then
                                        objectOrderContext.storageAreaTransferInfo = orderObject.sharedState.orderContext.storageAreaTransferInfo
                                        if orderObject.sharedState.orderContext.planObjectID and ((not orderState.context.planObjectID) or orderState.context.planObjectID == orderObjectID) then
                                            objectOrderContext.planObjectID = orderObject.sharedState.orderContext.planObjectID
                                        end
                                    end 
                                    serverSapienInventory:addObject(sapien, orderObject, sapienInventory.locations.held.index, objectOrderContext)
                                    serverGOM:removeGameObject(orderObjectID)
                                end

                               -- mj:log("pick up objectOrderContext:", objectOrderContext, " orderState.context:", orderState.context)

                                if objectOrderContext.planState and objectOrderContext.planState.planTypeIndex == plan.types.research.index then
                                    local researchTypeIndex = objectOrderContext.planState.researchTypeIndex
                                    if objectOrderContext.planState.discoveryCraftableTypeIndex and serverWorld:discoveryIsCompleteForTribe(sharedState.tribeID, researchTypeIndex) then
                                        serverWorld:startCraftableDiscoveryForTribe(sharedState.tribeID, objectOrderContext.planState.discoveryCraftableTypeIndex, sapien.uniqueID)
                                    else
                                        serverWorld:startDiscoveryForTribe(sharedState.tribeID, researchTypeIndex, sapien.uniqueID)
                                    end
                                end

                                ----disabled--mj:objectLog(sapien.uniqueID, "object picked up orderState.context:", orderState.context)
                                
                                if orderState.context and orderState.context.planObjectID then
                                    local cooldowns = serverSapienAI.aiStates[sapien.uniqueID].cooldowns
                                    if cooldowns then
                                        cooldowns["plan_" .. orderState.context.planObjectID] = nil
                                        cooldowns["m_" .. orderState.context.planObjectID] = nil
                                        ----disabled--mj:objectLog(sapien.uniqueID, "removed cooldown. cooldowns:", cooldowns)
                                    end
                                    if orderState.context.planObjectID == orderObjectID then
                                        sharedState:remove("orderQueue", 1, "context", "planObjectID") --set to nil so it doesn't cancel above when the object disappears
                                    end
                                end
                                sharedState:remove("orderQueue", 1, "objectID") --set to nil so it doesn't try to reload the object when the object disappears 

                                saveStateChange = true
                                actionCompleted = true
                            end
                        end
                    elseif currentActionTypeIndex == action.types.pickupMultiAddToHeld.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 0.15 then
                            actionCompleted = true
                        end
                    elseif currentActionTypeIndex == action.types.throwProjectileFollowThrough.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 2.0 then
                            actionCompleted = true
                        end
                    elseif currentActionTypeIndex == action.types.placeMultiCrouch.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 0.55 then
                            actionCompleted = true
                        end
                    elseif currentActionTypeIndex == action.types.eat.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 4.0 then

                            if sapienInventory:objectCount(sapien, sapienInventory.locations.held.index) > 0 then
                                local objectInfo = sapienInventory:lastObjectInfo(sapien, sapienInventory.locations.held.index)
                                if objectInfo then
                                    local gameObjectType = gameObject.types[objectInfo.objectTypeIndex]
                                    local resourceType = resource.types[gameObjectType.resourceTypeIndex]
                                    local foodValue = resourceType.foodValue
                                    if foodValue then
                                        local shouldRemove = true
                                        local totalPortionCount = resource:getFoodPortionCount(objectInfo.objectTypeIndex)
                                        if totalPortionCount then
                                            local usedPortionCount = (objectInfo.usedPortionCount or 0) + 1
                                            if usedPortionCount < totalPortionCount then
                                                shouldRemove = false
                                                serverSapienInventory:changeLastObjectState(sapien, sapienInventory.locations.held.index, "usedPortionCount", usedPortionCount)
                                            end
                                        end

                                        local lastOutputID = nil
                                        if shouldRemove then
                                            serverSapienInventory:removeObject(sapien, sapienInventory.locations.held.index)
                                            if gameObjectType.eatByProducts then
                                                for i, byProductObjectTypeIndex in ipairs(gameObjectType.eatByProducts) do
                                                    lastOutputID = serverGOM:createOutput(sapien.pos, 1.0, byProductObjectTypeIndex, nil, sharedState.tribeID, plan.types.storeObject.index, nil)
                                                end
                                            end
                                        end

                                        local contaminationResourceTypeIndex = objectInfo.contaminationResourceTypeIndex

                                        checkForFoodPoisoning(sapien, resourceType.index, contaminationResourceTypeIndex)

                                        sharedState:set("needs", need.types.food.index, sharedState.needs[need.types.food.index] - foodValue)
                                        
                                        serverStatusEffects:removeEffect(sapien.sharedState, statusEffect.types.hungry.index)
                                        
                                        local notified = false
                                        if statusEffect:hasEffect(sharedState, statusEffect.types.starving.index) then
                                            serverStatusEffects:removeEffect(sapien.sharedState, statusEffect.types.starving.index)
                                            serverGOM:sendNotificationForObject(sapien, notification.types.starvingRemoved.index, nil, sapien.sharedState.tribeID)
                                            notified = true
                                        end

                                        if statusEffect:hasEffect(sharedState, statusEffect.types.veryHungry.index) then
                                            serverStatusEffects:removeEffect(sapien.sharedState, statusEffect.types.veryHungry.index)
                                            if not notified then
                                                serverGOM:sendNotificationForObject(sapien, notification.types.veryHungryRemoved.index, nil, sapien.sharedState.tribeID)
                                            end
                                        end

                                        serverStatusEffects:setTimedEffect(sharedState, statusEffect.types.justAte.index, foodValue * 50.0)
                                        
                                        if lastOutputID then
                                            local lastOutputObject = serverGOM:getObjectWithID(lastOutputID)
                                            if lastOutputObject then
                                                serverSapien:setLookAt(sapien, lastOutputID, lastOutputObject.pos)
                                            end
                                        end
                                    end
                                end
                            end

                            actionCompleted = true
                        end
                    elseif currentActionTypeIndex == action.types.recruit.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier

                        local function completeRecruit()
                            serverSapien:recruitComplete(orderObject, sharedState.tribeID)
                            planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sharedState.tribeID)
                        end
                        
                        if privateState.actionStateTimer > 10.0 then
                            if not skill:hasSkill(sapien, skill.types.diplomacy.index) then --todo, have the skill influence the outcome
                                if orderState.context.planTypeIndex == plan.types.research.index then
                                    local researchProvidesSkillTypeIndex = research.types[orderState.context.researchTypeIndex].skillTypeIndex
                                    serverSapienSkills:addToSkill(sapien, researchProvidesSkillTypeIndex, orderState.context.researchTypeIndex, orderState.context.discoveryCraftableTypeIndex, privateState.actionStateTimer)
                                    if not skill:hasSkill(sapien, researchProvidesSkillTypeIndex) then
                                        checkForReserachNearlyComplete(sapien, orderState.context.researchTypeIndex, privateState.actionStateTimer)
                                    end
                                else
                                    addToSkillForOrder(sapien, orderObject, orderState.orderTypeIndex)
                                end

                            end

                            completeRecruit()

                            privateState.actionStateTimer = 0.0 
                            actionCompleted = true
                        end
                    elseif currentActionTypeIndex == action.types.greet.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 4.0 then
                            serverTribe:completeGreetAction(orderObject, sapien)

                            planManager:removePlanStateForObject(orderObject, orderState.context.planTypeIndex, nil, nil, sharedState.tribeID)
                            
                            privateState.actionStateTimer = 0.0 
                            actionCompleted = true
                        end
                        
                    elseif currentActionTypeIndex == action.types.sit.index then
                        privateState.actionStateTimer = privateState.actionStateTimer + dt * speedMultiplier
                        if privateState.actionStateTimer > 8.0 then
                            actionCompleted = true
                        end
                    else
                        --mj:warn("unhandled action:", action.types[currentActionTypeIndex].key)
                        actionCompleted = true
                    end
                end


                if actionCompleted then
                    saveStateChange = true

                    if orderObject then
                        local orderObjectReloaded = serverGOM:getObjectWithID(orderObject.uniqueID) --probably haven't cleaned up above when removing the object
                        if orderObjectReloaded and planManager:getPlanStatesForObjectForSapien(orderObjectReloaded, sapien) then
                            serverSapien:setLookAt(sapien, orderObject.uniqueID, orderObject.pos)
                        end
                    end

                    local result = serverSapien:startNextAction(sapien)
                    if result == serverSapien.startNextActionResult.cancel then
                        cancel = true
                    elseif result == serverSapien.startNextActionResult.done then
                        done = true
                    end
                end
                
            end
        end
    end

    if cancel then
        local removeHeldObjectOrderContext = false
        serverSapien:cancelOrderAtQueueIndex(sapien, 1, removeHeldObjectOrderContext)
        sapien.privateState.actionStateRepeatCounter = nil
    elseif done then
        local checkResult = serverSapienAI:checkAutoExtendCurrentOrder(sapien)
        if checkResult and checkResult.canExtend then

            if checkResult.replaceOrder then

                serverSapien:completeOrder(sapien)
                
                local aiState = serverSapienAI.aiStates[sapien.uniqueID]
                aiState.currentLookAtObjectInfo = {
                    lookAtIntent = lookAtIntents.types.work.index,
                    uniqueID = orderObject.uniqueID,
                    object = orderObject,
                    pos = orderObject.pos,
                    planTypeIndex = orderState.context.planTypeIndex,
                    assignObjectID = orderObject.uniqueID,
                    assignObjectDistance = length(orderObject.pos - sapien.pos),
                }

                --mj:log("replaceOrder")
                if startOrderAI:actOnLookAtObject(sapien) then
                    done = false --WATCH out for this, a bit dangerous if stuff is added below, this is really just setting done to false as a potential future fix
                end
            elseif checkResult.shouldActOnLookAtObject then

                serverSapien:completeOrder(sapien)

                local aiState = serverSapienAI.aiStates[sapien.uniqueID]
                aiState.currentLookAtObjectInfo = {
                    lookAtIntent = lookAtIntents.types.work.index,
                    uniqueID = checkResult.shouldActOnLookAtObject.uniqueID,
                    object = checkResult.shouldActOnLookAtObject,
                    pos = checkResult.shouldActOnLookAtObject.pos,
                    planTypeIndex = orderState.context.planTypeIndex,
                    assignObjectID = checkResult.shouldActOnLookAtObject.uniqueID,
                    assignObjectDistance = length(checkResult.shouldActOnLookAtObject.pos - sapien.pos),
                }

                --mj:log("replaceOrder")
                if startOrderAI:actOnLookAtObject(sapien) then
                    done = false --WATCH out for this, a bit dangerous if stuff is added below, this is really just setting done to false as a potential future fix
                end
            else
                local newActionSequence = serverSapien:createActionStateForOrder(sapien, orderObject, orderState)
                local actionState = sharedState.actionState
                local activeSequence = actionSequence.types[actionState.sequenceTypeIndex]
                if newActionSequence and actionState.sequenceTypeIndex == newActionSequence.sequenceTypeIndex then
                    sapien.sharedState:set("actionState", "progressIndex", #activeSequence.actions)
                    sapien.privateState.actionStateTimer = 0.0
                    --disabled--mj:objectLog(sapien.uniqueID, "order auto extended in activeOrderAI frequent update.")
                else
                    --disabled--mj:objectLog(sapien.uniqueID, "order not auto extended in activeOrderAI due to action sequence type mismatch.")
                    serverSapien:completeOrder(sapien)
                end
            end
        else
            serverSapien:completeOrder(sapien)
        end
       -- serverSapien:completeOrder(sapien) --leave this for checkPlans
    end

    --[[
    if cancel or done then
        --disabled--mj:objectLog(sapien.uniqueID, "cancel or done. cancel:", cancel, " done:", done)
    end]]

    
    if (not cancel) and (not done) then
        multitask:update(sapien, dt, speedMultiplier)
    end

    if saveStateChange then
        serverSapien:saveState(sapien)
    end
end

function activeOrderAI:init(initObjects)
    serverSapienAI = initObjects.serverSapienAI
    serverSapien = initObjects.serverSapien
    serverGOM = initObjects.serverGOM
    serverWorld = initObjects.serverWorld

    for actionTypeIndex,info in pairs(activeOrderAI.updateInfos) do
        info.actionTypeIndex = actionTypeIndex
    end
    
    --findOrderAI = findOrderAI_
end

return activeOrderAI