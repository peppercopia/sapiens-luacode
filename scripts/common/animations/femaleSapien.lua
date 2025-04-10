local sapienCommon = mjrequire "common/animations/sapienCommon"
local model = mjrequire "common/model"

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("femaleAnimations", 1)

sapienCommon:setup(animationInfo, 1.0)

function animationInfo:initMainThread()
    
end

return animationInfo