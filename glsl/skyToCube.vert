
#extension GL_EXT_multiview : enable


layout(binding = 0) uniform UniformBufferObject {
    mat4 mvpMatrix;
    mat4 mv_matrix[6];
    vec4 camPos;
} ubo;

layout(location = 0) in vec3 position;

layout(location = 0) out vec3 camDir;

out gl_PerVertex {
    vec4 gl_Position;
};

void main(void)
{
    camDir = vec3(ubo.mv_matrix[gl_ViewIndex] * vec4(position,1.0)) - ubo.camPos.xyz;
    
	gl_Position = ubo.mvpMatrix * vec4(position,1.0);
}
