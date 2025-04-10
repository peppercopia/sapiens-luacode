
layout(binding = 0) uniform UniformBufferObject {
    mat4 mvP;
    vec4 color;
} ubo;

layout(location = 0) in vec2 inPosition;

layout(location = 0) out vec4 fragColor;

out gl_PerVertex {
    vec4 gl_Position;
};

void main() {
    gl_Position = ubo.mvP * vec4(inPosition, 0.0, 1.0);
    fragColor = ubo.color;
}