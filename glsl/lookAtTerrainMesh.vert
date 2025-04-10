
layout(location = 0) in vec4 position;

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvMatrix;
    float animationTimer;
} ubo;

layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) out vec2 outAnimationAlpha;

out gl_PerVertex {
    vec4 gl_Position;
};

void main()
{
    gl_Position = camera.proj * camera.worldView * ubo.mvMatrix * vec4(position.x, position.y, position.z, 1.0);
    outAnimationAlpha = vec2(ubo.animationTimer, position.w);
}
