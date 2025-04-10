
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
    vec4 rAndFirst;
    int layer;
} inscatterUBO;



layout(binding = 3) uniform sampler2D transmittanceSampler;
layout(binding = 4) uniform sampler2D deltaESampler;
layout(binding = 5) uniform sampler2D deltaSRSampler[32];
layout(binding = 6) uniform sampler2D deltaSMSampler[32];



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



vec3 irradiance(in sampler2D samplerIn, float r, float muS) {
    vec2 uv = getIrradianceUV(r, muS);
    return texture(samplerIn, uv).rgb;
}

//end common


const float dphi = M_PI / float(INSCATTER_SPHERICAL_INTEGRAL_SAMPLES);
const float dtheta = M_PI / float(INSCATTER_SPHERICAL_INTEGRAL_SAMPLES);

void inscatter(float r, float mu, float muS, float nu, out vec3 raymie) {
    r = clamp(r, ubo.Rg, ubo.Rt);
    mu = clamp(mu, -1.0, 1.0);
    muS = clamp(muS, -1.0, 1.0);
    float var = sqrt(1.0 - mu * mu) * sqrt(1.0 - muS * muS);
    nu = clamp(nu, muS * mu - var, muS * mu + var);

    float cthetamin = -sqrt(1.0 - (ubo.Rg / r) * (ubo.Rg / r));

    vec3 v = vec3(sqrt(1.0 - mu * mu), 0.0, mu);
    float sx = v.x == 0.0 ? 0.0 : (nu - muS * mu) / v.x;
    vec3 s = vec3(sx, sqrt(max(0.0, 1.0 - sx * sx - muS * muS)), muS);

    raymie = vec3(0.0);

    // integral over 4.PI around x with two nested loops over w directions (theta,phi) -- Eq (7)
    for (int itheta = 0; itheta < INSCATTER_SPHERICAL_INTEGRAL_SAMPLES; ++itheta) {
        float theta = (float(itheta) + 0.5) * dtheta;
        float ctheta = cos(theta);

        float greflectance = 0.0;
        float dground = 0.0;
        vec3 gtransp = vec3(0.0);
        if (ctheta < cthetamin) { // if ground visible in direction w
            // compute transparency gtransp between x and ground
            greflectance = ubo.AVERAGE_GROUND_REFLECTANCE / M_PI;
            dground = -r * ctheta - sqrt(r * r * (ctheta * ctheta - 1.0) + ubo.Rg * ubo.Rg);
            gtransp = transmittance(ubo.Rg, -(r * ctheta + dground) / ubo.Rg, dground);
        }

        for (int iphi = 0; iphi < 2 * INSCATTER_SPHERICAL_INTEGRAL_SAMPLES; ++iphi) {
            float phi = (float(iphi) + 0.5) * dphi;
            float dw = dtheta * dphi * sin(theta);
            vec3 w = vec3(cos(phi) * sin(theta), sin(phi) * sin(theta), ctheta);

            float nu1 = dot(s, w);
            float nu2 = dot(v, w);
            float pr2 = phaseFunctionR(nu2);
            float pm2 = phaseFunctionM(nu2);

            // compute irradiance received at ground in direction w (if ground visible) =deltaE
            vec3 gnormal = (vec3(0.0, 0.0, r) + dground * w) / ubo.Rg;
            vec3 girradiance = irradiance(deltaESampler, ubo.Rg, dot(gnormal, s));

            vec3 raymie1; // light arriving at x from direction w

            // first term = light reflected from the ground and attenuated before reaching x, =T.alpha/PI.deltaE
            raymie1 = greflectance * girradiance * gtransp;

            // second term = inscattered light, =deltaS
            if (inscatterUBO.rAndFirst.y > 0.5) {
                // first iteration is special because Rayleigh and Mie were stored separately,
                // without the phase functions factors; they must be reintroduced here
                float pr1 = phaseFunctionR(nu1);
                float pm1 = phaseFunctionM(nu1);
                vec3 ray1 = texture4D(deltaSRSampler, r, w.z, muS, nu1).rgb;
                vec3 mie1 = texture4D(deltaSMSampler, r, w.z, muS, nu1).rgb;
                raymie1 += ray1 * pr1 + mie1 * pm1;
            } else {
                raymie1 += texture4D(deltaSRSampler, r, w.z, muS, nu1).rgb;
            }

            // light coming from direction w and scattered in direction v
            // = light arriving at x from direction w (raymie1) * SUM(scattering coefficient * phaseFunction)
            // see Eq (7)
            vec3 betaR = ubo.betaRAndHR.xyz;
            raymie += raymie1 * (betaR * exp(-(r - ubo.Rg) / ubo.betaRAndHR.w) * pr2 + ubo.betaMScaAndHM.xyz * exp(-(r - ubo.Rg) / ubo.betaMScaAndHM.w) * pm2) * dw;
        }
    }

    // output raymie = J[T.alpha/PI.deltaE + deltaS] (line 7 in algorithm 4.1)
}

void main() {
    vec3 raymie;
    float mu, muS, nu;
    getMuMuSNu(inscatterUBO.rAndFirst.x, inscatterUBO.dhdH, mu, muS, nu);
    inscatter(inscatterUBO.rAndFirst.x, mu, muS, nu, raymie);
    data.rgb = raymie;
    data.a = 1.0;
}
