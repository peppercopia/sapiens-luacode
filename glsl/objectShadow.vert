
#extension GL_EXT_multiview : enable

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix[5];
    mat4 pMatrix[5];
    mat4 normal_matrix;
    mat4 windMatrix;
    vec4 sunPos[5];
    vec4 windDir;
} ubo;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 normal;


void main()
{
    /*
    
    vec3 outNormal = (normal_matrix * vec4(normal, 1.0)).xyz;
    //gl_Position = pMatrix * mvMatrix * vec4(pos + -sunPos * 0.001 + outNormal * 0.001 * (1.0 - max(dot(outNormal, sunPos), 0.0)), 1.0);
    gl_Position = pMatrix * mvMatrix * vec4(pos - sunPos * 0.001 - outNormal * 0.0005, 1.0);
    */

    vec3 outNormal = normal.xyz;//normalize((ubo.normal_matrix * vec4(normal, 1.0)).xyz);
    vec3 rotatedSunPos = (inverse(ubo.normal_matrix) * vec4(ubo.sunPos[gl_ViewIndex].xyz, 1.0)).xyz;
    gl_Position = ubo.pMatrix[gl_ViewIndex] * ubo.mvMatrix[gl_ViewIndex] * vec4(pos.xyz - rotatedSunPos * 0.0000001 - outNormal * 0.0004, 1.0);
}