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
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 normal;
layout(location = 3) in vec4 tangent;
layout(location = 4) in uvec4 material;
layout(location = 5) in uvec4 materialB;

layout(location = 0) out vec3 outColor;
layout(location = 1) out vec4 outMaterialUV;
layout(location = 2) out vec4 outView_animationTimer;
layout(location = 3) out vec3 outNormal;
layout(location = 4) out vec3 outColorB;
layout(location = 5) out vec2 outMaterialB;
layout(location = 6) out vec3 outTangent;

void main(void)
{
    vec4 V = camera.view * ubo.mv_matrix * vec4(pos.xyz, 1.0);
    

    gl_Position = camera.proj * V;
    outView_animationTimer.w = ubo.camPos_animationTimer.w;
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(pos.xyz, 1.0)).xyz;
    
    outColor = material.xyz / 255.0;
    //outColor = outColor * outColor;
    outColorB = materialB.xyz / 255.0;
    //outColorB = outColorB * outColorB;

    if(material.w > 127)
    {
      outMaterialUV.xy = vec2((material.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialUV.xy = vec2(material.w / 127.0, 0.0);
    }
    outMaterialUV.zw = uv;
    if(materialB.w > 127)
    {
      outMaterialB = vec2((materialB.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialB = vec2(materialB.w / 127.0, 0.0);
    }
    
    outNormal = (ubo.normal_matrix * vec4(normal.xyz, 1.0)).xyz;
    outTangent = (ubo.normal_matrix * vec4(tangent.xyz, 1.0)).xyz;
    outView_animationTimer.xyz = ubo.camPos_animationTimer.xyz - rotatedPosition;
}
