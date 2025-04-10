
layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 shadow_matrices[4];
    vec4 camPos;
    vec4 sunPos;
    vec4 origin;
} ubo;

layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) in vec4 pos;


invariant gl_Position;


void main()
{
    vec4 V = camera.worldView * ubo.mv_matrix * vec4(pos.xyz, 1.0);
    gl_Position = camera.proj * V;
}
