
layout(binding = 0) uniform UniformBufferObject {
	mat4 mv_matrix;
	mat4 normal_matrix;
	vec4 color;
  vec4 size;
  vec4 texMinAndScale;
  vec4 material;
  vec4 animationTimer;
  vec4 shaderUniformA;
  vec4 shaderUniformB;
} ubo;

layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) in vec2 pos;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMaterial;
layout(location = 2) out vec3 outView;
layout(location = 3) out vec3 outNormal;
layout(location = 4) out vec2 outTex;
layout(location = 5) out mat4 outNormalMatrix;
layout(location = 9) out vec4 outTimer;
layout(location = 10) out vec4 outShaderUniformA;
layout(location = 11) out vec4 outShaderUniformB;

void main(void)
{
    vec3 newNormal = vec3(0,0,1);

    vec4 V = camera.worldView * ubo.mv_matrix * vec4(pos.xy * ubo.size.xy, 0.0, 1.0);
    

    gl_Position = camera.proj * V;
    
    vec3 rotatedPosition = V.xyz;

    outColor = vec4(ubo.material.xyz, 1.0) * ubo.color;
    outColor.xyz = outColor.xyz * outColor.xyz;
    if(ubo.material.w > 0.5)
    {
      outMaterial = vec2((ubo.material.w - 0.5) / 0.5, 1.0);
    }
    else
    {
      outMaterial = vec2(ubo.material.w / 0.5, 0.0);
    }
    
    outNormalMatrix = ubo.normal_matrix;
    outView = -rotatedPosition;

    outTimer = ubo.animationTimer;
    outShaderUniformA = ubo.shaderUniformA;
    outShaderUniformB = ubo.shaderUniformA;
    
    outTex = (pos * ubo.texMinAndScale.zw) + ubo.texMinAndScale.xy;
}
