local worldConfig = mjrequire "common/worldConfig"

local serverWorldSettings = {}

function serverWorldSettings:set(key,value)
    worldConfig.configData[key] = value
    worldConfig:save()
end

function serverWorldSettings:get(key)
    return worldConfig.configData[key]
end

function serverWorldSettings:clientSet(clientID, key, value)
    --todo ensure client has admin permission
    serverWorldSettings:set(key,value)
end


function serverWorldSettings:clientGetAll(clientID)
    return worldConfig.configData
end

return serverWorldSettings