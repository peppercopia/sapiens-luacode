local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local skill = mjrequire "common/skill"
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"
local sapienConstants = mjrequire "common/sapienConstants"

local playerSapiens = mjrequire "mainThread/playerSapiens"
local localPlayer = mjrequire "mainThread/localPlayer"

local uiAnimation = mjrequire "mainThread/ui/uiAnimation"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local sapienTrait = mjrequire "common/sapienTrait"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local tutorialUI = mjrequire "mainThread/ui/tutorialUI"
--local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"

local taskAssignUI = {}
local mainView = nil
local insetViewInfos = {}

local skillTypeIndex = nil
local roleUI = nil
local gameUI = nil
local manageUI = nil
local hubUI = nil

local titleView = nil
local titleIcon = nil
local titleTextView = nil

local iconHalfSize = 14
local iconPadding = 6

local columns = mj:indexed {
    {
        key = "traits",
        title = "+",
        width = 20.0
    },
    {
        key = "sapien",
        title = locale:get("tribeUI_sapien"),
        width = 160.0
    },
    {
        key = "distance",
        title = locale:get("tribeUI_distance"),
        width = 60.0
    },
    {
        key = "age",
        title = locale:get("tribeUI_age"),
        width = 50.0
    },
    {
        key = "roles",
        title = locale:get("tribeUI_roles"),
        width = 230.0
    },
}

local tableViews = {
    {
        sortHeaderIndex = columns.traits.index,
        sortOrderFlipped = false,
        columnViewInfos = {},
    },
    {
        sortHeaderIndex = columns.traits.index,
        sortOrderFlipped = false,
        columnViewInfos = {},
    }
}

function taskAssignUI:init(roleUI_, gameUI_, world_, manageUI_, hubUI_, contentView)
    roleUI = roleUI_
    gameUI = gameUI_
    manageUI = manageUI_
    hubUI = hubUI_

    mainView = View.new(contentView)
    mainView.size = vec2(contentView.size.x - 20, contentView.size.y - 20)
    mainView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    mainView.baseOffset = vec3(0,-10, 0)
    mainView.hidden = true

    

    titleView = View.new(mainView)
    titleView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleView.baseOffset = vec3(0,-5, 0)
    titleView.size = vec2(200, 32.0)
    
    titleIcon = ModelView.new(titleView)
    titleIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    --icon.baseOffset = vec3(4, 0, 1)
    titleIcon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
    titleIcon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
    titleIcon:setModel(model:modelIndexForName("icon_tribe2"))

    titleTextView = ModelTextView.new(titleView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    titleTextView.relativeView = titleIcon
    titleTextView.baseOffset = vec3(iconPadding, 0, 0)

    
    local backButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    backButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    backButton.baseOffset = vec3(0, 0, 0)
    uiStandardButton:setIconModel(backButton, "icon_back")
    uiStandardButton:setClickFunction(backButton, function()
        manageUI_:show(manageUI_.modeTypes.task)
        --optionsMenu:hide()
    end)


    local insetViewSize = vec2((mainView.size.x - 20) / 2, mainView.size.y - 70)
    local scrollViewSize = vec2(insetViewSize.x - 10, insetViewSize.y - 10)

    for i=1,2 do

        local insetView = ModelView.new(mainView)
        insetView:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
        local scaleToUsePaneX = insetViewSize.x * 0.5 / (2.0/3.0)
        local scaleToUsePaneY = insetViewSize.y * 0.5
        insetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
        insetView.size = insetViewSize
        insetView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
        insetView.baseOffset = vec3((i - 1) * (insetViewSize.x + 20),0,0)


        local scrollView = uiScrollView:create(insetView, scrollViewSize, MJPositionInnerLeft)
        scrollView.baseOffset = vec3(0,0,2)
        
        insetViewInfos[i] = {
            insetView = insetView,
            scrollView = scrollView,
            sapienViewinfos = {}
        }
    end

    --main header
    local headerMainTitleViews = {}
    local mainHeaderIconHalfSize = 8
    local mainHeaderIconTitlePadding = 4
    local mainHeaderYOffset = 15.0

    -- sub header containing sort catagories
    local headerHeight = 20.0
    local headerStartXOffset = 5.0


    local function layoutView(viewInfoIndex, titleText, textColor,  iconName, iconMaterial)

        local insetViewInfo = insetViewInfos[viewInfoIndex]
        local insetView = insetViewInfo.insetView

        local tableViewInfo = tableViews[viewInfoIndex]
        local columnViewInfos = tableViewInfo.columnViewInfos
    
        --main header
        local mainTitleHeaderView = View.new(mainView)
        mainTitleHeaderView.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)
        mainTitleHeaderView.relativeView = insetView
        mainTitleHeaderView.baseOffset = vec3(0,mainHeaderYOffset + headerHeight,0)
    
        local iconView = ModelView.new(mainTitleHeaderView)
        iconView:setModel(model:modelIndexForName(iconName), {
            default = iconMaterial
        })
        iconView.scale3D = vec3(mainHeaderIconHalfSize,mainHeaderIconHalfSize,mainHeaderIconHalfSize)
        iconView.size = vec2(mainHeaderIconHalfSize) * 2.0
        iconView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    
        local thisTitleTextView = TextView.new(mainTitleHeaderView)
        thisTitleTextView.font = Font(uiCommon.fontName, 22)
        thisTitleTextView.color = textColor
        thisTitleTextView.text = titleText
        thisTitleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        thisTitleTextView.relativeView = iconView
        thisTitleTextView.baseOffset = vec3(mainHeaderIconTitlePadding,-1,0)
    
        mainTitleHeaderView.size = vec2(mainHeaderIconHalfSize * 2.0 + mainHeaderIconTitlePadding + thisTitleTextView.size.x, 20.0)

        headerMainTitleViews[viewInfoIndex] = mainTitleHeaderView

        
        -- sub header containing sort catagories
        
        local headerIndex = 1
        local headerXOffset = headerStartXOffset

        local function addTitle(columnLayoutInfo, columnViewInfo)
        
            local headerView = ColorView.new(mainView)
            columnViewInfo.headerView = headerView
            columnViewInfo.xOffset = headerXOffset
            headerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionAbove)
            headerView.relativeView = insetView
            headerView.baseOffset = vec3(headerXOffset,-4,1)
            headerView.color = vec4(0.5,0.5,0.5,0.1)

            
            headerView.hoverStart = function ()
                if not columnViewInfo.headerHover then
                    columnViewInfo.headerHover = true
                    headerView.color = vec4(mj.highlightColor.x,mj.highlightColor.y,mj.highlightColor.z,0.4)
                end
            end
        
            headerView.hoverEnd = function ()
                if columnViewInfo.headerHover then
                    columnViewInfo.headerHover = nil
                    headerView.color = vec4(0.5,0.5,0.5,0.1)
                end
            end

            headerView.mouseDown = function(buttonIndex)
                if buttonIndex == 0 then
                    headerView.color = vec4(mj.highlightColor.x,mj.highlightColor.y,mj.highlightColor.z,0.6)
                end
            end

            headerView.mouseUp = function(buttonIndex)
                if buttonIndex == 0 then
                    headerView.color = vec4(mj.highlightColor.x,mj.highlightColor.y,mj.highlightColor.z,0.4)
                end
            end
            

            local sortIconHalfSIze = 8
            local function addSortIcon()
                local sortIconView = ModelView.new(headerView)
                columnViewInfo.sortIconView = sortIconView
                if tableViewInfo.sortOrderFlipped then
                    sortIconView:setModel(model:modelIndexForName("icon_down"))
                else
                    sortIconView:setModel(model:modelIndexForName("icon_up"))
                end
                sortIconView.scale3D = vec3(sortIconHalfSIze,sortIconHalfSIze,sortIconHalfSIze)
                sortIconView.size = vec2(sortIconHalfSIze) * 2.0
                sortIconView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
                sortIconView.baseOffset = vec3(-2,0,0)
            end

            local function updateHeaderTitleVisibility()

                if columnLayoutInfo.width < 30.0 then --hack to not display the + behind on the leftmost row
                    columnViewInfo.headerTitleTextView.hidden = true
                else
                    columnViewInfo.headerTitleTextView.hidden = false
                end
            end
            
            headerView.click = function()
                local sortHeaderIndex = tableViewInfo.sortHeaderIndex
                if columnLayoutInfo.index == sortHeaderIndex then
                    if tableViewInfo.sortOrderFlipped then
                        tableViewInfo.sortOrderFlipped = false
                        columnViewInfo.sortIconView:setModel(model:modelIndexForName("icon_up"))
                    else
                        tableViewInfo.sortOrderFlipped = true
                        columnViewInfo.sortIconView:setModel(model:modelIndexForName("icon_down"))
                    end
                else
                    local currentColumnViewData = columnViewInfos[sortHeaderIndex]
                    currentColumnViewData.headerView:removeSubview(currentColumnViewData.sortIconView)
                    currentColumnViewData.sortIconView = nil
                    currentColumnViewData.headerTitleTextView.hidden = false

                    tableViewInfo.sortOrderFlipped = false
                    tableViewInfo.sortHeaderIndex = columnLayoutInfo.index
                    addSortIcon()
                end
                updateHeaderTitleVisibility()
                taskAssignUI:show(skillTypeIndex)
            end

            if headerIndex ~= 1 then
                local vertLineView = ColorView.new(mainView)
                vertLineView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionAbove)
                vertLineView.relativeView = insetView
                vertLineView.masksEvents = false
                vertLineView.baseOffset = vec3(headerXOffset,-4,4)
                vertLineView.size = vec2(2, 20.0)
                vertLineView.color = vec4(0.5,0.5,0.5,0.4)
            end

            if columnLayoutInfo.index == tableViewInfo.sortHeaderIndex then
                addSortIcon()
            end
        
        
            local headerTitleTextView = TextView.new(headerView)
            columnViewInfo.headerTitleTextView = headerTitleTextView
            headerTitleTextView.font = Font(uiCommon.fontName, 16)
            headerTitleTextView.color = mj.textColor
            headerTitleTextView.text = columnLayoutInfo.title
            headerTitleTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            headerTitleTextView.baseOffset = vec3(4,0,0)
        
            if headerXOffset + columnLayoutInfo.width > scrollViewSize.x then
                columnLayoutInfo.width = scrollViewSize.x - headerXOffset - 10
            end
            headerView.size = vec2(columnLayoutInfo.width, headerHeight)

            updateHeaderTitleVisibility()

            headerXOffset = headerXOffset + columnLayoutInfo.width
            headerIndex = headerIndex + 1

        end

        for i,columnLayoutInfo in ipairs(columns) do
            local columnViewInfo = {}
            columnViewInfos[i] = columnViewInfo
            addTitle(columnLayoutInfo, columnViewInfo)
        end
    end
    

    layoutView(1, locale:get("ui_roles_allowed"), vec4(0.5,1.0,0.5,1.0), "icon_tick", material.types.ui_green.index)
    layoutView(2, locale:get("ui_roles_disallowed"), vec4(1.0,0.5,0.5,1.0), "icon_cancel_thic", material.types.ui_red.index)


    ----------------------------------------------------------

    local moveAllButtonSize = 24.0
    local moveAllButtonA = uiStandardButton:create(mainView, vec2(moveAllButtonSize,moveAllButtonSize), uiStandardButton.types.slim_1x1)
    moveAllButtonA.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
    moveAllButtonA.relativeView = headerMainTitleViews[2]
    uiStandardButton:setIconModel(moveAllButtonA, "icon_doubleArrowLeft", {
        default = material.types.ui_green.index
    })
    moveAllButtonA.baseOffset = vec3(-10, -1, 0)
    uiStandardButton:setClickFunction(moveAllButtonA, function()
        playerSapiens:moveAllBetweenSkillPriorities(skillTypeIndex, 0, 1)
        taskAssignUI:show(skillTypeIndex)
    end)
    
    uiToolTip:add(moveAllButtonA.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_allowAll"), nil, vec3(0,-8,10), nil, moveAllButtonA, mainView)

    
    local moveAllButtonB = uiStandardButton:create(mainView, vec2(moveAllButtonSize,moveAllButtonSize), uiStandardButton.types.slim_1x1)
    moveAllButtonB.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    moveAllButtonB.relativeView = headerMainTitleViews[1]
    uiStandardButton:setIconModel(moveAllButtonB, "icon_doubleArrowRight", {
        default = material.types.ui_red.index
    })
    moveAllButtonB.baseOffset = vec3(10, -1, 0)
    uiStandardButton:setClickFunction(moveAllButtonB, function()
        playerSapiens:moveAllBetweenSkillPriorities(skillTypeIndex, 1, 0)
        taskAssignUI:show(skillTypeIndex)
    end)

    uiToolTip:add(moveAllButtonB.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_disallowAll"), nil, vec3(0,-8,10), nil, moveAllButtonB, mainView)

end


function taskAssignUI:show(skillTypeIndex_, prevSelectedPriority, prevSelectedScrollIndex)
    skillTypeIndex = skillTypeIndex_

    for i=1,2 do
        uiScrollView:removeAllRows(insetViewInfos[i].scrollView)
        insetViewInfos[i].sapienViewinfos = {}
    end

    local distanceOrderedSapiens = playerSapiens:getDistanceOrderedSapienList(localPlayer:getNormalModePos())
    local orderedSapienInfosByList = {{},{}}
    local uiInfosBySapienID = {}
    for i,sapienInfo in ipairs(distanceOrderedSapiens) do
        uiInfosBySapienID[sapienInfo.sapien.uniqueID] = {
            limitedAbility = skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility and sapienConstants:getHasLimitedGeneralAbility(sapienInfo.sapien.sharedState)
        }
        
        local priority = skill:priorityLevel(sapienInfo.sapien, skillTypeIndex)
        local addIndex = 2
        if priority == 1 then
            addIndex = 1
        end
        table.insert(orderedSapienInfosByList[addIndex], sapienInfo)
    end

    local function sortList(listIndex)

        local ordered = orderedSapienInfosByList[listIndex]
        local tableViewInfo = tableViews[listIndex]
        local sortHeaderIndex = tableViewInfo.sortHeaderIndex
        local sortOrderFlipped = tableViewInfo.sortOrderFlipped

        if sortHeaderIndex == columns.traits.index then
            local function sort(a,b)
                local function getHeuristic(info)
                    local sapien = info.sapien
                    local uiInfo = uiInfosBySapienID[sapien.uniqueID]
                    local heuristic = 0
                    
                    if uiInfo.limitedAbility then
                        heuristic = heuristic - 5000
                    end
                    
                    if skill:learnStarted(sapien, skillTypeIndex) then
                        heuristic = heuristic + 100
                        if skill:hasSkill(sapien, skillTypeIndex) then
                            heuristic = heuristic + 100
                        else
                            heuristic = heuristic + 100 * skill:fractionLearned(sapien, skillTypeIndex)
                        end
                    end
                    
                    local traitInfluence = sapienTrait:getSkillInfluence(sapien.sharedState.traits, skillTypeIndex)
                    heuristic = heuristic + traitInfluence * 20000000.0

                    return heuristic
                end

                local heuristicA = getHeuristic(a)
                local heuristicB = getHeuristic(b)

                if heuristicA == heuristicB then
                    return a.sapien.sharedState.name < b.sapien.sharedState.name
                end
                
                return heuristicA > heuristicB
            end

            local function sortReverse(a,b)
                return sort(b,a)
            end
            if sortOrderFlipped then
                table.sort(ordered, sortReverse)
            else
                table.sort(ordered, sort)
            end

        elseif sortHeaderIndex == columns.sapien.index then
            local function sort(a,b)
                return a.sapien.sharedState.name < b.sapien.sharedState.name
            end

            local function sortReverse(a,b)
                return sort(b,a)
            end
            if sortOrderFlipped then
                table.sort(ordered, sortReverse)
            else
                table.sort(ordered, sort)
            end
        elseif sortHeaderIndex == columns.distance.index then
            if sortOrderFlipped then
                local newOrdered = {}
                local insertIndex = 1
                for i = #ordered,1,-1 do
                    newOrdered[insertIndex] = ordered[i]
                    insertIndex = insertIndex + 1
                end
                orderedSapienInfosByList[listIndex] = newOrdered
            end
        elseif sortHeaderIndex == columns.age.index then
            local function sort(a,b)
                return sapienConstants:getAgeValue(a.sapien.sharedState) < sapienConstants:getAgeValue(b.sapien.sharedState)
            end
            local function sortReverse(a,b)
                return sapienConstants:getAgeValue(a.sapien.sharedState) > sapienConstants:getAgeValue(b.sapien.sharedState)
            end
            if sortOrderFlipped then
                table.sort(ordered, sortReverse)
            else
                table.sort(ordered, sort)
            end
        elseif sortHeaderIndex == columns.roles.index then

            local function sort(a,b)
                local countA = skill:getAssignedRolesCount(a.sapien)
                local countB = skill:getAssignedRolesCount(b.sapien)

                if countA == countB then
                    for i, skillType in ipairs(skill.validTypes) do
                        local prirorityLevelA = skill:priorityLevel(a.sapien, skillType.index)
                        local prirorityLevelB = skill:priorityLevel(b.sapien, skillType.index)
                        if prirorityLevelA ~= prirorityLevelB then
                            if prirorityLevelA == 1 then
                                return true
                            else
                                return false
                            end
                        end
                    end
                end

                return countA > countB
            end

            local function sortReverse(a,b)
                return sort(b,a)
            end
            if sortOrderFlipped then
                table.sort(ordered, sortReverse)
            else
                table.sort(ordered, sort)
            end
        end
    end

    sortList(1)
    sortList(2)
    
    local sapienViewHeight = 30.0
    local sapienIconSize = sapienViewHeight - 4.0
    local buttonSize = sapienViewHeight - 2.0

    local iconModelNamesByPriority = {
        [1] = "icon_tick", 
        [0] = "icon_cancel_thic",
    }
    local iconMaterialsByPriority = {
        [1] = material.types.ui_green.index,
        [0] = material.types.ui_red.index
    }

    local function insertRow(sapienInfo, listIndex)
        local sapien = sapienInfo.sapien

        local uiInfo = uiInfosBySapienID[sapien.uniqueID]
        local limitedAbility = uiInfo.limitedAbility

        local scrollView = insetViewInfos[listIndex].scrollView

        local sapienView = ColorView.new(scrollView)
        local backgroundColor = vec4(0.0,0.0,0.0,0.5)
        if #insetViewInfos[listIndex].sapienViewinfos % 2 == 1 then
            backgroundColor = vec4(0.03,0.03,0.03,0.5)
        end
        

        local insertIndex = #insetViewInfos[listIndex].sapienViewinfos + 1

        

        sapienView.color = backgroundColor
        sapienView.size = vec2(scrollView.size.x - 20, sapienViewHeight)
        sapienView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        
        uiScrollView:insertRow(scrollView, sapienView, nil)
        local sapienViewinfo = {
            sapienView = sapienView
        }

        insetViewInfos[listIndex].sapienViewinfos[insertIndex] = sapienViewinfo


        local function otherPriorityFromThisPriority()
            if listIndex == 1 then
                return 0
            end
            return 1
        end

        local otherPriority = otherPriorityFromThisPriority()


        local moveButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
        moveButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
        moveButton.hidden = true
        moveButton.baseOffset = vec3(0,0,1)
        uiStandardButton:setIconModel(moveButton, iconModelNamesByPriority[otherPriority], {
            default = iconMaterialsByPriority[otherPriority]
        })
        uiStandardButton:setClickFunction(moveButton, function()
            playerSapiens:setSkillPriority(sapien.uniqueID, skillTypeIndex, otherPriority)
            if otherPriority == 1 then
                tutorialUI:roleAssignmentWasIssued()
            end
            taskAssignUI:show(skillTypeIndex, listIndex, insertIndex)
        end)

        local moveText = nil
        if listIndex == 1 then
            moveText = locale:get("ui_action_disallow")
        else
            moveText = locale:get("ui_action_allow")
        end
        uiToolTip:add(moveButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), moveText, nil, vec3(0,-8,10), nil, moveButton, mainView)

        
        local configureButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
        configureButton.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
        configureButton.relativeView = moveButton
        configureButton.hidden = true
        uiStandardButton:setIconModel(configureButton, "icon_configure")
        uiStandardButton:setClickFunction(configureButton, function()
            gameUI:showTasksMenuForSapienFromTribeTaskAssignUI(sapien, function()
                manageUI:show(manageUI.modeTypes.task)
                roleUI:selectTask(skillTypeIndex)
            end)
        end)
        uiToolTip:add(configureButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_manageRoles"), nil, vec3(0,-8,10), nil, configureButton, mainView)

        local zoomButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
        zoomButton.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
        zoomButton.relativeView = configureButton
        zoomButton.hidden = true
        uiStandardButton:setIconModel(zoomButton, "icon_inspect")
        uiStandardButton:setClickFunction(zoomButton, function()
            manageUI:hide()
            gameUI:followObject(sapien, false, {dismissAnyUI = true, stopWhenClose = true})
            hubUI:setLookAtInfo(sapien, false, false)
            hubUI:showInspectUI(sapien, nil, false)
        end)
        uiToolTip:add(zoomButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_zoom"), nil, vec3(0,-8,10), nil, zoomButton, mainView)

        --local rightButton = addButton(2, MJPositionInnerRight, sapienView)
       -- local leftButton = addButton(1, MJPositionOuterLeft, rightButton)
        
        local objectImageView = GameObjectView.new(sapienView, vec2(sapienIconSize, sapienIconSize))
        objectImageView.size = vec2(sapienIconSize, sapienIconSize)
        objectImageView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        --objectImageView.relativeView = rightButton
        --objectImageView.baseOffset = vec3(4,0,0)
        objectImageView.baseOffset = vec3(columns.traits.width,0,1)
        
        local animationInstance = uiAnimation:getUIAnimationInstance(sapienConstants:getAnimationGroupKey(sapien.sharedState))
        uiCommon:setGameObjectViewObject(objectImageView, sapien, animationInstance)

        local hasSkill = false
        local fractionLearned = 0.0

        if skill:learnStarted(sapien, skillTypeIndex) then
            local skillAchievementIcon = ModelView.new(sapienView)
            skillAchievementIcon.masksEvents = false
            skillAchievementIcon.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
            skillAchievementIcon.relativeView = objectImageView
           -- skillAchievementIcon.baseOffset = vec3(18,6,0)
            skillAchievementIcon.baseOffset = vec3(-22,6,0)
            
            if skill:hasSkill(sapien, skillTypeIndex) then
                hasSkill = true
                local skillAchievementIconHalfSize = 7
                skillAchievementIcon.scale3D = vec3(skillAchievementIconHalfSize,skillAchievementIconHalfSize,skillAchievementIconHalfSize)
                skillAchievementIcon.size = vec2(skillAchievementIconHalfSize,skillAchievementIconHalfSize) * 2.0
                fractionLearned = 1.0

                skillAchievementIcon:setModel(model:modelIndexForName("icon_achievement"), {
                    default = material.types.ui_selected.index,
                })
            else
                local skillAchievementIconHalfSize = 5
                skillAchievementIcon.scale3D = vec3(skillAchievementIconHalfSize,skillAchievementIconHalfSize,skillAchievementIconHalfSize)
                skillAchievementIcon.size = vec2(skillAchievementIconHalfSize,skillAchievementIconHalfSize) * 2.0

                skillAchievementIcon:setModel(model:modelIndexForName("icon_circle_filled"), {
                    default = material.types.ui_disabled.index
                })
                
                local skillAchievementProgressIcon = ModelView.new(sapienView)
                skillAchievementProgressIcon.masksEvents = false
                skillAchievementProgressIcon.relativeView = skillAchievementIcon
                skillAchievementProgressIcon.baseOffset = vec3(0, 0, 2)
                skillAchievementProgressIcon.scale3D = vec3(skillAchievementIconHalfSize,skillAchievementIconHalfSize,skillAchievementIconHalfSize)
                skillAchievementProgressIcon.size = vec2(skillAchievementIconHalfSize,skillAchievementIconHalfSize) * 2.0

                skillAchievementProgressIcon:setModel(model:modelIndexForName("icon_circle_thic"), {
                    default = material.types.ui_selected.index
                })
                fractionLearned = skill:fractionLearned(sapien, skillTypeIndex)
                skillAchievementProgressIcon:setRadialMaskFraction(fractionLearned)

                
                --[[local skillAchievementMiniIcon = ModelView.new(backgroundView)
                skillAchievementMiniIcon.masksEvents = false
                skillAchievementMiniIcon.relativeView = skillAchievementIcon
                local skillAchievementMiniIconHalfSize = 4
                skillAchievementMiniIcon.scale3D = vec3(skillAchievementMiniIconHalfSize,skillAchievementMiniIconHalfSize,skillAchievementMiniIconHalfSize)
                skillAchievementMiniIcon.size = vec2(skillAchievementMiniIconHalfSize,skillAchievementMiniIconHalfSize) * 2.0
                skillAchievementMiniIcon:setModel(model:modelIndexForName("icon_achievement"), nil, nil, function(materialIndexToRemap)
                    return material.types.ui_standard.index 
                end)]]
            end
        end 

        local traitInfluenceInfo = sapienTrait:getSkillInfluenceWithTraitsList(sapien.sharedState.traits, skillTypeIndex)
        if traitInfluenceInfo.influence ~= 0 then
            local traitText = nil
            local color = nil
            if traitInfluenceInfo.influence > 0 then
                if traitInfluenceInfo.influence > 1.1 then
                    traitText = "++"
                    color = vec4(0.4,0.8,0.4,1.0)
                else
                    traitText = "+"
                    color = vec4(0.4,0.8,0.4,1.0)
                end
            else
                if traitInfluenceInfo.influence < -1.1 then
                    traitText = "--"
                    color = vec4(0.8,0.4,0.4,1.0)
                else
                    traitText = "-"
                    color = vec4(0.8,0.4,0.4,1.0)
                end
            end
            local traitInfluenceTextView = TextView.new(sapienView)
            traitInfluenceTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
            traitInfluenceTextView.relativeView = objectImageView
            traitInfluenceTextView.baseOffset = vec3(-22,-8,0)
            traitInfluenceTextView.font = Font(uiCommon.fontName, 14)
            traitInfluenceTextView.color = color
            traitInfluenceTextView.text = traitText
        end


        local nameTextView = TextView.new(sapienView)
        nameTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        nameTextView.relativeView = objectImageView
        nameTextView.masksEvents = false
        nameTextView.baseOffset = vec3(4,0,1)
        nameTextView.font = Font(uiCommon.fontName, 16)

        
        local distanceTextView = TextView.new(sapienView)
        distanceTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        distanceTextView.baseOffset = vec3(tableViews[listIndex].columnViewInfos[columns.distance.index].xOffset,0,1)
        distanceTextView.font = Font(uiCommon.fontName, 16)
        distanceTextView.color = vec4(1.0,1.0,1.0,1.0)
        local distanceMeters = math.floor(mj:pToM(math.sqrt(sapienInfo.d2)))
        distanceTextView.text = string.format("%d m", distanceMeters)

        
        local ageTextView = TextView.new(sapienView)
        ageTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        ageTextView.baseOffset = vec3(tableViews[listIndex].columnViewInfos[columns.age.index].xOffset,0,1)
        ageTextView.font = Font(uiCommon.fontName, 16)
        ageTextView.color = vec4(1.0,1.0,1.0,1.0)
        ageTextView.text = math.floor(sapienConstants:getAgeValue(sapien.sharedState)) + 5

        local function getLimitedAbilityReasonInfo()
            local reason = {}
            if limitedAbility then
                local sharedState = sapien.sharedState
                if sharedState.pregnant then
                    reason.pregnant = true
                elseif sharedState.hasBaby then
                    reason.hasBaby = true
                elseif sharedState.lifeStageIndex == sapienConstants.lifeStages.child.index then
                    reason.child = true
                elseif sharedState.lifeStageIndex == sapienConstants.lifeStages.elder.index then
                    reason.elder = true
                end
            else
                reason.maxAssigned = true
            end
            return reason
        end

        local limitedAbilityReasonInfo = nil

        if limitedAbility then
            limitedAbilityReasonInfo = getLimitedAbilityReasonInfo()
            nameTextView.color = material:getUIColor(material.types.warning.index)
        else
            nameTextView.color = vec4(1.0,1.0,1.0,1.0)
        end

        nameTextView.text = sapien.sharedState.name

        
        if limitedAbilityReasonInfo or #traitInfluenceInfo.positiveTraits > 0 or #traitInfluenceInfo.negativeTraits > 0 or hasSkill or fractionLearned > 0.01 then
            local tipView = View.new(sapienView)
            tipView.masksEvents = true
            tipView.size = objectImageView.size + vec2(200.0,0)
            tipView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            tipView.relativeView = objectImageView
            tipView.baseOffset = vec3(-10,0,0)
            uiToolTip:add(tipView, ViewPosition(MJPositionInnerLeft, MJPositionBelow), "", nil, vec3(20,-8,10), nil, tipView, mainView)

            if hasSkill or fractionLearned > 0.01 then
                local traitText = nil
                if hasSkill then
                    traitText = locale:get("misc_skilled")
                else
                    traitText = string.format("%d%%", math.floor(fractionLearned * 100))
                end
                if #traitInfluenceInfo.positiveTraits > 0 or #traitInfluenceInfo.negativeTraits > 0 then
                    traitText = traitText .. ", "
                end
                uiToolTip:addColoredTitleText(tipView, traitText, mj.highlightColor)
            end

            for i, traitInfo in ipairs(traitInfluenceInfo.positiveTraits) do
                local traitType = sapienTrait.types[traitInfo.traitTypeIndex]
                local traitText = nil
                if traitInfo.opposite then
                    traitText = traitType.opposite
                else
                    traitText = traitType.name
                end
                if i < #traitInfluenceInfo.positiveTraits or #traitInfluenceInfo.negativeTraits > 0 then
                    traitText = traitText .. ", "
                end
                uiToolTip:addColoredTitleText(tipView, traitText, vec4(0.4,0.8,0.4,1.0))
            end
            for i, traitInfo in ipairs(traitInfluenceInfo.negativeTraits) do
                local traitType = sapienTrait.types[traitInfo.traitTypeIndex]
                local traitText = nil
                if traitInfo.opposite then
                    traitText = traitType.opposite
                else
                    traitText = traitType.name
                end
                if i < #traitInfluenceInfo.negativeTraits then
                    traitText = traitText .. ", "
                end
                uiToolTip:addColoredTitleText(tipView, traitText, vec4(0.8,0.4,0.4,1.0))
            end

            if limitedAbilityReasonInfo then
                local warningString = nil
                if limitedAbility and skill.types[skillTypeIndex].partialCapacityWithLimitedGeneralAbility then
                    warningString = locale:get("ui_partiallyCantDoTasks", limitedAbilityReasonInfo)
                else
                    warningString = locale:get("ui_cantDoTasks", limitedAbilityReasonInfo)
                end

                uiToolTip:addColoredTitleText(tipView, " (" .. warningString .. ")" , material:getUIColor(material.types.warning.index))
            end
        end

        sapienView.hoverStart = function ()
            if not sapienViewinfo.hover then
                sapienViewinfo.hover = true
                sapienView.color = vec4(mj.highlightColor.x * 0.3,mj.highlightColor.y * 0.3,mj.highlightColor.z * 0.3,0.5)
                moveButton.hidden = false
                configureButton.hidden = false
                zoomButton.hidden = false
                sapienView.alpha = 1.0
                --audio:playUISound(uiCommon.hoverSoundFile)
            end
        end
    
        sapienView.hoverEnd = function ()
            if sapienViewinfo.hover then
               -- mj:log("hover end:", buttonTable.view)
               sapienViewinfo.hover = false
               sapienView.color = backgroundColor
               moveButton.hidden = true
               configureButton.hidden = true
               zoomButton.hidden = true
                if sapienViewinfo.maxRolesReached then
                    sapienView.alpha = 0.4
                end
            end
        end

        if prevSelectedPriority and prevSelectedPriority == listIndex then
            if prevSelectedScrollIndex == insertIndex then
                sapienView.hoverStart()
            end
        end

        local iconXOffset = tableViews[listIndex].columnViewInfos[columns.roles.index].xOffset
        local skillIconHalfSize = 10

        local iconInfos = {}

        for i,otherSkillType in ipairs(skill.validTypes) do
            local otherSkillTypeIndex = otherSkillType.index
            local otherPriorityLevel = skill:priorityLevel(sapien, otherSkillTypeIndex)
            if otherPriorityLevel == 1 then
                local iconBackgroundView = View.new(sapienView)
                iconBackgroundView.masksEvents = true
                iconBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                iconBackgroundView.baseOffset = vec3(iconXOffset, 0, 2)
                iconBackgroundView.size = vec2(skillIconHalfSize,skillIconHalfSize) * 2.0

                local icon = ModelView.new(iconBackgroundView)
                icon.masksEvents = false
                icon.scale3D = vec3(skillIconHalfSize,skillIconHalfSize,skillIconHalfSize)
                icon.size = iconBackgroundView.size
                
                local hasOtherSkill = skill:hasSkill(sapien, otherSkillTypeIndex)

                if otherSkillTypeIndex == skillTypeIndex then
                    --[[if limitedAbility then
                        icon:setModel(model:modelIndexForName(skill.types[otherSkillTypeIndex].icon), {
                            default = material.types.warning.index
                        })
                    else]]
                        icon:setModel(model:modelIndexForName(skill.types[otherSkillTypeIndex].icon), {
                            default = material.types.ui_green.index
                        })
                    --end
                else
                    if hasOtherSkill then
                        icon:setModel(model:modelIndexForName(skill.types[otherSkillTypeIndex].icon), {
                            default = material.types.ui_selected.index
                        })
                    else
                        icon:setModel(model:modelIndexForName(skill.types[otherSkillTypeIndex].icon))
                    end
                end
                iconXOffset = iconXOffset + icon.size.x + 2

                local iconInfo =  {
                    skillTypeIndex = otherSkillTypeIndex,
                    icon = icon
                }
                table.insert(iconInfos, iconInfo)


                iconBackgroundView.click = function()
                    playerSapiens:setSkillPriority(sapien.uniqueID, otherSkillTypeIndex, 0)
                    taskAssignUI:show(skillTypeIndex)
                end
                
                
                iconBackgroundView.hoverStart = function ()
                    if not iconInfo.cancelIcon then
                        local cancelIcon = ModelView.new(iconBackgroundView)
                        iconInfo.cancelIcon = cancelIcon
                        cancelIcon.masksEvents = false
                        cancelIcon:setModel(model:modelIndexForName("icon_cancel_thic"))
                        cancelIcon.scale3D = icon.scale3D
                        cancelIcon.size = icon.size
                        cancelIcon.baseOffset = vec3(0,0,2)
                    end
                end
        
                iconBackgroundView.hoverEnd = function ()
                    if iconInfo.cancelIcon then
                        iconBackgroundView:removeSubview(iconInfo.cancelIcon)
                        iconInfo.cancelIcon = nil
                    end
                end

                --[[

        local secondaryIcon = ModelView.new(buttonView)
        secondaryIcon.masksEvents = false

        local logoHalfSize = buttonTable.iconHalfSize
        local iconYOffset = 0.0

        if buttonTable.type == uiStandardButton.types.orderMarker then
            if not buttonTable.orderMarkerCanCompleteState then
                logoHalfSize = logoHalfSize * orderMarkerWarningIconScale
                iconYOffset = buttonTable.currentHalfSize * orderMarkerWarningIconYOffset
            end
        end

        if backgroundMaterialRemapTableOrNil then
            secondaryIcon:setModel(model:modelIndexForName(modelName), backgroundMaterialRemapTableOrNil)
        else
            secondaryIcon:setModel(model:modelIndexForName(modelName))
        end
        
        secondaryIcon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
        secondaryIcon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
        secondaryIcon.baseOffset = vec3(0,iconYOffset * 1.5,iconZOffsetMultiplier * logoHalfSize * 1.5)
                ]]

                
                --[[uiStandardButton:setSecondaryHoverIconModel(cancelButton, "icon_cancel", {
                    default = material.types.red.index
                })]]

                if hasOtherSkill then
                    uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), "", nil, vec3(0,-8,10), nil, iconBackgroundView, mainView)
                    uiToolTip:addColoredTitleText(iconBackgroundView, otherSkillType.name .. " - " .. locale:get("misc_skilled"), mj.highlightColor)
                else
                    uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), otherSkillType.name, nil, vec3(0,-8,10), nil, iconBackgroundView, mainView)
                    local otherFractionLearned = skill:fractionLearned(sapien, otherSkillType.index)
                    if otherFractionLearned > 0.001 then
                        local traitText = string.format(" %d%%", math.floor(otherFractionLearned * 100))
                        uiToolTip:addColoredTitleText(iconBackgroundView, traitText, mj.highlightColor)
                    end
                end
            end
        end

        if listIndex == 2 then
            if #iconInfos >= skill.maxRoles then
                sapienViewinfo.maxRolesReached = true
                uiStandardButton:setDisabled(moveButton, true)
                --[[for i, iconInfo in ipairs(iconInfos) do
                    iconInfo.icon:setModel(model:modelIndexForName(skill.types[iconInfo.skillTypeIndex].icon), {
                        default = material.types.warning.index
                    })
                end]]
                
                uiStandardButton:setIconModel(moveButton, iconModelNamesByPriority[otherPriority], {
                    default = material.types.ui_disabled.index
                })
                local alpha = 0.4
                sapienView.alpha = alpha
            end
        end
    end

    
    for i,sapienInfo in ipairs(orderedSapienInfosByList[1]) do
        insertRow(sapienInfo, 1)
    end
    for i,sapienInfo in ipairs(orderedSapienInfosByList[2]) do
        insertRow(sapienInfo, 2)
    end

    --[[for i,sapienInfo in ipairs(ordered) do
        local priority = skill:priorityLevel(sapienInfo.sapien, skillTypeIndex)
        local addIndex = 2
        if priority == 1 then
            addIndex = 1
        end
        insertRow(sapienInfo, addIndex)
    end]]

    local function changeTitle(text, iconModelName)
        titleTextView:setText(text, material.types.standardText.index)
        titleIcon:setModel(model:modelIndexForName(iconModelName))
        titleView.size = vec2(titleTextView.size.x + iconHalfSize + iconHalfSize + iconPadding, titleView.size.y)
    end

    changeTitle(skill.types[skillTypeIndex].name, skill.types[skillTypeIndex].icon)

    mainView.hidden = false
end

function taskAssignUI:hide()
    mainView.hidden = true
end

return taskAssignUI