// Made by Meatboxing(Meatboxer) https://www.youtube.com/@meatboxing
// License: Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) https://creativecommons.org/licenses/by-nc/4.0/
// Subscrube

#include <Windows.h>
#include <Xinput.h>
#include <cmath>
#include <Psapi.h>

#pragma comment(lib, "XInput.lib")
#pragma comment(lib, "Psapi.lib")

typedef float* (__cdecl* CameraFunction_t)(float* a1, float* a2);

CameraFunction_t original_CameraFunction = nullptr;
void* trampoline = nullptr;
bool enabled = false;

float frozen_matrix[16] = { 0 };
float cam_pos_x = 0.0f, cam_pos_y = 0.0f, cam_pos_z = 0.0f;
float cam_yaw = 0.0f, cam_pitch = 0.0f;
float move_speed = 0.018f, rotate_speed = 0.01f;

float* __cdecl hooked_CameraFunction(float* a1, float* a2) {
    if (!a2) {
        return ((CameraFunction_t)trampoline)(a1, a2);
    }

    float* result = ((CameraFunction_t)trampoline)(a1, a2);

    if (!enabled) {
        memcpy(frozen_matrix, a2, 16 * sizeof(float));
        cam_pos_x = a2[12];
        cam_pos_y = a2[13];
        cam_pos_z = a2[14];
        cam_yaw = atan2f(a2[8], a2[10]);
        cam_pitch = asinf(-a2[9]);
    }
    else {
        float cp = cosf(cam_pitch), sp = sinf(cam_pitch);
        float cy = cosf(cam_yaw), sy = sinf(cam_yaw);

        a2[0] = cy;       a2[1] = 0;   a2[2] = -sy;      a2[3] = 0;
        a2[4] = sy * sp;  a2[5] = cp;  a2[6] = cy * sp;  a2[7] = 0;
        a2[8] = sy * cp;  a2[9] = -sp; a2[10] = cy * cp;  a2[11] = 0;
        a2[12] = cam_pos_x;
        a2[13] = cam_pos_y;
        a2[14] = cam_pos_z;
        a2[15] = 1;
    }

    return result;
}

DWORD WINAPI MainThread(LPVOID lpParam) {
    bool f1_prev = false;

    while (true) {
        bool f1_down = GetAsyncKeyState(VK_F1) & 0x8000;
        if (f1_down && !f1_prev) {
            enabled = !enabled;
        }
        f1_prev = f1_down;

        if (enabled) {
            if (GetAsyncKeyState(VK_UP) & 0x8000)    move_speed += 0.001f;
            if (GetAsyncKeyState(VK_DOWN) & 0x8000)  move_speed = max(0.01f, move_speed - 0.001f);
            if (GetAsyncKeyState(VK_RIGHT) & 0x8000) rotate_speed += 0.0001f;
            if (GetAsyncKeyState(VK_LEFT) & 0x8000)  rotate_speed = max(0.0001f, rotate_speed - 0.0001f);

            XINPUT_STATE state = {};
            if (XInputGetState(0, &state) == ERROR_SUCCESS) {
                float lx = state.Gamepad.sThumbLX / 32768.0f;
                float ly = state.Gamepad.sThumbLY / 32768.0f;
                float rx = state.Gamepad.sThumbRX / 32768.0f;
                float ry = state.Gamepad.sThumbRY / 32768.0f;

                if (fabsf(lx) < 0.15f) lx = 0;
                if (fabsf(ly) < 0.15f) ly = 0;
                if (fabsf(rx) < 0.15f) rx = 0;
                if (fabsf(ry) < 0.15f) ry = 0;

                cam_yaw += rx * rotate_speed;
                cam_pitch = fmaxf(-1.5f, fminf(1.5f, cam_pitch - ry * rotate_speed));

                float fx = cosf(cam_pitch) * sinf(cam_yaw);
                float fy = -sinf(cam_pitch);
                float fz = cosf(cam_pitch) * cosf(cam_yaw);
                float rx_vec = sinf(cam_yaw + 1.57f);
                float rz_vec = cosf(cam_yaw + 1.57f);

                float updown = 0;
                if (state.Gamepad.bRightTrigger > 30) updown += state.Gamepad.bRightTrigger / 255.0f;
                if (state.Gamepad.bLeftTrigger > 30) updown -= state.Gamepad.bLeftTrigger / 255.0f;

                cam_pos_x += (fx * ly + rx_vec * lx) * move_speed;
                cam_pos_y += (fy * ly + updown) * move_speed;
                cam_pos_z += (fz * ly + rz_vec * lx) * move_speed;
            }
        }

        Sleep(16);
    }
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinstDLL);

        HMODULE hModule = GetModuleHandle(NULL);
        MODULEINFO modInfo;
        GetModuleInformation(GetCurrentProcess(), hModule, &modInfo, sizeof(MODULEINFO));
        BYTE* moduleBase = (BYTE*)modInfo.lpBaseOfDll;
        DWORD moduleSize = modInfo.SizeOfImage;

        BYTE pattern[] = { 0x83, 0xEC, 0x0C, 0x8B, 0x4C, 0x24, 0x14, 0xD9, 0x41, 0x30, 0x8B, 0x44, 0x24, 0x10, 0xD9, 0xE0 };

        for (DWORD i = 0; i < moduleSize - 16; i++) {
            if (memcmp(moduleBase + i, pattern, 16) == 0) {
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

                CreateThread(NULL, 0, MainThread, NULL, 0, NULL);
                break;
            }
        }
    }
    else if (fdwReason == DLL_PROCESS_DETACH) {
        if (trampoline) VirtualFree(trampoline, 0, MEM_RELEASE);
    }
    return TRUE;
}