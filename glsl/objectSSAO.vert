
layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix;
    mat4 pMatrix;
    mat4 windMatrix;
    vec4 sunPosAnimationTimer;
    vec4 windDir;
} ubo;

layout(location = 0) in vec3 pos;

void main()
{
    gl_Position = ubo.pMatrix * ubo.mvMatrix * vec4(pos.xyz, 1.0);
}
