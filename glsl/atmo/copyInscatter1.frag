
layout(location = 0) out vec4 data;

layout(binding = 1) uniform AtmoCommonUniformBufferObjectFrag {
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
} ubo;

layout(binding = 2) uniform InscatterUBO {
    int layer;
} inscatterUBO;

layout(binding = 3) uniform sampler2D deltaSRSampler[32];
layout(binding = 4) uniform sampler2D deltaSMSampler[32];


vec4 mjTexture3D(in sampler2D tex[32], vec3 texCoord)
{
    float texZ = fract(texCoord.z) * 32.0;
    int base = int(texZ);
    int baseMin = clamp(base,0,31);
    int baseMax = clamp(base + 1,0,31);

    vec4 a = texture(tex[baseMin], texCoord.xy);
    vec4 b = texture(tex[baseMax], texCoord.xy);
    return mix(a, b, fract(texZ));
}

void main() {
    vec3 uvw = vec3(gl_FragCoord.xy, float(inscatterUBO.layer) + 0.5) / vec3(ivec3(ubo.RES_MU_S * ubo.RES_NU, ubo.RES_MU, ubo.RES_R));
    vec4 ray = mjTexture3D(deltaSRSampler, uvw);
    vec4 mie = mjTexture3D(deltaSMSampler, uvw);
    data = vec4(ray.rgb, mie.r); // store only red component of single Mie scattering (cf. 'Angular precision')
}