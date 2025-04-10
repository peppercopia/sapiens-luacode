
local model = mjrequire "common/model"
local animationGroups = mjrequire "common/animations/animationGroups"
local sapienCommon = mjrequire "mainThread/animations/sapienCommon"

local mainThreadAnimationGroup = {

}

local animationTypes = animationGroups.boySapien.animations
mainThreadAnimationGroup.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("childAnimations", 1)

sapienCommon:setup(mainThreadAnimationGroup, animationTypes, 1.2)

return mainThreadAnimationGroup