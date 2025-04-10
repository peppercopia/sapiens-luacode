#include "lightingCommon.frag"

layout(binding = 0) uniform UniformBufferObject {
    mat4 modelview;
    vec4 sunPos;
    vec4 origin;
    vec4 screenSize;
    vec4 lightOriginOffset;
    vec4 camPosLocal;
    mat4 shadow_matrices[4];
    mat4 rainMatrix;
    ivec4 outputType_SSAOEnabled;
} ubo;


layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(binding = 2) uniform UniformBufferObjectLights
{ 
    vec4 lightPositions[MAX_LIGHTS];
    vec4 lightColors[MAX_LIGHTS];
    int lightCount;
} lights;

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texCoord;
layout(location = 2) in vec4 typeAndLifeLeftAndRandomValueAndScale;
layout(location = 3) in vec3 upVector;

const float particleSize = 0.02;

layout(location = 0) out vec2 texOffset;
layout(location = 1) out vec2 outTexCoord;
layout(location = 2) out vec4 lifeColorOffsetAndLifeLeftAndRandomValue;

void main()
{
    vec3 up = upVector;
    vec3 back = normalize(position.xyz - ubo.camPosLocal.xyz);
    vec3 right = normalize(cross(up, back));
    //up = normalize(cross(right, -back));

    float size = particleSize * (0.4 + typeAndLifeLeftAndRandomValueAndScale.y * smoothstep(0.0, 0.35, 1.0 - typeAndLifeLeftAndRandomValueAndScale.y)) * typeAndLifeLeftAndRandomValueAndScale.w;
    vec3 offsetPos = position.xyz + right * (-0.5 + texCoord.x) * size + up * (-0.5 + texCoord.y) * size;

    vec4 eyePos = camera.worldView * ubo.modelview * vec4(offsetPos, 1.0);
    gl_Position = camera.proj * eyePos;


    float posOffset = (0.125 * typeAndLifeLeftAndRandomValueAndScale.x);
    float posOffsetFract = fract(posOffset);
    float yOffset = (posOffset - posOffsetFract) * 0.125 + 0.00390625;

    texOffset = vec2(posOffsetFract,1.0 - yOffset);
    outTexCoord = texCoord;

    lifeColorOffsetAndLifeLeftAndRandomValue.xy = vec2(texOffset.x + 0.125 * (1.0 - typeAndLifeLeftAndRandomValueAndScale.y), texOffset.y + 0.00390625);
    lifeColorOffsetAndLifeLeftAndRandomValue.zw = typeAndLifeLeftAndRandomValueAndScale.yz;
}
