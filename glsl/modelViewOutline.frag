
#include "uiRenderCommon.frag"

layout(binding = 2) uniform samplerCube cubeMapTex;
layout(binding = 3) uniform sampler2D brdfTex;

#define PBR_MIP_LEVELS 7
#define saturate(x) clamp(x, 0.0, 1.0)

layout(location = 0) in vec4 outColor;
layout(location = 1) in vec4 outMaterialUV;
layout(location = 2) in vec4 outView_animationTimer;
layout(location = 3) in vec3 outNormal;
//in vec3 outPos;

layout(location = 0) out vec4 data;

void main(void)
{
    vec3 normalToUse = normalize(outNormal);


    float NdotL = abs(dot( normalToUse, sunPos ));

    //float NdotL = clamp(baseNDotL, 0.0, 1.0);

    vec3 V = normalize(outView_animationTimer.xyz);

    vec3 diffuseColor = textureLod( cubeMapTex, normalToUse * vec3(1,-1,1), PBR_MIP_LEVELS - 1 ).rgb;

    vec3 diffuseLit = outColor.xyz * (vec3(NdotL) + diffuseColor);

    diffuseLit = diffuseLit * (1.0 - outMaterialUV.y);

    vec3 specularColor		= mix( vec3( 0.04 ), outColor.xyz, outMaterialUV.y );
    vec3 lookup				= -reflect( V, normalToUse );
    float mip				= PBR_MIP_LEVELS - 1 + log2(outMaterialUV.x);
    vec3 sampledColor		= textureLod( cubeMapTex, lookup * vec3(1,-1,1), mip ).rgb;

    float NdotV = dot( normalToUse, V );

    float NoV				= saturate(NdotV);
    vec3 EnvBRDF = texture( brdfTex, vec2(outMaterialUV.x, NoV)).rgb;
    vec3 reflectance		= (specularColor * EnvBRDF.x + EnvBRDF.y);
    
    vec3 lightReflect = vec3(1.0,1.0,1.0) * uiLightSpecular(normalToUse, V, sunPos, outMaterialUV.x);
  //  vec3 litColor = diffuseLit + (sampledColor) * reflectance;

    vec3 litColor = diffuseLit + (sampledColor + lightReflect) * reflectance * reflectanceMultiplier;

    data.rgb = uiHDR(litColor) * 1.5;
    
    data.a = outColor.a * 0.2;
    
}
