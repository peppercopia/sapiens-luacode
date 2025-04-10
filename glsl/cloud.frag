#include "shadowCommon.frag"
#include "lightingCommon.frag"
#include "atmoRenderCommon.frag"

layout(binding = 3) uniform sampler2D cloudMapN;
layout(binding = 4) uniform sampler2D cloudMapP;
layout(binding = 5) uniform sampler2D transmittanceSampler;
layout(binding = 6) uniform samplerCube cubeMapTex;
layout(binding = 7) uniform sampler2D brdfTex;
layout(binding = 8) uniform sampler2DShadow shadowTextureA;
layout(binding = 9) uniform sampler2DShadow shadowTextureB;
layout(binding = 10) uniform sampler2DShadow shadowTextureC;
layout(binding = 11) uniform sampler2DShadow shadowTextureD;
layout(binding = 12) uniform sampler2DShadow rainDepthTexture;
layout(binding = 13) uniform sampler2D exposureSampler;
layout(binding = 14) uniform sampler3D inscatterSampler;


layout(binding = 15) uniform AtmoUniformBufferObject {
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

layout(location = 0) in vec2 outTexCoord;
layout(location = 1) in vec3 outWorldPos;
layout(location = 2) in vec3 outSunPos;
layout(location = 3) in vec4 outLightAddition_cloudCover;
layout(location = 4) in vec3 outSunPosLocal;
layout(location = 5) in vec3 outWorldCamPos;
layout(location = 6) in vec3 outWorldViewVec;
layout(location = 7) flat in ivec4 outputType_SSAOEnabled;
layout(location = 8) in vec2 outAlphaDepthMultiplier;
layout(location = 9) in mat3 outMatrix;

layout(location = 0) out vec4 data;

void main()
{
    vec4 texN = texture(cloudMapN, outTexCoord);
    vec4 texP = texture(cloudMapP, outTexCoord);
    float alpha = pow(texN.a * texP.a * outAlphaDepthMultiplier.x, 0.6);


    float cloudAltitude = length(outWorldPos);
    float camAltitude = length(outWorldCamPos);

    alpha = alpha * clamp((cloudAltitude - camAltitude + 50.0) * 0.01, 0.0, 1.0);

    if(alpha < 0.001)
    {
        discard;
    }

    vec3 cloudLightAmount = vec3(mix(texN.x, texP.x, smoothstep(-0.1, 0.1, outSunPosLocal.x)),
                                mix(texN.y, texP.y, smoothstep(-0.1, 0.1, outSunPosLocal.y)),
                                mix(texN.z, texP.z, smoothstep(-0.1, 0.1, outSunPosLocal.z)));

    float cloudLight = cloudLightAmount.x * abs(outSunPosLocal.x) + cloudLightAmount.y * abs(outSunPosLocal.y) + cloudLightAmount.z * abs(outSunPosLocal.z);
    cloudLight = pow(cloudLight, 4.0);
    
    float sunFade = outLightAddition_cloudCover.w * 0.9 + 0.1;

    
    vec3 extinction;
    vec3 inscatter = max(inScattering(atmoUbo.betaMExAndmieG, transmittanceSampler, inscatterSampler, outWorldCamPos, outWorldPos, outWorldViewVec, vec4(outSunPos.xyz, outLightAddition_cloudCover.w * 0.99), extinction), vec3(0.0));

    vec3 normalToUse = normalize(outWorldPos);

    vec3 upVec = normalToUse;
    vec3 rightVec = outMatrix[0];
    vec3 forwardVec = outMatrix[2];
    
    vec3 diffuseColorUp = textureLod( cubeMapTex, upVec, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 diffuseColorRight = textureLod( cubeMapTex, rightVec, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 diffuseColorLeft = textureLod( cubeMapTex, -rightVec, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 diffuseColorForward = textureLod( cubeMapTex, forwardVec, PBR_MIP_LEVELS - 1 ).rgb;
    vec3 diffuseColorBack = textureLod( cubeMapTex,- forwardVec, PBR_MIP_LEVELS - 1 ).rgb;

    vec3 diffuse = diffuseColorUp * texP.y;
    diffuse += diffuseColorRight * texP.x;
    diffuse += diffuseColorLeft * texN.x;
    diffuse += diffuseColorForward * texP.z;
    diffuse += diffuseColorBack * texN.z;

    vec3 sunColor = sunRadiance(transmittanceSampler, cloudAltitude, dot(normalToUse, outSunPos));
    vec3 diffuseLit = vec3(0.11 * (1.0 - sunFade)) * (sunColor * cloudLight) + diffuse * 0.15;

    
    vec3 combined = diffuseLit * 0.8 * extinction + inscatter;
    
    data.a = alpha;
    if(outputType_SSAOEnabled.x != 0)
    {
        data.rgb = combined;
    }
    else
    {
        data.rgb = hdrFinal(exposureSampler, combined);
    }
}
