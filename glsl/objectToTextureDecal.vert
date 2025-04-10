#include "wind.vert"

layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 normal_matrix;
    vec4 camPos_animationTimer;
} ubo;

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

layout(location = 0) out vec3 outColor;
layout(location = 1) out vec2 outMaterial;
layout(location = 2) out vec4 outView_animationTimer;
layout(location = 3) out vec3 outNormal;
layout(location = 4) out vec3 outFaceNormal;
layout(location = 5) out vec2 outTexCoord;
layout(location = 6) out vec3 outColorB;
layout(location = 7) out vec2 outMaterialB;

//out vec3 outPos;

void main(void)
{
    vec3 newNormal = normal.xyz;
    vec4 V = camera.view * ubo.mv_matrix * vec4(pos, 1.0);
    gl_Position = camera.proj * V;
    outView_animationTimer.w = ubo.camPos_animationTimer.w;
    
    //gl_Position.z = (log2(max(1e-6, 1.0 + gl_Position.w)) * (2.0 / log2(100.0 + 1.0)) - 1.0) * gl_Position.w;
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(pos, 1.0)).xyz;
    
    outTexCoord = texCoord.xy;

    outColor = material.xyz / 255.0;
    outColorB = materialB.xyz / 255.0;
    //outColor = outColor + vec3(0.5,0.5,0.8) * instanceExtraData.x;
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

    //outColor = mix(matUbo.matColors[material].xyz, matUbo.matColors[material].xyz * 1.1, (texCoord.z));
    //outMaterial = vec2(matUbo.matProperties[material].x * (1.0 - texCoord.z * 0.2), matUbo.matProperties[material].y);
    outNormal = (ubo.normal_matrix * vec4(newNormal, 1.0)).xyz;
    outFaceNormal = (ubo.normal_matrix * vec4(faceNormal.xyz, 1.0)).xyz;
    outView_animationTimer.xyz = ubo.camPos_animationTimer.xyz - rotatedPosition;
    //outTangent = (ubo.normal_matrix * vec4(tangent.xyz, 1.0)).xyz;

    //outPos = rotatedPosition.xyz;
}
