
#include "uiRenderCommon.frag"

layout(binding = 2) uniform UniformBufferObjectFrag 
{
    vec4 sunPos;
} ubo;

layout(binding = 3) uniform samplerCube cubeMapTex;
layout(binding = 4) uniform sampler2D brdfTex;
layout(binding = 5) uniform sampler2D decalTexMap;

#define PBR_MIP_LEVELS 7
#define saturate(x) clamp(x, 0.0, 1.0)

layout(location = 0) in vec3 outColor;
layout(location = 1) in vec2 outMaterial;
layout(location = 2) in vec4 outView_animationTimer;
layout(location = 3) in vec3 outNormal;
layout(location = 4) in vec3 outFaceNormal;
layout(location = 5) in vec2 outTexCoord;
layout(location = 6) in vec3 outColorB;
layout(location = 7) in vec2 outMaterialB;
//in vec3 outPos;

layout(location = 0) out vec4 data;

void main(void)
{
    vec3 V = normalize(outView_animationTimer.xyz);
    
    float alpha = clamp((abs(dot(outFaceNormal, V))), 0.0, 1.0);
    alpha = smoothstep(0.3,0.6,alpha);
    //alpha = smoothstep(0.8,0.4,alpha);
    if(alpha < 0.1)
    {
        discard;
    }
    
    vec4 tex = texture(decalTexMap, outTexCoord);

    vec3 normalToUse = normalize(outNormal);

    float baseNDotL = dot( normalToUse, ubo.sunPos.xyz );

    float NdotL = clamp(baseNDotL, 0.0, 1.0);


   // vec3 diffuseColor = textureLod( cubeMapTex, normalToUse * vec3(1,-1,1), PBR_MIP_LEVELS - 1 ).rgb;
    vec3 diffuseLookup = textureLod( cubeMapTex, normalToUse * vec3(1,-1,1), PBR_MIP_LEVELS - 1 ).rgb;
    //vec3 diffuseColor = mix(diffuseLookup, vec3(diffuseLookup.y), 0.7) + vec3(0.05,0.05,0.05) * 1.0;
    vec3 diffuseColor = adjustLightMapLookupForGameObjectIcon(diffuseLookup);

    
    float mixValue = tex.g;
    float roughnessToUse = mix(outMaterial.x, outMaterialB.x, mixValue);
    vec3 colorToUse = mix(outColor, outColorB, mixValue);
    colorToUse = colorToUse * colorToUse;

    vec3 diffuseLit = colorToUse.xyz * (vec3(NdotL) + diffuseColor);
    //vec3 diffuseLit = colorToUse.xyz * (vec3(NdotL) + diffuseColor);

    diffuseLit = diffuseLit * (1.0 - outMaterial.y);

    vec3 specularColor		= mix( vec3( 0.04 ), colorToUse, outMaterial.y );
    vec3 lookup				= -reflect( V, normalToUse );
    float mip				= PBR_MIP_LEVELS - 1 + log2(roughnessToUse);
    vec3 sampledColor		= textureLod( cubeMapTex, lookup * vec3(1,-1,1), mip ).rgb;
    sampledColor = adjustLightMapLookupForGameObjectIcon(sampledColor);

    float NoV				= saturate( dot( normalToUse, V ) );
    vec3 EnvBRDF = texture( brdfTex, vec2(roughnessToUse, NoV)).rgb;
    vec3 reflectance		= (specularColor * EnvBRDF.x + EnvBRDF.y);
    
   // vec3 litColor = diffuseLit + (sampledColor) * reflectance;
    
    vec3 lightReflect = vec3(uiLightSpecular(normalToUse, V, ubo.sunPos.xyz, roughnessToUse));
    
    vec3 litColor = diffuseLit + (sampledColor + lightReflect) * reflectance * reflectanceMultiplier;

    data.rgb = uiHDR(litColor);
    
    data.a = tex.r * alpha;
    
}
