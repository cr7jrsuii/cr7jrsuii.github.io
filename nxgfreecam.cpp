// Made by Meatboxing(Meatboxer) https://www.youtube.com/@meatboxing
// License: Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) https://creativecommons.org/licenses/by-nc/4.0/
// Subscrube

#include <windows.h>
#include <Xinput.h>
#include <math.h>
#include <Psapi.h>

#pragma comment(lib, "XInput.lib")
#pragma comment(lib, "Psapi.lib")

typedef float* (__cdecl* CameraFunction_t)(float* a1, float* a2);

CameraFunction_t original_CameraFunction = nullptr;
void* trampoline = nullptr;

bool enabled = false;
bool toggled = false;
float frozen_matrix[16] = { 0 };

float cam_pos_x = 0.0f, cam_pos_y = 0.0f, cam_pos_z = 0.0f;
float cam_yaw = 0.0f, cam_pitch = 0.0f;
float move_speed = 0.001f, rotate_speed = 0.00005f;

float* __cdecl hooked_CameraFunction(float* a1, float* a2)
{
    if (!a2)
    {
        return ((CameraFunction_t)trampoline)(a1, a2);
    }

    bool key_down = GetAsyncKeyState(VK_F1) & 0x8000;
    if (key_down && !toggled)
    {
        enabled = !enabled;

        if (enabled)
        {
            memcpy(frozen_matrix, a2, 16 * sizeof(float));
            cam_pos_x = cam_pos_y = cam_pos_z = 0.0f;
            cam_yaw = cam_pitch = 0.0f;
        }
    }
    toggled = key_down;

    if (enabled)
    {
        if (GetAsyncKeyState(VK_UP) & 0x8000) move_speed += 0.0001f;
        if (GetAsyncKeyState(VK_DOWN) & 0x8000) move_speed = max(0.0001f, move_speed - 0.0001f);
        if (GetAsyncKeyState(VK_RIGHT) & 0x8000) rotate_speed += 0.00001f;
        if (GetAsyncKeyState(VK_LEFT) & 0x8000) rotate_speed = max(0.00001f, rotate_speed - 0.00001f);

        XINPUT_STATE state = {};
        if (XInputGetState(0, &state) == ERROR_SUCCESS)
        {
            float lx = state.Gamepad.sThumbLX / 32768.0f, ly = state.Gamepad.sThumbLY / 32768.0f;
            float rx = state.Gamepad.sThumbRX / 32768.0f, ry = state.Gamepad.sThumbRY / 32768.0f;
            if (fabsf(lx) < 0.24f) lx = 0; if (fabsf(ly) < 0.24f) ly = 0;
            if (fabsf(rx) < 0.24f) rx = 0; if (fabsf(ry) < 0.24f) ry = 0;

            cam_yaw += rx * rotate_speed;
            cam_pitch -= ry * rotate_speed * 0.7f;
            if (cam_pitch > 1.5f) cam_pitch = 1.5f;
            if (cam_pitch < -1.5f) cam_pitch = -1.5f;

            float fx = cosf(cam_pitch) * sinf(cam_yaw), fy = -sinf(cam_pitch), fz = cosf(cam_pitch) * cosf(cam_yaw);
            float rx_vec = cosf(cam_yaw), rz_vec = -sinf(cam_yaw);

            cam_pos_x += (fx * ly + rx_vec * lx) * move_speed;
            cam_pos_y += fy * ly * move_speed;
            cam_pos_z += (fz * ly + rz_vec * lx) * move_speed;

            float upDown = (state.Gamepad.bRightTrigger - state.Gamepad.bLeftTrigger) / 255.0f;
            cam_pos_y += upDown * move_speed * 0.5f;
        }

        float modified_matrix[16];
        memcpy(modified_matrix, frozen_matrix, 16 * sizeof(float));

        float cp = cosf(cam_pitch), sp = sinf(cam_pitch), cy = cosf(cam_yaw), sy = sinf(cam_yaw);
        modified_matrix[0] = cy; modified_matrix[1] = 0; modified_matrix[2] = -sy;
        modified_matrix[4] = sy * sp; modified_matrix[5] = cp; modified_matrix[6] = cy * sp;
        modified_matrix[8] = sy * cp; modified_matrix[9] = -sp; modified_matrix[10] = cy * cp;

        modified_matrix[12] = frozen_matrix[12] + cam_pos_x;
        modified_matrix[13] = frozen_matrix[13] + cam_pos_y;
        modified_matrix[14] = frozen_matrix[14] + cam_pos_z;

        memcpy(a2, modified_matrix, 16 * sizeof(float));
    }

    return ((CameraFunction_t)trampoline)(a1, a2);
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    if (fdwReason == DLL_PROCESS_ATTACH)
    {
        HMODULE hModule = GetModuleHandle(NULL);
        MODULEINFO modInfo;
        GetModuleInformation(GetCurrentProcess(), hModule, &modInfo, sizeof(MODULEINFO));

        BYTE* moduleBase = (BYTE*)modInfo.lpBaseOfDll;
        DWORD moduleSize = modInfo.SizeOfImage;

        BYTE pattern[] = { 0x83, 0xEC, 0x0C, 0x8B, 0x4C, 0x24, 0x14, 0xD9, 0x41, 0x30, 0x8B, 0x44, 0x24, 0x10, 0xD9, 0xE0 };

        for (DWORD i = 0; i < moduleSize - 16; i++)
        {
            if (memcmp(moduleBase + i, pattern, 16) == 0)
            {
                original_CameraFunction = (CameraFunction_t)(moduleBase + i);

                trampoline = VirtualAlloc(NULL, 32, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
                if (!trampoline) return FALSE;

                memcpy(trampoline, original_CameraFunction, 7);

                BYTE* trampolineBytes = (BYTE*)trampoline;
                trampolineBytes[7] = 0xE9;
                DWORD returnAddress = ((DWORD)original_CameraFunction + 7) - ((DWORD)trampoline + 12);
                memcpy(&trampolineBytes[8], &returnAddress, 4);

                DWORD oldProtect;
                VirtualProtect((LPVOID)original_CameraFunction, 7, PAGE_EXECUTE_READWRITE, &oldProtect);

                BYTE hookJump[7];
                hookJump[0] = 0xE9;
                DWORD relativeAddress = ((DWORD)hooked_CameraFunction - (DWORD)original_CameraFunction - 5);
                memcpy(&hookJump[1], &relativeAddress, 4);
                hookJump[5] = 0x90;
                hookJump[6] = 0x90;

                memcpy((LPVOID)original_CameraFunction, hookJump, 7);
                VirtualProtect((LPVOID)original_CameraFunction, 7, oldProtect, &oldProtect);

                break;
            }
        }
    }
    else if (fdwReason == DLL_PROCESS_DETACH)
    {
        if (trampoline)
        {
            VirtualFree(trampoline, 0, MEM_RELEASE);
        }
    }

    return TRUE;
}
