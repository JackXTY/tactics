using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public enum ToggleTag
{
    BlurToggle, FogToggle, RainDropToggle, DepthBlurToggle
}

[Serializable]
public struct ToggleInfo
{
    public Toggle ui;
    public ToggleTag tag;
}


public class RenderSettingPanel : MonoBehaviour
{
    public List<ToggleInfo> toggleList;
    

    private void Start()
    {
        // toggleDict = new();
        foreach(ToggleInfo info in toggleList)
        {
            info.ui.onValueChanged.AddListener(delegate {
                ToggleValueChanged(info);
            });
        }
    }

    void ToggleValueChanged(ToggleInfo info)
    {
        RenderSystem.instance.SetStatusComp(info.ui.isOn, GetVolumeComp(info.tag));
    }

    UnityEngine.Rendering.VolumeComponent GetVolumeComp(ToggleTag tag)
    {
        if(tag == ToggleTag.BlurToggle)
        {
            return RenderSystem.instance.blurComp;
        }
        else if (tag == ToggleTag.FogToggle)
        {
            return RenderSystem.instance.fogComp;
        }
        else if (tag == ToggleTag.RainDropToggle)
        {
            return RenderSystem.instance.rainDropComp;
        }
        else if (tag == ToggleTag.DepthBlurToggle)
        {
            return RenderSystem.instance.depthBlurComp;
        }
        return null;
    }

    public void ChangeGameObjectStatus(GameObject obj)
    {
        obj.SetActive(false);
    }

    
    public void FogChangeHeight(Slider slider)
    {
        RenderSystem.instance.fogComp.fogHeightEnd.Override(80.0f * slider.value);
    }

    public void FogChangeDepth(Slider slider)
    {
        RenderSystem.instance.fogComp.fogDepthNear.Override(30.0f * slider.value);
    }

    public void FogChangeDensity(Slider slider)
    {
        RenderSystem.instance.fogComp.fogDensity.Override(3.0f * slider.value);
    }
    public void RainChangeSize(Slider slider)
    {
        // from 31 to 1
        RenderSystem.instance.rainDropComp.gridNum.Override(31.0f - slider.value * 30.0f);
    }
    public void RainChangeAmount(Slider slider)
    {
        RenderSystem.instance.rainDropComp.rainAmount.Override(1 + Mathf.RoundToInt(slider.value * 6.0f));
    }
    public void RainChangeSpeed(Slider slider)
    {
        RenderSystem.instance.rainDropComp.rainSpeed.Override(slider.value * 3.0f);
    }
    public void DepthBlurChangeDistance(Slider slider)
    {
        // from 31 to 1
        RenderSystem.instance.depthBlurComp.focusDistance.Override(slider.value * 20.0f);
    }
    public void DepthBlurChangeRange(Slider slider)
    {
        RenderSystem.instance.depthBlurComp.focusRange.Override(slider.value * 20.0f);
    }
    public void DepthBlurChangeSparse(Slider slider)
    {
        RenderSystem.instance.depthBlurComp.radiusSparse.Override(slider.value * 20.0f);
    }
    public void BlurChangeIteration(Slider slider)
    {
        // from 31 to 1
        RenderSystem.instance.blurComp.iterations.Override(Mathf.RoundToInt(slider.value * 4.0f));
    }
    public void BlurChangeSpread(Slider slider)
    {
        RenderSystem.instance.blurComp.blurSpread.Override(slider.value * 3.0f);
    }
    public void BlurChangeDownSample(Slider slider)
    {
        RenderSystem.instance.blurComp.downSample.Override(1 + Mathf.RoundToInt(slider.value * 7.0f));
    }
    
}
