Shader "Custom/Skybox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HorizonIntensity ("HorizonIntensity", Range(0, 3)) = 1
        _OffsetHorizon ("Offset Horizon", Range(-1, 1)) = 0
        _SkyTint("Sky Tint", Color) = (128, 128, 128, 128)
        _GroundColor("Ground Color", Color) = (94, 89, 87, 128)
        _SunSize("Sun Size", Range(0, 1)) = 0.04
        _SunSizeConvergence("Sun Size Convergence", Range(1, 10)) = 5
        _AtmosphereThickness("Atmosphere Thickness", Range(0, 5)) = 1
        _Exposure("Exposure", Range(0, 8)) = 1.3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizonIntensity;
            float _OffsetHorizon;
            fixed4 _SkyTint;
            fixed4 _GroundColor;
            float _SunSize;
            float _SunSizeConvergence;
            float _AtmosphereThickness;
            float _Exposure;

            #define PositivePow(base, power) pow(abs(base), power)

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
            #define kSUN_BRIGHTNESS 20.0    // Sun brightness

            #define kMAX_SCATTER 50.0 // Maximum scattering value, to prevent math overflows on Adrenos

            static const float kHDSundiskIntensityFactor = 15.0;
            static const float kSimpleSundiskIntensityFactor = 27.0;

            static const float kSunScale = 400.0 * kSUN_BRIGHTNESS;
            static const float kKmESun = kMIE * kSUN_BRIGHTNESS;
            static const float kKm4PI = kMIE * 4.0 * 3.14159265;
            static const float kScale = 1.0 / (OUTER_RADIUS - 1.0);
            static const float kScaleDepth = 0.25;
            static const float kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
            static const float kSamples = 2.0; // THIS IS UNROLLED MANUALLY, DON'T TOUCH

            #define MIE_G (-0.990)
            #define MIE_G2 0.9801

            #define SKY_GROUND_THRESHOLD 0.02

            float4 GetFullScreenTriangleVertexPosition(uint vertexID, float z = UNITY_NEAR_CLIP_VALUE)
            {
                // note: the triangle vertex position coordinates are x2 so the returned UV coordinates are in range -1, 1 on the screen.
                float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
                return float4(uv * 2.0 - 1.0, z, 1.0);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // o.vertex = GetFullScreenTriangleVertexPosition(v.vertexID, 4);
                // o.vertex = GetFullScreenTriangleVertexPosition(v.vertexID);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            //float PositivePow(float base, float power) {
            //    return pow(abs(base), power);
            //}

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
            float getMiePhase(float eyeCos, float eyeCos2)
            {
                float temp = 1.0 + MIE_G2 - 2.0 * MIE_G * eyeCos;
                temp = PositivePow(temp, PositivePow(_SunSize, 0.65) * 10);
                temp = max(temp, 1.0e-4); // prevent division by zero, esp. in float precision
                temp = 1.5 * ((1.0 - MIE_G2) / (2.0 + MIE_G2)) * (1.0 + eyeCos2) / temp;
                return temp;
            }

            // Calculates the sun shape
            float calcSunAttenuation(float3 lightPos, float3 ray)
            {
                float focusedEyeCos = pow(saturate(dot(lightPos, ray)), _SunSizeConvergence);
                return getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos);
            }

            float4x4 _PixelCoordToViewDirWS;
            #if defined(USING_STEREO_MATRICES)
                #define _PixelCoordToViewDirWS  _XRPixelCoordToViewDirWS[unity_StereoEyeIndex]
            #endif

            fixed4 frag(v2f i) : SV_Target
            {
                // return fixed4(normalize(i.vertex.xy), 0, 1);
                
                // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                // float horizon = saturate(abs(i.uv.y * _HorizonIntensity - _OffsetHorizon));
                // float2 skyUV = i.uv.xz / i.uv.y;
                
                // float4 viewDirWS = mul(float4(i.vertex.xy, 1.0f, 1.0f), _PixelCoordToViewDirWS);
                // float3 dir = normalize(viewDirWS.xyz);

                // return fixed4(normalize(i.worldPos), 1);

                // float3 dir = i.uv; // for simplification
                float3 dir = normalize(i.worldPos.xyz);

                float4 _SunDirection = _WorldSpaceLightPos0;
                float4 _SunColor = _LightColor0;

                // return fixed4(normalize(i.vertex.xyz), 1);

                // float3 viewDirWS = GetSkyViewDirWS(input.positionCS.xy);

                // Reverse it to point into the scene
                // float3 dir = -viewDirWS;

                float3 kScatteringWavelength = lerp(
                    kDefaultScatteringWavelength - kVariableRangeForScatteringWavelength,
                    kDefaultScatteringWavelength + kVariableRangeForScatteringWavelength,
                    float3(1, 1, 1) - _SkyTint.xyz); // using Tint in sRGB gamma allows for more visually linear interpolation and to keep (.5) at (128, gray in sRGB) point
                float3 kInvWavelength = 1.0 / float3(PositivePow(kScatteringWavelength.x, 4), PositivePow(kScatteringWavelength.y, 4), PositivePow(kScatteringWavelength.z, 4));

                float kKrESun = kRAYLEIGH * kSUN_BRIGHTNESS;
                float kKr4PI = kRAYLEIGH * 4.0 * 3.14159265;

                float3 cameraPos = float3(0, kInnerRadius + kCameraHeight, 0);    // The camera's current position

                // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
                float3 eyeRay = dir; // normalize(mul((float3x3)GetObjectToWorldMatrix(), v.vertex.xyz));

                float far = 0.0;
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
                // For this to work we also needed to change slightly the computation so that cIn and cOut factor computed for the sky did not affect ground and vice versa (it was the case before) so that we can add both contribution without adding energy
                float horizonThreshold = 0.02;
                if (eyeRay.y >= 0.0)
                {
                    float3 clampedEyeRay = eyeRay;
                    clampedEyeRay.y = max(clampedEyeRay.y, horizonThreshold);
                    // Sky
                    // Calculate the length of the "atmosphere"
                    far = sqrt(kOuterRadius2 + kInnerRadius2 * clampedEyeRay.y * clampedEyeRay.y - kInnerRadius2) - kInnerRadius * clampedEyeRay.y;

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
                    float3 frontColor = float3(0.0, 0.0, 0.0);
                    for (int i = 0; i<int(kSamples); i++)
                    {
                        float sampleHeight = length(samplePoint);
                        float sampleDepth = exp(kScaleOverScaleDepth * (kInnerRadius - sampleHeight));
                        float lightAngle = dot(_SunDirection.xyz, samplePoint) / sampleHeight;
                        float cameraAngle = dot(clampedEyeRay, samplePoint) / sampleHeight;
                        float scatter = (startOffset + sampleDepth * (scale(lightAngle) - scale(cameraAngle)));
                        float3 attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));

                        frontColor += attenuate * (sampleDepth * scaledLength);
                        samplePoint += sampleRay;
                    }

                    // Finally, scale the Mie and Rayleigh colors and set up the varying variables for the pixel shader
                    cIn = frontColor * (kInvWavelength * kKrESun);
                    cOut = frontColor * kKmESun;

                    skyColor = (cIn * getRayleighPhase(_SunDirection.xyz, -eyeRay));
                }
                else
                {
                    float3 clampedEyeRay = eyeRay;
                    clampedEyeRay.y = min(clampedEyeRay.y, -horizonThreshold);
                    // Ground
                    far = (-kCameraHeight) / (min(-0.001, clampedEyeRay.y));

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

                    groundColor = (cIn + _GroundColor.rgb * _GroundColor.rgb * cOut);
                }

                float3 col = float3(0.0, 0.0, 0.0);

                // if y > 1 [eyeRay.y < -SKY_GROUND_THRESHOLD] - ground
                // if y >= 0 and < 1 [eyeRay.y <= 0 and > -SKY_GROUND_THRESHOLD] - horizon
                // if y < 0 [eyeRay.y > 0] - sky
                float y = -eyeRay.y / SKY_GROUND_THRESHOLD;

                col = groundColor + skyColor;

                // #if _ENABLE_SUN_DISK
                if (y < 0.0)
                {
                    float3 sunColor = float3(0.0, 0.0, 0.0);

                    // #if _ENABLE_SUN_DISK
                    // The sun should have a stable intensity in its course in the sky. Moreover it should match the highlight of a purely specular material.
                    // This matching was done using the standard shader BRDF1 on the 5/31/2017
                    // Finally we want the sun to be always bright even in LDR thus the normalization of the lightColor for low intensity.
                    float lightColorIntensity = max(length(_SunColor.xyz), 0.25);

                    sunColor = kHDSundiskIntensityFactor * saturate(cOut) * _SunColor.xyz / lightColorIntensity;
                    //#endif
                    col += sunColor * calcSunAttenuation(_SunDirection.xyz, eyeRay);

                    // float sunIntensity = saturate(dot(_SunDirection.xyz, eyeRay));
                    // col += _SunColor.xyz * pow(sunIntensity, 150);
                }
                // #endif


                // fixed4 col = fixed4(horizon, horizon, horizon, 1);
                return fixed4(col * _Exposure, 1);
            }
            ENDHLSL
        }
    }
}
