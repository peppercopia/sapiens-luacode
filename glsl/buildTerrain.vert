
layout(location = 0) in vec3 position;
layout(location = 1) in vec3 positionWeight;
layout(location = 2) in vec3 clearMarker;
layout(location = 3) in vec2 heightFlat;

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

layout(location = 0) out vec3 outPositionWeight;
layout(location = 1) out vec3 outClearMarker;
layout(location = 2) out vec3 outHeightFlatAnimation;

out gl_PerVertex {
    vec4 gl_Position;
};

void main()
{
    gl_Position = camera.proj * camera.worldView * ubo.mvMatrix * vec4(position.x, position.y, position.z, 1.0);

    outPositionWeight = positionWeight;
    outClearMarker = clearMarker;
    outHeightFlatAnimation.x = heightFlat.x;
    outHeightFlatAnimation.y = heightFlat.y;
    outHeightFlatAnimation.z = ubo.animationTimer;
}
