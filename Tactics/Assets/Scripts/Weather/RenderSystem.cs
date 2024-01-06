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

    public GameObject rainParticleObj;

    public Material terrainMat;

    bool hasCloud;

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
        if (terrainMat)
        {
            if (raining)
            {
                // terrainMat.EnableKeyword("_RAIN_EFFECT");
                CoreUtils.SetKeyword(terrainMat, "_RAIN_EFFECT", true);
            }
            else
            {
                // terrainMat.DisableKeyword("_RAIN_EFFECT");
                CoreUtils.SetKeyword(terrainMat, "_RAIN_EFFECT", false);
            }
        }

        if (GetComponent<GroundRain>())
        {
            GetComponent<GroundRain>().enabled = raining;
        }
        if (rainParticleObj)
        {
            rainParticleObj.SetActive(raining);
        }

    }
   
    public void SetStatusComp(bool status, UnityEngine.Rendering.VolumeComponent Comp)
    {
        Comp.active = status;
    }

}
