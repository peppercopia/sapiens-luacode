
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



layout(binding = 3) uniform sampler2D transmittanceSampler;

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

// ----------------------------------------------------------------------------
// PARAMETERIZATION FUNCTIONS
// ----------------------------------------------------------------------------

vec2 getTransmittanceUV(float r, float mu) {
    float uR, uMu;
#ifdef TRANSMITTANCE_NON_LINEAR
	uR = sqrt((r - ubo.Rg) / (ubo.Rt - ubo.Rg));
	uMu = atan((mu + 0.15) / (1.0 + 0.15) * tan(1.5)) / 1.5;
#else
	uR = (r - ubo.Rg) / (ubo.Rt - ubo.Rg);
	uMu = (mu + 0.15) / (1.0 + 0.15);
#endif
    return vec2(uMu, uR);
}

void getTransmittanceRMu(out float r, out float muS) {
    r = gl_FragCoord.y / float(ubo.TRANSMITTANCE_H);
    muS = gl_FragCoord.x / float(ubo.TRANSMITTANCE_W);
#ifdef TRANSMITTANCE_NON_LINEAR
    r = ubo.Rg + (r * r) * (ubo.Rt - ubo.Rg);
    muS = -0.15 + tan(1.5 * muS) / tan(1.5) * (1.0 + 0.15);
#else
    r = ubo.Rg + r * (ubo.Rt - ubo.Rg);
    muS = -0.15 + muS * (1.0 + 0.15);
#endif
}

vec2 getIrradianceUV(float r, float muS) {
    float uR = (r - ubo.Rg) / (ubo.Rt - ubo.Rg);
    float uMuS = (muS + 0.2) / (1.0 + 0.2);
    return vec2(uMuS, uR);
}

void getIrradianceRMuS(out float r, out float muS) {
    r = ubo.Rg + (gl_FragCoord.y - 0.5) / (float(ubo.SKY_H) - 1.0) * (ubo.Rt - ubo.Rg);
    muS = -0.2 + (gl_FragCoord.x - 0.5) / (float(ubo.SKY_W) - 1.0) * (1.0 + 0.2);
}

vec4 texture4D(in sampler3D table, float r, float mu, float muS, float nu)
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
    return texture(table, vec3((uNu + uMuS) / float(ubo.RES_NU), uMu, uR)) * (1.0 - lerp) +
           texture(table, vec3((uNu + uMuS + 1.0) / float(ubo.RES_NU), uMu, uR)) * lerp;
}

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

// ----------------------------------------------------------------------------
// UTILITY FUNCTIONS
// ----------------------------------------------------------------------------

// nearest intersection of ray r,mu with ground or top atmosphere boundary
// mu=cos(ray zenith angle at ray origin)
float limit(float r, float mu) {
    float dout = -r * mu + sqrt(r * r * (mu * mu - 1.0) + ubo.RL * ubo.RL);
    float delta2 = r * r * (mu * mu - 1.0) + ubo.Rg * ubo.Rg;
    if (delta2 >= 0.0) {
        float din = -r * mu - sqrt(delta2);
        if (din >= 0.0) {
            dout = min(dout, din);
        }
    }
    return dout;
}


// optical depth for ray (r,mu) of length d, using analytic formula
// (mu=cos(view zenith angle)), intersections with ground ignored
// H=height scale of exponential density function
float opticalDepth(float H, float r, float mu, float d) {
    float a = sqrt((0.5/H)*r);
    vec2 a01 = a*vec2(mu, mu + d / r);
    vec2 a01s = sign(a01);
    vec2 a01sq = a01*a01;
    float x = a01s.y > a01s.x ? exp(a01sq.x) : 0.0;
    vec2 y = a01s / (2.3193*abs(a01) + sqrt(1.52*a01sq + 4.0)) * vec2(1.0, exp(-d/H*(d/(2.0*r)+mu)));
    return sqrt((6.2831*H)*r) * exp((ubo.Rg-r)/H) * (x + dot(y, vec2(1.0, -1.0)));
}

// transmittance(=transparency) of atmosphere for ray (r,mu) of length d
// (mu=cos(view zenith angle)), intersections with ground ignored
// uses analytic formula instead of transmittance texture
vec3 analyticTransmittance(float r, float mu, float d) {
    return exp(- ubo.betaRAndHR.xyz * opticalDepth(ubo.betaRAndHR.w, r, mu, d) - ubo.betaMExAndmieG.xyz * opticalDepth(ubo.betaMScaAndHM.w, r, mu, d));
}

// Rayleigh phase function
float phaseFunctionR(float mu) {
    return (3.0 / (16.0 * M_PI)) * (1.0 + mu * mu);
}

// Mie phase function
float phaseFunctionM(float mu) {
    float mieG = ubo.betaMExAndmieG.w;
	return 1.5 * 1.0 / (4.0 * M_PI) * (1.0 - mieG*mieG) * pow(1.0 + (mieG*mieG) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + mieG*mieG);
}

// approximated single Mie scattering (cf. approximate Cm in paragraph 'Angular precision')
vec3 getMie(vec4 rayMie) { // rayMie.rgb=C*, rayMie.w=Cm,r
vec3 betaR = ubo.betaRAndHR.xyz;
	return rayMie.rgb * rayMie.w / max(rayMie.r, 1e-4) * (betaR.r / betaR);
}


vec3 transmittance(float r, float mu) {
	vec2 uv = getTransmittanceUV(r, mu);
    return texture(transmittanceSampler, uv).rgb;
}

vec3 transmittance(float r, float mu, float d) {
    vec3 result;
    float r1 = sqrt(r * r + d * d + 2.0 * r * mu * d);
    float mu1 = (r * mu + d) / r1;
    if (mu > 0.0) {
        result = min(transmittance(r, mu) / transmittance(r1, mu1), 1.0);
    } else {
        result = min(transmittance(r1, -mu1) / transmittance(r, -mu), 1.0);
    }
    return result;
}


//end common

void integrand(float r, float mu, float muS, float nu, float t, out vec3 ray, out vec3 mie) {
    ray = vec3(0.0);
    mie = vec3(0.0);
    float ri = sqrt(r * r + t * t + 2.0 * r * mu * t);
    float muSi = (nu * t + muS * r) / ri;
    ri = max(ubo.Rg, ri);
    if (muSi >= -sqrt(1.0 - ubo.Rg * ubo.Rg / (ri * ri))) {
        vec3 ti = transmittance(r, mu, t) * transmittance(ri, muSi);
        ray = exp(-(ri - ubo.Rg) / ubo.betaRAndHR.w) * ti;
        mie = exp(-(ri - ubo.Rg) / ubo.betaMScaAndHM.w) * ti;
    }
}

void inscatter(float r, float mu, float muS, float nu, out vec3 ray, out vec3 mie) {
    ray = vec3(0.0);
    mie = vec3(0.0);
    float dx = limit(r, mu) / float(INSCATTER_INTEGRAL_SAMPLES);
    float xi = 0.0;
    vec3 rayi;
    vec3 miei;
    integrand(r, mu, muS, nu, 0.0, rayi, miei);
    for (int i = 1; i <= INSCATTER_INTEGRAL_SAMPLES; ++i) {
        float xj = float(i) * dx;
        vec3 rayj;
        vec3 miej;
        integrand(r, mu, muS, nu, xj, rayj, miej);
        ray += (rayi + rayj) / 2.0 * dx;
        mie += (miei + miej) / 2.0 * dx;
        xi = xj;
        rayi = rayj;
        miei = miej;
    }
    ray *= ubo.betaRAndHR.xyz;
    mie *= ubo.betaMScaAndHM.xyz;
}

void main() {
    vec3 ray;
    vec3 mie;
    float mu, muS, nu;
    getMuMuSNu(inscatterUBO.r.x, inscatterUBO.dhdH, mu, muS, nu);
    inscatter(inscatterUBO.r.x, mu, muS, nu, ray, mie);
    // store separately Rayleigh and Mie contributions, WITHOUT the phase function factor
    // (cf 'Angular precision')
    //data0 = vec4(ray, 1.0);
    data = vec4(mie, 1.0);
    //data1.rgb = mie;
}