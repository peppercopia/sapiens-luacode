
#include "vertMath.vert"

layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 normal_matrix;
    mat4 windMatrix;
    mat4 shadow_matrices[4];
    mat4 waterDepthOrthoMatrix;
    vec4 camPos;
    vec4 sunPos;
    vec4 origin;
    vec4 translation;
    vec4 extraData;
    vec4 windDir;
} ubo;


layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

#define MAX_BONES 16

layout(binding = 3) uniform boneUniforms {
    vec4 boneRotations[MAX_BONES];
    vec4 boneTranslations[MAX_BONES];
} boneUBO;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec3 texCoord;
layout(location = 2) in vec3 decalLocalOrigin;
layout(location = 3) in vec4 normal;
layout(location = 4) in vec4 tangent;
layout(location = 5) in vec4 faceNormal;
layout(location = 6) in uvec4 material;
layout(location = 7) in uvec4 materialB;
layout(location = 8) in uvec2 bones;
layout(location = 9) in float boneMix;

layout(location = 0) out vec4 outView;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outTexCoord;

invariant gl_Position;

void main(void)
{

    vec3 newPos = rotate_vector(boneUBO.boneRotations[bones.x], pos + boneUBO.boneTranslations[bones.x].xyz);
    vec3 newNormal = rotate_vector(boneUBO.boneRotations[bones.x], faceNormal.xyz);
    if(boneMix > 0.05)
    {
      vec3 newPosB = rotate_vector(boneUBO.boneRotations[bones.y], pos + boneUBO.boneTranslations[bones.y].xyz);
      newPos = mix(newPos, newPosB, boneMix);
      newNormal = normalize(mix(newNormal, rotate_vector(boneUBO.boneRotations[bones.y], faceNormal.xyz), boneMix));
    }

    /*vec3 newPos = rotate_vector(boneUBO.boneRotations[bone], pos) + boneUBO.boneTranslations[bone].xyz;
    vec3 newNormal = normalize(rotate_vector(boneUBO.boneRotations[bone], faceNormal.xyz));*/

    vec4 V = camera.worldView * ubo.mv_matrix * vec4(newPos.xyz, 1.0);
    gl_Position = camera.proj * V;

    outTexCoord = texCoord;
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(newPos, 1.0)).xyz;
    
    outNormal = (ubo.normal_matrix * vec4(newNormal.xyz, 1.0)).xyz;
    outView.xyz = ubo.camPos.xyz - (ubo.translation.xyz + rotatedPosition.xyz);
    
    
    /*vec3 outWorldPos = (rotatedPosition.xyz + ubo.translation.xyz + ubo.origin.xyz) * 8.388608;
    vec3 outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    vec3 outWorldViewVec = (outWorldPos.xyz - outWorldCamPos);//(rotatedPosition.xyz - camPos.xyz) * 8.388608;
    outView.xyz = -outWorldViewVec;*/
    
    vec4 waterDepth = ubo.waterDepthOrthoMatrix * vec4((rotatedPosition.xyz + ubo.translation.xyz), 1.0);
    outView.w = -waterDepth.z + ubo.origin.w;
}
