--local mjm = mjrequire "common/mjm"

--local skill = mjrequire "common/skill"

local taskTreeUI = mjrequire "mainThread/ui/manageUI/taskTreeUI"
local taskAssignUI = mjrequire "mainThread/ui/manageUI/taskAssignUI"

local roleUI = {}

--local manageUI = nil
local world = nil


function roleUI:init(gameUI, world_, manageUI_, hubUI, contentView)
    --manageUI = manageUI_
    world = world_

    taskTreeUI:init(roleUI, gameUI, world_, manageUI_, contentView)
    taskAssignUI:init(roleUI, gameUI, world_, manageUI_, hubUI, contentView)
end

function roleUI:update()
    taskAssignUI:hide()
    taskTreeUI:show()
end

function roleUI:selectTask(skillTypeIndex)
    taskTreeUI:hide()
    taskAssignUI:show(skillTypeIndex)
end

function roleUI:show()
    world:setHasUsedTasksUI()
end

function roleUI:hide()
end

function roleUI:popUI()
    return false
end

return roleUI