#include "wind.vert"


layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix;
    mat4 pMatrix;
    mat4 windMatrix;
    vec4 sunPosAnimationTimer;
    vec4 windDir;
} ubo;

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 centerPos;
layout(location = 2) in vec4 stst;
layout(location = 3) in vec4 normal;

layout(location = 0) out vec4 outTex;


void main()
{
    vec3 windPos = pos.xyz;
    vec3 normalToUse = normal.xyz;

    if(stst.w > 0.5)
    {
        windPos = getDecalWindPos(ubo.windMatrix, ubo.windDir.xy, windPos - centerPos, centerPos, stst.w, ubo.sunPosAnimationTimer.w, normalToUse, 0.1, 1.0) + centerPos;
    }
    vec4 V = ubo.mvMatrix * vec4(windPos, 1.0);
    gl_Position = ubo.pMatrix * V;
    
    outTex = stst;

    //gl_Position = ubo.pMatrix * ubo.mvMatrix * vec4(pos.xyz, 1.0);
}
