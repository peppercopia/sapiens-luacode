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

layout(binding = 17) uniform boneUniforms {
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

layout(location = 0) out vec3 outPos;
layout(location = 1) out vec4 outWorldPos;
layout(location = 2) out vec3 outWorldCamPos;
layout(location = 3) out vec3 outColor;
layout(location = 4) out vec2 outMaterial;
layout(location = 5) out vec3 outView;
layout(location = 6) out vec3 outNormal;
layout(location = 7) out vec3 outWorldViewVec;
layout(location = 8) out vec4 outShadowCoords[4];
layout(location = 12) out vec4 outInstanceExtraData;

layout(location = 13) out vec3 outTexCoord;
layout(location = 14) out vec3 outTangent;
layout(location = 15) out vec3 outColorB;
layout(location = 16) out vec2 outMaterialB;

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
      vec3 newTangentB = rotate_vector(boneUBO.boneRotations[bones.y], tangent.xyz);
      newTangent = normalize(mix(newTangent, newTangentB, boneMix));
    }

    /*vec3 newPosA = rotate_vector(boneUBO.boneRotations[bones.x], pos + boneUBO.boneTranslations[bones.x].xyz);
    vec3 newPosB = rotate_vector(boneUBO.boneRotations[bones.y], pos + boneUBO.boneTranslations[bones.y].xyz);
    vec3 newPos = mix(newPosA, newPosB, boneMix);
    
    vec3 newNormalA = rotate_vector(boneUBO.boneRotations[bones.x], normal.xyz);
    vec3 newNormalB = rotate_vector(boneUBO.boneRotations[bones.y], normal.xyz);
    vec3 newNormal = normalize(mix(newNormalA, newNormalB, boneMix));
    
    vec3 newFaceNormalA = rotate_vector(boneUBO.boneRotations[bones.x], normal.xyz);
    vec3 newFaceNormalB = rotate_vector(boneUBO.boneRotations[bones.y], normal.xyz);
    vec3 newFaceNormal = normalize(mix(newFaceNormalA, newFaceNormalB, boneMix));*/

    //vec4 V = camera.worldView * ubo.mv_matrix * vec4(pos.xyz + decalLocalOrigin * texCoord.z, 1.0);
    vec4 V = camera.worldView * ubo.mv_matrix * vec4(newPos.xyz, 1.0);
    gl_Position = camera.proj * V;

    outTexCoord = texCoord;
    outTangent = (ubo.normal_matrix * vec4(newTangent.xyz, 1.0)).xyz;
  
    outInstanceExtraData = ubo.extraData;
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(newPos, 1.0)).xyz;
    
    outColor = material.xyz / 255.0;
    outColorB = materialB.xyz / 255.0;
    //outColor = outColor * outColor;
    //outColorB = outColorB * outColorB;
    if(material.w > 127)
    {
      outMaterial = vec2((material.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterial = vec2(material.w / 127.0, 0.0);
    }
    if(materialB.w > 127)
    {
      outMaterialB = vec2((materialB.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialB = vec2(materialB.w / 127.0, 0.0);
    }
    
    outNormal = (ubo.normal_matrix * vec4(newNormal.xyz, 1.0)).xyz;
    //outView = ubo.camPos.xyz - ubo.translation.xyz - rotatedPosition;
    outView = (ubo.camPos.xyz) - (ubo.translation.xyz + rotatedPosition.xyz);
    //outView.xyz = (ubo.normal_matrix * vec4((camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - ubo.translation.xyz - rotatedPosition.xyz, 1.0)).xyz;

    float baseNDotL = dot( outNormal, ubo.sunPos.xyz );


    /*if(dot(outNormal, outView) < 0)
    {
        if(baseNDotL < 0)
        {
            baseNDotL = -baseNDotL;
        outNormal = -outNormal;
        }
    }*/

    outPos = rotatedPosition.xyz + ubo.translation.xyz;
    
    outWorldPos.xyz = (rotatedPosition.xyz + ubo.translation.xyz + ubo.origin.xyz) * 8.388608;
    outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (outWorldPos.xyz - outWorldCamPos);//(rotatedPosition.xyz - camPos.xyz) * 8.388608;
    
    //outWorldPos.w = -(length(rotatedPosition.xyz + ubo.translation.xyz + ubo.origin.xyz) - 100000.0);
    vec4 waterDepth = ubo.waterDepthOrthoMatrix * vec4((rotatedPosition.xyz + ubo.translation.xyz), 1.0);
    outWorldPos.w = -waterDepth.z + ubo.origin.w;
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);

}
