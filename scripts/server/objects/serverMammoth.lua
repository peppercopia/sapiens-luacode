--local mjm = mjrequire "common/mjm"
--local normalize = mjm.normalize
--local vec3 = mjm.vec3
--local length = mjm.length
--local length2 = mjm.length2
--local mix = mjm.mix
--local cross = mjm.cross
--local mat3Rotate = mjm.mat3Rotate
--local mat3LookAtInverse = mjm.mat3LookAtInverse

local gameObject = mjrequire "common/gameObject"
local mob = mjrequire "common/mob/mob"

local serverMammoth = {}

local serverGOM = nil
--local serverWorld = nil
local serverMob = nil


local function infrequentUpdate(objectID, dt, speedMultiplier)
    serverMob:infrequentUpdate(objectID, dt, speedMultiplier)
end

local function mammothSapienProximity(objectID, sapienID, distance2, newIsClose)
    serverMob:mobSapienProximity(objectID, sapienID, distance2, newIsClose)
end

function serverMammoth:init(serverGOM_, serverWorld_, serverMob_)
    serverGOM = serverGOM_
    serverMob = serverMob_

    serverGOM:addObjectLoadedFunctionForTypes({ gameObject.types.mammoth.index }, function(object)
        serverGOM:addObjectToSet(object, serverGOM.objectSets.interestingToLookAt)
        serverGOM:addObjectToSet(object, serverGOM.objectSets.mammoths)

        serverMob:mobLoaded(object)
        return false
    end)

    serverGOM:addObjectUnloadedFunctionForTypes({gameObject.types.mammoth.index}, function(object)
        serverMob:mobUnloaded(object)
    end)
    
    local reactDistance = mob.types.mammoth.reactDistance

    serverGOM:setInfrequentCallbackForGameObjectsInSet(serverGOM.objectSets.mammoths, "update", 2.0, infrequentUpdate) -- this needs to be called frequently enough for the walk speed to only cover 4.5 meters, or mob will pause every update. Max of 4.5/speed
    serverGOM:addProximityCallbackForGameObjectsInSet(serverGOM.objectSets.mammoths, serverGOM.objectSets.sapiens, reactDistance, mammothSapienProximity)
end

return serverMammoth