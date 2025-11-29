// Made by Meatboxing(Meatboxer) https://www.youtube.com/@meatboxing
// License: Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) https://creativecommons.org/licenses/by-nc/4.0/
// Subscrube

#include <windows.h>
#include <math.h>
#include <Xinput.h>

#pragma comment(lib, "Xinput.lib")

typedef int(__cdecl* CameraFunction_t)(float*, int);
CameraFunction_t original_CameraFunction = nullptr;
BYTE original_bytes[5];
bool enabled = false, toggled = false;
float cam_x, cam_y, cam_z, cam_yaw, cam_pitch, move_speed = 0.018f, sensitivity = 0.006f;

int __cdecl hook_CameraFunction(float* a1, int a2) {
    bool key_down = GetAsyncKeyState(VK_F1) & 0x8000;
    if (key_down && !toggled) enabled = !enabled;
    toggled = key_down;

    if (!enabled && a1) {
        cam_x = a1[12]; cam_y = a1[13]; cam_z = a1[14];
        cam_yaw = atan2f(a1[8], a1[10]); cam_pitch = asinf(-a1[9]);
    }
    else if (enabled) {
        XINPUT_STATE state = {};
        if (XInputGetState(0, &state) == ERROR_SUCCESS) {
            if (GetAsyncKeyState(VK_UP) & 0x8000) move_speed += 0.001f;
            if (GetAsyncKeyState(VK_DOWN) & 0x8000) move_speed = max(0.01f, move_speed - 0.001f);
            if (GetAsyncKeyState(VK_RIGHT) & 0x8000) sensitivity += 0.0001f;
            if (GetAsyncKeyState(VK_LEFT) & 0x8000) sensitivity = max(0.0001f, sensitivity - 0.0001f);

            float lx = state.Gamepad.sThumbLX / 32768.0f, ly = state.Gamepad.sThumbLY / 32768.0f;
            float rx = state.Gamepad.sThumbRX / 32768.0f, ry = state.Gamepad.sThumbRY / 32768.0f;
            if (fabsf(lx) < 0.15f) lx = 0; if (fabsf(ly) < 0.15f) ly = 0;
            if (fabsf(rx) < 0.15f) rx = 0; if (fabsf(ry) < 0.15f) ry = 0;

            cam_yaw += rx * sensitivity;
            cam_pitch = fmaxf(-1.5f, fminf(1.5f, cam_pitch - ry * sensitivity));

            float fx = cosf(cam_pitch) * sinf(cam_yaw), fy = -sinf(cam_pitch), fz = cosf(cam_pitch) * cosf(cam_yaw);
            float rx_vec = sinf(cam_yaw + 1.57f), rz_vec = cosf(cam_yaw + 1.57f);
            float updown = (state.Gamepad.bRightTrigger > 30 ? state.Gamepad.bRightTrigger / 255.0f : 0)
                - (state.Gamepad.bLeftTrigger > 30 ? state.Gamepad.bLeftTrigger / 255.0f : 0);

            cam_x += (fx * ly + rx_vec * lx) * move_speed;
            cam_y += (fy * ly + updown) * move_speed;
            cam_z += (fz * ly + rz_vec * lx) * move_speed;
        }
        if (a1) {
            float cp = cosf(cam_pitch), sp = sinf(cam_pitch), cy = cosf(cam_yaw), sy = sinf(cam_yaw);
            a1[0] = cy; a1[2] = -sy; a1[4] = sy * sp; a1[5] = cp; a1[6] = cy * sp;
            a1[8] = sy * cp; a1[9] = -sp; a1[10] = cy * cp; a1[12] = cam_x; a1[13] = cam_y; a1[14] = cam_z;
        }
    }

    DWORD old;
    VirtualProtect(original_CameraFunction, 5, PAGE_EXECUTE_READWRITE, &old);
    memcpy(original_CameraFunction, original_bytes, 5);
    int result = original_CameraFunction(a1, a2);
    *(BYTE*)original_CameraFunction = 0xE9;
    *(DWORD*)((DWORD)original_CameraFunction + 1) = (DWORD)hook_CameraFunction - (DWORD)original_CameraFunction - 5;
    VirtualProtect(original_CameraFunction, 5, old, &old);
    return result;
}

DWORD WINAPI MainThread(LPVOID param) {
    BYTE* base = (BYTE*)GetModuleHandle(NULL);
    IMAGE_NT_HEADERS* ntHeaders = (IMAGE_NT_HEADERS*)(base + ((IMAGE_DOS_HEADER*)base)->e_lfanew);
    BYTE* codeBase = base + ntHeaders->OptionalHeader.BaseOfCode;
    BYTE pattern[] = { 0x81, 0xEC, 0xC8, 0x00, 0x00, 0x00, 0x55, 0x56 };

    for (DWORD i = 0; i < ntHeaders->OptionalHeader.SizeOfCode - 8; i++) {
        if (memcmp(codeBase + i, pattern, 8) == 0) {
            original_CameraFunction = (CameraFunction_t)(codeBase + i);
            memcpy(original_bytes, original_CameraFunction, 5);
            DWORD old;
            VirtualProtect(original_CameraFunction, 5, PAGE_EXECUTE_READWRITE, &old);
            *(BYTE*)original_CameraFunction = 0xE9;
            *(DWORD*)((DWORD)original_CameraFunction + 1) = (DWORD)hook_CameraFunction - (DWORD)original_CameraFunction - 5;
            VirtualProtect(original_CameraFunction, 5, old, &old);
            break;
        }
    }
    return 0;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID reserved) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hModule);
        HANDLE h = CreateThread(NULL, 0, MainThread, NULL, 0, NULL);
        if (h) CloseHandle(h);
    }
    return TRUE;
}
