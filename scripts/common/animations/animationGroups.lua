local animationGroups = {}

animationGroups.groupNames = {
    "maleSapien",
    "femaleSapien",
    "girlSapien",
    "boySapien",
    "chicken",
    "alpaca",
    "mammoth",
    "catfish",
}

function animationGroups:mjInit()
    for i,name in ipairs(animationGroups.groupNames) do
        local animations = mjrequire("common/animations/" .. name)
        local element = {
            key = name,
            animations = animations
        }
        mj:insertIndexed(animationGroups, element)
    end
end

return animationGroups