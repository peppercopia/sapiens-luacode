
layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 posRotationMatrix;
    vec4 camPos;
    vec4 sunPos_transition;
    vec4 translation;
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

layout(location = 0) out vec3 outPos;
//layout(location = 1) out vec3 outWorldPos;
layout(location = 1) out vec3 outWorldCamPos;
layout(location = 2) out vec3 outView;
layout(location = 3) out vec3 outNormal;
layout(location = 4) out vec3 outWorldViewVec;

layout(location = 5) out float flow;
layout(location = 6) out float[3] vertWeights;

out gl_PerVertex {
    vec4 gl_Position;
};

void main()
{
    vec4 posToUse = ubo.posRotationMatrix * vec4(pos.xyz, 1.0);
    vec4 V = camera.worldView * ubo.mv_matrix * posToUse;
    gl_Position = camera.proj * V;

     outPos = posToUse.xyz;
    
   // outView = (camera.worldView * vec4(ubo.camPos.xyz, 1.0)).xyz - pos.xyz;

   //outView = (camera.worldView * ubo.mv_matrix * camera.camOffsetPosWorld).xyz - pos.xyz;
    outView = (camera.camOffsetPos.xyz + ubo.camPos.xyz) - posToUse.xyz;

    vertWeights[0] = 0.0;
    vertWeights[1] = 0.0;
    vertWeights[2] = 0.0;

    uint vertIndex = gl_VertexIndex % 3;
    vertWeights[vertIndex] = 1.0;

    outNormal = (ubo.posRotationMatrix * vec4(normal.xyz, 1.0)).xyz;

    //outWorldPos = normalize(posToUse.xyz) * 838860.8;
   // vec3 camPos = -vec3(camera.worldView * ubo.mv_matrix * vec4(0.0,0.0,0.0, 1.0));
    vec3 camPos = (camera.camOffsetPos.xyz + ubo.camPos.xyz) * ubo.camPos.w;
    outWorldCamPos = (camPos - ubo.translation.xyz * ubo.camPos.w) * 838860.8;
    outWorldViewVec = ((posToUse.xyz + ubo.translation.xyz * ubo.camPos.w) - (camPos)) * 838860.8;

    
    flow = pos.w;
}