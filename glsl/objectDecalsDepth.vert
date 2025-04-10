layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 normal_matrix;
    mat4 windMatrix;
    mat4 shadow_matrices[4];
    mat4 waterDepthOrthoMatrix;
    vec4 camPos;
    vec4 sunPos;
    vec4 origin;
    vec4 translation;
    vec4 extraData;
    vec4 windDir;
} ubo;


layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) in vec3 pos;
layout(location = 1) in vec3 texCoord;
layout(location = 2) in vec3 decalLocalOrigin;
layout(location = 3) in vec4 normal;
layout(location = 4) in vec4 tangent;
layout(location = 5) in vec4 faceNormal;
layout(location = 6) in uvec4 material;
layout(location = 7) in uvec4 materialB;

layout(location = 0) out vec4 outView;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outTexCoord;

invariant gl_Position;

void main(void)
{
    vec4 V = camera.worldView * ubo.mv_matrix * vec4(pos.xyz, 1.0);
    gl_Position = camera.proj * V;

    outTexCoord = texCoord;
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(pos, 1.0)).xyz;
    
    outNormal = (ubo.normal_matrix * vec4(faceNormal.xyz, 1.0)).xyz;
    //outView.xyz = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - ubo.translation.xyz - rotatedPosition.xyz;
    outView.xyz = ubo.camPos.xyz - (ubo.translation.xyz + rotatedPosition.xyz);
    //outView.xyz = (ubo.normal_matrix * vec4((camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - ubo.translation.xyz - rotatedPosition.xyz, 1.0)).xyz;
    
    vec4 waterDepth = ubo.waterDepthOrthoMatrix * vec4((rotatedPosition.xyz + ubo.translation.xyz), 1.0);
    outView.w = -waterDepth.z + ubo.origin.w;
}
