local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2

--local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"

local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiProgressBar = {}


local function updateVisuals(userTable)
    local barSize = vec2(userTable.backgroundView.size.x * userTable.value, userTable.backgroundView.size.y)
    --mj:log("barSize:", barSize)
    local scaleToUseX = barSize.x * 0.5
    local scaleToUseY = barSize.y * 0.5 / 0.05
    userTable.barView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseY)
    userTable.barView.size = barSize
end


function uiProgressBar:setValue(progressBarView, value)
    local userTable = progressBarView.userData
    userTable.value = value

    updateVisuals(userTable)

end


function uiProgressBar:setSelected(progressBarView, selected)
    if selected ~= progressBarView.userData.selected then
        progressBarView.userData.selected = selected
        updateVisuals(progressBarView.userData)
    end
end

function uiProgressBar:setMaterials(progressBarView, backgroundMaterialOrNil, insetMaterialOrNil, barMaterialOrNil)
    local userTable = progressBarView.userData
    userTable.backgroundMaterial = backgroundMaterialOrNil or userTable.backgroundMaterial
    userTable.insetMaterial = insetMaterialOrNil or userTable.insetMaterial
    userTable.barMaterial = barMaterialOrNil or userTable.barMaterial

    userTable.backgroundView:setModel(model:modelIndexForName("ui_favorProgressBar_bg"), {
        [material.types.ui_background.index] = userTable.backgroundMaterial,
        [material.types.ui_background_inset.index] = userTable.insetMaterial,
    })

    userTable.barView:setModel(model:modelIndexForName("ui_favorProgressBar_bar"), {
        [material.types.ui_background_inset.index] = userTable.barMaterial,
    })
    
end

function uiProgressBar:create(parentView, size, value, optionsOrNil)
    local options = optionsOrNil or {}
    local userTable = {
        value = value,
        backgroundMaterial = options.backgroundMaterial or material.types.ui_bronze.index,
        insetMaterial = options.insetMaterial or material.types.ui_bronze.index,
        barMaterial = options.barMaterial or material.types.ui_bronze_lightest.index,
    }

    local mainView = View.new(parentView)
    userTable.view = mainView
    mainView.size = size

    local backgroundSize = size
    --local barFillMaterialIndex = material.types.ui_standard.index
    
    local backgroundView = ModelView.new(mainView)
    userTable.backgroundView = backgroundView
    local scaleToUseX = backgroundSize.x * 0.5
    local scaleToUseY = backgroundSize.y * 0.5 / 0.05
    backgroundView.scale3D = vec3(scaleToUseX,scaleToUseY,backgroundSize.y * 0.5 / 0.05)
    backgroundView.size = backgroundSize

    local barView = ModelView.new(mainView)
    userTable.barView = barView
    barView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    --barView.baseOffset = vec3(0,0,8)

    mainView.userData = userTable

    uiProgressBar:setMaterials(mainView)

    updateVisuals(userTable)

    return mainView
end

return uiProgressBar