using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

// TODO: save slider information,
// then when switch camera, set new component's value according to slider
public enum PostEffect { Fog, DepthBlur, RainDrop, Blur };

public class RenderSystem : MonoBehaviour
{
    private Camera mainCam = null;

    public List<PostEffect> postEffectList = new();

    public Transform fogbox;

    PostBlur blurComp;
    PostFog fogComp;
    PostRaindrop rainDropComp;
    DepthBlur depthBlurComp;

    public void ChangeGameObjectStatus(GameObject obj)
    {
        obj.SetActive(false);
    }

    public void BlurToggleChange(Toggle toggle)
    {
        blurComp.enabled = toggle.isOn;
        if (toggle.isOn) { postEffectList.Add(PostEffect.Blur); }
        else { postEffectList.Remove(PostEffect.Blur); }
    }
    public void FogToggleChange(Toggle toggle)
    {
        fogComp.enabled = toggle.isOn;
        if (toggle.isOn) { postEffectList.Add(PostEffect.Fog); }
        else { postEffectList.Remove(PostEffect.Fog); }
    }
    public void RainDropToggleChange(Toggle toggle)
    {
        rainDropComp.enabled = toggle.isOn;
        if (toggle.isOn) { postEffectList.Add(PostEffect.RainDrop); }
        else { postEffectList.Remove(PostEffect.RainDrop); }
    }
    public void DepthBlurToggleChange(Toggle toggle)
    {
        depthBlurComp.enabled = toggle.isOn;
        if (toggle.isOn) { postEffectList.Add(PostEffect.DepthBlur); }
        else { postEffectList.Remove(PostEffect.DepthBlur); }
    }

    public void FogChangeHeight(Slider slider)
    {
        fogComp.fogHeightEnd = 80.0f * slider.value;
    }

    public void FogChangeDepth(Slider slider)
    {
        fogComp.fogDepthNear = 30.0f * slider.value;
    }

    public void FogChangeDensity(Slider slider)
    {
        fogComp.fogDensity = 3.0f * slider.value;
    }
    public void RainChangeSize(Slider slider)
    {
        // from 31 to 1
        rainDropComp.gridNum = 31.0f - slider.value * 30.0f;
    }
    public void RainChangeAmount(Slider slider)
    {
        rainDropComp.rainAmount = 1 + Mathf.RoundToInt(slider.value * 6.0f);
    }
    public void RainChangeSpeed(Slider slider)
    {
        rainDropComp.rainSpeed = slider.value * 3.0f;
    }
    public void DepthBlurChangeDistance(Slider slider)
    {
        // from 31 to 1
        depthBlurComp.focusDistance = slider.value * 20.0f;
    }
    public void DepthBlurChangeRange(Slider slider)
    {
        depthBlurComp.focusRange = slider.value * 20.0f;
    }
    public void DepthBlurChangeSparse(Slider slider)
    {
        depthBlurComp.radiusSparse = slider.value * 20.0f;
    }
    public void BlurChangeIteration(Slider slider)
    {
        // from 31 to 1
        blurComp.iterations = Mathf.RoundToInt(slider.value * 4.0f);
    }
    public void BlurChangeSpread(Slider slider)
    {
        blurComp.blurSpread = slider.value * 3.0f;
    }
    public void BlurChangeDownSample(Slider slider)
    {
        blurComp.downSample = 1 + Mathf.RoundToInt(slider.value * 7.0f);
    }


    void UpdateMainCamera()
    {
        foreach (PostEffect e in System.Enum.GetValues(typeof(PostEffect)))
        {
            switch (e)
            {
                case PostEffect.Blur:
                    if (!mainCam.TryGetComponent(out blurComp))
                    {
                        blurComp = mainCam.gameObject.AddComponent<PostBlur>();
                    }
                    blurComp.enabled = (postEffectList.Contains(e));
                    break;
                case PostEffect.DepthBlur:
                    if (!mainCam.TryGetComponent(out depthBlurComp))
                    {
                        depthBlurComp = mainCam.gameObject.AddComponent<DepthBlur>();
                    }
                    depthBlurComp.enabled = (postEffectList.Contains(e));
                    break;
                case PostEffect.Fog:
                    if (!mainCam.TryGetComponent(out fogComp))
                    {
                        fogComp = mainCam.gameObject.AddComponent<PostFog>();
                    }
                    fogComp.fogBoxTrans = fogbox;
                    fogComp.enabled = (postEffectList.Contains(e));
                    break;
                case PostEffect.RainDrop:
                    if (!mainCam.TryGetComponent(out rainDropComp))
                    {
                        rainDropComp = mainCam.gameObject.AddComponent<PostRaindrop>();
                    }
                    rainDropComp.enabled = (postEffectList.Contains(e));
                    break;
                default:
                    break;
            }
        }
    }
    
    void Awake()
    {
        mainCam = Camera.main;
        UpdateMainCamera();
    }


    /*
    void Update()
    {
        if(Camera.main != mainCam)
        {
            mainCam = Camera.main;
            UpdateMainCamera();
        }
    }
    */
}
