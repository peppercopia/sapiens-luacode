#extension GL_EXT_multiview : enable

#include "vertMath.vert"

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix[5];
    mat4 pMatrix[5];
    mat4 normal_matrix;
    mat4 windMatrix;
    vec4 sunPos[5];
    vec4 windDir;
} ubo;

layout(location = 0) in vec3 pos;
layout(location = 2) in vec4 normal;
layout(location = 6) in uvec2 bones;
layout(location = 7) in float boneMix;

#define MAX_BONES 16

layout(binding = 1) uniform boneUniforms {
    vec4 boneRotations[MAX_BONES];
    vec4 boneTranslations[MAX_BONES];
} boneUBO;

void main()
{
    vec3 newPos = rotate_vector(boneUBO.boneRotations[bones.x], pos + boneUBO.boneTranslations[bones.x].xyz);
    vec3 newNormal = rotate_vector(boneUBO.boneRotations[bones.x], normal.xyz);
    if(boneMix > 0.05)
    {
      vec3 newPosB = rotate_vector(boneUBO.boneRotations[bones.y], pos + boneUBO.boneTranslations[bones.y].xyz);
      newPos = mix(newPos, newPosB, boneMix);
      newNormal = normalize(mix(newNormal, rotate_vector(boneUBO.boneRotations[bones.y], normal.xyz), boneMix));
    }
    
    newNormal = (ubo.normal_matrix * vec4(newNormal, 1.0)).xyz;
    //vec3 newSunPos = rotate_vector(boneRotations[bone], sunPos);
    vec3 newSunPos = (inverse(ubo.normal_matrix) * vec4(ubo.sunPos[gl_ViewIndex].xyz, 1.0)).xyz;
   // gl_Position = pMatrix * mvMatrix * vec4(newPos - sunPos * 0.001 + newNormal * 0.001 * (dot(newNormal, sunPos)), 1.0);
    gl_Position = ubo.pMatrix[gl_ViewIndex] * ubo.mvMatrix[gl_ViewIndex] * vec4(newPos - newSunPos * 0.001 - newNormal * 0.0001, 1.0);
}
