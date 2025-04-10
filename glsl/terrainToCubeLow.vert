
#extension GL_EXT_multiview : enable

layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix[6];
    mat4 p_matrix;
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
layout(location = 1) in vec4 normal;
layout(location = 2) in vec4 matTex;

layout(location = 0) out vec3 outPos;
layout(location = 1) out vec3 outWorldPos;
layout(location = 2) out vec3 outWorldCamPos;
layout(location = 3) out vec3 outView;
layout(location = 4) out vec3 outNormal;
layout(location = 5) out vec3 outWorldViewVec;
layout(location = 6) out vec4 outShadowCoords[4];

layout(location = 10) out float depth;
layout(location = 11) out vec2 outMatTex;
layout(location = 12) out vec2 outMatBlendTex;

out gl_PerVertex {
    vec4 gl_Position;
};


void main()
{
    vec4 V = ubo.mv_matrix[gl_ViewIndex] * vec4(pos.xyz, 1.0);
    gl_Position = ubo.p_matrix * V;

    outPos = pos.xyz;
    outView = ubo.camPos.xyz - pos.xyz;

    outNormal = normal.xyz;
    outMatTex = matTex.xy;
    outMatBlendTex = matTex.zw;

    outWorldPos = (pos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (pos.xyz - ubo.camPos.xyz) * 8.388608;
    
    depth = -pos.w;
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(pos.xyz, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(pos.xyz, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(pos.xyz, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(pos.xyz, 1.0);

}
