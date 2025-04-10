local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local length2 = mjm.length2

local plan = mjrequire "common/plan"
local planHelper = mjrequire "common/planHelper"
--local tool = mjrequire "common/tool"
--local order = mjrequire "common/order"
local fuel = mjrequire "common/fuel"
--local notification = mjrequire "common/notification"
local constructable = mjrequire "common/constructable"
local research = mjrequire "common/research"
local skill = mjrequire "common/skill"
local resource = mjrequire "common/resource"
local rng = mjrequire "common/randomNumberGenerator"
local gameObject = mjrequire "common/gameObject"
local sapienConstants = mjrequire "common/sapienConstants"
local gameObjectSharedState = mjrequire "common/gameObjectSharedState"
local gameConstants = mjrequire "common/gameConstants"
--local physicsSets = mjrequire "common/physicsSets"
local medicine = mjrequire "common/medicine"
--local physics = mjrequire "common/physics"
local worldHelper = mjrequire "common/worldHelper"
local terrain = mjrequire "server/serverTerrain"
local anchor = mjrequire "server/anchor"
local serverStorageArea = mjrequire "server/serverStorageArea"
local serverResourceManager = mjrequire "server/serverResourceManager"
local serverSapienSkills = mjrequire "server/serverSapienSkills"
local serverCompostBin = mjrequire "server/objects/serverCompostBin"
local planLightProbes = mjrequire "server/planLightProbes"
local serverTutorialState = mjrequire "server/serverTutorialState"


--local timer = mjrequire "common/timer"

local planManager = {}


planManager.maxPlanDistance = mj:mToP(400.0)
planManager.maxPlanDistance2 = planManager.maxPlanDistance * planManager.maxPlanDistance

planManager.maxAssignedOrPrioritizedPlanDistance = mj:mToP(2500.0)
planManager.maxAssignedOrPrioritizedPlanDistance2 = planManager.maxAssignedOrPrioritizedPlanDistance * planManager.maxAssignedOrPrioritizedPlanDistance

local orderedPlansByTribeID = {}
planManager.orderedPlansByTribeID = orderedPlansByTribeID
planManager.canPossiblyCompleteForSapienIterationByPlanID = {}
--local hasReachedMaxPlansByTribeID = {}
local maxOrdersByTribeID = {}
local plansHaveBeenSortedByTribeID = {}


local serverGOM = nil
local serverSapien = nil
local serverWorld = nil
local serverCraftArea = nil
local planManagerDatabase = nil
local planIDCounter = 0
local prioritizeIDCounter = 0

--local completablePlanObjectsByTribeID = {}
--local addedPlanObjectArrayPositionsByTribeID = {}

local closeSapiensBySkillTypeByObjectByTribe = {}

local needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs = {}

local addedProximitySetsByPlanObjectID = {}


function planManager:init(serverGOM_, serverWorld_, serverSapien_, serverCraftArea_)
    serverGOM = serverGOM_
    serverSapien = serverSapien_
    serverCraftArea = serverCraftArea_
    serverWorld = serverWorld_

    planManagerDatabase = serverWorld:getDatabase("planManager", true)
    planIDCounter = planManagerDatabase:dataForKey("idCounter") or 0
    prioritizeIDCounter = planManagerDatabase:dataForKey("prioritizeIDCounter") or 0

    planHelper:init(nil, serverWorld)
    planLightProbes:init(planManager, serverGOM_, serverWorld_)

end

function planManager:getAndIncrementPlanID()
    planIDCounter = planIDCounter + 1
    planManagerDatabase:setDataForKey(planIDCounter, "idCounter")

    return planIDCounter
end

function planManager:getAndIncrementPrioritizedID()
    prioritizeIDCounter = prioritizeIDCounter - 1
    planManagerDatabase:setDataForKey(prioritizeIDCounter, "prioritizeIDCounter")

    return prioritizeIDCounter
end

local function checkRemoveSpecialStateForPlanStateRemoval(planObject, planTypeIndexOrNIlForAll, tribeID)
    if ((not planTypeIndexOrNIlForAll) or planTypeIndexOrNIlForAll == plan.types.deconstruct.index or planTypeIndexOrNIlForAll == plan.types.rebuild.index) and 
    (gameObject.types[planObject.objectTypeIndex].isStorageArea or planObject.objectTypeIndex == gameObject.types.compostBin.index) then
        planObject.sharedState:remove("settingsByTribe", tribeID, "removeAllDueToDeconstruct")
    end
end

--[[local function addToCanCompleteList(object, tribeID, basePriorityOffset, manuallyPrioritized)
    
    local priorityOffset = basePriorityOffset or 0
    if manuallyPrioritized then
        priorityOffset = priorityOffset + 1000
    end

    if not serverGOM:getObjectWithID(object.uniqueID) then
        mj:error("attempt to addToCanCompleteList for non-loaded object")
        return
    end
    local planObjectsByThisTribeID = completablePlanObjectsByTribeID[tribeID]
    local addedPlanObjectArrayPositionsByThisTribeID = addedPlanObjectArrayPositionsByTribeID[tribeID]
    if not planObjectsByThisTribeID then
        planObjectsByThisTribeID = {}
        completablePlanObjectsByTribeID[tribeID] = planObjectsByThisTribeID
        addedPlanObjectArrayPositionsByThisTribeID = {}
        addedPlanObjectArrayPositionsByTribeID[tribeID] = addedPlanObjectArrayPositionsByThisTribeID
    end

    if not addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID] then
        
        if priorityOffset > 0 then
            local insertObject = {
                object = object,
                priorityOffset = priorityOffset,
            }
            for i = 1, #planObjectsByThisTribeID do
                local existingInfo = planObjectsByThisTribeID[i]
                if (not existingInfo.priorityOffset) or existingInfo.priorityOffset < insertObject.priorityOffset then
                    planObjectsByThisTribeID[i] = insertObject
                    addedPlanObjectArrayPositionsByThisTribeID[insertObject.object.uniqueID] = i
                    insertObject = existingInfo
                end
                if (not existingInfo.priorityOffset) then
                    break
                end
            end
            
            table.insert(planObjectsByThisTribeID, insertObject)
            addedPlanObjectArrayPositionsByThisTribeID[insertObject.object.uniqueID] = #planObjectsByThisTribeID
        else
            table.insert(planObjectsByThisTribeID, {
                object = object
            })
            addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID] = #planObjectsByThisTribeID
        end
    end
end]]

--[[local function removeFromCanCompleteList(object, tribeID)
   -- mj:log("removeFromCanCompleteList:", object.uniqueID)
    local addedPlanObjectArrayPositionsByThisTribeID = addedPlanObjectArrayPositionsByTribeID[tribeID]
    if addedPlanObjectArrayPositionsByThisTribeID then
        local arrayPosition = addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID]
        if arrayPosition then
            local planObjectsByThisTribeID = completablePlanObjectsByTribeID[tribeID]
            if #planObjectsByThisTribeID > arrayPosition then
                local moveObjectInfo = planObjectsByThisTribeID[#planObjectsByThisTribeID]
                planObjectsByThisTribeID[arrayPosition] = moveObjectInfo
                addedPlanObjectArrayPositionsByThisTribeID[moveObjectInfo.object.uniqueID] = arrayPosition
            end
            
            addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID] = nil
            planObjectsByThisTribeID[#planObjectsByThisTribeID] = nil
        end
    end
end]]


--[[local function updateOrderWithinCanCompleteList(object, tribeID, priorityOffset, manuallyPrioritized)
    removeFromCanCompleteList(object, tribeID)
    addToCanCompleteList(object, tribeID, priorityOffset, manuallyPrioritized)
end]]

function planManager:canCompleteIgnoringOrderLimit(planState)
    if planState.tooDark then
        return false
    end
    if planState.missingResources then
        return false
    end
    if planState.maintainQuantityThresholdMet then
        return false
    end
    if planState.missingTools then
        return false
    end
    if planState.missingStorage then
        return false
    end
    if planState.missingCraftArea then
        return false
    end
    if planState.missingSuitableTerrain then
        return false
    end
    if planState.missingShallowWater then
        return false
    end
    if planState.missingStorageAreaContainedObjects then
        return false
    end
    if planState.missingSkill then
        return false
    end
    if planState.inaccessible then
        return false
    end
    if planState.terrainTooSteepFill or planState.terrainTooSteepDig then
        return false
    end
    if planState.invalidUnderWater then
        return false
    end
    if planState.needsLit then
        return false
    end
    if planState.tooDistant then
        return false
    end
    return true
end

local function updateCanCompleteAndSave(object, sharedState, planState, planTribeID, planIndex, skipUpdateOfOrderLimits)
    local newCanComplete = planManager:canCompleteIgnoringOrderLimit(planState)

    if not skipUpdateOfOrderLimits then
        if not needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[planTribeID] then
            needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[planTribeID] = 0.0
        end
    end

    if planState.disabledDueToOrderLimit then
        newCanComplete = false
    end

    if not planState.planTypeIndex then
        mj:error("updateCanCompleteAndSave a:", planState, " shared state:", sharedState.planStates[planTribeID][planIndex])
        error()
    end 
    if not sharedState.planStates[planTribeID][planIndex].planTypeIndex then
        mj:error("updateCanCompleteAndSave b:", planState, " shared state:", sharedState.planStates[planTribeID][planIndex])
        error()
    end

    local addToIteratePlansList = newCanComplete
    if not addToIteratePlansList then
        if serverWorld:getAutoRoleAssignmentEnabled(planTribeID) then
            if planState.tooDistant and planState.requiredSkill then
                --mj:log("add due to role assignment:", planState)
                addToIteratePlansList = true
            end
        end
    end

    if addToIteratePlansList then
        planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
    else
        planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = nil
    end

    --[[local oldPlanState = sharedState.planStates[planTribeID][planIndex]

    if newCanComplete and (not oldPlanState.canComplete) then
        
        local priorityOffset = math.max(planState.priorityOffset or 0, plan.types[planState.planTypeIndex].priorityOffset or 0)

        addToCanCompleteList(object, planTribeID, priorityOffset, planState.manuallyPrioritized)
    elseif (not newCanComplete) and oldPlanState.canComplete then
        local foundOther = false
        for i,otherPlanState in ipairs(sharedState.planStates[planTribeID]) do
            if i ~= planIndex then
                if otherPlanState.canComplete then
                    foundOther = true
                    break
                end
            end
        end
        if not foundOther then
            removeFromCanCompleteList(object, planTribeID)
        end
    end]]

    --mj:log("updateCanCompleteAndSave newCanComplete:", newCanComplete)

    sharedState:set("planStates", planTribeID, planIndex, "canComplete", newCanComplete)

end

function planManager:updateCanCompleteAndSave(object, sharedState, planState, planTribeID, planIndex, skipUpdateOfOrderLimits)
    updateCanCompleteAndSave(object, sharedState, planState, planTribeID, planIndex, skipUpdateOfOrderLimits)
end


local function getCloseSapiensBySkillTypeForObjectForTribe(tribeID, objectID, createIfNeeded)
    local closeSapiensBySkillTypeByObject = closeSapiensBySkillTypeByObjectByTribe[tribeID]
    if not closeSapiensBySkillTypeByObject then
        closeSapiensBySkillTypeByObject = {}
        closeSapiensBySkillTypeByObjectByTribe[tribeID] = closeSapiensBySkillTypeByObject
    end
    local closeSapiensBySkillType = closeSapiensBySkillTypeByObject[objectID]
    if createIfNeeded and (not closeSapiensBySkillType) then
        closeSapiensBySkillType = {}
        closeSapiensBySkillTypeByObject[objectID] = closeSapiensBySkillType
    end
    return closeSapiensBySkillType
end

function planManager:updateProximityForAbilityChange(sapienID)
    local sapien = serverGOM:getObjectWithID(sapienID)
    if sapien then
        local function updatePlanObjectSet(skillTypeIndexOrNil, planObjectSetIndex)
            serverGOM:callFunctionForObjectsInSet(planObjectSetIndex, function(planObjectID)
                local planObject = serverGOM:getObjectWithID(planObjectID)
                if planObject then
                    local newIsClose = false

                    if skillTypeIndexOrNil then
                        local closeSapiensBySkillType = getCloseSapiensBySkillTypeForObjectForTribe(sapien.sharedState.tribeID, planObjectID, false)
                        if closeSapiensBySkillType then
                            local closeSapiens = closeSapiensBySkillType[skillTypeIndexOrNil]
                            if closeSapiens and closeSapiens[sapienID] then
                                newIsClose = true
                            end
                        end
                    end

                    if not newIsClose then
                        local planObjectDistance2 = length2(planObject.pos - sapien.pos)
                        if planObjectDistance2 < planManager.maxPlanDistance2 then
                            newIsClose = true
                        end
                    end

                    planManager:updateProximity(skillTypeIndexOrNil, planObjectID, sapienID, newIsClose)
                end
            end)
        end

        if skill:priorityLevel(sapien, skill.types.researching.index) ~= 0 then
            updatePlanObjectSet(skill.types.researching.index, skill.types.researching.planObjectSetIndex)
        end
    end
end

local function checkSapienHasAbilityForRole(sapien, skillTypeIndex, planStateOrNil)
    if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
        if skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility then
            return false
        elseif planStateOrNil and planStateOrNil.researchTypeIndex then
            local researchType = research.types[planStateOrNil.researchTypeIndex]
            if researchType and researchType.disallowsLimitedAbilitySapiens then
                return false
            end
        end

        local constructableTypeIndex = planStateOrNil and planStateOrNil.constructableTypeIndex
        if constructableTypeIndex then
            local constructableType = constructable.types[constructableTypeIndex]
            if constructableType.disallowsLimitedAbilitySapiens then
                return false
            end
        end
    end
    return true
end

function planManager:assignNearbySapienToRequiredRoleIfable(tribeID, skillTypeIndexOrNil, planObjectPos, planStateOrNil)
    if not skillTypeIndexOrNil then
        return false
    end

    if serverWorld:getAutoRoleAssignmentIsAllowedForRole(tribeID, skillTypeIndexOrNil, nil) then
        --mj:log("assignNearbySapienToRequiredRoleIfable tribeID:", tribeID, "skillTypeIndexOrNil:", skillTypeIndexOrNil)
        local allCloseSapiens = serverGOM:getGameObjectsInSetWithinRadiusOfPos(serverGOM.objectSets.sapiens, planObjectPos, planManager.maxPlanDistance)
        local bestSapien = nil
        local bestHeuristic = nil
        for j,objectInfo in ipairs(allCloseSapiens) do
            local sapien = serverGOM:getObjectWithID(objectInfo.objectID)
            if sapien then
                if sapien.sharedState.tribeID == tribeID then
                    local allowed = checkSapienHasAbilityForRole(sapien, skillTypeIndexOrNil, planStateOrNil)

                    if allowed then
                        if skill:priorityLevel(sapien, skillTypeIndexOrNil) == 1 then
                            return false
                        end
                    end

                    if allowed then
                        local heuristic = -objectInfo.distance2 / planManager.maxPlanDistance2
                        local assignedRoleCount = skill:getAssignedRolesCount(sapien)
                        heuristic = heuristic - assignedRoleCount * planManager.maxPlanDistance2 * 0.5

                        if (not bestHeuristic) or bestHeuristic < heuristic then
                            bestSapien = sapien
                            bestHeuristic = heuristic
                        end
                    end
                end
            end
        end

        if bestSapien then
            mj:log("assigning sapien found best:", bestSapien.uniqueID)
            return serverSapien:autoAssignToRole(bestSapien, skillTypeIndexOrNil)
        end
    end
    return false
end

function planManager:updateProximity(skillTypeIndexOrNil, planObjectID, sapienID, newIsClose)
    local addedProximitySets = addedProximitySetsByPlanObjectID[planObjectID]
    if not addedProximitySets then
        return
    end

    --disabled--mj:objectLog(planObjectID, "updateProximity:", sapienID, " newIsClose:", newIsClose)
    local skillTypeIndexSaveKeyToUse = skillTypeIndexOrNil or 0

    local sapien = serverGOM:getObjectWithID(sapienID)
    if not sapien then
        return
    end
    local sapienTribeID = sapien.sharedState.tribeID

    if newIsClose and skillTypeIndexOrNil == skill.types.researching.index then
        if sapien and sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
            local planObject = serverGOM:getObjectWithID(planObjectID)
            if planObject then
                local sharedState = planObject.sharedState
                if sharedState then
                    local planStatesForThisTribe = nil
                    if sharedState.planStates and sharedState.planStates[sapienTribeID] then
                        planStatesForThisTribe = sharedState.planStates[sapienTribeID]
                    end
                    if planStatesForThisTribe then
                        for planIndex, thisPlanState in ipairs(planStatesForThisTribe) do
                            if thisPlanState.researchTypeIndex then
                                local researchType = research.types[thisPlanState.researchTypeIndex]
                                if researchType and researchType.disallowsLimitedAbilitySapiens then
                                    newIsClose = false
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local closeSapiensBySkillType = getCloseSapiensBySkillTypeForObjectForTribe(sapienTribeID, planObjectID, true)
    local closeSapiens = closeSapiensBySkillType[skillTypeIndexSaveKeyToUse]

    local hasCloseSapiens = false
    local tooDistantChanged = false

    if newIsClose then
        if not closeSapiens then
            closeSapiens = {}
            closeSapiensBySkillType[skillTypeIndexSaveKeyToUse] = closeSapiens
            tooDistantChanged = true
        end
        
        closeSapiens[sapienID] = sapienTribeID
        hasCloseSapiens = true
    else
        if closeSapiens then
            closeSapiens[sapienID] = nil
            hasCloseSapiens = false
            for closeSapienID,closeSapienTribeID in pairs(closeSapiens) do
                if closeSapienTribeID == sapienTribeID then
                    hasCloseSapiens = true
                    break
                end
            end
            
            if not hasCloseSapiens then
                tooDistantChanged = true
                if not next(closeSapiens) then
                    closeSapiensBySkillType[skillTypeIndexSaveKeyToUse] = nil
                end
            end
        else
            tooDistantChanged = true -- the default is for it to not be too distant, so we will just always force it to check. Could be optimized if needed.
        end
    end

    if tooDistantChanged then
        local planObject = serverGOM:getObjectWithID(planObjectID)
        if planObject then
            local planStatesByTribeID = planObject.sharedState.planStates
            if planStatesByTribeID then
                local planStates = planStatesByTribeID[sapienTribeID]
                if planStates then
                    for i,thisPlanState in ipairs(planStates) do
                        if thisPlanState.requiredSkill == skillTypeIndexOrNil or (thisPlanState.optionalFallbackSkill and thisPlanState.optionalFallbackSkill == skillTypeIndexOrNil) then
                            if hasCloseSapiens or plan.types[thisPlanState.planTypeIndex].skipMaxOrderChecks then
                                if thisPlanState.tooDistant then
                                    planObject.sharedState:remove("planStates", sapienTribeID, i, "tooDistant")
                                    updateCanCompleteAndSave(planObject, planObject.sharedState, thisPlanState, sapienTribeID, i, false)
                                end
                            else
                                if (not thisPlanState.tooDistant) and (not thisPlanState.manuallyPrioritized) and (not thisPlanState.manualAssignedSapien) then


                                    local skipDueToMainSkill = false
                                    if thisPlanState.requiredSkill ~= skillTypeIndexOrNil and thisPlanState.requiredSkill then -- optionalFallbackSkill
                                        local requiredSkillCloseSapiens = closeSapiensBySkillType[thisPlanState.requiredSkill]
                                        if requiredSkillCloseSapiens then
                                            for closeSapienID,closeSapienTribeID in pairs(requiredSkillCloseSapiens) do
                                                if closeSapienTribeID == sapienTribeID then
                                                    skipDueToMainSkill = true
                                                    break
                                                end
                                            end
                                        end
                                    end

                                    if not skipDueToMainSkill then
                                        if not planManager:assignNearbySapienToRequiredRoleIfable(thisPlanState.tribeID, skillTypeIndexOrNil, planObject.pos, thisPlanState) then
                                            --planManager:updateProximity(skillTypeIndexOrNil, planObjectID, sapienID, newIsClose) --commented out and added 'not' above, April '24, seems redundant
                                            --return
                                        --else
                                            planObject.sharedState:set("planStates", sapienTribeID, i, "tooDistant", skillTypeIndexOrNil or 1)
                                            updateCanCompleteAndSave(planObject, planObject.sharedState, thisPlanState, sapienTribeID, i, false)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
    needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[tribeID] = nil

    local maxPlanCount = maxOrdersByTribeID[tribeID]
    if not maxPlanCount then
        return
    end

    local function setPlanEnabled(planInfo, newEnabled)
        local changed = false
        if newEnabled then
            if planInfo.disabledDueToOrderLimit then
                planInfo.disabledDueToOrderLimit = nil
                changed = true
            end
        else
            if not planInfo.disabledDueToOrderLimit then
                planInfo.disabledDueToOrderLimit = true
                changed = true
            end
        end

       -- mj:log("setPlanEnabled:", newEnabled)

        local foundAvailablePlan = false

        if changed or newEnabled then
            local object = serverGOM:getObjectWithID(planInfo.objectID)
            if object then
                local sharedState = object.sharedState
                local planStatesByTribeID = sharedState.planStates
                if planStatesByTribeID then
                    local planStates = planStatesByTribeID[tribeID]
                    if planStates then
                        for i,thisPlanState in ipairs(planStates) do
                            if thisPlanState.planID == planInfo.planID then
                                if changed then
                                    if newEnabled then
                                        sharedState:remove("planStates", tribeID, i, "disabledDueToOrderLimit")
                                    else
                                        sharedState:set("planStates", tribeID, i, "disabledDueToOrderLimit", true)
                                    end

                                    updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, true)
                                end

                                if newEnabled then
                                    foundAvailablePlan = planManager:canCompleteIgnoringOrderLimit(thisPlanState)
                                end
                                
                                break
                            end
                        end
                    end
                end
            end
        end

        return foundAvailablePlan
    end

    --local maxReached = false

    local orderedPlans = orderedPlansByTribeID[tribeID]
    local orderedPlansCount = 0
    if orderedPlans then
        orderedPlansCount = #orderedPlans
        local availableCounter = 1
        for i, planInfo in ipairs(orderedPlans) do

            if availableCounter <= maxPlanCount then
                if setPlanEnabled(planInfo, true) then
                    availableCounter = availableCounter + 1
                end
            else
                setPlanEnabled(planInfo, false)
            end
        end
    end

    --hasReachedMaxPlansByTribeID[tribeID] = maxReached

    --mj:error("updatePlansForFollowerOrOrderCountChange maxPlanCount:", maxPlanCount, " orderedPlans count:", orderedPlansCount)

    
    serverWorld:notifyClientOfPlanCountChange(tribeID, orderedPlansCount, maxPlanCount)
end

local function planWillBeRemoved(planObject, planState)
    if planState.researchTypeIndex then
        serverWorld:removeDiscoveryOrCraftableDiscoveryPlanForTribe(planState.tribeID, planState.researchTypeIndex, planState.discoveryCraftableTypeIndex)
    end

    planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = nil

    local orderedPlans = orderedPlansByTribeID[planState.tribeID]
    if orderedPlans then
        for i, orderedPlan in ipairs(orderedPlans) do
            if orderedPlan.planID == planState.planID then
                table.remove(orderedPlans, i)
                if not needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[planState.tribeID] then
                    needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[planState.tribeID] = 0.0
                end
                break
            end
        end
    end

    if planState.manualAssignedSapien then
        local sapien = serverGOM:getObjectWithID(planState.manualAssignedSapien)
        if sapien then
            if sapien.sharedState.manualAssignedPlanObject == planObject.uniqueID then
                sapien.sharedState:remove("manualAssignedPlanObject")
            end
        end
    end

    if planState.markerObjectID then
        serverGOM:removeGameObject(planState.markerObjectID)
        serverGOM:setAlwaysSendToClientWithTribeIDForObjectWithID(planObject.uniqueID, planState.tribeID, false)
    end
end

local function updateAnchorForPlanAddedOrRemoved(planObject, tribeID)
    if planObject.objectTypeIndex ~= gameObject.types.sapien.index then --don't bother adding for sapiens, as they have their own larger anchors already
        local planStatesByTribeID = planObject.sharedState.planStates
        if planStatesByTribeID then
            local planStates = planStatesByTribeID[tribeID]
            if planStates and planStates[1] then
                anchor:addAnchor(planObject.uniqueID, anchor.types.planObject.index, tribeID)
            else
                anchor:removeAnchor(planObject.uniqueID, anchor.types.planObject.index, tribeID)
            end
        end
    end
end



--[[function planManager:debugCheckAllPlansGone(object)
    for tribeID,planObjectsByThisTribeID in pairs(completablePlanObjectsByTribeID) do
        if planObjectsByThisTribeID and #planObjectsByThisTribeID > 0 then
            for i, planObjectInfo in ipairs(planObjectsByThisTribeID) do
                if planObjectInfo.object.uniqueID == object.uniqueID then
                    mj:error("planManager:debugCheckAllPlansGone failed", object.sharedState)
                    error()
                end
            end
        end
    end
end]]

--[[local function removeFromCanCompleteListDueToPlanOrObjectRemoval(object, allPlansRemoved)

    if allPlansRemoved then
        for tribeID,addedPlanObjectArrayPositionsByThisTribeID in pairs(addedPlanObjectArrayPositionsByTribeID) do
            local arrayPosition = addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID]
            if arrayPosition then
                local planObjectsByThisTribeID = completablePlanObjectsByTribeID[tribeID]
                if #planObjectsByThisTribeID > arrayPosition then
                    local moveObjectInfo = planObjectsByThisTribeID[#planObjectsByThisTribeID]
                    planObjectsByThisTribeID[arrayPosition] = moveObjectInfo
                    addedPlanObjectArrayPositionsByThisTribeID[moveObjectInfo.object.uniqueID] = arrayPosition
                end
                
                addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID] = nil
                planObjectsByThisTribeID[#planObjectsByThisTribeID] = nil
            end
        end
    else
        for tribeID,addedPlanObjectArrayPositionsByThisTribeID in pairs(addedPlanObjectArrayPositionsByTribeID) do
            local arrayPosition = addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID]
            if arrayPosition then
                local found = false
                if object.sharedState.planStates and object.sharedState.planStates[tribeID] then
                    for i,planState in ipairs(object.sharedState.planStates[tribeID]) do
                        if planState.canComplete then
                            found = true
                            break
                        end
                    end
                end
                if not found then
                    local planObjectsByThisTribeID = completablePlanObjectsByTribeID[tribeID]
                    if #planObjectsByThisTribeID > arrayPosition then
                        local moveObjectInfo = planObjectsByThisTribeID[#planObjectsByThisTribeID]
                        planObjectsByThisTribeID[arrayPosition] = moveObjectInfo
                        addedPlanObjectArrayPositionsByThisTribeID[moveObjectInfo.object.uniqueID] = arrayPosition
                    end
                    
                    addedPlanObjectArrayPositionsByThisTribeID[object.uniqueID] = nil
                    planObjectsByThisTribeID[#planObjectsByThisTribeID] = nil
                end
            end
        end
    end
end]]


local function getIsMissingRequiredSkill(tribeID, requiredSkill, optionalFallbackSkill)

    local missingSkills = true

    if serverSapienSkills:tribeHasSapienAllowedToDoTask(tribeID, requiredSkill) then
        missingSkills = false
    elseif optionalFallbackSkill then
        if serverSapienSkills:tribeHasSapienAllowedToDoTask(tribeID, optionalFallbackSkill) then
            missingSkills = false
        end
    end

    return missingSkills
end

local function updateImpossibleStateForSkillChange(tribeID, objectID, skillTypeIndexOrNil, becameAvailableOrRemoved)
    --mj:log("updateImpossibleStateForSkillChange:", objectID)
    local object = serverGOM:getObjectWithID(objectID)
    if object then
        local sharedState = object.sharedState
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            local planStates = planStatesByTribeID[tribeID]
            if planStates then
                for i,thisPlanState in ipairs(planStates) do
                    if thisPlanState.requiredSkill then

                        local missingSkills = getIsMissingRequiredSkill(tribeID, thisPlanState.requiredSkill, thisPlanState.optionalFallbackSkill)

                        if missingSkills then
                            sharedState:set("planStates", tribeID, i, "missingSkill", thisPlanState.requiredSkill)
                        else
                            sharedState:remove("planStates", tribeID, i, "missingSkill")
                        end
                        updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                    end
                end
            end
        end
    end
end

local minDigFillAccessableAltitude = -mj:mToP(0.1)

function planManager:updateImpossibleStateForVert(vertID)
    local vert = terrain:getVertWithID(vertID)
    if vert then
        local objectID = terrain:getObjectIDForTerrainModificationForVertex(vert)
        if objectID then
            local planObject = serverGOM:getObjectWithID(objectID)
            if planObject then
                local steepnessAffectedPlanInfos = {}
                local planStatesByTribeID = planObject.sharedState.planStates
                if planStatesByTribeID then
                    for tribeID,planStates in pairs(planStatesByTribeID) do
                        for i,thisPlanState in ipairs(planStates) do
                            if plan.types[thisPlanState.planTypeIndex].modifiesTerrainHeight then
                                table.insert(steepnessAffectedPlanInfos, {
                                    planTypeIndex = thisPlanState.planTypeIndex,
                                    tribeID = tribeID,
                                    index = i,
                                })
                            end
                        end
                    end

                    local foundHighEnough = vert.altitude > minDigFillAccessableAltitude

                    if next(steepnessAffectedPlanInfos) or not foundHighEnough then
                        local maxAltitude = -99
                        local minAltitude = 99
                        local neighborVerts = terrain:getNeighborVertsForVert(vertID)
                        local canDig = true
                        local canFill = true

                        if neighborVerts then
                            for i, neighborVert in ipairs(neighborVerts) do
                                local neighborAltitude = neighborVert.altitude
                                if neighborAltitude > maxAltitude then
                                    maxAltitude = neighborAltitude
                                end
                                if neighborAltitude < minAltitude then
                                    minAltitude = neighborAltitude
                                end
                            end

                            local thisAltitude = vert.altitude

                            if maxAltitude - thisAltitude > gameConstants.maxTerrainSteepness then
                                canDig = false
                            end
                            if thisAltitude - minAltitude > gameConstants.maxTerrainSteepness then
                                canFill = false
                            end

                            if not foundHighEnough then
                                foundHighEnough = maxAltitude > minDigFillAccessableAltitude
                            end
                        end

                        for i,planInfo in ipairs(steepnessAffectedPlanInfos) do
                            if planInfo.planTypeIndex == plan.types.dig.index or planInfo.planTypeIndex == plan.types.mine.index or planInfo.planTypeIndex == plan.types.chiselStone.index then
                                if canDig then
                                    planObject.sharedState:remove("planStates", planInfo.tribeID, planInfo.index, "terrainTooSteepDig")
                                else
                                    planObject.sharedState:set("planStates", planInfo.tribeID, planInfo.index, "terrainTooSteepDig", true)
                                end
                            elseif planInfo.planTypeIndex == plan.types.fill.index then
                                if canFill then
                                    planObject.sharedState:remove("planStates", planInfo.tribeID, planInfo.index, "terrainTooSteepFill")
                                else
                                    planObject.sharedState:set("planStates", planInfo.tribeID, planInfo.index, "terrainTooSteepFill", true)
                                end
                            end
                        end
                    end

                    for tribeID,planStates in pairs(planStatesByTribeID) do
                        for i,thisPlanState in ipairs(planStates) do
                            if foundHighEnough then
                                planObject.sharedState:remove("planStates", tribeID, i, "invalidUnderWater")
                            else
                                planObject.sharedState:set("planStates", tribeID, i, "invalidUnderWater", true)
                            end
                            updateCanCompleteAndSave(planObject, planObject.sharedState, thisPlanState, tribeID, i, false)
                        end
                    end


                end
            end
        end
    end
end

local function updateImpossibleStateForStorageAvailibilityChange(storageAreaTribeID, objectID, objectTypeIndex, isNewlyAvailable)
    --mj:error("updateImpossibleStateForStorageAvailibilityChange:", objectID, " isNewlyAvailable:", isNewlyAvailable)
    local object = serverGOM:getObjectWithID(objectID)
    if object then
        local sharedState = object.sharedState
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            --local planStates = planStatesByTribeID[tribeID]
            --if planStates then
            for tribeID,planStates in pairs(planStatesByTribeID) do
                for i,thisPlanState in ipairs(planStates) do
                    if thisPlanState.requiresStorageObjectTypeIndex and thisPlanState.requiresStorageObjectTypeIndex == objectTypeIndex then
                        if ((not thisPlanState.missingStorage) and (not isNewlyAvailable)) or (thisPlanState.missingStorage and isNewlyAvailable) then
                            local missingStorage = nil 
                            if not isNewlyAvailable then
                                missingStorage = true
                            end
                            sharedState:set("planStates", tribeID, i, "missingStorage", missingStorage)
                            updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                        end
                    end
                end
            end
            --end
        end
    end
end


local function updateImpossibleStateForCraftAreaAvailibilityChange(craftAreaTribeID, objectID, craftAreaGroupTypeIndex, isNewlyAvailableOrNilForNewlyUnavailable, craftAreaObjectPos)
    --mj:log("updateImpossibleStateForCraftAreaAvailibilityChange:", objectID)
    local object = serverGOM:getObjectWithID(objectID)
    if object then
       -- mj:log("object sharedState:", object.sharedState)
        local sharedState = object.sharedState
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            --local planStates = planStatesByTribeID[tribeID]
            for tribeID,planStates in pairs(planStatesByTribeID) do
                --if planStates then
                    for i,thisPlanState in ipairs(planStates) do
                        if thisPlanState.requiresCraftAreaGroupTypeIndexes then
                            local needsToCheckAgain = false
                            for j, thisCraftAreaGroupTypeIndex in ipairs(thisPlanState.requiresCraftAreaGroupTypeIndexes) do
                                if thisCraftAreaGroupTypeIndex == craftAreaGroupTypeIndex then
                                    if isNewlyAvailableOrNilForNewlyUnavailable then
                                        sharedState:remove("planStates", tribeID, i, "missingCraftArea")
                                        updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                                        --mj:log("isNewlyAvailableOrNilForNewlyUnavailable:", isNewlyAvailableOrNilForNewlyUnavailable)
                                    else
                                        needsToCheckAgain = true
                                    -- mj:log("needsToCheckAgain:")
                                    end
                                end
                            end
                            if needsToCheckAgain then
                                if serverCraftArea:anyCraftAreaAvailable(tribeID, thisPlanState.requiresCraftAreaGroupTypeIndexes, object.pos, thisPlanState.planTypeIndex) then
                                    --mj:log("remoivce")
                                    sharedState:remove("planStates", tribeID, i, "missingCraftArea")
                                    updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                                else
                                -- mj:log("set missingCraftArea")
                                    sharedState:set("planStates", tribeID, i, "missingCraftArea", true)
                                    updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                                end
                            end
                        end
                    end
                --end
            end
        end
    end
end

local function updateImpossibleStateForTerrainTypeAvailibilityChange(objectID, vertID)
    local object = serverGOM:getObjectWithID(objectID)
    if object then
        --mj:log("object sharedState:", object.sharedState)
        --mj:log("object.pos:", object.pos)
        local sharedState = object.sharedState
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            --local planStates = planStatesByTribeID[tribeID]
            for tribeID,planStates in pairs(planStatesByTribeID) do
                for i,thisPlanState in ipairs(planStates) do
                    if thisPlanState.requiresTerrainBaseTypeIndexes then
                        --mj:log("thisPlanState:", thisPlanState)
                        if (not thisPlanState.suitableTerrainVertID) or (vertID == thisPlanState.suitableTerrainVertID) then
                            local suitableTerrainVertID = terrain:closeVertIDWithinRadiusOfTypes(thisPlanState.requiresTerrainBaseTypeIndexes, object.pos, serverResourceManager.storageResourceMaxDistance)
                            if suitableTerrainVertID then
                                --mj:log("removing missingSuitableTerrain")
                                sharedState:remove("planStates", tribeID, i, "missingSuitableTerrain")
                                sharedState:set("planStates", tribeID, i, "suitableTerrainVertID", suitableTerrainVertID)
                                local vert = terrain:getVertWithID(suitableTerrainVertID)
                                if vert then
                                    sharedState:set("planStates", tribeID, i, "suitableTerrainVertPos", vert.pos)
                                end
                                updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                            else
                                --mj:log("adding missingSuitableTerrain")
                                sharedState:set("planStates", tribeID, i, "missingSuitableTerrain", true)
                                sharedState:remove("planStates", tribeID, i, "suitableTerrainVertID")
                                sharedState:remove("planStates", tribeID, i, "suitableTerrainVertPos")
                                updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function updateImpossibleStateForStorageAreaContainedObjectsPlanChange(objectID)
    local object = serverGOM:getObjectWithID(objectID)
    if object then
        local sharedState = object.sharedState

        local function getRequiredObjectTypeIndex(validResourceTypeIndexSet, restrictedResourceObjectTypes)
            local inventory = sharedState.inventory
            if inventory.countsByObjectType then
                for inventoryObjectTypeIndex, count in pairs(inventory.countsByObjectType) do
                    if count > 0 then
                        if (not restrictedResourceObjectTypes) or not restrictedResourceObjectTypes[inventoryObjectTypeIndex] then
                            local inventoryResourceTypeIndex = gameObject.types[inventoryObjectTypeIndex].resourceTypeIndex
                            if validResourceTypeIndexSet[inventoryResourceTypeIndex] then
                                return inventoryObjectTypeIndex
                            end
                        end
                    end
                end
            end
            return nil
        end

        --[[local function getHighestCountObjectTypeIndex(validResourceTypeIndexSet, restrictedResourceObjectTypes)
            local inventory = sharedState.inventory
            if inventory.countsByObjectType then
                for inventoryObjectTypeIndex, count in pairs(inventory.countsByObjectType) do
                    if count > 0 then
                        if (not restrictedResourceObjectTypes) or not restrictedResourceObjectTypes[inventoryObjectTypeIndex] then
                            local inventoryResourceTypeIndex = gameObject.types[inventoryObjectTypeIndex].resourceTypeIndex
                            if validResourceTypeIndexSet[inventoryResourceTypeIndex] then
                                return inventoryObjectTypeIndex
                            end
                        end
                    end
                end
            end
            return nil
        end]]

        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            for tribeID,planStates in pairs(planStatesByTribeID) do
                for i,thisPlanState in ipairs(planStates) do
                    if thisPlanState.planTypeIndex ~= plan.types.haulObject.index then
                        local foundObjectTypeIndex = nil
                        if thisPlanState.researchTypeIndex then
                            local discoveryCraftableTypeIndex = thisPlanState.discoveryCraftableTypeIndex
                            local function checkMatchesDiscoveryCraftableRequiredResource(resourceTypeIndex)
                                if discoveryCraftableTypeIndex then
                                    local craftableRequiredResources = constructable.types[discoveryCraftableTypeIndex].requiredResources
                                    for j, requiredResourceInfo in ipairs(craftableRequiredResources) do
                                        if resource:groupOrResourceMatchesResource(requiredResourceInfo.type or requiredResourceInfo.group, resourceTypeIndex) then
                                            return true
                                        end
                                    end
                                    return false
                                end
                                return true
                            end

                            local researchType = research.types[thisPlanState.researchTypeIndex]
                            local validResourceTypeIndexArray = researchType.resourceTypeIndexes
                            local validResourceTypeIndexSet = {}
                            for j, validResourceTypeIndex in ipairs(validResourceTypeIndexArray) do
                                if checkMatchesDiscoveryCraftableRequiredResource(validResourceTypeIndex) then
                                    validResourceTypeIndexSet[validResourceTypeIndex] = true
                                end
                            end
                            foundObjectTypeIndex = getRequiredObjectTypeIndex(validResourceTypeIndexSet, sharedState.restrictedResourceObjectTypes)
                        elseif thisPlanState.planTypeIndex == plan.types.playInstrument.index then
                            local validResourceTypeIndexSet = {
                                [resource.types.boneFlute.index] = true,
                                [resource.types.logDrum.index] = true,
                                [resource.types.balafon.index] = true
                            }
                            foundObjectTypeIndex = getRequiredObjectTypeIndex(validResourceTypeIndexSet, nil)
                        else
                            local constructableTypeIndex = thisPlanState.constructableTypeIndex
                            local requiredResources = constructable.types[constructableTypeIndex].requiredResources
                            local validResourceTypeIndexSet = {}
                            for j, resourceInfo in ipairs(requiredResources) do
                                if resourceInfo.type then
                                    validResourceTypeIndexSet[resourceInfo.type] = true
                                else
                                    for k, resourceTypeIndex in ipairs(resource.groups[resourceInfo.group].resourceTypes) do
                                        validResourceTypeIndexSet[resourceTypeIndex] = true
                                    end
                                end
                            end
                            foundObjectTypeIndex = getRequiredObjectTypeIndex(validResourceTypeIndexSet, sharedState.restrictedResourceObjectTypes)
                        end
                        
                        if foundObjectTypeIndex then
                            if thisPlanState.missingStorageAreaContainedObjects then
                                sharedState:remove("planStates", tribeID, i, "missingStorageAreaContainedObjects")
                                updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                            end
                        else
                            if not thisPlanState.missingStorageAreaContainedObjects then
                                sharedState:set("planStates", tribeID, i, "missingStorageAreaContainedObjects", true)
                                updateCanCompleteAndSave(object, sharedState, thisPlanState, tribeID, i, false)
                            end
                        end
                    end
                end
            end
        end
    end
end

function planManager:updateImpossibleStatesForSurroundingVertsForTerrainLevelChange(changedVertID)
    planManager:updateImpossibleStateForVert(changedVertID)
    local neighborVerts = terrain:getNeighborVertsForVert(changedVertID)
    for i, neighborVert in ipairs(neighborVerts) do
        planManager:updateImpossibleStateForVert(neighborVert.uniqueID)
    end
end

function planManager:updateAnyPlanStatesForPlanObjectAccessibilityChange(object, isInaccessible)
    if object.objectTypeIndex ~= gameObject.types.sapien.index and (not gameObject.types[object.objectTypeIndex].mobTypeIndex) then --bit of a hack. As they are moving, chances are we hit a false positive. Just never mark as inaccessible
        local sharedState = object.sharedState
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            for planTribeID,planStates in pairs(planStatesByTribeID) do
                if planStates then
                    for i,thisPlanState in ipairs(planStates) do
                        if thisPlanState.inaccessible and (not isInaccessible) then
                            sharedState:remove("planStates", planTribeID, i, "inaccessible")
                            updateCanCompleteAndSave(object, sharedState, thisPlanState, planTribeID, i, false)
                        elseif (not thisPlanState.inaccessible) and isInaccessible then
                            sharedState:set("planStates", planTribeID, i, "inaccessible", true)
                            updateCanCompleteAndSave(object, sharedState, thisPlanState, planTribeID, i, false)
                        end
                    end
                end
            end
        end
    end
end

local function updateImpossibleStateForResourceAvailabilityChange(objectID)
    local function compareMissingResourceContentsEqual(missingResourcesA, missingResourcesB)
        if missingResourcesA then
            if missingResourcesB then
                for i,resourceInfoA in ipairs(missingResourcesA) do
                    local resourceInfoB = missingResourcesB[i]
                    if not resourceInfoB then
                        return false
                    end
                    if resourceInfoA.objectTypeIndex ~= resourceInfoB.objectTypeIndex then
                        return false
                    end
                    if resourceInfoA.type ~= resourceInfoB.type then
                        return false
                    end
                    if resourceInfoA.group ~= resourceInfoB.group then
                        return false
                    end
                    if resourceInfoA.missingCount ~= resourceInfoB.missingCount then
                        return false
                    end
                end
            else
                return false
            end
        else
            if missingResourcesB then
                return false
            end
        end
        return true
    end
    
    local function compareMissingToolsArrayEqual(missingToolsA, missingToolsB)
        if missingToolsA then
            if missingToolsB then
                if #missingToolsA ~= #missingToolsB then
                    return false
                end
                for i,toolTypeIndexA in ipairs(missingToolsA) do
                    if toolTypeIndexA ~= missingToolsB[i] then
                        return false
                    end
                end
            else
                return false
            end
        else
            if missingToolsB then
                return false
            end
        end
        return true
    end

    local object = serverGOM:getObjectWithID(objectID)
    if object then
        local sharedState = object.sharedState
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            for planTribeID,planStates in pairs(planStatesByTribeID) do
                for i,thisPlanState in ipairs(planStates) do
                    local needsSave = false
                    if thisPlanState.requiredResources then
                        
                        local restrictedResourceObjectTypes = sharedState.restrictedResourceObjectTypes
                        if thisPlanState.constructableTypeIndex then
                            restrictedResourceObjectTypes = serverWorld:getResourceBlockListForConstructableTypeIndex(thisPlanState.tribeID, thisPlanState.constructableTypeIndex, restrictedResourceObjectTypes)
                        elseif plan.types[thisPlanState.planTypeIndex].isMedicineTreatment then
                            restrictedResourceObjectTypes = serverWorld:getResourceBlockListForMedicineTreatment(thisPlanState.tribeID, restrictedResourceObjectTypes)
                        elseif thisPlanState.planTypeIndex == plan.types.light.index then
                            local fuelGroup = fuel.groupsByObjectTypeIndex[object.objectTypeIndex]
                            if fuelGroup then
                                restrictedResourceObjectTypes = serverWorld:getResourceBlockListForFuel(thisPlanState.tribeID, fuelGroup.index, restrictedResourceObjectTypes)
                            end
                        end

                        local returnedMissingResourceArray = {}
                        local allFound = serverResourceManager:allRequiredResourcesAreAvailable(thisPlanState.requiredResources, 
                        object.pos, 
                        true, 
                        restrictedResourceObjectTypes,
                        returnedMissingResourceArray, 
                        thisPlanState.tribeID)

                        if allFound then
                            if thisPlanState.missingResources then
                                --Traceback(object.uniqueID, "removing resources A missing requiredResources:", thisPlanState.requiredResources, " returnedMissingResourceArray:", returnedMissingResourceArray, " tribe id:", thisPlanState.tribeID, " restrictedResourceObjectTypes:", restrictedResourceObjectTypes, " thisPlanState:", thisPlanState)
                                sharedState:remove("planStates", planTribeID, i, "missingResources")
                                needsSave = true
                            end
                        else
                            if not thisPlanState.missingResources then
                                needsSave = true
                            else
                                if not compareMissingResourceContentsEqual(thisPlanState.missingResources, returnedMissingResourceArray) then
                                    needsSave = true
                                end
                            end
                            sharedState:set("planStates", planTribeID, i, "missingResources", returnedMissingResourceArray)
                            --mj:objectLogTraceback(object.uniqueID, "setting resources missing requiredResources:", thisPlanState.requiredResources, " returnedMissingResourceArray:", returnedMissingResourceArray, " tribe id:", thisPlanState.tribeID, " restrictedResourceObjectTypes:", restrictedResourceObjectTypes, " thisPlanState:", thisPlanState)
                            --mj:log("thisPlanState.missingResources found object:", object.uniqueID, " missing:", returnedMissingResourceArray)
                        end
                    else
                        if thisPlanState.missingResources then
                            sharedState:remove("planStates", planTribeID, i, "missingResources")
                            needsSave = true
                        end
                    end

                    if thisPlanState.requiredTools then
                        local missingTools = nil
                        for l, toolTypeIndex in ipairs(thisPlanState.requiredTools) do
                            local toolObjectTypeIndexes = gameObject.gameObjectTypeIndexesByToolTypeIndex[toolTypeIndex]
                            local restrictedToolObjectTypes = sharedState.restrictedToolObjectTypes or thisPlanState.restrictedToolObjectTypes
                            
                            local toolBlockList = nil
                            local resourceBlockLists = serverWorld:getResourceBlockListsForTribe(thisPlanState.tribeID)
                            if resourceBlockLists then
                                toolBlockList = resourceBlockLists.toolBlockList
                            end

                            if restrictedToolObjectTypes or toolBlockList then
                                local strippedToolTypIndexes = {}
                                for m,toolObjectTypeIndex in ipairs(toolObjectTypeIndexes) do
                                    if (not toolBlockList) or (not toolBlockList[toolObjectTypeIndex]) then
                                        if (not restrictedToolObjectTypes) or (not restrictedToolObjectTypes[toolObjectTypeIndex]) then
                                            table.insert(strippedToolTypIndexes, toolObjectTypeIndex)
                                        end
                                    end
                                end
                                toolObjectTypeIndexes = strippedToolTypIndexes
                            end
                            
                            --mj:log("calling serverResourceManager:anyResourceIsAvailable for tools for plan state for object:", object.uniqueID)

                            if not serverResourceManager:anyResourceIsAvailable(toolObjectTypeIndexes, object.pos, true, thisPlanState.tribeID) then
                                if not missingTools then
                                    missingTools = {}
                                end
                                table.insert(missingTools, toolTypeIndex)
                            end
                        end

                        if not compareMissingToolsArrayEqual(thisPlanState.missingTools, missingTools) then
                            needsSave = true
                            sharedState:set("planStates", planTribeID, i, "missingTools", missingTools)
                            
                            --mj:log("thisPlanState.missingTools found object:", object.uniqueID, " missing:", missingTools)
                        end
                    else
                        if thisPlanState.missingTools then
                            sharedState:remove("planStates", planTribeID, i, "missingTools")
                            needsSave = true
                        end
                    end

                    
                    if thisPlanState.maintainQuantityOutputResourceCounts then
                        --mj:log("hi a:", object.uniqueID)
                        local shouldCraftMore = false
                        
                        for j,resourceInfo in ipairs(thisPlanState.maintainQuantityOutputResourceCounts) do
                            local nearbyCount = serverResourceManager:countOfResourcesNearPos(resourceInfo.resourceGroupTypeIndex or resourceInfo.resourceTypeIndex, object.pos, true, planTribeID, nil, nil)
                            sharedState:set("planStates", planTribeID, i, "maintainQuantityOutputResourceCounts", j, "nearbyCount", nearbyCount)

                            --mj:log("resourceInfo:", resourceInfo, "nearbyCount:", nearbyCount)
                            local thresholdMet = (nearbyCount >= resourceInfo.count)
                            if not thresholdMet then
                                shouldCraftMore = true
                                --mj:log("shouldCraftMore:", object.uniqueID)
                            end
                        end

                        if shouldCraftMore then
                            if thisPlanState.maintainQuantityThresholdMet then
                                sharedState:remove("planStates", planTribeID, i, "maintainQuantityThresholdMet")
                                needsSave = true
                            end
                        else
                            if not thisPlanState.maintainQuantityThresholdMet then
                                sharedState:set("planStates", planTribeID, i, "maintainQuantityThresholdMet", true)
                                --mj:log("maintainQuantityThresholdMet:", object.uniqueID)
                                needsSave = true
                            end
                        end
                    end
                    
                    if needsSave then
                        updateCanCompleteAndSave(object, sharedState, thisPlanState, planTribeID, i, false)
                    end
                end
            end
        end
    end
end

local function setCallbacksForResourceAvailabilityChanges(object)
    
    local resourceTypeIndexes = {}
    local foundTypes = {}

    local sharedState = object.sharedState
    local planStatesByTribeID = sharedState.planStates
    if planStatesByTribeID then
        for tribeID, planStates in pairs(planStatesByTribeID) do
            for i_,thisPlanState in ipairs(planStates) do
                if thisPlanState.requiredResources then
                    for i, requiredResourceInfo in ipairs(thisPlanState.requiredResources) do
                        if requiredResourceInfo.objectTypeIndex then
                            local resourceTypeIndex = gameObject.types[requiredResourceInfo.objectTypeIndex].resourceTypeIndex
                            if not foundTypes[resourceTypeIndex] then
                                foundTypes[resourceTypeIndex] = true
                                table.insert(resourceTypeIndexes, resourceTypeIndex)
                            end
                        elseif requiredResourceInfo.group then
                            for j,resourceTypeIndex in ipairs(resource.groups[requiredResourceInfo.group].resourceTypes) do
                                if not foundTypes[resourceTypeIndex] then
                                    foundTypes[resourceTypeIndex] = true
                                    table.insert(resourceTypeIndexes, resourceTypeIndex)
                                end
                            end
                        else
                            if not foundTypes[requiredResourceInfo.type] then
                                foundTypes[requiredResourceInfo.type] = true
                                table.insert(resourceTypeIndexes, requiredResourceInfo.type)
                            end
                        end
                    end
                end
                if thisPlanState.requiredTools then
                    for j,toolTypeIndex in ipairs(thisPlanState.requiredTools) do
                        --mj:log("tool type:", tool.types[toolTypeIndex])
                        local toolObjectTypeIndexes = gameObject.gameObjectTypeIndexesByToolTypeIndex[toolTypeIndex]
                        for l,toolObjectTypeIndex in ipairs(toolObjectTypeIndexes) do
                            local resourceTypeIndex = gameObject.types[toolObjectTypeIndex].resourceTypeIndex
                            if not foundTypes[resourceTypeIndex] then
                                foundTypes[resourceTypeIndex] = true
                                table.insert(resourceTypeIndexes, resourceTypeIndex)
                            end
                        end
                    end
                end
                if thisPlanState.maintainQuantityOutputResourceCounts then
                    for i,resourceInfo in ipairs(thisPlanState.maintainQuantityOutputResourceCounts) do
                        if resourceInfo.resourceGroupTypeIndex then
                            for j,resourceTypeIndex in ipairs(resource.groups[resourceInfo.resourceGroupTypeIndex].resourceTypes) do
                                if not foundTypes[resourceTypeIndex] then
                                    foundTypes[resourceTypeIndex] = true
                                    table.insert(resourceTypeIndexes, resourceTypeIndex)
                                end
                            end
                        else
                            if not foundTypes[resourceInfo.resourceTypeIndex] then
                                foundTypes[resourceInfo.resourceTypeIndex] = true
                                table.insert(resourceTypeIndexes, resourceInfo.resourceTypeIndex)
                            end
                        end
                    end
                end
            end
        end
    end

    if resourceTypeIndexes[1] then
        serverResourceManager:setCallbackForResourceAvailabilityChange(object.uniqueID, resourceTypeIndexes, object.pos, updateImpossibleStateForResourceAvailabilityChange)
        updateImpossibleStateForResourceAvailabilityChange(object.uniqueID)
    else
        serverResourceManager:removeCallbackForResourceAvailabilityChange(object.uniqueID)
    end
end

local function setCallbacksForStorageAreaContainedObjectsPlan(object)
    serverResourceManager:setCallbackForStorageAreaResourceAvailabilityChange(object.uniqueID, updateImpossibleStateForStorageAreaContainedObjectsPlanChange)
    updateImpossibleStateForStorageAreaContainedObjectsPlanChange(object.uniqueID)
end


local function setCallbacksForRequiredSkills(object, requiredSkillTypeIndexes)
    if requiredSkillTypeIndexes then
        serverSapienSkills:setCallbackForSkillAvailabilityChange(object.uniqueID, requiredSkillTypeIndexes, updateImpossibleStateForSkillChange)
    else
        serverSapienSkills:removeCallbackForSkillAvailabilityChange(object.uniqueID)
    end
end

local function getAndUpdateConstructionOptionalFallbackSkillTypeIndex(buildOrCraftObject, planState, planIndex)
    local optionalFallbackRequiredSkillTypeIndex = nil

    local isDeconstructOrRebuild = (planState.planTypeIndex == plan.types.deconstruct.index or planState.planTypeIndex == plan.types.rebuild.index)
    if isDeconstructOrRebuild then
        return
    end

    if planState.constructableTypeIndex then
        local constructableType = constructable.types[planState.constructableTypeIndex]
        local buildSequenceIndex = buildOrCraftObject.sharedState.buildSequenceIndex or 1
        local currentBuildSequenceInfo = constructableType.buildSequence[buildSequenceIndex]
        
        if currentBuildSequenceInfo then
            local constructableSequenceType = constructable.sequenceTypes[currentBuildSequenceInfo.constructableSequenceTypeIndex]
            if constructableSequenceType and constructableSequenceType.optionalFallbackSkill then
                optionalFallbackRequiredSkillTypeIndex = constructableSequenceType.optionalFallbackSkill
            end
        end
    end

    if optionalFallbackRequiredSkillTypeIndex then
        buildOrCraftObject.sharedState:set("planStates", planState.tribeID, planIndex, "optionalFallbackSkill", optionalFallbackRequiredSkillTypeIndex)
    else
        buildOrCraftObject.sharedState:remove("planStates", planState.tribeID, planIndex, "optionalFallbackSkill")
    end
    return optionalFallbackRequiredSkillTypeIndex
end

local function getCloseSapienExistsForPlan(orderObject, planState)
    --mj:log("getCloseSapienExistsForPlan:", orderObject.uniqueID, " tribeID:", planState.tribeID)
    if plan.types[planState.planTypeIndex].skipMaxOrderChecks then
        return true
    end

    local tribeID = planState.tribeID

    local closeSapiensBySkillType = getCloseSapiensBySkillTypeForObjectForTribe(planState.tribeID, orderObject.uniqueID, false)
    if closeSapiensBySkillType then
        local skillTypeIndexSaveKeyToUse = planState.requiredSkill or 0
        local closeSapiens = closeSapiensBySkillType[skillTypeIndexSaveKeyToUse]
        if closeSapiens then
            for sapienID,sapienTribeID in pairs(closeSapiens) do
                if sapienTribeID == tribeID then
                    --mj:log("getCloseSapienExistsForPlan a")
                    return true
                end
            end
        end

        if planState.optionalFallbackSkill then
            local optionalFallbackSkillTypeIndexSaveKeyToUse = planState.optionalFallbackSkill
            local optionalFallbackCloseSapiens = closeSapiensBySkillType[optionalFallbackSkillTypeIndexSaveKeyToUse]
            if optionalFallbackCloseSapiens then
                for sapienID,sapienTribeID in pairs(optionalFallbackCloseSapiens) do
                    if sapienTribeID == tribeID then
                        --mj:log("getCloseSapienExistsForPlan b")
                        return true
                    end
                end
            end
        end
    end

    local maxSearchDistance = planManager.maxPlanDistance
    if planState.manuallyPrioritized or planState.manualAssignedSapien then
        maxSearchDistance = planManager.maxAssignedOrPrioritizedPlanDistance
    end

    if planState.requiredSkill then

        local function testSkill(skillTypeIndex)
            if skillTypeIndex then

                local researchTypeIndex = planState.researchTypeIndex
                local closeContenders = serverGOM:getGameObjectsInSetWithinRadiusOfPos(skill.types[skillTypeIndex].sapienSetIndex, orderObject.pos, maxSearchDistance)
                for j,objectInfo in ipairs(closeContenders) do
                    local sapien = serverGOM:getObjectWithID(objectInfo.objectID)
                    if sapien and sapien.sharedState.tribeID == tribeID then
                        --mj:log("sapien.sharedState:", sapien.sharedState)
                        if skillTypeIndex == skill.types.researching.index and researchTypeIndex and research.types[researchTypeIndex].disallowsLimitedAbilitySapiens then
                            if not sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                                return true
                            end
                            return false
                        end
                        return true
                    end
                end
                --[[if skillTypeIndex == skill.types.researching.index then
                    local researchTypeIndex = planState.researchTypeIndex
                    if researchTypeIndex and research.types[researchTypeIndex].disallowsLimitedAbilitySapiens then
                        local closeContenders = serverGOM:getGameObjectsInSetWithinRadiusOfPos(skill.types[skillTypeIndex].sapienSetIndex, orderObject.pos, planManager.maxPlanDistance)
                        for j,objectInfo in ipairs(closeContenders) do
                            local sapien = serverGOM:getObjectWithID(objectInfo.objectID)
                            if sapien and sapien.sharedState.tribeID == tribeID then
                                if not sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                                    return true
                                end
                            end
                        end
                    else
                        if serverGOM:getGameObjectExistsInSetWithinRadiusOfPos(skill.types[skillTypeIndex].sapienSetIndex, orderObject.pos, planManager.maxPlanDistance) then
                            return true
                        end
                    end
                else
                    if serverGOM:getGameObjectExistsInSetWithinRadiusOfPos(skill.types[skillTypeIndex].sapienSetIndex, orderObject.pos, planManager.maxPlanDistance) then
                        return true
                    end
                end]]
            end
            return false
        end

        if testSkill(planState.requiredSkill) then
            --mj:log("getCloseSapienExistsForPlan c:", planState.requiredSkill)
            return true
        end
        if testSkill(planState.optionalFallbackSkill) then
            --mj:log("getCloseSapienExistsForPlan d")
            return true
        end

    else
        if serverGOM:getGameObjectExistsInSetWithinRadiusOfPos(serverGOM.objectSets.sapiens, orderObject.pos, maxSearchDistance) then
            --mj:log("getCloseSapienExistsForPlan e")
            return true
        end
    end

    return false
end


local function updateTooDistantState(orderObject, planState, planIndex)
    local foundClose = getCloseSapienExistsForPlan(orderObject, planState)

    if (not foundClose) then
        if planManager:assignNearbySapienToRequiredRoleIfable(planState.tribeID, planState.requiredSkill, orderObject.pos, planState) then
            foundClose = getCloseSapienExistsForPlan(orderObject, planState)
        end

        if (not foundClose) and planState.optionalFallbackSkill then
            if planManager:assignNearbySapienToRequiredRoleIfable(planState.tribeID, planState.optionalFallbackSkill, orderObject.pos, planState) then
                foundClose = getCloseSapienExistsForPlan(orderObject, planState)
            end
        end
    end

    if foundClose then
        if planState.tooDistant then
            orderObject.sharedState:remove("planStates", planState.tribeID, planIndex, "tooDistant")
            updateCanCompleteAndSave(orderObject, orderObject.sharedState, planState, planState.tribeID, planIndex, false)
        end
    else
        if not planState.tooDistant then
            orderObject.sharedState:set("planStates", planState.tribeID, planIndex, "tooDistant", planState.requiredSkill or 1)
            updateCanCompleteAndSave(orderObject, orderObject.sharedState, planState, planState.tribeID, planIndex, false)
        end
    end
end

local function updateRequiredSkills(orderObject, planState, planIndex)
    local requiredSkillTypeIndexes = {planState.requiredSkill}
    if planIndex then
        local optionalFallbackRequiredSkillTypeIndex = getAndUpdateConstructionOptionalFallbackSkillTypeIndex(orderObject, planState, planIndex)
        if optionalFallbackRequiredSkillTypeIndex then
            table.insert(requiredSkillTypeIndexes, optionalFallbackRequiredSkillTypeIndex)
        end
    end
    
    if planState.requiredSkill then
        serverGOM:addObjectToSet(orderObject, skill.types[planState.requiredSkill].planObjectSetIndex)
        if planState.optionalFallbackSkill then
            serverGOM:addObjectToSet(orderObject, skill.types[planState.optionalFallbackSkill].planObjectSetIndex)
        end
    else
        serverGOM:addObjectToSet(orderObject, serverGOM.objectSets.planObjectsWithoutRequiredSkill)
    end

    updateTooDistantState(orderObject, planState, planIndex)
    updateImpossibleStateForSkillChange(planState.tribeID, orderObject.uniqueID, nil, nil)
    setCallbacksForRequiredSkills(orderObject, requiredSkillTypeIndexes)
end

function planManager:removeManualAssignmentsForPlanObjectForSapien(object, sapien)
    local sharedState = object.sharedState
    local planStatesByTribeID = sharedState.planStates
    if planStatesByTribeID then
        local tribeID = sapien.sharedState.tribeID
        local planStates = planStatesByTribeID[tribeID]
        if planStates then
            for i,thisPlanState in ipairs(planStates) do
                if thisPlanState.manualAssignedSapien == sapien.uniqueID then
                    sharedState:remove("planStates", tribeID, i, "manualAssignedSapien")
                    updateTooDistantState(object, thisPlanState, i)
                    planManager:updateStorageAvailibilityForManualPrioritizationOrAssignment(object, thisPlanState)
                end
            end
        end
    end
end

local function addOrderToOrderedPlans(orderInfo, planState, orderedPlans, orderIndex)
    
    local planType = plan.types[planState.planTypeIndex]
    local priorityOffset = (orderInfo.priorityOffset or planState.priorityOffset) or planType.priorityOffset
    local manuallyPrioritized = (orderInfo.manuallyPrioritized or planState.manuallyPrioritized)

    --mj:log("addOrderToOrderedPlans planState:", planState)

    --[[if not orderInfo.priorityOffset and planType.priorityOffset then
        mj:error("no priorityOffset:", orderInfo, " planState:", planState)
    end]]

    
    if priorityOffset and priorityOffset > 0 then
        local found = false
        for j,otherInfo in ipairs(orderedPlans) do
            if manuallyPrioritized and (not otherInfo.manuallyPrioritized) then
                --mj:log("addOrderToOrderedPlans insert a at index:", j, " otherInfo:", otherInfo, " my info:", orderInfo)
                table.insert(orderedPlans, j, orderInfo)
                found = true
                break
            elseif (manuallyPrioritized == otherInfo.manuallyPrioritized) then
                if otherInfo.priorityOffset and otherInfo.priorityOffset == priorityOffset then
                    if planState.planOrderIndex then
                        if otherInfo.orderIndex > orderIndex then
                            --mj:log("addOrderToOrderedPlans insert b at index:", j, " otherInfo:", otherInfo, " my info:", orderInfo)
                            table.insert(orderedPlans, j, orderInfo)
                            found = true
                            break
                        end
                    end
                elseif (not otherInfo.priorityOffset) or otherInfo.priorityOffset < priorityOffset then
                    --if otherInfo.orderIndex > orderIndex then
                       --mj:log("addOrderToOrderedPlans insert c at index:", j, " otherInfo:", otherInfo, " my info:", orderInfo)
                        table.insert(orderedPlans, j, orderInfo)
                        found = true
                        break
                    --end
                end
            end
        end
        if not found then
           -- mj:log("addOrderToOrderedPlans insert d at index:", #orderedPlans, " orderInfo:", orderInfo)
            table.insert(orderedPlans, orderInfo)
        end
    elseif planState.planOrderIndex then
        local found = false
        for j,otherInfo in ipairs(orderedPlans) do
            if (manuallyPrioritized and (not otherInfo.manuallyPrioritized)) or (otherInfo.orderIndex > orderIndex) then
                --mj:log("addOrderToOrderedPlans insert e at index:", j, " otherInfo:", otherInfo, " my info:", orderInfo)
                table.insert(orderedPlans, j, orderInfo)
                found = true
                break
            end
        end
        if not found then
            --mj:log("addOrderToOrderedPlans insert f at index:", #orderedPlans, " orderInfo:", orderInfo)
            table.insert(orderedPlans, orderInfo)
        end
    else
        --mj:log("addOrderToOrderedPlans insert g at index:", #orderedPlans, " orderInfo:", orderInfo)
        table.insert(orderedPlans, orderInfo)
    end
end

function planManager:updateStorageAvailibilityForManualPrioritizationOrAssignment(object, planState)   
    
    local foundRequiredStorageObjectTypeIndex = planState.requiresStorageObjectTypeIndex
    if foundRequiredStorageObjectTypeIndex then
        local foundAvailableStorage = (not planState.missingStorage)
        serverStorageArea:setCallbackForStorageAvailabilityChange(planState.tribeID, 
            object.uniqueID, 
            foundRequiredStorageObjectTypeIndex, 
            object.pos, 
            foundAvailableStorage, 
            (planState.manualAssignedSapien or planState.manuallyPrioritized), 
            updateImpossibleStateForStorageAvailibilityChange)
    end

end

function planManager:addPlanObject(object)
    serverGOM:addObjectToSet(object, serverGOM.objectSets.plans)

    --local privateState = serverGOM:getPrivateState(object)

    local unsavedState = serverGOM:getUnsavedPrivateState(object)
    if not unsavedState.addedPlansByID then
        unsavedState.addedPlansByID = {}
    end

    local foundRequiredStorageObjectTypeIndex = nil
    local foundRequiredCraftAreaGroupTypeIndexes = nil
    local foundRequiredTerrainBaseTypeIndexes = nil
    local requiredResources = nil
    local requiredTools = nil
    local requiredSkills = nil
    local maintainQuantityOutputResourceCounts = nil
    local sharedState = object.sharedState
    local planStatesByTribeID = sharedState.planStates
    local hasDeconstructOrRebuildPlan = false
    local hasPlanRequiringLight = false


    if planStatesByTribeID then
        for tribeID,planStates in pairs(planStatesByTribeID) do

            if object.objectTypeIndex ~= gameObject.types.sapien.index then --don't bother adding for sapiens, as they have their own larger anchors already
                anchor:addAnchor(object.uniqueID, anchor.types.planObject.index, tribeID)
            end

            local orderedPlans = orderedPlansByTribeID[tribeID]
            if not orderedPlans then
                orderedPlans = {}
                orderedPlansByTribeID[tribeID] = orderedPlans
            end

            local maxPriority = 0

            local foundAvailableStorage = false
            local hasPrioritizedOrManuallyAssignedPlan = false

            --local manualPrioritizationFound = false
           -- local canComplete = false
            for i,thisPlanState in ipairs(planStates) do

                if not thisPlanState.planID then
                    sharedState:set("planStates", tribeID, i, "planID", planManager:getAndIncrementPlanID())
                end

                local addToIteratePlansList = thisPlanState.canComplete
                if not addToIteratePlansList then
                    if serverWorld:getAutoRoleAssignmentEnabled(tribeID) then
                        if thisPlanState.tooDistant and thisPlanState.requiredSkill then
                            --mj:log("add due to role assignment:", planState)
                            addToIteratePlansList = true
                        end
                    end
                end
            
                if addToIteratePlansList then
                    planManager.canPossiblyCompleteForSapienIterationByPlanID[thisPlanState.planID] = true
                else
                    planManager.canPossiblyCompleteForSapienIterationByPlanID[thisPlanState.planID] = nil
                end

                local planType = plan.types[thisPlanState.planTypeIndex]
                local priorityOffset = math.max(thisPlanState.priorityOffset or 0, planType.priorityOffset or 0)

               --[[ if thisPlanState.manuallyPrioritized then
                    manualPrioritizationFound = true
                end]]

                maxPriority = math.max(maxPriority, priorityOffset)

                if planType.requiresLight then
                    hasPlanRequiringLight = true
                    if thisPlanState.planTypeIndex == plan.types.build.index then
                        if thisPlanState.constructableTypeIndex then
                            local constructableType = constructable.types[thisPlanState.constructableTypeIndex]
                            if constructableType.allowBuildEvenWhenDark then
                                hasPlanRequiringLight = false
                            end
                        end
                    elseif thisPlanState.planTypeIndex == plan.types.research.index and thisPlanState.researchTypeIndex then
                        local researchType = research.types[thisPlanState.researchTypeIndex]
                        if researchType.allowResearchEvenWhenDark then
                            hasPlanRequiringLight = false
                        end
                    end
                end

                if not unsavedState.addedPlansByID[thisPlanState.planID] then
                    unsavedState.addedPlansByID[thisPlanState.planID] = true

                    if not planType.skipMaxOrderChecks then
                        local disabledDueToOrderLimit = thisPlanState.disabledDueToOrderLimit

                        local orderIndex = thisPlanState.planOrderIndex or thisPlanState.planID

                        local orderInfo = {
                            objectID = object.uniqueID,
                            planID = thisPlanState.planID,
                            disabledDueToOrderLimit = disabledDueToOrderLimit,
                            orderIndex = orderIndex,
                            priorityOffset = priorityOffset,
                            manuallyPrioritized = thisPlanState.manuallyPrioritized,
                        }
                        --mj:log("calling addOrderToOrderedPlans:", object.uniqueID)
                        addOrderToOrderedPlans(orderInfo, thisPlanState, orderedPlans, orderIndex)
                    end
                end

                -- mj:log("insert plan:", thisPlanState.planID, " objectID:", object.uniqueID, " tribeID:", tribeID)

                --[[if thisPlanState.canComplete then
                    canComplete = true
                end]]
                if thisPlanState.planTypeIndex == plan.types.deconstruct.index or thisPlanState.planTypeIndex == plan.types.rebuild.index then
                    hasDeconstructOrRebuildPlan = true
                end
                if thisPlanState.requiresStorageObjectTypeIndex then
                    foundRequiredStorageObjectTypeIndex = thisPlanState.requiresStorageObjectTypeIndex
                    foundAvailableStorage = (not thisPlanState.missingStorage)
                end
                if thisPlanState.requiresCraftAreaGroupTypeIndexes then
                    foundRequiredCraftAreaGroupTypeIndexes = thisPlanState.requiresCraftAreaGroupTypeIndexes
                end
                if thisPlanState.requiresTerrainBaseTypeIndexes then
                    foundRequiredTerrainBaseTypeIndexes = thisPlanState.requiresTerrainBaseTypeIndexes
                end
                
                if thisPlanState.requiredResources then
                    requiredResources = thisPlanState.requiredResources
                end
                if thisPlanState.requiredSkill then
                    requiredSkills = {thisPlanState.requiredSkill}
                    if thisPlanState.optionalFallbackSkill then
                        table.insert(requiredSkills, thisPlanState.optionalFallbackSkill)
                    end
                end
                if thisPlanState.requiredTools then
                    requiredTools = thisPlanState.requiredTools
                end
                if thisPlanState.maintainQuantityOutputResourceCounts then
                    maintainQuantityOutputResourceCounts = thisPlanState.maintainQuantityOutputResourceCounts
                end

                local adddedProximitySets = addedProximitySetsByPlanObjectID[object.uniqueID]
                if not adddedProximitySets then
                    adddedProximitySets = {}
                    addedProximitySetsByPlanObjectID[object.uniqueID] = adddedProximitySets
                end

                if thisPlanState.manuallyPrioritized or thisPlanState.manualAssignedSapien then
                    hasPrioritizedOrManuallyAssignedPlan = true
                end

                if thisPlanState.requiredSkill then
                    local setIndex = skill.types[thisPlanState.requiredSkill].planObjectSetIndex
                    --mj:log("adding plan object to set:", setIndex)
                    adddedProximitySets[setIndex] = true
                    serverGOM:addObjectToSet(object, setIndex)
                    if thisPlanState.optionalFallbackSkill then
                        local optionalFallbackSetIndex = skill.types[thisPlanState.requiredSkill].planObjectSetIndex
                        --mj:log("adding plan object to fallback set:", optionalFallbackSetIndex)
                        adddedProximitySets[optionalFallbackSetIndex] = true
                        serverGOM:addObjectToSet(object, optionalFallbackSetIndex)
                    end
                else
                    local setIndex = serverGOM.objectSets.planObjectsWithoutRequiredSkill
                    adddedProximitySets[setIndex] = true
                    serverGOM:addObjectToSet(object, setIndex)
                end
            end
            
            --[[if canComplete then
                addToCanCompleteList(object, tribeID, maxPriority, manualPrioritizationFound)
            end]]

            if foundRequiredStorageObjectTypeIndex then
                serverStorageArea:setCallbackForStorageAvailabilityChange(tribeID, object.uniqueID, foundRequiredStorageObjectTypeIndex, object.pos, foundAvailableStorage, hasPrioritizedOrManuallyAssignedPlan, updateImpossibleStateForStorageAvailibilityChange)
            end
        end
    end

    if hasPlanRequiringLight then
        planLightProbes:addPlanObject(object)
    end


    if gameObject.types[object.objectTypeIndex].isStorageArea and (not hasDeconstructOrRebuildPlan) then -- hasDeconstructPlan is a bit of a hack. may need to distinguish between area plans and contained object plans some other way
        setCallbacksForStorageAreaContainedObjectsPlan(object)
    end
    
    
    if foundRequiredCraftAreaGroupTypeIndexes then
        --mj:log("adding craft area callback:", object.uniqueID)
        serverCraftArea:addCallbackForAvailabilityChange(object.uniqueID, foundRequiredCraftAreaGroupTypeIndexes, object.pos, updateImpossibleStateForCraftAreaAvailibilityChange)
    end

    if foundRequiredTerrainBaseTypeIndexes then
        terrain:addCallbackForTerrainTypeChange(object.uniqueID, foundRequiredTerrainBaseTypeIndexes, object.pos, updateImpossibleStateForTerrainTypeAvailibilityChange)
    end

    if requiredResources or requiredTools or maintainQuantityOutputResourceCounts then
        setCallbacksForResourceAvailabilityChanges(object)
    end

    if requiredSkills then
        setCallbacksForRequiredSkills(object, requiredSkills)
    end

    if planStatesByTribeID then
        for tribeID,planStates in pairs(planStatesByTribeID) do
            if plansHaveBeenSortedByTribeID[tribeID] then
                if not needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[tribeID] then
                    needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[tribeID] = 0.0
                end
            end
        end
    end
end

function planManager:updatePlansForFollowerCountChange(tribeID, followerCount)
    maxOrdersByTribeID[tribeID] = math.max(followerCount * gameConstants.allowedPlansPerFollower, 1)
    if not needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[tribeID] then
        needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[tribeID] = 0.0
    end
end

function planManager:sortPlansForNewlyLoadedTribeID(tribeID, followerCount)
    
    local function sortByPlanID(a,b)
        if a.manuallyPrioritized ~= b.manuallyPrioritized then
            return a.manuallyPrioritized == true
        end
        local priorityOffsetA = a.priorityOffset or 0
        local priorityOffsetB = b.priorityOffset or 0
        if priorityOffsetA ~= priorityOffsetB then
            if priorityOffsetA > 0 or priorityOffsetB > 0 then
                return priorityOffsetA > priorityOffsetB
            end
        end

        local aIndex = a.orderIndex or a.planID
        local bIndex = b.orderIndex or b.planID
        return aIndex < bIndex
    end
    
    local orderedPlans = orderedPlansByTribeID[tribeID]
    if orderedPlans then
        table.sort(orderedPlans, sortByPlanID)
    end

    plansHaveBeenSortedByTribeID[tribeID] = true

    planManager:updatePlansForFollowerCountChange(tribeID, followerCount)
end

local function getPlanIndex(tribeID, planState, orderObject)
    if orderObject then
        local sharedState = orderObject.sharedState
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            for planTribeID,planStates in pairs(planStatesByTribeID) do
                if planTribeID == tribeID then
                    for i,thisPlanState in ipairs(planStates) do
                        if thisPlanState.planID == planState.planID then
                            return i
                        end
                    end
                end
            end
        end
    end
    return nil
end


function planManager:updateRequiredSkillsForBuildSequenceIncrement(orderObject, planState)
    local planIndex = getPlanIndex(planState.tribeID, planState, orderObject)
    if planIndex then
        updateRequiredSkills(orderObject, planState, planIndex)
    end
end

function planManager:setRequiredSkillForPlan(tribeID, planState, orderObject, requiredSkillTypeIndex)
    --mj:error("setRequiredSkillForPlan:", requiredSkillTypeIndex)
    local planIndex = getPlanIndex(tribeID, planState, orderObject)
    if planIndex then
        orderObject.sharedState:set("planStates", tribeID, planIndex, "requiredSkill", requiredSkillTypeIndex)
        updateRequiredSkills(orderObject, planState, planIndex)
    end
end

function planManager:updateRequiredResourcesForPlan(tribeID, planState, orderObject, requiredItems)

   --mj:log("planManager:updateRequiredResourcesForPlan:", orderObject.uniqueID, " requiredItems:", requiredItems, " orderObject.sharedState:", orderObject.sharedState)

    local planIndex = getPlanIndex(tribeID, planState, orderObject)
    --mj:log("planIndex:", planIndex, " planState:", planState, " tribeID:", tribeID)
    if planIndex then
        if requiredItems then
            orderObject.sharedState:set("planStates", tribeID, planIndex, "requiredResources", requiredItems.resources)
            orderObject.sharedState:set("planStates", tribeID, planIndex, "requiredTools", requiredItems.tools)
        else
            orderObject.sharedState:remove("planStates", tribeID, planIndex, "requiredResources")
            orderObject.sharedState:remove("planStates", tribeID, planIndex, "requiredTools")
        end
    end


    updateImpossibleStateForResourceAvailabilityChange(orderObject.uniqueID)
    setCallbacksForResourceAvailabilityChanges(orderObject)
end



function planManager:updatePlansForCraftFireLitStateChange(object)
    local planStatesByTribeID = object.sharedState.planStates
    if planStatesByTribeID then
        if object.sharedState.isLit then
            for tribeID,planStates in pairs(planStatesByTribeID) do
                for i,thisPlanState in ipairs(planStates) do
                    if thisPlanState.needsLit then
                        object.sharedState:remove("planStates", tribeID, i, "needsLit")
                        updateCanCompleteAndSave(object, object.sharedState, thisPlanState, tribeID, i, false)
                    end
                end
            end
            planManager:removePlanStateForObject(object, plan.types.light.index, nil, nil, nil, nil)
        else
            for tribeID,planStates in pairs(planStatesByTribeID) do
                for i,thisPlanState in ipairs(planStates) do
                    local planTypeIndex = thisPlanState.planTypeIndex
                    if planTypeIndex == plan.types.craft.index or planTypeIndex == plan.types.research.index then
                        if (not thisPlanState.needsLit) then
                            object.sharedState:set("planStates", tribeID, i, "needsLit", true)
                            updateCanCompleteAndSave(object, object.sharedState, thisPlanState, tribeID, i, false)
                        end
                    end
                end
            end
        end
        setCallbacksForResourceAvailabilityChanges(object)
    end
end

function planManager:removePlanObject(object)
    
    local planStatesByTribeID = object.sharedState.planStates
    if planStatesByTribeID then
        for tribeID,planStates in pairs(planStatesByTribeID) do
            for i,thisPlanState in ipairs(planStates) do
                planWillBeRemoved(object, thisPlanState)
            end
            object.sharedState:remove("planStates", tribeID)
            anchor:removeAnchor(object.uniqueID, anchor.types.planObject.index, tribeID)
        end
    end

    serverGOM:removeObjectFromSet(object, serverGOM.objectSets.plans)
    serverStorageArea:removeAllCallbacksForStorageAvailabilityChange(object.uniqueID, nil)
    serverCraftArea:removeAllCallbacksForAvailabilityChange(object.uniqueID)
    terrain:removeAllCallbacksForAvailabilityChange(object.uniqueID)
    serverResourceManager:removeCallbackForResourceAvailabilityChange(object.uniqueID)
    serverSapienSkills:removeCallbackForSkillAvailabilityChange(object.uniqueID)
    serverResourceManager:removeCallbackForStorageAreaResourceAvailabilityChange(object.uniqueID)
    
    planLightProbes:removePlanObject(object)

    --removeFromCanCompleteListDueToPlanOrObjectRemoval(object, true)

    --[[for tribeID,planObjectsByThisTribeID in pairs(planObjectsByTribeID) do
        for i, foundObject in ipairs(planObjectsByThisTribeID) do
            if foundObject == object then
                if #planObjectsByThisTribeID > i then
                    planObjectsByThisTribeID[i] = planObjectsByThisTribeID[#planObjectsByThisTribeID]
                end
                planObjectsByThisTribeID[#planObjectsByThisTribeID] = nil
                break
            end
        end
        --planObjectPositionsByThisTribeID[object.uniqueID] = nil
    end]]

    local addedProximitySets = addedProximitySetsByPlanObjectID[object.uniqueID]
    addedProximitySetsByPlanObjectID[object.uniqueID] = nil
    if addedProximitySets then
        for setIndex,v in pairs(addedProximitySets) do
            serverGOM:removeObjectFromSet(object, setIndex)
        end
    end

    for tribeID,closeSapiensBySkillTypeByObject in pairs(closeSapiensBySkillTypeByObjectByTribe) do
        closeSapiensBySkillTypeByObject[object.uniqueID] = nil
        if not next(closeSapiensBySkillTypeByObject) then
            closeSapiensBySkillTypeByObjectByTribe[tribeID] = nil
        end
    end
end

function planManager:updatePlanForConstructionObjectToolOrResourceChange(object, sapienOrNil, constructableType, tribeID)
    local planState = planManager:getPlanSateForConstructionObject(object, tribeID)
    if planState then
        local couldComplete = planState.canComplete
        local requiredItems = serverGOM:getRequiredItemsNotInInventory(object, planState, constructableType.requiredTools, constructableType.requiredResources, constructableType.index)
        planManager:updateRequiredResourcesForPlan(tribeID, planState, object, requiredItems)
        if not serverGOM:checkIfBuildOrCraftOrderIsComplete(object, sapienOrNil, planState) then
            updateImpossibleStateForResourceAvailabilityChange(object.uniqueID)
            serverGOM:resetBuildSequence(object)
            if (not couldComplete) and planState.canComplete then
                serverSapien:announce(object.uniqueID, tribeID)
            end
        end
    end
end

function planManager:updateAnyPlansForInventoryGatherRemoval(object)
    local sharedState = object.sharedState
    if sharedState then
        local countsByObjectTypes = nil
        if sharedState.inventory then
            countsByObjectTypes = sharedState.inventory.countsByObjectType
        end
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            for tribeID,planStates in pairs(planStatesByTribeID) do
                for i=#planStates,1,-1 do
                    local thisPlanState = planStates[i]
                    if thisPlanState.planTypeIndex == plan.types.gather.index then

                        local function removeGatherPlan()
                            planWillBeRemoved(object, thisPlanState)
                            sharedState:removeFromArray("planStates", tribeID, i)
                        end
                        
                        if (not countsByObjectTypes) then
                            removeGatherPlan()
                        else
                            if thisPlanState.objectTypeIndex then
                                if (not countsByObjectTypes[thisPlanState.objectTypeIndex]) or (countsByObjectTypes[thisPlanState.objectTypeIndex] <= 0) then
                                    removeGatherPlan()
                                end
                            else
                                local found = false
                                for objectTypeIndex, count in pairs(countsByObjectTypes) do
                                    if count > 0 then
                                        found = true
                                        break
                                    end
                                end

                                if not found then
                                    removeGatherPlan()
                                end
                            end
                        end
                    end
                end

                if not planStates[1] then
                    sharedState:remove("planStates", tribeID)
                    anchor:removeAnchor(object.uniqueID, anchor.types.planObject.index, tribeID)
                end
                
            end
            
            if not next(sharedState.planStates) then
                sharedState:remove("planStates")
                planManager:removePlanObject(object)
                serverGOM:saveObject(object.uniqueID)
            --else
                --removeFromCanCompleteListDueToPlanOrObjectRemoval(object, false)
            end
        end
    end
end

function planManager:removeAllPlanStatesForObject(object, sharedState, tribeIDOrNilForAll)
    if sharedState.planStates then
        local planStatesByTribeID = sharedState.planStates
        if planStatesByTribeID then
            for tribeID,planStates in pairs(planStatesByTribeID) do
                if not tribeIDOrNilForAll or (tribeID == tribeIDOrNilForAll) then
                    for i,thisPlanState in ipairs(planStates) do
                        planWillBeRemoved(object, thisPlanState)
                        checkRemoveSpecialStateForPlanStateRemoval(object, thisPlanState.planTypeIndex, thisPlanState.tribeID)
                    end
                end
            end
        end
        if tribeIDOrNilForAll then
            sharedState:remove("planStates", tribeIDOrNilForAll)
            updateAnchorForPlanAddedOrRemoved(object, tribeIDOrNilForAll)
            if not next(sharedState.planStates) then
                sharedState:remove("planStates")
                planManager:removePlanObject(object)
            --else
                --removeFromCanCompleteListDueToPlanOrObjectRemoval(object, false)
            end
        else
            for tribeID,planStates in pairs(planStatesByTribeID) do
                anchor:removeAnchor(object.uniqueID, anchor.types.planObject.index, tribeID)
            end
            sharedState:remove("planStates")
            planManager:removePlanObject(object)
        end
    else
        planManager:removePlanObject(object)
        serverGOM:saveObject(object.uniqueID)
    end
end

function planManager:getPlanStatesForObject(object, tribeID)
    
    if not tribeID then
        mj:error("no tribeID in planManager:getPlanStatesForObject")
        return nil
    end
    local sharedState = object.sharedState
    if sharedState then
        if sharedState.planStates and sharedState.planStates[tribeID] then
            if next(sharedState.planStates[tribeID]) then
                --mj:log("found:", sharedState.planStates[tribeID])
                return sharedState.planStates[tribeID]
            else
                planManager:removeAllPlanStatesForObject(object, sharedState, tribeID)
                serverGOM:saveObject(object.uniqueID)
            end
        end
    end
    return nil
end


function planManager:getPlanSateForConstructionObject(buildObjectOrCraftArea, tribeID)
    local planStates = planManager:getPlanStatesForObject(buildObjectOrCraftArea, tribeID)
    if planStates then
        for i,thisPlanState in ipairs(planStates) do
            if thisPlanState.planTypeIndex == plan.types.build.index or 
            thisPlanState.planTypeIndex == plan.types.deconstruct.index or 
            thisPlanState.planTypeIndex == plan.types.rebuild.index or 
            thisPlanState.planTypeIndex == plan.types.craft.index or 
            thisPlanState.planTypeIndex == plan.types.plant.index  or 
            thisPlanState.planTypeIndex == plan.types.research.index  or 
            thisPlanState.planTypeIndex == plan.types.fill.index or 
            thisPlanState.planTypeIndex == plan.types.fertilize.index or 
            thisPlanState.planTypeIndex == plan.types.buildPath.index then
                return thisPlanState
            end
        end
    end
    return nil
end

local function hasPlansAvailableForSapien(object, planState, planIndex, sapien)
    if not planState.canComplete then
        --disabled--mj:objectLog(object.uniqueID, "hasPlansAvailableForSapien:",  sapien.uniqueID)
        local assignedSapien = false
        if planState.tooDistant and planState.requiredSkill then
            if length2(object.pos - sapien.pos) < planManager.maxPlanDistance2 then
                --disabled--mj:objectLog(object.uniqueID, "planState.tooDistant and planState.requiredSkill")
                if serverWorld:getAutoRoleAssignmentIsAllowedForRole(sapien.sharedState.tribeID, planState.requiredSkill, sapien) then
                    --disabled--mj:objectLog(object.uniqueID, "RoleAssignmentIsAllowedForRole")
                    local allowed = checkSapienHasAbilityForRole(sapien, planState.requiredSkill, planState)
                    if allowed then
                        --disabled--mj:objectLog(object.uniqueID, "allowed")
                        if serverSapien:autoAssignToRole(sapien, planState.requiredSkill) then
                            ----disabled--mj:objectLog(object.uniqueID, "autoAssignToRole success")
                            updateTooDistantState(object, planState, planIndex)
                            if planState.canComplete then
                                --mj:log("success!")
                                assignedSapien = true
                            end
                        end
                    end
                end
            end
            --planManager:assignNearbySapienToRequiredRoleIfable(sapien.sharedState.tribeID, skillTypeIndexOrNil, planObjectPos, planState)
        end
        --disabled--mj:objectLog(sapien.uniqueID, "hasPlansAvailableForSapien fail a:", planState)
        if not assignedSapien then
            return false
        end
    end

    local planObjectSapienAssignmentInfo = serverSapien:getInfoForPlanObjectSapienAssignment(object, sapien, planState.planTypeIndex)
    if not planObjectSapienAssignmentInfo.available then
        --disabled--mj:objectLog(sapien.uniqueID, "hasPlansAvailableForSapien returning false due to other sapien assignment")
        return false
    end

   --[[ if serverSapien:objectIsAssignedToOtherSapien(object, sapien.sharedState.tribeID, nil, sapien, {planState.planTypeIndex}, true) then
        --disabled--mj:objectLog(sapien.uniqueID, "serverSapien:objectIsAssignedToOtherSapien")
        return false
    end]]

    if planState.sapienID == sapien.uniqueID then
       -- --disabled--mj:objectLog(sapien.uniqueID, "hasPlansAvailableForSapien c")
        return true
    end

    if not planState.sapienID then
       -- --disabled--mj:objectLog(sapien.uniqueID, "hasPlansAvailableForSapien d")
        return true
    end

   -- --disabled--mj:objectLog(sapien.uniqueID, "hasPlansAvailableForSapien e")
    return false
end

function planManager:getPlanStatesForObjectForSapien(object, sapien)
    if object.sharedState then
        --disabled--mj:objectLog(sapien.uniqueID, "getPlanStatesForObjectForSapien a")
        local planStatesForTribeID = planManager:getPlanStatesForObject(object, sapien.sharedState.tribeID)
        if planStatesForTribeID then
            --disabled--mj:objectLog(sapien.uniqueID, "getPlanStatesForObjectForSapien b")
            local result = {}
            for i,thisPlanState in ipairs(planStatesForTribeID) do
                --disabled--mj:objectLog(sapien.uniqueID, "getPlanStatesForObjectForSapien c")
                if hasPlansAvailableForSapien(object, thisPlanState, i, sapien) then
                    --disabled--mj:objectLog(sapien.uniqueID, "getPlanStatesForObjectForSapien d")
                    result[#result + 1] = thisPlanState
                end
            end
            if next(result) then
                --disabled--mj:objectLog(sapien.uniqueID, "getPlanStatesForObjectForSapien e")
                return result
            end
        end
    end
   -- --disabled--mj:objectLog(sapien.uniqueID, "getPlanStatesForObjectForSapien f. object.sharedState:", object.sharedState)
    return nil
end


function planManager:getPlanStateForObjectForSapienForPlanType(object, sapien, planTypeIndex)
    if object.sharedState then
        --disabled--mj:objectLog(sapien.uniqueID, "planManager:getPlanStateForObjectForSapienForPlanType:", planTypeIndex)
        local planStatesForTribeID = planManager:getPlanStatesForObject(object, sapien.sharedState.tribeID)
        if planStatesForTribeID then
            --disabled--mj:objectLog(sapien.uniqueID, "planManager:getPlanStateForObjectForSapienForPlanType, planStatesForTribeID:", planStatesForTribeID)
            for i,thisPlanState in ipairs(planStatesForTribeID) do
                if thisPlanState.planTypeIndex == planTypeIndex then
                    --disabled--mj:objectLog(sapien.uniqueID, "planManager:getPlanStateForObjectForSapienForPlanType, thisPlanState.planTypeIndex == planTypeIndex")
                    if hasPlansAvailableForSapien(object, thisPlanState, i, sapien) then
                        --disabled--mj:objectLog(sapien.uniqueID, "planManager:getPlanStateForObjectForSapienForPlanType, hasPlansAvailableForSapien")
                        return thisPlanState
                    end
                end
            end
        end
    end
    return nil
end

function planManager:getPlanStateForObject(object, planTypeIndex, objectTypeIndexOrNil, researchTypeIndexOrNil, tribeID, sapienIDOrNil)
    local sharedState = object.sharedState
    if sharedState then
        local planStatesForThisTribe = nil

        if sharedState.planStates and sharedState.planStates[tribeID] then
            planStatesForThisTribe =  sharedState.planStates[tribeID]
        end

        if planStatesForThisTribe then
            for i=#planStatesForThisTribe,1,-1 do
                local thisPlanState = planStatesForThisTribe[i]
                if thisPlanState.planTypeIndex == planTypeIndex and 
                ((not objectTypeIndexOrNil) or objectTypeIndexOrNil == thisPlanState.objectTypeIndex) and 
                ((not researchTypeIndexOrNil) or researchTypeIndexOrNil == thisPlanState.researchTypeIndex) and 
                ((not sapienIDOrNil) or sapienIDOrNil == thisPlanState.sapienID) then
                    return thisPlanState
                end
            end
        end
    end
    return nil
end


function planManager:hasPlanForObjectSapienAndType(sapien, planObject, planTypeIndex)
    local planStates = planManager:getPlanStatesForObjectForSapien(planObject, sapien)
    --disabled--mj:objectLog(sapien.uniqueID, "planManager:hasPlanForObjectSapienAndType planStates:", planStates, " planObject:", planObject.uniqueID)
    if planStates then
        for i,planState in ipairs(planStates) do
            if planState.planTypeIndex == planTypeIndex then
                return true
            end
        end
    end
    --disabled--mj:objectLog(sapien.uniqueID, "planManager:hasPlanForObjectSapienAndType returning false. planTypeIndex:", planTypeIndex)
    return false
end

--[[function planManager:removePlanObjectForTerrainModification(vertID, planTypeIndex, tribeID)
    local vert = terrain:getVertWithID(vertID)
    local sharedState = vert:getSharedState()

    if sharedState and sharedState.planObjectIDs then
        local objectIDsByPlanTypeIndex = sharedState.planObjectIDs[tribeID]
        if objectIDsByPlanTypeIndex then
            local objectID = objectIDsByPlanTypeIndex[planTypeIndex]
            if objectID then
                serverGOM:removeGameObject(objectID)
            end
        end
    end
end]]

function planManager:removePlanStateFromTerrainVertForTerrainModification(vertID, planTypeIndex, tribeID, researchTypeIndex)
    local vert = terrain:getVertWithID(vertID)
    if vert then
        local planObjectID = terrain:getObjectIDForTerrainModificationForVertex(vert)

        if planObjectID then
            local planObject = serverGOM:getObjectWithID(planObjectID)
            
            if not planObject then --added in 0.3.6
                terrain:loadArea(vert.normalizedVert)
                planObject = serverGOM:getObjectWithID(planObjectID)
                if not planObject then 
                    mj:error("planManager:removePlanStateFromTerrainVertForTerrainModification couldn't load plan object for terrain modification")
                    return
                end
            end

            planManager:removePlanStateForObject(planObject, planTypeIndex, nil, researchTypeIndex, tribeID, nil)
            serverGOM:planWasCancelledForObject(planObject, planTypeIndex, tribeID)
        end
    end
end

function planManager:getPlanStateForVertForTerrainModification(vertID, planTypeIndex, tribeID, researchTypeIndex)
    local vert = terrain:getVertWithID(vertID)
    if vert then
        local planObjectID = terrain:getObjectIDForTerrainModificationForVertex(vert)

        if planObjectID then
            local planObject = serverGOM:getObjectWithID(planObjectID)
            if planObject.sharedState then
                local planStatesForTribeID = planManager:getPlanStatesForObject(planObject, tribeID)
                if planStatesForTribeID then
                    for i,thisPlanState in ipairs(planStatesForTribeID) do
                        if thisPlanState.planTypeIndex == planTypeIndex and ((not researchTypeIndex) or researchTypeIndex == thisPlanState.researchTypeIndex) then
                            return thisPlanState
                        end
                    end
                end
            end
            
        end
    end
    return nil
end

function planManager:removePlanStateForObject(object, planTypeIndex, objectTypeIndex, researchTypeIndex, tribeIDOrNilForAll, sapienID)
    local sharedState = object.sharedState
    if sharedState then

        if sharedState.planStates then

            local function removeMatchingPlanStatesForTribeID(tribeID, planStatesForThisTribe)
                if planStatesForThisTribe then
                    local stillHasPlans = false
                    for i=#planStatesForThisTribe,1,-1 do
                        local thisPlanState = planStatesForThisTribe[i]
                        if thisPlanState.planTypeIndex == planTypeIndex and 
                        ((not objectTypeIndex) or objectTypeIndex == thisPlanState.objectTypeIndex) and 
                        ((not researchTypeIndex) or researchTypeIndex == thisPlanState.researchTypeIndex) and 
                        ((not sapienID) or sapienID == thisPlanState.sapienID) then
                            planWillBeRemoved(object, thisPlanState)
                            sharedState:removeFromArray("planStates", tribeID, i)
                            checkRemoveSpecialStateForPlanStateRemoval(object, planTypeIndex, tribeID)
                        else
                            stillHasPlans = true
                        end
                    end
                    if not stillHasPlans then
                        planManager:removeAllPlanStatesForObject(object, sharedState, tribeID)
                        anchor:removeAnchor(object.uniqueID, anchor.types.planObject.index, tribeID)
                    --else
                       -- removeFromCanCompleteListDueToPlanOrObjectRemoval(object, false)
                    end
                end
            end

            if tribeIDOrNilForAll then
                removeMatchingPlanStatesForTribeID(tribeIDOrNilForAll, sharedState.planStates[tribeIDOrNilForAll])
            else
                for tribeID,planStates in pairs(sharedState.planStates) do
                    removeMatchingPlanStatesForTribeID(tribeID, planStates)
                end
            end
        end
    end
end



local function getOrCreatePlanStates(sharedState, tribeID)
    local planStatesByTribeID = sharedState.planStates
    if not planStatesByTribeID then
        sharedState:set("planStates", {})
        planStatesByTribeID = sharedState.planStates
    end
    local planStates = planStatesByTribeID[tribeID]
    if not planStates then
        sharedState:set("planStates", tribeID, {})
        planStates = planStatesByTribeID[tribeID]
    end
    return planStates
end


local function addPlanState(object, 
    tribeID, 
    planTypeIndex, 
    objectTypeIndex, 
    sapienID, 
    researchTypeIndex, 
    discoveryCraftableTypeIndex, 
    constructableTypeIndex, 
    planOrderIndexOrNil, 
    planPriorityOffsetOrNil, 
    planManuallyPrioritizedOrNil,
    extraPlanStateDataOrNil,
    userDataOrNil) -- WARNING not used in all cases, eg.planManager:addBuildPlan doesn't call this

    if not object.sharedState then
        serverGOM:createSharedState(object)
        gameObjectSharedState:setupState(object, object.sharedState)
    end
    local objectState = object.sharedState

    local restrictedResourceObjectTypes = nil --todo
    
    serverGOM:removeInaccessible(object) --if we're queuing up a new plan, let's check again whether it's still inaccessible

    local requiresStorageObjectTypeIndex = nil
    local requiresCraftAreaGroupTypeIndexes = nil
    local requiresTerrainBaseTypeIndexes = nil
    local requiresShallowWater = nil

    local canComplete = true
    local missingStorage = nil
    local missingCraftArea = nil
    local missingSuitableTerrain = nil
    local missingShallowWater = nil
    local suitableTerrainVertID = nil
    local availablePlans = nil

    local foundPlanInfo = nil
    if planTypeIndex == plan.types.transferObject.index or 
    planTypeIndex == plan.types.destroyContents.index then -- bit of a hack, I guess there should be a superset of availablePlansForObjectInfos with hidden plans or something?
        foundPlanInfo = {
            planTypeIndex = planTypeIndex,
            requirements = {
                skill = skill.types.gathering.index,
            },
            hasNonQueuedAvailable = true,
        }
    else
        availablePlans = planHelper:availablePlansForObjectInfos(object, {object}, tribeID)
        if availablePlans then
            for i,planInfo in ipairs(availablePlans) do
                --mj:log("planInfo:", planInfo, " objectTypeIndex:", objectTypeIndex, " planTypeIndex:", planTypeIndex)
                --if planInfo.planTypeIndex == planTypeIndex and (planInfo.allowAnyObjectType or (planInfo.objectTypeIndex == objectTypeIndex)) and planInfo.hasNonQueuedAvailable then
                if planInfo.planTypeIndex == planTypeIndex and ((not objectTypeIndex) or planInfo.objectTypeIndex == objectTypeIndex) and planInfo.hasNonQueuedAvailable then
                    foundPlanInfo = planInfo
                    break
                elseif constructableTypeIndex and planInfo.planTypeIndex == plan.types.constructWith.index and planInfo.hasNonQueuedAvailable then
                    foundPlanInfo = planInfo
                    break
                end
            end
        end
    end


    if not foundPlanInfo then --this is OK, happens when multi-select attempts to queue plans for objects with mixed state
        --mj:warn("no valid available plan found in addPlanState for planTypeIndex:", planTypeIndex, " object:", object.uniqueID, " availablePlans:", availablePlans)
        return nil
    end

    if foundPlanInfo.disabled then
        return nil
    end

    local planStates = getOrCreatePlanStates(objectState, tribeID)

    for i,planState in ipairs(planStates) do
        if planState.planTypeIndex == planTypeIndex and planState.objectTypeIndex == objectTypeIndex and planState.sapienID == sapienID then --no duplicates
            mj:log("duplicate addPlanState for object:", object.uniqueID, ", not adding. ", "sapien IDS: plan: ", planState.sapienID, "sapien: ", sapienID)
            return nil
        end
    end
    
    if planTypeIndex == plan.types.storeObject.index or planTypeIndex == plan.types.transferObject.index then
        requiresStorageObjectTypeIndex = object.objectTypeIndex
        --if (not requiresStorageObjectTypeIndex) or (not serverStorageArea:storageAreaIsAvailableForObjectType(tribeID, requiresStorageObjectTypeIndex, object.pos)) then
            canComplete = false
            missingStorage = true --let the callback update this later
       -- end
    end

    local requiredSkill = nil
    local requiredTools = nil
    local requiredResources = nil
    local objectTypeIndexToUse = objectTypeIndex

    if researchTypeIndex then
        requiredSkill = skill.types.researching.index
        local researchType = research.types[researchTypeIndex]
        if researchType.constructableTypeIndex or researchType.constructableTypeIndexesByBaseResourceTypeIndex or researchType.constructableTypeIndexArraysByBaseResourceTypeIndex then
            local researchConstructableTypeIndex = researchType.constructableTypeIndex

            local function checkMatchesDiscoveryCraftableRequiredResource(resourceTypeIndex)
                if discoveryCraftableTypeIndex then
                    local craftableRequiredResources = constructable.types[discoveryCraftableTypeIndex].requiredResources
                    for i, requiredResourceInfo in ipairs(craftableRequiredResources) do
                        if resource:groupOrResourceMatchesResource(requiredResourceInfo.type or requiredResourceInfo.group, resourceTypeIndex) then
                            return true
                        end
                    end
                    return false
                end
                return true
            end

            if researchType.constructableTypeIndexesByBaseResourceTypeIndex or researchType.constructableTypeIndexArraysByBaseResourceTypeIndex then
                objectTypeIndexToUse = object.objectTypeIndex
                if gameObject.types[object.objectTypeIndex].isStorageArea then
                    objectTypeIndexToUse = objectTypeIndex
                    if not objectTypeIndexToUse then
                        local validResourceTypeIndexArray = researchType.resourceTypeIndexes
                        local validResourceTypeIndexSet = {}
                        for i, validResourceTypeIndex in ipairs(validResourceTypeIndexArray) do
                            if checkMatchesDiscoveryCraftableRequiredResource(validResourceTypeIndex) then
                                validResourceTypeIndexSet[validResourceTypeIndex] = true
                            end
                        end
                        objectTypeIndexToUse = serverStorageArea:getObjectTypeIndexMatchingResourceType(object, validResourceTypeIndexSet, restrictedResourceObjectTypes)
                    end
                end

                if discoveryCraftableTypeIndex then
                    researchConstructableTypeIndex = discoveryCraftableTypeIndex
                else
                    local complete = serverWorld:discoveryIsCompleteForTribe(tribeID, researchTypeIndex)
                    researchConstructableTypeIndex = research:getBestConstructableIndexForResearch(researchTypeIndex, gameObject.types[objectTypeIndexToUse].resourceTypeIndex, planHelper:getCraftableDiscoveriesForTribeID(tribeID), complete)
                end
            end
            
            if researchConstructableTypeIndex then
                local constructableType = constructable.types[researchConstructableTypeIndex]
                if constructableType then
                    if constructableType.requiredCraftAreaGroups then
                        requiresCraftAreaGroupTypeIndexes = constructableType.requiredCraftAreaGroups
                        if not serverCraftArea:anyCraftAreaAvailable(tribeID, requiresCraftAreaGroupTypeIndexes, object.pos, planTypeIndex) then
                            missingCraftArea = true
                            canComplete = false
                        end
                    elseif constructableType.requiresShallowWaterToResearch then
                        requiresShallowWater = true
                        suitableTerrainVertID = terrain:closeVertIDWithinRadiusNextToWater(object.pos, serverResourceManager.storageResourceMaxDistance)
                        if not suitableTerrainVertID then
                            missingShallowWater = true
                            canComplete = false
                        end
                    elseif constructableType.requiredTerrainTypes then
                        requiresTerrainBaseTypeIndexes = constructableType.requiredTerrainTypes
                        suitableTerrainVertID = terrain:closeVertIDWithinRadiusOfTypes(requiresTerrainBaseTypeIndexes, object.pos, serverResourceManager.storageResourceMaxDistance)
                        if not suitableTerrainVertID then
                            missingSuitableTerrain = true
                            canComplete = false
                        end
                    end
                end
            elseif researchType.requiredToolTypeIndex then
                requiredTools = {researchType.requiredToolTypeIndex}
            end
        elseif researchType.requiredToolTypeIndex then
            requiredTools = {researchType.requiredToolTypeIndex}
        end
    elseif constructableTypeIndex then
        local constructableType = constructable.types[constructableTypeIndex]
        if constructableType.requiredCraftAreaGroups then
            requiresCraftAreaGroupTypeIndexes = constructableType.requiredCraftAreaGroups
            if not serverCraftArea:anyCraftAreaAvailable(tribeID, requiresCraftAreaGroupTypeIndexes, object.pos, planTypeIndex) then
                missingCraftArea = true
                canComplete = false
            end
        elseif constructableType.requiredTerrainTypes then
            requiresTerrainBaseTypeIndexes = constructableType.requiredTerrainTypes
            suitableTerrainVertID = terrain:closeVertIDWithinRadiusOfTypes(requiresTerrainBaseTypeIndexes, object.pos, serverResourceManager.storageResourceMaxDistance)
            if not suitableTerrainVertID then
                missingSuitableTerrain = true
                canComplete = false
            end
        end
    end
    
    if foundPlanInfo.requirements then --changed 0.4 to override the researchType with the planInfo from planHelper, as it gives more contextural control 
        if foundPlanInfo.requirements.skill then
            requiredSkill = foundPlanInfo.requirements.skill
        end
        if foundPlanInfo.requirements.toolTypeIndex then
            requiredTools = {foundPlanInfo.requirements.toolTypeIndex}
        end
    end

    --mj:log("requiredTools:", requiredTools, " foundPlanInfo:", foundPlanInfo)
    local suitableTerrainVertPos = nil
    if suitableTerrainVertID then
        local vert = terrain:getVertWithID(suitableTerrainVertID)
        if vert then
            suitableTerrainVertPos = vert.pos
        end
    end

    local priorityOffset = planPriorityOffsetOrNil
    local planTypePriorityOffset = plan.types[planTypeIndex].priorityOffset
    if planTypePriorityOffset then
        if (not priorityOffset) or priorityOffset < planTypePriorityOffset then
            priorityOffset = planTypePriorityOffset
        end
    end 

    local planID = nil
    if userDataOrNil and userDataOrNil.frontOfTheQueue then
        planID = planManager:getAndIncrementPrioritizedID()
        planOrderIndexOrNil = planID
    else
        planID = planManager:getAndIncrementPlanID()
    end

    local planState = {
        tribeID = tribeID,
        planID = planID,
        planTypeIndex = planTypeIndex,
        objectTypeIndex = objectTypeIndexToUse,
        researchTypeIndex = researchTypeIndex,
        discoveryCraftableTypeIndex = discoveryCraftableTypeIndex,
        constructableTypeIndex = constructableTypeIndex,
        sapienID = sapienID,
        canComplete = canComplete,
        requiresStorageObjectTypeIndex = requiresStorageObjectTypeIndex,
        requiredTools = requiredTools,
        requiredSkill = requiredSkill,
        missingStorage = missingStorage,
        requiresCraftAreaGroupTypeIndexes = requiresCraftAreaGroupTypeIndexes,
        requiresTerrainBaseTypeIndexes = requiresTerrainBaseTypeIndexes,
        requiresShallowWater = requiresShallowWater,
        missingCraftArea = missingCraftArea,
        missingSuitableTerrain = missingSuitableTerrain,
        missingShallowWater = missingShallowWater,
        suitableTerrainVertID = suitableTerrainVertID,
        suitableTerrainVertPos = suitableTerrainVertPos,
        planOrderIndex = planOrderIndexOrNil,
        priorityOffset = priorityOffset,
        manuallyPrioritized = planManuallyPrioritizedOrNil,
        supressStoreOrders = userDataOrNil and userDataOrNil.supressStoreOrders,
    }
    if canComplete then
        planManager.canPossiblyCompleteForSapienIterationByPlanID[planID] = true
    end

    if extraPlanStateDataOrNil then
        for k,v in pairs(extraPlanStateDataOrNil) do
            planState[k] = v
        end
    end

    local insertIndex = 1
    if objectState.planStates and objectState.planStates[tribeID] then
        insertIndex = #objectState.planStates[tribeID] + 1
    end
    objectState:set("planStates", tribeID, insertIndex, planState)

    local requiredItems = nil
    if planTypeIndex == plan.types.light.index or planTypeIndex == plan.types.addFuel.index then
        requiredItems = fuel:getRequiredItemsForFuelAdd(object)
    elseif plan.types[planTypeIndex].isMedicineTreatment then
        requiredItems = medicine:getRequiredItemsForPlanType(planTypeIndex)
    elseif planTypeIndex == plan.types.deliverToCompost.index then
        requiredItems = serverCompostBin:getRequiredItems(object, tribeID)
    else
        requiredItems = serverGOM:getRequiredItemsNotInInventory(object, planState, requiredTools, requiredResources, constructableTypeIndex)
    end
    planManager:updateRequiredResourcesForPlan(tribeID, planState, object, requiredItems)

    
    if requiredSkill then
        planManager:setRequiredSkillForPlan(tribeID, planState, object, requiredSkill)
    end

    planManager:addPlanObject(object)
    --serverSapien:cancelOrdersIfNeededDueToPlanAddedForObjectForTribe(object.uniqueID, tribeID)
    
    if planState.canComplete then
        serverSapien:announce(object.uniqueID, tribeID)
    end

    if researchTypeIndex then
        
        if discoveryCraftableTypeIndex and serverWorld:discoveryIsCompleteForTribe(tribeID, researchTypeIndex) then
            serverWorld:startCraftableDiscoveryForTribe(tribeID, discoveryCraftableTypeIndex, object.uniqueID)
        else
            serverWorld:startDiscoveryForTribe(tribeID, researchTypeIndex, object.uniqueID)
        end
    end

    return planState
end

function planManager:addCraftPlan(tribeID, 
    planTypeIndex, 
    craftAreaObjectID, 
    craftResourcePlanObjectID, 
    constructableTypeIndex, 
    craftCount, 
    researchTypeIndex, 
    discoveryCraftableTypeIndex, 
    restrictedResourceObjectTypesOrNil, 
    restrictedToolObjectTypesOrNil,
    planOrderIndexOrNil,
    planPriorityOffsetOrNil,
    planManuallyPrioritizedOrNil,
    shouldMaintainSetQuantity)

    if (not constructableTypeIndex) then
        mj:error("(not constructableTypeIndex) in addCraftPlan")
        return false
    end

    local constructableType = constructable.types[constructableTypeIndex]

    if craftResourcePlanObjectID then
        --mj:log("planManager:addCraftPlan constructableType:", constructableType)
        if constructableType.requiredCraftAreaGroups then
            planManager:addStandardPlan(tribeID, planTypeIndex, craftResourcePlanObjectID, nil, researchTypeIndex, discoveryCraftableTypeIndex, constructableTypeIndex, 
            planOrderIndexOrNil,
            planPriorityOffsetOrNil, 
            planManuallyPrioritizedOrNil)
            return true
        else
            local object = serverGOM:getObjectWithID(craftResourcePlanObjectID)
            if gameObject.types[object.objectTypeIndex].isStorageArea then
                planManager:addStandardPlan(tribeID, planTypeIndex, craftResourcePlanObjectID, nil, researchTypeIndex, discoveryCraftableTypeIndex, constructableTypeIndex, 
                planOrderIndexOrNil,
                planPriorityOffsetOrNil,
                planManuallyPrioritizedOrNil)
            else
                local craftResourcePlanObject = serverGOM:getObjectWithID(craftResourcePlanObjectID)
                local addObjectInfo = serverGOM:convertToTemporaryCraftArea(craftResourcePlanObject, tribeID)
                if planManager:addCraftPlan(tribeID, planTypeIndex, craftResourcePlanObjectID, nil, constructableTypeIndex, 1, researchTypeIndex, discoveryCraftableTypeIndex, restrictedResourceObjectTypesOrNil, restrictedToolObjectTypesOrNil,
                planOrderIndexOrNil,
                planPriorityOffsetOrNil,
                planManuallyPrioritizedOrNil, shouldMaintainSetQuantity) then
                    --craftResourcePlanObject.sharedState:set("inProgressConstructableTypeIndex", constructableTypeIndex)
                    serverGOM:addConstructionObjectComponent(craftResourcePlanObject, addObjectInfo, tribeID)
                    return true
                else
                    return false
                end
            end
        end
    end

    if (not craftAreaObjectID) then
        mj:error("(not craftAreaObjectID) in addCraftPlan")
        return false
    end
    
    local object = serverGOM:getObjectWithID(craftAreaObjectID)

    if not object then
        mj:log("object not loaded in addCraftPlan")
        return false
    end

    local objectState = object.sharedState
    serverGOM:removeInaccessible(object) --if we're queuing up a new plan, let's check again whether it's still inaccessible

    local planStates = getOrCreatePlanStates(objectState, tribeID)

    for i,planState in ipairs(planStates) do
        if planState.planTypeIndex == planTypeIndex  then --no duplicates
            mj:error("duplicate addCraftPlan for object:", object.uniqueID, ", not adding.")
            return false
        end
    end

    local canComplete = true
    
    local priorityOffset = planPriorityOffsetOrNil
    local planTypePriorityOffset = plan.types[planTypeIndex].priorityOffset
    if planTypePriorityOffset then
        if (not priorityOffset) or priorityOffset < planTypePriorityOffset then
            priorityOffset = planTypePriorityOffset
        end
    end 

    local planState = {
        tribeID = tribeID,
        planID = planManager:getAndIncrementPlanID(),
        planTypeIndex = planTypeIndex,
        constructableTypeIndex = constructableTypeIndex,
        researchTypeIndex = researchTypeIndex,
        discoveryCraftableTypeIndex = discoveryCraftableTypeIndex,
        craftCount = craftCount,
        canComplete = canComplete,
        currentCraftIndex = 1,
        planOrderIndex = planOrderIndexOrNil,
        priorityOffset = priorityOffset,
        manuallyPrioritized = planManuallyPrioritizedOrNil,
        shouldMaintainSetQuantity = shouldMaintainSetQuantity,
    }

    if canComplete then
        planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
    end

    if shouldMaintainSetQuantity and craftCount > 0 then
        local maintainQuantityOutputResourceCounts = {}
        local outputDisplayCounts = constructableType.outputDisplayCounts
        
        for i,displayinfo in ipairs(outputDisplayCounts) do
            table.insert(maintainQuantityOutputResourceCounts, {
                resourceTypeIndex = displayinfo.type,
                resourceGroupTypeIndex = displayinfo.group,
                count = craftCount * displayinfo.count,
            })
        end
        
        planState.maintainQuantityOutputResourceCounts = maintainQuantityOutputResourceCounts
    end

    objectState:set("planStates", tribeID, #objectState.planStates[tribeID] + 1, planState)

    objectState:remove("buildSequenceIndex")
    objectState:remove("buildSequenceRepeatCounters")
    --objectState:set("inProgressConstructableTypeIndex", constructableTypeIndex)
    
    if restrictedResourceObjectTypesOrNil and next(restrictedResourceObjectTypesOrNil) then
        objectState:set("restrictedResourceObjectTypes", restrictedResourceObjectTypesOrNil)
    else
        objectState:remove("restrictedResourceObjectTypes")
    end
    if restrictedToolObjectTypesOrNil and next(restrictedToolObjectTypesOrNil) then
        objectState:set("restrictedToolObjectTypes", restrictedToolObjectTypesOrNil)
    else
        objectState:remove("restrictedToolObjectTypes")
    end

    serverResourceManager:updateResourcesForObject(object) --craft areas's resources are no longer available if it has a plan state
    serverCraftArea:updateInUseStateForCraftArea(object)

    serverGOM:saveObject(object.uniqueID)

    planManager:addPlanObject(object)

    --mj:log("hi dave constructableType:", constructableType)

    local requiredItems = serverGOM:getRequiredItemsNotInInventory(object, planState, constructableType.requiredTools, constructableType.requiredResources, constructableType.index)
    planManager:updateRequiredResourcesForPlan(tribeID, planState, object, requiredItems)

    if object.objectTypeIndex == gameObject.types.campfire.index or object.objectTypeIndex == gameObject.types.brickKiln.index then
        planManager:updatePlansForCraftFireLitStateChange(object)
    end
    
    
    if researchTypeIndex then
        planManager:setRequiredSkillForPlan(tribeID, planState, object, skill.types.researching.index)
        
        if discoveryCraftableTypeIndex and serverWorld:discoveryIsCompleteForTribe(tribeID, researchTypeIndex) then
            serverWorld:startCraftableDiscoveryForTribe(tribeID, discoveryCraftableTypeIndex, object.uniqueID)
        else
            serverWorld:startDiscoveryForTribe(tribeID, researchTypeIndex, object.uniqueID)
        end

    else
        if constructableType.skills and constructableType.skills.required then
            planManager:setRequiredSkillForPlan(tribeID, planState, object, constructableType.skills.required)
        end
    end

    if planState.canComplete then
        serverSapien:announce(object.uniqueID, tribeID)
    end


    return true
end

function planManager:addDeconstructPlanForEmptyConstructedObject(tribeID, buildObject)
    local sharedState = buildObject.sharedState
    local constructableTypeIndex = sharedState.inProgressConstructableTypeIndex
            
    if not constructableTypeIndex then
        constructableTypeIndex = sharedState.constructionConstructableTypeIndex
        if constructableTypeIndex then
            local constructableType = constructable.types[constructableTypeIndex]
            if constructableType.buildSequence then
                serverGOM:convertFinalBuildObjectToInProgressForDeconstruction(buildObject, tribeID)
            else
                serverGOM:ejectTools(buildObject, tribeID, nil, nil, nil)
                serverGOM:removeGameObject(buildObject.uniqueID)
                return
            end
        end
    end

    if constructableTypeIndex then
        
        local planState = {
            tribeID = tribeID,
            planID = planManager:getAndIncrementPlanID(),
            planTypeIndex = plan.types.deconstruct.index,
            canComplete = true,
            constructableTypeIndex = constructableTypeIndex,
            priorityOffset = plan.types.deconstruct.priorityOffset
        }

        planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
        
        local constructableType = constructable.types[constructableTypeIndex]
        
        local insertIndex = 1
        if sharedState.planStates and sharedState.planStates[tribeID] then
            insertIndex = #sharedState.planStates[tribeID] + 1
        end
        sharedState:set("planStates", tribeID, insertIndex, planState)

        if constructableType.skills and constructableType.skills.required then
            planManager:setRequiredSkillForPlan(tribeID, planState, buildObject, constructableType.skills.required)
        end
        serverSapien:announce(buildObject.uniqueID, tribeID)
        planManager:addPlanObject(buildObject)

        serverGOM:saveObject(buildObject.uniqueID)

        serverGOM:checkIfNeedsToIncrementBuildSequenceDueToMoveComponentsComplete(buildObject, nil, planState)
        serverGOM:checkIfBuildOrCraftOrderIsComplete(buildObject, nil, planState)
    end
end


function planManager:addRebuildPlanForEmptyConstructedObject(tribeID, buildObject, rebuildConstructableTypeIndex, restrictedResourceObjectTypes, restrictedToolObjectTypes)
    local sharedState = buildObject.sharedState
    local constructableTypeIndex = sharedState.inProgressConstructableTypeIndex
            
    if not constructableTypeIndex then
        constructableTypeIndex = sharedState.constructionConstructableTypeIndex
        if constructableTypeIndex then
            local constructableType = constructable.types[constructableTypeIndex]
            if constructableType.buildSequence then
                serverGOM:convertFinalBuildObjectToInProgressForDeconstruction(buildObject, tribeID)
            else
                serverGOM:ejectTools(buildObject, tribeID, nil, nil, nil)
                planManager:addBuildOrPlantPlanForRebuild(buildObject.uniqueID, tribeID, rebuildConstructableTypeIndex, restrictedResourceObjectTypes, restrictedToolObjectTypes)
                serverGOM:removeGameObject(buildObject.uniqueID) --todo convert to new object
                return
            end
        end
    end

    if constructableTypeIndex then
        local planState = {
            tribeID = tribeID,
            planID = planManager:getAndIncrementPlanID(),
            planTypeIndex = plan.types.rebuild.index,
            canComplete = true,
            constructableTypeIndex = constructableTypeIndex,
            priorityOffset = plan.types.rebuild.priorityOffset,
            
            rebuildConstructableTypeIndex = rebuildConstructableTypeIndex,
            rebuildRestrictedResourceObjectTypes = restrictedResourceObjectTypes,
            rebuildRestrictedToolObjectTypes = restrictedToolObjectTypes,
        }
        
        planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true

        local constructableType = constructable.types[constructableTypeIndex]
        
        local insertIndex = 1
        if sharedState.planStates and sharedState.planStates[tribeID] then
            insertIndex = #sharedState.planStates[tribeID] + 1
        end
        sharedState:set("planStates", tribeID, insertIndex, planState)

        if constructableType.skills and constructableType.skills.required then
            planManager:setRequiredSkillForPlan(tribeID, planState, buildObject, constructableType.skills.required)
        end
        serverSapien:announce(buildObject.uniqueID, tribeID)
        planManager:addPlanObject(buildObject)

        serverGOM:saveObject(buildObject.uniqueID)

        serverGOM:checkIfNeedsToIncrementBuildSequenceDueToMoveComponentsComplete(buildObject, nil, planState)
        serverGOM:checkIfBuildOrCraftOrderIsComplete(buildObject, nil, planState)
    end
end

function planManager:addDeconstructPlan(tribeID, objectID)
    local buildObject = serverGOM:getObjectWithID(objectID)
    if buildObject then
        local sharedState = buildObject.sharedState
        
        local planStates = getOrCreatePlanStates(sharedState, tribeID)
        if next(planStates) then
            planManager:removeAllPlanStatesForObject(buildObject, sharedState, tribeID)
            --mj:error("existing plan state in addDeconstructPlan:", buildObject.uniqueID, ", not adding.") -- don't allow deconstruction unless all other plans have been cancelled
            --return false
        end

        serverGOM:removeInaccessible(buildObject) --if we're queuing up a new plan, let's check again whether it's still inaccessible

        local function addDeconstructPlanForRemovingInventory()
            local planState = {
                tribeID = tribeID,
                planID = planManager:getAndIncrementPlanID(),
                planTypeIndex = plan.types.deconstruct.index,
                canComplete = true,
                priorityOffset = plan.types.deconstruct.priorityOffset,
            }
            planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
            local insertIndex = 1
            if sharedState.planStates and sharedState.planStates[tribeID] then
                insertIndex = #sharedState.planStates[tribeID] + 1
            end

            local constructableTypeIndex = sharedState.inProgressConstructableTypeIndex
            if not constructableTypeIndex then
                constructableTypeIndex = sharedState.constructionConstructableTypeIndex
            end

            if constructableTypeIndex then

                local constructableType = constructable.types[constructableTypeIndex]
                planManager:setRequiredSkillForPlan(tribeID, planState, buildObject, constructableType.skills.required)

                sharedState:set("planStates", tribeID, insertIndex, planState)
                sharedState:set("settingsByTribe", tribeID, "removeAllDueToDeconstruct", true)
                serverSapien:announce(buildObject.uniqueID, tribeID)
                planManager:addPlanObject(buildObject)
                serverGOM:saveObject(buildObject.uniqueID)
            end
        end

        local gameObjectType = gameObject.types[buildObject.objectTypeIndex]
        if gameObjectType.isStorageArea then
            if not sharedState.inventory or not sharedState.inventory.objects or #sharedState.inventory.objects == 0 then
                if gameObjectType.buildRequiresNoResources then
                    serverGOM:removeGameObject(objectID)
                else
                    planManager:addDeconstructPlanForEmptyConstructedObject(tribeID, buildObject)
                end
            else
                addDeconstructPlanForRemovingInventory()
            end
        elseif buildObject.objectTypeIndex == gameObject.types.compostBin.index then
            if not sharedState.inventory or not sharedState.inventory.objects or #sharedState.inventory.objects == 0 then
                planManager:addDeconstructPlanForEmptyConstructedObject(tribeID, buildObject)
            else
                addDeconstructPlanForRemovingInventory()
            end
        else
            planManager:addDeconstructPlanForEmptyConstructedObject(tribeID, buildObject)
        end

    end
end


function planManager:addRebuildPlan(tribeID, objectID, constructableTypeIndex, restrictedResourceObjectTypes, restrictedToolObjectTypes)
    local buildObject = serverGOM:getObjectWithID(objectID)
    if buildObject then
        local sharedState = buildObject.sharedState
        
        local planStates = getOrCreatePlanStates(sharedState, tribeID)
        if next(planStates) then
            planManager:removeAllPlanStatesForObject(buildObject, sharedState, tribeID)
            --mj:error("existing plan state in addDeconstructPlan:", buildObject.uniqueID, ", not adding.") -- don't allow deconstruction unless all other plans have been cancelled
            --return false
        end

        serverGOM:removeInaccessible(buildObject) --if we're queuing up a new plan, let's check again whether it's still inaccessible

        local function addPlanForRemovingInventory()
            local planState = {
                tribeID = tribeID,
                planID = planManager:getAndIncrementPlanID(),
                planTypeIndex = plan.types.rebuild.index,
                canComplete = true,
                priorityOffset = plan.types.rebuild.priorityOffset,
                rebuildConstructableTypeIndex = constructableTypeIndex,
                rebuildRestrictedResourceObjectTypes = restrictedResourceObjectTypes,
                rebuildRestrictedToolObjectTypes = restrictedToolObjectTypes,
            }
            planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
            local insertIndex = 1
            if sharedState.planStates and sharedState.planStates[tribeID] then
                insertIndex = #sharedState.planStates[tribeID] + 1
            end
            sharedState:set("planStates", tribeID, insertIndex, planState)
            sharedState:set("settingsByTribe", tribeID, "removeAllDueToDeconstruct", true)
            serverSapien:announce(buildObject.uniqueID, tribeID)
            planManager:addPlanObject(buildObject)
            serverGOM:saveObject(buildObject.uniqueID)
        end

        if gameObject.types[buildObject.objectTypeIndex].isStorageArea then
            if not sharedState.inventory or not sharedState.inventory.objects or #sharedState.inventory.objects == 0 then
                serverGOM:removeGameObject(objectID)
            else
                addPlanForRemovingInventory()
            end
        elseif buildObject.objectTypeIndex == gameObject.types.compostBin.index then
            if not sharedState.inventory or not sharedState.inventory.objects or #sharedState.inventory.objects == 0 then
                planManager:addRebuildPlanForEmptyConstructedObject(tribeID, buildObject, constructableTypeIndex, restrictedResourceObjectTypes, restrictedToolObjectTypes)
            else
                addPlanForRemovingInventory()
            end
        else
            planManager:addRebuildPlanForEmptyConstructedObject(tribeID, buildObject, constructableTypeIndex, restrictedResourceObjectTypes, restrictedToolObjectTypes)
        end

    end
end

local function finalizeBuildOrPlantPlan(tribeID, 
    buildObject, 
    planState, 
    constructableType,
    restrictedResourceObjectTypesOrNil,
    restrictedToolObjectTypesOrNil)

    local requiredItems = serverGOM:getRequiredItemsNotInInventory(buildObject, planState, constructableType.requiredTools, constructableType.requiredResources, constructableType.index)
    planManager:updateRequiredResourcesForPlan(tribeID, planState, buildObject, requiredItems)

    if restrictedResourceObjectTypesOrNil and next(restrictedResourceObjectTypesOrNil) then
        buildObject.sharedState:set("restrictedResourceObjectTypes", restrictedResourceObjectTypesOrNil)
    end
    if restrictedToolObjectTypesOrNil and next(restrictedToolObjectTypesOrNil) then
        buildObject.sharedState:set("restrictedToolObjectTypes", restrictedToolObjectTypesOrNil)
    end

    if constructableType.skills and constructableType.skills.required then
        if planState.researchTypeIndex then
            planManager:setRequiredSkillForPlan(tribeID, planState, buildObject, skill.types.researching.index)
        else
            planManager:setRequiredSkillForPlan(tribeID, planState, buildObject, constructableType.skills.required)
        end
    end

    serverGOM:checkIfNeedsToIncrementBuildSequenceDueToMoveComponentsComplete(buildObject, nil, planState)
    if not serverGOM:checkIfBuildOrCraftOrderIsComplete(buildObject, nil, planState) then
        updateImpossibleStateForResourceAvailabilityChange(buildObject.uniqueID)
        planManager:addPlanObject(buildObject)
        
        if planState.canComplete then
            serverSapien:announce(buildObject.uniqueID, tribeID)
        end
    end

    serverGOM:saveObject(buildObject.uniqueID)
end

function planManager:reAddBuildOrPlantPlan(tribeID, planTypeIndex, objectID)
    local buildObject = serverGOM:getObjectWithID(objectID)
    if buildObject then
        local objectState = buildObject.sharedState

        serverGOM:removeInaccessible(buildObject) --if we're queuing up a new plan, let's check again whether it's still inaccessible
        
        local planStates = getOrCreatePlanStates(objectState, tribeID)

        for i,planState in ipairs(planStates) do
            if planState.planTypeIndex == planTypeIndex  then --no duplicates
                mj:error("duplicate reAddBuildOrPlantPlan for object:", buildObject.uniqueID, ", not adding.")
                return false
            end
        end
        
        if next(planStates) then
            planManager:removeAllPlanStatesForObject(buildObject, objectState, tribeID)
        end


        local constructableTypeIndex = objectState.inProgressConstructableTypeIndex
        if constructableTypeIndex then
            local planState = {
                tribeID = tribeID,
                planID = planManager:getAndIncrementPlanID(),
                planTypeIndex = planTypeIndex,
                canComplete = true,
                constructableTypeIndex = constructableTypeIndex,
                priorityOffset = plan.types[planTypeIndex].priorityOffset,
            }
            planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
            local constructableType = constructable.types[constructableTypeIndex]
            
            local insertIndex = 1
            if objectState.planStates and objectState.planStates[tribeID] then
                insertIndex = #objectState.planStates[tribeID] + 1
            end
            objectState:set("planStates", tribeID, insertIndex, planState)
            finalizeBuildOrPlantPlan(tribeID, buildObject, planState, constructableType, buildObject.sharedState.restrictedResourceObjectTypes, buildObject.sharedState.restrictedToolObjectTypes)
        end
    end
end

function planManager:addBuildOrPlantPlanForRebuild(objectID, tribeID, rebuildConstructableTypeIndex, restrictedResourceObjectTypes, restrictedToolObjectTypes)
    local buildObject = serverGOM:getObjectWithID(objectID)
    --mj:error("planManager:addBuildOrPlantPlanForRebuild:", objectID)
    if buildObject then
        local objectState = buildObject.sharedState
        local newConstructableTypeIndex = rebuildConstructableTypeIndex

        
        local planStates = getOrCreatePlanStates(objectState, tribeID)
        --mj:log("current planstates:", planStates)

        for i,planState in ipairs(planStates) do
            if planState.planTypeIndex == plan.types.build.index or 
            planState.planTypeIndex == plan.types.plant.index or 
            planState.planTypeIndex == plan.types.deconstruct.index  then --no duplicates
                mj:log("build plan already exists for object:", buildObject.uniqueID, ", not adding.")
                return false
            end
        end
        
        if next(planStates) then
            planManager:removeAllPlanStatesForObject(buildObject, objectState, tribeID)
        end
        serverGOM:removeInaccessible(buildObject) --if we're queuing up a new plan, let's check again whether it's still inaccessible

        --planManager:addBuildOrPlantPlanForRebuild(buildOrCraftObject.uniqueID, planState.tribeID, plan.types.build.index, , planState.rebuildConstructableTypeIndex, planState.restrictedResourceObjectTypes, planState.restrictedToolObjectTypes)

        local constructableType = constructable.types[newConstructableTypeIndex]
        local newObjectTypeIndex = nil
        if not constructableType.buildSequence then
            local gameObjectType = gameObject.types[constructableType.finalGameObjectTypeKey]
            newObjectTypeIndex = gameObjectType.index
        else
            local gameObjectType = gameObject.types[constructableType.inProgressGameObjectTypeKey]

            if constructableType.isPlaceType then
                local restrictedResourceTypes = restrictedResourceObjectTypes
                local resourceInfo = constructableType.requiredResources[1]
                local whiteListTypes = serverWorld:seenResourceObjectTypesForTribe(tribeID)
                local availableObjectTypeIndexes = gameObject:getAvailableGameObjectTypeIndexesForRestrictedResource(resourceInfo, restrictedResourceTypes, whiteListTypes)
                
                if availableObjectTypeIndexes then
                    local baseGameObjectType = gameObject.types[availableObjectTypeIndexes[1]]
                    local placeKey = "place_" .. baseGameObjectType.key
                    gameObjectType = gameObject.types[placeKey]
                end
            end
            
            newObjectTypeIndex = gameObjectType.index
        end

        serverGOM:changeObjectType(objectID, newObjectTypeIndex, false)

        if not constructableType.buildSequence then
            objectState:set("constructionConstructableTypeIndex", newConstructableTypeIndex)
        else
            objectState:set("inProgressConstructableTypeIndex", newConstructableTypeIndex)
        end
        
        --objectState:set("buildSequenceIndex", 1)

        --[[subModelInfos = subModelInfosOrNil,
        constructionConstructableTypeIndex = constructableTypeIndex,
        decalBlockers = decalBlockersOrNil,
        attachedToTerrain = attachedToTerrain,]]

        local planTypeIndex = plan.types.build.index
        if constructableType.classification == constructable.classifications.plant.index then
            planTypeIndex = plan.types.plant.index
        end

        local planState = {
            tribeID = tribeID,
            planID = planManager:getAndIncrementPlanID(),
            planTypeIndex = planTypeIndex,
            canComplete = true,
            constructableTypeIndex = newConstructableTypeIndex,
            priorityOffset = plan.types.build.priorityOffset,
        }
        planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
        
        local insertIndex = 1
        if objectState.planStates and objectState.planStates[tribeID] then
            insertIndex = #objectState.planStates[tribeID] + 1
        end
        objectState:set("planStates", tribeID, insertIndex, planState)
        finalizeBuildOrPlantPlan(tribeID, buildObject, planState, constructableType, restrictedResourceObjectTypes, restrictedToolObjectTypes)
    end
end

function planManager:addBuildOrPlantPlan(tribeID, 
    planTypeIndex, 
    constructableTypeIndex,
    researchTypeIndex,
    pos, 
    rotation, 
    sapienIDOrNil, 
    subModelInfosOrNil, 
    attachedToTerrain,
    decalBlockersOrNil,
    restrictedResourceObjectTypesOrNil,
    restrictedToolObjectTypesOrNil,
    noBuildOrder)
    --mj:log("planManager:addBuildPlan")
    if constructableTypeIndex and pos and rotation then
        --mj:log("planManager:addBuildPlan b")
        local constructableType = constructable.types[constructableTypeIndex]


        --local physicsTestSet = nil
        local gameObjectType = nil
        if not constructableType.buildSequence then
            gameObjectType = gameObject.types[constructableType.finalGameObjectTypeKey]
        else
            gameObjectType = gameObject.types[constructableType.inProgressGameObjectTypeKey]

            if constructableType.isPlaceType then
                local restrictedResourceTypes = restrictedResourceObjectTypesOrNil
                local resourceInfo = constructableType.requiredResources[1]
                local whiteListTypes = serverWorld:seenResourceObjectTypesForTribe(tribeID)
                local availableObjectTypeIndexes = gameObject:getAvailableGameObjectTypeIndexesForRestrictedResource(resourceInfo, restrictedResourceTypes, whiteListTypes)
                
                if availableObjectTypeIndexes then
                    local baseGameObjectType = gameObject.types[availableObjectTypeIndexes[1]]
                    local placeKey = "place_" .. baseGameObjectType.key
                    gameObjectType = gameObject.types[placeKey]
                end
            end
        end


       --[[ if not gameObjectType.disallowAnyCollisionsOnPlacement then
            physicsTestSet = physicsSets.disallowAnyCollisionsOnPlacement
        end]]

        -- this works, but it occasionally rejects placements that were allowed client-side, and just generally sucks. Only really needed for cheat prevention anyway.
        --local useMeshForWorldObjects = false
        --local collidersTestResult = physics:modelTest(pos, rotation, 1.0, constructableType.modelIndex, "placeCollide", useMeshForWorldObjects, physicsTestSet, "placeCollide")
        --mj:log("place collidersTestResult:", collidersTestResult, " constructableType.modelIndex:", constructableType.modelIndex)
      --  if collidersTestResult.hasHitObject then
            --mj:log("collides with object fail")
       --     return false
     --   end

        if not constructableType.buildSequence then
            local newTypeIndex = gameObjectType.index
            local builtObjectID = serverGOM:createGameObject({
                objectTypeIndex = newTypeIndex,
                addLevel = mj.SUBDIVISIONS - 3,
                pos = pos,
                rotation = rotation,
                velocity = vec3(0.0,0.0,0.0),
                scale = gameObjectType.scale,
                renderType = gameObjectType.renderTypeOverride or RENDER_TYPE_STATIC,
                hasPhysics = gameObjectType.hasPhysics,
                sharedState = {
                    tribeID = tribeID,
                    subModelInfos = subModelInfosOrNil,
                    constructionConstructableTypeIndex = constructableTypeIndex,
                    decalBlockers = decalBlockersOrNil,
                    attachedToTerrain = attachedToTerrain,
                },
                privateState = {
                    attachedToTerrain = attachedToTerrain,
                },
            })
            
            --tutorial hooks
            if constructableType.index == constructable.types.storageArea.index or 
            constructableType.index == constructable.types.storageArea1x1.index or 
            constructableType.index == constructable.types.storageArea4x4.index then
                if not serverTutorialState:placeStorageIsComplete(tribeID) then
                    serverTutorialState:setTotalStorageAreaCount(tribeID, serverStorageArea:getTotalStorageAreaCount(tribeID))
                end
            end

            serverGOM:preventFutureTransientObjectsNearObject(builtObjectID)

            return builtObjectID

        else
            local canComplete = true

            local planState = nil
            if not noBuildOrder then
                planState = {
                    tribeID = tribeID,
                    planID = planManager:getAndIncrementPlanID(),
                    planTypeIndex = planTypeIndex,
                    sapienID = sapienIDOrNil,
                    canComplete = canComplete,
                    constructableTypeIndex = constructableTypeIndex,
                    researchTypeIndex = researchTypeIndex,
                    discoveryCraftableTypeIndex = (researchTypeIndex and constructableTypeIndex),
                    priorityOffset = plan.types[planTypeIndex].priorityOffset,
                }
                if canComplete then
                    planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
                end
            end

            local buildObjectID = serverGOM:createGameObject({
                objectTypeIndex = gameObjectType.index,
                addLevel = mj.SUBDIVISIONS - 3,
                pos = pos,
                rotation = rotation,
                velocity = vec3(0.0,0.0,0.0),
                scale = gameObjectType.scale,
                renderType = gameObjectType.renderTypeOverride or RENDER_TYPE_STATIC,
                hasPhysics = gameObjectType.hasPhysics,
                sharedState = {
                    inProgressConstructableTypeIndex = constructableTypeIndex,
                    tribeID = tribeID,
                    subModelInfos = subModelInfosOrNil,
                    planStates = {
                        [tribeID] = {
                            planState,
                        }
                    },
                },
                privateState = {
                    decalBlockers = decalBlockersOrNil,
                    attachedToTerrain = attachedToTerrain,
                },
            })

            serverGOM:preventFutureTransientObjectsNearObject(buildObjectID)

            if planState then
                local buildObject = serverGOM:getObjectWithID(buildObjectID)
                finalizeBuildOrPlantPlan(tribeID, buildObject, planState, constructableType, restrictedResourceObjectTypesOrNil, restrictedToolObjectTypesOrNil)

                if serverWorld.completionCheatEnabled then
                    serverGOM:completeBuildImmediately(buildObject, constructableType, planState, tribeID)
                end
            end

            --tutorial hooks
            if constructableType.index == constructable.types.hayBed.index or
            constructableType.index == constructable.types.woolskinBed.index then
                if not serverTutorialState:placeBedsIsComplete(tribeID) then
                    local totalCount = 0
                    local beds = serverGOM:getAllGameObjectsInSet(serverGOM.objectSets.beds)
                    local inProgressBeds = serverGOM:getAllGameObjectsInSet(serverGOM.objectSets.inProgressBeds)
                    local function checkOwnership(objectID)
                        local object = serverGOM:getObjectWithID(objectID)
                        if object and object.sharedState and object.sharedState.tribeID == tribeID then
                            totalCount = totalCount + 1
                        end
                    end
                    for i,objectID in ipairs(beds) do
                        checkOwnership(objectID)
                    end
                    for i,objectID in ipairs(inProgressBeds) do
                        checkOwnership(objectID)
                    end
                    serverTutorialState:setTotalPlacedBedCount(tribeID, totalCount)
                end
            elseif constructableType.index == constructable.types.campfire.index then
                serverTutorialState:setPlaceCampfireComplete(tribeID)
            elseif constructableType.countsAsThatchRoofForTutorial then
                serverTutorialState:setPlaceThatchHutComplete(tribeID)
            end

            return buildObjectID
        end
    end
    return false
end

function planManager:addTerrainModificationPlan(tribeID, 
    planTypeIndex, 
    vertIDs, 
    fillConstructableTypeIndex, 
    researchTypeIndex, 
    restrictedResourceObjectTypesOrNil, 
    restrictedToolObjectTypesOrNil, 
    planOrderIndexOrNil, 
    planPriorityOffsetOrNil, 
    planManuallyPrioritizedOrNil,
    userData)
    if vertIDs and vertIDs[1] then

        for i,vertID in ipairs(vertIDs) do
            --mj:log("vertID:", vertID)
            local vert = terrain:getVertWithID(vertID)
            if vert then
                --mj:log("distance from baseVert to offsetVert is:", mj:pToM(mjm.length(vert.pos) - mjm.length(vert.basePos)))
                local planObjectID = serverGOM:getOrCreateObjectIDForTerrainModificationForVertex(vert, tribeID)
                
                local planObject = serverGOM:getObjectWithID(planObjectID)
                if not planObject then
                    terrain:loadArea(vert.normalizedVert) --added in 0.3.6
                    planObject = serverGOM:getObjectWithID(planObjectID)
                    if not planObject then
                        mj:error("planManager:addTerrainModificationPlan couldn't load plan object for terrain modification")
                        return
                    end
                end
                --mj:log("distance from offsetVert to planObject is:", mj:pToM(mjm.length(vert.pos) - mjm.length(planObject.pos)))

                local vertInfo = terrain:retrieveVertInfo(vertID)

                local foundPlanInfo = nil
                local availablePlans = planHelper:availablePlansForVertInfos(vertInfo, {vertInfo}, tribeID)
                --mj:log("addTerrainModificationPlan availablePlans:", availablePlans)
                if availablePlans then
                    for j,planInfo in ipairs(availablePlans) do
                        if planInfo.planTypeIndex == planTypeIndex and planInfo.hasNonQueuedAvailable then
                            foundPlanInfo = planInfo
                            break
                        end
                    end
                end

                if (foundPlanInfo and (not foundPlanInfo.disabled)) or researchTypeIndex == research.types.mulching.index then --bit of a hack, special case for mulching research. Could be made more generic.
                    --mj:log("foundPlanInfo:", foundPlanInfo)
                
                    local objectState = planObject.sharedState
                    
                    serverGOM:removeInaccessible(planObject) --if we're queuing up a new plan, let's check again whether it's still inaccessible
                    
                    --addPlanState(planObject, tribeID, planTypeIndex, gameObject.types.terrainModificationProxy.index, nil)


                    local requiredSkill = nil
                    local requiredTools = nil

                    if researchTypeIndex then
                        requiredSkill = skill.types.researching.index
                        local researchType = research.types[researchTypeIndex]
                        if researchType.requiredToolTypeIndex then
                            requiredTools = {researchType.requiredToolTypeIndex}
                        end
                    end
                    
                    if foundPlanInfo and foundPlanInfo.requirements then --changed 0.4 to override the researchType with the planInfo from planHelper, as it gives more contextural control 
                        if foundPlanInfo.requirements.skill then
                            requiredSkill = foundPlanInfo.requirements.skill
                        end
                        if foundPlanInfo.requirements.toolTypeIndex then
                            requiredTools = {foundPlanInfo.requirements.toolTypeIndex}
                        end
                    end
                    
                    local priorityOffset = planPriorityOffsetOrNil
                    local planTypePriorityOffset = plan.types[planTypeIndex].priorityOffset
                    if planTypePriorityOffset then
                        if (not priorityOffset) or priorityOffset < planTypePriorityOffset then
                            priorityOffset = planTypePriorityOffset
                        end
                    end 

                    local planState = {
                        tribeID = tribeID,
                        planID = planManager:getAndIncrementPlanID(),
                        planTypeIndex = planTypeIndex,
                        canComplete = true,
                        requiredTools = requiredTools,
                        requiredSkill = requiredSkill,
                        researchTypeIndex = researchTypeIndex,
                        planOrderIndex = planOrderIndexOrNil,
                        priorityOffset = priorityOffset,
                        manuallyPrioritized = planManuallyPrioritizedOrNil,
                    }
                    
                    planManager.canPossiblyCompleteForSapienIterationByPlanID[planState.planID] = true
                    

                    local addIndex = 1
                    if objectState.planStates and objectState.planStates[tribeID] then
                        addIndex = #objectState.planStates[tribeID] + 1
                    end
                    
                    objectState:remove("buildSequenceIndex")
                    objectState:remove("buildSequenceRepeatCounters")

                    if planTypeIndex == plan.types.fill.index or 
                    planTypeIndex == plan.types.fertilize.index or
                    researchTypeIndex == research.types.mulching.index then
                        local constructableTypeIndex = fillConstructableTypeIndex
                        if planTypeIndex == plan.types.fertilize.index or researchTypeIndex == research.types.mulching.index then
                            constructableTypeIndex = constructable.types.fertilize.index
                        end

                        local constructableType = constructable.types[constructableTypeIndex]

                        planState.constructableTypeIndex = constructableTypeIndex
                        objectState:set("planStates", tribeID, addIndex, planState)
                        objectState:set("inProgressConstructableTypeIndex", constructableTypeIndex)
                        
                        if restrictedResourceObjectTypesOrNil and next(restrictedResourceObjectTypesOrNil) then
                            objectState:set("restrictedResourceObjectTypes", restrictedResourceObjectTypesOrNil)
                        end
                        if restrictedToolObjectTypesOrNil and next(restrictedToolObjectTypesOrNil) then
                            objectState:set("restrictedToolObjectTypes", restrictedToolObjectTypesOrNil)
                        end
                        
                        local requiredItems = serverGOM:getRequiredItemsNotInInventory(planObject, planState, constructableType.requiredTools, constructableType.requiredResources, constructableType.index)
                        planManager:updateRequiredResourcesForPlan(tribeID, planState, planObject, requiredItems)

                        if constructableType.skills and constructableType.skills.required and (not researchTypeIndex) then
                            planManager:setRequiredSkillForPlan(tribeID, planState, planObject, constructableType.skills.required)
                        end
                
                       -- if not serverGOM:checkIfBuildOrCraftOrderIsComplete(planObject, planState) then
                            updateImpossibleStateForResourceAvailabilityChange(planObject.uniqueID)
                       -- end

                    else
                        objectState:set("planStates", tribeID, addIndex, planState)

                        if requiredTools then
                            updateImpossibleStateForResourceAvailabilityChange(planObjectID)
                        end
                        
                        if requiredSkill then
                            --updateImpossibleStateForSkillChange(tribeID, planObjectID, nil, nil)
                            --setCallbacksForRequiredSkills(planObject, {requiredSkill})
                            planManager:setRequiredSkillForPlan(tribeID, planState, planObject, requiredSkill)
                        end
                    end

                   -- if planTypeIndex == plan.types.fill.index or planTypeIndex == plan.types.dig.index or planTypeIndex == plan.types.mine.index then
                        planManager:updateImpossibleStateForVert(vertID)
                   -- end

                    planManager:addPlanObject(planObject)

                    
                    if planState.canComplete then
                        serverSapien:announce(planObject.uniqueID, tribeID)
                    end
                    
                    if researchTypeIndex then
                        serverWorld:startDiscoveryForTribe(tribeID, researchTypeIndex, planObject.uniqueID)
                    end
                end
            end
        end
    end
end


function planManager:addStandardPlan(tribeID, 
    planTypeIndex, 
    objectID, 
    objectTypeIndex, 
    researchTypeIndex, 
    discoveryCraftableTypeIndex,
    constructableTypeIndex, 
    planOrderIndexOrNil,
    planPriorityOffsetOrNil,
    planManuallyPrioritizedOrNil,
    extraPlanStateOrNil)
	if objectID ~= nil then
		local object = serverGOM:getObjectWithID(objectID)
		if object then
            addPlanState(object, tribeID, planTypeIndex, objectTypeIndex, nil, researchTypeIndex, discoveryCraftableTypeIndex, constructableTypeIndex, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, extraPlanStateOrNil)
		else
			mj:log("object not loaded in addPlan")
		end
	else
		mj:error("no object ID given")
	end
end


function planManager:reAddPlanForDroppedObjectWithPlanState(tribeID, inventoryRemovalObjectInfo, droppedObjectID)
    local oldPlanState = inventoryRemovalObjectInfo.orderContext.planState
    if oldPlanState then
        if oldPlanState.researchTypeIndex then
            planManager:addResearchPlan(tribeID, 
            oldPlanState.planTypeIndex, 
            droppedObjectID,
            {droppedObjectID},
            oldPlanState.objectTypeIndex, 
            oldPlanState.researchTypeIndex, 
            oldPlanState.discoveryCraftableTypeIndex, 
            oldPlanState.planOrderIndex or oldPlanState.planID, 
            oldPlanState.priorityOffset, 
            oldPlanState.manuallyPrioritized)
        elseif oldPlanState.planTypeIndex == plan.types.craft.index then
            planManager:addCraftPlan(tribeID, 
            oldPlanState.planTypeIndex, 
            nil, 
            droppedObjectID, 
            oldPlanState.constructableTypeIndex, 
            oldPlanState.craftCount, 
            oldPlanState.researchTypeIndex,
            oldPlanState.discoveryCraftableTypeIndex,
            inventoryRemovalObjectInfo.restrictedResourceObjectTypes,
            inventoryRemovalObjectInfo.restrictedToolObjectTypes,
            oldPlanState.planOrderIndex or oldPlanState.planID, 
            oldPlanState.priorityOffset,
            oldPlanState.manuallyPrioritized,
            false)
        else
            planManager:addStandardPlan(tribeID, 
            oldPlanState.planTypeIndex, 
            droppedObjectID, 
            oldPlanState.objectTypeIndex, 
            oldPlanState.researchTypeIndex, 
            oldPlanState.discoveryCraftableTypeIndex, 
            oldPlanState.constructableTypeIndex, 
            oldPlanState.planOrderIndex or oldPlanState.planID, 
            oldPlanState.priorityOffset, 
            oldPlanState.manuallyPrioritized)
        end
    end
end

local function cancelSinglePlan(object, planTypeIndex, objectTypeIndex, researchTypeIndex, tribeID)
    --[[if object.sharedState and object.sharedState.vertID then
        planManager:removePlanStateFromTerrainVertForTerrainModification(object.sharedState.vertID, planTypeIndex, tribeID, researchTypeIndex)
    end]]

    planManager:removePlanStateForObject(object, planTypeIndex, objectTypeIndex, researchTypeIndex, tribeID, nil)
    serverGOM:planWasCancelledForObject(object, planTypeIndex, tribeID)
end


function planManager:addPathPlacementPlans(tribeID, userData)
    if userData then
        local firstObjectID = nil
        for i,planInfo in ipairs(userData.nodes) do
            local objectID = planManager:addBuildOrPlantPlan(tribeID, 
            plan.types.buildPath.index, 
            userData.constructableTypeIndex,
            nil,
            planInfo.pos, 
            planInfo.rotation, 
            nil, 
            planInfo.subModelInfos, 
            true,
            planInfo.decalBlockers,
            userData.restrictedResourceObjectTypes,
            userData.restrictedToolObjectTypes,
            userData.noBuildOrder)

            if not objectID then
                break
            end
            
            if i == 1 then
                firstObjectID = objectID
            end
        end
        if not firstObjectID then
            return nil
        end
        return {
            uniqueID = firstObjectID,
            pos = userData.nodes[1].pos
        }
    end
    return nil
end

function planManager:addResearchPlan(tribeID, 
    planTypeIndex, 
    baseObjectOrVertID, 
    objectOrVertIDs,
    objectTypeIndex, 
    researchTypeIndex, 
    discoveryCraftableTypeIndex, 
    planOrderIndexOrNil, 
    planPriorityOffsetOrNil, 
    planManuallyPrioritizedOrNil,
    userDataOrNil)
    
    --mj:log("objectOrVertIDs:", objectOrVertIDs)
    for i,objectOrVertID in ipairs(objectOrVertIDs) do
        local object = serverGOM:getObjectWithID(objectOrVertID)
        if object then
            local researchType = research.types[researchTypeIndex]
            if researchType.constructableTypeIndex or researchType.constructableTypeIndexesByBaseResourceTypeIndex or researchType.constructableTypeIndexArraysByBaseResourceTypeIndex then
                if gameObject.types[object.objectTypeIndex].isStorageArea then
                    planManager:addStandardPlan(tribeID, planTypeIndex, objectOrVertID, objectTypeIndex, researchTypeIndex, discoveryCraftableTypeIndex, nil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, userDataOrNil)
                else
                    local constructableTypeIndex = discoveryCraftableTypeIndex
                    if not constructableTypeIndex then --the stuff in here seems redundant probably
                        constructableTypeIndex = researchType.constructableTypeIndex
                        if researchType.constructableTypeIndexesByBaseResourceTypeIndex or researchType.constructableTypeIndexArraysByBaseResourceTypeIndex then
                            local complete = serverWorld:discoveryIsCompleteForTribe(tribeID, researchTypeIndex)
                            constructableTypeIndex = research:getBestConstructableIndexForResearch(researchTypeIndex, gameObject.types[object.objectTypeIndex].resourceTypeIndex, planHelper:getCraftableDiscoveriesForTribeID(tribeID), complete)
                        end
                    end
                    if not constructableTypeIndex then
                        planManager:addStandardPlan(tribeID, planTypeIndex, objectOrVertID, objectTypeIndex, researchTypeIndex, discoveryCraftableTypeIndex, nil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, userDataOrNil)
                    else
                        local constructableType = constructable.types[constructableTypeIndex]
                        if constructableType.requiredCraftAreaGroups or constructableType.requiredTerrainTypes or constructableType.requiresShallowWaterToResearch then
                            planManager:addStandardPlan(tribeID, planTypeIndex, objectOrVertID, objectTypeIndex, researchTypeIndex, discoveryCraftableTypeIndex, nil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, userDataOrNil)
                        else
                            local addObjectInfo = serverGOM:convertToTemporaryCraftArea(object, tribeID)
                            planManager:addCraftPlan(tribeID, planTypeIndex, objectOrVertID, nil, constructableTypeIndex, 1, researchTypeIndex, discoveryCraftableTypeIndex, nil, nil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, false)
                            object.sharedState:set("inProgressConstructableTypeIndex", constructableTypeIndex)
                            serverGOM:addConstructionObjectComponent(object, addObjectInfo, tribeID)
                        end
                    end
                end
            else
                planManager:addStandardPlan(tribeID, planTypeIndex, objectOrVertID, objectTypeIndex, researchTypeIndex, discoveryCraftableTypeIndex, nil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, userDataOrNil)
            end
        else
            planManager:addTerrainModificationPlan(tribeID, planTypeIndex, {objectOrVertID}, nil, researchTypeIndex, nil, nil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, userDataOrNil)
        end
    end
end

--planManager:updatePlansForFollowerOrOrderCountChange(tribeID)

function planManager:addPlans(tribeID, userData)
    
    local result = nil

    if not userData then
        return result
    end
    local planTypeIndex = userData.planTypeIndex
    if not planTypeIndex then
        return result
    end


    local functionsByPlanType = {
        [plan.types.research.index] = function()
            if userData.baseVertID then
                result = planManager:addResearchPlan(tribeID, 
                planTypeIndex, 
                userData.baseVertID, 
                userData.objectOrVertIDs,
                userData.objectTypeIndex, 
                userData.researchTypeIndex, 
                userData.discoveryCraftableTypeIndex, 
                nil, 
                nil,
                userData.prioritize)
            elseif userData.objectOrVertIDs and userData.objectOrVertIDs[1] then
                result = planManager:addResearchPlan(tribeID, 
                planTypeIndex, 
                userData.baseObjectOrVertID or userData.objectOrVertIDs[1], 
                userData.objectOrVertIDs,
                userData.objectTypeIndex, 
                userData.researchTypeIndex, 
                userData.discoveryCraftableTypeIndex, 
                nil, 
                nil,
                userData.prioritize)
            end
        end,
        [plan.types.deconstruct.index] = function()
            if userData.objectOrVertIDs then
                for i,objectID in ipairs(userData.objectOrVertIDs) do
                    result = planManager:addDeconstructPlan(tribeID, objectID)
                end
            end
        end,
        [plan.types.rebuild.index] = function()
            --mj:log("rebuild")
            if userData.objectOrVertIDs then
                for i,objectID in ipairs(userData.objectOrVertIDs) do
                    --mj:log("addRebuildPlan")
                    result = planManager:addRebuildPlan(tribeID, objectID, userData.constructableTypeIndex, userData.restrictedResourceObjectTypes, userData.restrictedToolObjectTypes)
                end
            end
        end,
        [plan.types.haulObject.index] = function()
            local moveToPos = worldHelper:getSantizedMoveToPos(userData.moveToPos)
            if moveToPos then
                for i,objectID in ipairs(userData.objectOrVertIDs) do
                local object = serverGOM:getObjectWithID(objectID)
                if object then
                    local markerObjectID = serverGOM:createGameObject({
                        objectTypeIndex = gameObject.types.haulObjectDestinationMarker.index,
                        addLevel = mj.SUBDIVISIONS - 3,
                        pos = moveToPos,
                        rotation = mj:getNorthFacingFlatRotationForPoint(moveToPos),
                        velocity = vec3(0.0,0.0,0.0),
                        scale = 1.0,
                        renderType = RENDER_TYPE_NONE,
                        hasPhysics = false,
                        sharedState = {
                            tribeID = tribeID,
                            haulObjectID = objectID,
                            haulObjectName = object.sharedState and object.sharedState.name,
                            haulObjectTypeIndex = object.objectTypeIndex,
                        },
                    })
                    if markerObjectID then
                        local extraPlanState = {
                            moveToPos = moveToPos,
                            markerObjectID = markerObjectID,
                        }
                        local planState = addPlanState(object, tribeID, planTypeIndex, userData.objectTypeIndex, nil, nil, nil, nil, nil, nil, userData.prioritize, extraPlanState)
                        if not planState then
                            serverGOM:removeGameObject(markerObjectID)
                        else
                            serverGOM:setAlwaysSendToClientWithTribeIDForObjectWithID(objectID, planState.tribeID, true) --send the sled info always, so the marker object will be kept up to date client-side
                        end
                    end

                end
            end
        end 
        end,
        [plan.types.build.index] = function()
            if userData.objectOrVertIDs then
                for i,objectID in ipairs(userData.objectOrVertIDs) do
                    result = planManager:reAddBuildOrPlantPlan(tribeID, planTypeIndex, objectID)
                end
            else
                result = planManager:addBuildOrPlantPlan(tribeID, 
                    planTypeIndex, 
                    userData.constructableTypeIndex,
                    nil,
                    userData.pos, 
                    userData.rotation, 
                    userData.sapienID, 
                    userData.subModelInfos, 
                    userData.attachedToTerrain,
                    userData.decalBlockers,
                    userData.restrictedResourceObjectTypes,
                    userData.restrictedToolObjectTypes,
                    userData.noBuildOrder)
            end
        end,
        [plan.types.craft.index] = function()
            result = planManager:addCraftPlan(tribeID, 
                planTypeIndex, 
                userData.craftAreaObjectID, 
                userData.craftResourcePlanObjectID, 
                userData.constructableTypeIndex, 
                userData.craftCount,
                nil,
                nil,
                userData.restrictedResourceObjectTypes,
                userData.restrictedToolObjectTypes,
                nil, 
                nil,
                nil,
                userData.shouldMaintainSetQuantity)
        end,
    }

    functionsByPlanType[plan.types.buildPath.index] = functionsByPlanType[plan.types.build.index]
    functionsByPlanType[plan.types.plant.index] = functionsByPlanType[plan.types.build.index]

    local customFunction = functionsByPlanType[planTypeIndex]
    if customFunction then
        customFunction()
    else
        if userData.objectOrVertIDs then
            local foundObject = false
            for i,objectID in ipairs(userData.objectOrVertIDs) do
                local object = serverGOM:getObjectWithID(objectID)
                if object then
                    foundObject = true
                    addPlanState(object, tribeID, planTypeIndex, userData.objectTypeIndex, nil, nil, nil, nil, nil, nil, userData.prioritize, nil, userData)
                end
            end
            if not foundObject then
                -- bit of a hack, its possible the object has been removed, but lets assume it's a terrain plan. It will only be applied if it finds valid verts.
                result = planManager:addTerrainModificationPlan(tribeID, 
                planTypeIndex, 
                userData.objectOrVertIDs, 
                userData.constructableTypeIndex, 
                nil, 
                userData.restrictedResourceObjectTypes, 
                userData.restrictedToolObjectTypes, 
                nil, 
                nil, 
                nil,
                userData)
            end
        end
    end
    
    planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
        
    return result
end

function planManager:addPlanToObject(object, tribeID, planTypeIndex, objectTypeIndex, sapienIDOrNil, researchTypeIndexOrNil, discoveryCraftableTypeIndexOrNil, constructableTypeIndexOrNil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, extraPlanStateDataOrNil)
    addPlanState(object, tribeID, planTypeIndex, objectTypeIndex, sapienIDOrNil, researchTypeIndexOrNil, discoveryCraftableTypeIndexOrNil, constructableTypeIndexOrNil, planOrderIndexOrNil, planPriorityOffsetOrNil, planManuallyPrioritizedOrNil, extraPlanStateDataOrNil)
end

function planManager:assignSapienToPlan(tribeID, userData)
    --mj:log("planManager:assignSapienToPlan:", userData)
    if userData.sapienID and userData.planObjectID and userData.planTypeIndex then
        local sapien = serverGOM:getObjectWithID(userData.sapienID)
        if sapien and sapien.objectTypeIndex == gameObject.types.sapien.index and sapien.sharedState.tribeID == tribeID then
            local planObject = serverGOM:getObjectWithID(userData.planObjectID)
            if planObject then
                local sharedState = planObject.sharedState
                if sharedState then
                    local planStatesForThisTribe = nil
            
                    if sharedState.planStates and sharedState.planStates[tribeID] then
                        planStatesForThisTribe =  sharedState.planStates[tribeID]
                    end
                    if planStatesForThisTribe then
                        for planIndex, thisPlanState in ipairs(planStatesForThisTribe) do
                            if thisPlanState.planTypeIndex == userData.planTypeIndex and 
                            ((not userData.objectTypeIndex) or userData.objectTypeIndex == thisPlanState.objectTypeIndex) and 
                            ((not userData.researchTypeIndex) or userData.researchTypeIndex == thisPlanState.researchTypeIndex) then

                                if thisPlanState.requiredSkill then 
                                    local priorityLevel = skill:priorityLevel(sapien, thisPlanState.requiredSkill)
                                    if priorityLevel ~= 1 then
                                        if not serverSapien:autoAssignToRole(sapien, thisPlanState.requiredSkill) then
                                            return false
                                        end
                                    end
                                end
                                local assignedSapienIDs = sharedState.assignedSapienIDs
                                if assignedSapienIDs then
                                   -- mj:log("already has assignedSapienIDs")
                                    for assignedSapienID,planTypeIndexOrTrue in pairs(assignedSapienIDs) do
                                        local assignedSapien = serverGOM:getObjectWithID(assignedSapienID)
                                        if assignedSapien then
                                            local orderQueue = assignedSapien.sharedState.orderQueue
                                            --mj:log("assigned orderQueue:", orderQueue)
                                            if orderQueue and orderQueue[1] then
                                                local orderContext = orderQueue[1].context
                                                if orderContext and orderContext.planObjectID == planObject.uniqueID and 
                                                orderContext.planTypeIndex == thisPlanState.planTypeIndex and 
                                                ((not userData.objectTypeIndex) or orderContext.objectTypeIndex == thisPlanState.objectTypeIndex) then
                                                    --mj:log("calling cancelAllOrders:", assignedSapien.uniqueID)
                                                    --disabled--mj:objectLog(assignedSapien.uniqueID, "cancelling orders as another sapien has been assigned to my plan:", userData.sapienID)
                                                    serverSapien:cancelAllOrders(assignedSapien, false, true)
                                                end
                                            end
                                        end
                                    end
                                end


                                
                                planObject.sharedState:remove("inaccessibleCount")
                                planObject.sharedState:remove("lastInaccessibleTime")

                                serverSapien:cancelAllOrders(sapien, false, true)
                                serverSapien:dropHeldInventoryImmediately(sapien)

                                sapien.sharedState:set("manualAssignedPlanObject", planObject.uniqueID)
                                sapien.sharedState:remove("resting")

                                sharedState:set("planStates", tribeID, planIndex, "manualAssignedSapien", sapien.uniqueID)
                                
                                updateTooDistantState(planObject, thisPlanState, planIndex)
                                planManager:updateStorageAvailibilityForManualPrioritizationOrAssignment(planObject, thisPlanState)
                                return true
                            end 
                        end
                    end
                end
            end
        end
    end
    return false
end



function planManager:cancelPlans(tribeID, userData)
	if userData then
        --mj:log("cancelPlans:", userData)
        local planTypeIndex = userData.planTypeIndex
        if userData.objectOrVertIDs then
            for i,objectOrVertID in ipairs(userData.objectOrVertIDs) do
                if planTypeIndex and objectOrVertID then
                    
                    local object = serverGOM:getObjectWithID(objectOrVertID)

                    if object then
                        cancelSinglePlan(object, planTypeIndex, userData.objectTypeIndex, userData.researchTypeIndex, tribeID)
                    else
                        planManager:removePlanStateFromTerrainVertForTerrainModification(objectOrVertID, planTypeIndex, tribeID, userData.researchTypeIndex)
                    end

                    --[[if gameConstants.useLegacyResearchRules and planTypeIndex == plan.types.research.index and userData.researchTypeIndex then
                        local planObjectID = nil

                        local baseResearchTypeIndex = userData.researchTypeIndex
                        local discoveryCraftableTypeIndexIfIsCraftableDiscovery = nil

                        if serverWorld:discoveryIsCompleteForTribe(tribeID, baseResearchTypeIndex) then
                            if userData.discoveryCraftableTypeIndex then
                                discoveryCraftableTypeIndexIfIsCraftableDiscovery = userData.discoveryCraftableTypeIndex
                                planObjectID = serverWorld:getPlanObjectIDForCraftableDiscoveryForTribe(tribeID, discoveryCraftableTypeIndexIfIsCraftableDiscovery)
                            end
                        else
                            planObjectID = serverWorld:getPlanObjectIDForDiscoveryForTribe(tribeID, baseResearchTypeIndex)
                        end

                        if planObjectID and planObjectID ~= objectOrVertID then
                            local researchPlanObject = serverGOM:getObjectWithID(planObjectID)
                            if researchPlanObject then
                                if researchPlanObject.objectTypeIndex == gameObject.types.sapien.index then
                                    serverSapien:cancelAllOrders(researchPlanObject, false, true)
                                else
                                    cancelSinglePlan(researchPlanObject, planTypeIndex, userData.objectTypeIndex, userData.researchTypeIndex, tribeID)
                                end
                                if object then
                                    serverGOM:sendNotificationForObject(object, notification.types.updateUI.index, nil, tribeID)
                                else
                                    local vert = terrain:getVertWithID(objectOrVertID)
                                    if vert then
                                        local notificationObjectID = serverGOM:getOrCreateObjectIDForTerrainModificationForVertex(vert, tribeID)
                                        local notificationObject = serverGOM:getObjectWithID(notificationObjectID)
                                        if notificationObject then
                                            serverGOM:sendNotificationForObject(notificationObject, notification.types.updateUI.index, nil, tribeID)
                                        end
                                    end
                                end

                            end

                            if discoveryCraftableTypeIndexIfIsCraftableDiscovery then
                                serverWorld:cancelCraftableDiscoveryPlanForTribe(tribeID, discoveryCraftableTypeIndexIfIsCraftableDiscovery) --ambulance just in case
                            else
                                serverWorld:cancelDiscoveryPlanForTribe(tribeID, baseResearchTypeIndex) --ambulance just in case
                            end
                        end
                    end]]
                end
            end
        end
        planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
    end
end

local researchPlansToDelayedCancelByTribeID = {} --delayed so that the research action can be completed
local researchCraftablePlansToDelayedCancelByTribeID = {}

function planManager:cancelResearchPlansForDiscoveryResearchCompletion(tribeID, researchTypeIndex)
    local researchTypeIndexes = researchPlansToDelayedCancelByTribeID[tribeID]
    if not researchTypeIndexes then
        researchTypeIndexes = {}
        researchPlansToDelayedCancelByTribeID[tribeID] = researchTypeIndexes
        researchTypeIndexes[researchTypeIndex] = true
    end
end


function planManager:doCancelResearchPlansForDiscoveryResearchCompletion(tribeID, researchTypeIndexSet)
    --mj:log("planManager:cancelResearchPlansForDiscoveryResearchCompletion:", researchTypeIndexSet)
    local orderedPlans = orderedPlansByTribeID[tribeID]

    local plansToRemove = {} --can't remove directly, as cancelSinglePlan modifies orderedPlans

    if orderedPlans then
        for i, orderedPlan in ipairs(orderedPlans) do

            local object = serverGOM:getObjectWithID(orderedPlan.objectID)
            if object then
                local sharedState = object.sharedState
                local planStatesByTribeID = sharedState.planStates
                if planStatesByTribeID then
                    local planStates = planStatesByTribeID[tribeID]
                    if planStates then
                        for j,thisPlanState in ipairs(planStates) do
                            if researchTypeIndexSet[thisPlanState.researchTypeIndex] then
                                --mj:log("cancel plan:", thisPlanState)
                                table.insert(plansToRemove, {
                                    object = object,
                                    planState = thisPlanState,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    for i,removeInfo in ipairs(plansToRemove) do
        cancelSinglePlan(removeInfo.object, removeInfo.planState.planTypeIndex, removeInfo.planState.objectTypeIndex, removeInfo.planState.researchTypeIndex, tribeID)
    end
end



function planManager:cancelResearchPlansForCraftableDiscoveryResearchCompletion(tribeID, discoveryCraftableTypeIndex)
    local discoveryCraftableTypeIndexes = researchCraftablePlansToDelayedCancelByTribeID[tribeID]
    if not discoveryCraftableTypeIndexes then
        discoveryCraftableTypeIndexes = {}
        researchCraftablePlansToDelayedCancelByTribeID[tribeID] = discoveryCraftableTypeIndexes
        discoveryCraftableTypeIndexes[discoveryCraftableTypeIndex] = true
    end
end

function planManager:doCancelResearchPlansForCraftableDiscoveryResearchCompletion(tribeID, discoveryCraftableTypeIndexSet)
    --mj:log("planManager:cancelResearchPlansForCraftableDiscoveryResearchCompletion:", discoveryCraftableTypeIndexSet)
    local orderedPlans = orderedPlansByTribeID[tribeID]

    local plansToRemove = {} --can't remove directly, as cancelSinglePlan modifies orderedPlans

    if orderedPlans then
        for i, orderedPlan in ipairs(orderedPlans) do

            local object = serverGOM:getObjectWithID(orderedPlan.objectID)
            if object then
                local sharedState = object.sharedState
                local planStatesByTribeID = sharedState.planStates
                if planStatesByTribeID then
                    local planStates = planStatesByTribeID[tribeID]
                    if planStates then
                        for j,thisPlanState in ipairs(planStates) do
                            if discoveryCraftableTypeIndexSet[thisPlanState.discoveryCraftableTypeIndex] then
                                table.insert(plansToRemove, {
                                    object = object,
                                    planState = thisPlanState,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    for i,removeInfo in ipairs(plansToRemove) do
        cancelSinglePlan(removeInfo.object, removeInfo.planState.planTypeIndex, removeInfo.planState.objectTypeIndex, removeInfo.planState.researchTypeIndex, tribeID)
    end
end

function planManager:cancelAnyResearchPlans()
    if next(researchPlansToDelayedCancelByTribeID) then
        for tribeID, researchTypeSet in pairs(researchPlansToDelayedCancelByTribeID) do
            planManager:doCancelResearchPlansForDiscoveryResearchCompletion(tribeID, researchTypeSet)
        end
        researchPlansToDelayedCancelByTribeID = {}
    end
    if next(researchCraftablePlansToDelayedCancelByTribeID) then
        for tribeID, discoveryCraftableTypeIndexSet in pairs(researchCraftablePlansToDelayedCancelByTribeID) do
            planManager:doCancelResearchPlansForCraftableDiscoveryResearchCompletion(tribeID, discoveryCraftableTypeIndexSet)
        end
        researchCraftablePlansToDelayedCancelByTribeID = {}
    end
end

local function eachPlanState(tribeID, objectOrVertIDs, planFunc)
    for objectI,objectOrVertID in ipairs(objectOrVertIDs) do

        --mj:log("objectOrVertID:", objectOrVertID)
        
        local planObject = serverGOM:getObjectWithID(objectOrVertID)
        if not planObject then
            local vert = terrain:getVertWithID(objectOrVertID)
            --mj:log("not planObject vert:", vert)
            if vert then
                local planObjectID = terrain:getObjectIDForTerrainModificationForVertex(vert)

                --mj:log("not planObject planObjectID:", planObjectID)
                if planObjectID then
                    planObject = serverGOM:getObjectWithID(planObjectID)
                end
            end
        end

        if planObject then
            local sharedState = planObject.sharedState
            --mj:log("sharedState:", sharedState)
            if sharedState then
                local planStatesForThisTribe = nil
                if sharedState.planStates and sharedState.planStates[tribeID] then
                    planStatesForThisTribe = sharedState.planStates[tribeID]
                end
                if planStatesForThisTribe then
                    for planIndex, thisPlanState in ipairs(planStatesForThisTribe) do
                        if planFunc(planObject, planIndex, thisPlanState) then
                            return
                        end
                    end
                end
            end
        end
    end
end

local function prioritizePlan(planObject, tribeID, orderedPlans, orderedPlanIndex, thisPlanState, planIndex)
    local planOrderIndex = planManager:getAndIncrementPrioritizedID()
    planObject.sharedState:set("planStates", tribeID, planIndex, "planOrderIndex", planOrderIndex)
    planObject.sharedState:set("planStates", tribeID, planIndex, "manuallyPrioritized", true)
    updateTooDistantState(planObject, thisPlanState, planIndex)
    serverGOM:removeInaccessible(planObject)
    planManager:updateStorageAvailibilityForManualPrioritizationOrAssignment(planObject, thisPlanState)
    table.remove(orderedPlans, orderedPlanIndex)
    local priorityOffset = thisPlanState.priorityOffset or plan.types[thisPlanState.planTypeIndex].priorityOffset
    local orderInfo = {
        objectID = planObject.uniqueID,
        planID = thisPlanState.planID,
        disabledDueToOrderLimit = thisPlanState.disabledDueToOrderLimit,
        orderIndex = planOrderIndex,
        priorityOffset = priorityOffset,
        manuallyPrioritized = true,
    }
    --table.insert(orderedPlans, 1, orderInfo)
    addOrderToOrderedPlans(orderInfo, thisPlanState, orderedPlans, planOrderIndex)
end

function planManager:prioritizePlans(tribeID, userData)
    if userData and userData.objectOrVertIDs then
        local orderedPlans = orderedPlansByTribeID[tribeID]
        if orderedPlans then
            eachPlanState(tribeID, userData.objectOrVertIDs, function(planObject, planIndex, thisPlanState)
                if thisPlanState.planTypeIndex == userData.planTypeIndex and 
                ((not userData.objectTypeIndex) or userData.objectTypeIndex == thisPlanState.objectTypeIndex) and 
                ((not userData.researchTypeIndex) or userData.researchTypeIndex == thisPlanState.researchTypeIndex) then
                    for j, orderedPlan in ipairs(orderedPlans) do
                        if orderedPlan.planID == thisPlanState.planID then
                            prioritizePlan(planObject, tribeID, orderedPlans, j, thisPlanState, planIndex)
                            --updateOrderWithinCanCompleteList(planObject, tribeID, priorityOffset, true)
                            break
                        end
                    end
                end
            end)
            planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
        end
    end
end

local function deprioritizePlan(planObject, tribeID, orderedPlans, orderedPlanIndex, thisPlanState, planIndex)
    planObject.sharedState:remove("planStates", tribeID, planIndex, "manuallyPrioritized")
    updateTooDistantState(planObject, thisPlanState, planIndex)
    planManager:updateStorageAvailibilityForManualPrioritizationOrAssignment(planObject, thisPlanState)
    planObject.sharedState:remove("planStates", tribeID, planIndex, "planOrderIndex")

    table.remove(orderedPlans, orderedPlanIndex)
    local priorityOffset = thisPlanState.priorityOffset or plan.types[thisPlanState.planTypeIndex].priorityOffset

    local orderIndex = thisPlanState.planID
    local orderInfo = {
        objectID = planObject.uniqueID,
        planID = thisPlanState.planID,
        disabledDueToOrderLimit = thisPlanState.disabledDueToOrderLimit,
        orderIndex = orderIndex,
        priorityOffset = priorityOffset,
    }
    addOrderToOrderedPlans(orderInfo, thisPlanState, orderedPlans, orderIndex)
end


function planManager:deprioritizePlans(tribeID, userData)
	if userData and userData.objectOrVertIDs then
        local orderedPlans = orderedPlansByTribeID[tribeID]
        if orderedPlans then
            eachPlanState(tribeID, userData.objectOrVertIDs, function(planObject, planIndex, thisPlanState)
                if thisPlanState.planTypeIndex == userData.planTypeIndex and 
                ((not userData.objectTypeIndex) or userData.objectTypeIndex == thisPlanState.objectTypeIndex) and 
                ((not userData.researchTypeIndex) or userData.researchTypeIndex == thisPlanState.researchTypeIndex) then
                    for j, orderedPlan in ipairs(orderedPlans) do
                        if orderedPlan.planID == thisPlanState.planID then
                            deprioritizePlan(planObject, tribeID, orderedPlans, j, thisPlanState, planIndex)
                            --updateOrderWithinCanCompleteList(planObject, tribeID, priorityOffset, false)
                            break
                        end
                    end
                end
            end)
            planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
        end
    end
end


function planManager:togglePlanPrioritization(tribeID, userData)
	if userData and userData.objectOrVertIDs then
        local orderedPlans = orderedPlansByTribeID[tribeID]
        if orderedPlans then

            local shouldPrioritize = true
            eachPlanState(tribeID, userData.objectOrVertIDs, function(planObject, planIndex, thisPlanState)
                if thisPlanState.manuallyPrioritized then
                    shouldPrioritize = false
                    return true
                end
            end)

            eachPlanState(tribeID, userData.objectOrVertIDs, function(planObject, planIndex, thisPlanState)
                for j, orderedPlan in ipairs(orderedPlans) do
                    if orderedPlan.planID == thisPlanState.planID then
                        if shouldPrioritize then
                            prioritizePlan(planObject, tribeID, orderedPlans, j, thisPlanState, planIndex)
                        else
                            deprioritizePlan(planObject, tribeID, orderedPlans, j, thisPlanState, planIndex)
                        end
                        --updateOrderWithinCanCompleteList(planObject, tribeID, priorityOffset, false)
                        break
                    end
                end
            end)
        end
    end
    planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
end

function planManager:cancelAllPlansForObject(tribeID, objectID)
    local object = serverGOM:getObjectWithID(objectID)
    if object then
        local sharedState = object.sharedState
        if sharedState.haulObjectID then
            local haulObject = serverGOM:getObjectWithID(sharedState.haulObjectID)
            if haulObject then
                cancelSinglePlan(haulObject, plan.types.haulObject.index, nil, nil, tribeID)
            end
        else
            local planStatesByTribeID = sharedState.planStates
            if planStatesByTribeID then
                local allRemovedPlanTypeIndexes = {}
                local planStates = planStatesByTribeID[tribeID]
                if planStates then
                    for i,thisPlanState in ipairs(planStates) do
                        table.insert(allRemovedPlanTypeIndexes, thisPlanState.planTypeIndex)
                    end

                    planManager:removeAllPlanStatesForObject(object, object.sharedState, tribeID)
                        
                    for i,planTypeIndex in ipairs(allRemovedPlanTypeIndexes) do
                        serverGOM:planWasCancelledForObject(object, planTypeIndex, tribeID)
                    end
                end
            end
        end
        planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
    end
    serverGOM:removeTemporaryGameObjectForOrderCompleteIfNeeded(object)
end

function planManager:cancelAllPlansForVert(tribeID, vertID)
    local vert = terrain:getVertWithID(vertID)
    if vert then
        local planObjectID = terrain:getObjectIDForTerrainModificationForVertex(vert)
        if planObjectID then
            planManager:cancelAllPlansForObject(tribeID, planObjectID)
        end
    end
end

function planManager:storageAreaAllowItemUseChanged(storageObject)
    local sharedState = storageObject.sharedState
    local planStatesByTribeID = sharedState.planStates
    local tribePlansToRemove = {}
    if planStatesByTribeID then
        for tribeID,planStates in pairs(planStatesByTribeID) do
            local tribeSettings = serverStorageArea:getTribeSettings(sharedState, tribeID)
            if not serverStorageArea:getAllowItemUse(sharedState, tribeID, tribeSettings) then
                tribePlansToRemove[tribeID] = true
            end
        end
    end

    for tribeID,v in pairs(tribePlansToRemove) do --this is a bit much, could be marked impossible instead, but doesn't seem worth the effort right now, as hitchhiking on "missingStorage" is not easy
        planManager:removeAllPlanStatesForObject(storageObject, sharedState, tribeID)
    end
end

function planManager:checkPlanAvailability(tribeID, userData)
    local result = {}

    --mj:log("planManager:checkPlanAvailability:", userData)

	if userData and userData.plans then
        local objectsOrVerts = {}
        local foundObject = false
        local foundTerrain = false

        for i, objectOrVertID in ipairs(userData.objectOrVertIDs) do
            if foundTerrain then
                local vertInfo = terrain:retrieveVertInfo(objectOrVertID)
                if vertInfo then
                    foundTerrain = true
                    table.insert(objectsOrVerts, vertInfo)
                end
            else
                local object = serverGOM:getObjectWithID(objectOrVertID)
                if object then
                    serverGOM:ensureSharedStateLoaded(object)
                    table.insert(objectsOrVerts, object)
                    foundObject = true
                elseif not foundObject then
                    
                    local vertInfo = terrain:retrieveVertInfo(objectOrVertID)
                    --local vert = terrain:getVertWithID(objectOrVertID)
                    if vertInfo then
                        foundTerrain = true
                        table.insert(objectsOrVerts, vertInfo)
                    end
                end
            end
        end

        local availablePlans = nil
        if foundObject then
            local baseObject = serverGOM:getObjectWithID(userData.baseObjectOrVertID)
            if baseObject then
                availablePlans = planHelper:availablePlansForObjectInfos(baseObject, objectsOrVerts, tribeID)
            end
        elseif foundTerrain then
            local baseVert = terrain:retrieveVertInfo(userData.baseObjectOrVertID)
            if baseVert then
                availablePlans = planHelper:availablePlansForVertInfos(baseVert, objectsOrVerts, tribeID)
            end
        end
        
        --mj:log("availablePlans:", availablePlans)
        if availablePlans then
            for i, uiPlanInfo in ipairs(userData.plans) do

                local foundPlanInfo = nil
                if uiPlanInfo.planTypeIndex == plan.types.transferObject.index or
                uiPlanInfo.planTypeIndex == plan.types.destroyContents.index then -- bit of a hack, I guess there should be a superset of availablePlansForObjectInfos with hidden plans or something?
                    foundPlanInfo = {
                        planTypeIndex = uiPlanInfo.planTypeIndex,
                        requirements = {
                            skill = skill.types.gathering.index,
                        },
                        hasNonQueuedAvailable = true,
                    }
                else
                    for j,availablePlanInfo in ipairs(availablePlans) do
                        if availablePlanInfo.planTypeIndex == uiPlanInfo.planTypeIndex and ((not uiPlanInfo.objectTypeIndex) or availablePlanInfo.objectTypeIndex == uiPlanInfo.objectTypeIndex) and availablePlanInfo.hasNonQueuedAvailable then
                            foundPlanInfo = availablePlanInfo
                            break
                        end
                    end
                end

                --mj:log("uiPlanInfo:", uiPlanInfo)
               -- mj:log("foundPlanInfo:", foundPlanInfo)

                if foundPlanInfo and foundPlanInfo.hasNonQueuedAvailable then

                    local buildConstructableTypeIndex = nil
                    
                    local requiredSkillTypeIndex = nil
                    local requiredTools = nil
                    local requiredResources = nil
                    local researchType = nil

                    if uiPlanInfo.researchTypeIndex then
                        requiredSkillTypeIndex = skill.types.researching.index
                        researchType = research.types[uiPlanInfo.researchTypeIndex]
                        if researchType.requiredToolTypeIndex then
                            requiredTools = {researchType.requiredToolTypeIndex}
                        end
                    else
                        if uiPlanInfo.planTypeIndex == plan.types.clone.index then
                            buildConstructableTypeIndex = constructable:getConstructableTypeIndexForCloneOrRebuild(objectsOrVerts[1])
                        elseif uiPlanInfo.planTypeIndex == plan.types.build.index  or 
                        uiPlanInfo.planTypeIndex == plan.types.buildPath.index or
                        uiPlanInfo.planTypeIndex == plan.types.plant.index then
                            local objectState = objectsOrVerts[1].sharedState
                            buildConstructableTypeIndex = objectState.inProgressConstructableTypeIndex
                            if not buildConstructableTypeIndex then
                                buildConstructableTypeIndex = objectState.constructionConstructableTypeIndex
                            end
                        end
                        
                        if buildConstructableTypeIndex then
                            local constructableType = constructable.types[buildConstructableTypeIndex]
                            if constructableType.skills and constructableType.skills.required then
                                requiredSkillTypeIndex = constructableType.skills.required
                            end
                        end
                    end

                    
                    if foundPlanInfo.requirements then --changed 0.4 to override the researchType with the planInfo from planHelper, as it gives more contextural control 
                        if foundPlanInfo.requirements.skill then
                            requiredSkillTypeIndex = foundPlanInfo.requirements.skill
                        end
                        if foundPlanInfo.requirements.toolTypeIndex then
                            requiredTools = {foundPlanInfo.requirements.toolTypeIndex}
                        end
                    end

                    local resultToAdd = nil

                    local function addProblem(problemName, problemValue)
                        if not resultToAdd then
                            resultToAdd = {
                                planTypeIndex = uiPlanInfo.planTypeIndex,
                                objectTypeIndex = uiPlanInfo.objectTypeIndex,
                                researchTypeIndex = uiPlanInfo.researchTypeIndex,
                            }
                        end
                        resultToAdd[problemName] = problemValue
                    end
                    

                    --[[local orderedPlans = orderedPlansByTribeID[tribeID]
                    if orderedPlans then
                        local maxPlanCount = maxOrdersByTribeID[tribeID]
                        if maxPlanCount and #orderedPlans >= maxPlanCount then
                            addProblem("disabledDueToOrderLimit", true)
                        end
                    end]]

                    --[[if hasReachedMaxPlansByTribeID[tribeID] then
                        addProblem("disabledDueToOrderLimit", true)
                    end]]

                    --mj:log("requiredTools:", requiredTools)
                    
                    local missingSkill = false
                    if requiredSkillTypeIndex then
                        missingSkill = getIsMissingRequiredSkill(tribeID, requiredSkillTypeIndex, nil)
                        if missingSkill then
                            addProblem("missingSkill", requiredSkillTypeIndex)
                        end
                    end

                    if not missingSkill then
                        local foundClose = false
                        if plan.types[uiPlanInfo.planTypeIndex].skipMaxOrderChecks then
                            foundClose = true
                        else
                            local closeSapiensBySkillType = getCloseSapiensBySkillTypeForObjectForTribe(tribeID, objectsOrVerts[1].uniqueID, false)
                            if closeSapiensBySkillType then
                                local skillTypeIndexSaveKeyToUse = requiredSkillTypeIndex or 0
                                local closeSapiens = closeSapiensBySkillType[skillTypeIndexSaveKeyToUse]

                                if closeSapiens then
                                    for sapienID,sapienTribeID in pairs(closeSapiens) do
                                        if sapienTribeID == tribeID then
                                            foundClose = true
                                            break
                                        end
                                    end
                                end
                            end
                        end

                        if not foundClose then
                            local sapienSetIndex = serverGOM.objectSets.sapiens
                            if requiredSkillTypeIndex then
                                sapienSetIndex = skill.types[requiredSkillTypeIndex].sapienSetIndex
                            end
                            
                            local closeContenders = serverGOM:getGameObjectsInSetWithinRadiusOfPos(sapienSetIndex, objectsOrVerts[1].pos, planManager.maxPlanDistance)
                            for j,objectInfo in ipairs(closeContenders) do
                                local sapien = serverGOM:getObjectWithID(objectInfo.objectID)
                                if sapien and sapien.sharedState.tribeID == tribeID then
                                    if researchType and researchType.disallowsLimitedAbilitySapiens then
                                        if not sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                                            foundClose = true
                                            break
                                        end
                                    else
                                        foundClose = true
                                        break
                                    end
                                end
                            end
                        end

                        if not foundClose then
                            addProblem("tooDistant", requiredSkillTypeIndex or true)
                        end
                    end

                    local constructableTypeIndexForRequiredStuff = uiPlanInfo.constructableTypeIndex or buildConstructableTypeIndex
                    if constructableTypeIndexForRequiredStuff then
                        local constructableType = constructable.types[constructableTypeIndexForRequiredStuff]
                        requiredResources = constructableType.requiredResources
                        
                        if not requiredTools then
                            requiredTools = constructableType.requiredTools
                        end
                    end

                    if not requiredResources then
                        if uiPlanInfo.planTypeIndex == plan.types.light.index or uiPlanInfo.planTypeIndex == plan.types.addFuel.index then
                            if not fuel:objectHasAnyFuel(objectsOrVerts[1]) then
                                local requiredItems = fuel:getRequiredItemsForFuelAdd(objectsOrVerts[1])
                                if requiredItems then
                                    requiredResources = requiredItems.resources
                                end
                            end
                        end
                    end
                    
                    if not requiredResources then
                        if plan.types[uiPlanInfo.planTypeIndex].isMedicineTreatment then
                            local requiredItems = medicine:getRequiredItemsForPlanType(uiPlanInfo.planTypeIndex)
                            if requiredItems then
                                requiredResources = requiredItems.resources
                            end
                        end
                    end

                    
                    if requiredResources then
                        local restrictedResourceObjectTypes = uiPlanInfo.restrictedResourceObjectTypes
                        if constructableTypeIndexForRequiredStuff then
                            if (not restrictedResourceObjectTypes) then
                                local objectState = objectsOrVerts[1].sharedState
                                if objectState then
                                    restrictedResourceObjectTypes = objectState.restrictedResourceObjectTypes
                                    if restrictedResourceObjectTypes then
                                        restrictedResourceObjectTypes = serverWorld:getResourceBlockListForConstructableTypeIndex(tribeID, constructableTypeIndexForRequiredStuff, restrictedResourceObjectTypes)
                                    end
                                end
                            end
                        elseif plan.types[uiPlanInfo.planTypeIndex].isMedicineTreatment then
                            restrictedResourceObjectTypes = serverWorld:getResourceBlockListForMedicineTreatment(tribeID, restrictedResourceObjectTypes)
                            --mj:log("restrictedResourceObjectTypes:", restrictedResourceObjectTypes)
                        elseif uiPlanInfo.planTypeIndex == plan.types.light.index then
                            local fuelGroup = fuel.groupsByObjectTypeIndex[objectsOrVerts[1].objectTypeIndex]
                            if fuelGroup then
                                restrictedResourceObjectTypes = serverWorld:getResourceBlockListForFuel(tribeID, fuelGroup.index, restrictedResourceObjectTypes)
                            end
                        end
                        
                        local returnedMissingResourceArray = {}
                        local allFound = serverResourceManager:allRequiredResourcesAreAvailable(requiredResources, 
                        objectsOrVerts[1].pos, 
                        true, 
                        restrictedResourceObjectTypes,
                        returnedMissingResourceArray,
                        tribeID)

                        if not allFound then
                            addProblem("missingResources", returnedMissingResourceArray)
                        end
                    end

                    if requiredTools then
                        local objectState = objectsOrVerts[1].sharedState
                        
                        local missingTools = nil
                        for l, toolTypeIndex in ipairs(requiredTools) do
                            local toolObjectTypeIndexes = gameObject.gameObjectTypeIndexesByToolTypeIndex[toolTypeIndex]
                            
                            local restrictedToolObjectTypes = uiPlanInfo.restrictedToolObjectTypes
                            if (not restrictedToolObjectTypes) and objectState then
                                restrictedToolObjectTypes = objectState.restrictedToolObjectTypes
                            end
                            
                            local toolBlockList = nil
                            local resourceBlockLists = serverWorld:getResourceBlockListsForTribe(tribeID)
                            if resourceBlockLists then
                                toolBlockList = resourceBlockLists.toolBlockList
                            end

                            if restrictedToolObjectTypes or toolBlockList then
                                local strippedToolTypIndexes = {}
                                for m,toolObjectTypeIndex in ipairs(toolObjectTypeIndexes) do
                                    if (not toolBlockList) or (not toolBlockList[toolObjectTypeIndex]) then
                                        if (not restrictedToolObjectTypes) or (not restrictedToolObjectTypes[toolObjectTypeIndex]) then
                                            table.insert(strippedToolTypIndexes, toolObjectTypeIndex)
                                        end
                                    end
                                end
                                toolObjectTypeIndexes = strippedToolTypIndexes
                            end

                            --mj:log("check serverResourceManager:anyResourceIsAvailable toolObjectTypeIndexes:", toolObjectTypeIndexes)

                            if not serverResourceManager:anyResourceIsAvailable(toolObjectTypeIndexes, objectsOrVerts[1].pos, true, tribeID) then
                                --mj:log("none available")
                                if not missingTools then
                                    missingTools = {}
                                end
                                table.insert(missingTools, toolTypeIndex)
                            end
                        end

                        if missingTools then
                            addProblem("missingTools", missingTools)
                        end
                    end

                    if serverGOM:objectIsInaccessible(objectsOrVerts[1]) then
                        addProblem("inaccessible", true)
                    end

                    local planType = plan.types[uiPlanInfo.planTypeIndex]
                    local hasPlanRequiringLight = false
                    if planType.requiresLight or uiPlanInfo.planTypeIndex == plan.types.clone.index then
                        hasPlanRequiringLight = true
                        if uiPlanInfo.planTypeIndex == plan.types.build.index then
                            if constructableTypeIndexForRequiredStuff then
                                local constructableType = constructable.types[constructableTypeIndexForRequiredStuff]
                                if constructableType.allowBuildEvenWhenDark then
                                    hasPlanRequiringLight = false
                                end
                            end
                        elseif uiPlanInfo.planTypeIndex == plan.types.research.index and researchType then
                            if researchType.allowResearchEvenWhenDark then
                                hasPlanRequiringLight = false
                            end
                        end
                    end

                    if hasPlanRequiringLight then
                        if planLightProbes:getIsDarkForPos(objectsOrVerts[1].pos) then
                            addProblem("tooDark", true)
                        end
                    end

                    if foundTerrain then
                        local vert = objectsOrVerts[1]
                        local foundHighEnough = vert.altitude > minDigFillAccessableAltitude
                        if plan.types[uiPlanInfo.planTypeIndex].modifiesTerrainHeight or (not foundHighEnough) then
                            local maxAltitude = -99
                            local minAltitude = 99
                            local neighborVerts = terrain:getNeighborVertsForVert(vert.uniqueID)
                            local canDig = true
                            local canFill = true

                            if neighborVerts then
                                for j, neighborVert in ipairs(neighborVerts) do
                                    local neighborAltitude = neighborVert.altitude
                                    if neighborAltitude > maxAltitude then
                                        maxAltitude = neighborAltitude
                                    end
                                    if neighborAltitude < minAltitude then
                                        minAltitude = neighborAltitude
                                    end
                                end

                                local thisAltitude = vert.altitude

                                if maxAltitude - thisAltitude > gameConstants.maxTerrainSteepness then
                                    canDig = false
                                end
                                if thisAltitude - minAltitude > gameConstants.maxTerrainSteepness then
                                    canFill = false
                                end

                                if not foundHighEnough then
                                    foundHighEnough = maxAltitude > minDigFillAccessableAltitude
                                end
                            end

                            if (not foundHighEnough) then
                                addProblem("invalidUnderWater", true)
                            end
                            
                            if uiPlanInfo.planTypeIndex == plan.types.dig.index or uiPlanInfo.planTypeIndex == plan.types.mine.index or uiPlanInfo.planTypeIndex == plan.types.chiselStone.index then
                                if not canDig then
                                    addProblem("terrainTooSteepDig", true)
                                end
                            elseif uiPlanInfo.planTypeIndex == plan.types.fill.index then
                                if not canFill then
                                    addProblem("terrainTooSteepFill", true)
                                end
                            end
                        end
                    end

                    if uiPlanInfo.planTypeIndex == plan.types.storeObject.index or uiPlanInfo.planTypeIndex == plan.types.transferObject.index then
                        local requiresStorageObjectTypeIndex = objectsOrVerts[1].objectTypeIndex
                        if (not serverStorageArea:storageAreaIsAvailableForObjectType(tribeID, requiresStorageObjectTypeIndex, objectsOrVerts[1].pos)) then
                            addProblem("missingStorage", true)
                        end
                    end

                    if resultToAdd then
                        table.insert(result, resultToAdd)
                    end
                end

            end
        end
    end

    if next(result) then
        return result
    end
    return nil
end

function planManager:getHasAvailablePlan(tribeID)
    local orderedPlans = orderedPlansByTribeID[tribeID]
    if orderedPlans then
        return (orderedPlans[1] ~= nil)
    end
    return false
end

function planManager:iteratePlans(tribeID, func, sapien)
    
    local orderedPlans = orderedPlansByTribeID[tribeID]
   -- mj:log("orderedPlans:", orderedPlans, " tribeID:", tribeID)
    if orderedPlans then
        local unsavedState = serverGOM:getUnsavedPrivateState(sapien)
        ----disabled--mj:objectLog(sapien.uniqueID, "iterate plans orderedPlans:", orderedPlans, " tribeID:", tribeID)

        if not unsavedState.nextIdleCheckTime or unsavedState.nextIdleCheckTime < serverWorld:getWorldTime() then
            local planCount = #orderedPlans
            if planCount > 0 then
                local startIndex = sapien.privateState.iteratePlansStartIndex or 1
                if startIndex > planCount then
                    startIndex = 1
                end
                for planIndex=startIndex,planCount do
                    --disabled--mj:objectLog(sapien.uniqueID, "iterate plans planIndex:", planIndex, "/", planCount)
                    local planInfo = orderedPlans[planIndex]
                    if not planInfo then --fix to crash in 0.4, I guess plans can get removed from orderedPlans during this loop
                        break
                    end
                    if planManager.canPossiblyCompleteForSapienIterationByPlanID[planInfo.planID] then
                        local object = serverGOM:getObjectWithID(planInfo.objectID)
                        if object then
                            --disabled--mj:objectLog(sapien.uniqueID, "iterate plans testing object:", planInfo.objectID)
                            if not func(object) then
                                sapien.privateState.iteratePlansStartIndex = planIndex + 1
                                return
                            end
                        end
                    --else
                        --mj:log("plan rejected due to canPossiblyCompleteForSapienIterationByPlanID for planInfo:", planInfo)
                    end
                end
                sapien.privateState.iteratePlansStartIndex = nil
                unsavedState.nextIdleCheckTime = serverWorld:getWorldTime() + 5.0 + 5.0 * rng:randomValue()
            end
        end
    end


    --[[local planObjectsByThisTribeID = completablePlanObjectsByTribeID[tribeID]
    if planObjectsByThisTribeID and #planObjectsByThisTribeID > 0 then
        local randomBase = (math.max((rng:randomValue() - 0.2), 0.0) / 0.8)-- earlier indexes have higher priority, so this will start at 1 20% of the time
        randomBase = randomBase * randomBase -- and square it too for good measure. Majority can start at priority tasks, but sometimes they need to look elsewhere too
        local randomOffset = math.floor(mjm.clamp(randomBase * #planObjectsByThisTribeID, 0, #planObjectsByThisTribeID))
        local planCount = #planObjectsByThisTribeID
        ----disabled--mj:objectLog(sapienID, "planManager:iteratePlans randomOffset:", randomOffset, " planObjectsByThisTribeID:", planObjectsByThisTribeID)
        for i=1,planCount do
            local iToUse = ((i - 1) + randomOffset) % planCount + 1
            local planObjectInfo = planObjectsByThisTribeID[iToUse]
            if planObjectInfo then
                --disabled--mj:objectLog(sapienID, "planManager:iteratePlans planObjectInfo.priorityOffset:", planObjectInfo.priorityOffset)
                if not func(planObjectInfo.object) then
                    return
                end
            end
        end
    end]]
end

function planManager:update(dt)
    planLightProbes:update(dt)
    for tribeID,timer in pairs(needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs) do
        timer = timer + dt
        if timer > 5.0 then
            planManager:updatePlansForFollowerOrOrderCountChange(tribeID)
        else
            needsToUpdatePlansForFollowerOrOrderCountChangeTimersByTribeIDs[tribeID] = timer
        end
    end
    planManager:cancelAnyResearchPlans()
end

return planManager