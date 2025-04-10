--local mjm = mjrequire "common/mjm"
--local length2 = mjm.length2

local gameObject = mjrequire "common/gameObject"
--local rng = mjrequire "common/randomNumberGenerator"
local mob = mjrequire "common/mob/mob"

local serverChicken = {}

local serverGOM = nil
--local serverWorld = nil
local serverMob = nil


local function infrequentUpdate(objectID, dt, speedMultiplier)
    serverMob:infrequentUpdate(objectID, dt, speedMultiplier)
end


local function chickenSapienProximity(objectID, sapienID, distance2, newIsClose)
    serverMob:mobSapienProximity(objectID, sapienID, distance2, newIsClose)
end

function serverChicken:init(serverGOM_, serverWorld_, serverMob_)
    serverGOM = serverGOM_
    --serverWorld = serverWorld_
    serverMob = serverMob_

    serverGOM:addObjectLoadedFunctionForTypes({ gameObject.types.chicken.index }, function(object)
        --mj:log("serverChicken:init a:", anchor.types.mob.index)
        serverGOM:addObjectToSet(object, serverGOM.objectSets.interestingToLookAt)
        serverGOM:addObjectToSet(object, serverGOM.objectSets.chickens)
        
        serverMob:mobLoaded(object)
        --mj:log("serverChicken:init b")
        return false
    end)


    serverGOM:addObjectUnloadedFunctionForTypes({gameObject.types.chicken.index}, function(object)
        serverMob:mobUnloaded(object)
    end)
    
    local reactDistance = mob.types.chicken.reactDistance
    
    serverGOM:setInfrequentCallbackForGameObjectsInSet(serverGOM.objectSets.chickens, "update", 5.0, infrequentUpdate)-- this needs to be called frequently enough for the walk speed to only cover 4.5 meters, or mob will pause every update. Max of 4.5/speed
    serverGOM:addProximityCallbackForGameObjectsInSet(serverGOM.objectSets.chickens, serverGOM.objectSets.sapiens, reactDistance, chickenSapienProximity)
end

return serverChicken