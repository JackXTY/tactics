using AOT;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityStandardAssets.Vehicles.Car;

public class CppControl
{

    //CarControlCpp��InitializeCppControl������Cpp�ļ��б�д
    [DllImport("CppControl")]
    public static extern void CarControlCpp();
    [DllImport("CppControl")]
    public static extern void InitializeCppControl();

    /*
    //����callback����
    public delegate void LogDelegate(IntPtr message, int iSize);

    [DllImport("CppControl")]
    public static extern void InitCSharpDelegate(LogDelegate log);

    //C# Function for C++'s call
    [MonoPInvokeCallback(typeof(LogDelegate))]
    public static void LogMessageFromCpp(IntPtr message, int iSize)
    {
        Debug.Log(Marshal.PtrToStringAnsi(message, iSize));
    }
    */
    //����callback����
    public delegate float FloatDelegate(int CarNum);
    public delegate double doubleDelegate(int CarNum);
    public delegate int intDelegate();

    [DllImport("CppControl")]
    public static extern void InitSpeedDelegate(FloatDelegate callbackFloat);
    [DllImport("CppControl")]
    public static extern void InitPositionXDelegate(FloatDelegate callbackFloat);
    [DllImport("CppControl")]
    public static extern void InitPositionYDelegate(FloatDelegate callbackFloat);
    [DllImport("CppControl")]
    public static extern void InitPositionZDelegate(FloatDelegate callbackFloat);
    [DllImport("CppControl")]
    public static extern void InitCruiseErrorDelegate(FloatDelegate callbackFloat);
    [DllImport("CppControl")]
    public static extern void InitCurvatureDelegate(FloatDelegate callbackFloat);
    [DllImport("CppControl")]
    public static extern void InitAngleErrorDelegate(FloatDelegate callbackFloat);
    [DllImport("CppControl")]
    public static extern void InitPlayerNumDelegate(intDelegate callbackint);

    //����callback����
    public delegate void CarMoveDelegate(float steering, float accel, float footbrake, float handbrake, int CarNum);

    [DllImport("CppControl")]
    public static extern void InitCarMoveDelegate(CarMoveDelegate GetCarMove);

    //C# Function for C++'s call
    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static int CallbackPlayerNumFromCpp()
    {
        return GameSetting.NumofPlayer;
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static float CallbackSpeedFromCpp(int CarNum)
    {
        return SpeedDisplay.speed[CarNum];
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static float CallbackPositionXFromCpp(int CarNum)
    {
        return MiniMap2.CarPosition[CarNum].x;
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static float CallbackPositionYFromCpp(int CarNum)
    {
        return MiniMap2.CarPosition[CarNum].y;
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static float CallbackPositionZFromCpp(int CarNum)
    {
        return MiniMap2.CarPosition[CarNum].z;
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static float CallbackCruiseErrorFromCpp(int CarNum)
    {
        return CruiseData.DistanceError[CarNum];
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static float CallbackCurvatureFromCpp(int CarNum)
    {
        return CruiseData.Curvature[CarNum];
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static float CallbackAngleErrorFromCpp(int CarNum)
    {
        return CruiseData.AngleError[CarNum];
    }

    [MonoPInvokeCallback(typeof(FloatDelegate))]
    public static void GetCarMoveFromCpp(float steering, float accel, float footbrake, float handbrake, int CarNum)
    {
        CallCppControl.steering[CarNum] = steering;
        CallCppControl.accel[CarNum] = accel;
        CallCppControl.footbrake[CarNum] = footbrake;
        CallCppControl.handbrake[CarNum] = handbrake;
        /*
        CallCppControl.steering[CarNum] = float.Parse(steering.ToString("#0.0000"));
        CallCppControl.accel[CarNum] = float.Parse(accel.ToString("#0.0000"));
        CallCppControl.footbrake[CarNum] = float.Parse(footbrake.ToString("#0.0000"));
        CallCppControl.handbrake[CarNum] = float.Parse(handbrake.ToString("#0.0000"));
        */
    }
}