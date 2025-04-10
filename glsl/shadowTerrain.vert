
#extension GL_EXT_multiview : enable

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix[5];
    mat4 pMatrix[5];
} ubo;

layout(location = 0) in vec4 pos;
layout(location = 1) in vec4 normal;

const float offsets[5] = {
    0.002,
    0.004,
    0.008,
    0.016,
    0.0,
};


void main()
{
    gl_Position = ubo.pMatrix[gl_ViewIndex] * ubo.mvMatrix[gl_ViewIndex] * vec4(pos.xyz - normal.xyz * offsets[gl_ViewIndex], 1.0);
}
