using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeatherManager : MonoBehaviour
{
    public Material skyboxMat;

    public Transform directionalLight;

    public bool autoTime = true;

    [Tooltip("how many minutes for weather system per second in real world, for auto time mode")]
    public float worldSpeed = 30;

    [Tooltip("when the system begin, in hour")]
    public float worldBeginTime = 0;

    float worldTime = 0; // when in world now (in mins)
    float timeRatio; // timeRatio in [0, 1]; 0 => night, 1 => noon

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
        Debug.Log("sun angle = " + sunAngle.ToString() + "timeRatio = " + timeRatio.ToString());
        directionalLight.rotation = Quaternion.Euler((180 * sunAngle), 0, 0);

    }

    public void InitMat()
    {
        worldTime = (worldBeginTime * 60) % 1440;
        UpdateSky();
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
