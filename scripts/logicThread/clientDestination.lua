

local clientDestination = {}

local knownDestinations = {}
local logic = nil
local terrain = nil

function clientDestination:setLogic(logic_)
    logic = logic_
end

function clientDestination:setTerrain(terrain_)
    terrain = terrain_
end

function clientDestination:reset()
    knownDestinations = {}
end

function clientDestination:addDestinationInfos(destinationInfos)
    for i,destinationInfo in ipairs(destinationInfos) do
        --mj:log("clientDestination:addDestinationInfo:", destinationInfo)
        local destinationID = destinationInfo.destinationID
        if not knownDestinations[destinationID] then
            if (not destinationInfo.pos) and destinationInfo.normalizedPos then
                destinationInfo.pos = terrain:getHighestDetailTerrainPointAtPoint(destinationInfo.normalizedPos) --probably not needed anymore
            end
            if destinationInfo.pos then
                logic:callMainThreadFunction("addDestination", destinationInfo)
                knownDestinations[destinationID] = true
            end
        end
    end
end


function clientDestination:updateDestination(destinationInfo)
    if knownDestinations[destinationInfo.destinationID] then
        --mj:log("update destination:", destinationInfo)
        logic:callMainThreadFunction("updateDestination", destinationInfo)
    else
        --mj:log("update destination adding:", destinationInfo)
        clientDestination:addDestinationInfos({destinationInfo})
    end
end

function clientDestination:updateDestinationTribeCenters(tribeCentersInfo)
    if knownDestinations[tribeCentersInfo.destinationID] then
        logic:callMainThreadFunction("updateDestinationTribeCenters", tribeCentersInfo)
    end
end

function clientDestination:updateDestinationRelationship(relationshipInfo)
    if knownDestinations[relationshipInfo.destinationID] then
        logic:callMainThreadFunction("updateDestinationRelationship", relationshipInfo)
    end
end

function clientDestination:updateDestinationTradeables(info)
    if knownDestinations[info.destinationID] then
        logic:callMainThreadFunction("updateDestinationTradeables", info)
    end
end

function clientDestination:updateDestinationPlayerOnlineStatus(info)
    if knownDestinations[info.destinationID] then
        logic:callMainThreadFunction("updateDestinationPlayerOnlineStatus", info)
    end
end



return clientDestination