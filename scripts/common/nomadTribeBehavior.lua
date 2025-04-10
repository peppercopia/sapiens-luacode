
local typeMaps = mjrequire "common/typeMaps"
local locale = mjrequire "common/locale"

local nomadTribeBehavior = {

}


nomadTribeBehavior.types = typeMaps:createMap("nomadTribeBehavior", {
    {
        key = "foodRaid",
        name = locale:get("nomadTribeBehavior_foodRaid_name"),
        recruitModifier = -1,
        ignoreNeeds = true,  --todo this is not good enough, need some kind of adrenaline/stress based system or something. In particular if this sapien is trapped, they will never sleep
    },
    {
        key = "friendlyVisit",
        name = locale:get("nomadTribeBehavior_friendlyVisit_name"),
    },
    {
        key = "cautiousVisit",
        name = locale:get("nomadTribeBehavior_cautiousVisit_name"),
    },
    {
        key = "join",
        name = locale:get("nomadTribeBehavior_join_name"),
        recruitModifier = 1,
    },
    {
        key = "passThrough",
        name = locale:get("nomadTribeBehavior_passThrough_name"),
    },
    {
        key = "leave",
        name = locale:get("nomadTribeBehavior_leave_name"),
    },
})


nomadTribeBehavior.validTypes = typeMaps:createValidTypesArray("nomadTribeBehavior", nomadTribeBehavior.types)

return nomadTribeBehavior