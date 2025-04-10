
#include "shadowCommon.frag"
#include "lightingCommon.frag"
#include "atmoRenderCommon.frag"

layout(binding = 2) uniform AtmoUniformBufferObject {
    float Rg;
    float Rt;
    float RL;
    float AVERAGE_GROUND_REFLECTANCE;

    vec4 betaRAndHR;
    vec4 betaMScaAndHM;
    vec4 betaMExAndmieG;

    int TRANSMITTANCE_W;
    int TRANSMITTANCE_H;
    int SKY_W;
    int SKY_H;
    int RES_R;
    int RES_MU;
    int RES_MU_S;
    int RES_NU;
} atmoUbo;

layout(binding = 3) uniform UniformBufferObjectFrag 
{
    vec4 sunPos;
    vec4 camDirection;
    vec4 lightOriginOffset;
    vec4 screenSize_cloudCover;
    ivec4 outputType_SSAOEnabled;
} ubo;


layout(binding = 4) uniform UniformBufferObjectLights
{ 
    vec4 lightPositions[MAX_LIGHTS];
    vec4 lightColors[MAX_LIGHTS];
    int lightCount;
} lights;

layout(binding = 5) uniform sampler2D transmittanceSampler;
layout(binding = 6) uniform sampler3D inscatterSampler;
layout(binding = 7) uniform samplerCube cubeMapTex;
layout(binding = 8) uniform sampler2D brdfTex;
layout(binding = 9) uniform sampler2DShadow shadowTextureA;
layout(binding = 10) uniform sampler2DShadow shadowTextureB;
layout(binding = 11) uniform sampler2DShadow shadowTextureC;
layout(binding = 12) uniform sampler2DShadow shadowTextureD;
layout(binding = 13) uniform sampler2D exposureSampler;
layout(binding = 14) uniform sampler2D decalTexMap;
layout(binding = 15) uniform sampler2D decalNormalMap;
layout(binding = 16) uniform sampler2D ssaoTexture;

layout(location = 0) in vec3 outPos;
layout(location = 1) in vec3 outWorldPos;
layout(location = 2) in vec3 outWorldCamPos;
layout(location = 3) in vec3 outView;
layout(location = 4) in vec3 outNormal;
layout(location = 5) in vec3 outWorldViewVec;
layout(location = 6) in vec4 outShadowCoords[4];

layout(location = 10) in vec4 outTex;
layout(location = 11) in float alpha;

layout(location = 12) in vec2 outMaterialA;
layout(location = 13) in vec2 outMaterialB;
layout(location = 14) in vec2 outMaterialC;
layout(location = 15) in vec2 outMaterialD;

layout(location = 16) in vec3 outColorA;
layout(location = 17) in vec3 outColorB;
layout(location = 18) in vec3 outColorC;
layout(location = 19) in vec3 outColorD;

layout(location = 20) in vec3 outUnmodifiedNormal;
layout(location = 21) in vec3 outForwardNormal;
layout(location = 22) in float depth;

layout(location = 0) out vec4 data;


void main()
{
    vec4 tex = texture(decalTexMap, outTex.xy);
    tex.gb = min(tex.gb / max(tex.r, 0.1), vec2(1.0,1.0));
    /*if(tex.r * alpha < 0.1)
    {
        discard;
    }*/
   // setFragDepthIfNeeded();

    //vec3 normalizedNormal = normalize(outNormal);
    vec3 V = normalize(outView);
    float viewDepth = depth;
    vec3 normalizedWorldPosition = normalize(outWorldPos);
    
    float outViewLength = length(outView);
    
    float baseDepthOffset = 0.0;
    if(depth > 0.0)
    {
        float viewAngle = dot(outView / outViewLength, normalizedWorldPosition);
        viewDepth = depth / max(0.8 + viewAngle * 0.2, 0.001);
        viewDepth = clamp((viewDepth * 6.0), 0.0, 1.0);
        viewDepth = pow(viewDepth, 0.5);
        
        baseDepthOffset = clamp((depth) * 200.0, 0.0, 1.0);
        baseDepthOffset = pow(baseDepthOffset, 0.6) * 0.8;
    }
    viewDepth = clamp(viewDepth, 0.0, 1.0);


    vec4 normalTextureValue = texture(decalNormalMap, outTex.xy);
    vec3 tNorm = normalize(normalTextureValue.rgb * 2.0 - 1.0);

    vec3 faceNormal = -outForwardNormal;
    /*if(!gl_FrontFacing)
    {
      faceNormal = -faceNormal;
    }*/
    if(dot(faceNormal, ubo.sunPos.xyz) < 0.0)
    {
      faceNormal = -faceNormal;
    }
    
    vec3 outNorm = normalize(mix(outNormal, faceNormal, 0.95));//normalize(mix(outNormal, V, outTexCoord.z));
    /*if(dot(outNorm, ubo.sunPos.xyz) < 0.0)
    {
        outNorm = -outNorm;
    }*/

   // vec3 outBinormal = normalize(cross(outNorm, normalize(outTangent)));
   // vec3 finalTangent = normalize(cross(outBinormal, outNorm));
    
    vec3 finalTangent = normalize(cross(faceNormal, outNormal));
    vec3 outBinormal = normalize(cross(outNorm, finalTangent));

    mat3 outTBN;
    outTBN[0] = finalTangent;
    outTBN[1] = outBinormal;
    outTBN[2] = outNorm;
    
    vec2 material = mix(mix(outMaterialA, outMaterialB, tex.g), mix(outMaterialC, outMaterialD, tex.g), tex.b);
    float roughnessToUse = material.x;
    roughnessToUse = mix(roughnessToUse, 1.0, baseDepthOffset);

    vec3 normalToUse = (outTBN) * tNorm;
    normalToUse = normalize(mix(outNormal, normalToUse, (0.02 + roughnessToUse * BUMP_MAPPING_STRENGTH) * smoothstep(0.0, 0.5, outTex.w)));


    //float NdotLToUseShadow = clamp(dot( outUnmodifiedNormal, ubo.sunPos.xyz ), 0.0, 1.0);
    float NdotLToUse = clamp(dot( normalToUse, ubo.sunPos.xyz ), 0.0, 1.0);
    float sunFade = ubo.screenSize_cloudCover.z * 0.9 + 0.1;
    float shadowBaseVisibility = 1.0;//pow(min(max(NdotLToUseShadow - 0.01, 0.0) / 0.01, 1.0), 0.6);
    //float shadowVisibility = getShadowVisibility(shadowBaseVisibility, outShadowCoords, shadowTextureA,shadowTextureB,shadowTextureC,shadowTextureD) * (1.0 - ubo.screenSize_cloudCover.z);
    float shadowVisibility = mix(getShadowVisibility(shadowBaseVisibility, outShadowCoords, shadowTextureA,shadowTextureB,shadowTextureC,shadowTextureD), 0.0, sunFade);
    shadowVisibility = mix(shadowVisibility, 0.0, clamp((viewDepth * 1.5), 0.0, 1.0));


    
    //material.x *= 0.3;//wet

    vec3 color = mix(mix(outColorA, outColorB, tex.g), mix(outColorC, outColorD, tex.g), tex.b);

    color = mix(color, vec3(0.02, 0.02, 0.02), baseDepthOffset);

    
    

    //vec3 outColor = mix(outColorB, outColorA, clamp(materialMixValue + heightGrainMixAddition, 0.0, 1.0));
   // vec2 outMaterial = mix(outMaterialB, outMaterialA, clamp(materialMixValue + heightGrainMixAddition, 0.0, 1.0));

    //color = color * color;

    vec3 extinction;
    vec3 inscatter = max(inScattering(atmoUbo.betaMExAndmieG, transmittanceSampler, inscatterSampler,outWorldCamPos, outWorldPos, outWorldViewVec, vec4(ubo.sunPos.xyz, sunFade), extinction), vec3(0.0));
    float ssaoValue = 1.0;
    if(ubo.outputType_SSAOEnabled.y == 1 && ubo.outputType_SSAOEnabled.x == 0)
    {
        vec2 ssaoTexCoord = gl_FragCoord.xy / ubo.screenSize_cloudCover.xy;
        ssaoTexCoord.y = 1.0 - ssaoTexCoord.y;
        ssaoValue = mix(texture(ssaoTexture, ssaoTexCoord).r, 1.0, tex.g);
    }
    vec3 diffuseColor = textureLod( cubeMapTex, normalToUse, PBR_MIP_LEVELS - 1 ).rgb * ssaoValue;
    vec3 sunColor = sunRadiance(transmittanceSampler, length(outWorldPos), dot(normalize(outWorldPos), ubo.sunPos.xyz)) * (1.0 - ubo.screenSize_cloudCover.z);
    vec3 diffuseLit = color.xyz * ((sunColor * NdotLToUse * shadowVisibility) + diffuseColor);
    
    //diffuseLit += color * getSpotlight(V, outView, normalizedNormal, ubo.camDirection.xyz);
    
    vec3 specularColor		= mix( vec3( 0.04), color, material.y );
    
    vec3 lookup				= -reflect( V, normalToUse );
    float mip				= PBR_MIP_LEVELS - 1 + log2(material.x);
    //vec3 sampledColor		= textureLod( cubeMapTex, (cubeMapMatrix * vec4(lookup, 1.0)).xyz, mip ).rgb * mix(clamp(shadowVisibility + 1.0 - dot(lookup, sunPos), 0.5, 1.0), 1.0, tex.g);
    vec3 sampledColor		= textureLod( cubeMapTex, lookup, mip ).rgb * ssaoValue;// * clamp(shadowVisibility + 1.0 - dot(lookup, ubo.sunPos.xyz), 0.5, 1.0) * ssaoValue;

    vec3 H = normalize(ubo.sunPos.xyz + V);
    float directDot = saturate( dot(H, normalToUse));
    
    float NoV				= saturate( dot( normalToUse, V ) );
    vec3 EnvBRDF = texture( brdfTex, vec2(material.x, NoV)).rgb;
    vec3 reflectance		= (specularColor * EnvBRDF.x + EnvBRDF.y);

    vec3 lightReflect = sunColor * lightSpecular(normalToUse, V, ubo.sunPos.xyz, material.x) * shadowVisibility * 0.3;
    if(ubo.outputType_SSAOEnabled.x == 0)
    {
        vec3 outColorBase = color.xyz * ssaoValue;
        for(int lightIndex = 0; lightIndex < lights.lightCount; lightIndex++)
        {
            vec3 distanceVec = (lights.lightPositions[lightIndex].xyz + ubo.lightOriginOffset.xyz - outPos) * LIGHT_DISTANCE_MULTIPLIER;
            float lightDistance2 = dot(distanceVec,distanceVec);
            if(lightDistance2 < MAX_LIGHT_DISTANCE2)
            {
                float fadeOutNearEdge = clamp((lightDistance2 - FADE_OUT_START_LIGHT_DISTANCE2) / FADE_OUT_DIVIDER_LIGHT_DISTANCE2, 0.0, 1.0);
                fadeOutNearEdge = 1.0 - fadeOutNearEdge;
                float att = mix(0.0, 0.1 / max(lightDistance2, 0.1), fadeOutNearEdge);
                vec3 lightNormal = normalize(distanceVec);
                float NdotLP        = mix(clamp(dot( normalToUse, lightNormal ), 0.0, 1.0), 0.3, outTex.w * 0.5);
                diffuseLit += outColorBase * lights.lightColors[lightIndex].xyz * NdotLP * att;
                
                lightReflect += lights.lightColors[lightIndex].xyz * lightSpecular(normalToUse, V, lightNormal, material.x) * att;
                //lightReflect += lights.lightColors[lightIndex].xyz * lightSpecular(normalizedNormal, V, lightNormal, material.x * 0.8 + 0.2) * att;
            }
        }
    }

    diffuseLit = diffuseLit * (1.0 - material.y);
    
   // vec3 litColor = ((normalToUse * 0.5) + vec3(0.5)) * 0.05; 
   // vec3 litColor = diffuseLit + (sampledColor + lightReflect) * reflectance * reflectanceMultiplier;   
    vec3 litColor = diffuseLit + (sampledColor + lightReflect) * reflectance * reflectanceMultiplier;    
    
    if(ubo.outputType_SSAOEnabled.x != 2)
    {
        vec3 waterDiffuseLit = vec3(0.005, 0.04, 0.08) * (sunColor * clamp(dot( normalizedWorldPosition, ubo.sunPos.xyz ), 0.0, 1.0) * (0.1 + shadowVisibility * 0.9) + diffuseColor);
        litColor = mix(litColor, waterDiffuseLit, viewDepth);
    }
    
    vec3 combined = litColor * extinction + inscatter;
    
    if(ubo.outputType_SSAOEnabled.x != 0)
    {
        data.rgb = combined;
    }
    else
    {
        data.rgb = hdrFinal(exposureSampler, combined);
    }

	//data.a = tex.r * alpha * min(tex.g * 16.0, 1.0) * clamp(((abs(dot(V,outForwardNormal))) - 0.5) * 4.0, 0.0, 1.0);
}
