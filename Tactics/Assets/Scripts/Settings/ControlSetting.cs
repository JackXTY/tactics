/**
 * @file ControlSetting.cs
 * @brief This scrips allows the user to custom the control settings of the game.
 * @author Yueyuan Li
 * @date 2023-04-27
 * @copyright GNU Public License
 */

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class ControlSetting : MonoBehaviour
{
    [SerializeField] private TMP_Text inputSourceLabel;
    private string[] inputSource = {"Keyboard and mouse", "Joystick"};
    private int inputSourceIndex = 0;

    void Start()
    {
        UpdateInputSourceLabel();
    }

    public void SwitchInput(int switchDirection)
    {
        inputSourceIndex += switchDirection;

        if (inputSourceIndex < 0)
        {
            inputSourceIndex = inputSource.Length - 1;
        }
        else if (inputSourceIndex >= inputSource.Length)
        {
            inputSourceIndex = 0;
        }

        UpdateInputSourceLabel();
    }

    private void UpdateInputSourceLabel ()
    {
        inputSourceLabel.text = inputSource[inputSourceIndex];
    }
}
