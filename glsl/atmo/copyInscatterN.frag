
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
    vec4 dhdH;
    vec4 r;
    int layer;
} inscatterUBO;

layout(binding = 3) uniform sampler2D deltaSRSampler[32];
layout(binding = 4) uniform sampler2D otherInscatterSampler[32];


const float M_PI = 3.141592657;

void getMuMuSNu(float r, vec4 dhdH, out float mu, out float muS, out float nu) {
    float x = gl_FragCoord.x - 0.5;
    float y = gl_FragCoord.y - 0.5;
#ifdef INSCATTER_NON_LINEAR
    if (y < float(ubo.RES_MU) / 2.0) {
        float d = 1.0 - y / (float(ubo.RES_MU) / 2.0 - 1.0);
        d = min(max(dhdH.z, d * dhdH.w), dhdH.w * 0.999);
        mu = (ubo.Rg * ubo.Rg - r * r - d * d) / (2.0 * r * d);
        mu = min(mu, -sqrt(1.0 - (ubo.Rg / r) * (ubo.Rg / r)) - 0.001);
    } else {
        float d = (y - float(ubo.RES_MU) / 2.0) / (float(ubo.RES_MU) / 2.0 - 1.0);
        d = min(max(dhdH.x, d * dhdH.y), dhdH.y * 0.999);
        mu = (ubo.Rt * ubo.Rt - r * r - d * d) / (2.0 * r * d);
    }
    muS = mod(x, float(ubo.RES_MU_S)) / (float(ubo.RES_MU_S) - 1.0);
    // paper formula
    //muS = -(0.6 + log(1.0 - muS * (1.0 -  exp(-3.6)))) / 3.0;
    // better formula
    muS = tan((2.0 * muS - 1.0 + 0.26) * 1.1) / tan(1.26 * 1.1);
    nu = -1.0 + floor(x / float(ubo.RES_MU_S)) / (float(ubo.RES_NU) - 1.0) * 2.0;
#else
    mu = -1.0 + 2.0 * y / (float(ubo.RES_MU) - 1.0);
    muS = mod(x, float(ubo.RES_MU_S)) / (float(ubo.RES_MU_S) - 1.0);
    muS = -0.2 + muS * 1.2;
    nu = -1.0 + floor(x / float(ubo.RES_MU_S)) / (float(ubo.RES_NU) - 1.0) * 2.0;
#endif
}


// Rayleigh phase function
float phaseFunctionR(float mu) {
    return (3.0 / (16.0 * M_PI)) * (1.0 + mu * mu);
}

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
    float mu, muS, nu;
    getMuMuSNu(inscatterUBO.r.x, inscatterUBO.dhdH, mu, muS, nu);
    vec3 uvw = vec3(gl_FragCoord.xy, float(inscatterUBO.layer) + 0.5) / vec3(ivec3(ubo.RES_MU_S * ubo.RES_NU, ubo.RES_MU, ubo.RES_R));
    data = vec4(mjTexture3D(deltaSRSampler, uvw).rgb / phaseFunctionR(nu), 0.0) + texture(otherInscatterSampler[inscatterUBO.layer], uvw.xy);
}
