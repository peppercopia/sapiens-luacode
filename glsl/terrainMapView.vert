layout(binding = 0) uniform UniformBufferObject {
    mat4 modelMatrix;
    vec4 color;
    vec4 size;
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

layout(location = 0) in vec4 posSelectionAltitude;
layout(location = 1) in vec4 normal;
layout(location = 2) in uvec4 material;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec2 outMaterial;
layout(location = 2) out vec3 outNormal;
layout(location = 3) out vec3 rawPosAndDepth;


vec2 getOutMaterial(uint matIn)
{
    if(matIn > 127)
    {
      return vec2((matIn - 128.0) / 127.0, 1.0);
    }
    else
    {
      return vec2(matIn / 127.0, 0.0);
    }
}

void main()
{
    gl_Position = camera.proj * camera.worldView * ubo.modelMatrix * vec4(vec3(posSelectionAltitude.xy * 0.5 * ubo.size.xy + ubo.size.xy * 0.5, 1.0), 1.0);
    
    outColor.rgb = (material.xyz / 255.0) * 0.6 + vec3(0.3,0.7,1.0) * posSelectionAltitude.z * 0.3;
    outColor.a = 1.0;
    outMaterial = getOutMaterial(material.w);

    outNormal = normal.xyz;
    
    rawPosAndDepth.xy = posSelectionAltitude.xy;
    rawPosAndDepth.z = -posSelectionAltitude.w - 0.001;
}
