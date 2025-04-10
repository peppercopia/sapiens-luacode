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

layout(binding = 16) uniform boneUniforms {
    vec4 boneRotations[MAX_BONES];
    vec4 boneTranslations[MAX_BONES];
} boneUBO;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 normal;
layout(location = 3) in vec4 tangent;
layout(location = 4) in uvec4 material;
layout(location = 5) in uvec4 materialB;
layout(location = 6) in uvec2 bones;
layout(location = 7) in float boneMix;

layout(location = 0) out vec3 outPos;
layout(location = 1) out vec4 outWorldPos;
layout(location = 2) out vec3 outWorldCamPos;
layout(location = 3) out vec3 outColor;
layout(location = 4) out vec4 outMaterialUV;
layout(location = 5) out vec3 outView;
layout(location = 6) out vec3 outNormal;
layout(location = 7) out vec3 outWorldViewVec;
layout(location = 8) out vec4 outShadowCoords[4];
layout(location = 12) out vec4 outInstanceExtraData;
layout(location = 13) out vec3 outColorB;
layout(location = 14) out vec2 outMaterialB;
layout(location = 15) out vec3 outTangent;

out gl_PerVertex {
    vec4 gl_Position;
};

invariant gl_Position;

void main(void)
{
    vec3 newPos = rotate_vector(boneUBO.boneRotations[bones.x], pos + boneUBO.boneTranslations[bones.x].xyz);
    vec3 newNormal = rotate_vector(boneUBO.boneRotations[bones.x], normal.xyz);
    vec3 newTangent = rotate_vector(boneUBO.boneRotations[bones.x], tangent.xyz);
    if(boneMix > 0.05)
    {
      vec3 newPosB = rotate_vector(boneUBO.boneRotations[bones.y], pos + boneUBO.boneTranslations[bones.y].xyz);
      newPos = mix(newPos, newPosB, boneMix);
      newNormal = normalize(mix(newNormal, rotate_vector(boneUBO.boneRotations[bones.y], normal.xyz), boneMix));
      newTangent = normalize(mix(newTangent, rotate_vector(boneUBO.boneRotations[bones.y], tangent.xyz), boneMix));
    }

    vec4 V = camera.worldView * ubo.mv_matrix * vec4(newPos.xyz, 1.0);
    gl_Position = camera.proj * V;

    outInstanceExtraData = ubo.extraData;
    
    vec4 rotatedPosition = (ubo.normal_matrix * vec4(newPos.xyz, 1.0));
    
    outColor = material.xyz / 255.0;
    outColorB = materialB.xyz / 255.0;
    //outColor = outColor * outColor;
    //outColorB = outColorB * outColorB;
    if(material.w > 127)
    {
      outMaterialUV.xy = vec2((material.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialUV.xy = vec2(material.w / 127.0, 0.0);
    }
    if(materialB.w > 127)
    {
      outMaterialB = vec2((materialB.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialB = vec2(materialB.w / 127.0, 0.0);
    }

    outMaterialUV.zw = uv;

    outNormal = normalize((ubo.normal_matrix * vec4(newNormal.xyz, 1.0)).xyz);
    outTangent = normalize((ubo.normal_matrix * vec4(newTangent.xyz, 1.0)).xyz);
    //outView = (ubo.mv_matrix * camera.camOffsetPosWorld).xyz - ubo.translation.xyz - rotatedPosition.xyz;
    //outView = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - ubo.translation.xyz - rotatedPosition.xyz;
    outView = ubo.camPos.xyz - (ubo.translation.xyz + rotatedPosition.xyz);
    
    outPos = rotatedPosition.xyz + ubo.translation.xyz;
    outWorldPos.xyz = (rotatedPosition.xyz + ubo.translation.xyz + ubo.origin.xyz) * 8.388608;
    outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (outWorldPos.xyz - outWorldCamPos);//(rotatedPosition.xyz - camPos.xyz) * 8.388608;
    
    vec4 waterDepth = ubo.waterDepthOrthoMatrix * vec4((rotatedPosition.xyz + ubo.translation.xyz), 1.0);
    outWorldPos.w = -waterDepth.z + ubo.origin.w;
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(rotatedPosition.xyz + ubo.translation.xyz, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(rotatedPosition.xyz + ubo.translation.xyz, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(rotatedPosition.xyz + ubo.translation.xyz, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(rotatedPosition.xyz + ubo.translation.xyz, 1.0);

   // setupWorldCommon();
    
}
