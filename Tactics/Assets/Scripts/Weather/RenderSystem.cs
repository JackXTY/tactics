using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public enum Weather
{
    Sun, Cloudy, Rain, Snow, ThunderRain
}

/*
 * RenderSystem:
 *      - Manage the whole weather render system
 *      - Each post effect is executed in its own VolumeComponent (GaussianBlur/PostFog...), 
 *          and relative data also stored there
 */

public class RenderSystem : MonoBehaviour
{
    public static RenderSystem instance;
    
    public Weather weather;

    [Header("- BaseInfo")]

    public Transform fogbox;

    public Volume volume;

    [HideInInspector]
    public UnityEngine.Experiemntal.Rendering.Universal.GaussianBlur blurComp;
    [HideInInspector]
    public UnityEngine.Experiemntal.Rendering.Universal.PostFog fogComp;
    [HideInInspector]
    public UnityEngine.Experiemntal.Rendering.Universal.PostRainDrop rainDropComp;
    [HideInInspector]
    public UnityEngine.Experiemntal.Rendering.Universal.DepthBlur depthBlurComp;

    private Camera mainCam = null;

    public WeatherManager weatherManager;

    public Material terrainMat;

    bool hasCloud;


    // Rain Properties

    [Header("- Rain")]

    public GameObject rainParticleObj;

    [Range(0.0f, 100.0f)]
    public float rainAmount = 50.0f;

    ParticleSystem rainParticle;

    GroundRain groundRainComp;

    public bool terrainRainCircles = false;

    public bool rainPostProcess = false;

    void Awake()
    {
        instance = this;

        // check post process initialization
        {
            VolumeProfile volumeProfile = volume.profile;
            if (!volumeProfile) throw new System.NullReferenceException(nameof(UnityEngine.Rendering.VolumeProfile));

            if (!volumeProfile.TryGet(out blurComp)) throw new System.NullReferenceException(nameof(blurComp));
            if (!volumeProfile.TryGet(out fogComp)) throw new System.NullReferenceException(nameof(fogComp));
            if (!volumeProfile.TryGet(out rainDropComp)) throw new System.NullReferenceException(nameof(rainDropComp));
            if (!volumeProfile.TryGet(out depthBlurComp)) throw new System.NullReferenceException(nameof(depthBlurComp));
        }

        hasCloud = (weather == Weather.Rain || weather == Weather.Cloudy);
        weatherManager.SetCloudy(hasCloud);
        Rain();
    }

    public void Rain()
    {
        bool raining = (weather == Weather.Rain);

        // enable terrain rain effect
        if (terrainMat)
        {
            GroundRain grounRainComp;
            if (TryGetComponent(out grounRainComp))
            {
                grounRainComp.enabled = (raining && terrainRainCircles);
                CoreUtils.SetKeyword(terrainMat, "_RAIN_EFFECT", (raining && terrainRainCircles));
            }
        }

        // enable rain particle effect
        if (rainParticleObj)
        {
            rainParticleObj.SetActive(raining);
            
            if(rainParticleObj.TryGetComponent(out rainParticle))
            {
                if(!TryGetComponent(out groundRainComp))
                {
                    Debug.LogWarning("GroundRain Component Not Found!!");
                }
                UpdateRainAmount();
            }
            else
            {
                Debug.LogWarning("Rain Particle System Not Found!!");
            }
        }

        SetStatusComp(raining && rainPostProcess, rainDropComp);
    }

    public void UpdateRainAmount()
    {
        ParticleSystem.EmissionModule em = rainParticle.emission;
        em.rateOverTime = rainAmount * 8.0f;
        if (groundRainComp)
        {
            groundRainComp.raindropCount = (int)(rainAmount * 10.0f);
        }
        rainDropComp.rainAmount.Override(1 + Mathf.RoundToInt(rainAmount / 100.0f * 6.0f));
    }

    public void SetStatusComp(bool status, UnityEngine.Rendering.VolumeComponent Comp)
    {
        Comp.active = status;
    }
}
