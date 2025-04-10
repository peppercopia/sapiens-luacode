
layout(binding = 0) uniform UniformBufferObject {
    mat4 mvpMatrix;
} ubo;

layout(location = 0) in vec2 position;

out gl_PerVertex {
    vec4 gl_Position;
};

void main() {
    gl_Position = ubo.mvpMatrix * vec4(position, 0.0, 1.0);
}