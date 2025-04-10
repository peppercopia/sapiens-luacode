
#include "uiRenderCommon.frag"

layout(binding = 2) uniform samplerCube cubeMapTex;
layout(binding = 3) uniform sampler2D brdfTex;
layout(binding = 4) uniform sampler2D fontTex;
layout(binding = 5) uniform sampler2D fontNormalTex;

#define PBR_MIP_LEVELS 7
#define saturate(x) clamp(x, 0.0, 1.0)

layout(location = 0) in vec4 outColor;
layout(location = 1) in vec2 outMaterial;
layout(location = 2) in vec4 outView_animationTimer;
layout(location = 3) in vec3 outNormal;
layout(location = 4) in vec2 outTex;
layout(location = 5) in mat4 outNormalMatrix;
//in vec3 outPos;

layout(location = 0) out vec4 data;

void main(void)
{
    vec3 normalTex = normalize((texture(fontNormalTex, outTex).rgb - vec3(0.5,0.5,0.5)) * vec3(-1.0,1.0,1.0) + vec3(0.0,0.0,1.0));

    vec3 normalToUse = (outNormalMatrix * vec4(normalTex, 1.0)).xyz;

    vec4 tex = texture(fontTex, outTex);

    float baseNDotL = dot( normalToUse, sunPos );

    float NdotL = clamp(baseNDotL, 0.0, 1.0);

    vec3 V = normalize(outView_animationTimer.xyz);

    vec3 diffuseLookup = textureLod( cubeMapTex, normalToUse * vec3(1,-1,1), PBR_MIP_LEVELS - 1 ).rgb;
    vec3 diffuseColor = adjustLightMapLookupForGameObjectIcon(diffuseLookup);

    vec3 diffuseLit = outColor.xyz * (vec3(NdotL) + diffuseColor);

    diffuseLit = diffuseLit * (1.0 - outMaterial.y);

    vec3 specularColor		= mix( vec3( 0.04 ), outColor.xyz, outMaterial.y );
    vec3 lookup				= -reflect( V, normalToUse );
    float mip				= PBR_MIP_LEVELS - 1 + log2(outMaterial.x);
    vec3 sampledColor		= textureLod( cubeMapTex, lookup * vec3(1,-1,1), mip ).rgb;
    //sampledColor = adjustLightMapLookupForGameObjectIcon(sampledColor);
    sampledColor = adjustLightMapLookupForUI(sampledColor);

    float NoV				= saturate( dot( normalToUse, V ) );
    vec3 EnvBRDF = texture( brdfTex, vec2(outMaterial.x, NoV)).rgb;
    vec3 reflectance		= (specularColor * EnvBRDF.x + EnvBRDF.y);
    
    vec3 lightReflect = vec3(1.0,1.0,1.0) * uiLightSpecular(normalToUse, V, sunPos, outMaterial.x) * 0.6;
  //  vec3 litColor = diffuseLit + (sampledColor) * reflectance;
  
    if(outMaterial.y > 0.01)
    {
        for(int lightIndex = 0; lightIndex < UI_LIGHT_COUNT; lightIndex++)
        {
            vec3 lightNormal = uiLightGetPosition(lightIndex, outView_animationTimer.w);
            float NdotLP        = clamp(dot( normalToUse, lightNormal ), 0.0, 1.0);
            if(NdotLP > 0.001)
            {
                lightReflect += vec3(uiLightIntensity) * uiLightSpecular(normalToUse, V, lightNormal, outMaterial.x) * NdotLP;
            }
        }
    }

    vec3 litColor = diffuseLit + (sampledColor + lightReflect) * reflectance * reflectanceMultiplier;
    

    vec4 result = vec4(uiHDR(litColor), 1.0);

    data = result * tex * outColor.a;
    
}