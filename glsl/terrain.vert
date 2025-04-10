
layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 shadow_matrices[4];
    vec4 camPos;
    vec4 sunPos;
    vec4 origin;
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
layout(location = 1) in vec4 normal;
layout(location = 2) in vec4 tangent;
layout(location = 3) in uvec4 materialsAA;
layout(location = 4) in uvec4 materialsAB;
layout(location = 5) in uvec4 materialsAC;
layout(location = 6) in uvec4 materialsBA;
layout(location = 7) in uvec4 materialsBB;
layout(location = 8) in uvec4 materialsBC;

layout(location = 0) out vec3 outPos;
layout(location = 1) out vec3 outWorldPos;
layout(location = 2) out vec3 outWorldCamPos;
layout(location = 3) out vec3 outColorsA[3];
layout(location = 6) out vec2 outMaterialsA[3];
layout(location = 9) out vec3 outView;
layout(location = 10) out vec3 outNormal;
layout(location = 11) out vec3 outTangent;
layout(location = 12) out vec3 outWorldViewVec;
layout(location = 13) out vec4 outShadowCoords[4];

layout(location = 17) out float depth;
layout(location = 18) out vec2 materialTexCoord;
layout(location = 19) out vec3 outColorsB[3];
layout(location = 22) out vec2 outMaterialsB[3];


invariant gl_Position;

const float texCoordOffset = 0.0625;

const vec2 texCoords[12] = {
  vec2(0.0 + texCoordOffset,0.5 + texCoordOffset),
  vec2(0.25,1.0 - texCoordOffset),
  vec2(0.5 - texCoordOffset,0.5 + texCoordOffset),

  vec2(0.5 + texCoordOffset,0.5 + texCoordOffset),
  vec2(0.75,1.0 - texCoordOffset),
  vec2(1.0 - texCoordOffset,0.5 + texCoordOffset),

  vec2(0.0 + texCoordOffset,0.0 + texCoordOffset),
  vec2(0.25,0.5 - texCoordOffset),
  vec2(0.5 - texCoordOffset,0.0 + texCoordOffset),

  vec2(0.5 + texCoordOffset,0.0 + texCoordOffset),
  vec2(0.75,0.5 - texCoordOffset),
  vec2(1.0 - texCoordOffset,0.0 + texCoordOffset)
};


vec2 getOutMaterial(uint matIn)
{
    if(matIn > 127)
    {
      return vec2((matIn - 128.0) / 127.0, 1.0);
    }
    else
    {
      return vec2(matIn / 127.0, 0.0);
    }
}

void main()
{
    vec4 V = camera.worldView * ubo.mv_matrix * vec4(pos.xyz, 1.0);
    gl_Position = camera.proj * V;

    outPos = pos.xyz;
    
   // outView = (camera.worldView * vec4(ubo.camPos.xyz, 1.0)).xyz - pos.xyz;
   //outView = (camera.worldView * ubo.mv_matrix * camera.camOffsetPosWorld).xyz - pos.xyz;
    outView = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - pos.xyz;

    uint vertIndex = gl_VertexIndex % 12;
    materialTexCoord = texCoords[vertIndex];
    
    outColorsA[0] = materialsAA.xyz / 255.0;
    outMaterialsA[0] = getOutMaterial(materialsAA.w);
    outColorsA[1] = materialsAB.xyz / 255.0;
    outMaterialsA[1] = getOutMaterial(materialsAB.w);
    outColorsA[2] = materialsAC.xyz / 255.0;
    outMaterialsA[2] = getOutMaterial(materialsAC.w);
    
    outColorsB[0] = materialsBA.xyz / 255.0;
    outMaterialsB[0] = getOutMaterial(materialsBA.w);
    outColorsB[1] = materialsBB.xyz / 255.0;
    outMaterialsB[1] = getOutMaterial(materialsBB.w);
    outColorsB[2] = materialsBC.xyz / 255.0;
    outMaterialsB[2] = getOutMaterial(materialsBC.w);

    outColorsA[0] = outColorsA[0] * outColorsA[0];
    outColorsA[1] = outColorsA[1] * outColorsA[1];
    outColorsA[2] = outColorsA[2] * outColorsA[2];

    outColorsB[0] = outColorsB[0] * outColorsB[0];
    outColorsB[1] = outColorsB[1] * outColorsB[1];
    outColorsB[2] = outColorsB[2] * outColorsB[2];

    outNormal = (normal.xyz);
    outTangent = (tangent.xyz);

    outWorldPos = (pos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (pos.xyz - ubo.camPos.xyz) * 8.388608;
    
    depth = -pos.w - 0.001;
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(pos.xyz, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(pos.xyz, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(pos.xyz, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(pos.xyz, 1.0);
}
