
layout(binding = 0) uniform UniformBufferObject {
    mat4 mvP;
    vec4 color;
    vec4 layer;
} ubo;

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoord;

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec3 fragTexCoord;

out gl_PerVertex {
    vec4 gl_Position;
};

void main() {
    gl_Position = ubo.mvP * vec4(position, 0.0, 1.0);
    fragColor = ubo.color;
    fragTexCoord = vec3(texCoord, ubo.layer.x);
}