
local model = mjrequire "common/model"
local animationGroups = mjrequire "common/animations/animationGroups"
local sapienCommon = mjrequire "mainThread/animations/sapienCommon"

local mainThreadAnimationGroup = {

}

local animationTypes = animationGroups.femaleSapien.animations
mainThreadAnimationGroup.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("femaleAnimations", 1)

sapienCommon:setup(mainThreadAnimationGroup, animationTypes, 1.0)

return mainThreadAnimationGroup