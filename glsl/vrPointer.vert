
layout(location = 0) in vec3 position;

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvpMatrix;
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


layout(location = 0) out vec4 outColor;

out gl_PerVertex {
    vec4 gl_Position;
};

void main()
{
    gl_Position = camera.proj * camera.worldView * ubo.mvpMatrix * vec4(position.xyz, 1.0);
    outColor = ubo.color; 
}
