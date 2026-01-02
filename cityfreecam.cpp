// Made by Meatboxing(Meatboxer) https://www.youtube.com/@meatboxing
// License: Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) https://creativecommons.org/licenses/by-nc/4.0/
// Subscrube

#include <Windows.h>
#include <Xinput.h>
#include <cmath>

#pragma comment(lib, "Xinput.lib")

typedef __int64(__fastcall* tCamFunc)(__int64, __int64);

tCamFunc oCamFunc = nullptr;
BYTE original_bytes[14];
volatile bool frozen = false;
BYTE saved_data[880];

float cam_x = 0, cam_y = 0, cam_z = 0;
float pitch = 0, yaw = 0;
float speed = 0.018f;
float sensitivity = 0.01f;

__int64 __fastcall hkCamFunc(__int64 a1, __int64 a2) {
    DWORD old;
    VirtualProtect(oCamFunc, 14, PAGE_EXECUTE_READWRITE, &old);
    memcpy(oCamFunc, original_bytes, 14);
    VirtualProtect(oCamFunc, 14, old, &old);

    __int64 result = oCamFunc(a1, a2);

    if (!frozen) {
        memcpy(saved_data, (void*)a2, sizeof(saved_data));
        float* mat = (float*)a2;
        cam_x = mat[12];
        cam_y = mat[13];
        cam_z = mat[14];
        yaw = atan2f(mat[8], mat[10]);
        pitch = asinf(-mat[9]);
    }
    else {
        float* mat = (float*)a2;

        float cp = cosf(pitch);
        float sp = sinf(pitch);
        float cy = cosf(yaw);
        float sy = sinf(yaw);

        mat[0] = cy;
        mat[1] = 0;
        mat[2] = -sy;
        mat[3] = 0;
        mat[4] = sy * sp;
        mat[5] = cp;
        mat[6] = cy * sp;
        mat[7] = 0;
        mat[8] = sy * cp;
        mat[9] = -sp;
        mat[10] = cy * cp;
        mat[11] = 0;
        mat[12] = cam_x;
        mat[13] = cam_y;
        mat[14] = cam_z;
        mat[15] = 1;
    }

    VirtualProtect(oCamFunc, 14, PAGE_EXECUTE_READWRITE, &old);
    *(BYTE*)oCamFunc = 0xFF;
    *((BYTE*)oCamFunc + 1) = 0x25;
    *(DWORD*)((BYTE*)oCamFunc + 2) = 0;
    *(UINT64*)((BYTE*)oCamFunc + 6) = (UINT64)&hkCamFunc;
    VirtualProtect(oCamFunc, 14, old, &old);

    return result;
}

void InstallHook() {
    HMODULE hModule = GetModuleHandleA(NULL);
    BYTE* baseAddr = (BYTE*)hModule;
    oCamFunc = (tCamFunc)(baseAddr + 0x325A80);

    memcpy(original_bytes, oCamFunc, 14);

    DWORD old;
    VirtualProtect(oCamFunc, 14, PAGE_EXECUTE_READWRITE, &old);
    *(BYTE*)oCamFunc = 0xFF;
    *((BYTE*)oCamFunc + 1) = 0x25;
    *(DWORD*)((BYTE*)oCamFunc + 2) = 0;
    *(UINT64*)((BYTE*)oCamFunc + 6) = (UINT64)&hkCamFunc;
    VirtualProtect(oCamFunc, 14, old, &old);
}

DWORD WINAPI MainThread(LPVOID lpParam) {
    InstallHook();

    bool f1 = false;

    while (true) {
        if (GetAsyncKeyState(VK_F1) & 0x8000) {
            if (!f1) {
                frozen = !frozen;
                f1 = true;
            }
        }
        else f1 = false;

        if (frozen) {
            if (GetAsyncKeyState(VK_UP) & 0x8000) speed += 0.001f;
            if (GetAsyncKeyState(VK_DOWN) & 0x8000) speed = max(0.01f, speed - 0.001f);
            if (GetAsyncKeyState(VK_RIGHT) & 0x8000) sensitivity += 0.0001f;
            if (GetAsyncKeyState(VK_LEFT) & 0x8000) sensitivity = max(0.0001f, sensitivity - 0.0001f);

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

                yaw += rx * sensitivity;
                pitch = fmaxf(-1.5f, fminf(1.5f, pitch - ry * sensitivity));

                float fx = cosf(pitch) * sinf(yaw);
                float fy = -sinf(pitch);
                float fz = cosf(pitch) * cosf(yaw);
                float rx_vec = sinf(yaw + 1.57f);
                float rz_vec = cosf(yaw + 1.57f);

                float updown = 0;
                if (state.Gamepad.bRightTrigger > 30) updown += state.Gamepad.bRightTrigger / 255.0f;
                if (state.Gamepad.bLeftTrigger > 30) updown -= state.Gamepad.bLeftTrigger / 255.0f;

                cam_x += (fx * ly + rx_vec * lx) * speed;
                cam_y += (fy * ly + updown) * speed;
                cam_z += (fz * ly + rz_vec * lx) * speed;
            }
        }

        Sleep(16);
    }

    return 0;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD dwReason, LPVOID lpReserved) {
    if (dwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hModule);
        CreateThread(NULL, 0, MainThread, hModule, 0, NULL);
    }
    return TRUE;
}