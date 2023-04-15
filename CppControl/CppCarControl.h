#pragma once
#define DLLForUnity_API _declspec(dllexport)
//#define UnityLog(acStr)  char acLogStr[512] = { 0 }; sprintf_s(acLogStr, "%s",acStr); Debug::Log(acLogStr,strlen(acStr));

//C++ Call C#

EXTERN_C class TacticAPI
{
//�ӿڶ���
public:
	//�����ĸ�����(steering��accel��footbrake��handbrake)����С���ƶ�
	static void (*CarMove)(int CarNum, float steering, float accel, float footbrake, float handbrake);

	static float (*speed)(int CarNum); //����С���ٶ�
	static float (*acc)(int CarNum);//����С�����ٶ�
	static float (*midline)(int CarNum, float k, int index); //����С����������k�״��ĵ�·��������
	static float (*cruise_error)(int CarNum); //����С���������������ߵľ���
	static float (*curvature)(int CarNum); //����ǰ�����������ߵ�����
	static float (*yaw)(int CarNum); //����С����������������߷����ƫ��
	static float (*yawrate)(int CarNum); //����С�����ٶ�
	static int (*player_num)(); //����С������
	static float (*width)();//���ص�·���
};

void CarControli(int i);

//��Ϊ�ӿڶ�����ش��룬�����Ķ�
//C# Call C++

EXTERN_C void DLLForUnity_API InitSpeedDelegate(float (*callbackFloat)(int CarNum));
EXTERN_C void DLLForUnity_API InitAccDelegate(float (*callbackFloat)(int CarNum));
//EXTERN_C void DLLForUnity_API InitPositionXDelegate(float (*callbackFloat)(int CarNum));
//EXTERN_C void DLLForUnity_API InitPositionYDelegate(float (*callbackFloat)(int CarNum));
//EXTERN_C void DLLForUnity_API InitPositionZDelegate(float (*callbackFloat)(int CarNum));
EXTERN_C void DLLForUnity_API InitCruiseErrorDelegate(float (*callbackFloat)(int CarNum));
EXTERN_C void DLLForUnity_API InitCurvatureDelegate(float (*callbackFloat)(int CarNum));
EXTERN_C void DLLForUnity_API InitAngleErrorDelegate(float (*callbackFloat)(int CarNum));
EXTERN_C void DLLForUnity_API InitYawrateDelegate(float (*callbackFloat)(int CarNum));
EXTERN_C void DLLForUnity_API InitPlayerNumDelegate(int (*callbackint)());
EXTERN_C void DLLForUnity_API InitMidlineDelegate(float (*callbackfloat)(int CarNum, float k, int index));
EXTERN_C void DLLForUnity_API InitWidthDelegate(float (*callbackfloat)());
EXTERN_C void DLLForUnity_API InitCarMoveDelegate(void (*GetCarMove)(int CarNum, float steering, float accel, float footbrake, float handbrake));

EXTERN_C DLLForUnity_API void __stdcall CarControlCpp();
EXTERN_C DLLForUnity_API void __stdcall InitializeCppControl();
/*
EXTERN_C class Debug
{
	public:
		static void (*Log)(char* message, int iSize);
};
//EXTERN_C void DLLForUnity_API InitCSharpDelegate(void (*Log)(char* message, int iSize));
*/

