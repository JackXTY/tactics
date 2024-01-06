using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

/*
 * WeatherManager:
 *     - Skybox day Cycle and sun light (directional light, maybe also shadow)
 *     - Simple cloud based inside skybox
 */
public class WeatherManager : MonoBehaviour
{

    public Material skyboxMat;

    public Transform directionalLight;

    public Light sun;

    public bool autoTime = true;

    [Tooltip("how many minutes for weather system per second in real world, for auto time mode")]
    public float worldSpeed = 30;

    [Tooltip("when the system begin, in hour")]
    public float worldBeginTime = 0;

    public Color sunTintColor;

    bool hasCloud = false;

    float worldTime = 0; // when in world now (in mins)
    float timeRatio; // timeRatio in [0, 1]; 0 => night, 1 => noon

    public float sunShadow = 1.0f;

    // Update sky in every frame
    void UpdateSky()
    {
        timeRatio = worldTime / 1440;

        // for sun brightness: 0~7.5 [18:00 - 06:00], 7.5-30 [06:00 - 18:00]
        // float sunBrightness = 14.697f * timeRatio * timeRatio * Mathf.Sqrt(6 * timeRatio);
        // float sunBrightness = 33.0f * Mathf.Pow(1.45f, 6 * timeRatio - 6) - 3.5f;
        // float sunRatio = 1 - Mathf.Abs(2 * (timeRatio - 0.5f));
        // float sunBrightness = 33.0f * Mathf.Pow(1.45f, 6 * sunRatio - 6) - 5f; // calculate manually
        // skyboxMat.SetFloat("_kSunBrightness", Mathf.Clamp(sunBrightness, 0.05f, 30));

        float sunAngle = (timeRatio - 0.25f) * 2;
        //if(timeRatio >= 0.25f || timeRatio <= 0.75f)
        //{
        //    sunAngle = clamp()
        //}
        // float sunAngle = Mathf.Clamp((timeRatio - 0.25f) * 2, 0, 1);

        skyboxMat.SetVector("_SunDirection", Quaternion.Euler(180 * sunAngle, 0, 0) * -Vector3.forward);
        skyboxMat.SetFloat("_TimeRatio", timeRatio);

        Debug.Log("sun angle = " + sunAngle.ToString() + "timeRatio = " + timeRatio.ToString());
        directionalLight.rotation = Quaternion.Euler((180 * sunAngle), 0, 0);


        if (timeRatio > 0.2f && timeRatio < 0.3f)
        {
            sun.intensity = Mathf.Lerp(0, 1, (timeRatio - 0.2f) / 0.1f);
            sun.shadowStrength = Mathf.Lerp(0, sunShadow, (timeRatio - 0.2f) / 0.1f);
        }
        if (timeRatio > 0.7f && timeRatio < 0.85f)
        {
            sun.intensity = Mathf.Lerp(1, 0, (timeRatio - 0.7f) / 0.15f);
            sun.shadowStrength = Mathf.Lerp(sunShadow, 0, (timeRatio - 0.7f) / 0.1f);
        }
    }

    public void InitMat()
    {
        worldTime = (worldBeginTime * 60) % 1440;

        //skyboxMat.SetColor("_SkyTint", new Color(10f / 256f, 11f / 256f, 12f / 256f));

        if (hasCloud)
        {
            skyboxMat.EnableKeyword("_CLOUDY");
            skyboxMat.SetColor("_SkyTint", new Color(5f / 256f, 6f / 256f, 7f / 256f));
        }
        else
        {
            skyboxMat.DisableKeyword("_CLOUDY");
            skyboxMat.SetColor("_SkyTint", sunTintColor);
        }

        timeRatio = worldTime / 1440;
        if (timeRatio > 0.3f && timeRatio < 0.7f)
        {
            sun.intensity = 1;
            sun.shadowStrength = sunShadow;
        }
        if (timeRatio > 0.85f || timeRatio < 0.2f)
        {
            sun.intensity = 0;
            sun.shadowStrength = 0;
        }

        UpdateSky();
    }

    public void SetCloudy(bool cloudy)
    {
        hasCloud = cloudy;
    }

    void Start()
    {
        InitMat();
        // skyboxMat.SetFloat("_kMoonBrightness", MoonBrightness);
    }

    void FixedUpdate()
    {
        if (autoTime)
        {
            worldTime += Time.fixedDeltaTime * worldSpeed;
            if (worldTime > 1440) { worldTime -= 1440; }

            UpdateSky();
        }
    }
}
