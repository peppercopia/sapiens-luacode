
layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix;
    mat4 pMatrix;
    mat4 windMatrix;
    vec4 sunPosAnimationTimer;
    vec4 windDir;
} ubo;

layout(location = 0) in vec3 pos;
layout(location = 2) in vec4 normal;
layout(location = 6) in uvec2 bones;
layout(location = 7) in float boneMix;

vec3 rotate_vector( vec4 quat, vec3 vec )
{
    return vec + 2.0 * cross( cross( vec, quat.xyz ) + quat.w * vec, quat.xyz );
}

#define MAX_BONES 16

layout(binding = 1) uniform boneUniforms {
    vec4 boneRotations[MAX_BONES];
    vec4 boneTranslations[MAX_BONES];
} boneUBO;

void main()
{
    
    vec3 newPos = rotate_vector(boneUBO.boneRotations[bones.x], pos + boneUBO.boneTranslations[bones.x].xyz);
    if(boneMix > 0.05)
    {
      vec3 newPosB = rotate_vector(boneUBO.boneRotations[bones.y], pos + boneUBO.boneTranslations[bones.y].xyz);
      newPos = mix(newPos, newPosB, boneMix);
    }
    
    
    gl_Position = ubo.pMatrix * ubo.mvMatrix * vec4(newPos, 1.0);
}
