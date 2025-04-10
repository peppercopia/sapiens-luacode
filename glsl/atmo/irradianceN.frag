
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

layout(binding = 2) uniform IrradianceNUBO {
    vec4 first;
} irradianceNUBO;

layout(binding = 3) uniform sampler2D deltaSRSampler[32];
layout(binding = 4) uniform sampler2D deltaSMSampler[32];


// ----------------------------------------------------------------------------
// NUMERICAL INTEGRATION PARAMETERS
// ----------------------------------------------------------------------------

const int TRANSMITTANCE_INTEGRAL_SAMPLES = 500;
const int INSCATTER_INTEGRAL_SAMPLES = 50;
const int IRRADIANCE_INTEGRAL_SAMPLES = 32;
const int INSCATTER_SPHERICAL_INTEGRAL_SAMPLES = 16;


const float M_PI = 3.141592657;

// ----------------------------------------------------------------------------
// PARAMETERIZATION OPTIONS
// ----------------------------------------------------------------------------

#define TRANSMITTANCE_NON_LINEAR
#define INSCATTER_NON_LINEAR

/*uniform sampler3D deltaSRSampler;
uniform sampler3D deltaSMSampler;
uniform float first;*/

const float dphi = M_PI / float(IRRADIANCE_INTEGRAL_SAMPLES);
const float dtheta = M_PI / float(IRRADIANCE_INTEGRAL_SAMPLES);



// Rayleigh phase function
float phaseFunctionR(float mu) {
    return (3.0 / (16.0 * M_PI)) * (1.0 + mu * mu);
}

// Mie phase function
float phaseFunctionM(float mu) {
    float mieG = ubo.betaMExAndmieG.w;
	return 1.5 * 1.0 / (4.0 * M_PI) * (1.0 - mieG*mieG) * pow(1.0 + (mieG*mieG) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + mieG*mieG);
}



void getIrradianceRMuS(out float r, out float muS) {
    r = ubo.Rg + (gl_FragCoord.y - 0.5) / (float(ubo.SKY_H) - 1.0) * (ubo.Rt - ubo.Rg);
    muS = -0.2 + (gl_FragCoord.x - 0.5) / (float(ubo.SKY_W) - 1.0) * (1.0 + 0.2);
}


vec4 mjTexture3D(in sampler2D tex[32], vec3 texCoord)
{
    float texZ = texCoord.z * 32.0;
    int base = int(texZ);
    int baseMin = clamp(base,0,31);
    int baseMax = clamp(base + 1,0,31);

    vec4 a = texture(tex[baseMin], texCoord.xy);
    vec4 b = texture(tex[baseMax], texCoord.xy);
    return mix(a, b, fract(texZ));
}

vec4 texture4D(in sampler2D table[32], float r, float mu, float muS, float nu)
{
    float H = sqrt(ubo.Rt * ubo.Rt - ubo.Rg * ubo.Rg);
    float rho = sqrt(r * r - ubo.Rg * ubo.Rg);
#ifdef INSCATTER_NON_LINEAR
    float rmu = r * mu;
    float delta = rmu * rmu - r * r + ubo.Rg * ubo.Rg;
    vec4 cst = rmu < 0.0 && delta > 0.0 ? vec4(1.0, 0.0, 0.0, 0.5 - 0.5 / float(ubo.RES_MU)) : vec4(-1.0, H * H, H, 0.5 + 0.5 / float(ubo.RES_MU));
	float uR = 0.5 / float(ubo.RES_R) + rho / H * (1.0 - 1.0 / float(ubo.RES_R));
    float uMu = cst.w + (rmu * cst.x + sqrt(delta + cst.y)) / (rho + cst.z) * (0.5 - 1.0 / float(ubo.RES_MU));
    // paper formula
    //float uMuS = 0.5 / float(ubo.RES_MU_S) + max((1.0 - exp(-3.0 * muS - 0.6)) / (1.0 - exp(-3.6)), 0.0) * (1.0 - 1.0 / float(ubo.RES_MU_S));
    // better formula
    float uMuS = 0.5 / float(ubo.RES_MU_S) + (atan(max(muS, -0.1975) * tan(1.26 * 1.1)) / 1.1 + (1.0 - 0.26)) * 0.5 * (1.0 - 1.0 / float(ubo.RES_MU_S));
#else
	float uR = 0.5 / float(ubo.RES_R) + rho / H * (1.0 - 1.0 / float(ubo.RES_R));
    float uMu = 0.5 / float(ubo.RES_MU) + (mu + 1.0) / 2.0 * (1.0 - 1.0 / float(ubo.RES_MU));
    float uMuS = 0.5 / float(ubo.RES_MU_S) + max(muS + 0.2, 0.0) / 1.2 * (1.0 - 1.0 / float(ubo.RES_MU_S));
#endif
    float lerp = (nu + 1.0) / 2.0 * (float(ubo.RES_NU) - 1.0);
    float uNu = floor(lerp);
    lerp = lerp - uNu;
    return mjTexture3D(table, vec3((uNu + uMuS) / float(ubo.RES_NU), uMu, uR)) * (1.0 - lerp) +
           mjTexture3D(table, vec3((uNu + uMuS + 1.0) / float(ubo.RES_NU), uMu, uR)) * lerp;
}

void main() {
    float r, muS;
    getIrradianceRMuS(r, muS);
    vec3 s = vec3(sqrt(max(1.0 - muS * muS, 0.0)), 0.0, muS);

    vec3 result = vec3(0.0);
    // integral over 2.PI around x with two nested loops over w directions (theta,phi) -- Eq (15)
    for (int iphi = 0; iphi < 2 * IRRADIANCE_INTEGRAL_SAMPLES; ++iphi) {
        float phi = (float(iphi) + 0.5) * dphi;
        for (int itheta = 0; itheta < IRRADIANCE_INTEGRAL_SAMPLES / 2; ++itheta) {
            float theta = (float(itheta) + 0.5) * dtheta;
            float dw = dtheta * dphi * sin(theta);
            vec3 w = vec3(cos(phi) * sin(theta), sin(phi) * sin(theta), cos(theta));
            float nu = dot(s, w);
            if (irradianceNUBO.first.x > 0.5) {
                // first iteration is special because Rayleigh and Mie were stored separately,
                // without the phase functions factors; they must be reintroduced here
                float pr1 = phaseFunctionR(nu);
                float pm1 = phaseFunctionM(nu);
                vec3 ray1 = texture4D(deltaSRSampler, r, w.z, muS, nu).rgb;
                vec3 mie1 = texture4D(deltaSMSampler, r, w.z, muS, nu).rgb;
                result += (ray1 * pr1 + mie1 * pm1) * w.z * dw;
            } else {
                result += texture4D(deltaSRSampler, r, w.z, muS, nu).rgb * w.z * dw;
            }
        }
    }

    data = vec4(result, 1.0);
}