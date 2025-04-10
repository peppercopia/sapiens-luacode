local mjm = mjrequire "common/mjm"
local vec4 = mjm.vec4
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local notification = mjrequire "common/notification"
local sapienConstants = mjrequire "common/sapienConstants"
local timer = mjrequire "common/timer"
local gameObject = mjrequire "common/gameObject"
--local grievance = mjrequire "common/grievance"

local clientGameSettings = mjrequire "mainThread/clientGameSettings"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiAnimation = mjrequire "mainThread/ui/uiAnimation"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiFavorView = mjrequire "mainThread/ui/uiCommon/uiFavorView"

local tribeNotificationsUI = {}

--local world = nil
local gameUI = nil
local manageUI = nil
local hubUI = nil
local logicInterface = nil
local parentView = nil
local currentHoverItem = nil

local listView = nil
local listPaneView = nil
local listScrollView = nil

local needsToUpdateListOnHoverExit = false

local function updateList()
    

    local tribeResult = nil
    local globalResult = nil

    local enabledStateByDisplayGroupTypeIndex = {}
    local allDisabled = true
    for i,displayGroupInfo in ipairs(notification.displayGroups) do
        local settingKey = "notificationFilter" .. displayGroupInfo.key
        local notificationFilterDisabled = clientGameSettings:getSetting(settingKey)
        if notificationFilterDisabled then
            enabledStateByDisplayGroupTypeIndex[displayGroupInfo.index] = false
        else
            enabledStateByDisplayGroupTypeIndex[displayGroupInfo.index] = true
            allDisabled = false
        end
    end

    if allDisabled then
        for k,v in pairs(enabledStateByDisplayGroupTypeIndex) do
            enabledStateByDisplayGroupTypeIndex[k] = true
        end
    end


    local function updateUI(combinedResults)
        local viewinfos = {}

        local sapienViewHeight = 30.0
        local circleBackgroundSize = sapienViewHeight - 4.0
        local sapienIconSize = sapienViewHeight - 6.0
        --local buttonSize = sapienViewHeight - 2.0
    
        local function insertRow(notificationInfo)
    
            local notificationType = notification.types[notificationInfo.notificationTypeIndex]

            if notificationType.supressedByDefault then --todo user settings for supressing notifications
                return
            end

            local displayGroupTypeIndex = notificationType.displayGroupTypeIndex or notification.displayGroups.standard.index
            local displayGroupInfo = notification.displayGroups[displayGroupTypeIndex]

            if not enabledStateByDisplayGroupTypeIndex[displayGroupTypeIndex] then
                return
            end

            
            local backgroundMaterialColor = material:getUIColor(displayGroupInfo.backgroundMaterial)
            local foregroundMaterialColor = material:getUIColor(displayGroupInfo.foregroundMaterial)

            local itemView = ColorView.new(listScrollView)
            local backgroundColor = vec4(backgroundMaterialColor.x,backgroundMaterialColor.y,backgroundMaterialColor.z,0.2)
            local selectionHighlightColor = vec4(foregroundMaterialColor.x,foregroundMaterialColor.y,foregroundMaterialColor.z,0.3)
            
            if #viewinfos % 2 == 1 then
                backgroundColor = vec4(backgroundColor.x * 0.8,backgroundColor.y * 0.8,backgroundColor.z * 0.8,0.2)
            end
    
            local insertIndex = #viewinfos + 1
    
            itemView.color = backgroundColor
            itemView.size = vec2(listScrollView.size.x - 20, sapienViewHeight)
            itemView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            
            uiScrollView:insertRow(listScrollView, itemView, nil)
            local viewinfo = {
                itemView = itemView
            }
    
            viewinfos[insertIndex] = viewinfo

                
            local circleView = ModelView.new(itemView)
            circleView:setModel(model:modelIndexForName("ui_circleBackgroundSmallOutline"), {
                [material.types.ui_background.index] = displayGroupInfo.backgroundMaterial,
                [material.types.ui_standard.index] = displayGroupInfo.foregroundMaterial,
            })
            
            local circleBackgroundScale = circleBackgroundSize * 0.5
            circleView.scale3D = vec3(circleBackgroundScale,circleBackgroundScale,circleBackgroundScale)
            circleView.size = vec2(circleBackgroundSize, circleBackgroundSize)
            circleView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            circleView.baseOffset = vec3(8,0,1)
            

            local penalty = (notificationInfo.userData and (notificationInfo.userData.penalty or notificationInfo.userData.cost))

            local objectView = nil
            local objectInfo = notification:getObjectInfo(notificationInfo)
            if objectInfo.objectTypeIndex == gameObject.types.sapien.index then
                objectView = GameObjectView.new(circleView, vec2(sapienIconSize, sapienIconSize))
                objectView.size = vec2(sapienIconSize, sapienIconSize)
                objectView.baseOffset = vec3(0,0,1)

                local animationInstance = uiAnimation:getUIAnimationInstance(sapienConstants:getAnimationGroupKey(objectInfo.sharedState))
                uiCommon:setGameObjectViewObject(objectView, objectInfo, animationInstance)
            elseif notificationInfo.userData.grievanceTypeIndex then
                objectView = uiFavorView:create(circleView, uiFavorView.types.noBackground_notification_1x1_small)
                --favorView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
                uiFavorView:setValue(objectView, -notificationInfo.userData.favorPenaltyTaken, false)
                --objectView.baseOffset = vec3(-4,0,0)
            elseif notificationInfo.userData.reward then
                objectView = uiFavorView:create(circleView, uiFavorView.types.noBackground_notification_1x1_small)
                uiFavorView:setValue(objectView, notificationInfo.userData.reward, false)
            elseif penalty then
                objectView = uiFavorView:create(circleView, uiFavorView.types.noBackground_notification_1x1_small)
                uiFavorView:setValue(objectView, -penalty, false)
            elseif objectInfo.objectTypeIndex then
                objectView = GameObjectView.new(circleView, vec2(sapienIconSize, sapienIconSize))
                objectView.size = vec2(sapienIconSize, sapienIconSize)
                objectView.baseOffset = vec3(0,0,1)
                uiCommon:setGameObjectViewObject(objectView, objectInfo, nil)
            else
                mj:error("missing info:", notificationInfo)
            end
    
            

            local title = notificationType.key
            if notificationType.titleFunction then
                title = notificationType.titleFunction(notificationInfo.userData)
            end


            local zoomIconSize = 20
    
            local nameTextView = TextView.new(itemView)
            nameTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
            nameTextView.relativeView = objectView
            nameTextView.baseOffset = vec3(4,0,1)
            nameTextView.font = Font(uiCommon.fontName, 16)
            nameTextView.color = vec4(1.0,1.0,1.0,1.0)--material:getUIColor(backgroundMaterialText)
            nameTextView.text = title


            local hover = false
            local zoomIcon = nil

            itemView.hoverStart = function()
                --mj:log("start:", insertIndex, " key:", notificationType.key, " hover:", hover)
                if not hover then
                    hover = true
                    currentHoverItem = itemView
                    itemView.color = selectionHighlightColor
                    if not zoomIcon then
                        
                        zoomIcon = ModelView.new(itemView)
                        zoomIcon:setModel(model:modelIndexForName("icon_inspect"), nil)
                        
                        local zoomIconScale = zoomIconSize * 0.5
                        zoomIcon.scale3D = vec3(zoomIconScale,zoomIconScale,zoomIconScale)
                        zoomIcon.size = vec2(zoomIconSize, zoomIconSize)
                        zoomIcon.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
                        zoomIcon.baseOffset = vec3(8,0,1)
                        zoomIcon.relativeView = nameTextView
                    end
                end
            end
        
            itemView.hoverEnd = function()
                --mj:log("end:", insertIndex, " key:", notificationType.key, " hover:", hover)
                if hover then
                    hover = false
                    if currentHoverItem == itemView then
                        currentHoverItem = nil
                    end
                    itemView.color = backgroundColor
                    if zoomIcon then
                        itemView:removeSubview(zoomIcon)
                        zoomIcon = nil
                    end
                    if needsToUpdateListOnHoverExit then
                        timer:addCallbackTimer(0.5, function()
                            if needsToUpdateListOnHoverExit and (not currentHoverItem) then
                                needsToUpdateListOnHoverExit = false
                                updateList()
                            end
                        end)
                    end
                end
            end

            itemView.click = function()

                local function zoomToPos(pos)
                    if pos then
                        manageUI:hide()
                        gameUI:teleportToLookAtPos(pos)
                    end
                end
                
                local function zoomToObject(fullObjectInfo)
                    manageUI:hide()
                    gameUI:followObject(fullObjectInfo, false, {dismissAnyUI = true})
                    hubUI:setLookAtInfo(fullObjectInfo, false, false)
                    hubUI:showInspectUI(fullObjectInfo, nil, false)
                end

                if objectInfo.uniqueID then
                    logicInterface:callLogicThreadFunction("retrieveObject", objectInfo.uniqueID, function(result)
                        --mj:log("retrieveObject result:", result)
                       -- mj:log("objectInfo:", objectInfo)
                        if result and result.found then
                            zoomToObject(result)
                        else
                            zoomToPos(objectInfo.pos)
                        end
                    end)
                else
                    zoomToPos(objectInfo.pos)
                end
            end
        end

        for i=#combinedResults,1,-1 do
            insertRow(combinedResults[i])
        end
    end

    local function processResults()
        
        uiScrollView:removeAllRows(listScrollView)
        local combinedResults = {}
        if globalResult and tribeResult then
            local globalResultIndex = 1
            local tribeResultIndex = 1

            while true do
                local thisGlobalResult = globalResult[globalResultIndex]
                local thisTribeResult = tribeResult[tribeResultIndex]

                if not thisGlobalResult then
                    if not thisTribeResult then
                        break
                    end
                    table.insert(combinedResults, thisTribeResult)
                    tribeResultIndex = tribeResultIndex + 1
                elseif not thisTribeResult then
                    table.insert(combinedResults, thisGlobalResult)
                    globalResultIndex = globalResultIndex + 1
                else
                    if thisGlobalResult.time < thisTribeResult.time then
                        table.insert(combinedResults, thisGlobalResult)
                        globalResultIndex = globalResultIndex + 1
                    else
                        table.insert(combinedResults, thisTribeResult)
                        tribeResultIndex = tribeResultIndex + 1
                    end
                end
            end
        end

        updateUI(combinedResults)
    end

    logicInterface:callServerFunction("getNotifications", { 
        globalNotifications = true
    }, 
    function(result)
        globalResult = result
        processResults()
    end)

    logicInterface:callServerFunction("getNotifications", nil,
    function(result)
        tribeResult = result
        processResults()
    end)
end

function tribeNotificationsUI:init(gameUI_, world_, manageUI_, hubUI_, parentView_, logicInterface_)
    gameUI = gameUI_
    manageUI = manageUI_
    hubUI = hubUI_
    parentView = parentView_
    logicInterface = logicInterface_
    --world = world_
    
    local contentView = View.new(parentView)
    contentView.size = parentView.size
    
    listView = View.new(contentView)
    listView.size = vec2(contentView.size.x - 20, contentView.size.y - 20.0)
    listView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    listView.baseOffset = vec3(0,-10, 0)

    local insetViewSize = vec2(listView.size.x, listView.size.y - 60)
    local scrollViewSize = vec2(insetViewSize.x - 22, insetViewSize.y - 22)

    listPaneView = ModelView.new(listView)
    listPaneView:setModel(model:modelIndexForName("ui_inset_lg_4x3"))
    local scaleToUsePaneX = insetViewSize.x * 0.5
    local scaleToUsePaneY = insetViewSize.y * 0.5 / 0.75
    listPaneView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    listPaneView.size = insetViewSize
    listPaneView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    --listPaneView.baseOffset = vec3(20,20,0)

    listScrollView = uiScrollView:create(listPaneView, scrollViewSize, MJPositionInnerLeft)
    listScrollView.baseOffset = vec3(0,0,4)
    
    local filterTextView = TextView.new(contentView)
    filterTextView.font = Font(uiCommon.fontName, 18)
    filterTextView.color = mj.textColor
    filterTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    filterTextView.baseOffset = vec3(-44 * #notification.displayGroups * 0.5, -25, 0)
    filterTextView.text = locale:get("ui_action_filter") .. ":"

    local relativeView = filterTextView
    for i,displayGroupInfo in ipairs(notification.displayGroups) do
        local toggleButton = uiStandardButton:create(parentView, vec2(40,40), uiStandardButton.types.filterToggle)
        toggleButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionTop)
        toggleButton.relativeView = relativeView
        if i == 1 then
            toggleButton.baseOffset = vec3(4, 8, 0)
        end

        uiStandardButton:setIconModel(toggleButton, displayGroupInfo.icon, {
            default = displayGroupInfo.foregroundMaterial
        })
        
        uiToolTip:add(toggleButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), displayGroupInfo.name, nil, nil, nil, toggleButton)

        local settingKey = "notificationFilter" .. displayGroupInfo.key
        local notificationFilterDisabled = clientGameSettings:getSetting(settingKey)
        if not notificationFilterDisabled then
            uiStandardButton:setToggleState(toggleButton, true)
        end

        uiStandardButton:setClickFunction(toggleButton, function()
            clientGameSettings:changeSetting(settingKey, (not uiStandardButton:getToggleState(toggleButton)))
            updateList()
        end)

        relativeView = toggleButton
    end
end

function tribeNotificationsUI:updateDataDueToNewNotificationsIfVisible()
    if (not parentView.hidden) then
        if currentHoverItem then
            needsToUpdateListOnHoverExit = true
        else
            updateList()
        end
    end
end

function tribeNotificationsUI:update()
    
end

function tribeNotificationsUI:show()
    currentHoverItem = nil
    updateList()
end


function tribeNotificationsUI:hide()
    uiScrollView:removeAllRows(listScrollView)
    currentHoverItem = nil
end

function tribeNotificationsUI:popUI()
    return false
end

return tribeNotificationsUI