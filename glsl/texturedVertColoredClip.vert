
layout(binding = 0) uniform UniformBufferObject {
    mat4 modelMatrix;
    mat4 clip_matrix;
    vec4 color;
} ubo;

layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoord;
layout(location = 2) in vec4 color;

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec2 fragTexCoord;
layout(location = 2) out vec4 outClipPos;

out gl_PerVertex {
    vec4 gl_Position;
};

void main() {
    gl_Position = camera.proj * camera.worldView * ubo.modelMatrix * vec4(position, 0.0, 1.0);
    
    outClipPos = ubo.clip_matrix * vec4(position.xy, 0.0, 1.0);

    fragColor = color * ubo.color;
    fragTexCoord = texCoord;
}