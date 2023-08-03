using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering.Universal;


public class RenderSystem : MonoBehaviour
{
    private Camera mainCam = null;

    public Transform fogbox;

    public UnityEngine.Rendering.Volume volume;

    UnityEngine.Experiemntal.Rendering.Universal.GaussianBlur blurComp;
    UnityEngine.Experiemntal.Rendering.Universal.PostFog fogComp;
    UnityEngine.Experiemntal.Rendering.Universal.PostRainDrop rainDropComp;
    UnityEngine.Experiemntal.Rendering.Universal.DepthBlur depthBlurComp;

    void Awake()
    {
        UnityEngine.Rendering.VolumeProfile volumeProfile = volume.profile;
        if (!volumeProfile) throw new System.NullReferenceException(nameof(UnityEngine.Rendering.VolumeProfile));

        if (!volumeProfile.TryGet(out blurComp)) throw new System.NullReferenceException(nameof(blurComp));
        if (!volumeProfile.TryGet(out fogComp)) throw new System.NullReferenceException(nameof(fogComp));
        if (!volumeProfile.TryGet(out rainDropComp)) throw new System.NullReferenceException(nameof(rainDropComp));
        if (!volumeProfile.TryGet(out depthBlurComp)) throw new System.NullReferenceException(nameof(depthBlurComp));

    }

    public void ChangeGameObjectStatus(GameObject obj)
    {
        obj.SetActive(false);
    }

    public void BlurToggleChange(Toggle toggle)
    {
        blurComp.active = toggle.isOn;
    }
    public void FogToggleChange(Toggle toggle)
    {
        fogComp.active = toggle.isOn;
    }
    public void RainDropToggleChange(Toggle toggle)
    {
        rainDropComp.active = toggle.isOn;
    }
    public void DepthBlurToggleChange(Toggle toggle)
    {
        depthBlurComp.active = toggle.isOn;
    }

    public void FogChangeHeight(Slider slider)
    {
        fogComp.fogHeightEnd.Override(80.0f * slider.value);
    }

    public void FogChangeDepth(Slider slider)
    {
        fogComp.fogDepthNear.Override(30.0f * slider.value);
    }

    public void FogChangeDensity(Slider slider)
    {
        fogComp.fogDensity.Override(3.0f * slider.value);
    }
    public void RainChangeSize(Slider slider)
    {
        // from 31 to 1
        rainDropComp.gridNum.Override(31.0f - slider.value * 30.0f);
    }
    public void RainChangeAmount(Slider slider)
    {
        rainDropComp.rainAmount.Override(1 + Mathf.RoundToInt(slider.value * 6.0f));
    }
    public void RainChangeSpeed(Slider slider)
    {
        rainDropComp.rainSpeed.Override(slider.value * 3.0f);
    }
    public void DepthBlurChangeDistance(Slider slider)
    {
        // from 31 to 1
        depthBlurComp.focusDistance.Override(slider.value * 20.0f);
    }
    public void DepthBlurChangeRange(Slider slider)
    {
        depthBlurComp.focusRange.Override(slider.value * 20.0f);
    }
    public void DepthBlurChangeSparse(Slider slider)
    {
        depthBlurComp.radiusSparse.Override(slider.value * 20.0f);
    }
    public void BlurChangeIteration(Slider slider)
    {
        // from 31 to 1
        blurComp.iterations.Override(Mathf.RoundToInt(slider.value * 4.0f));
    }
    public void BlurChangeSpread(Slider slider)
    {
        blurComp.blurSpread.Override(slider.value * 3.0f);
    }
    public void BlurChangeDownSample(Slider slider)
    {
        blurComp.downSample.Override(1 + Mathf.RoundToInt(slider.value * 7.0f));
    }
}
