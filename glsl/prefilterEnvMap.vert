
#extension GL_EXT_multiview : enable

layout(binding = 0) uniform UniformBufferObject {
    mat4 mvpMatrix[6];
    mat4 playerMatrix;
} ubo;


layout(location = 0) in vec3 position;

layout(location = 0) out vec3 normal;

out gl_PerVertex {
    vec4 gl_Position;
};

void main( void )
{
	normal = vec3(ubo.playerMatrix * vec4(position, 1.0));
    
	gl_Position = ubo.mvpMatrix[gl_ViewIndex] * vec4(position, 1.0);
}
