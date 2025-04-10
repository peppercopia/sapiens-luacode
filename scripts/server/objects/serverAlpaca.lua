--local mjm = mjrequire "common/mjm"
--local length2 = mjm.length2

local gameObject = mjrequire "common/gameObject"
--local rng = mjrequire "common/randomNumberGenerator"
local mob = mjrequire "common/mob/mob"

local serverAlpaca = {}

local serverGOM = nil
--local serverWorld = nil
local serverMob = nil



local function infrequentUpdate(objectID, dt, speedMultiplier)
    serverMob:infrequentUpdate(objectID, dt, speedMultiplier)
end




function serverAlpaca:init(serverGOM_, serverWorld_, serverMob_)
    serverGOM = serverGOM_
    --serverWorld = serverWorld_
    serverMob = serverMob_

    serverGOM:addObjectLoadedFunctionForTypes({ gameObject.types.alpaca.index }, function(object)
        --mj:log("serverAlpaca:init a:", anchor.types.mob.index)
        serverGOM:addObjectToSet(object, serverGOM.objectSets.interestingToLookAt)
        serverGOM:addObjectToSet(object, serverGOM.objectSets.alpacas)
        
        serverMob:mobLoaded(object)
        --mj:log("serverAlpaca:init b")
        return false
    end)

    serverGOM:addObjectUnloadedFunctionForTypes({gameObject.types.alpaca.index}, function(object)
        serverMob:mobUnloaded(object)
    end)

    serverGOM:setInfrequentCallbackForGameObjectsInSet(serverGOM.objectSets.alpacas, "update", 5.0, infrequentUpdate) -- this needs to be called frequently enough for the walk speed to only cover 4.5 meters, or mob will pause every update. Max of 4.5/speed

    local function alpacaSapienProximity(objectID, sapienID, distance2, newIsClose)
        serverMob:mobSapienProximity(objectID, sapienID, distance2, newIsClose)
    end
    serverGOM:addProximityCallbackForGameObjectsInSet(serverGOM.objectSets.alpacas, serverGOM.objectSets.sapiens, mob.types.alpaca.reactDistance, alpacaSapienProximity)
end

return serverAlpaca