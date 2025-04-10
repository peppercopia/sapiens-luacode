
--local gameObject = mjrequire "common/gameObject"
local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local normalize = mjm.normalize
local length = mjm.length
local length2D2 = mjm.length2D2
local mat3LookAtInverse = mjm.mat3LookAtInverse
local mat3Identity = mjm.mat3Identity
local mat3Rotate = mjm.mat3Rotate
local approxEqual = mjm.approxEqual

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local plan = mjrequire "common/plan"
local locale = mjrequire "common/locale"
local terrainTypesModule = mjrequire "common/terrainTypes"
--local order = mjrequire "common/order"
--local skill = mjrequire "common/skill"
local planHelper = mjrequire "common/planHelper"
local gameObject = mjrequire "common/gameObject"
local research = mjrequire "common/research"
local constructable = mjrequire "common/constructable"




local eventManager = mjrequire "mainThread/eventManager"
local mainThreadDestination = mjrequire "mainThread/mainThreadDestination"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiGameObjectView = mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local audio = mjrequire "mainThread/audio"
local sapienMoveUI = mjrequire "mainThread/ui/sapienMoveUI"
local objectMoveUI = mjrequire "mainThread/ui/objectMoveUI"
local tribeRelationsUI = mjrequire "mainThread/ui/tribeRelationsUI"
local actionUIQuestView = mjrequire "mainThread/ui/actionUIQuestView"
--local keyMapping = mjrequire "mainThread/keyMapping"
local constructableUIHelper = mjrequire "mainThread/ui/constructableUIHelper"
local playerSapiens = mjrequire "mainThread/playerSapiens"
local hubUIUtilities = mjrequire "mainThread/ui/hubUIUtilities"
local tutorialUI = mjrequire "mainThread/ui/tutorialUI"
local uiKeyImage = mjrequire "mainThread/ui/uiCommon/uiKeyImage"
local storageLogisticsDestinationsUI = mjrequire "mainThread/ui/storageLogisticsDestinationsUI"


local logicInterface = mjrequire "mainThread/logicInterface"
local buildModeInteractUI = mjrequire "mainThread/ui/buildModeInteractUI"
local worldUIViewManager = mjrequire "mainThread/worldUIViewManager"
--local manageUI = mjrequire "mainThread/ui/manageUI/manageUI"

local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local manageButtonsUI = mjrequire "mainThread/ui/manageButtonsUI"
local changeAssignedSapienUI = mjrequire "mainThread/ui/changeAssignedSapienUI"


local inspectUI = mjrequire "mainThread/ui/inspect/inspectUI"


local actionUI = {}

local gameUI = nil
local hubUI = nil
local world = nil
local vRWorldViewInfo = nil

actionUI.mainView = nil
--local menuButtonsView = nil

--local buttonViews = {}
actionUI.wheels = {}
actionUI.currentWheelIndex = nil

actionUI.baseObject = nil
actionUI.selectedObjects = nil
actionUI.baseVert = nil
actionUI.selectedVertInfos = nil

--local mainViewSize = vec2(200.0,200.0)
actionUI.iconViewHalfSize = 150.0
actionUI.iconCenterDistance = 105.0
actionUI.backgroundView = nil

actionUI.innerSegmentIconCenterDistance = 47.0

actionUI.planStatusSize = vec2(80.0,80.0)
--local planStatusWarningSize = vec2(128.0,128.0)
actionUI.cancelIconOffsetScale = 2.2
actionUI.optionButtonOffsetScale = 2.2

--local buttonMinSize = vec2(100.0, 30.0)

--local thirdRotationMatrix = mat3Rotate(mat3Identity, math.pi * 2.0 / 3.0, vec3(0.0,0.0,1.0))
--local rotatedVec = vec3xMat3(vec3(0.0,1.0,0.0), thirdRotationMatrix)
--mj:log("rotatedVec:", rotatedVec)

--local multiSelectSegment = nil
--local zoomSegment = nil

local animateInOutFraction = 0.0
local animatingIn = false
local animatingInOrOut = false
local animateOutAxis = vec3(0.0,-1.0,0.0)

local minControllerLength2 = 0.2 * 0.2
local waitingForUnselect = false

actionUI.animateOutCompletionFunction = nil

--local currentObjectOrTriangleID = nil

local optionsButtonRotationAngle = math.pi / 5.0
local fifthAngle = (math.pi * 2.0) / 5.0
local sixthAngle = (math.pi * 2.0) / 6.0

local function rotatedButtonPos(startPos, angle)
    local cosTheta = math.cos(angle);
    local sinTheta = math.sin(angle);
    return vec2(startPos.x * cosTheta - startPos.y * sinTheta, startPos.x * sinTheta + startPos.y * cosTheta)
end


local iconLocationsForCounts = {
    [1] = {
        {
            offset = vec2(0.0,1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,1.0) * actionUI.iconCenterDistance, optionsButtonRotationAngle),
        }
    },
    [2] = {
        {
            offset = vec2(0.0,1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,1.0) * actionUI.iconCenterDistance, optionsButtonRotationAngle),
        },
        {
            offset = vec2(0.0,-1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,-1.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        }
    },
    [3] = {
        {
            offset = vec2(0.0,1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,1.0) * actionUI.iconCenterDistance, optionsButtonRotationAngle),
        },
        {
            offset = vec2(0.86602540378444,-0.5) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.86602540378444,-0.5) * actionUI.iconCenterDistance, optionsButtonRotationAngle),
        },
        {
            offset = vec2(-0.86602540378444,-0.5) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(-0.86602540378444,-0.5) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
    },
    [4] = {
        {
            offset = vec2(0.0,1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,1.0) * actionUI.iconCenterDistance, optionsButtonRotationAngle),
        },
        {
            offset = vec2(1.0,0.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = vec2(0.0,-1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,-1.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = vec2(-1.0,0.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(-1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
    },
    [5] = {
        {
            offset = vec2(0.0,1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,1.0) * actionUI.iconCenterDistance, optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -fifthAngle) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -fifthAngle * 2.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,-1.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -fifthAngle * 3.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(-1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -fifthAngle * 4.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(-1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
    },
    [6] = {
        {
            offset = vec2(0.0,1.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,1.0) * actionUI.iconCenterDistance, optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -sixthAngle) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -sixthAngle * 2.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(0.0,-1.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -sixthAngle * 3.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(-1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -sixthAngle * 4.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(-1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
        {
            offset = rotatedButtonPos(vec2(0.0,1.0), -sixthAngle * 5.0) * actionUI.iconCenterDistance,
            optionsOffset = rotatedButtonPos(vec2(-1.0,0.0) * actionUI.iconCenterDistance, -optionsButtonRotationAngle),
        },
    }
}

local toolTipZDistance = 6.0
local toolTipLocationsForCounts = {
    [1] = {
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        }
    },
    [2] = {
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        }
    },
    [3] = {
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(0.0,-50.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(0.0,-50.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
    },
    [4] = {
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            orderTextPlinthOffset = vec3(30.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            orderTextPlinthOffset = vec3(-30.0,0.0,0.0),
        },
    },
    [5] = {
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(0.0,30.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            orderTextPlinthOffset = vec3(30.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(-20.0,-100.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            orderTextPlinthOffset = vec3(30.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(20.0,-100.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            orderTextPlinthOffset = vec3(-30.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(0.0,30.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            orderTextPlinthOffset = vec3(-30.0,0.0,0.0),
        },
    },
    [6] = {
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionAbove),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(-5.0,57.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            orderTextPlinthOffset = vec3(30.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(-5.0,-57.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter),
            orderTextPlinthOffset = vec3(30.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance),
            relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionCenter, MJPositionBelow),
            orderTextPlinthOffset = vec3(0.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(5.0,-57.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            orderTextPlinthOffset = vec3(-30.0,0.0,0.0),
        },
        {
            offset = vec3(0.0,0.0,toolTipZDistance) + vec3(5.0,57.0,0.0),
            relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            cancelOffset = vec3(0.0,0.0,toolTipZDistance),
            cancelRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            optionsOffset = vec3(0.0,0.0,toolTipZDistance),
            optionsRelativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter),
            orderTextPlinthOffset = vec3(-30.0,0.0,0.0),
        },
    }
}



local controllerStartAnglesForCounts = {
    [1] = 0.0,
    [2] = 0.0,
    [3] = math.pi * 0.5 - math.pi / 3.0,
    [4] = math.pi * 0.25,
    [5] = math.pi * 0.5 - math.pi / 5.0,
    [6] = math.pi * 0.5 - math.pi / 6.0,
}

local wheelModelNames = {
    [1] = {
        "ui_radialMenu_1x1",
    },
    [2] = {
        "ui_radialMenu_2_top",
        "ui_radialMenu_2_bot"
    },
    [3] = {
        "ui_radialMenu_3_top",
        "ui_radialMenu_3_right",
        "ui_radialMenu_3_left",
    },
    [4] = {
        "ui_radialMenu_4_top",
        "ui_radialMenu_4_right",
        "ui_radialMenu_4_bot",
        "ui_radialMenu_4_left",
    },
    [5] = {
        "ui_radialMenu_5_top",
        "ui_radialMenu_5_topRight",
        "ui_radialMenu_5_botRight",
        "ui_radialMenu_5_botLeft",
        "ui_radialMenu_5_topLeft",
    },
    [6] = {
        "ui_radialMenu_6_topMid",
        "ui_radialMenu_6_topRight",
        "ui_radialMenu_6_botRight",
        "ui_radialMenu_6_botMid",
        "ui_radialMenu_6_botLeft",
        "ui_radialMenu_6_topLeft",
    }
}

local innerSegmentModelNames = {
    "ui_radialMenu_centerLeft",
    "ui_radialMenu_centerRight"
}

local innerSegmentControllerShortcuts = {
    "menuLeft",
    "menuRight"
}

local innerSegmentControllerShortcutKeyImageXOffsets = {
    4,
    -4
}


local innerSegmentIconNames = {
    "icon_multiSelect",
    "icon_inspect"
}

local innerSegmentIconOffsets = {
    vec2(-actionUI.innerSegmentIconCenterDistance, 0),
    vec2(actionUI.innerSegmentIconCenterDistance, 0)
}

local innerSegmentFunctions = {
    function()
        if inspectUI.baseObjectOrVertInfo then
            gameUI:selectMulti(inspectUI.baseObjectOrVertInfo, inspectUI.isTerrain)
        end
    end,
    function()
        if inspectUI.baseObjectOrVertInfo then
            gameUI:followObject(inspectUI.baseObjectOrVertInfo, inspectUI.isTerrain, {dismissAnyUI = true})
        end
    end
}

local innerSegmentToolTipInfos = {
    {
        offset = vec3(-actionUI.innerSegmentIconCenterDistance,30.0,8.0),
        relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter),
        text = locale:get("ui_action_selectMore"),
        groupKey = "game",
        mappingKey = "multiselectModifier",
        controllerSetIndex = nil, --todo
        controllerActionName = nil,
    },
    {
        offset = vec3(actionUI.innerSegmentIconCenterDistance,30.0,8.0),
        relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter),
        text = locale:get("ui_action_zoom"),
        groupKey = "game",
        mappingKey = "zoomModifier",
        controllerSetIndex = nil, --todo
        controllerActionName = nil,
    },
}

--[[local animateOutAxes = {
    [1] = {
        vec3(-1.0,0.0,0.0),
    },
    [2] = {
        vec3(-1.0,0.0,0.0),
        vec3(1.0,0.0,0.0),
    },
    [3] = {
        vec3(-1.0,0.0,0.0),
        normalize(vec3(0.5, -0.86602540378444, 0.0)),
        normalize(vec3(0.5, 0.86602540378444, 0.0))
    },
    [4] = {
        vec3(-1.0,0.0,0.0),
        vec3(0.0,-1.0,0.0),
        vec3(1.0,0.0,0.0),
        vec3(0.0,1.0,0.0),
    }
}]]

local currentlyRegisteredForStateChangesObjectIDs = nil
local currentlyRegisteredForStateChangesVertIDs = nil

local function deregisterStateChanges()
    if currentlyRegisteredForStateChangesObjectIDs then
        logicInterface:deregisterFunctionForObjectStateChanges(currentlyRegisteredForStateChangesObjectIDs, logicInterface.stateChangeRegistrationGroups.actionUI)
        currentlyRegisteredForStateChangesObjectIDs = nil
    end
    if currentlyRegisteredForStateChangesVertIDs then
        logicInterface:deregisterFunctionForVertStateChanges(currentlyRegisteredForStateChangesVertIDs, logicInterface.stateChangeRegistrationGroups.actionUI)
        currentlyRegisteredForStateChangesVertIDs = nil
    end
end

function actionUI:animateOutForOptionSelected()
    deregisterStateChanges()
    gameUI:stopFollowingObject()
    hubUI:hideInspectUI()
end

local function updateVisuals(wheelSegment, buttonTable)
    if buttonTable.icon then

        if buttonTable.hover and not animatingInOrOut then
            buttonTable.selected = true
        else
            buttonTable.selected = false
        end
        local materialIndex = material.types.standardText.index

        local disabled = buttonTable.disabled

        if disabled then
            materialIndex = material.types.disabledText.index
        else
            if buttonTable.hover then
                if buttonTable.planInfo.isDestructive then 
                    materialIndex = material.types.red.index
                elseif buttonTable.availibilityResult then
                    materialIndex = material.types.warning_selected.index
                else
                    materialIndex = material.types.selectedText.index
                end
            else
                if buttonTable.planInfo.isDestructive then 
                    materialIndex = material.types.warning_selected.index
                elseif buttonTable.availibilityResult then
                    materialIndex = material.types.warning.index
                else
                    materialIndex = material.types.standardText.index
                end
            end
        end

        --buttonTable.textView:setText(buttonTable.text, materialIndex)

        local tipText = buttonTable.toolTipText
        local shortcutMappingKey = nil
        if disabled then
            if buttonTable.planInfo.unavailableReasonText then
                tipText = tipText .. " (" .. buttonTable.planInfo.unavailableReasonText .. ")"
            else
                tipText = tipText .. " (".. locale:get("misc_unavailable") .. ")"
            end
        else
            if buttonTable.planInfo.isDestructive then
                shortcutMappingKey = "radialMenuDeconstruct"
            elseif buttonTable.planTypeIndex == plan.types.clone.index then
                shortcutMappingKey = "radialMenuClone"
            elseif buttonTable.planTypeIndex == plan.types.chopReplant.index then
                shortcutMappingKey = "radialMenuChopReplant"
            else
                shortcutMappingKey = string.format("radialMenuShortcut%d", buttonTable.segmentIndex)
            end
        end

        

        if buttonTable.availibilityResult then
            uiToolTip:updateText(wheelSegment, "", nil, disabled)
            uiToolTip:addColoredTitleText(wheelSegment, tipText, material:getUIColor(material.types.warning.index))

            --mj:log("buttonTable.availibilityResult:", buttonTable.availibilityResult)
            
            local problemStrings = hubUIUtilities:getPlanProblemStrings(buttonTable.availibilityResult)
            if problemStrings and next(problemStrings) then
                local descriptionText = ""
                for i, problemString in ipairs(problemStrings) do
                    descriptionText = descriptionText .. problemString
                    if i < #problemStrings then
                        descriptionText = descriptionText .. "\n"
                    end
                end

                uiToolTip:addColoredDescriptionText(wheelSegment, descriptionText, material:getUIColor(material.types.warning.index))
            end
            
        else
            uiToolTip:updateText(wheelSegment, tipText, nil, disabled)
        end

        if shortcutMappingKey then
            uiToolTip:addKeyboardShortcut(wheelSegment, "game", shortcutMappingKey, nil, nil)
        else
            uiToolTip:removeKeyboardShortcut(wheelSegment)
        end

        if buttonTable.planTypeIndex == plan.types.manageSapien.index then
            uiGameObjectView:setObject(buttonTable.gameObjectView, actionUI.baseObject, nil, nil)
            buttonTable.gameObjectView.hidden = false
            uiGameObjectView:setDisabled(buttonTable.gameObjectView, disabled)
            uiGameObjectView:setSelected(buttonTable.gameObjectView, buttonTable.selected)
            buttonTable.icon.hidden = true
        elseif buttonTable.planInfo.objectTypeIndex or buttonTable.fillConstructionTypeIndex then
            
            local objectInfo = {
                objectTypeIndex = buttonTable.planInfo.objectTypeIndex
            }
            if buttonTable.fillConstructionTypeIndex then
                objectInfo.objectTypeIndex = constructableUIHelper:getDisplayObjectTypeIndexForConstructableTypeIndex(buttonTable.fillConstructionTypeIndex)
            end

            uiGameObjectView:setObject(buttonTable.gameObjectView, objectInfo, nil, nil)
            buttonTable.gameObjectView.hidden = false
            uiGameObjectView:setDisabled(buttonTable.gameObjectView, disabled)
            uiGameObjectView:setSelected(buttonTable.gameObjectView, buttonTable.selected)
            uiGameObjectView:setWarning(buttonTable.gameObjectView, buttonTable.availibilityResult ~= nil)
            buttonTable.icon.hidden = true

        else
            buttonTable.gameObjectView.hidden = true
           -- buttonTable.objectImageBackgroundView.hidden = true
            buttonTable.icon.hidden = false
            local iconModelName = plan.types[buttonTable.planTypeIndex].icon or "icon_hand"
            if disabled then
                buttonTable.icon.alpha = 0.5
            else
                buttonTable.icon.alpha = 1.0
            end

            buttonTable.icon:setModel(model:modelIndexForName(iconModelName), {
                default = materialIndex
            })

            if (buttonTable.planTypeIndex == plan.types.research.index) and (not disabled) and (not buttonTable.availibilityResult) then
                buttonTable.icon.update = function(dt)
                    local timerValue = buttonTable.animationTimner or 0.0
                    timerValue = timerValue + dt
                    buttonTable.animationTimner = timerValue
                    local animationAddition = (1.0 + math.sin(timerValue * 5.0)) * 0.5
                    local logoHalfSize = 50.0 * 0.5 + animationAddition * 4.0
                    buttonTable.icon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
                    buttonTable.icon.size = vec2(logoHalfSize,logoHalfSize) * 2.0

                    
                    buttonTable.icon.alpha = 1.0 + animationAddition * 0.5
                end
            else
                buttonTable.icon.update = nil
                local logoHalfSize = 50.0 * 0.5
                buttonTable.icon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
                buttonTable.icon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
            end
        end


        if buttonTable.planInfo.hasQueuedPlans then
            uiStandardButton:setOrderMarkerCanComplete(buttonTable.cancelButton, buttonTable.planInfo.allQueuedPlansCanComplete)
            if buttonTable.planInfo.cancelOverrideIconName then
                uiStandardButton:setIconModel(buttonTable.cancelButton, buttonTable.planInfo.cancelOverrideIconName)
            else
                uiStandardButton:setIconModel(buttonTable.cancelButton, plan.types[buttonTable.planTypeIndex].icon or "icon_axe")
            end

            buttonTable.cancelButton.hidden = false

            local planStateForText = nil

            local function getMatchingCantCompletePlanState(planStates)
                if planStates then
                    local planStatesForTribe = planStates[world.tribeID]
                    if planStatesForTribe then
                        for j,planState in ipairs(planStatesForTribe) do
                            if planState.planTypeIndex == buttonTable.planTypeIndex and 
                            planState.objectTypeIndex == buttonTable.objectTypeIndex and 
                            (buttonTable.planInfo.allQueuedPlansCanComplete or (not planState.canComplete)) then --todo may need to check objectType and researchType
                                return planState
                            end
                        end
                    end
                end
            end
            
            if actionUI.selectedObjects then
                for i,objectInfo in ipairs(actionUI.selectedObjects) do
                    local planStates = objectInfo.sharedState.planStates
                    planStateForText = getMatchingCantCompletePlanState(planStates)
                    if planStateForText then
                        break
                    end
                end
            else
                for i,vertInfo in ipairs(actionUI.selectedVertInfos) do
                    local planObjectInfo = vertInfo.planObjectInfo
                    if planObjectInfo and planObjectInfo.sharedState then
                        local planStates = planObjectInfo.sharedState.planStates
                        planStateForText = getMatchingCantCompletePlanState(planStates)
                        if planStateForText then
                            break
                        end
                    end
                end
            end


            if not planStateForText then
                buttonTable.currentOrderTextPlinth.hidden = true
                buttonTable.currentOrderTextPlinthShouldBeVisible = false
            elseif not buttonTable.cancelButton.userData.hover then
                local planInfoString = hubUIUtilities:getPlanTitle(planStateForText)

                local materialToUse = material.types.ok.index
                if not buttonTable.planInfo.allQueuedPlansCanComplete then
                    materialToUse = material.types.warning.index
                end

                local problemStrings = hubUIUtilities:getPlanProblemStrings(planStateForText)

                if problemStrings and next(problemStrings) then
                    local descriptionText = ""
                    for i, problemString in ipairs(problemStrings) do
                        descriptionText = descriptionText .. problemString
                        if i < #problemStrings then
                            descriptionText = descriptionText .. "\n"
                        end
                    end
                    planInfoString = planInfoString .. "\n" .. descriptionText
                end

                buttonTable.currentOrderTitleTextView.color = material:getUIColor(materialToUse)
                buttonTable.currentOrderTitleTextView.text = planInfoString
                
                local sizeToUse = vec2(buttonTable.currentOrderTitleTextView.size.x + 12, buttonTable.currentOrderTitleTextView.size.y + 8)
                local scaleToUseX = sizeToUse.x * 0.5
                local scaleToUseY = sizeToUse.y * 0.5 / 0.2
                buttonTable.currentOrderTextPlinth.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
                buttonTable.currentOrderTextPlinth.size = sizeToUse

                buttonTable.currentOrderTextPlinth.hidden = false
                buttonTable.currentOrderTextPlinthShouldBeVisible = true
            end

            uiToolTip:updateText(buttonTable.cancelButton.userData.backgroundView, buttonTable.cancelToolTipText, nil, false)

            if buttonTable.changeAssignedSapienClickFunction then
                if buttonTable.assignedSapienInfo then
                    uiStandardButton:setIconModel(buttonTable.changeAssignedSapienButton, nil, nil)
                    uiStandardButton:setObjectIcon(buttonTable.changeAssignedSapienButton, buttonTable.assignedSapienInfo)
                    
                    uiToolTip:updateText(buttonTable.changeAssignedSapienButton.userData.backgroundView, locale:get("ui_action_assignDifferentSapien"), nil, false)
                else
                    uiStandardButton:setObjectIcon(buttonTable.changeAssignedSapienButton, nil)
                    uiStandardButton:setIconModel(buttonTable.changeAssignedSapienButton, "icon_sapien", nil)
                    
                    uiToolTip:updateText(buttonTable.changeAssignedSapienButton.userData.backgroundView, locale:get("ui_action_assignSapien"), nil, false)
                end
                buttonTable.changeAssignedSapienButton.hidden = false
                if buttonTable.hover or buttonTable.disabledHover then
                    buttonTable.changeAssignedSapienKeyImage.hidden = false
                else
                    buttonTable.changeAssignedSapienKeyImage.hidden = true
                end
            else
                buttonTable.changeAssignedSapienButton.hidden = true
                buttonTable.changeAssignedSapienKeyImage.hidden = true
            end

            if buttonTable.prioritizeFunction then
                buttonTable.prioritizeButton.hidden = false
                if buttonTable.hover or buttonTable.disabledHover then
                    buttonTable.prioritizeKeyImage.hidden = false
                else
                    buttonTable.prioritizeKeyImage.hidden = true
                end

                if buttonTable.planInfo.hasManuallyPrioritizedQueuedPlan then
                    uiStandardButton:setIconModel(buttonTable.prioritizeButton, "icon_downArrow", nil)
                    uiToolTip:updateText(buttonTable.prioritizeButton.userData.backgroundView, locale:get("ui_action_deprioritize"), nil, false)
                else
                    uiStandardButton:setIconModel(buttonTable.prioritizeButton, "icon_upArrow", nil)
                    uiToolTip:updateText(buttonTable.prioritizeButton.userData.backgroundView, locale:get("ui_action_prioritize"), nil, false)
                end
            else
                buttonTable.prioritizeButton.hidden = true
                buttonTable.prioritizeKeyImage.hidden = true
            end
            
            if buttonTable.hover or buttonTable.disabledHover then
                buttonTable.cancelKeyImage.hidden = false
            else
                buttonTable.cancelKeyImage.hidden = true
            end

        else
            buttonTable.cancelButton.hidden = true
            buttonTable.cancelKeyImage.hidden = true
            buttonTable.currentOrderTextPlinth.hidden = true
            buttonTable.changeAssignedSapienButton.hidden = true
            buttonTable.changeAssignedSapienKeyImage.hidden = true
            buttonTable.prioritizeButton.hidden = true
            buttonTable.prioritizeKeyImage.hidden = true
        end
        
        if buttonTable.planInfo.allowsObjectTypeSelection then
            uiStandardButton:setOrderMarkerCanComplete(buttonTable.optionsButton, true)
            uiStandardButton:setIconModel(buttonTable.optionsButton, "icon_settings")
            buttonTable.optionsButton.hidden = false

            if buttonTable.hover or buttonTable.disabledHover then
                buttonTable.optionsKeyImage.hidden = false
            else
                buttonTable.optionsKeyImage.hidden = true
            end

            local optionsTipText = locale:get("ui_action_setFillType")
            uiToolTip:updateText(buttonTable.optionsButton.userData.backgroundView, optionsTipText, nil, false)
        else
            buttonTable.optionsButton.hidden = true
            buttonTable.optionsKeyImage.hidden = true
        end
    end
end

local function updateInnerSegmentVisuals(innerSegment, buttonTable)
    if buttonTable.icon then

        if buttonTable.hover and not animatingInOrOut then
            buttonTable.selected = true
        else
            buttonTable.selected = false
        end
        local materialIndex = material.types.standardText.index

        local disabled = buttonTable.disabled

        if disabled then
            materialIndex = material.types.disabledText.index
        else
            if buttonTable.hover then
                materialIndex = material.types.selectedText.index
            else
                materialIndex = material.types.standardText.index
            end
        end
        
        if disabled then
            buttonTable.icon.alpha = 0.5
        else
            buttonTable.icon.alpha = 1.0
        end

        buttonTable.icon:setModel(model:modelIndexForName(buttonTable.iconModelName), {
            default = materialIndex
        })
    end
end

local buttonInfos = {}

local planAvailibilityRequestCounter = 1

local function updatePlanAvailibility(result)

    if result and next(result) then
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        local wheelSegments = wheel.segments

        for buttonIndex,wheelSegment in ipairs(wheelSegments) do
            local buttonTable = wheelSegment.userData
            for i,availibilityInfo in ipairs(result) do
                if availibilityInfo.planTypeIndex == buttonTable.planTypeIndex then
                    if buttonTable.planInfo.objectTypeIndex == availibilityInfo.objectTypeIndex and 
                    buttonTable.planInfo.researchTypeIndex == availibilityInfo.researchTypeIndex then
                        buttonTable.availibilityResult = availibilityInfo
                        updateVisuals(wheelSegment, buttonTable)
                        break
                    end
                end
            end
        end
    end
end

function actionUI:getCurrentObjectOfVertIDs()
    if not actionUI.mainView.hidden then
        local objectOrVertIDs = {}
        if actionUI.selectedObjects then
            for i,objectInfo in ipairs(actionUI.selectedObjects) do
                objectOrVertIDs[i] = objectInfo.uniqueID
            end
        else
            for i,vertInfo in ipairs(actionUI.selectedVertInfos) do
                objectOrVertIDs[i] = vertInfo.uniqueID
            end
        end
        if next(objectOrVertIDs) then
            return objectOrVertIDs
        end
    end
    return nil
end

local function updateButtons()
    buttonInfos = {}

    local buttonCount = 0
    if actionUI.selectedObjects or actionUI.selectedVertInfos then

        local availablePlans = nil
        local objectOrVertIDs = {}
        local baseObjectOrVertID = nil
        if actionUI.selectedObjects then
            --mj:log("calling planHelper:availablePlansForObjectInfos via updateButtons actionUI.selectedObjects:", actionUI.selectedObjects)
            availablePlans = planHelper:availablePlansForObjectInfos(actionUI.baseObject, actionUI.selectedObjects, world.tribeID)
            for i,objectInfo in ipairs(actionUI.selectedObjects) do
                objectOrVertIDs[i] = objectInfo.uniqueID
            end
            baseObjectOrVertID = actionUI.baseObject.uniqueID
        else
            availablePlans = planHelper:availablePlansForVertInfos(actionUI.baseVert, actionUI.selectedVertInfos, world.tribeID)
            for i,vertInfo in ipairs(actionUI.selectedVertInfos) do
                objectOrVertIDs[i] = vertInfo.uniqueID
            end
            baseObjectOrVertID = actionUI.baseVert.uniqueID
        end

        local availabilityRequest = {
            objectOrVertIDs = objectOrVertIDs,
            baseObjectOrVertID = baseObjectOrVertID,
            plans = {},
        }

        if availablePlans then
            
            local skipUnavailableCount = 0
            if #availablePlans > 6 then
                mj:warn("availablePlans > 6:", availablePlans)
                for i,planInfo in ipairs(availablePlans) do
                    mj:log("plan type:", plan.types[planInfo.planTypeIndex])
                end
                skipUnavailableCount = #availablePlans - 6
                --error()
            end

            for i,planInfo in ipairs(availablePlans) do

                local skip = false
                if skipUnavailableCount > 0 then
                    if (not planInfo.hasNonQueuedAvailable) and (not planInfo.hasQueuedPlans) then
                        skipUnavailableCount = skipUnavailableCount - 1
                        skip = true
                    end
                end

                if not skip then

                    if buttonCount >= 6 then
                        mj:error("buttonCount > 6. Skipping the rest.")
                        break
                    end
                    buttonCount = buttonCount + 1
                    local buttonIndex = buttonCount
                    local buttonFunction = nil
                    local cancelClickFunction = nil
                    local optionsClickFunction = nil
                    local changeAssignedSapienClickFunction = nil
                    local prioritizeFunction = nil
                    local planTypeIndex = planInfo.planTypeIndex
                    local fillConstructionTypeIndex = nil

                    if planTypeIndex == plan.types.fill.index then
                        if planInfo.hasQueuedPlans then
                            --mj:log("selectedVertInfo:", selectedVertInfo)
                            if actionUI.baseVert and actionUI.baseVert.planObjectInfo then
                                local planStates = actionUI.baseVert.planObjectInfo.sharedState.planStates
                                if planStates and planStates[world.tribeID] then
                                    for j, planState in ipairs(planStates[world.tribeID]) do
                                        if planState.planTypeIndex == planTypeIndex then
                                            fillConstructionTypeIndex = planState.constructableTypeIndex
                                            break
                                        end
                                    end
                                end
                            end
                        end

                        if not fillConstructionTypeIndex then
                            fillConstructionTypeIndex = constructableUIHelper:getTerrainFillConstructableTypeIndex()
                        end
                    end

                    local function getToolTipText(planTypeIndexToUse, inProgress)
                        local toolTipText = nil

                        if planTypeIndexToUse == plan.types.manageSapien.index then
                            toolTipText = locale:get("ui_action_manageSapien", {name = actionUI.baseObject.sharedState.name})
                        elseif planTypeIndexToUse == plan.types.manageTribeRelations.index then
                            local tribeName = nil
                            if actionUI.baseObject.sharedState and actionUI.baseObject.sharedState.tribeID then
                                local info = mainThreadDestination.destinationInfosByID[actionUI.baseObject.sharedState.tribeID]
                                if info then
                                    tribeName = info.name
                                end
                            end
                            if tribeName then
                                toolTipText = locale:get("plan_manageTribeRelationsWithTribeName", {tribeName = tribeName})
                            else
                                toolTipText = plan.types[planTypeIndexToUse].name
                            end
                        else
                            if inProgress and plan.types[planTypeIndexToUse].inProgress then 
                                toolTipText = plan.types[planTypeIndexToUse].inProgress
                            else
                                toolTipText = plan.types[planTypeIndexToUse].name
                            end
                            
                            local objectTypeIndex = planInfo.objectTypeIndex
                            if objectTypeIndex then
                                toolTipText = toolTipText .. " " .. gameObject.types[objectTypeIndex].plural
                            elseif planTypeIndexToUse == plan.types.gather.index then
                                if inProgress then
                                    toolTipText = locale:get("plan_gatherAllInProgress")
                                else
                                    toolTipText = locale:get("plan_gatherAll")
                                end
                            elseif fillConstructionTypeIndex then
                                toolTipText = toolTipText .. " " .. constructable.types[fillConstructionTypeIndex].name
                            elseif planTypeIndexToUse == plan.types.clone.index then
                                local constructableTypeIndexToUse = constructable:getConstructableTypeIndexForCloneOrRebuild(actionUI.selectedObjects[1])
                                --mj:log("constructableTypeIndexToUse:", constructableTypeIndexToUse)
                                if constructableTypeIndexToUse then
                                    local constructableType = constructable.types[constructableTypeIndexToUse]
                                    local classificationType = constructable.classifications[constructableType.classification]

                                    if not constructableType.plural then
                                        mj:error("no plural for constructableType:", constructableType)
                                    end
                                    
                                    toolTipText = classificationType.actionName .. " " .. constructableType.plural
                                end
                            elseif planInfo.researchTypeIndex then
                                local clueText = nil
                                if planInfo.discoveryCraftableTypeIndex then 
                                    local constructableType = constructable.types[planInfo.discoveryCraftableTypeIndex]
                                    if constructableType.constructableResearchClueText then
                                        clueText = constructableType.constructableResearchClueText
                                    end
                                end

                                if not clueText then
                                    clueText = research.types[planInfo.researchTypeIndex].clueText
                                end

                                if clueText then
                                    toolTipText = toolTipText .. ": " .. clueText
                                end

                                --mj:log("planInfo:", planInfo)
                                --toolTipText = research.types[planInfo.researchTypeIndex].name
                            end
                        end

                        if planInfo.cancelIsElsewhere then
                            toolTipText = toolTipText .. " " .. locale:get("misc_elsewhere")
                        end

                        return toolTipText
                    end

                    local toolTipText = getToolTipText(planInfo.planTypeIndex, false)
                

                    local cancelToolTipText = nil

                    if planTypeIndex == plan.types.fill.index then
                        cancelToolTipText = locale:get("ui_action_stop") .. " " .. getToolTipText(planTypeIndex, true)
                    else
                        --[[if planInfo.cancelOverrideDisplayedText then
                            cancelToolTipText = "Cancel " .. planInfo.cancelOverrideDisplayedText
                        else]]
                            cancelToolTipText = locale:get("ui_action_stop") .. " " .. getToolTipText(planTypeIndex, true)
                    -- end
                    end

                    if planInfo.hasNonQueuedAvailable then

                        if plan.types[planInfo.planTypeIndex].checkCanCompleteForRadialUI then
                            
                            local addInfo = {
                                planTypeIndex = planInfo.planTypeIndex,
                                objectTypeIndex = planInfo.objectTypeIndex,
                                researchTypeIndex = planInfo.researchTypeIndex,
                                discoveryCraftableTypeIndex = planInfo.discoveryCraftableTypeIndex,
                            }

                            if planTypeIndex == plan.types.fill.index then
                                addInfo.constructableTypeIndex = fillConstructionTypeIndex
                                addInfo.restrictedResourceObjectTypes = world:getConstructableRestrictedObjectTypes(addInfo.constructableTypeIndex, false)
                                addInfo.restrictedToolObjectTypes = world:getConstructableRestrictedObjectTypes(addInfo.constructableTypeIndex, true)
                            end

                            table.insert(availabilityRequest.plans, addInfo)
                        end

                        buttonFunction = function(wasQuickSwipeAction)
                            audio:playUISound(uiCommon.orderSoundFile)
                            if planInfo.researchTypeIndex then
                                world:setHasQueuedResearchPlan(true)
                            end
                            
                            --mj:log("planInfo:", planInfo)
                            if planInfo.planTypeIndex == plan.types.moveTo.index then
                                actionUI:animateOutForOptionSelected()
                                sapienMoveUI:show(objectOrVertIDs)
                            elseif planInfo.planTypeIndex == plan.types.haulObject.index then
                                actionUI:animateOutForOptionSelected()
                                objectMoveUI:show(objectOrVertIDs, inspectUI.baseObjectOrVertInfo)
                            elseif planInfo.planTypeIndex == plan.types.stop.index then
                                logicInterface:callServerFunction("cancelSapienOrders", {
                                    sapienIDs = objectOrVertIDs,
                                })
                                actionUI:animateOutForOptionSelected()
                            elseif planInfo.planTypeIndex == plan.types.wait.index then
                                logicInterface:callServerFunction("addWaitOrder", {
                                    sapienIDs = objectOrVertIDs,
                                })
                                actionUI:animateOutForOptionSelected()
                            elseif planInfo.planTypeIndex == plan.types.clone.index then
                                if inspectUI.baseObjectOrVertInfo then
                                    buildModeInteractUI:showForDuplication(inspectUI.baseObjectOrVertInfo)
                                    actionUI:animateOutForOptionSelected()
                                end
                            elseif planInfo.planTypeIndex == plan.types.craft.index or 
                            planInfo.planTypeIndex == plan.types.manageStorage.index or 
                            planInfo.planTypeIndex == plan.types.manageSapien.index or 
                            planInfo.planTypeIndex == plan.types.constructWith.index or 
                            planInfo.planTypeIndex == plan.types.rebuild.index then
                                inspectUI:showInspectPanelForActionUISelectedPlanType(planInfo.planTypeIndex)
                            elseif planInfo.planTypeIndex == plan.types.allowUse.index then
                                logicInterface:callServerFunction("changeAllowItemUse", {
                                    objectIDs = objectOrVertIDs,
                                    allowItemUse = true,
                                })
                                --if wasQuickSwipeAction then
                                    actionUI:animateOutForOptionSelected()
                                --[[else
                                    buttonInfos[buttonIndex].disabled = true
                                    local wheel = actionUI.wheels[actionUI.currentWheelIndex]
                                    updateVisuals(wheel.segments[buttonIndex], wheel.segments[buttonIndex].userData) --todo this is untested, will only show up with lag, needs to be tested
                                end]]
                            elseif planInfo.planTypeIndex == plan.types.manageTribeRelations.index then
                                tribeRelationsUI:show(mainThreadDestination.destinationInfosByID[actionUI.baseObject.sharedState.tribeID], nil, nil, nil, false)
                                actionUI:animateOutForOptionSelected()
                            elseif planInfo.planTypeIndex == plan.types.startRoute.index then
                                logicInterface:createLogisticsRoute(objectOrVertIDs[1], nil, function(uiRouteInfo)
                                    if uiRouteInfo then
                                        gameUI:hideAllUI(false)
                                        storageLogisticsDestinationsUI:show(uiRouteInfo)
                                    end
                                end)
                                actionUI:animateOutForOptionSelected()
                            else
                                local addInfo = {
                                    planTypeIndex = planInfo.planTypeIndex,
                                    objectTypeIndex = planInfo.objectTypeIndex,
                                    researchTypeIndex = planInfo.researchTypeIndex,
                                    discoveryCraftableTypeIndex = planInfo.discoveryCraftableTypeIndex,
                                    objectOrVertIDs = objectOrVertIDs,
                                }

                                if actionUI.baseVert then
                                    addInfo.baseVertID = actionUI.baseVert.uniqueID
                                end

                                if planTypeIndex == plan.types.fill.index then
                                    addInfo.constructableTypeIndex = fillConstructionTypeIndex
                                    addInfo.restrictedResourceObjectTypes = world:getConstructableRestrictedObjectTypes(addInfo.constructableTypeIndex, false)
                                    addInfo.restrictedToolObjectTypes = world:getConstructableRestrictedObjectTypes(addInfo.constructableTypeIndex, true)
                                end

                                if planTypeIndex == plan.types.clear.index and actionUI.selectedVertInfos then
                                    
                                    if not tutorialUI:clearPlanComplete() then
                                        local function checkForHayOrGrass()
                                            for j,vertInfo in ipairs(actionUI.selectedVertInfos) do
                                                local variations = vertInfo.variations
                                                if variations then
                                                    for terrainVariationTypeIndex,v in pairs(variations) do
                                                        local terrainVariationType = terrainTypesModule.variations[terrainVariationTypeIndex]
                                                        if terrainVariationType.canBeCleared and terrainVariationType.clearOutputs then
                                                            for k,outputInfo in ipairs(terrainVariationType.clearOutputs) do
                                                                if outputInfo.objectKeyName == "grass" or outputInfo.objectKeyName == "hay" then
                                                                    return true
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            return false
                                        end
                                        if checkForHayOrGrass() then
                                            tutorialUI:clearPlanWasIssued()
                                        end
                                    end
                                end

                                --mj:log("objectOrVertIDs:", objectOrVertIDs)

                                logicInterface:callServerFunction("addPlans", addInfo)
                                --if wasQuickSwipeAction then
                                    actionUI:animateOutForOptionSelected()
                                --[[else
                                    buttonInfos[buttonIndex].disabled = true
                                    local wheel = actionUI.wheels[actionUI.currentWheelIndex]
                                    updateVisuals(wheel.segments[buttonIndex], wheel.segments[buttonIndex].userData) --todo this is untested, will only show up with lag, needs to be tested
                                end]]
                            end

                            

                            if not tutorialUI:multiSelectComplete() then
                                local objectCount = #objectOrVertIDs
                                if objectCount > 1 then
                                    tutorialUI:multiSelectWasIssued(objectCount)
                                end
                            end
                        end
                        
                    end

                    local assignedSapienInfo = nil

                    if planInfo.hasQueuedPlans then
                        cancelClickFunction = function()
                            audio:playUISound(uiCommon.cancelSoundFile)
                            if planInfo.cancelIsFollowerOrderQueue then
                                logicInterface:callServerFunction("cancelSapienOrders", {
                                    sapienIDs = objectOrVertIDs,
                                    planTypeIndex = planInfo.planTypeIndex,
                                })
                            elseif planInfo.planTypeIndex == plan.types.wait.index then
                                logicInterface:callServerFunction("cancelWaitOrder", {
                                    sapienIDs = objectOrVertIDs,
                                })
                            else
                                local planTypeIndexToUseForCancel = planInfo.planTypeIndex

                                if planTypeIndexToUseForCancel == plan.types.constructWith.index then
                                    planTypeIndexToUseForCancel = plan.types.craft.index
                                end
                                logicInterface:callServerFunction("cancelPlans", {
                                    planTypeIndex = planTypeIndexToUseForCancel,
                                    objectTypeIndex = planInfo.objectTypeIndex,
                                    researchTypeIndex = planInfo.researchTypeIndex,
                                    discoveryCraftableTypeIndex = planInfo.discoveryCraftableTypeIndex,
                                    objectOrVertIDs = objectOrVertIDs,
                                })
                            end

                        -- if planInfo.hideUIOnCancel then
                            --   actionUI:animateOutForOptionSelected(buttonIndex, nil)
                        -- end
                            
                            planInfo.hasQueuedPlans = false
                            local wheel = actionUI.wheels[actionUI.currentWheelIndex]
                            updateVisuals(wheel.segments[buttonIndex], wheel.segments[buttonIndex].userData) --todo this is untested, will only show up with lag, needs to be tested
                        end

                        if (not planInfo.cancelIsFollowerOrderQueue) and (planInfo.planTypeIndex ~= plan.types.wait.index) and (not planInfo.cancelIsElsewhere) then
                            prioritizeFunction = function()
                                local planTypeIndexToUse = planInfo.planTypeIndex

                                if planTypeIndexToUse == plan.types.constructWith.index then
                                    planTypeIndexToUse = plan.types.craft.index
                                end

                                if planInfo.hasManuallyPrioritizedQueuedPlan then
                                    logicInterface:callServerFunction("deprioritizePlans", {
                                        objectOrVertIDs = objectOrVertIDs,
                                        planTypeIndex = planTypeIndexToUse,
                                        objectTypeIndex = planInfo.objectTypeIndex,
                                        researchTypeIndex = planInfo.researchTypeIndex,
                                        discoveryCraftableTypeIndex = planInfo.discoveryCraftableTypeIndex,
                                    })
                                    --todo maybe update visuals
                                else
                                    logicInterface:callServerFunction("prioritizePlans", {
                                        objectOrVertIDs = objectOrVertIDs,
                                        planTypeIndex = planTypeIndexToUse,
                                        objectTypeIndex = planInfo.objectTypeIndex,
                                        researchTypeIndex = planInfo.researchTypeIndex,
                                        discoveryCraftableTypeIndex = planInfo.discoveryCraftableTypeIndex,
                                    })

                                    tutorialUI:prioritizationWasIssued()
                                end
                            end
                        end

                        if #objectOrVertIDs == 1 and (not planInfo.cancelIsElsewhere) and (planInfo.allQueuedPlansCanComplete) then
                            local firstObjectInfo = nil
                            if actionUI.baseVert then
                                firstObjectInfo = actionUI.baseVert.planObjectInfo
                            else
                                firstObjectInfo = actionUI.selectedObjects[1]
                            end
                            if firstObjectInfo and firstObjectInfo.sharedState then
                                local assignedSapienIDs = firstObjectInfo.sharedState.assignedSapienIDs
                                if assignedSapienIDs then
                                    for assignedSapienID,planTypeIndexOrTrue in pairs(assignedSapienIDs) do
                                        local sapienInfo = playerSapiens:getInfo(assignedSapienID)
                                        if sapienInfo then
                                            local orderQueue = sapienInfo.sharedState.orderQueue
                                            if orderQueue and orderQueue[1] then
                                                local orderContext = orderQueue[1].context
                                                if orderContext and orderContext.planObjectID == firstObjectInfo.uniqueID and 
                                                orderContext.planTypeIndex == planInfo.planTypeIndex and 
                                            ((not planInfo.objectTypeIndex) or (not orderContext.objectTypeIndex) or orderContext.objectTypeIndex == planInfo.objectTypeIndex) then
                                                    --mj:log("found assigned sapien info:", sapienInfo)
                                                    assignedSapienInfo = {
                                                        uniqueID = assignedSapienID,
                                                        objectTypeIndex = gameObject.types.sapien.index,
                                                        sharedState = sapienInfo.sharedState,
                                                    }
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            if not planInfo.sapienAssignButtonShouldBeHidden then
                                changeAssignedSapienClickFunction = function()
                                    actionUI:animateOutForOptionSelected()
                                    changeAssignedSapienUI:show(firstObjectInfo, planInfo)
                                end
                            end
                        end
                    end

                    if planInfo.allowsObjectTypeSelection then
                        optionsClickFunction = function()
                            inspectUI:showInspectPanelForActionUIOptionsButton(planInfo.planTypeIndex)
                        end
                    end

                    buttonInfos[buttonIndex] = {
                        toolTipText = toolTipText,
                        cancelToolTipText = cancelToolTipText,
                        clickFunction = buttonFunction,
                        cancelClickFunction = cancelClickFunction,
                        optionsClickFunction = optionsClickFunction,
                        changeAssignedSapienClickFunction = changeAssignedSapienClickFunction,
                        prioritizeFunction = prioritizeFunction,
                        planTypeIndex = planTypeIndex,
                        objectTypeIndex = planInfo.objectTypeIndex,
                        researchTypeIndex = planInfo.researchTypeIndex,
                        fillConstructionTypeIndex = fillConstructionTypeIndex,
                        planInfo = planInfo,
                        disabled = not planInfo.hasNonQueuedAvailable,
                        assignedSapienInfo = assignedSapienInfo,
                    }
                end

            end
        end

        planAvailibilityRequestCounter = planAvailibilityRequestCounter + 1
        local thisRequestCounter = planAvailibilityRequestCounter
        logicInterface:callServerFunction("checkPlanAvailability", availabilityRequest, function(result)
            if thisRequestCounter == planAvailibilityRequestCounter then
                updatePlanAvailibility(result)
            end
        end)
    else
        mj:error("No selectedVertInfo or actionUI.selectedObjects")
        return false
    end

    if actionUI.currentWheelIndex ~= buttonCount then
        if buttonCount < 1 or buttonCount > 6 then
            mj:error("Unimplemted wheel button count:", buttonCount)
            error()
            return false
        end
        if actionUI.currentWheelIndex then
            actionUI.wheels[actionUI.currentWheelIndex].view.hidden = true
        end

        actionUI.currentWheelIndex = buttonCount
        actionUI.wheels[actionUI.currentWheelIndex].view.hidden = false
    end

    --[[
    if actionUI.selectedObjects then --todo multiselect and zoom for terrain. This just stops it crashing for now
        multiSelectSegment.userData.disabled = false
        zoomSegment.userData.disabled = false
    else
        multiSelectSegment.userData.disabled = true
        zoomSegment.userData.disabled = true
    end]]

    local wheel = actionUI.wheels[actionUI.currentWheelIndex]
    for segmentIndex=1,buttonCount do
       local segment = wheel.segments[segmentIndex]
       local segmentTable = segment.userData
       segmentTable.clickFunction = buttonInfos[segmentIndex].clickFunction
       segmentTable.toolTipText = buttonInfos[segmentIndex].toolTipText
       segmentTable.cancelToolTipText = buttonInfos[segmentIndex].cancelToolTipText
       segmentTable.planTypeIndex = buttonInfos[segmentIndex].planTypeIndex
       segmentTable.objectTypeIndex = buttonInfos[segmentIndex].objectTypeIndex
       segmentTable.researchTypeIndex = buttonInfos[segmentIndex].researchTypeIndex
       segmentTable.fillConstructionTypeIndex = buttonInfos[segmentIndex].fillConstructionTypeIndex
       segmentTable.planInfo = buttonInfos[segmentIndex].planInfo
       segmentTable.disabled = buttonInfos[segmentIndex].disabled
       segmentTable.assignedSapienInfo = buttonInfos[segmentIndex].assignedSapienInfo
       segmentTable.cancelClickFunction = buttonInfos[segmentIndex].cancelClickFunction
       segmentTable.optionsClickFunction = buttonInfos[segmentIndex].optionsClickFunction
       segmentTable.changeAssignedSapienClickFunction = buttonInfos[segmentIndex].changeAssignedSapienClickFunction
       segmentTable.prioritizeFunction = buttonInfos[segmentIndex].prioritizeFunction
       segmentTable.availibilityResult = nil
       uiStandardButton:setClickFunction(segmentTable.cancelButton, buttonInfos[segmentIndex].cancelClickFunction)
       uiStandardButton:setClickFunction(segmentTable.optionsButton, buttonInfos[segmentIndex].optionsClickFunction)
       uiStandardButton:setClickFunction(segmentTable.changeAssignedSapienButton, buttonInfos[segmentIndex].changeAssignedSapienClickFunction)
       uiStandardButton:setClickFunction(segmentTable.prioritizeButton, buttonInfos[segmentIndex].prioritizeFunction)
       
       updateVisuals(segment, segmentTable)
    end

    return true
end

--local knobView = nil

--local menuButtonsByManageUIModeType = {}

function actionUI:selectButtonAtIndex(index, shouldAutomateOrOpenOptions)
    local buttonInfo = buttonInfos[index]
    if buttonInfo then
        if buttonInfo.planInfo.isDestructive then
            audio:playUISound(uiCommon.failSoundFile)
            actionUI:animateOutForOptionSelected()
        else
            if shouldAutomateOrOpenOptions then
                if buttonInfo.optionsClickFunction then
                    buttonInfo.optionsClickFunction()
                end
            else
                if buttonInfo.cancelClickFunction then
                    audio:playUISound(uiCommon.failSoundFile)
                    actionUI:animateOutForOptionSelected()
                    --buttonInfo.cancelClickFunction()
                elseif buttonInfo.disabled then
                    audio:playUISound(uiCommon.failSoundFile)
                    actionUI:animateOutForOptionSelected()
                elseif buttonInfo.clickFunction then
                    buttonInfo.clickFunction(true)
                end
            end
        end
    else
        audio:playUISound(uiCommon.failSoundFile)
        actionUI:animateOutForOptionSelected()
    end
end

function actionUI:zoomShortcut()
    innerSegmentFunctions[2]()
end

function actionUI:multiselectShortcut()
    innerSegmentFunctions[1]()
end

function actionUI:selectDeconstructAction(shouldAutomateOrOpenOptions)
    if actionUI.currentWheelIndex then
        for index=1,actionUI.currentWheelIndex do
            local buttonInfo = buttonInfos[index]
            if buttonInfo and buttonInfo.planInfo.isDestructive then
                if buttonInfo.cancelClickFunction then
                    audio:playUISound(uiCommon.failSoundFile)
                    actionUI:animateOutForOptionSelected()
                    --buttonInfo.cancelClickFunction()
                elseif buttonInfo.clickFunction then
                    buttonInfo.clickFunction(true)
                end
            end
        end
    end
end

function actionUI:selectCloneAction(shouldAutomateOrOpenOptions)
    if actionUI.currentWheelIndex then
        for index=1,actionUI.currentWheelIndex do
            local buttonInfo = buttonInfos[index]
            if buttonInfo and buttonInfo.planTypeIndex == plan.types.clone.index then
                if buttonInfo.cancelClickFunction then
                    audio:playUISound(uiCommon.failSoundFile)
                    actionUI:animateOutForOptionSelected()
                    --buttonInfo.cancelClickFunction()
                elseif buttonInfo.clickFunction then
                    buttonInfo.clickFunction(true)
                end
            end
        end
    end
end

function actionUI:selectChopReplantAction(shouldAutomateOrOpenOptions)
    if actionUI.currentWheelIndex then
        for index=1,actionUI.currentWheelIndex do
            local buttonInfo = buttonInfos[index]
            if buttonInfo and buttonInfo.planTypeIndex == plan.types.chopReplant.index then
                if buttonInfo.cancelClickFunction then
                    audio:playUISound(uiCommon.failSoundFile)
                    actionUI:animateOutForOptionSelected()
                    --buttonInfo.cancelClickFunction()
                elseif buttonInfo.clickFunction then
                    buttonInfo.clickFunction(true)
                end
            end
        end
    end
end


function actionUI:init(gameUI_, hubUI_, world_)
    gameUI = gameUI_
    world = world_
    hubUI = hubUI_
    local ownerView = gameUI.view


    if world.isVR then
        actionUI.iconViewHalfSize = actionUI.iconViewHalfSize * 0.01

        vRWorldViewInfo = worldUIViewManager:addView(vec3(0.0,0.0,0.0),
            worldUIViewManager.groups.actionUI,
            {
                offsets = mj:mToP(1.0) -- not tested
            }
        )

        vRWorldViewInfo.view.hidden = true
        ownerView = vRWorldViewInfo.view
        ownerView.hidden = true
        --worldUIViewManager:setMouseInteractionsEnabledForView(vRWorldViewInfo.uniqueID, false)

        
    end

    actionUI.mainView = View.new(ownerView)
    actionUI.mainView.hidden = true
    actionUI.mainView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    actionUI.mainView.size = vec2(actionUI.iconViewHalfSize * 2, actionUI.iconViewHalfSize * 2)
    --actionUI.mainView:setRenderTargetBacked(true, true, true)

    
    if vRWorldViewInfo then
        actionUI.mainView.scale = 0.1
    end
        
        --[[local knobSize = vec2(3.0,3.0)
        knobView = ModelView.new(actionUI.mainView)
        knobView:setModel(model:modelIndexForName("ui_slider_knob"))
        local knobScaleToUseX = knobSize.x * 0.5
        local knobScaleToUseY = knobSize.y * 0.5
        knobView.scale3D = vec3(knobScaleToUseX,knobScaleToUseY,knobScaleToUseY)
        knobView.size = knobSize
        knobView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)]]
   -- end


    local scaleToUse = actionUI.iconViewHalfSize

    actionUI.backgroundView = View.new(actionUI.mainView)
    actionUI.backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    actionUI.backgroundView.size = vec2(actionUI.iconViewHalfSize * 2, actionUI.iconViewHalfSize * 2)

   -- local updateTimer = 0.0
    actionUI.backgroundView.update = function(dt)
        if animatingInOrOut then
            if animatingIn then
                animateInOutFraction = animateInOutFraction + dt * 8.0
                if animateInOutFraction > 1.0 then
                    animatingInOrOut = false
                    animateInOutFraction = 1.0
                    local wheel = actionUI.wheels[actionUI.currentWheelIndex]
                    for segmentIndex=1,actionUI.currentWheelIndex do
                        local segment = wheel.segments[segmentIndex]
                        local segmentTable = segment.userData
                        updateVisuals(segment, segmentTable)
                    end
                end
                local angleFraction = (1.0 - animateInOutFraction) * (1.0 - animateInOutFraction)
                actionUI.backgroundView.rotation = mat3Rotate(mat3Identity, math.pi * 0.4 * angleFraction, vec3(0.0,1.0,0.0))
                actionUI.backgroundView.alpha = 1.0 - angleFraction
            else
                animateInOutFraction = animateInOutFraction - dt * 8.0
                if animateInOutFraction < 0.0 then
                    actionUI:hide()
                    if actionUI.animateOutCompletionFunction then
                        actionUI.animateOutCompletionFunction()
                        actionUI.animateOutCompletionFunction = nil
                    end
                else
                    local angleFraction = (1.0 - animateInOutFraction) * (1.0 - animateInOutFraction)
                    actionUI.backgroundView.rotation = mat3Rotate(mat3Identity, math.pi * 0.4 * angleFraction, animateOutAxis)
                    actionUI.backgroundView.alpha = 1.0 - angleFraction
                end
            end
        end
        --updateTimer = updateTimer + dt
       -- actionUI.backgroundView.rotation = mat3Rotate(mat3Identity, math.pi * updateTimer, vec3(0.0,1.0,0.0))
    end
    
    
    local function addWheelSegment(segmentCount, segmentIndex)
        local parentView = actionUI.wheels[segmentCount].view
        local modelName = wheelModelNames[segmentCount][segmentIndex]

        local wheelSegmentView = View.new(parentView)
        wheelSegmentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        wheelSegmentView.size = vec2(actionUI.iconViewHalfSize * 2, actionUI.iconViewHalfSize * 2)

        local wheelSegment = ModelView.new(wheelSegmentView)
        wheelSegment.alpha = 0.97
        wheelSegment:setModel(model:modelIndexForName(modelName), {
            default = material.types.ui_background.index
        })
        wheelSegment:setUsesModelHitTest(true)
        wheelSegment.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse * 0.1)
        wheelSegment.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        wheelSegment.size = vec2(actionUI.iconViewHalfSize * 2, actionUI.iconViewHalfSize * 2)

        
        local buttonTable = {
            selected = false,
            mouseDown = false,
            segmentIndex = segmentIndex,
        }
        
        wheelSegment.hoverStart = function (mouseLoc)
            if not (buttonTable.hover or buttonTable.disabledHover) then
                if not buttonTable.disabled then
                    buttonTable.hover = true
                    buttonTable.disabledHover = false
                    audio:playUISound(uiCommon.hoverSoundFile)
                else
                    buttonTable.hover = false
                    buttonTable.disabledHover = true
                end
                updateVisuals(wheelSegment, buttonTable)
            end
        end

        wheelSegment.hoverEnd = function ()
            if buttonTable.hover then
                buttonTable.hover = false
                buttonTable.mouseDown = false
            end
            buttonTable.disabledHover = false
            updateVisuals(wheelSegment, buttonTable)
        end

        wheelSegment.mouseDown = function (buttonIndex)
            if buttonIndex == 0 then
                if not buttonTable.mouseDown then
                    if not buttonTable.disabled then
                        buttonTable.mouseDown = true
                        buttonTable.hover = true
                        updateVisuals(wheelSegment, buttonTable)
                        audio:playUISound(uiCommon.clickDownSoundFile)
                    end
                end
            end
        end

        wheelSegment.mouseUp = function (buttonIndex)
            if (not animatingInOrOut) and buttonIndex == 0 then
                local wasQuickSwipeAction = true
                if buttonTable.mouseDown then
                    wasQuickSwipeAction = false
                    buttonTable.mouseDown = false
                    updateVisuals(wheelSegment, buttonTable)
                    audio:playUISound(uiCommon.clickReleaseSoundFile)
                end
                if buttonTable.clickFunction and not buttonTable.disabled then
                    buttonTable.clickFunction(wasQuickSwipeAction)
                end
            end
        end

       --[[ wheelSegment.click = function()
            if buttonTable.clickFunction and not buttonTable.disabled then
                buttonTable.clickFunction()
            end
        end]]

        
        local iconLocations = iconLocationsForCounts[segmentCount]
        local buttonLocation = iconLocations[segmentIndex]
        --[[local textView = ModelTextView.new(wheelSegmentView)
        textView.font = Font(uiCommon.fontName, 12)
        textView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        textView.baseOffset = vec3(buttonLocation.offset.x,buttonLocation.offset.y - 20, 20)
        buttonTable.textView = textView]]

        local logoHalfSize = 50.0 * 0.5

        
        local icon = ModelView.new(wheelSegmentView)
        icon.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        icon.baseOffset = vec3(buttonLocation.offset.x,buttonLocation.offset.y, 1)
        icon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
        icon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
        icon.masksEvents = false
        buttonTable.icon = icon

        
        local toolTipLocations = toolTipLocationsForCounts[segmentCount]
        local toolTipLocation = toolTipLocations[segmentIndex]

        local cancelButton = uiStandardButton:create(parentView, actionUI.planStatusSize, uiStandardButton.types.orderMarker)
        cancelButton.baseOffset = vec3(buttonLocation.offset.x * actionUI.cancelIconOffsetScale,buttonLocation.offset.y * actionUI.cancelIconOffsetScale, 0)
        buttonTable.cancelButton = cancelButton
        uiToolTip:add(cancelButton.userData.backgroundView, toolTipLocation.cancelRelativePosition, "Stop", nil, toolTipLocation.orderTextPlinthOffset, nil, cancelButton)
        uiStandardButton:setSecondaryHoverIconModel(cancelButton, "icon_cancel", {
            default = material.types.red.index
        })

        
        local cancelKeyImage = uiKeyImage:create(parentView, 30, nil, nil, eventManager.controllerSetIndexMenu, "menuCancel", nil)
        cancelKeyImage.hidden = true
        --cancelKeyImage.baseOffset = vec3(30,30,0)
        cancelKeyImage.relativeView = cancelButton
        buttonTable.cancelKeyImage = cancelKeyImage

        local changeAssignedSapienButton = uiStandardButton:create(cancelButton, actionUI.planStatusSize * 0.6, uiStandardButton.types.orderMarkerSmall, {
            [material.types.ui_standard.index] = material.types.ok.index,
        })
        changeAssignedSapienButton.baseOffset = vec3(actionUI.planStatusSize.x * 0.5,-actionUI.planStatusSize.y * 0.3, actionUI.planStatusSize.x * 0.01)
        buttonTable.changeAssignedSapienButton = changeAssignedSapienButton
        uiToolTip:add(changeAssignedSapienButton.userData.backgroundView, toolTipLocation.cancelRelativePosition, locale:get("ui_action_assignDifferentSapien"), nil, toolTipLocation.cancelOffset, nil, changeAssignedSapienButton)
        
        local changeAssignedSapienKeyImage = uiKeyImage:create(parentView, 30, nil, nil, eventManager.controllerSetIndexMenu, "menuSpecial", nil)
        changeAssignedSapienKeyImage.hidden = true
        changeAssignedSapienKeyImage.relativeView = changeAssignedSapienButton
        buttonTable.changeAssignedSapienKeyImage = changeAssignedSapienKeyImage
        
        local prioritizeButton = uiStandardButton:create(cancelButton, actionUI.planStatusSize * 0.6, uiStandardButton.types.orderMarkerSmall, {
            [material.types.ui_standard.index] = material.types.ok.index,
        })
        prioritizeButton.baseOffset = vec3(-actionUI.planStatusSize.x * 0.5,-actionUI.planStatusSize.y * 0.3, actionUI.planStatusSize.x * 0.01)
        buttonTable.prioritizeButton = prioritizeButton
        uiStandardButton:setIconModel(prioritizeButton, "icon_upArrow", nil)
        uiToolTip:add(prioritizeButton.userData.backgroundView, toolTipLocation.cancelRelativePosition, locale:get("ui_action_prioritize"), nil, toolTipLocation.cancelOffset, nil, prioritizeButton)
        uiToolTip:addKeyboardShortcut(prioritizeButton.userData.backgroundView, "game", "prioritize", nil, nil)

        local prioritizeKeyImage = uiKeyImage:create(parentView, 30, nil, nil, eventManager.controllerSetIndexMenu, "menuUp", nil)
        prioritizeKeyImage.hidden = true
        prioritizeKeyImage.relativeView = prioritizeButton
        buttonTable.prioritizeKeyImage = prioritizeKeyImage

        local currentOrderTextPlinth = ModelView.new(parentView)
        buttonTable.currentOrderTextPlinth = currentOrderTextPlinth
        currentOrderTextPlinth.relativeView = cancelButton
        currentOrderTextPlinth.relativePosition = toolTipLocation.cancelRelativePosition
        currentOrderTextPlinth.baseOffset = toolTipLocation.orderTextPlinthOffset
        currentOrderTextPlinth:setModel(model:modelIndexForName("ui_panel_10x2"))

        
        local currentOrderTitleTextView = TextView.new(currentOrderTextPlinth)
        buttonTable.currentOrderTitleTextView = currentOrderTitleTextView
        currentOrderTitleTextView.font = Font(uiCommon.fontName, 16)
        currentOrderTitleTextView.textAlignment = MJHorizontalAlignmentCenter
        currentOrderTitleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
        currentOrderTitleTextView.baseOffset = vec3(0,-4,0)
        currentOrderTitleTextView.text = ""

        local function cancelHoverStarted()
            currentOrderTextPlinth.hidden = true
        end
        local function cancelHoverEnded()
            if not cancelButton.hidden then
                if buttonTable.currentOrderTextPlinthShouldBeVisible then
                    currentOrderTextPlinth.hidden = false
                end
            end
        end
        
        uiStandardButton:addAdditionalHoverFunctions(cancelButton, cancelHoverStarted, cancelHoverEnded)
        
        local optionsButton = uiStandardButton:create(parentView, actionUI.planStatusSize, uiStandardButton.types.markerLike)
        optionsButton.baseOffset = vec3(buttonLocation.optionsOffset.x * actionUI.optionButtonOffsetScale, buttonLocation.optionsOffset.y * actionUI.optionButtonOffsetScale, 0)
        buttonTable.optionsButton = optionsButton
        uiToolTip:add(optionsButton.userData.backgroundView, toolTipLocation.optionsRelativePosition, locale:get("misc_settings"), nil, toolTipLocation.optionsOffset, nil, optionsButton)
        
        local optionsKeyImage = uiKeyImage:create(parentView, 30, nil, nil, eventManager.controllerSetIndexMenu, "menuOther", nil)
        optionsKeyImage.hidden = true
        --optionsKeyImage.baseOffset = vec3(30,30,0)
        optionsKeyImage.relativeView = optionsButton
        buttonTable.optionsKeyImage = optionsKeyImage

        local gameObjectView = uiGameObjectView:create(wheelSegmentView, vec2(logoHalfSize,logoHalfSize) * 2.2, uiGameObjectView.types.backgroundCircleBordered)
        --uiGameObjectView:setBackgroundAlpha(gameObjectView, 0.6)
        gameObjectView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        gameObjectView.baseOffset = vec3(buttonLocation.offset.x,buttonLocation.offset.y, 1)
        gameObjectView.hidden = true
        gameObjectView.masksEvents = false
        buttonTable.gameObjectView = gameObjectView

        local hoverOffset = 2.0
        if world.isVR then
            hoverOffset = -2.0
        end
        wheelSegment.update = uiCommon:createButtonUpdateFunction(buttonTable, wheelSegmentView, hoverOffset)
        wheelSegment.userData = buttonTable

        --[[local toolTipLocation = {
            relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter),
            offset = vec3(buttonLocation.offset.x,buttonLocation.offset.y + 40.0, 10)
        }]]

        uiToolTip:add(wheelSegment, toolTipLocation.relativePosition, "", nil, toolTipLocation.offset, nil, nil)

        return wheelSegment
    end

    for segmentCount = 1,6 do 
        actionUI.wheels[segmentCount] = {}
        actionUI.wheels[segmentCount].view = View.new(actionUI.backgroundView)
        actionUI.wheels[segmentCount].view.hidden = true
        actionUI.wheels[segmentCount].segments = {}
        actionUI.wheels[segmentCount].selectedSegment = nil
        for segmentIndex = 1,segmentCount do
            actionUI.wheels[segmentCount].segments[segmentIndex] = addWheelSegment(segmentCount, segmentIndex)
        end
    end

    

    local function addInnerSegment(addOffsetIndex)
        local modelName = innerSegmentModelNames[addOffsetIndex]

        local innerSegmentView = View.new(actionUI.backgroundView)
        innerSegmentView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        innerSegmentView.size = vec2(actionUI.iconViewHalfSize * 2, actionUI.iconViewHalfSize * 2)

        local innerSegment = ModelView.new(innerSegmentView)
        innerSegment.alpha = 0.97
        innerSegment:setModel(model:modelIndexForName(modelName), {
            default = material.types.ui_background.index
        })
        innerSegment:setUsesModelHitTest(true)
        innerSegment.scale3D = vec3(scaleToUse,scaleToUse,scaleToUse * 0.1)
        innerSegment.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        innerSegment.size = vec2(actionUI.iconViewHalfSize * 2, actionUI.iconViewHalfSize * 2)

        
        local buttonTable = {
            selected = false,
            mouseDown = false,
        }
        
        innerSegment.hoverStart = function (mouseLoc)
            if not buttonTable.hover then
                if not buttonTable.disabled then
                    buttonTable.hover = true
                    audio:playUISound(uiCommon.hoverSoundFile)
                    updateInnerSegmentVisuals(innerSegment, buttonTable)
                end
            end
        end

        innerSegment.hoverEnd = function ()
            if buttonTable.hover then
                buttonTable.hover = false
                buttonTable.mouseDown = false
                updateInnerSegmentVisuals(innerSegment, buttonTable)
            end
        end

        innerSegment.mouseDown = function (buttonIndex)
            if buttonIndex == 0 then
                if not buttonTable.mouseDown then
                    if not buttonTable.disabled then
                        buttonTable.mouseDown = true
                        updateInnerSegmentVisuals(innerSegment, buttonTable)
                        audio:playUISound(uiCommon.clickDownSoundFile)
                    end
                end
            end
        end

        innerSegment.mouseUp = function (buttonIndex)
            if (not animatingInOrOut) and buttonIndex == 0 then
                if buttonTable.mouseDown then
                    buttonTable.mouseDown = false
                    updateInnerSegmentVisuals(innerSegment, buttonTable)
                    audio:playUISound(uiCommon.clickReleaseSoundFile)
                end
                innerSegmentFunctions[addOffsetIndex]()
            end
        end

        local iconLocation = innerSegmentIconOffsets[addOffsetIndex]
        local iconModelName = innerSegmentIconNames[addOffsetIndex]
        local logoHalfSize = 20.0 * 0.5
        
        local icon = ModelView.new(innerSegmentView)
        icon.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
        icon.baseOffset = vec3(iconLocation.x,iconLocation.y, 1)
        icon.scale3D = vec3(logoHalfSize,logoHalfSize,logoHalfSize)
        icon.size = vec2(logoHalfSize,logoHalfSize) * 2.0
        icon.masksEvents = false
        buttonTable.iconModelName = iconModelName
        buttonTable.icon = icon

        local toolTipInfo = innerSegmentToolTipInfos[addOffsetIndex]
        
        uiToolTip:add(innerSegment, toolTipInfo.relativePosition, toolTipInfo.text, nil, toolTipInfo.offset, nil, nil)
        --uiToolTip:addKeyboardShortcut(innerSegment, toolTipInfo.groupKey, toolTipInfo.mappingKey, toolTipInfo.controllerSetIndex, toolTipInfo.controllerActionName)


        local keyImage = uiKeyImage:create(innerSegmentView, 15, nil, nil, eventManager.controllerSetIndexMenu, innerSegmentControllerShortcuts[addOffsetIndex], nil)
        keyImage.baseOffset = vec3(innerSegmentControllerShortcutKeyImageXOffsets[addOffsetIndex],2,0)
        keyImage.relativeView = icon
        keyImage.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)

        local hoverOffset = 2.0
        if world.isVR then
            hoverOffset = -2.0
        end
        innerSegment.update = uiCommon:createButtonUpdateFunction(buttonTable, innerSegmentView, hoverOffset)
        innerSegment.userData = buttonTable

        updateInnerSegmentVisuals(innerSegment, buttonTable)
        
        --uiToolTip:add(wheelSegment, toolTipLocation.relativePosition, "Title", nil, toolTipLocation.offset, nil, nil)


        return innerSegment
    end

    addInnerSegment(1)
    addInnerSegment(2)


    actionUIQuestView:init(gameUI_, hubUI_, world_, actionUI, mainThreadDestination)

    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, false, "radialMenuDirection", function(pos)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            return actionUI:controllerChanged(pos)
        end
        return false
    end)
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuSelect", function(isDown)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            if isDown then
                return actionUI:rightPrimaryButtonDown()
            else
                return actionUI:rightPrimaryButtonUp()
            end
        end
        return false
    end)
    
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuOther", function(isDown)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            if isDown then
                return actionUI:controllerOptionsButton()
            end
        end
        return false
    end)
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuCancel", function(isDown)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            if isDown then
                return actionUI:controllerCancel()
            end
        end
        return false
    end)
    
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuSpecial", function(isDown)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            if isDown then
                return actionUI:controllerSpecialButton()
            end
        end
        return false
    end)
    
    
    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuUp", function(isDown)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            if isDown then
                return actionUI:controllerUpButton()
            end
        end
        return false
    end)

    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuLeft", function(isDown)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            if isDown then
                actionUI:multiselectShortcut()
                return true
            end
        end
        return false
    end)

    
    eventManager:addControllerCallback(eventManager.controllerSetIndexMenu, true, "menuRight", function(isDown)
        if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
            if isDown then
                actionUI:zoomShortcut()
                return true
            end
        end
        return false
    end)

end

local hasHadControllerEventThisShow = false

function actionUI:controllerChanged(position)
    if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
        --knobView.baseOffset = vec3(actionUI.iconViewHalfSize * position.x, actionUI.iconViewHalfSize * position.y, 10.0)
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        local posLength = length2D2(position)
        if posLength < minControllerLength2 then
            
            waitingForUnselect = false
            if wheel.selectedSegment then
                wheel.selectedSegment = nil
                for segmentIndex=1,actionUI.currentWheelIndex do
                    local segment = wheel.segments[segmentIndex]
                    segment.hoverEnd()
                end
            end
        else
            if not hasHadControllerEventThisShow then
                waitingForUnselect = true
            end
            local angle = math.atan2(-position.x, position.y)
            local twoPi = (math.pi * 2.0)
            local angleRelativeToX = -angle + twoPi + math.pi * 0.5
            local fraction = ((angleRelativeToX - controllerStartAnglesForCounts[actionUI.currentWheelIndex]) % twoPi) / (math.pi * 2.0)
            local selectedIndex = math.floor(fraction * actionUI.currentWheelIndex) + 1
            wheel.selectedSegment = selectedIndex

            for segmentIndex=1,actionUI.currentWheelIndex do
                local segment = wheel.segments[segmentIndex]
                if selectedIndex == segmentIndex then
                    segment.hoverStart()
                else
                    segment.hoverEnd()
                end
            end
        end

        hasHadControllerEventThisShow = true

        return true
    end

    return false
end

function actionUI:rightPrimaryButtonDown()
    if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        if wheel.selectedSegment then
            local segment = wheel.segments[wheel.selectedSegment]
            segment.mouseDown(0)
        end
        --mj:log("actionUI:rightPrimaryButtonDown")
        return true
    end
    return false
end

function actionUI:rightPrimaryButtonUp()
    if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        if wheel.selectedSegment then
            if not waitingForUnselect then
                mj:log("mouse up")
                local segment = wheel.segments[wheel.selectedSegment]
                segment.mouseUp(0)
            end
        end
        return true
    end
    return false
end

function actionUI:controllerCancel()
    if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        if wheel.selectedSegment then
            local segment = wheel.segments[wheel.selectedSegment]
            local segmentTable = segment.userData
            if segmentTable.cancelClickFunction then
                segmentTable.cancelClickFunction()
                return true
            end
        end
    end
    return false
end

function actionUI:controllerOptionsButton()
    if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        if wheel.selectedSegment then
            local segment = wheel.segments[wheel.selectedSegment]
            local segmentTable = segment.userData
            if not segmentTable.optionsButton.hidden then
                uiStandardButton:callClickFunction(segmentTable.optionsButton)
                return true
            end
        end
    end
    return false
end

function actionUI:controllerSpecialButton()
    if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        if wheel.selectedSegment then
            local segment = wheel.segments[wheel.selectedSegment]
            local segmentTable = segment.userData
            if not segmentTable.changeAssignedSapienButton.hidden then
                uiStandardButton:callClickFunction(segmentTable.changeAssignedSapienButton)
                return true
            end
        end
    end
    return false
end

function actionUI:controllerUpButton()
    if (not actionUI.mainView.hidden) and ((not animatingInOrOut) or animatingIn) then
        local wheel = actionUI.wheels[actionUI.currentWheelIndex]
        if wheel.selectedSegment then
            local segment = wheel.segments[wheel.selectedSegment]
            local segmentTable = segment.userData
            if not segmentTable.prioritizeButton.hidden then
                uiStandardButton:callClickFunction(segmentTable.prioritizeButton)
                return true
            end
        end
    end
    return false
end

local lookAtPos = nil


local function registerStateChanges()
    deregisterStateChanges()

    if actionUI.selectedObjects then
        local objectIDs = {}
        for i,objectInfo in ipairs(actionUI.selectedObjects) do
            objectIDs[i] = objectInfo.uniqueID
        end
        --mj:log("registerStateChanges objectIDs:", objectIDs, " actionUI.selectedObjects:", actionUI.selectedObjects)
        
        logicInterface:registerFunctionForObjectStateChanges(objectIDs, logicInterface.stateChangeRegistrationGroups.actionUI, function (retrievedObjectResponse)
            --mj:log("incoming:", retrievedObjectResponse, " actionUI.selectedObjects:", actionUI.selectedObjects)
            if actionUI.selectedObjects then
                for i,object in ipairs(actionUI.selectedObjects) do
                    if object.uniqueID == retrievedObjectResponse.uniqueID then
                        --mj:log("got updated info forid:", retrievedObjectResponse.uniqueID, " name:", retrievedObjectResponse.sharedState.name, "index: ", i)
                        actionUI.selectedObjects[i] = retrievedObjectResponse
                        break
                    end
                end
            end
            --mj:log("after actionUI.selectedObjects:", actionUI.selectedObjects)
            updateButtons()
            actionUIQuestView:updateObject()
        end,
        function(removedObjectID)
            if (not actionUI.baseObject) or (not actionUI.selectedObjects) or #actionUI.selectedObjects == 1 then
                if not actionUI.mainView.hidden then
                    gameUI:hideAllUI()
                end
            else
                local newSelectedObjects = {}
                for i, objectInfo in ipairs(actionUI.selectedObjects) do
                    if objectInfo.uniqueID ~= removedObjectID then
                        table.insert(newSelectedObjects, objectInfo)
                    end
                end
                actionUI.selectedObjects = newSelectedObjects
                if removedObjectID == actionUI.baseObject.uniqueID then
                    actionUI.baseObject = actionUI.selectedObjects[1]
                end
                updateButtons()
                actionUIQuestView:updateObject()
                registerStateChanges()
                inspectUI:show(actionUI.baseObject, actionUI.selectedObjects, false)
            end
        end)
            
        currentlyRegisteredForStateChangesObjectIDs = objectIDs
    elseif actionUI.selectedVertInfos then
        
        local vertIDs = {}
        for i,vertInfo in ipairs(actionUI.selectedVertInfos) do
            vertIDs[i] = vertInfo.uniqueID
        end
        logicInterface:registerFunctionForVertStateChanges(vertIDs, logicInterface.stateChangeRegistrationGroups.actionUI, function (retrievedVertResponse)
           -- mj:log("got state change", retrievedVertResponse)
            if actionUI.baseVert and actionUI.baseVert.uniqueID == retrievedVertResponse.uniqueID then
                actionUI.baseVert = retrievedVertResponse
            end

            if actionUI.selectedVertInfos then
                for i,vertInfo in ipairs(actionUI.selectedVertInfos) do
                    if vertInfo.uniqueID == retrievedVertResponse.uniqueID then
                        --mj:log("got updated info forid:", retrievedObjectResponse.uniqueID, " name:", retrievedObjectResponse.sharedState.name, "index: ", i)
                        actionUI.selectedVertInfos[i] = retrievedVertResponse
                        break
                    end
                end
            end

            updateButtons()
            actionUIQuestView:updateObject()
        end)
        currentlyRegisteredForStateChangesVertIDs = vertIDs
    end
end


function actionUI:show()
    if ((not animatingInOrOut) or animatingIn) and (actionUI.baseObject or actionUI.baseVert) then

        hasHadControllerEventThisShow = false

        updateButtons()
        actionUIQuestView:updateObject()
        actionUI:animateIn()
        --hubUI:showInspectUI(actionUI.baseObject, actionUI.selectedObjects, false)
        registerStateChanges()
        actionUI.backgroundView.baseOffset = vec3(0.0,0.0,0.0)
    end
end

function actionUI:showObjects(baseObjectInfo_, multiSelectAllObjects, lookAtPos_)
    if (not animatingInOrOut) or animatingIn then
        actionUI.baseObject = baseObjectInfo_
        actionUI.selectedObjects = multiSelectAllObjects or {actionUI.baseObject}
        actionUI.baseVert = nil
        actionUI.selectedVertInfos = nil
        lookAtPos = lookAtPos_
        actionUI:show()
        if gameObject.types[actionUI.baseObject.objectTypeIndex].notifyServerOnTransientInspection then
            local objectIDS = {}
            for i,objectInfo in ipairs(actionUI.selectedObjects) do
                if not objectInfo.stored then
                    table.insert(objectIDS, objectInfo.uniqueID)
                end
            end
            if next(objectIDS) then
                logicInterface:callServerFunction("transientObjectsWereInspected", {
                    objectIDs = objectIDS,
                })
            end
        end
    end
end


function actionUI:showTerrain(vertInfo, multiSelectAllVerts, lookAtPos_)
    if (not animatingInOrOut) or animatingIn then
        actionUI.baseVert = vertInfo
        actionUI.selectedVertInfos = multiSelectAllVerts
        actionUI.baseObject = nil
        actionUI.selectedObjects = nil
        lookAtPos = lookAtPos_
        actionUI:show()
    end
end

function actionUI:hide()
    if not actionUI.mainView.hidden then
        actionUI.mainView.hidden = true
        manageButtonsUI:updateHiddenState()
        --menuButtonsView.hidden = true
        if vRWorldViewInfo then
            vRWorldViewInfo.view.hidden = true
        end
        animatingInOrOut = false
        animateInOutFraction = 0.0
        deregisterStateChanges()
        gameUI:updateUIHidden()
        
        --inspectUI:hideIfNeeded()
    end
end

function actionUI:animateIn()
    --[[for modeIndex,button in pairs(menuButtonsByManageUIModeType) do
        uiStandardButton:setSelected(button, false)
        uiStandardButton:resetAnimationState(button)
    end]]

    --mj:error("animateIn")

    actionUI.mainView.hidden = false
    manageButtonsUI:updateHiddenState()
    --menuButtonsView.hidden = false
    if vRWorldViewInfo then
        vRWorldViewInfo.view.hidden = false

        
        local headRayStart = world:getRealPlayerHeadPos()

        local pointerRayStart = world:getPointerRayStart()
        local pointerDirection = world:getPointerRayDirection()
        local distanceToUse = mj:mToP(3.0)
        if lookAtPos then
            local lookRay = lookAtPos - pointerRayStart
            local lookAtDistance = length(lookAtPos - pointerRayStart)
            pointerDirection = lookRay / lookAtDistance

            lookAtDistance = lookAtDistance - mj:mToP(0.5) - lookAtDistance * 0.2
            distanceToUse = mjm.clamp(lookAtDistance, mj:mToP(0.15), distanceToUse)
        end
        local uiPos = pointerRayStart + pointerDirection * distanceToUse

        --[[local uiPosNormal = normalize(uiPos)

        local downRayResult = world:rayTest(uiPos, uiPos * 0.9, nil, nil)

        if downRayResult.hasHitTerrain or downRayResult.hasHitObject then
            local collisionPoint = nil
            if downRayResult.hasHitObject and (not downRayResult.terrainIsCloserThanObject) then
                collisionPoint = downRayResult.objectCollisionPoint
            else
                collisionPoint = downRayResult.terrainCollisionPoint
            end

            local collisionDistance = length(collisionPoint - uiPos)
            local halfSizeWorld = mj:mToP(worldUIViewManager:scaleForViewAtPos(vRWorldViewInfo.uniqueID, uiPos) * actionUI.iconViewHalfSize * 0.1 + 0.1)

            if collisionDistance < halfSizeWorld then
                uiPos = collisionPoint + uiPosNormal * halfSizeWorld
            end


        end]]

        local rotationDirection = normalize(headRayStart - uiPos)

        local worldUp = normalize(headRayStart)

        local rotationMatrix = mat3LookAtInverse(rotationDirection, worldUp)


        worldUIViewManager:updateView(vRWorldViewInfo.uniqueID, uiPos, nil, nil, nil, rotationMatrix)
    end
    animatingIn = true
    actionUI.mainView:resetAnimationTimer()
    animatingInOrOut = true
    gameUI:updateUIHidden()
end

function actionUI:animateOut(animateOutAxisOrNil, animateOutCompletionFuntionOrNil)
    if (not animatingInOrOut) or animatingIn then
        animateOutAxis = animateOutAxisOrNil or vec3(0.0,-1.0,0.0)
        animatingIn = false
        animatingInOrOut = true
        actionUI.animateOutCompletionFunction = animateOutCompletionFuntionOrNil
    elseif animateOutCompletionFuntionOrNil then
        animateOutCompletionFuntionOrNil()
    end
end

function actionUI:hidden()
    return (actionUI.mainView.hidden)
end

function actionUI:isAnimatingOut()
    return animatingInOrOut and (not animatingIn)
end

function actionUI:getVRPointerIntersection(rayTestStartPos, rayDirection)
    return actionUI.mainView:getIntersection(rayTestStartPos, rayDirection)
end

function actionUI:warpForPointAndClickInteraction()
    --mj:log("actionUI:warpForPointAndClickInteraction mouseLoc:", eventManager.mouseLocUI)
    --mj:log("gameUI.view size:", gameUI.view.size)

    if not eventManager.mouseLocUI then
        return
    end

    local mainViewHalfSize = vec2(1920,1080) * 0.5
    local extraPadding = vec2(actionUI.iconViewHalfSize + 200, actionUI.iconViewHalfSize + 100)
    local maxOffset = mainViewHalfSize - extraPadding
    maxOffset = vec2(math.max(maxOffset.x, 0), math.max(maxOffset.y, 0))

    local clampedMouseLoc = vec2(mjm.clamp(eventManager.mouseLocUI.x, -maxOffset.x, maxOffset.x), mjm.clamp(eventManager.mouseLocUI.y, -maxOffset.y, maxOffset.y))

    actionUI.backgroundView.baseOffset = vec3(clampedMouseLoc.x, clampedMouseLoc.y, 0.0)

    if not (approxEqual(clampedMouseLoc.x, eventManager.mouseLocUI.x) and approxEqual(clampedMouseLoc.y, eventManager.mouseLocUI.y)) then
        eventManager:warpMouse(clampedMouseLoc)
    end
end

return actionUI