local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local length2 = mjm.length2
--local vec4 = mjm.vec4
--local normalize = mjm.normalize
--local mat3LookAtInverse = mjm.mat3LookAtInverse

local model = mjrequire "common/model"
--local order = mjrequire "common/order"
local plan = mjrequire "common/plan"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"
local desire = mjrequire "common/desire"
local need = mjrequire "common/need"
local mood = mjrequire "common/mood"
local resource = mjrequire "common/resource"
--local storage = mjrequire "common/storage"
local constructable = mjrequire "common/constructable"
local research = mjrequire "common/research"
local skill = mjrequire "common/skill"
--local physicsSets = mjrequire "common/physicsSets"
local gameObject = mjrequire "common/gameObject"
local sapienConstants = mjrequire "common/sapienConstants"

local logicInterface = mjrequire "mainThread/logicInterface"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local sapienMarkersUI = mjrequire "mainThread/ui/sapienMarkersUI"
local playerSapiens = mjrequire "mainThread/playerSapiens"
--local uiObjectManager = mjrequire "mainThread/uiObjectManager"
local audio = mjrequire "mainThread/audio"
local eventManager = mjrequire "mainThread/eventManager"
local worldUIViewManager = mjrequire "mainThread/worldUIViewManager"

local localPlayer = nil
local gameUI = nil

local changeAssignedSapienUI = {}

local planObjectInfo = nil
local planInfo = nil
local planState = nil

local topView = nil
local titleView = nil
local subTitleView = nil
local iconView = nil
local lookAtSapienID = nil
local lookAtSapienCanDoJob = false
--local lookAtSapienCanDoJobIfRoleAssigned = false
local world = nil

local titleIconHalfSize = 20

function changeAssignedSapienUI:setLocalPlayer(localPlayer_, world_) 
    localPlayer = localPlayer_
    world = world_
end

local function checkNeedsAllowObjectTypeToBeCarriedProblem(resourceTypeIndex, foodDesire, restDesire, sleepDesire, happySadMood)
    if foodDesire >= desire.levels.mild then
        local foodValue = resource.types[resourceTypeIndex].foodValue
        if foodValue then
            return nil
        end
    end

    local maxSleepRestDesire = math.max(restDesire, sleepDesire)
    if maxSleepRestDesire >= desire.levels.strong then
        return locale:get("ui_tooTiredToWork")
    end

    return nil
end

local function getMaxCarryCountProblem(sapien, resourceTypeIndex)
    local needsResult =  checkNeedsAllowObjectTypeToBeCarriedProblem(resourceTypeIndex, 
    desire:getDesire(sapien, need.types.food.index, false), 
    desire:getDesire(sapien, need.types.rest.index, true), 
    desire:getSleep(sapien, world:getTimeOfDayFraction(sapien.pos)), 
    mood:getMood(sapien, mood.types.happySad.index))

    if needsResult then
        return needsResult
    end
    
    return nil
end

local function quickFirstResourceTypeIndexToSeeIfCanCarryForRequiredPickup(storageObject)
    local inventory = storageObject.sharedState.inventory
    if inventory and inventory.objects and #inventory.objects > 0 then
        local objectTypeIndex = inventory.objects[#inventory.objects].objectTypeIndex
        return gameObject.types[objectTypeIndex].resourceTypeIndex
    end
    return nil
end

local function getCantDoPlanReasonInfo(sapien, planTypeIndex, planObject)
    if planTypeIndex == plan.types.storeObject.index or planTypeIndex == plan.types.transferObject.index or planTypeIndex == plan.types.deliverToCompost.index then
        local resourceTypeIndex = nil
        if gameObject.types[planObject.objectTypeIndex].isStorageArea then
            resourceTypeIndex = quickFirstResourceTypeIndexToSeeIfCanCarryForRequiredPickup(planObject)
        else
            resourceTypeIndex = gameObject.types[planObject.objectTypeIndex].resourceTypeIndex
        end
        if not resourceTypeIndex then
            return {
                canAssign = false,
                infoText = skill:getLimitedAbilityReason(sapien.sharedState, false)
            }
        end

        local carryResult = getMaxCarryCountProblem(sapien, resourceTypeIndex)
        if carryResult then
            return {
                canAssign = false,
                infoText = carryResult
            }
        end
    end

   --[[ if planTypeIndex == plan.types.hunt.index or planTypeIndex == plan.types.dig.index or planTypeIndex == plan.types.chop.index or planTypeIndex == plan.types.mine.index then
        if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
            return skill:getLimitedAbilityReason(sapien.sharedState, false)
        end
    end]]

    local constructableTypeIndex = planState.constructableTypeIndex
    if constructableTypeIndex then
        local constructableType = constructable.types[constructableTypeIndex]
        if constructableType.disallowsLimitedAbilitySapiens then
            if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                return {
                    canAssign = false,
                    infoText = skill:getLimitedAbilityReason(sapien.sharedState, false)
                }
            end
        end

    end

    if planTypeIndex == plan.types.research.index then
        local researchTypeIndex = planState.researchTypeIndex
        if research.types[researchTypeIndex].disallowsLimitedAbilitySapiens then
            if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                return {
                    canAssign = false,
                    infoText = skill:getLimitedAbilityReason(sapien.sharedState, false)
                }
            end
        end
    end

    if planTypeIndex == plan.types.haulObject.index then
        if not planObject.sharedState.waterRideable then
            if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState, true) then
                return {
                    canAssign = false,
                    infoText = skill:getLimitedAbilityReason(sapien.sharedState, false)
                }
            end
        end
    end

    if planState.requiredSkill then
        if skill.types[planState.requiredSkill].noCapacityWithLimitedGeneralAbility or skill.types[planState.requiredSkill].partialCapacityWithLimitedGeneralAbility then
            if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                local hasPartialCapacity = (not skill.types[planState.requiredSkill].noCapacityWithLimitedGeneralAbility)
                local infoText = skill:getLimitedAbilityReason(sapien.sharedState, hasPartialCapacity)
                return {
                    canAssign = false,
                    infoText = infoText
                }
            end
        end
        
    
        local priorityLevel = skill:priorityLevel(sapien, planState.requiredSkill)
        if priorityLevel == 1 then
            return nil
        end

        local infoText = locale:get("ui_missingTaskAssignment", {
            taskName = skill.types[planState.requiredSkill].name
        })

        return {
            canAssign = true,
            infoText = infoText
        }

    end


    return nil
end

local function updateTopViewSize()
    
    local maxWidth = math.max(200, titleView.size.x + 30 + titleIconHalfSize * 2.0)
    local height = titleView.size.y + 10

    if not subTitleView.hidden then
        maxWidth = math.max(maxWidth, subTitleView.size.x + 20)
        height = height + subTitleView.size.y
    end

    local sizeToUse = vec2(maxWidth, height)

    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / 0.4
    topView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    topView.size = sizeToUse

end

local function updateTitleText()
    titleView:setText(locale:get("ui_name_changeAssignedSapien"), material.types.standardText.index)
    iconView:setModel(model:modelIndexForName("icon_sapien"))
    updateTopViewSize()
end


local function updateSubtitle(subtitleTextOrNil, colorOrNil) --if color changes but not text, it's currently ignored.
    if subtitleTextOrNil then
        subTitleView.hidden = false
        subTitleView.text = subtitleTextOrNil
        subTitleView.color = colorOrNil or mj.textColor
    else
        subTitleView.hidden = true
    end

    updateTopViewSize()
end

function changeAssignedSapienUI:load(gameUI_)
    gameUI = gameUI_
    
    topView = ModelView.new(gameUI.worldViews)
    topView:setModel(model:modelIndexForName("ui_panel_10x4"))
    topView.hidden = true;
    topView.alpha = 0.9
    topView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    topView.baseOffset = vec3(0, -20, 0)

    --[[titleView = ModelTextView.new(topView)
    titleView.font = Font(uiCommon.fontName, 36)
    titleView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    titleView.baseOffset = vec3(titleIconHalfSize,0,0)]]

    
    titleView = ModelTextView.new(topView)
    titleView.font = Font(uiCommon.fontName, 36)
    titleView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleView.baseOffset = vec3(titleIconHalfSize, -6, 0)
    
    iconView = ModelView.new(topView)
    iconView.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
    iconView.relativeView = titleView
    iconView.baseOffset = vec3(-5,0,0)
    iconView.scale3D = vec3(titleIconHalfSize,titleIconHalfSize,titleIconHalfSize)
    iconView.size = vec2(titleIconHalfSize,titleIconHalfSize) * 2.0
    
    --[[titleGameObjectView = uiGameObjectView:create(topView, vec2(titleIconHalfSize,titleIconHalfSize) * 2.0, uiGameObjectView.types.standard)
    --uiGameObjectView:setBackgroundAlpha(gameObjectView, 0.6)
    titleGameObjectView.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
    titleGameObjectView.relativeView = titleView
    titleGameObjectView.baseOffset = vec3(-5,0,0)]]

    subTitleView = TextView.new(topView)
    subTitleView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    subTitleView.relativeView = titleView
    subTitleView.font = Font(uiCommon.fontName, 16)
    subTitleView.color = mj.textColor
    subTitleView.hidden = true
    subTitleView.baseOffset = vec3(-titleIconHalfSize, 0, 0)

    eventManager:addControllerCallback(eventManager.controllerSetIndexInGame, true, "confirm", function(isDown)
        if isDown and topView and (not topView.hidden) then
            changeAssignedSapienUI:terrainOrObjectClicked(false, 0)
            return true
        end
        return false
    end)
    
    updateTitleText()
end

function changeAssignedSapienUI:show(objectInfo_, planInfo_)
    -- mj:error("changeAssignedSapienUI:show()")
    -- mj:log("changeAssignedSapienUI:show:", sapienIDs_)
    planObjectInfo = objectInfo_
    planInfo = planInfo_
    sapienMarkersUI:showAllMarkers()
    worldUIViewManager:setAllHiddenExceptGroup(worldUIViewManager.groups.sapienMarker)

    planState = nil

    --mj:log("changeAssignedSapienUI:show planInfo:", planInfo, " planObjectInfo:", planObjectInfo)
    
    local sharedState = planObjectInfo.sharedState
    local planStatesByTribeID = sharedState.planStates
    if planStatesByTribeID then
        local planStates = planStatesByTribeID[world.tribeID]
        if planStates then
            for i,thisPlanState in ipairs(planStates) do
                if planInfo.planTypeIndex == thisPlanState.planTypeIndex and
                planInfo.researchTypeIndex == thisPlanState.researchTypeIndex and
                ((not planInfo.objectTypeIndex) or planInfo.objectTypeIndex == thisPlanState.objectTypeIndex) then
                    planState = thisPlanState
                    break
                end
            end
        end
    end

    if not planState then
        mj:error("No matching plan state found in changeAssignedSapienUI:show")
        planObjectInfo = nil
        planInfo = nil
        return
    else
        if topView.hidden then
            topView.hidden = false
            gameUI:updateWarningNoticeForTopPanelDisplayed(-topView.size.y - 10)
        end
        updateSubtitle(nil, nil)

        local sapiens = playerSapiens:getFollowerInfos()
        local sapienIDsToHide = {}

        for sapienID, sapien in pairs(sapiens) do
            if getCantDoPlanReasonInfo(sapien, planInfo.planTypeIndex, planObjectInfo) then
                table.insert(sapienIDsToHide, sapienID)
                --mj:log("not ok:", sapienID)
            --else
                --mj:log("ok:", sapienID)
            end
        end

        sapienMarkersUI:hideMarkers(sapienIDsToHide)
    end
end

function changeAssignedSapienUI:update()
   --[[ if not changeAssignedSapienUI:hidden() then
    end]]
end

function changeAssignedSapienUI:hide()
    if topView and not topView.hidden then
        topView.hidden = true
        gameUI:updateWarningNoticeForTopPanelWillHide()
        sapienMarkersUI:showAllMarkers()
        worldUIViewManager:unhideAllGroups()
    end
    gameUI:updateUIHidden()
end

function changeAssignedSapienUI:hidden()
    return (topView and topView.hidden)
end




function changeAssignedSapienUI:updateLookAtObject(uniqueID)
    if lookAtSapienID ~= uniqueID then
        if uniqueID then
            local lookAtObject = localPlayer.retrievedLookAtObject
            if lookAtObject and lookAtObject.uniqueID == uniqueID and lookAtObject.objectTypeIndex == gameObject.types.sapien.index then
                lookAtSapienID = uniqueID

                if lookAtObject.sharedState.tribeID == world.tribeID then
                    --mj:log("lookAtObject:", lookAtObject)
                    local cantDoPlanReasonInfo = getCantDoPlanReasonInfo(lookAtObject, planInfo.planTypeIndex, planObjectInfo)
                    if cantDoPlanReasonInfo then
                        if cantDoPlanReasonInfo.canAssign then
                            updateSubtitle(cantDoPlanReasonInfo.infoText, material:getUIColor(material.types.warning.index))
                            lookAtSapienCanDoJob = true
                        else
                            updateSubtitle(cantDoPlanReasonInfo.infoText, material:getUIColor(material.types.ui_red.index))
                            lookAtSapienCanDoJob = false
                        end
                    else
                        updateSubtitle(nil, nil)
                        lookAtSapienCanDoJob = true
                    end
                else
                    updateSubtitle(locale:get("ui_notInYourTribe"), material:getUIColor(material.types.ui_red.index))
                    lookAtSapienCanDoJob = false
                end
            else
                lookAtSapienCanDoJob = false
                lookAtSapienID = nil
                updateSubtitle(nil, nil)
            end
        else
            lookAtSapienCanDoJob = false
            lookAtSapienID = nil
            updateSubtitle(nil, nil)
        end
    end
end

function changeAssignedSapienUI:terrainOrObjectClicked(wasTerrain, buttonIndex)
    if buttonIndex == 0 and not wasTerrain and lookAtSapienID then
        if lookAtSapienCanDoJob then
            audio:playUISound("audio/sounds/place.wav")

            logicInterface:callServerFunction("assignSapienToPlan", {
                sapienID = lookAtSapienID,
                planObjectID = planObjectInfo.uniqueID,
                planTypeIndex = planInfo.planTypeIndex,
                objectTypeIndex = planInfo.objectTypeIndex,
                researchTypeIndex = planInfo.researchTypeIndex,
            })
            changeAssignedSapienUI:hide()
        else
            audio:playUISound(uiCommon.failSoundFile)
        end
    end
end

function changeAssignedSapienUI:popUI()
    if topView and not topView.hidden then
        changeAssignedSapienUI:hide()
    end
end

return changeAssignedSapienUI