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
    vec3 newPos = rotate_vector(instanceRot, pos * instancePosScale.w);
    vec3 newNormal = rotate_vector(instanceRot, normal.xyz);
    vec3 windNormal = newNormal;
    outTangent = normalize((ubo.normal_matrix * vec4(rotate_vector(instanceRot, tangent.xyz), 1.0)).xyz);
    
    vec3 windPos;
    if(instanceExtraData.w > 0.5)
    {
        windPos = getFloatingObjectWavePos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, ubo.sunPosAnimationTimer.w) - instanceOffset.xyz;
    }
    else
    {
        windPos = getWindPos(ubo.windMatrix, ubo.windDir.xy, newPos + instanceOffset.xyz, instancePosScale.xyz - instanceOffset.xyz, pos.y + instanceOffset.w, ubo.sunPosAnimationTimer.w, newNormal, (1.0 - pc.windStrength.x) * 0.1 * pc.windStrength.z, pc.windStrength.z) - instanceOffset.xyz;
    }

    windPos = getDecalWindPos(ubo.windMatrix, ubo.windDir.xy, windPos - decalLocalOrigin * texCoord.z, decalLocalOrigin * texCoord.z + instancePosScale.xyz,  pos.y, ubo.sunPosAnimationTimer.w, windNormal,  0.001 * texCoord.z * (1.0 - pc.windStrength.y), pc.windStrength.z);
    windPos = windPos + instancePosScale.xyz + decalLocalOrigin * texCoord.z;
    
    vec4 V = camera.worldView * ubo.mv_matrix * vec4(windPos.xyz, 1.0);
    gl_Position = camera.proj * V;

    outTexCoord = texCoord;
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(windPos, 1.0)).xyz;
    
    
    outColor = material.xyz / 255.0;
    outColorB = materialB.xyz / 255.0;
    //outColor = outColor + vec3(0.5,0.5,0.8) * instanceExtraData.x;
    //outColor = outColor * outColor;
    //outColorB = outColorB * outColorB;

    outInstanceExtraData = instanceExtraData;

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

    //outColor = mix(matUbo.matColors[material].xyz, matUbo.matColors[material].xyz * 1.02, (texCoord.z));
    //outMaterial = vec2(matUbo.matProperties[material].x * (1.0 - texCoord.z * 0.02), matUbo.matProperties[material].y);
    outNormal = (ubo.normal_matrix * vec4(windNormal, 1.0)).xyz;
   // outView = ubo.camPos.xyz - ubo.translation.xyz - rotatedPosition;
    //outView = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - ubo.translation.xyz - rotatedPosition.xyz;
    outView.xyz = ubo.camPos.xyz - (ubo.translation.xyz + rotatedPosition.xyz);

    outPos = rotatedPosition.xyz + ubo.translation.xyz;
    
    outWorldPos.xyz = (rotatedPosition.xyz + ubo.translation.xyz + ubo.origin.xyz) * 8.388608;
    outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (outWorldPos.xyz - outWorldCamPos);//(rotatedPosition.xyz - camPos.xyz) * 8.388608;
    
    vec4 waterDepth = ubo.waterDepthOrthoMatrix * vec4((rotatedPosition.xyz + ubo.translation.xyz), 1.0);
    outWorldPos.w = -waterDepth.z + ubo.origin.w;
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(rotatedPosition + ubo.translation.xyz, 1.0);

    
}