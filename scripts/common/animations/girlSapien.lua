local sapienCommon = mjrequire "common/animations/sapienCommon"
local model = mjrequire "common/model"

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("childAnimations", 1)

sapienCommon:setup(animationInfo, 1.2)


function animationInfo:initMainThread()
    
end

return animationInfo