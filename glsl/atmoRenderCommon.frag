

//atmo

#define OPTIMIZE
#define ATMO_FULL
#define HORIZON_HACK

#define SUN_INTENSITY 0.6
#define SKY_SUN_INTENSITY_HACK 2.5

#define NIGHT_LIGHT 0.001

#define PBR_MIP_LEVELS 7
//#define SKY_POWER 1.4
#define SKY_POWER 1.0

#define SCALE 100.0

const float Rg = 8388.0 * SCALE;
const float Rt = 8448.0 * SCALE;
const float RL = 8449.0 * SCALE;

const float HR = 9.0 * SCALE;
const vec3 betaR = vec3(5.8e-3, 1.35e-2, 3.31e-2) / SCALE;

const float M_PI = 3.141592657;
const int TRANSMITTANCE_INTEGRAL_SAMPLES = 500;
const int INSCATTER_INTEGRAL_SAMPLES = 50;
const int IRRADIANCE_INTEGRAL_SAMPLES = 32;
const int INSCATTER_SPHERICAL_INTEGRAL_SAMPLES = 16;

const int TRANSMITTANCE_W = 256;
const int TRANSMITTANCE_H = 64;

const int SKY_W = 64;
const int SKY_H = 16;

const int RES_R = 32;
const int RES_MU = 128;
const int RES_MU_S = 128;
const int RES_NU = 8;


/*
#define  Pr  .299
#define  Pg  .587
#define  Pb  .114
#define saturationIncrease 1.2

vec3 changeSaturation(vec3 inColor)
{
  float  P=sqrt(
  (inColor.r)*(inColor.r)*Pr+
  (inColor.g)*(inColor.g)*Pg+
  (inColor.b)*(inColor.b)*Pb) ;

  return vec3(max(P+((inColor.r)-P), 0.0) * saturationIncrease,
  max(P+((inColor.g)-P), 0.0) * saturationIncrease,
  max(P+((inColor.b)-P), 0.0) * saturationIncrease);
}*/

#define TRANSMITTANCE_NON_LINEAR
#define INSCATTER_NON_LINEAR

float SQRT(float f, float err) {
#ifdef OPTIMIZE
    return sqrt(f);
#else
    return f >= 0.0 ? sqrt(f) : err;
#endif
}

vec4 texture4D(in sampler3D table, float r, float mu, float muS, float nu)
{
    float H = sqrt(Rt * Rt - Rg * Rg);
    float rho = sqrt(r * r - Rg * Rg);
#ifdef INSCATTER_NON_LINEAR
    float rmu = r * mu;
    float delta = rmu * rmu - r * r + Rg * Rg;
    vec4 cst = rmu < 0.0 && delta > 0.0 ? vec4(1.0, 0.0, 0.0, 0.5 - 0.5 / float(RES_MU)) : vec4(-1.0, H * H, H, 0.5 + 0.5 / float(RES_MU));
	float uR = 0.5 / float(RES_R) + rho / H * (1.0 - 1.0 / float(RES_R));
    float uMu = cst.w + (rmu * cst.x + sqrt(delta + cst.y)) / (rho + cst.z) * (0.5 - 1.0 / float(RES_MU));
    // paper formula
    //float uMuS = 0.5 / float(atmoUbo.RES_MU_S) + max((1.0 - exp(-3.0 * muS - 0.6)) / (1.0 - exp(-3.6)), 0.0) * (1.0 - 1.0 / float(atmoUbo.RES_MU_S));
    // better formula
    float uMuS = 0.5 / float(RES_MU_S) + (atan(max(muS, -0.1975) * tan(1.26 * 1.1)) / 1.1 + (1.0 - 0.26)) * 0.5 * (1.0 - 1.0 / float(RES_MU_S));
#else
	float uR = 0.5 / float(RES_R) + rho / H * (1.0 - 1.0 / float(RES_R));
    float uMu = 0.5 / float(RES_MU) + (mu + 1.0) / 2.0 * (1.0 - 1.0 / float(RES_MU));
    float uMuS = 0.5 / float(RES_MU_S) + max(muS + 0.2, 0.0) / 1.2 * (1.0 - 1.0 / float(RES_MU_S));
#endif
    float lerp = (nu + 1.0) / 2.0 * (float(RES_NU) - 1.0);
    float uNu = floor(lerp);
    lerp = lerp - uNu;
    //vec3 value = vec3(uR * 0.5);
   // return vec4(value, 1.0);
    return texture(table, vec3((uNu + uMuS) / float(RES_NU), uMu, uR)) * (1.0 - lerp) +
           texture(table, vec3((uNu + uMuS + 1.0) / float(RES_NU), uMu, uR)) * lerp;
}//



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
    return sqrt((6.2831*H)*r) * exp((Rg-r)/H) * (x + dot(y, vec2(1.0, -1.0)));
}


// approximated single Mie scattering (cf. approximate Cm in paragraph 'Angular precision')
vec3 getMie(vec4 rayMie) { // rayMie.rgb=C*, rayMie.w=Cm,r
	return rayMie.rgb * rayMie.w / max(rayMie.r, 1e-4) * (betaR.r / betaR);
}


// Rayleigh phase function
float phaseFunctionR(float mu) {
    return (3.0 / (16.0 * M_PI)) * (1.0 + mu * mu);
}

// Mie phase function
float phaseFunctionM(vec4 betaMExAndmieG, float mu) {
    float mieG = betaMExAndmieG.w;
	return 1.5 * 1.0 / (4.0 * M_PI) * (1.0 - mieG*mieG) * pow(1.0 + (mieG*mieG) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + mieG*mieG);
}


vec2 getTransmittanceUV(float r, float mu) {
    float uR, uMu;
#ifdef TRANSMITTANCE_NON_LINEAR
	uR = sqrt((r - Rg) / (Rt - Rg));
	uMu = atan((mu + 0.15) / (1.0 + 0.15) * tan(1.5)) / 1.5;
#else
	uR = (r - Rg) / (Rt - Rg);
	uMu = (mu + 0.15) / (1.0 + 0.15);
#endif
    return vec2(uMu, uR);
}

vec3 transmittance(sampler2D transmittanceSampler, float r, float mu) {
	vec2 uv = getTransmittanceUV(r, mu);
    return texture(transmittanceSampler, uv).rgb;
}

vec3 transmittanceWithShadow(sampler2D transmittanceSampler, float r, float mu) {
    return (mu < -sqrt(1.0 - (Rg / r) * (Rg / r)) ? vec3(0.0) : transmittance(transmittanceSampler, r, mu));
}

vec3 sunRadiance(sampler2D transmittanceSampler, float r, float muS) {
    return pow(transmittanceWithShadow(transmittanceSampler, r, muS) * SUN_INTENSITY, vec3(1.2));
}

vec3 inScattering(vec4 betaMExAndmieG, sampler2D transmittanceSampler, sampler3D inscatterSampler, vec3 camera, vec3 point, vec3 viewdir_, vec4 sunPos_cloudCover, out vec3 extinction) {
#if defined(ATMO_INSCATTER_ONLY) || defined(ATMO_FULL)
    vec3 result;
    vec3 viewdir = viewdir_;
   
    float pointLength = length(point);
    if(pointLength < (Rg + 10.0))
    {
        point = (point / pointLength) * (Rg + 10.0);
        viewdir = point - camera;
    }

    float d = length(viewdir);
    if(d < 2.0)
    {
        extinction = vec3(1.0);
        return vec3(0.0);
    }
    viewdir = viewdir / d;
    float r = length(camera);
    if (r < 0.9 * Rg) {
        camera.z += Rg;
        point.z += Rg;
    }

    float rMu = dot(camera, viewdir);
    float mu = rMu / r;
    float r0 = r;
    float mu0 = mu;

    float deltaSq = SQRT(rMu * rMu - r * r + Rt*Rt, 1e30);
    float din = -rMu - deltaSq;

    if (din > 0.0 && din < d) {
        camera += din * viewdir;
        rMu += din;
        mu = rMu / Rt;
        r = Rt;
        d -= din;
    }


    //point = mix(point, normalize(point) * Rg * 0.999, clamp(r - Rt, 0.0,1.0));
        //point = normalize(point) * Rg * 0.999;

    if (r <= Rt) {
        float nu = dot(viewdir, sunPos_cloudCover.xyz);
        float muS = dot(camera, sunPos_cloudCover.xyz) / r;

        vec4 inScatter;

        if (r < Rg + SCALE) {
            // avoids imprecision problems in aerial perspective near ground
            float f = (Rg + SCALE) / r;
            r = r * f;
            rMu = rMu * f;
            point = point * f;
        }
        
        vec3 pointNormal = normalize(point);

        float r1 = length(point);
        float mu1 = dot(pointNormal, viewdir);
       // float mu1 = rMu1 / r1;
        float muS1 = dot(pointNormal, sunPos_cloudCover.xyz);

        if (mu > 0.0) {
            extinction = min(transmittance(transmittanceSampler, r, mu) / transmittance(transmittanceSampler, r1, mu1), 1.0);
        } else {
            extinction = min(transmittance(transmittanceSampler, r1, -mu1) / transmittance(transmittanceSampler, r, -mu), 1.0);
        }

#ifdef HORIZON_HACK
        const float EPS = 0.0004;
        float lim = -sqrt(1.0 - (Rg / r) * (Rg / r));
        if (abs(mu - lim) < EPS) {
            float a = ((mu - lim) + EPS) / (2.0 * EPS);

            mu = lim + EPS;
            r1 = sqrt(r * r + d * d + 2.0 * r * d * mu);
            mu1 = (r * mu + d) / r1;
            
            vec4 inScatter0 = texture4D(inscatterSampler, r, mu, muS, nu);
            vec4 inScatter1 = texture4D(inscatterSampler, r1, mu1, muS1, nu);
            inScatter = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);

        } else {

            vec4 inScatter0 = texture4D(inscatterSampler, r, mu, muS, nu);
            vec4 inScatter1 = texture4D(inscatterSampler, r1, mu1, muS1, nu);
            inScatter = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);
           // return (inScatter0.rgb - vec3(0.3,0.3,0.3)) * 100.0;
           // return texture(inscatterSampler, vec3(0.2,0.2,0.2)).rgb;
          // return (vec3(0.1,0.1,0.1) + (vec3(r, mu, muS) - vec3(r1, mu1, muS1)) *0.001);
        }
#else
        vec4 inScatter0 = texture4D(inscatterSampler, r, mu, muS, nu);
        vec4 inScatter1 = texture4D(inscatterSampler, r1, mu1, muS1, nu);
        inScatter = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);
        
#endif


        // avoids imprecision problems in Mie scattering when sun is below horizon
        inScatter.w *= smoothstep(0.00, 0.02, muS);
        

        vec3 inScatterM = getMie(inScatter);
        float phase = phaseFunctionR(nu);
        float phaseM = phaseFunctionM(betaMExAndmieG, nu);
        result = inScatter.rgb * phase + inScatterM * phaseM * (1.0 - sunPos_cloudCover.w * 0.3);
        
        if(muS < 0.2)
        {
            float nightMix = smoothstep(0.2, -0.2, muS);
            float nuNight = 1.0;
            float muSNight = 1.0;
            vec4 inScatterNight0 = texture4D(inscatterSampler, r, mu, muSNight, nuNight) * NIGHT_LIGHT;
            vec4 inScatterNight1 = texture4D(inscatterSampler, r1, mu1, muSNight, nuNight) * NIGHT_LIGHT;
            vec4 inScatterNight = max(inScatterNight0 - inScatterNight1 * extinction.rgbr, 0.0);
            result = result + inScatterNight.rgb * nightMix * (1.0 - sunPos_cloudCover.w);
        }
        
    } else {
        result = vec3(0.0);
        extinction = vec3(1.0);
    }

   // result = pow(result, vec3(SKY_POWER)) * SUN_INTENSITY * SKY_SUN_INTENSITY_HACK * min(d * 0.1 - 0.4, 1.0);// * ((1.0 - smoothstep(0.4, 10.0, dNew * 0.0001) * 0.8) + 0.2);
   // result = changeSaturation(result);
    
   result = result * SUN_INTENSITY * SKY_SUN_INTENSITY_HACK;
   result = pow(result, vec3(1.2));
   //result = mix(result, vec3(result.g) * 0.1, (sunPos_cloudCover.w * 0.96));
   //result = changeSaturation(result);

    result = mix(result, vec3(result.g), (sunPos_cloudCover.w * 0.96));

    float extinctionMultiplier = min(sunPos_cloudCover.w * d * 0.001, sunPos_cloudCover.w * 0.9);

    vec3 sunColor = max(sunRadiance(transmittanceSampler, length(camera), dot(normalize(camera), sunPos_cloudCover.xyz)), vec3(0.005));
    sunColor = mix(sunColor, vec3(sunColor.g), 0.7);
    result = mix(result, vec3(0.01) * sunColor, extinctionMultiplier);

    //result = mix(result, vec3(0.1) * max(transmittance(transmittanceSampler, length(camera) * 1.0, dot(normalize(camera), sunPos_cloudCover.xyz)), vec3(0.0)), extinctionMultiplier);

    float closeMix = 1.0 - clamp((d - 2.0) * 0.1, 0.0, 1.0);
    extinction = mix(extinction, vec3(0.0), extinctionMultiplier * closeMix);

    result = mix(result, vec3(0.0), closeMix);
   

    return result;
#else
    extinction = vec3(1.0);
    return vec3(0.0);
#endif
}




vec3 skyRadiance(vec4 betaMExAndmieG, sampler2D transmittanceSampler, sampler3D inscatterSampler, vec3 camera, vec3 viewdir, vec4 sunPos_cloudCover, out vec3 extinction)
{
#if defined(ATMO_INSCATTER_ONLY) || defined(ATMO_FULL)
    vec3 result;
    float r = length(camera);
    float rMu = dot(camera, viewdir);
    float mu = rMu / r;
    float r0 = r;
    float mu0 = mu;

    float deltaSq = SQRT(rMu * rMu - r * r + Rt*Rt, 1e30);
    float din = max(-rMu - deltaSq, 0.0);
    if (din > 0.0) {
        camera += din * viewdir;
        rMu += din;
        mu = rMu / Rt;
        r = Rt;
    }

    if (r <= Rt) {
        float nu = dot(viewdir, sunPos_cloudCover.xyz);
        float muS = dot(camera, sunPos_cloudCover.xyz) / r;
        
        

        vec4 inScatter = texture4D(inscatterSampler, r, rMu / r, muS, nu);
        extinction = transmittance(transmittanceSampler, r, mu);

        vec3 inScatterM = getMie(inScatter);
        float phase = phaseFunctionR(nu);
        float phaseM = phaseFunctionM(betaMExAndmieG, nu);
        
        
        result = inScatter.rgb * phase + inScatterM * phaseM * (1.0 - sunPos_cloudCover.w * 0.3);

        if(muS < 0.2)
        {
            float nightMix = smoothstep(0.2, -0.2, muS);
        
            float nuNight = 1.0;
            float muSNight = 1.0;
            vec4 inScatterNight = texture4D(inscatterSampler, r, rMu / r, muSNight, nuNight) * NIGHT_LIGHT;
            result = result + inScatterNight.rgb * nightMix * (1.0 - sunPos_cloudCover.w);
        }
        
    } else {
        result = vec3(0.0);
        extinction = vec3(1.0);
    }

   // result = pow(result, vec3(SKY_POWER)) * SUN_INTENSITY * SKY_SUN_INTENSITY_HACK;

   result = result * SUN_INTENSITY * SKY_SUN_INTENSITY_HACK;
   result = pow(result, vec3(1.2));
   //result = mix(result, vec3(result.g) * 0.1, (sunPos_cloudCover.w * 0.96));

   
    result = mix(result, vec3(result.g), (sunPos_cloudCover.w * 0.96));

    float extinctionMultiplier = sunPos_cloudCover.w * 0.9;//min(sunPos_cloudCover.w * r * 0.001, sunPos_cloudCover.w * 0.95);

    vec3 sunColor = max(sunRadiance(transmittanceSampler, length(camera), dot(normalize(camera), sunPos_cloudCover.xyz)), vec3(0.005));
    sunColor = mix(sunColor, vec3(sunColor.g), 0.7);
    result = mix(result, vec3(0.01) * sunColor, extinctionMultiplier);
    extinction = mix(extinction, vec3(0.0), extinctionMultiplier);

    //result = changeSaturation(result);

    return result;
#else
    extinction = vec3(1.0);
    return vec3(0.0);
#endif
}

#define saturate(x) clamp(x, 0.0, 1.0)
