--local mjm = mjrequire "common/mjm"
--local length2 = mjm.length2

local gameObject = mjrequire "common/gameObject"
--local rng = mjrequire "common/randomNumberGenerator"
local mob = mjrequire "common/mob/mob"

local serverCatfish = {}

local serverGOM = nil
--local serverWorld = nil
local serverMob = nil



local function infrequentUpdate(objectID, dt, speedMultiplier)
    mj:log("infrequentUpdate")
    serverMob:infrequentUpdate(objectID, dt, speedMultiplier)
end



function serverCatfish:init(serverGOM_, serverWorld_, serverMob_)
    serverGOM = serverGOM_
    --serverWorld = serverWorld_
    serverMob = serverMob_

    local objectTypeIndex = gameObject.types.catfish.index
    local mobSetIndex = serverGOM.objectSets.catfish

    serverGOM:addObjectLoadedFunctionForTypes({ objectTypeIndex }, function(object)
        serverGOM:addObjectToSet(object, serverGOM.objectSets.interestingToLookAt)
        serverGOM:addObjectToSet(object, mobSetIndex)
        
        serverMob:mobLoaded(object)
        return false
    end)

    serverGOM:addObjectUnloadedFunctionForTypes({objectTypeIndex}, function(object)
        serverMob:mobUnloaded(object)
    end)

    serverGOM:setInfrequentCallbackForGameObjectsInSet(mobSetIndex, "update", 5.0, infrequentUpdate) -- this needs to be called frequently enough for the walk speed to only cover 4.5 meters, or mob will pause every update. Max of 4.5/speed

    local function mobSapienProximity(objectID, sapienID, distance2, newIsClose)
        serverMob:mobSapienProximity(objectID, sapienID, distance2, newIsClose)
    end
    
    serverGOM:addProximityCallbackForGameObjectsInSet(mobSetIndex, serverGOM.objectSets.sapiens, mob.types.catfish.reactDistance, mobSapienProximity)
end

return serverCatfish