
layout(binding = 0) uniform UniformBufferObject {
	mat4 mv_matrix;
	mat4 normal_matrix;
	vec4 color;
  vec4 animationTimer;
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
layout(location = 1) in vec2 tex;
layout(location = 2) in uvec4 material;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMaterial;
layout(location = 2) out vec4 outView_animationTimer;
layout(location = 3) out vec3 outNormal;
layout(location = 4) out vec2 outTex;
layout(location = 5) out mat4 outNormalMatrix;

void main(void)
{
    vec3 newNormal = vec3(0,0,1);

    vec4 V = camera.worldView * ubo.mv_matrix * vec4(pos.xy, 0.0, 1.0);
    

    gl_Position = camera.proj * V;
    outView_animationTimer.w = ubo.animationTimer.x;
    
    vec3 rotatedPosition = V.xyz;

    outColor = vec4(material.xyz / 255.0, 1.0) * ubo.color;
    outColor.xyz = outColor.xyz * outColor.xyz;
    if(material.w > 127)
    {
      outMaterial = vec2((material.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterial = vec2(material.w / 127.0, 0.0);
    }
    
    outNormalMatrix = ubo.normal_matrix;
    outView_animationTimer.xyz = -rotatedPosition;
    outTex = tex;
}
