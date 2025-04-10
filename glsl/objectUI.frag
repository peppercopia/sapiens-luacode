
#include "uiRenderCommon.frag"

layout(binding = 2) uniform samplerCube cubeMapTex;
layout(binding = 3) uniform sampler2D brdfTex;
layout(binding = 4) uniform sampler2D objectDetailsTexture;

#define PBR_MIP_LEVELS 7
#define saturate(x) clamp(x, 0.0, 1.0)

layout(location = 0) in vec4 outColor;
layout(location = 1) in vec4 outMaterialUV;
layout(location = 2) in vec4 outView_animationTimer;
layout(location = 3) in vec3 outNormal;
layout(location = 4) in vec4 outPos_radialFraction;
layout(location = 5) in vec3 outColorB;
layout(location = 6) in vec2 outMaterialB;
layout(location = 7) in vec3 outTangent;
layout(location = 8) in mat3 outRotMatrix;
//in vec3 outPos;

layout(location = 0) out vec4 data;

void main(void)
{
    
    vec4 texMapValue = texture(objectDetailsTexture, outMaterialUV.zw);
    float mixValue = min(texMapValue.a * 2.0, 1.0);
    float roughnessToUse =  mix(outMaterialUV.x, outMaterialB.x, mixValue);
    float metalToUse = mix(outMaterialUV.y, outMaterialB.y, mixValue);

    vec3 tNorm = normalize(texMapValue.rgb * 2.0 - 1.0);
    vec3 outNorm = normalize(outNormal);
    if(!gl_FrontFacing)
    {
      outNorm = -outNorm;
    }
    vec3 finalTangent = normalize(outTangent);
    vec3 outBinormal = normalize(cross(outNorm, finalTangent));

    mat3 outTBN;
    outTBN[0] = finalTangent;
    outTBN[1] = outBinormal;
    outTBN[2] = outNorm;

    vec3 normalToUse = (outTBN) * tNorm;
    normalToUse = normalize(mix(outNorm, normalToUse, 0.02 + roughnessToUse * UI_BUMP_MAPPING_STRENGTH));


    float NdotL = abs(dot( normalToUse, sunPos ));

    vec3 V = normalize(outView_animationTimer.xyz);

    vec3 diffuseColor = textureLod( cubeMapTex, normalToUse * vec3(1,-1,-1), PBR_MIP_LEVELS - 1 ).rgb;
    diffuseColor = adjustLightMapLookupForUI(diffuseColor);

    vec3 colorToUse = mix(outColor.xyz, outColorB, mixValue);
    colorToUse = colorToUse * colorToUse;

    vec3 diffuseLit = colorToUse * (vec3(NdotL) + diffuseColor);

    diffuseLit = diffuseLit * (1.0 - metalToUse);

    vec3 specularColor		= mix( vec3( 0.04 ), colorToUse, metalToUse );

    vec3 lookup				= -reflect( V, normalToUse );
    float mip				= PBR_MIP_LEVELS - 1 + log2(roughnessToUse);
    vec3 sampledColor		= textureLod( cubeMapTex, lookup * vec3(1,-1,-1), mip ).rgb;
    sampledColor = adjustLightMapLookupForUI(sampledColor);// * (1.0 + metalToUse);

    float NoV				= saturate( dot( normalToUse, V ) );
    vec3 EnvBRDF = texture( brdfTex, vec2(roughnessToUse, NoV)).rgb;
    vec3 reflectance		= (specularColor * EnvBRDF.x + EnvBRDF.y);
    
    vec3 lightReflect = vec3(1.0,1.0,1.0) * uiLightSpecular(normalToUse, V, sunPos, roughnessToUse) * 0.6;// * (0.6 + metalToUse * 10.0);

    if(metalToUse > 0.01)
    {
        for(int lightIndex = 0; lightIndex < UI_LIGHT_COUNT; lightIndex++)
        {
            vec3 lightNormal = normalize(outRotMatrix * uiLightGetPosition(lightIndex, outView_animationTimer.w));
            float NdotLP        = clamp(dot( normalToUse, lightNormal ), 0.0, 1.0);
            if(NdotLP > 0.001)
            {
                lightReflect += vec3(uiLightIntensity) * uiLightSpecular(normalToUse, V, lightNormal, roughnessToUse) * NdotLP;
            }
        }
    }

    vec3 litColor = diffuseLit + (sampledColor + lightReflect) * reflectance * reflectanceMultiplier;

    //litColor = vec3(V * 0.5 + vec3(0.5)) * 0.1;
    

    data.rgb = uiHDR(litColor);
    
    data.a = outColor.a;
    
}
