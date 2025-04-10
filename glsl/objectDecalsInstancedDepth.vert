#include "wind.vert"


layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 normal_matrix;
    mat4 windMatrix;
    mat4 shadow_matrices[4];
    mat4 waterDepthOrthoMatrix;
    vec4 camPos;
    vec4 sunPosAnimationTimer;
    vec4 origin;
    vec4 translation;
    vec4 extraData;
    vec4 windDir;
} ubo;

layout( push_constant ) uniform WindStrengthBlock {
  vec4 windStrength;
} pc;


layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec3 texCoord;
layout(location = 2) in vec3 decalLocalOrigin;
layout(location = 3) in vec4 normal;
layout(location = 4) in vec4 tangent;
layout(location = 5) in vec4 faceNormal;
layout(location = 6) in uvec4 material;
layout(location = 7) in uvec4 materialB;

layout(location = 8) in vec4 instancePosScale;
layout(location = 9) in vec4 instanceRot;
layout (location = 10) in vec4 instanceOffset;
layout (location = 11) in vec4 instanceExtraData;

layout(location = 0) out vec4 outView;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outTexCoord;

invariant gl_Position;

void main(void)
{
    vec3 newPos = rotate_vector(instanceRot, pos * instancePosScale.w);
    vec3 newNormal = rotate_vector(instanceRot, faceNormal.xyz);
    vec3 windNormal = newNormal;

    vec3 windPos;
    if(instanceExtraData.w > 0.5)
    {
        windPos = getFloatingObjectWavePos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, ubo.sunPosAnimationTimer.w) - instanceOffset.xyz;
    }
    else
    {
        windPos = getWindPos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, pos.y + instanceOffset.w, ubo.sunPosAnimationTimer.w, newNormal, (1.0 - pc.windStrength.x) * 0.1 * pc.windStrength.z, pc.windStrength.z) - instanceOffset.xyz;
    }

    //vec3 windPos = getWindPos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, pos.y + instanceOffset.w, ubo.sunPosAnimationTimer.w, newNormal, (1.0 - pc.windStrength.x) * 0.1 * pc.windStrength.z, pc.windStrength.z) - instanceOffset.xyz;
    windPos = getDecalWindPos(ubo.windMatrix, ubo.windDir.xy, windPos - decalLocalOrigin * texCoord.z, decalLocalOrigin * texCoord.z + instancePosScale.xyz,  pos.y, ubo.sunPosAnimationTimer.w, windNormal, 0.001 * texCoord.z * (1.0 - pc.windStrength.y), pc.windStrength.z);
    windPos = windPos + instancePosScale.xyz + decalLocalOrigin * texCoord.z;
    
    vec4 V = camera.worldView * ubo.mv_matrix * vec4(windPos.xyz, 1.0);
    gl_Position = camera.proj * V;

    outTexCoord = texCoord;
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(windPos, 1.0)).xyz;
    
    outNormal = (ubo.normal_matrix * vec4(windNormal, 1.0)).xyz;
    //outView.xyz = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - ubo.translation.xyz - rotatedPosition.xyz;
    outView.xyz = ubo.camPos.xyz - (ubo.translation.xyz + rotatedPosition.xyz);
    
    vec4 waterDepth = ubo.waterDepthOrthoMatrix * vec4((rotatedPosition.xyz + ubo.translation.xyz), 1.0);
    outView.w = -waterDepth.z + ubo.origin.w;
}
