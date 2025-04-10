local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
--local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
--local uiObjectManager = mjrequire "mainThread/uiObjectManager"
--local audio = mjrequire "mainThread/audio"

local mapModeUI = {}

local world = nil

local titlePanelView = nil
local titleView = nil



local iconHalfSize = 20

local function updateTitleText()
    titleView:setText(world:getWorldName() .. " - " .. locale:get("ui_name_mapMode"), material.types.standardText.index)
    
    local maxWidth = math.max(200, titleView.size.x + 30)
    
    local sizeToUse = vec2(maxWidth + iconHalfSize * 2.0, titleView.size.y + 10)
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / 0.4
    titlePanelView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    titlePanelView.size = sizeToUse

end

function mapModeUI:load(gameUI, world_)
    world = world_
    
    titlePanelView = ModelView.new(gameUI.worldViews)
    titlePanelView:setModel(model:modelIndexForName("ui_panel_10x4"))
    titlePanelView.hidden = true;
    titlePanelView.alpha = 0.9
    titlePanelView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titlePanelView.baseOffset = vec3(0, -20, 0)

    titleView = ModelTextView.new(titlePanelView)
    titleView.font = Font(uiCommon.titleFontName, 36)
    titleView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    titleView.baseOffset = vec3(iconHalfSize,0,0)
    

    local iconView = ModelView.new(titlePanelView)
    iconView.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
    iconView.relativeView = titleView
    iconView.baseOffset = vec3(-5,0,0)
    iconView:setModel(model:modelIndexForName("icon_map"))
    iconView.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
    iconView.size = vec2(iconHalfSize,iconHalfSize) * 2.0
    
    updateTitleText()
end

function mapModeUI:show()
    if titlePanelView then
        titlePanelView.hidden = false
    end
end

function mapModeUI:hide()
    if titlePanelView then
        titlePanelView.hidden = true
    end
end

return mapModeUI