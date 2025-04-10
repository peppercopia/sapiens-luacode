
#include "wind.vert"

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix;
    mat4 pMatrix;
    mat4 windMatrix;
    vec4 sunPosAnimationTimer;
    vec4 windDir;
} ubo;

layout( push_constant ) uniform WindStrengthBlock {
  vec4 windStrength;
} pc;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 normal;
layout(location = 3) in vec4 tangent;
layout(location = 4) in uvec4 material;
layout(location = 5) in uvec4 materialB;

layout (location = 6) in vec4 instancePosScale;
layout (location = 7) in vec4 instanceRot;
layout (location = 8) in vec4 instanceOffset;
layout (location = 9) in vec4 instanceExtraData;

void main()
{
    vec3 newPos = rotate_vector(instanceRot, pos * instancePosScale.w);
    vec3 newNormal = rotate_vector(instanceRot, normal.xyz);
    //vec3 windPos = getWindPos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, pos.y + instanceOffset.w, ubo.sunPosAnimationTimer.w, newNormal, (1.0 - pc.windStrength.x) * 0.1 * pc.windStrength.z, pc.windStrength.z) + instancePosScale.xyz - instanceOffset.xyz;

    vec3 windPos;
    if(instanceExtraData.w > 0.5)
    {
        windPos = getFloatingObjectWavePos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, ubo.sunPosAnimationTimer.w) + instancePosScale.xyz - instanceOffset.xyz;
    }
    else
    {
        windPos = getWindPos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, pos.y + instanceOffset.w, ubo.sunPosAnimationTimer.w, newNormal, (1.0 - pc.windStrength.x) * 0.1 * pc.windStrength.z, pc.windStrength.z) + instancePosScale.xyz - instanceOffset.xyz;
    }

    gl_Position = ubo.pMatrix * ubo.mvMatrix * vec4(windPos.xyz - ubo.sunPosAnimationTimer.xyz * 0.0000001, 1.0);
}
