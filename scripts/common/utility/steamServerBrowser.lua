local steamServerBrowser = {}

local bridge = nil

function steamServerBrowser:refreshInternetServers(callback) --callback is called multiple times with results, last callback will have no result. Be careful, could show up very late!
    bridge:refreshInternetServers(callback)
end

function steamServerBrowser:refreshLANServers(callback)
    bridge:refreshLANServers(callback)
end

function steamServerBrowser:setBridge(bridge_)
    bridge = bridge_
end

return steamServerBrowser