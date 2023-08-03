Shader "Custom/Skybox"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _HorizonThreshold("Horizon Threshold", Range(0, 1)) = 0.02
        _OffsetHorizon("Offset Horizon", Range(-1, 1)) = 0
        _GroundColor("Ground Color", Color) = (94, 89, 87, 128)
        _TimeRatio("Time Ratio", Range(0, 1)) = 0.5
        [HideInInspector] _SunDirection("Sun Direction", Vector) = (0, 1, 0, 0)

        [Space]

        [Header(Scattering)]
        [Space]
        _SkyTint("Sky Tint", Color) = (128, 128, 128, 128)
        _AtmosphereThickness("Atmosphere Thickness", Range(0, 5)) = 1
        _Exposure("Exposure", Range(0, 8)) = 1.3
        _kSunBrightness("Sun Brightness", Range(0, 50)) = 20
        _kMoonBrightness("Moon Brightness", Range(0, 5)) = 1

        [Header(Cloudy)]
        [Space]
        [Toggle(_CLOUDY)]_Cloudy("Cloudy", Float) = 0
        _CloudySunFactor("Cloudy Factor", Range(0, 1)) = 0.75
        _MinCloudyRatio("Min Cloudy Ratio", Range(0, 1)) = 0.3
        _CloudyTopColor("Cloudy Top Color", Color) = (32, 32, 32, 128)
        _CloudyBottomColor("Cloudy Bottom Color", Color) = (64, 64, 64, 128)
        // [Toggle(_TEXTURE_CLOUD_ON)]_TextureCloud_On("Texture Cloud On/Off", Float) = 0
        _CloudTexture("Cloud Texture", 2D) = "black" {}
        _CloudSpeed("Cloud Speed", Range(0, 10)) = 1
        _CloudAlpha("Cloud Alpha", Range(0, 1)) = 0.5


        [Space]

        [Header(Sun Disk)]
        [Space]
        _SunSize("Sun Size", Range(0, 1)) = 0.04
        _SunSizeConvergence("Sun Size Convergence", Range(1, 10)) = 5

        [Space]

        [Header(Moon Disk)]
        [Space]
        _MoonSize("Moon Size", Range(0, 1)) = 0.04
        _MoonSizeConvergence("Moon Size Convergence", Range(1, 10)) = 5
        _MoonColor("Moon Color", Color) = (200, 200, 200, 128)
        _MoonRatio("Moon Ratio", Range(-2, 2)) = 0

        [Space]

        [Header(Night)]
        [Space]
        _StarNoiseTex("Star Noise Texture", 2D) = "black" {}
        _StarIntensity("Star Intensity", Range(0, 1)) = 0.4
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // #pragma shader_feature_local _TEXTURE_CLOUD_ON
            #pragma multi_compile_local _ _CLOUDY


            

            float _TimeRatio;
            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            float _HorizonThreshold;
            float _OffsetHorizon;
            half4 _SkyTint;
            half4 _GroundColor;
            float _SunSize;
            float _SunSizeConvergence;
            float _MoonSize;
            float _MoonSizeConvergence;
            half4 _MoonColor;
            float _AtmosphereThickness;
            float _Exposure;
            float _kSunBrightness;
            float _kMoonBrightness;
            float _MoonRatio;
            // sampler2D _StarNoiseTex;
            TEXTURE2D(_StarNoiseTex); SAMPLER(sampler_StarNoiseTex);
            float _StarIntensity;

            float _MinCloudyRatio;
            float _CloudySunFactor;
            float4 _CloudyTopColor;
            float4 _CloudyBottomColor;
            // sampler2D _CloudTexture;
            TEXTURE2D(_CloudTexture); SAMPLER(sampler_CloudTexture);
            float4 _CloudTexture_ST;
            float _CloudSpeed;
            float _CloudAlpha;

            #define PositivePow(base, power) pow(abs(base), power)

            // Pass from script
            float4 _SunDirection;
            float4 _SunColor;
            // #define _SunDirection _WorldSpaceLightPos0
            #define _SunColor _MainLightColor //_LightColor0

            // RGB wavelengths
            // .35 (.62=158), .43 (.68=174), .525 (.75=190)
            static const float3 kDefaultScatteringWavelength = float3(.65, .57, .475);
            static const float3 kVariableRangeForScatteringWavelength = float3(.15, .15, .15);

            #define OUTER_RADIUS 1.025
            static const float kOuterRadius = OUTER_RADIUS;
            static const float kOuterRadius2 = OUTER_RADIUS * OUTER_RADIUS;
            static const float kInnerRadius = 1.0;
            static const float kInnerRadius2 = 1.0;

            static const float kCameraHeight = 0.0001;

            #define kRAYLEIGH (lerp(0.0, 0.0025, PositivePow(_AtmosphereThickness,2.5)))      // Rayleigh constant
            #define kMIE 0.0010             // Mie constant

            #define kMAX_SCATTER 50.0 // Maximum scattering value, to prevent math overflows on Adrenos

            static const float kHDSundiskIntensityFactor = 15.0;
            static const float kSimpleSundiskIntensityFactor = 27.0;

            // static const float kSunScale = 400.0 * _kSunBrightness;
            static const float kKmESun = kMIE * _kSunBrightness;
            static const float kKmEMoon = kMIE * _kMoonBrightness;
            static const float kKm4PI = kMIE * 4.0 * 3.14159265;
            static const float kScale = 1.0 / (OUTER_RADIUS - 1.0);
            static const float kScaleDepth = 0.25;
            static const float kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
            static const float kSamples = 2.0; // THIS IS UNROLLED MANUALLY, DON'T TOUCH

            #define MIE_G (-0.990)
            #define MIE_G2 0.9801

            static const float kKrESun = kRAYLEIGH * _kSunBrightness;
            static const float kKrEMoon = kRAYLEIGH * _kMoonBrightness;
            static const float kKr4PI = kRAYLEIGH * 4.0 * 3.14159265;


            

            // Calculates the Rayleigh phase function
            float getRayleighPhase(float eyeCos2)
            {
                return 0.75 + 0.75 * eyeCos2;
            }
            float getRayleighPhase(float3 light, float3 ray)
            {
                float eyeCos = dot(light, ray);
                return getRayleighPhase(eyeCos * eyeCos);
            }

            float scale(float inCos)
            {
                float x = 1.0 - inCos;
                return 0.25 * exp(-0.00287 + x * (0.459 + x * (3.83 + x * (-6.80 + x * 5.25))));
            }

            // Calculates the Mie phase function
            float getMiePhase(float eyeCos, float eyeCos2, float sunSize)
            {
                float temp = 1.0 + MIE_G2 - 2.0 * MIE_G * eyeCos;
                temp = PositivePow(temp, PositivePow(sunSize, 0.65) * 10);
                temp = max(temp, 1.0e-4); // prevent division by zero, esp. in float precision
                temp = 1.5 * ((1.0 - MIE_G2) / (2.0 + MIE_G2)) * (1.0 + eyeCos2) / temp;
                return temp;
            }

            // Calculates the sun shape
            float calcSunAttenuation(float3 lightPos, float3 ray)
            {
                float focusedEyeCos = pow(saturate(dot(lightPos, ray)), _SunSizeConvergence);
                return getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos, _SunSize);
            }

            float calcMoonAttenuation(float3 lightPos, float3 ray)
            {
            float focusedEyeCos = pow(saturate(dot(lightPos, ray)), _MoonSizeConvergence);
            return getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos, _MoonSize);
            }

            float3 renderCloudyColor(float3 eyeRay, float3 cameraPos, float3 kInvWavelength,
                out float3 cIn, out float3 cOut)
            {
                float3 clampedEyeRay = eyeRay;
                clampedEyeRay.y = max(clampedEyeRay.y, _HorizonThreshold);
                // Sky
                // Calculate the length of the "atmosphere"
                float far = sqrt(kOuterRadius2 + kInnerRadius2 * clampedEyeRay.y * clampedEyeRay.y - kInnerRadius2) - kInnerRadius * clampedEyeRay.y;
                float3 pos = cameraPos + far * clampedEyeRay;

                float3 r = smoothstep(_HorizonThreshold, 1, clampedEyeRay.y);
                float3 col = r * _CloudyTopColor.rgb + (1 - r) * _CloudyBottomColor.rgb;

                float sunlightAngle = dot(_SunDirection.xyz, pos);
                col *= _MinCloudyRatio + (1 - _MinCloudyRatio) * smoothstep(-1, 1, sunlightAngle);

                cOut = col;
                cIn = col;
                return col;
            }

            float3 renderSkyColor(float3 eyeRay, float3 cameraPos, float3 kInvWavelength,
                out float3 cIn, out float3 cOut)
            {
                // Reference: https://zhuanlan.zhihu.com/p/36498679

                float3 clampedEyeRay = eyeRay;
                clampedEyeRay.y = max(clampedEyeRay.y, _HorizonThreshold);
                // Sky
                // Calculate the length of the "atmosphere"
                float far = sqrt(kOuterRadius2 + kInnerRadius2 * clampedEyeRay.y * clampedEyeRay.y - kInnerRadius2) - kInnerRadius * clampedEyeRay.y;

                float3 pos = cameraPos + far * clampedEyeRay;

                // Calculate the ray's starting position, then calculate its scattering offset
                float height = kInnerRadius + kCameraHeight;
                float depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
                float startAngle = dot(clampedEyeRay, cameraPos) / height;
                float startOffset = depth * scale(startAngle);


                // Initialize the scattering loop variables
                float sampleLength = far / kSamples;
                float scaledLength = sampleLength * kScale;
                float3 sampleRay = clampedEyeRay * sampleLength;
                float3 samplePoint = cameraPos + sampleRay * 0.5;

                // Now loop through the sample rays
                float3 sunFrontColor = float3(0.0, 0.0, 0.0);
                float3 moonFrontColor = float3(0.0, 0.0, 0.0);
                for (int i = 0; i<int(kSamples); i++)
                {
                    float sampleHeight = length(samplePoint);
                    float sampleDepth = exp(kScaleOverScaleDepth * (kInnerRadius - sampleHeight));
                    float cameraAngle = dot(clampedEyeRay, samplePoint) / sampleHeight;

                    float sunlightAngle = dot(_SunDirection.xyz, samplePoint) / sampleHeight;
                    float sunScatter = (startOffset + sampleDepth * (scale(sunlightAngle) - scale(cameraAngle)));
                    float3 sunAttenuate = exp(-clamp(sunScatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));
                    sunFrontColor += sunAttenuate * (sampleDepth * scaledLength);

                    float moonlightAngle = dot(-_SunDirection.xyz, samplePoint) / sampleHeight;
                    float moonScatter = (startOffset + sampleDepth * (scale(moonlightAngle) - scale(cameraAngle)));
                    float3 moonAttenuate = exp(-clamp(moonScatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));
                    moonFrontColor += moonAttenuate * (sampleDepth * scaledLength);

                    samplePoint += sampleRay;
                }

                // Finally, scale the Mie and Rayleigh colors and set up the varying variables for the pixel shader
                float3 cInSun = sunFrontColor * (kInvWavelength * kKrESun);
                float3 cInMoon = moonFrontColor * (kInvWavelength * kKrEMoon);
                cIn = cInSun + cInMoon;
                // cOut = sunFrontColor * kKmESun + moonFrontColor * kKmEMoon;
                cOut = sunFrontColor * kKmESun;

                //return cInSun + cInMoon;
                return cInSun * getRayleighPhase(_SunDirection.xyz, -eyeRay) + cInMoon * getRayleighPhase(-_SunDirection.xyz, -eyeRay);
            }

            float3 renderGroundColor(float3 eyeRay, float3 cameraPos, float3 kInvWavelength,
                out float3 cIn, out float3 cOut)
            {
                float3 clampedEyeRay = eyeRay;
                clampedEyeRay.y = min(clampedEyeRay.y, -_HorizonThreshold);
                // Ground
                float far = (-kCameraHeight) / (min(-0.001, clampedEyeRay.y));

                float3 pos = cameraPos + far * clampedEyeRay;

                // Calculate the ray's starting position, then calculate its scattering offset
                float depth = exp((-kCameraHeight) * (1.0 / kScaleDepth));
                float cameraAngle = dot(-clampedEyeRay, pos);
                float lightAngle = dot(_SunDirection.xyz, pos);
                float cameraScale = scale(cameraAngle);
                float lightScale = scale(lightAngle);
                float cameraOffset = depth * cameraScale;
                float temp = (lightScale + cameraScale);

                // Initialize the scattering loop variables
                float sampleLength = far / kSamples;
                float scaledLength = sampleLength * kScale;
                float3 sampleRay = clampedEyeRay * sampleLength;
                float3 samplePoint = cameraPos + sampleRay * 0.5;

                // Now loop through the sample rays
                float3 frontColor = float3(0.0, 0.0, 0.0);
                float3 attenuate;
                {
                    float sampleHeight = length(samplePoint);
                    float sampleDepth = exp(kScaleOverScaleDepth * (kInnerRadius - sampleHeight));
                    float scatter = sampleDepth * temp - cameraOffset;
                    attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));
                    frontColor += attenuate * (sampleDepth * scaledLength);
                    samplePoint += sampleRay;
                }

                cIn = frontColor * (kInvWavelength * kKrESun + kKmESun);
                cOut = clamp(attenuate, 0.0, 1.0);

                return cIn + _GroundColor.rgb * _GroundColor.rgb * cOut;
                }

                float random(float2 p) {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x + p.y);
            }

            
        ENDHLSL

        Pass
        {
            // Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            struct a2v
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
                uint vertexID : SV_VertexID;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {

                // _SunDirection *= 1 - 2 * step(0.25f, abs(_TimeRatio - 0.5f));
                // use worldPos rather than i.uv to sample, to avoid triangle fragment
                float3 dir = normalize(i.worldPos.xyz);
                //#ifdef _CLOUDY
                //                float3 kScatteringWavelength = lerp(
                //                    kDefaultScatteringWavelength - 2 * kVariableRangeForScatteringWavelength,
                //                    kDefaultScatteringWavelength + 2 * kVariableRangeForScatteringWavelength,
                //                    float3(1, 1, 1) - _SkyTint.xyz);
                //#else
                float3 kScatteringWavelength = lerp(
                kDefaultScatteringWavelength - kVariableRangeForScatteringWavelength,
                kDefaultScatteringWavelength + kVariableRangeForScatteringWavelength,
                float3(1, 1, 1) - _SkyTint.xyz); // using Tint in sRGB gamma allows for more visually linear interpolation and to keep (.5) at (128, gray in sRGB) point
                //#endif
                float3 kInvWavelength = 1.0 / float3(PositivePow(kScatteringWavelength.x, 4), PositivePow(kScatteringWavelength.y, 4), PositivePow(kScatteringWavelength.z, 4));
                // = 1 / (lambda^4)

                float3 cameraPos = float3(0, kInnerRadius + kCameraHeight, 0);    // The camera's current position

                // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
                float3 eyeRay = dir; // normalize(mul((float3x3)GetObjectToWorldMatrix(), v.vertex.xyz));

                // float far = 0.0;
                float3 cIn = float3(0.0, 0.0, 0.0);
                float3 cOut = float3(0.0, 0.0, 0.0);

                float3 groundColor = float3(0.0, 0.0, 0.0);
                float3 skyColor = float3(0.0, 0.0, 0.0);

                // Modification for per-pixel procedural sky:
                // Contrary to the legacy version that is run per-vertex, this version is per pixel.
                // The fact that it was run per-vertex means that the colors were never computed at the horizon.
                // Now that it's per vertex, we reach the limitation of the computation at the horizon where a very bright line appears.
                // To avoid that, we clampe the height of the eye ray just above and below the horizon for sky and ground respectively.
                // Another modification to make this work was to add ground and sky contribution instead of lerping between them.
                // For this to work we also needed to change slightly the computation so that cIn and cOut factor computed for the sky
                // did not affect ground and vice versa (it was the case before) so that we can add both contribution without adding energy                


                if (eyeRay.y >= _OffsetHorizon)
                {
                #ifdef _CLOUDY
                    skyColor = renderCloudyColor(eyeRay, cameraPos, kInvWavelength, cIn, cOut) * _CloudySunFactor
                        + renderSkyColor(eyeRay, cameraPos, kInvWavelength, cIn, cOut) * (1 - _CloudySunFactor);
                #else
                    skyColor = renderSkyColor(eyeRay, cameraPos, kInvWavelength, cIn, cOut);
                #endif
                }
                else
                {
                    groundColor = renderGroundColor(eyeRay, cameraPos, kInvWavelength, cIn, cOut);
                }



                float3 col = float3(0.0, 0.0, 0.0);

                // if y > 1 [eyeRay.y < -_HorizonThreshold] - ground
                // if y >= 0 and < 1 [eyeRay.y <= 0 and > -_HorizonThreshold] - horizon
                // if y < 0 [eyeRay.y > 0] - sky
                float y = -(eyeRay.y - _OffsetHorizon) / _HorizonThreshold;

                col = groundColor + skyColor;

                // 187 217 250

                if (y < 0.0)
                {
                    float2 skyUV = eyeRay.xz / sqrt(abs(eyeRay.y));
                    float cloud = 0;

                    // Sun
                    // The sun should have a stable intensity in its course in the sky. Moreover it should match the highlight of a purely specular material.
                    // This matching was done using the standard shader BRDF1 on the 5/31/2017
                    // Finally we want the sun to be always bright even in LDR thus the normalization of the lightColor for low intensity.
                //#ifndef _CLOUDY
                    float lightColorIntensity = max(length(_SunColor.xyz), 0.25);
                    float3 sunColor = kHDSundiskIntensityFactor * saturate(cOut) * _SunColor.xyz / lightColorIntensity;
                    col += sunColor * calcSunAttenuation(_SunDirection.xyz, eyeRay);

                    // Moon
                    // Calculate the moon disk, according to how sun disk is calculated
                    // float3 moonColor = kHDSundiskIntensityFactor * saturate(cOut) * _SunColor.xyz / lightColorIntensity;
                    /*float3 moonColor = kHDSundiskIntensityFactor * 0.1f * _MoonColor.xyz / lightColorIntensity;
                    moonColor *= saturate(calcMoonAttenuation(-_SunDirection.xyz, eyeRay));
                    moonColor = lerp(float3(0, 0, 0), moonColor, pow(saturate(abs(_SunDirection.y) * 15), 2));*/

                    // Calculate the shape change of moon, and don't let it affect sun
                    float moonAngleCos = dot(eyeRay, -_SunDirection.xyz);
                    if (_SunDirection.y < 0 && moonAngleCos > 0) { // the dot test if it's for sun or moon
                        float3 xAxis;
                        if (dot(-_SunDirection.xyz, float3(0, 1, 0)) > 0.001)
                        {
                            xAxis = cross(float3(1, 0, 0), -_SunDirection.xyz);
                        }
                        else {
                            xAxis = cross(float3(0, 1, 0), -_SunDirection.xyz);
                        }
                        float3 yAxis = cross(-_SunDirection.xyz, xAxis);
                        float2 moonAxis = float2(dot(xAxis, eyeRay), dot(yAxis, eyeRay)) / sqrt(_MoonSize);
                        float moonRadius2 = dot(moonAxis, moonAxis);
                        float moonShineRadius2 = _MoonSize * _MoonSize;
                        float moonMaxRadius2 = moonShineRadius2 * 1.2f; // Manually Decide!! If need change, should change with TEST!!
                        if (moonRadius2 < moonMaxRadius2) {
                            // _MoonRatio : [-2, 2], from first quarter to last quater, 0 is full moon
                            float occlusion = 1; // how the moon is occluded, to change its shape, we use SDF to calculate

                            float circleHorizontalLen =
                                sqrt(max(moonShineRadius2 * 1.5f - moonAxis.x * moonAxis.x, 0));
                            float r = sign(_MoonRatio) - _MoonRatio;
                            float occlusionSDF =
                                sign(_MoonRatio) * moonAxis.y - sign(_MoonRatio) * r * circleHorizontalLen;

                            float maxSDF = 0.1f;
                            occlusion = 1 - saturate(occlusionSDF / maxSDF);
                            occlusion = pow(occlusion, 3);
                            // col += float3(occlusion, occlusion, occlusion);

                            float moonAttenuate = (moonMaxRadius2 - moonRadius2) / (moonMaxRadius2 - moonShineRadius2)
                                * occlusion * saturate(_SunDirection.y * _SunDirection.y * 10);
                            col += lerp(float3(0, 0, 0), _MoonColor.xyz, saturate(moonAttenuate));
                        }
                    }
                    //#else
                    #ifdef _CLOUDY
                        // Cloud, simplest skybox texture cloud
                        float t = frac(0.1f * _CloudSpeed * fmod(_Time.y, 100));
                        // cloud = tex2D(_CloudTexture, float2(skyUV.x / _CloudTexture_ST.x + t, skyUV.y / _CloudTexture_ST.y + t)).r;
                        cloud = SAMPLE_TEXTURE2D(_CloudTexture, sampler_CloudTexture, float2(skyUV.x / _CloudTexture_ST.x + t, skyUV.y / _CloudTexture_ST.y + t)).r;
                        //cloud = smoothstep(0, 0.7, cloud);
                        cloud = smoothstep(0, 1, sqrt(cloud));
                        col += _CloudAlpha * half3(cloud, cloud, cloud);
                    #endif

                        // Stars
                        if (_SunDirection.y < 0 && cloud < 0.35f)
                        {
                            //float star = smoothstep(_StarIntensity, 1, tex2D(_StarNoiseTex, skyUV).r);
                            float star = smoothstep(_StarIntensity, 1, SAMPLE_TEXTURE2D(_StarNoiseTex, sampler_StarNoiseTex, skyUV).r);
                            float t = random(skyUV * 100) * 5.0f + fmod(_Time.y, 100);
                            star *= smoothstep(0, 1, sin(2 * t)); // make the star shine
                            star *= smoothstep(0, -0.4, _SunDirection.y); // make the star show up and fade with moon
                            col += float3(star, star, star);
                        }
                    }
                    else if (y < 1) // horizon, y in [0, 1)
                    {
                        float3 tempEyeRay = eyeRay;
                        tempEyeRay.y = _OffsetHorizon;
                    #ifdef _CLOUDY
                        skyColor = renderCloudyColor(eyeRay, cameraPos, kInvWavelength, cIn, cOut) * _CloudySunFactor
                            + renderSkyColor(eyeRay, cameraPos, kInvWavelength, cIn, cOut) * (1 - _CloudySunFactor);
                    #else
                        skyColor = renderSkyColor(tempEyeRay, cameraPos, kInvWavelength, cIn, cOut);
                    #endif
                        col = lerp(skyColor, groundColor, y);
                    }

                    return half4(col * _Exposure, 1);
                }

            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
