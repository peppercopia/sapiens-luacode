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

layout(binding = 4) uniform sampler2D transmittanceSampler;
layout(binding = 5) uniform sampler3D inscatterSampler;
layout(binding = 6) uniform sampler2D brdfTex;

layout(location = 0) in vec3 outPos;
//layout(location = 1) in vec3 outWorldPos;
layout(location = 1) in vec3 outWorldCamPos;
//layout(location = 3) in vec3 outColors[3];
//layout(location = 6) in vec2 outMaterials[3];
layout(location = 2) in vec3 outView;
layout(location = 3) in vec3 outNormal;
layout(location = 4) in vec3 outWorldViewVec;
layout(location = 5) in float flow;
layout(location = 6) in float[3] vertWeights;

layout(location = 0) out vec4 data;




void main()
{
    vec3 outPosNormal = normalize(outPos);
    vec3 worldPosToUse = outPosNormal * 838860.8;
    vec3 worldViewVecToUse = outWorldViewVec;

     vec3 outColor = vec3(1.0,0.0,0.0);
    vec2 outMaterial = vec2(0.5,0.5);

    vec3 normalizedNormal = normalize(outNormal);
    float NdotLToUse = clamp(dot( normalizedNormal, ubo.sunPos_transition.xyz ), 0.0, 1.0);
    float shadowVisibility = 1.0;
    vec3 V = normalize(outView);// / outViewLength;
    
    vec3 sunColor = sunRadiance(transmittanceSampler, 838860.8, dot(outPosNormal, ubo.sunPos_transition.xyz));

    
    //vec3 waterDiffuseColor = textureLod( cubeMapTex, (ubo.cubeMapMatrix * vec4(normalize(worldPosToUse), 1.0)).xyz, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 waterDiffuseLit = vec3(0.0, 0.04, 0.06) * (sunColor * clamp(dot( outPosNormal, ubo.sunPos_transition.xyz ), 0.0, 1.0)) * 0.5;//((sunColor * vec3(NdotLToUse) * (mix(shadowVisibility, 1.0, 0.8))));
    //waterDiffuseLit = waterDiffuseLit + 
    
   // diffuseLit += outColor.xyz * getSpotlight(V, outView, normalizedNormal, ubo.camDirection.xyz);

    float roughness = 0.01;

    
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
    
    vec3 litColor = waterDiffuseLit + (lightReflect) * reflectance;

    vec3 combined = litColor * extinction + inscatter;

    data.rgb = hdrConst(combined);
	data.a = flow * ubo.sunPos_transition.w;
}
