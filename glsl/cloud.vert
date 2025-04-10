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

const float particleSize = 15.0;

layout(location = 0) out vec2 outTexCoord;
layout(location = 1) out vec3 outWorldPos;
layout(location = 2) out vec3 outSunPos;
layout(location = 3) out vec4 outLightAddition_cloudCover;
layout(location = 4) out vec3 outSunPosLocal;
layout(location = 5) out vec3 outWorldCamPos;
layout(location = 6) out vec3 outWorldViewVec;
layout(location = 7) out ivec4 outputType_SSAOEnabled;
layout(location = 8) out vec2 outAlphaDepthMultiplier;

layout(location = 9) out mat3 outMatrix;


const float M_2PI = 6.283185;



vec4 quatAngleAxis(float angle, vec3 axis)
{
    float s = sin(angle * 0.5);
    vec4 result = vec4(axis * s, cos(angle * 0.5));
    return result;
}

vec3 rotate_vector( vec4 quat, vec3 vec )
{
    return vec + 2.0 * cross( cross( vec, quat.xyz ) + quat.w * vec, quat.xyz );
}

void main()
{
    vec3 up = normalize(ubo.origin.xyz);
    vec3 viewVec = (camera.camOffsetPos.xyz + ubo.camPosLocal.xyz) - position.xyz;
    float viewDistance = length(viewVec);
    vec3 forward = -viewVec / viewDistance;
    vec3 right = normalize(cross(up, -forward));
    forward = normalize(cross(up, right));
    
    mat3 mat = mat3(right.x, right.y, right.z, up.x, up.y, up.z, -forward.x, -forward.y, -forward.z);

   // outTexCoord = texCoord;
    float posOffset = (0.25 * typeAndLifeLeftAndRandomValueAndScale.x);
    float posOffsetFract = fract(posOffset);
    float yOffset = (posOffset - posOffsetFract) * 0.25;

   // texOffsetAndScale.zw = vec2(1.0 - 0.008,1.0 - 0.008);
    float posYOffset = 0.0;
    float posYScale = 0.8;
    float baseScale = 1.0;

    vec2 scale = vec2(1.0,1.0);
    
    if(typeAndLifeLeftAndRandomValueAndScale.x > 27)
    {
        right = normalize(cross(up, vec3(0.0,1.0,0.0)));
        vec4 quat = quatAngleAxis(typeAndLifeLeftAndRandomValueAndScale.z * M_2PI, up);
        right = normalize(rotate_vector(quat, right));
        forward = normalize(cross(up, right));
        vec3 temp = forward;
        forward = up;
        up = -temp;

        mat = mat3(right.x, right.y, right.z, forward.x, forward.y, forward.z, up.x, up.y, up.z);
        
        posYOffset = -1.0;
        posYScale = 2.0;
        baseScale = 1.05;
        scale = vec2(1.0 + typeAndLifeLeftAndRandomValueAndScale.z * 0.5);
        
        posOffset = (0.125 * (typeAndLifeLeftAndRandomValueAndScale.x - 28));
        posOffsetFract = fract(posOffset);
        yOffset = (posOffset - posOffsetFract) * 0.125;
        outTexCoord = vec2(posOffsetFract,0.125 - yOffset) + texCoord * vec2(0.125, 0.125);
    }
    else if(typeAndLifeLeftAndRandomValueAndScale.x > 11)
    {
        posOffset = (0.125 * (typeAndLifeLeftAndRandomValueAndScale.x - 12));
        posOffsetFract = fract(posOffset);
        yOffset = (posOffset - posOffsetFract) * 0.125 * 0.5;
        outTexCoord = vec2(posOffsetFract,1.0 - 0.5 - 0.125 - 0.125 * 0.5 - yOffset) + texCoord * vec2(0.125, 0.125 * 0.5);
        scale.x = 1.0 + typeAndLifeLeftAndRandomValueAndScale.z * 1.0;
    }
    else if(typeAndLifeLeftAndRandomValueAndScale.x > 3)
    {
        right = normalize(cross(up, vec3(0.0,1.0,0.0)));
        vec4 quat = quatAngleAxis(typeAndLifeLeftAndRandomValueAndScale.z * M_2PI, up);
        right = normalize(rotate_vector(quat, right));
        forward = normalize(cross(up, right));
        vec3 temp = forward;
        forward = up;
        up = -temp;

        mat = mat3(right.x, right.y, right.z, forward.x, forward.y, forward.z, up.x, up.y, up.z);
        
        posYOffset = -1.0;
        posYScale = 2.0;
        outTexCoord = vec2(posOffsetFract + 0.003,1.0 - 0.125 - yOffset + 0.003) + texCoord * vec2(0.25 - 0.006, 0.25 - 0.006);
        baseScale = 1.05;
        scale = vec2(1.0 + typeAndLifeLeftAndRandomValueAndScale.z * 0.5);
    }
    else
    {
        //vec2(0.25, 0.125)
        outTexCoord = vec2(posOffsetFract + 0.003,1.0 - 0.125 - yOffset + 0.003) + texCoord * vec2(0.25 - 0.006, 0.125 - 0.006);
        scale.x = 1.0 + typeAndLifeLeftAndRandomValueAndScale.z * 0.5;
    }

    if(typeAndLifeLeftAndRandomValueAndScale.x > 3)
    {
        if(typeAndLifeLeftAndRandomValueAndScale.x > 11)
        {
            if(typeAndLifeLeftAndRandomValueAndScale.x > 27)
            {
                outAlphaDepthMultiplier.x = clamp((abs(dot(-forward, normalize(viewVec))) - 0.05) * 100.0, 0.0, 1.0);
            }
            else
            {
                outAlphaDepthMultiplier.x = clamp((abs(dot(-forward, normalize(viewVec))) - 0.8) * 40.0, 0.0, 1.0) * clamp((viewDistance * 0.2) - 4.0 * typeAndLifeLeftAndRandomValueAndScale.w, 0.0, 1.0);
            }
        }
        else
        {
            if(typeAndLifeLeftAndRandomValueAndScale.x < 8)
            {
                outAlphaDepthMultiplier.x = clamp((abs(dot(-forward, normalize(viewVec))) - 0.1) * 50.0, 0.0, 1.0);
            }
            else
            {
                outAlphaDepthMultiplier.x = 1.0;
            }
        }
    }
    else
    {
        outAlphaDepthMultiplier.x = clamp((abs(dot(-forward, normalize(viewVec))) - 0.8) * 20.0, 0.0, 1.0) * clamp((viewDistance * 0.2) - 4.0 * typeAndLifeLeftAndRandomValueAndScale.w, 0.0, 1.0);
    }

    float finalScale = step(0.1, outAlphaDepthMultiplier.x) * typeAndLifeLeftAndRandomValueAndScale.w * baseScale;

    outAlphaDepthMultiplier.y = typeAndLifeLeftAndRandomValueAndScale.w;

    outMatrix = mat;
    outSunPosLocal = normalize(inverse(mat) * ubo.sunPos.xyz);
    
    vec2 size = vec2(particleSize * 2.0 * scale.x, particleSize * scale.y) * finalScale;
    vec2 vertPos = vec2(-0.5 + texCoord.x, posYOffset + texCoord.y * posYScale);
    vec3 offsetPos = position.xyz + right * vertPos.x * size.x + up * vertPos.y * size.y;

    vec4 eyePos = camera.worldView * ubo.modelview * vec4(offsetPos, 1.0);
    gl_Position = camera.proj * eyePos;
    
    outWorldPos = (offsetPos + ubo.origin.xyz) * 8.388608;
    outSunPos = ubo.sunPos.xyz;

    outLightAddition_cloudCover = vec4(0.0,0.0,0.0, ubo.screenSize_cloudCover.z);
    vec3 normalToUse = normalize(outWorldPos);
    
    outWorldCamPos = ((camera.camOffsetPos.xyz + ubo.camPosLocal.xyz) + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (outWorldPos.xyz - outWorldCamPos);

    outputType_SSAOEnabled = ubo.outputType_SSAOEnabled;
    
}

