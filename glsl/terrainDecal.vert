#include "wind.vert"

layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 shadow_matrices[4];
    mat4 windMatrix;
    vec4 camPosDecalRenderDistance;
    vec4 sunPosAnimationTimer;
    vec4 originWindStrength;
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

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 centerPos;
layout(location = 2) in vec4 stst;
layout(location = 3) in vec4 normal;
layout(location = 4) in vec4 forwardNormal;
layout(location = 5) in uvec4 materialsA;
layout(location = 6) in uvec4 materialsB;
layout(location = 7) in uvec4 materialsC;
layout(location = 8) in uvec4 materialsD;

layout(location = 0) out vec3 outPos;
layout(location = 1) out vec3 outWorldPos;
layout(location = 2) out vec3 outWorldCamPos;
layout(location = 3) out vec3 outView;
layout(location = 4) out vec3 outNormal;
layout(location = 5) out vec3 outWorldViewVec;
layout(location = 6) out vec4 outShadowCoords[4];

layout(location = 10) out vec4 outTex;
layout(location = 11) out float alpha;

layout(location = 12) out vec2 outMaterialA;
layout(location = 13) out vec2 outMaterialB;
layout(location = 14) out vec2 outMaterialC;
layout(location = 15) out vec2 outMaterialD;

layout(location = 16) out vec3 outColorA;
layout(location = 17) out vec3 outColorB;
layout(location = 18) out vec3 outColorC;
layout(location = 19) out vec3 outColorD;

layout(location = 20) out vec3 outUnmodifiedNormal;
layout(location = 21) out vec3 outForwardNormal;
layout(location = 22) out float depth;


invariant gl_Position;

void main()
{
    vec3 windPos = pos.xyz;
    vec3 normalToUse = normalize(normal.xyz);

    if(stst.w > 0.5)
    {
        windPos = getTerrainDecalWindPos(ubo.windMatrix, ubo.windDir.xy, windPos - centerPos, centerPos, 1.0, ubo.sunPosAnimationTimer.w, normalToUse, ubo.originWindStrength.w) + centerPos;
        //windPos = normalize(pos.xyz) * length(windPos);
    }
    vec4 V = camera.worldView * ubo.mv_matrix * vec4(windPos, 1.0);
    gl_Position = camera.proj * V;

    outPos = windPos;

    outTex = stst;
    outForwardNormal = forwardNormal.xyz;
    
    //outView = ubo.camPosDecalRenderDistance.xyz - windPos;
    
    //outView = (ubo.mv_matrix * camera.camOffsetPosWorld).xyz - windPos;
   // outView = ((camera.worldView * ubo.mv_matrix * vec4(0.0,0.0,0.0,1.0)).xyz + ubo.camPosDecalRenderDistance.xyz) - windPos;
    outView = (camera.camOffsetPosWorld.xyz + ubo.camPosDecalRenderDistance.xyz) - windPos;

    alpha = 1.0 - smoothstep(ubo.camPosDecalRenderDistance.w - 0.15, ubo.camPosDecalRenderDistance.w - 0.05, length(outView));
 
    /*outColorA = matUbo.matColors[material.x].xyz;
    outColorB = matUbo.matColors[material.y].xyz;
    outColorC = matUbo.matColors[material.z].xyz;

    outMaterialA = vec2(matUbo.matProperties[material.x].x * (1.0 - stst.w * 0.2), matUbo.matProperties[material.x].y);
    outMaterialB = vec2(matUbo.matProperties[material.y].x * (1.0 - stst.w * 0.2), matUbo.matProperties[material.y].y);
    outMaterialC = vec2(matUbo.matProperties[material.z].x * (1.0 - stst.w * 0.2), matUbo.matProperties[material.z].y);*/

    outColorA = materialsA.xyz / 255.0;
    outColorA = outColorA * outColorA;
    if(materialsA.w > 127)
    {
      outMaterialA = vec2((materialsA.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialA = vec2(materialsA.w / 127.0, 0.0);
    }
    
    outColorB = materialsB.xyz / 255.0;
    outColorB = outColorB * outColorB;
    if(materialsB.w > 127)
    {
      outMaterialB = vec2((materialsB.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialB = vec2(materialsB.w / 127.0, 0.0);
    }

    outColorC = materialsC.xyz / 255.0;
    outColorC = outColorC * outColorC;
    if(materialsC.w > 127)
    {
      outMaterialC = vec2((materialsC.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialC = vec2(materialsC.w / 127.0, 0.0);
    }

    outColorD = materialsD.xyz / 255.0;
    outColorD = outColorD * outColorD;
    if(materialsD.w > 127)
    {
      outMaterialD = vec2((materialsD.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialD = vec2(materialsD.w / 127.0, 0.0);
    }

    
    depth = -pos.w - 0.001;

    outNormal = normalToUse.xyz;// + sunPos * 0.2 * tex.y);
    outUnmodifiedNormal = normal.xyz;

    outWorldPos = (windPos + ubo.originWindStrength.xyz ) * 8.388608;
    outWorldCamPos = (ubo.camPosDecalRenderDistance.xyz  + ubo.originWindStrength.xyz ) * 8.388608;
    outWorldViewVec = (windPos - ubo.camPosDecalRenderDistance.xyz ) * 8.388608;
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(windPos, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(windPos, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(windPos, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(windPos, 1.0);

    
}
