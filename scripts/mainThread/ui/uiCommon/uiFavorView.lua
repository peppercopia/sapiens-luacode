local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

local locale = mjrequire "common/locale"
--local gameObject = mjrequire "common/gameObject"
local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"


local favorTextMaterial = material.types.ui_bronze_roughText.index

local uiFavorView = {}


uiFavorView.types = mj:enum {
    "standard_50x30",
    "large_1x1",
    "noBackground_notification_1x1",
    "noBackground_notification_1x1_small",
}

function uiFavorView:setValue(view, favorChangeValue, changeRequiresQuestCompletion)
    local userTable = view.userData
    if userTable.favorChangeValue ~= favorChangeValue then
        userTable.favorChangeValue = favorChangeValue

        if favorChangeValue == 0 then
            userTable.arrowIconView:setModel(model:modelIndexForName("icon_dot"),{
                [material.types.ui_standard.index] = material.types.ui_bronze_lightest_mildPositive.index,
            })
            userTable.arrowIconView.baseOffset = vec3(0,0,0)
        elseif favorChangeValue < 0 then
            userTable.arrowIconView:setModel(model:modelIndexForName("icon_down"),{
                [material.types.ui_standard.index] = material.types.ui_bronze_lightest_mildNegative.index,
            })
            userTable.arrowIconView.baseOffset = vec3(0,0,0)
        else
            userTable.arrowIconView:setModel(model:modelIndexForName("icon_up"),{
                [material.types.ui_standard.index] = material.types.ui_bronze_lightest_severePositive.index,
            })
            --userTable.arrowIconView.baseOffset = vec3(0,-1,0)
            userTable.arrowIconView.baseOffset = vec3(0,0,0)
        end

        userTable.favorValueTextView.text = string.format("%d", math.abs(favorChangeValue))--, favorTextMaterial)

        local combinedWidth = userTable.favorValueTextView.size.x + userTable.arrowIconView.size.x
        userTable.arrowTextLayoutView.size = vec2(combinedWidth + userTable.paddingOffsetBetweenIconAndText, userTable.arrowIconView.size.y)


        local tipTitle = nil
        if favorChangeValue > 0 then
            if changeRequiresQuestCompletion then
                tipTitle = locale:get("favor_tooltip_gain_later", {favorChangeValue=favorChangeValue})
            else
                tipTitle = locale:get("favor_tooltip_gain_now", {favorChangeValue=favorChangeValue})
            end
            if userTable.costsTextView then
                userTable.costsTextView:setText("Rewards", favorTextMaterial)
            end
        else
            if changeRequiresQuestCompletion then
                tipTitle = locale:get("favor_tooltip_cost_later", {favorChangeValue=-favorChangeValue})
            else
                tipTitle = locale:get("favor_tooltip_cost_now", {favorChangeValue=-favorChangeValue})
            end
            if userTable.costsTextView then
                userTable.costsTextView:setText("Costs", favorTextMaterial)
            end
        end

        if userTable.tipAdded then
            uiToolTip:updateText(userTable.backgroundView, tipTitle, nil, false)
        end

    end
end


function uiFavorView:create(parentView, typeOrNil)
    
    local userTable = {
        type = typeOrNil or uiFavorView.types.standard_50x30
    }
    local favorBackgroundSize = vec2(40,22)
    local modelName = "ui_inset_favor_10x3"
    local modelScaleDimensions = vec2(1.0, 0.3)
    local arrowHalfSize = 8
    local favorValueTextFontSize = 18
    local favorTextYOffset = 1
    local paddingOffsetBetweenIconAndText = -2

    if typeOrNil == uiFavorView.types.large_1x1 then
        modelName = "ui_inset_favor_1x1"
        favorBackgroundSize = vec2(80,80)
        modelScaleDimensions = vec2(1.0, 1.0)
        arrowHalfSize = 16
        favorValueTextFontSize = 36
        favorTextYOffset = -1
        paddingOffsetBetweenIconAndText = -4
    elseif typeOrNil == uiFavorView.types.noBackground_notification_1x1 then
        modelName = nil
        favorBackgroundSize = vec2(80,80)
        arrowHalfSize = 14
        favorValueTextFontSize = 24
        favorTextYOffset = -1
        paddingOffsetBetweenIconAndText = -4
    elseif typeOrNil == uiFavorView.types.noBackground_notification_1x1_small then
        modelName = nil
        favorBackgroundSize = vec2(20,20)
        arrowHalfSize = 6
        favorValueTextFontSize = 14
        favorTextYOffset = 1
        paddingOffsetBetweenIconAndText = -2
    end

    userTable.paddingOffsetBetweenIconAndText = paddingOffsetBetweenIconAndText

    local view = View.new(parentView)
    view.userData = userTable
    view.size = favorBackgroundSize

    local backgroundView = nil

    if modelName then
        backgroundView = ModelView.new(view)
        userTable.backgroundView = backgroundView
        backgroundView:setModel(model:modelIndexForName(modelName), {
            [material.types.ui_background_button.index] = material.types.ui_bronze.index,
            --[material.types.ui_selected.index] = material.types.ui_bronze_lighter.index,
        })
        backgroundView.baseOffset = vec3(0,0,1)

        local toolTipOffset = vec3(0,10,6)
        uiToolTip:add(backgroundView, ViewPosition(MJPositionCenter, MJPositionAbove), "", nil, toolTipOffset, nil, backgroundView, backgroundView)
        userTable.tipAdded = true

        local scaleToUseFavorBackgroundX = favorBackgroundSize.x * 0.5 / modelScaleDimensions.x
        local scaleToUseFavorBackgroundY = favorBackgroundSize.y * 0.5 / modelScaleDimensions.y
        backgroundView.scale3D = vec3(scaleToUseFavorBackgroundX,scaleToUseFavorBackgroundY,scaleToUseFavorBackgroundY)
        backgroundView.size = favorBackgroundSize
    else
        backgroundView = View.new(view)
        userTable.backgroundView = backgroundView
        backgroundView.size = favorBackgroundSize
        backgroundView.baseOffset = vec3(0,0,1)
    end

    local arrowTextLayoutView = View.new(backgroundView)
    userTable.arrowTextLayoutView = arrowTextLayoutView
    arrowTextLayoutView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    arrowTextLayoutView.baseOffset = vec3(-2,0,1)

    local arrowIconView = ModelView.new(arrowTextLayoutView)
    userTable.arrowIconView = arrowIconView
    arrowIconView.scale3D = vec3(arrowHalfSize,arrowHalfSize,arrowHalfSize)
    arrowIconView.size = vec2(arrowHalfSize) * 2.0
    arrowIconView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)

    --local favorTextView = ModelTextView.new(backgroundView)

    local favorValueTextView = TextView.new(arrowTextLayoutView)
    userTable.favorValueTextView = favorValueTextView
    favorValueTextView.font = Font(uiCommon.titleFontName, favorValueTextFontSize)
    favorValueTextView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    favorValueTextView.baseOffset = vec3(0,favorTextYOffset,0)

    --favorValueTextView.baseOffset = vec3(0,-1,0) do this above

    if typeOrNil == uiFavorView.types.large_1x1 then
        local costsTextView = ModelTextView.new(backgroundView)
        userTable.costsTextView = costsTextView
        costsTextView.font = Font(uiCommon.titleFontName, 18)
        costsTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
        costsTextView.baseOffset = vec3(0,-2,0)

        local favorTextView = ModelTextView.new(backgroundView)
        favorTextView.font = Font(uiCommon.titleFontName, 18)
        favorTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBottom)
        favorTextView.baseOffset = vec3(0,2,0)
        favorTextView:setText("Favor", favorTextMaterial)
    end

    return view
end

return uiFavorView