local mjm = mjrequire "common/mjm"
local vec4 = mjm.vec4
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local locale = mjrequire "common/locale"
local model = mjrequire "common/model"
local sapienConstants = mjrequire "common/sapienConstants"
local skill = mjrequire "common/skill"
local mood = mjrequire "common/mood"
local material = mjrequire "common/material"
local statusEffect = mjrequire "common/statusEffect"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local uiTribeView = mjrequire "mainThread/ui/uiCommon/uiTribeView"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"

local uiAnimation = mjrequire "mainThread/ui/uiAnimation"

local playerSapiens = mjrequire "mainThread/playerSapiens"
local localPlayer = mjrequire "mainThread/localPlayer"

local tribeUI = {}

local listView = nil
local gameUI = nil
local world = nil
local hubUI = nil
local manageUI = nil
local listPaneView = nil
local listScrollView = nil
local tribeSapiensRenderGameObjectView = nil

local tribeTitleTextView = nil
local populationTextView = nil

local columns = mj:indexed {
    {
        key = "sapien",
        title = locale:get("tribeUI_sapien"),
        width = 200.0
    },
    {
        key = "distance",
        title = locale:get("tribeUI_distance"),
        width = 60.0
    },
    {
        key = "age",
        title = locale:get("tribeUI_age"),
        width = 80.0
    },
    {
        key = "happiness",
        title = locale:get("tribeUI_happiness"),
        width = 80.0
    },
    {
        key = "loyalty",
        title = locale:get("tribeUI_loyalty"),
        width = 80.0
    },
    {
        key = "effects",
        title = locale:get("tribeUI_effects"),
        width = 128.0 -- 24 * 5 + padding of 5 on both left and right - line width
    },
    {
        key = "roles",
        title = locale:get("tribeUI_roles"),
        width = 160.0
    },
    {
        key = "skills",
        title = locale:get("tribeUI_skills"),
        width = 382.0
    },
}

local sortHeaderIndex = columns.sapien.index
local sortOrderFlipped = false

function tribeUI:init(gameUI_, world_, manageUI_, hubUI_, contentView)
    gameUI = gameUI_
    world = world_
    hubUI = hubUI_
    manageUI = manageUI_

    local tribeSapiensInsetViewHeight = 200

    listView = View.new(contentView)
    listView.size = vec2(contentView.size.x - 20, contentView.size.y - tribeSapiensInsetViewHeight - 40)
    listView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    listView.baseOffset = vec3(0,20,0)

    local tribeSapiensInsetViewSize = vec2(contentView.size.x - 20, tribeSapiensInsetViewHeight)
    local tribeSapiensInsetView = ModelView.new(contentView)
    tribeSapiensInsetView:setModel(model:modelIndexForName("ui_inset_lg_4x3"))
    local scaleToUseTribeViewX = tribeSapiensInsetViewSize.x * 0.5
    local scaleToUseTribeViewY = tribeSapiensInsetViewSize.y * 0.5 / 0.75
    tribeSapiensInsetView.scale3D = vec3(scaleToUseTribeViewX,scaleToUseTribeViewY,scaleToUseTribeViewX)
    tribeSapiensInsetView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    tribeSapiensInsetView.size = tribeSapiensInsetViewSize
    tribeSapiensInsetView.baseOffset = vec3(0,-10,0)

    local tribeSapiensRenderGameObjectViewSize = vec2(tribeSapiensInsetViewSize.x, tribeSapiensInsetViewSize.y - 20)
    tribeSapiensRenderGameObjectView = uiTribeView:create(tribeSapiensInsetView, tribeSapiensRenderGameObjectViewSize)


    local insetViewSize = vec2(listView.size.x, listView.size.y - 20)
    local scrollViewSize = vec2(insetViewSize.x - 8, insetViewSize.y - 4)

    listPaneView = ModelView.new(listView)
    listPaneView:setModel(model:modelIndexForName("ui_inset_lg_4x3"))
    local scaleToUsePaneX = insetViewSize.x * 0.5
    local scaleToUsePaneY = insetViewSize.y * 0.5 / 0.75
    listPaneView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    listPaneView.size = insetViewSize
    listPaneView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
    listPaneView.baseOffset = vec3(0,0,0)

    listScrollView = uiScrollView:create(listPaneView, scrollViewSize, MJPositionInnerLeft)
    listScrollView.baseOffset = vec3(0,4,4)


    tribeTitleTextView = ModelTextView.new(contentView)
    tribeTitleTextView.font = Font(uiCommon.titleFontName, 32)
    tribeTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    tribeTitleTextView.baseOffset = vec3(0,-12,0)

    populationTextView = TextView.new(contentView)
    populationTextView.font = Font(uiCommon.fontName, 16)
    populationTextView.color = mj.textColor
    populationTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    populationTextView.relativeView = tribeTitleTextView
    populationTextView.baseOffset = vec3(0,4,0)

    local tribeTitleTextEntry = nil
    local titleTextEntryEditButton = nil
    
    local textEntrySize = vec2(300.0,24.0)
    tribeTitleTextEntry = uiTextEntry:create(contentView, textEntrySize, uiTextEntry.types.standard_10x3, nil, locale:get("ui_action_editName"))
    uiTextEntry:setMaxChars(tribeTitleTextEntry, 40)
    tribeTitleTextEntry.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    tribeTitleTextEntry.baseOffset = vec3(0, -14, 0)
    uiTextEntry:setFunction(tribeTitleTextEntry, function(newValue)
        if newValue and string.len(newValue) > 0 then
            --changeRouteName(newValue)
            world:setTribeName(newValue)
            tribeTitleTextView:setText(locale:get("misc_tribeNameFormal", {tribeName = newValue}), material.types.standardText.index)
            titleTextEntryEditButton.hidden = false
            tribeTitleTextView.hidden = false
            tribeTitleTextEntry.hidden = true
        end
        --changeObjectName(newValue)
    end)
    tribeTitleTextEntry.hidden = true

    titleTextEntryEditButton = uiStandardButton:create(contentView, vec2(20,20), uiStandardButton.types.slim_1x1)
    titleTextEntryEditButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    titleTextEntryEditButton.baseOffset = vec3(10, -2, 0)
    titleTextEntryEditButton.relativeView = tribeTitleTextView
    --titleTextEntryEditButton.hidden = true
    uiStandardButton:setIconModel(titleTextEntryEditButton, "icon_edit")
    uiStandardButton:setClickFunction(titleTextEntryEditButton, function()
        titleTextEntryEditButton.hidden = true
        tribeTitleTextView.hidden = true
        uiTextEntry:setText(tribeTitleTextEntry, world:getTribeName())
        tribeTitleTextEntry.hidden = false
        uiTextEntry:callClickFunction(tribeTitleTextEntry)
    end)
    uiToolTip:add(titleTextEntryEditButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_editName"), nil, vec3(0,-8,10), nil, titleTextEntryEditButton)


    --[[



    ]]


    local headerStartXOffset = 2.0
    local headerXOffset = headerStartXOffset
    local headerHeight = 20.0
    local headerIndex = 1
    local function addTitle(info)
    
        local headerView = ColorView.new(listView)
        info.headerView = headerView
        headerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        headerView.baseOffset = vec3(headerXOffset,0,4)
        headerView.color = vec4(0.5,0.5,0.5,0.1)


        headerView.hoverStart = function ()
            if not info.headerHover then
                info.headerHover = true
                headerView.color = vec4(mj.highlightColor.x,mj.highlightColor.y,mj.highlightColor.z,0.4)
            end
        end
    
        headerView.hoverEnd = function ()
            if info.headerHover then
                info.headerHover = nil
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
            info.sortIconView = sortIconView
            if sortOrderFlipped then
                sortIconView:setModel(model:modelIndexForName("icon_down"))
            else
                sortIconView:setModel(model:modelIndexForName("icon_up"))
            end
            sortIconView.scale3D = vec3(sortIconHalfSIze,sortIconHalfSIze,sortIconHalfSIze)
            sortIconView.size = vec2(sortIconHalfSIze) * 2.0
            sortIconView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
            sortIconView.baseOffset = vec3(0,0,2)
        end

        
        headerView.click = function()
            if info.index == sortHeaderIndex then
                if sortOrderFlipped then
                    sortOrderFlipped = false
                    info.sortIconView:setModel(model:modelIndexForName("icon_up"))
                else
                    sortOrderFlipped = true
                    info.sortIconView:setModel(model:modelIndexForName("icon_down"))
                end
            else
                local currentHeaderInfo = columns[sortHeaderIndex]
                currentHeaderInfo.headerView:removeSubview(currentHeaderInfo.sortIconView)
                currentHeaderInfo.sortIconView = nil

                sortOrderFlipped = false
                sortHeaderIndex = info.index
                addSortIcon()
            end
            tribeUI:show()
        end

        info.xOffset = headerXOffset - headerStartXOffset + 5

        if headerIndex ~= 1 then
            local vertLineView = ColorView.new(listView)
            vertLineView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
            vertLineView.masksEvents = false
            vertLineView.baseOffset = vec3(headerXOffset,0,4)
            vertLineView.size = vec2(2, insetViewSize.y + 20.0)
            vertLineView.color = vec4(0.5,0.5,0.5,0.4)
        end

        if info.index == sortHeaderIndex then
            addSortIcon()
        end
    
        --[[local iconView = ModelView.new(headerView)
        iconView:setModel(model:modelIndexForName(iconName), {
            default = iconMaterial
        })
        iconView.scale3D = vec3(headerIconHalfSize,headerIconHalfSize,headerIconHalfSize)
        iconView.size = vec2(headerIconHalfSize) * 2.0
        iconView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)]]
    
        local titleTextView = TextView.new(headerView)
        titleTextView.font = Font(uiCommon.fontName, 16)
        titleTextView.color = mj.textColor
        titleTextView.text = info.title
        titleTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        titleTextView.baseOffset = vec3(4,0,0)
    
        if headerXOffset + info.width > scrollViewSize.x then
            info.width = scrollViewSize.x - headerXOffset - 10
        end
        headerView.size = vec2(info.width, headerHeight)
        headerXOffset = headerXOffset + info.width
        headerIndex = headerIndex + 1
    end

    for i,info in ipairs(columns) do
        addTitle(info)
    end

end

function tribeUI:update()
    
end

function tribeUI:show()
    

    uiScrollView:removeAllRows(listScrollView)

    tribeTitleTextView:setText(locale:get("misc_tribeNameFormal", {tribeName = world:getTribeName()}), material.types.standardText.index)
    
    populationTextView.text = locale:get("tribeUI_population") .. ": " .. mj:tostring(playerSapiens:getPopulationCountIncludingBabies())
    
    local distanceOrderedSapiens = playerSapiens:getDistanceOrderedSapienList(localPlayer:getNormalModePos())
    local ordered = distanceOrderedSapiens

    local sapiensByID = {}
    for i,orderedInfo in ipairs(distanceOrderedSapiens) do
        sapiensByID[orderedInfo.sapien.uniqueID] = orderedInfo.sapien
    end

    uiTribeView:setTribe(tribeSapiensRenderGameObjectView, world:getTribeID(), sapiensByID)

    if sortHeaderIndex == columns.distance.index then
        if sortOrderFlipped then
            ordered = {}
            local insertIndex = 1
            for i = #distanceOrderedSapiens,1,-1 do
                ordered[insertIndex] = distanceOrderedSapiens[i]
                insertIndex = insertIndex + 1
            end
        end
    elseif sortHeaderIndex == columns.sapien.index then
        local function sort(a,b)
            return a.sapien.sharedState.name < b.sapien.sharedState.name
        end
        local function sortReverse(a,b)
            return a.sapien.sharedState.name > b.sapien.sharedState.name
        end
        if sortOrderFlipped then
            table.sort(ordered, sortReverse)
        else
            table.sort(ordered, sort)
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
    elseif sortHeaderIndex == columns.happiness.index then
        local function sort(a,b)
            return mood:getRawMoodValue(a.sapien, mood.types.happySad.index) > mood:getRawMoodValue(b.sapien, mood.types.happySad.index)
        end
        local function sortReverse(a,b)
            return mood:getRawMoodValue(a.sapien, mood.types.happySad.index) < mood:getRawMoodValue(b.sapien, mood.types.happySad.index)
        end
        if sortOrderFlipped then
            table.sort(ordered, sortReverse)
        else
            table.sort(ordered, sort)
        end
    elseif sortHeaderIndex == columns.loyalty.index then
        local function sort(a,b)
            return mood:getRawMoodValue(a.sapien, mood.types.loyalty.index) > mood:getRawMoodValue(b.sapien, mood.types.loyalty.index)
        end
        local function sortReverse(a,b)
            return mood:getRawMoodValue(a.sapien, mood.types.loyalty.index) < mood:getRawMoodValue(b.sapien, mood.types.loyalty.index)
        end
        if sortOrderFlipped then
            table.sort(ordered, sortReverse)
        else
            table.sort(ordered, sort)
        end
    elseif sortHeaderIndex == columns.effects.index then
        local function getHeursitic(sapien, flipped)
            local incomingStatusEffects = sapien.sharedState.statusEffects
            local value = 0.0
            local positiveOffsetMultiplier = 1.0
            local negativeOffsetMultiplier = 1.0

            if flipped then
                negativeOffsetMultiplier = 1.01
            else
                positiveOffsetMultiplier = 1.01
            end

            for i,statusEffectTypeIndex in ipairs(statusEffect.orderedNegativeEffects) do -- critical negatives
                local statusEffectType = statusEffect.types[statusEffectTypeIndex]
                if statusEffectType.impact < -5 then
                    if incomingStatusEffects[statusEffectTypeIndex] then
                        value = value - 20000.0 * negativeOffsetMultiplier
                    end
                end
            end

            for i,statusEffectTypeIndex in ipairs(statusEffect.orderedNegativeEffects) do -- big negatives
                local statusEffectType = statusEffect.types[statusEffectTypeIndex]
                if statusEffectType.impact >= -5 and statusEffectType.impact < -1 then
                    if incomingStatusEffects[statusEffectTypeIndex] then
                        value = value - 200.0 * negativeOffsetMultiplier
                    end
                end
            end
            for i,statusEffectTypeIndex in ipairs(statusEffect.orderedPositiveEffects) do --all positives (big first)
                if incomingStatusEffects[statusEffectTypeIndex] then
                    local statusEffectType = statusEffect.types[statusEffectTypeIndex]
                    if statusEffectType.impact > 1 then
                        value = value + 200.0 * positiveOffsetMultiplier
                    else
                        value = value + 1 * positiveOffsetMultiplier
                    end
                end
            end
            for i,statusEffectTypeIndex in ipairs(statusEffect.orderedNegativeEffects) do -- non-big negatives
                if incomingStatusEffects[statusEffectTypeIndex] then
                    local statusEffectType = statusEffect.types[statusEffectTypeIndex]
                    if statusEffectType.impact == -1 then
                        value = value - 1 * negativeOffsetMultiplier
                    end
                end
            end
            return value
        end
        local function sort(a,b)
            return getHeursitic(a.sapien, false) > getHeursitic(b.sapien, false)
        end
        local function sortReverse(a,b)
            return getHeursitic(a.sapien, true) < getHeursitic(b.sapien, true)
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
    elseif sortHeaderIndex == columns.skills.index then
        local function sort(a,b)
            
            local heuristicA = skill:getSkilledHeuristic(a.sapien)
            local heuristicB = skill:getSkilledHeuristic(b.sapien)

            if heuristicA == heuristicB then
                for i, skillType in ipairs(skill.validTypes) do
                    local hasSkillA = skill:hasSkill(a.sapien, skillType.index)
                    local hasSkillB = skill:hasSkill(b.sapien, skillType.index)
                    if hasSkillA ~= hasSkillB then
                        if hasSkillA then
                            return true
                        else
                            return false
                        end
                    end
                end
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
    end
    

    local sapienViewinfos = {}

    local sapienViewHeight = 30.0
    local sapienIconSize = sapienViewHeight - 4.0
    --local buttonSize = sapienViewHeight - 2.0

    local function insertRow(sapienInfo)

        local sapien = sapienInfo.sapien

        local sapienView = ColorView.new(listScrollView)
        
        local backgroundColor = vec4(0.0,0.0,0.0,0.5)
        if #sapienViewinfos % 2 == 1 then
            backgroundColor = vec4(0.03,0.03,0.03,0.5)
        end

        local insertIndex = #sapienViewinfos + 1

        sapienView.color = backgroundColor
        sapienView.size = vec2(listScrollView.size.x - 20, sapienViewHeight)
        sapienView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        
        uiScrollView:insertRow(listScrollView, sapienView, nil)
        local sapienViewinfo = {
            sapienView = sapienView
        }

        sapienViewinfos[insertIndex] = sapienViewinfo
        
        local objectImageView = GameObjectView.new(sapienView, vec2(sapienIconSize, sapienIconSize))
        objectImageView.size = vec2(sapienIconSize, sapienIconSize)
        objectImageView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        --objectImageView.relativeView = rightButton
        --objectImageView.baseOffset = vec3(4,0,0)
        objectImageView.baseOffset = vec3(8,0,1)
        
        local animationInstance = uiAnimation:getUIAnimationInstance(sapienConstants:getAnimationGroupKey(sapien.sharedState))
        uiCommon:setGameObjectViewObject(objectImageView, sapien, animationInstance)

        local buttonSize = 30

        local nameTextView = TextView.new(sapienView)
        nameTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        nameTextView.relativeView = objectImageView
        nameTextView.baseOffset = vec3(4,0,1)
        nameTextView.font = Font(uiCommon.fontName, 16)
        nameTextView.color = vec4(1.0,1.0,1.0,1.0)
        nameTextView.text = sapien.sharedState.name

        local contextualButtons = {}
        
        local sapienZoomButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
        sapienZoomButton.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
        sapienZoomButton.baseOffset = vec3(columns[columns.sapien.index + 1].xOffset - 6, 0, 3)
        sapienZoomButton.hidden = true
        uiStandardButton:setIconModel(sapienZoomButton, "icon_inspect")
        uiStandardButton:setClickFunction(sapienZoomButton, function()
            manageUI:hide()
            gameUI:followObject(sapien, false, {dismissAnyUI = true, stopWhenClose = true})
            hubUI:setLookAtInfo(sapien, false, false)
            hubUI:showInspectUI(sapien, nil, false)
        end)
        table.insert(contextualButtons, sapienZoomButton)
        uiToolTip:add(sapienZoomButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_zoom"), nil, vec3(0,-8,10), nil, sapienZoomButton, listView)
        

        
        local ageTextView = TextView.new(sapienView)
        ageTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        ageTextView.baseOffset = vec3(4 + columns.age.xOffset,0,3)
        ageTextView.font = Font(uiCommon.fontName, 16)
        ageTextView.color = vec4(1.0,1.0,1.0,1.0)
        ageTextView.text = sapienConstants:getAgeDescription(sapien.sharedState)

        
        local skillIconHalfSize = 9
        local skillIconBackgroundHalfSize = 11

        local iconXOffset = columns.roles.xOffset
        for i,otherSkillType in ipairs(skill.validTypes) do
            local otherPriorityLevel = skill:priorityLevel(sapien, otherSkillType.index)
            if otherPriorityLevel == 1 then

                local iconBackgroundView = View.new(sapienView)
                iconBackgroundView.masksEvents = true
                iconBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                iconBackgroundView.baseOffset = vec3(iconXOffset, 0, 3)
                iconBackgroundView.size = vec2(skillIconHalfSize,skillIconHalfSize) * 2.0

                local icon = ModelView.new(iconBackgroundView)
                icon.masksEvents = false
                icon.scale3D = vec3(skillIconHalfSize,skillIconHalfSize,skillIconHalfSize)
                icon.size = iconBackgroundView.size
                
        
                local limitedAbility = nil
                local limitedAbilityIsPartial = false
                if skill.types[otherSkillType.index].noCapacityWithLimitedGeneralAbility or skill.types[otherSkillType.index].partialCapacityWithLimitedGeneralAbility then
                    if sapienConstants:getHasLimitedGeneralAbility(sapien.sharedState) then
                        limitedAbility = true
                        if not skill.types[otherSkillType.index].noCapacityWithLimitedGeneralAbility then
                            limitedAbilityIsPartial = true
                        end
                    end
                end
                
                if limitedAbility then
                    icon:setModel(model:modelIndexForName(skill.types[otherSkillType.index].icon), {
                        default = material.types.warning.index
                    })
                else
                    icon:setModel(model:modelIndexForName(skill.types[otherSkillType.index].icon))
                end

                
            
                local nameText = otherSkillType.name
                if limitedAbility then
                    local limitedAbilityText = skill:getLimitedAbilityReason(sapien.sharedState, limitedAbilityIsPartial)
                    uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), "", nil, vec3(0,-8,10), nil, iconBackgroundView, listView)
                    uiToolTip:addColoredTitleText(iconBackgroundView, nameText .. " - " .. limitedAbilityText, material:getUIColor(material.types.warning.index))
                else
                    uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), nameText, nil, vec3(0,-8,10), nil, iconBackgroundView, listView)
                end

                iconXOffset = iconXOffset + icon.size.x + 2
            end
        end
        

        local roleZoomButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
        roleZoomButton.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
        roleZoomButton.baseOffset = vec3(columns[columns.roles.index + 1].xOffset - 6, 0, 3)
        roleZoomButton.hidden = true
        uiStandardButton:setIconModel(roleZoomButton, "icon_configure")
        uiStandardButton:setClickFunction(roleZoomButton, function()
            gameUI:showTasksMenuForSapienFromTribeTaskAssignUI(sapien, function()
                manageUI:show(manageUI.modeTypes.tribe)
            end)
        end)
        table.insert(contextualButtons, roleZoomButton)
        uiToolTip:add(roleZoomButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_manageRoles"), nil, vec3(0,-8,10), nil, roleZoomButton, listView)

        local distanceTextView = TextView.new(sapienView)
        distanceTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        distanceTextView.baseOffset = vec3(columns.distance.xOffset,0,1)
        distanceTextView.font = Font(uiCommon.fontName, 16)
        distanceTextView.color = vec4(1.0,1.0,1.0,1.0)
        local distanceMeters = math.floor(mj:pToM(math.sqrt(sapienInfo.d2)))
        distanceTextView.text = string.format("%d m", distanceMeters)

        local function updateStarCount(moodTypeIndex, parentView)
            local newCount = mood:getStarCount(sapien, moodTypeIndex)
            local moodValue = mood:getMood(sapien, moodTypeIndex)

            --uiToolTip:updateText(parentView, mood.types[moodTypeIndex].name, mood.types[moodTypeIndex].descriptions[moodValue], false)



            local function updateModel(starIcon, starIndex)
                local modelName = "icon_star_inset"
                local materialIndex = "ui_background_inset"
                if newCount >= starIndex then
                    modelName = "icon_star"
                    materialIndex = mood.materials[moodValue]
                else
                    materialIndex = mood.uiBackgroundMaterials[moodValue]
                end
                starIcon:setModel(model:modelIndexForName(modelName), {
                    default = materialIndex
                })
            end

            local iconHalfSize = 6.0

            for i = 1,5 do
                local starIcon = ModelView.new(parentView)
                starIcon.masksEvents = false
                starIcon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
                starIcon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
                starIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                starIcon.baseOffset = vec3(2.0 + (i - 1) * 14.0, 0.0,0.0)
                updateModel(starIcon, i)
            end
        end

        local happyIconsView = View.new(sapienView)
        happyIconsView.size = vec2(columns.happiness.width, sapienViewHeight)
        happyIconsView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        happyIconsView.baseOffset = vec3(columns.happiness.xOffset,0,3)
        
        local loyaltyIconsView = View.new(sapienView)
        loyaltyIconsView.size = vec2(columns.loyalty.width, sapienViewHeight)
        loyaltyIconsView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        loyaltyIconsView.baseOffset = vec3(columns.loyalty.xOffset,0,3)
    
        updateStarCount(mood.types.happySad.index, happyIconsView)
        updateStarCount(mood.types.loyalty.index, loyaltyIconsView)

        local statusEffectsContainerView = View.new(sapienView)
        statusEffectsContainerView.size = vec2(columns.effects.width, sapienViewHeight)
        statusEffectsContainerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        statusEffectsContainerView.baseOffset = vec3(columns.effects.xOffset,0,3)

        local bigEffectCount = 0
        local smallEffectPositiveCount = 0
        local smallEffectNegativeCount = 0

        local hasSmallPositives = false
        local hasSmallNegatives = false
        
        local incomingStatusEffects = sapien.sharedState.statusEffects
        
        for statusEffectTypeIndex,v in pairs(incomingStatusEffects) do
            local statusEffectType = statusEffect.types[statusEffectTypeIndex]
            if statusEffectType.impact < 0 and statusEffectType.impact >= -1 then
                hasSmallNegatives = true
            elseif statusEffectType.impact > 0 and statusEffectType.impact <= 1 then
                hasSmallPositives = true
            end
        end

        local smallIconQuadSize = 12.0
        local bigIconQuadSize = 24.0
        
        local smallIconModelHalfSize = 5.5
        local bigIconModelHalfSize = 12.0

        local function addStatusEffectIcon(statusEffectType)

            local isBig = (statusEffectType.impact < -1 or statusEffectType.impact > 1)
            local isNegative = statusEffectType.impact < 0

            local xOffset = bigIconQuadSize * bigEffectCount
            local yOffset = 0.0

            local iconBackgroundHalfSize = smallIconModelHalfSize
            if isBig then
                iconBackgroundHalfSize = bigIconModelHalfSize
                yOffset = -2.0
            else
                if isNegative then
                    xOffset = xOffset + smallEffectNegativeCount * smallIconQuadSize
                    if hasSmallPositives then
                        yOffset = -3.0 - smallIconQuadSize
                    else
                        yOffset = -3.0 - smallIconQuadSize * 0.5
                    end
                else
                    xOffset = xOffset + smallEffectPositiveCount * smallIconQuadSize
                    
                    if hasSmallNegatives then
                        yOffset = -2.0
                    else
                        yOffset = -3.0 - smallIconQuadSize * 0.5
                    end
                end
            end

            if xOffset > bigIconQuadSize * 4.9 then
                return
            end
            
            yOffset = yOffset - 1.0

            local materialIndex = material.types.mood_severePositive.index
            if isNegative then
                if statusEffectType.impact < -5 then
                    materialIndex = material.types.mood_severeNegative.index
                else
                    materialIndex = material.types.mood_moderateNegative.index
                end
            end

            local iconBackgroundView = View.new(statusEffectsContainerView)
            iconBackgroundView.size = vec2(iconBackgroundHalfSize,iconBackgroundHalfSize) * 2.0
            iconBackgroundView.baseOffset = vec3(xOffset, yOffset, 0.001)
            iconBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
            iconBackgroundView.masksEvents = true

            

            local iconCircle = ModelView.new(iconBackgroundView)
            iconCircle.scale3D = vec3(iconBackgroundHalfSize,iconBackgroundHalfSize,iconBackgroundHalfSize)
            iconCircle.size = vec2(iconBackgroundHalfSize,iconBackgroundHalfSize) * 2.0
            --uiToolTip:add(iconCircle, ViewPosition(MJPositionCenter, MJPositionAbove), statusEffectType.name, statusEffectType.description, vec3(0,8,2), nil, nil)

            iconCircle:setModel(model:modelIndexForName("icon_circle"), {
                default = materialIndex
            })
            iconCircle.masksEvents = false

            local iconHalfSize = iconBackgroundHalfSize * 0.7
            local icon = ModelView.new(iconBackgroundView)
            icon.masksEvents = false
            icon.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
            icon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
            icon.size = vec2(iconHalfSize,iconHalfSize) * 2.0

            
            uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), "", nil, vec3(0,-8,10), nil, iconBackgroundView, listView)
            uiToolTip:addColoredTitleText(iconBackgroundView, statusEffectType.name, material:getUIColor(materialIndex))

            icon:setModel(model:modelIndexForName(statusEffectType.icon), {
                default = materialIndex
            })

            if isBig then
                bigEffectCount = bigEffectCount + 1
            else
                if isNegative then
                    smallEffectNegativeCount = smallEffectNegativeCount + 1
                else 
                    smallEffectPositiveCount = smallEffectPositiveCount + 1
                end
            end
        end

        for i,statusEffectTypeIndex in ipairs(statusEffect.orderedNegativeEffects) do -- critical negatives
            local statusEffectType = statusEffect.types[statusEffectTypeIndex]
            if statusEffectType.impact < -5 then
                if incomingStatusEffects[statusEffectTypeIndex] then
                    addStatusEffectIcon(statusEffectType)
                end
            end
        end

        for i,statusEffectTypeIndex in ipairs(statusEffect.orderedNegativeEffects) do -- big negatives
            local statusEffectType = statusEffect.types[statusEffectTypeIndex]
            if statusEffectType.impact >= -5 and statusEffectType.impact < -1 then
                if incomingStatusEffects[statusEffectTypeIndex] then
                    addStatusEffectIcon(statusEffectType)
                end
            end
        end
        for i,statusEffectTypeIndex in ipairs(statusEffect.orderedPositiveEffects) do --all positives (big first)
            if incomingStatusEffects[statusEffectTypeIndex] then
                local statusEffectType = statusEffect.types[statusEffectTypeIndex]
                addStatusEffectIcon(statusEffectType)
            end
        end
        for i,statusEffectTypeIndex in ipairs(statusEffect.orderedNegativeEffects) do -- non-big negatives
            if incomingStatusEffects[statusEffectTypeIndex] then
                local statusEffectType = statusEffect.types[statusEffectTypeIndex]
                if statusEffectType.impact == -1 then
                    addStatusEffectIcon(statusEffectType)
                end
            end
        end

        if bigEffectCount == 0 and (smallEffectPositiveCount == 0 or smallEffectNegativeCount == 0) then
            statusEffectsContainerView.size = vec2(statusEffectsContainerView.size.x, 20.0)
        else
            statusEffectsContainerView.size = vec2(statusEffectsContainerView.size.x, 40.0)
        end

        local skillsIconXOffset = columns.skills.xOffset
        local addedCount = 0
        local function addSkillIcon(skillTypeIndex, hasSkill, fractionLearned)

            if addedCount >= 12 then
                return
            end
            
            local iconMaterial = material.types.ui_standard.index
            local alpha = 1.0
            if hasSkill then
                iconMaterial = material.types.ui_selected.index
            else
                alpha = 0.5
                local skillAchievementProgressIcon = ModelView.new(sapienView)
                skillAchievementProgressIcon.masksEvents = false
                skillAchievementProgressIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                skillAchievementProgressIcon.baseOffset = vec3(skillsIconXOffset - (skillIconBackgroundHalfSize - skillIconHalfSize), 0, 3)
                skillAchievementProgressIcon.scale3D = vec3(skillIconBackgroundHalfSize,skillIconBackgroundHalfSize,skillIconBackgroundHalfSize)
                skillAchievementProgressIcon.size = vec2(skillIconBackgroundHalfSize,skillIconBackgroundHalfSize) * 2.0
                skillAchievementProgressIcon.alpha = 0.7

                skillAchievementProgressIcon:setModel(model:modelIndexForName("icon_circle_thic"), {
                    default = material.types.ui_selected.index
                })
                --mj:log("fraction:", skill:fractionLearned(sapien, skillTypeIndex))
                skillAchievementProgressIcon:setRadialMaskFraction(fractionLearned)
            end

            local iconBackgroundView = View.new(sapienView)
            iconBackgroundView.masksEvents = true
            iconBackgroundView.size = vec2(skillIconHalfSize,skillIconHalfSize) * 2.0
            iconBackgroundView.baseOffset = vec3(skillsIconXOffset, 0, 4)
            iconBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            
            local icon = ModelView.new(iconBackgroundView)
            icon.masksEvents = false
            icon.scale3D = vec3(skillIconHalfSize,skillIconHalfSize,skillIconHalfSize)
            icon.size = iconBackgroundView.size
            icon.alpha = alpha
            icon:setModel(model:modelIndexForName(skill.types[skillTypeIndex].icon), {
                default = iconMaterial
            })
            skillsIconXOffset = skillsIconXOffset + icon.size.x + 2
            addedCount = addedCount + 1
            
            local nameText = skill.types[skillTypeIndex].name
            if hasSkill then
                uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), "", nil, vec3(0,-8,10), nil, iconBackgroundView, listView)
                uiToolTip:addColoredTitleText(iconBackgroundView, nameText, material:getUIColor(material.types.ui_selected.index))
            else
                local percentageLerned = math.floor(fractionLearned * 100)
                uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), nameText, nil, vec3(0,-8,10), nil, iconBackgroundView, listView)
                uiToolTip:addColoredTitleText(iconBackgroundView, string.format(" %d%%", percentageLerned), material:getUIColor(material.types.ui_selected.index))
            end
        end
        
        local partialSkills = {}
        for i,skillType in ipairs(skill.validTypes) do
            local skillTypeIndex = skillType.index
            if not skill.defaultSkills[skillTypeIndex] and skill:learnStarted(sapien, skillTypeIndex) then
                local hasSkill = skill:hasSkill(sapien, skillTypeIndex)
                if hasSkill then
                    addSkillIcon(skillTypeIndex, true, 1.0)
                else
                    table.insert(partialSkills, {
                        skillTypeIndex = skillTypeIndex,
                        fractionLearned = skill:fractionLearned(sapien, skillTypeIndex),
                    })
                end
            end
        end

        local function sortPartialSkills(a, b)
            return a.fractionLearned > b.fractionLearned
        end

        table.sort(partialSkills, sortPartialSkills)

        for i, skillInfo in ipairs(partialSkills) do
            addSkillIcon(skillInfo.skillTypeIndex, false, skillInfo.fractionLearned)
        end

        sapienView.hoverStart = function ()
            if not sapienViewinfo.hover then
                sapienViewinfo.hover = true
                sapienView.color = vec4(mj.highlightColor.x,mj.highlightColor.y,mj.highlightColor.z,0.08)
                for i, button in ipairs(contextualButtons) do
                    button.hidden = false
                end
            end
        end
    
        sapienView.hoverEnd = function ()
            if sapienViewinfo.hover then
               sapienViewinfo.hover = false
               sapienView.color = backgroundColor
               for i, button in ipairs(contextualButtons) do
                   button.hidden = true
               end
            end
        end
    end
    
    for i,sapienInfo in ipairs(ordered) do
        insertRow(sapienInfo)
    end
end

function tribeUI:hide()
end

function tribeUI:popUI()
    return false
end

return tribeUI