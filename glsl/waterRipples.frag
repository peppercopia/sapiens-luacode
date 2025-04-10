
#include "shadowCommon.frag"
#include "lightingCommon.frag"
#include "atmoRenderCommon.frag"

layout(binding = 3) uniform sampler2D texMap;
layout(binding = 4) uniform sampler2D transmittanceSampler;
layout(binding = 5) uniform samplerCube cubeMapTex;
layout(binding = 6) uniform sampler2D brdfTex;
layout(binding = 7) uniform sampler2DShadow shadowTextureA;
layout(binding = 8) uniform sampler2DShadow shadowTextureB;
layout(binding = 9) uniform sampler2DShadow shadowTextureC;
layout(binding = 10) uniform sampler2DShadow shadowTextureD;
layout(binding = 11) uniform sampler2DShadow rainDepthTexture;
layout(binding = 12) uniform sampler2D exposureSampler;

layout(location = 0) in vec2 outTexCoord;
layout(location = 1) in vec2 lifeColorOffset;
layout(location = 2) in vec3 outWorldPos;
layout(location = 3) in vec3 outSunPos;
layout(location = 4) in vec4 outLightAddition_cloudCover;
layout(location = 5) in vec4 outShadowCoords[4];
layout(location = 9) in vec3 outWorldViewVec;

layout(location = 0) out vec4 data;

void main()
{
    vec4 tex = texture(texMap, outTexCoord);
    vec4 texLife = vec4(1.0,1.0,1.0,1.0) * lifeColorOffset.x;
    vec4 combined = (tex * texLife * 0.3);
    

    vec3 normalToUse = normalize(outWorldPos);
    
    //vec3 reflectLookup				= -reflect( outWorldViewVec, normalToUse );
    
    //float NdotLToUse = 0.8;// clamp(dot( normalToUse, outSunPos ), 0.0, 1.0);
    
    float sunFade = outLightAddition_cloudCover.w * 0.9 + 0.1;
    float shadowBaseVisibility = 1.0;//pow(min(max(NdotLToUse - 0.01, 0.0) / 0.01, 1.0), 0.6);
    float shadowVisibility = mix(getShadowVisibility(shadowBaseVisibility, outShadowCoords, shadowTextureA,shadowTextureB,shadowTextureC,shadowTextureD), 0.0, sunFade);
    
    //vec3 reflectColor = textureLod( cubeMapTex, reflectLookup, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 diffuseColor = textureLod( cubeMapTex, normalToUse, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 sunColor = sunRadiance(transmittanceSampler, length(outWorldPos), dot(normalToUse, outSunPos));
    vec3 diffuseLit = (diffuseColor * 0.3) + (sunColor * 0.3 * shadowVisibility);//combined.xyz * ((1.0 - sunFade) * (sunColor * vec3(NdotLToUse) * shadowVisibility) + diffuseColor);// + outLightAddition_cloudCover.xyz);

    
    
    data.a = combined.a;
    data.rgb = hdrFinal(exposureSampler, diffuseLit);
}
