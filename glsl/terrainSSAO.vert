
layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix;
    mat4 pMatrix;
} ubo;

layout(location = 0) in vec4 pos;

void main()
{
    gl_Position = ubo.pMatrix * ubo.mvMatrix * vec4(pos.xyz, 1.0);
}
