

layout(location = 0) in vec4 position;

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvpMatrix;
    float color;
} ubo;


layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;


layout(location = 0) out float outColor;

out gl_PerVertex {
    vec4 gl_Position;
    float gl_PointSize;
};

void main()
{
    gl_Position = camera.proj * camera.worldRotation * ubo.mvpMatrix * vec4(position.xyz, 1.0);
    float sizeOpacityFloat = min((position.w * ubo.color) / 4.0, 50.0);
    outColor = min(sizeOpacityFloat * 0.03, 1.0); 
    gl_PointSize = max(sizeOpacityFloat * 3.0, 1.0) * 4.0;
}
