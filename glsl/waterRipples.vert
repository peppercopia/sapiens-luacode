#include "lightingCommon.frag"

layout(binding = 0) uniform UniformBufferObject {
    mat4 modelview;
    vec4 sunPos;
    vec4 origin;
    vec4 screenSize_cloudCover;
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

const float particleSize = 0.1;

layout(location = 0) out vec2 outTexCoord;
layout(location = 1) out vec2 lifeColorOffset;
layout(location = 2) out vec3 outWorldPos;
layout(location = 3) out vec3 outSunPos;
layout(location = 4) out vec4 outLightAddition_cloudCover;
layout(location = 5) out vec4 outShadowCoords[4];
layout(location = 9) out vec3 outWorldViewVec;


const float M_2PI = 6.283185;

void main()
{
  
    vec3 up = normalize(ubo.origin.xyz);
    vec3 back = normalize(position.xyz - (camera.camOffsetPos.xyz + ubo.camPosLocal.xyz));
    vec3 right = normalize(cross(up, back));
    //up = normalize(cross(right, -back));
    back = normalize(cross(up, right));

    
    float size = particleSize * typeAndLifeLeftAndRandomValueAndScale.w * (1.1 - typeAndLifeLeftAndRandomValueAndScale.y);
    vec2 vertPos = vec2(-0.5 + texCoord.x, -0.5 + texCoord.y);
    float rotation = typeAndLifeLeftAndRandomValueAndScale.z * M_2PI;
    float cosTheta = cos(rotation);
    float sinTheta = sin(rotation);
    vertPos = vec2(vertPos.x * cosTheta - vertPos.y * sinTheta, vertPos.x * sinTheta + vertPos.y * cosTheta);
    vec3 offsetPos = position.xyz + right * vertPos.x * size + back * vertPos.y * size;

    vec4 eyePos = camera.worldView * ubo.modelview * vec4(offsetPos, 1.0);
    gl_Position = camera.proj * eyePos;
    
    outWorldPos = (offsetPos + ubo.origin.xyz) * 8.388608;
    outSunPos = ubo.sunPos.xyz;

    
    //outCamPos = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz);
  //  outView = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - pos.xyz;

    outTexCoord = texCoord * 0.25 + vec2(0.0,1.0 -0.125 - 0.25);

    lifeColorOffset = vec2((typeAndLifeLeftAndRandomValueAndScale.y), 0.0);

    outLightAddition_cloudCover = vec4(0.0,0.0,0.0, ubo.screenSize_cloudCover.z);
    vec3 normalToUse = normalize(outWorldPos);
    
    for(int lightIndex = 0; lightIndex < lights.lightCount; lightIndex++)
    {
        vec3 distanceVec = (lights.lightPositions[lightIndex].xyz + ubo.lightOriginOffset.xyz - offsetPos) * LIGHT_DISTANCE_MULTIPLIER;
        float lightDistance2 = dot(distanceVec,distanceVec);
        if(lightDistance2 < MAX_LIGHT_DISTANCE2)
        {
            float fadeOutNearEdge = clamp((lightDistance2 - FADE_OUT_START_LIGHT_DISTANCE2) / FADE_OUT_DIVIDER_LIGHT_DISTANCE2, 0.0, 1.0);
            fadeOutNearEdge = 1.0 - fadeOutNearEdge;
            float att = mix(0.0, 0.1 / max(lightDistance2, 0.1), fadeOutNearEdge);
           // vec3 lightNormal = normalize(distanceVec);
            float NdotLP        = 0.5;//clamp(dot( normalToUse, lightNormal ), 0.0, 1.0);
            outLightAddition_cloudCover.xyz += lights.lightColors[lightIndex].xyz * NdotLP * att;

            // lightReflect += lights.lightColors[lightIndex].xyz * lightSpecular(normalToUse, V, lightNormal, outMaterial.x * 0.8 + 0.2) * att;
        }
    }
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(offsetPos, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(offsetPos, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(offsetPos, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(offsetPos, 1.0);
    
    vec3 outWorldCamPos = ((camera.camOffsetPos.xyz + ubo.camPosLocal.xyz) + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (outWorldPos.xyz - outWorldCamPos);
}

