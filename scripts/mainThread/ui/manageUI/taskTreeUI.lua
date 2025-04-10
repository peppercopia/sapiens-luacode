local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local skill = mjrequire "common/skill"
local research = mjrequire "common/research"
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local roleUICommon = mjrequire "mainThread/ui/roleUICommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local playerSapiens = mjrequire "mainThread/playerSapiens"
local uiHorizontalScrollView = mjrequire "mainThread/ui/uiCommon/uiHorizontalScrollView"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"

local taskTreeUI = {}

local titleView = nil
local mainView = nil
local insetView = nil
local scrollView = nil

local roleUI = nil
local world = nil

local taskBackgroundSize = roleUICommon.plinthSize

local autoRoleAssignmentToggleButton = nil

local viewsBySkillTypeIndex = {}
local columnViews = {}

function taskTreeUI:init(roleUI_, gameUI, world_, manageUI_, contentView)
    roleUI = roleUI_
    world = world_

    mainView = View.new(contentView)
    mainView.size = vec2(contentView.size.x - 20, contentView.size.y - 70)
    mainView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    mainView.baseOffset = vec3(0,-10 - 50, 0)
    mainView.hidden = true

    
    titleView = View.new(contentView)
    titleView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleView.baseOffset = vec3(0,-16, 0)
    titleView.hidden = true
    --titleView.color = vec4(0.2,0.5,0.9,0.4)


    local autoAssignTextView = TextView.new(titleView)
    autoAssignTextView.font = Font(uiCommon.fontName, 18)
    autoAssignTextView.color = mj.textColor
    autoAssignTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    --autoAssignTextView.baseOffset = vec3(0,-12,0)
    autoAssignTextView.text = locale:get("ui_roles_assignAutomatically") .. ":"

    autoRoleAssignmentToggleButton = uiStandardButton:create(titleView, vec2(26,26), uiStandardButton.types.toggle)
    autoRoleAssignmentToggleButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    autoRoleAssignmentToggleButton.relativeView = autoAssignTextView
    autoRoleAssignmentToggleButton.baseOffset = vec3(4, 0, 0)
    
    uiToolTip:add(autoRoleAssignmentToggleButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_roles_assignAutomatically_toolTip"), nil, vec3(0,-8,4), nil, autoRoleAssignmentToggleButton)
    
    uiStandardButton:setClickFunction(autoRoleAssignmentToggleButton, function()
        world:setAutoRoleAssignmentEnabled(uiStandardButton:getToggleState(autoRoleAssignmentToggleButton))
    end)
    
    titleView.size = vec2(autoAssignTextView.size.x + 4 + autoRoleAssignmentToggleButton.size.x, 20.0)

    --mj:log("taskTreeUI mainView.size", mainView.size)

    local insetViewSize = mainView.size

    insetView = ModelView.new(mainView)
    insetView:setModel(model:modelIndexForName("ui_inset_lg_4x3"))
    local scaleToUsePaneX = insetViewSize.x * 0.5
    local scaleToUsePaneY = insetViewSize.y * 0.5 / 0.75
    insetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    insetView.size = insetViewSize
    
    local scrollViewSize = vec2(insetViewSize.x - 14, insetViewSize.y - 14)
    scrollView = uiHorizontalScrollView:create(insetView, scrollViewSize)
    --scrollView.baseOffset = vec3(0, 0, 0)

    local function customConnectionsCreationFunction(scrollView_)
        local connections = {}
        for columnIndex,skillColumn in ipairs(roleUICommon.skillUIColumns) do
            for rowIndex,skillUIInfo in ipairs(skillColumn) do
                local skillTypeIndex = skillUIInfo.skillTypeIndex
                if skillTypeIndex then
                    local skillView = viewsBySkillTypeIndex[skillTypeIndex]
                    local thisViewConnections = connections[skillView]
                    if not thisViewConnections then
                        thisViewConnections = {}
                        connections[skillView] = thisViewConnections
                    end

                    if rowIndex < #skillColumn then
                        for k=rowIndex+1,#skillColumn do
                            local otherSkillUIInfo = skillColumn[k]
                            if otherSkillUIInfo.skillTypeIndex then
                                local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                                thisViewConnections[uiSelectionLayout.directions.down] = {
                                    view = otherSkillView
                                }
                                break
                            end
                        end
                    end
                    
                    if rowIndex > 1 then
                        for k=rowIndex-1,1,-1 do
                            local otherSkillUIInfo = skillColumn[k]
                            if otherSkillUIInfo.skillTypeIndex then
                                local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                                thisViewConnections[uiSelectionLayout.directions.up] = {
                                    view = otherSkillView
                                }
                                break
                            end
                        end
                    end

                    mj:log("creating connections for:", skill.types[skillTypeIndex].key)

                    if columnIndex < #roleUICommon.skillUIColumns then

                        --[[local found = false 

                        for otherColumnOffset = 1,3 do --search for top child --this is incomplete, started trying to base it on skill requirements, but too many corner cases, probably not actually what we want
                            local otherColumn = roleUICommon.skillUIColumns[columnIndex + otherColumnOffset]
                            if otherColumn then
                                for k,otherSkillUIInfo in ipairs(otherColumn) do
                                    local requiredSkillTypes = otherSkillUIInfo.requiredSkillTypes
                                    if requiredSkillTypes then
                                        for l,requiredSkillTypeIndex in ipairs(requiredSkillTypes) do
                                            if requiredSkillTypeIndex == skillTypeIndex then
                                                
                                                mj:log("right top child:", skill.types[otherSkillUIInfo.skillTypeIndex].key)
                                                found = true
                                                local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                                                thisViewConnections[uiSelectionLayout.directions.right] = {
                                                    view = otherSkillView
                                                }

                                                local otherViewConnections = connections[otherSkillView]
                                                if not otherViewConnections then
                                                    otherViewConnections = {}
                                                    connections[otherSkillView] = otherViewConnections
                                                end

                                                if (not otherViewConnections[uiSelectionLayout.directions.left]) then
                                                    otherViewConnections[uiSelectionLayout.directions.left] = {
                                                        view = skillView
                                                    }
                                                end

                                                break
                                            end
                                        end
                                    end
                                    if found then
                                        break
                                    end
                                end
                            end
                            if found then
                                break
                            end
                        end]]

                        local otherColumn = roleUICommon.skillUIColumns[columnIndex + 1]
                        local startRowIndex = rowIndex
                        if columnIndex % 2 == 1 then
                            startRowIndex = startRowIndex - 1
                        end

                        local otherSkillUIInfo = otherColumn[startRowIndex]
                        if otherSkillUIInfo and otherSkillUIInfo.skillTypeIndex then
                            mj:log("right same index:", skill.types[otherSkillUIInfo.skillTypeIndex].key)
                            local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                            thisViewConnections[uiSelectionLayout.directions.right] = {
                                view = otherSkillView
                            }
                        else
                            local maxDistance = 8
                            for k=1,maxDistance do
                                otherSkillUIInfo = otherColumn[startRowIndex + k]
                                if otherSkillUIInfo and otherSkillUIInfo.skillTypeIndex then
                                    mj:log("right with positive index:", k, " -", skill.types[otherSkillUIInfo.skillTypeIndex].key)
                                    local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                                    thisViewConnections[uiSelectionLayout.directions.right] = {
                                        view = otherSkillView
                                    }
                                    break
                                end
                                otherSkillUIInfo = otherColumn[startRowIndex - k]
                                if otherSkillUIInfo and otherSkillUIInfo.skillTypeIndex then
                                    mj:log("right with negative index:", -k, " -", skill.types[otherSkillUIInfo.skillTypeIndex].key)
                                    local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                                    thisViewConnections[uiSelectionLayout.directions.right] = {
                                        view = otherSkillView
                                    }
                                    break
                                end
                            end
                        end
                    end

                    if columnIndex > 1 and (not thisViewConnections[uiSelectionLayout.directions.left]) then
                        local otherColumn = roleUICommon.skillUIColumns[columnIndex - 1]
                        
                        local startRowIndex = rowIndex
                        if columnIndex % 2 == 0 then
                            startRowIndex = startRowIndex + 1
                        end

                        local otherSkillUIInfo = otherColumn[startRowIndex]
                        if otherSkillUIInfo and otherSkillUIInfo.skillTypeIndex then
                            mj:log("left same index:", skill.types[otherSkillUIInfo.skillTypeIndex].key)
                            local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                            thisViewConnections[uiSelectionLayout.directions.left] = {
                                view = otherSkillView
                            }
                        else
                            local maxDistance = 8
                            for k=1,maxDistance do
                                otherSkillUIInfo = otherColumn[startRowIndex - k]
                                if otherSkillUIInfo and otherSkillUIInfo.skillTypeIndex then
                                    mj:log("left with negative index:", -k, " -", skill.types[otherSkillUIInfo.skillTypeIndex].key)
                                    local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                                    thisViewConnections[uiSelectionLayout.directions.left] = {
                                        view = otherSkillView
                                    }
                                    break
                                end
                                otherSkillUIInfo = otherColumn[startRowIndex + k]
                                if otherSkillUIInfo and otherSkillUIInfo.skillTypeIndex then
                                    mj:log("left with positive index:", k, " -", skill.types[otherSkillUIInfo.skillTypeIndex].key)
                                    local otherSkillView = viewsBySkillTypeIndex[otherSkillUIInfo.skillTypeIndex]
                                    thisViewConnections[uiSelectionLayout.directions.left] = {
                                        view = otherSkillView
                                    }
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        return connections
    end
    
    uiSelectionLayout:createForView(scrollView, customConnectionsCreationFunction)

    local connectionsBackgroundView = View.new(scrollView)
    connectionsBackgroundView.size = scrollView.size
    roleUICommon:constructBackgroundConnections(connectionsBackgroundView)
    uiHorizontalScrollView:addBackgroundView(scrollView, connectionsBackgroundView)

end


local shouldScrollOnSelectionEvents = true --bit of a hack to avoid scrolling to start every time. Possibly uiSelectionLayout should track whether event is user or programatic, or we should auto-scroll based on some other mechanism entirely
local previouslySelectedSkillTypeIndex = nil

function taskTreeUI:show()
    uiSelectionLayout:removeAllViews(scrollView)
    
    uiStandardButton:setToggleState(autoRoleAssignmentToggleButton, world:getAutoRoleAssignmentEnabled())

    shouldScrollOnSelectionEvents = false
   -- local xOffset = 0--roleUICommon.plinthInitialXOffset
    for i,skillColumn in ipairs(roleUICommon.skillUIColumns) do

        local columnView = columnViews[i]
        if not columnView then
            columnView = View.new(scrollView)
            columnView.size = vec2(taskBackgroundSize.x + roleUICommon.plinthPadding.x, scrollView.size.y)
            uiHorizontalScrollView:insertColumn(scrollView, columnView)
            columnViews[i] = columnView
        end

        local yOffset = roleUICommon.plinthInitialYOffset
        if i % 2 == 0 then
            yOffset = yOffset - (taskBackgroundSize.y) / 2 - roleUICommon.plinthPadding.y / 2
        end
        for j,skillUIInfo in ipairs(skillColumn) do
            local skillTypeIndex = skillUIInfo.skillTypeIndex
            if skillTypeIndex then
                if viewsBySkillTypeIndex[skillTypeIndex] then
                    columnView:removeSubview(viewsBySkillTypeIndex[skillTypeIndex])
                end
                
                local complete = true
                local researchType = research.researchTypesBySkillType[skillTypeIndex]
                if researchType then
                    local discoveryStatus = world:discoveryInfoForResearchTypeIndex(researchType.index)
                    complete = discoveryStatus and discoveryStatus.complete
                end


                local visible = complete
                if not visible then
                    local requiredSkillTypes = skillUIInfo.requiredSkillTypes
                    local allComplete = true
                    local anyComplete = false
                    if requiredSkillTypes then
                        for k,requiredSkillTypeIndex in ipairs(requiredSkillTypes) do

                            local thisComplete = true
                            local thisResearchType = research.researchTypesBySkillType[requiredSkillTypeIndex]
                            if thisResearchType then
                                local discoveryStatus = world:discoveryInfoForResearchTypeIndex(thisResearchType.index)
                                thisComplete = discoveryStatus and discoveryStatus.complete
                            end

                            if (not thisComplete) then
                                allComplete = false
                            else
                                anyComplete = true
                            end
                        end
                    end
                    if allComplete then
                        visible = true
                    elseif skillUIInfo.onlyRequiresSingleSkillUnlocked and anyComplete then
                        visible = true
                    end
                end

                local backgroundMaterialTable = nil

                if not complete then
                    backgroundMaterialTable = {
                        default = material.types.ui_background_inset.index
                    }
                else
                    backgroundMaterialTable = {
                        default = material.types.ui_background.index
                    }
                end
                
                local backgroundView = uiStandardButton:create(columnView, taskBackgroundSize, uiStandardButton.types.slim_4x1, backgroundMaterialTable)

                backgroundView.userData.selectionLayoutAllowsDisabledSelection = true
                uiStandardButton:setSelectionChangedCallbackFunction(backgroundView, function(isSelected)
                    if isSelected then
                        previouslySelectedSkillTypeIndex = skillTypeIndex
                        if shouldScrollOnSelectionEvents then
                            uiHorizontalScrollView:scrollToVisible(scrollView, i, columnView)
                        end
                    end
                end)
                
                uiSelectionLayout:addView(scrollView, backgroundView)
                
                if previouslySelectedSkillTypeIndex == skillTypeIndex then
                    uiSelectionLayout:setSelection(scrollView, backgroundView)
                end

                --local backgroundView = ModelView.new(insetView)
                viewsBySkillTypeIndex[skillTypeIndex] = backgroundView
                --backgroundView:setModel(model:modelIndexForName("ui_panel_10x3"))
                
                --local scaleToUseX = taskBackgroundSize.x * 0.5
                -- local scaleToUseY = taskBackgroundSize.y * 0.5 / 0.3
                --backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
                -- backgroundView.size = taskBackgroundSize
                backgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
                if complete then
                    backgroundView.baseOffset = vec3(roleUICommon.plinthInitialXOffset, yOffset, 4)
                else
                    backgroundView.baseOffset = vec3(roleUICommon.plinthInitialXOffset, yOffset, -1)
                end


                if complete then
                    uiStandardButton:setDisabled(backgroundView, false)
                    uiStandardButton:setClickFunction(backgroundView, function()
                        roleUI:selectTask(skillTypeIndex)
                    end)

                    uiToolTip:add(backgroundView.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), skill.types[skillTypeIndex].description, nil, vec3(0,-8,4), nil, backgroundView, scrollView)
                else
                    uiStandardButton:setDisabled(backgroundView, true)
                end

                if visible then
                    local icon = ModelView.new(backgroundView)
                    icon.masksEvents = false
                    if complete then
                        icon:setModel(model:modelIndexForName(skill.types[skillTypeIndex].icon))
                    else
                        icon:setModel(model:modelIndexForName(skill.types[skillTypeIndex].icon), {
                            default = material.types.ui_disabled.index
                        })
                    end
                    icon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                    icon.baseOffset = vec3(4, 0, 1)
                    local iconHalfSize = 14
                    icon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
                    icon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
                else
                    local icon = ModelView.new(backgroundView)
                    icon.masksEvents = false
                    icon:setModel(model:modelIndexForName("icon_lock"), {
                        default = material.types.ui_disabled.index
                    })
                    icon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                    icon.baseOffset = vec3(4, 0, 1)
                    local iconHalfSize = 14
                    icon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
                    icon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
                end


                --[[if not complete then
                    local lockIcon = ModelView.new(backgroundView)
                    lockIcon.masksEvents = false
                    lockIcon:setModel(model:modelIndexForName("icon_lock"), nil, nil, function(materialIndexToRemap)
                        return material.types.ui_disabled.index 
                    end)
                    lockIcon.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
                    lockIcon.baseOffset = vec3(-4, -4, 1)
                    local lockIconHalfSize = 7
                    lockIcon.scale3D = vec3(lockIconHalfSize,lockIconHalfSize,lockIconHalfSize)
                    lockIcon.size = vec2(lockIconHalfSize,lockIconHalfSize) * 2.0
                end]]

                local titleTextView = TextView.new(backgroundView)
                titleTextView.masksEvents = false
                titleTextView.font = Font(uiCommon.fontName, 14)
                titleTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
                titleTextView.baseOffset = vec3(36,-6, 0)
                if visible then
                    titleTextView.text = skill.types[skillTypeIndex].name
                    if complete then 
                        titleTextView.color = mj.textColor
                    else
                        titleTextView.color = vec4(1.0,1.0,1.0,0.3)
                    end
                else
                    titleTextView.text = "???"
                    titleTextView.color = vec4(1.0,1.0,1.0,0.3)
                end

                
                if complete then
                    local allowCount = playerSapiens:getCountForSkillTypeAndPriority(skillTypeIndex, 1)
                    
                    local iconHalfSize = 6
                    
                    local allowIcon = ModelView.new(backgroundView)
                    allowIcon.masksEvents = false
                    local materialIndex = material.types.ui_green.index
                    if allowCount == 0 then
                        materialIndex = material.types.ui_disabled.index
                    end
                    allowIcon:setModel(model:modelIndexForName("icon_tick"), {
                        default = materialIndex
                    })
                    allowIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
                    allowIcon.baseOffset = vec3(38, 4, 1)
                    allowIcon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
                    allowIcon.size = vec2(iconHalfSize,iconHalfSize) * 2.0

                    local allowCountTextView = TextView.new(backgroundView)
                    allowCountTextView.masksEvents = false
                    allowCountTextView.font = Font(uiCommon.fontName, 14)
                    allowCountTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
                    allowCountTextView.relativeView = allowIcon
                    allowCountTextView.baseOffset = vec3(1,-1, 0)
                    if allowCount == 0 then
                        allowCountTextView.color = vec4(0.4,0.4,0.4,0.6)
                    else
                        allowCountTextView.color = vec4(0.6,1.0,0.6,1.0)
                    end
                    allowCountTextView.text = mj:tostring(allowCount)
                end
            end

            yOffset = yOffset - taskBackgroundSize.y - roleUICommon.plinthPadding.y
        end
        --xOffset = xOffset + taskBackgroundSize.x + roleUICommon.plinthPadding.x
    end
    mainView.hidden = false
    titleView.hidden = false
    uiSelectionLayout:setActiveSelectionLayoutView(scrollView)
    shouldScrollOnSelectionEvents = true

end

function taskTreeUI:hide()
    mainView.hidden = true
    titleView.hidden = true
    uiSelectionLayout:removeActiveSelectionLayoutView(scrollView)
end

return taskTreeUI