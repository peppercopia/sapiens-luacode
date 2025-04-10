layout(binding = 0) uniform vUniformBufferObject {
  mat4 mvMatrix;
} vubo;

layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) in vec3 position;

layout(location = 0) out vec3 camDir;

out gl_PerVertex {
    vec4 gl_Position;
};

void main(void)
{
    camDir = position;
    
	gl_Position = camera.proj * camera.worldRotation * vubo.mvMatrix * vec4(position,1.0);
}
