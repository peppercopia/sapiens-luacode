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
    vec4 sunPos_transition;
    //vec4 camDirection;
} ubo;

const float matTexSize = 4096;

layout(binding = 4) uniform sampler2D transmittanceSampler;
layout(binding = 5) uniform sampler3D inscatterSampler;
layout(binding = 6) uniform sampler2D brdfTex;
layout(binding = 7) uniform sampler2D materialTexture;
layout(binding = 8) uniform sampler2D materialIndexTexture;
layout(binding = 9) uniform sampler2D materialBlendTexture;

layout(location = 0) in vec3 outPos;
//layout(location = 1) in vec3 outWorldPos;
layout(location = 1) in vec3 outWorldCamPos;
layout(location = 2) in vec3 outView;
layout(location = 3) in vec3 outNormal;
layout(location = 4) in vec3 outWorldViewVec;
layout(location = 5) in float depth;
layout(location = 6) in vec2 outMatTex;
layout(location = 7) in vec2 outMatBlendTex;

layout(location = 0) out vec4 data;




void main()
{
    vec3 outPosNormal = normalize(outPos);
    vec3 worldPosToUse = outPosNormal * 838860.8;
    vec3 worldViewVecToUse = outWorldViewVec;

    
    float viewDepth = depth;
    
    if(depth > 0.0)
    {
        //float viewAngle = dot(normalize(outView), normalize(outWorldPos));
        viewDepth = depth;// / max(viewAngle, 0.001);

        //worldPosToUse = outWorldPos + viewDepth * (normalize(outView) * 8.388608);
        worldViewVecToUse = (worldPosToUse - outWorldCamPos);
        
        if(viewDepth > 0.0)
        {
            viewDepth = viewDepth * 0.004 + 0.8;
        }

       // viewDepth = viewDepth + pow(depth, 0.3);
    }


    vec4 indexTexValue = texture(materialIndexTexture, outMatBlendTex);

    vec4 matTexValueA = texture(materialTexture, outMatTex + vec2((indexTexValue.x * 255.0) / matTexSize,0.0) + vec2(0.5,0.5) / matTexSize);
    vec4 matTexValueB = texture(materialTexture, outMatTex + vec2((indexTexValue.y * 255.0) / matTexSize,0.0) + vec2(0.5,0.5) / matTexSize);
    vec4 matTexValueC = texture(materialTexture, outMatTex + vec2((indexTexValue.z * 255.0) / matTexSize,0.0) + vec2(0.5,0.5) / matTexSize);
    
    vec4 materialWeightValue = texture(materialBlendTexture, outMatBlendTex);
    materialWeightValue = materialWeightValue / (materialWeightValue.x + materialWeightValue.y + materialWeightValue.z);
    
    vec3 outColor = matTexValueA.xyz * materialWeightValue.x + matTexValueB.xyz * materialWeightValue.y + matTexValueC.xyz * materialWeightValue.z;
    float matValue = matTexValueA.w * materialWeightValue.x + matTexValueB.w * materialWeightValue.y + matTexValueC.w * materialWeightValue.z;
    vec2 outMaterial = vec2(matValue * 2.0, 0.0);
    
    outColor = outColor * outColor * 0.8;
    
    if(viewDepth > 0.0)
    {
        outColor = outColor + vec3(0.1,0.5,0.7) * 0.2;
    }

    vec3 normalizedNormal = normalize(outNormal);
    float NdotLToUse = clamp(dot( normalizedNormal, ubo.sunPos_transition.xyz ), 0.0, 1.0);
    float shadowVisibility = 1.0;
    vec3 V = normalize(outView);// / outViewLength;
    
    vec3 sunColor = sunRadiance(transmittanceSampler, length(worldPosToUse), dot(outPosNormal, ubo.sunPos_transition.xyz));
    vec3 diffuseLit = outColor.xyz * ((sunColor * vec3(NdotLToUse) * shadowVisibility));

    
    //vec3 waterDiffuseColor = textureLod( cubeMapTex, (ubo.cubeMapMatrix * vec4(outPosNormal, 1.0)).xyz, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 waterDiffuseLit = vec3(0.01, 0.045, 0.06) * (sunColor * clamp(dot( outPosNormal, ubo.sunPos_transition.xyz ), 0.0, 1.0)) * 0.5 * (0.1 + shadowVisibility * 0.9);//((sunColor * vec3(NdotLToUse) * (mix(shadowVisibility, 1.0, 0.8))));
    //vec3 waterDiffuseLit = vec3(0.01, 0.045, 0.06) * (sunColor * clamp(dot( normalizedWorldPosition, ubo.sunPos.xyz ), 0.0, 1.0) * (0.1 + shadowVisibility * 0.9) + diffuseColor);
    //waterDiffuseLit = waterDiffuseLit + 
    
   // diffuseLit += outColor.xyz * getSpotlight(V, outView, normalizedNormal, ubo.camDirection.xyz);

   float roughness = outMaterial.x;
    roughness = mix(roughness, 0.01, clamp(viewDepth, 0.0, 1.0));

    
    vec3 N                  = normalizedNormal;
    vec3 specularColor		= mix( vec3( 0.04), outColor, outMaterial.y );

    vec3 H = normalize(ubo.sunPos_transition.xyz + V);
    float directDot = saturate( dot(H, N));
    
    float NoV				= saturate( dot( N, V ) );
    vec3 EnvBRDF = texture( brdfTex, vec2(roughness, NoV)).rgb;
    vec3 reflectance		= (specularColor * EnvBRDF.x + EnvBRDF.y);

    vec3 lightReflect = sunColor * lightSpecular(normalizedNormal, V, ubo.sunPos_transition.xyz, roughness) * shadowVisibility;

    
    vec3 extinction;
    vec3 inscatter = max(inScattering(atmoUbo.betaMExAndmieG, transmittanceSampler, inscatterSampler, outWorldCamPos, worldPosToUse, worldViewVecToUse, vec4(ubo.sunPos_transition.xyz, 0.0), extinction), vec3(0.0));
    //vec3 inscatter = max(inScattering(atmoUbo.betaMExAndmieG, transmittanceSampler, inscatterSampler, outWorldCamPos, worldPosToUse, worldViewVecToUse, normalize(vec3(0.3,0.3,0.3)), extinction), vec3(0.0));
    //vec3 litColor = vec3(0.0,0.0,0.0);
   // vec3 combined = litColor * extinction + inscatter;

    
    diffuseLit = diffuseLit * (1.0 - outMaterial.y);
    
    vec3 litColor = diffuseLit + (lightReflect) * reflectance;
    litColor = mix(litColor, waterDiffuseLit + (lightReflect) * reflectance, clamp(viewDepth, 0.0, 1.0));

    vec3 combined = litColor * extinction + inscatter;

    data.rgb = hdrConst(combined);
	data.a = 1.0;
}
