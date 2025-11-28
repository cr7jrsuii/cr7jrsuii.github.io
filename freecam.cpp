// Made by Meatboxing(Meatboxer) https://www.youtube.com/@meatboxing
// License: Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) https://creativecommons.org/licenses/by-nc/4.0/
// Subscrube

#include <Windows.h>
#include <Xinput.h>
#include <Psapi.h>
#include <cmath>
#include <vector>

#pragma comment(lib, "Xinput.lib")
#pragma comment(lib, "Psapi.lib")

typedef __int64(__fastcall* CameraUpdate)(__int64, float);
CameraUpdate OriginalUpdate = nullptr;
BYTE* FuncAddr = nullptr;
BYTE OriginalBytes[14] = {};

bool bFreecam = false;
float Pitch = 0.f, Yaw = 0.f, CamX = 0.f, CamY = 0.f, CamZ = 0.f, Speed = 0.08f, Sensitivity = 0.032f;

BYTE* SearchPattern(BYTE* start, size_t size, const char* pattern) {
    std::vector<int> bytes;
    std::vector<bool> mask;

    const char* p = pattern;
    while (*p) {
        if (*p == '?') {
            bytes.push_back(0);
            mask.push_back(false);
            p++;
        }
        else if (isxdigit(*p)) {
            char hex[3] = { 0 };
            hex[0] = *p++;
            if (isxdigit(*p)) hex[1] = *p++;
            bytes.push_back(strtol(hex, nullptr, 16));
            mask.push_back(true);
        }
        else {
            p++;
        }
    }

    for (size_t i = 0; i <= size - bytes.size(); i++) {
        bool found = true;
        for (size_t j = 0; j < bytes.size(); j++) {
            if (mask[j] && start[i + j] != (BYTE)bytes[j]) {
                found = false;
                break;
            }
        }
        if (found) return &start[i];
    }
    return nullptr;
}

std::vector<BYTE*> FindAllPatterns(BYTE* start, size_t size, const char* pattern) {
    std::vector<BYTE*> results;
    BYTE* current = start;
    size_t remaining = size;

    while (remaining > 0) {
        BYTE* found = SearchPattern(current, remaining, pattern);
        if (!found) break;

        results.push_back(found);
        size_t offset = (found - current) + 1;
        current = found + 1;
        remaining = size - (current - start);
    }

    return results;
}

int RateFunction(BYTE* addr, BYTE* base, size_t size) {
    int score = 0;
    size_t maxScan = 8192;

    if (addr < base || addr >= base + size) return 0;
    if (addr + maxScan > base + size) maxScan = base + size - addr;

    if (SearchPattern(addr, maxScan, "0C 0D 00 00")) score += 3;
    if (SearchPattern(addr, maxScan, "10 0D 00 00")) score += 2;
    if (SearchPattern(addr, maxScan, "14 0D 00 00")) score += 2;
    if (SearchPattern(addr, maxScan, "34 06 00 00")) score += 3;
    if (SearchPattern(addr, maxScan, "38 06 00 00")) score += 2;
    if (SearchPattern(addr, maxScan, "3C 06 00 00")) score += 2;
    if (SearchPattern(addr, maxScan, "4C 0D 00 00")) score += 2;
    if (SearchPattern(addr, maxScan, "90 0D 00 00")) score += 2;
    if (SearchPattern(addr, maxScan, "88 0E 00 00")) score += 1;
    if (SearchPattern(addr, maxScan, "28 0F 00 00")) score += 1;
    if (SearchPattern(addr, maxScan, "F3 0F")) score += 1;

    return score;
}

BYTE* LocateCameraFunction(HMODULE base) {
    MODULEINFO info = { 0 };
    if (!GetModuleInformation(GetCurrentProcess(), base, &info, sizeof(MODULEINFO)))
        return nullptr;

    BYTE* baseAddr = (BYTE*)info.lpBaseOfDll;
    size_t moduleSize = info.SizeOfImage;

    const char* pattern = "48 8B C4 55 41 54 41 55 41 56 41 57 48 8D";
    std::vector<BYTE*> candidates = FindAllPatterns(baseAddr, moduleSize, pattern);

    if (candidates.empty()) {
        pattern = "48 8B C4 55 41 54 41 55 41 56";
        candidates = FindAllPatterns(baseAddr, moduleSize, pattern);
    }

    if (candidates.empty()) {
        pattern = "48 8B C4 55 41 54";
        candidates = FindAllPatterns(baseAddr, moduleSize, pattern);
    }

    if (candidates.empty()) return nullptr;

    BYTE* best = nullptr;
    int bestScore = 0;

    for (BYTE* addr : candidates) {
        int score = RateFunction(addr, baseAddr, moduleSize);
        if (score > bestScore) {
            bestScore = score;
            best = addr;
        }
    }

    return (bestScore >= 8) ? best : nullptr;
}

__int64 __fastcall CameraHook(__int64 controller, float dt) {
    static bool bInitialized = false;

    if (controller && bFreecam) {
        if (!bInitialized) {
            CamX = *(float*)(controller + 3468);
            CamY = *(float*)(controller + 3472);
            CamZ = *(float*)(controller + 3476);
            bInitialized = true;
        }

        *(BYTE*)(controller + 3317) = 1;
        *(float*)(controller + 3040) = CamX;
        *(float*)(controller + 3044) = CamY;
        *(float*)(controller + 3048) = CamZ;

        float fx = cosf(Pitch) * sinf(Yaw);
        float fy = sinf(Pitch);
        float fz = cosf(Pitch) * cosf(Yaw);

        *(float*)(controller + 3024) = fx * 10.f;
        *(float*)(controller + 3028) = fy * 10.f;
        *(float*)(controller + 3032) = fz * 10.f;
    }
    else if (controller) {
        *(BYTE*)(controller + 3317) = 0;
        bInitialized = false;
    }

    DWORD old;
    VirtualProtect(FuncAddr, 14, PAGE_EXECUTE_READWRITE, &old);
    memcpy(FuncAddr, OriginalBytes, 14);
    VirtualProtect(FuncAddr, 14, old, &old);

    __int64 ret = OriginalUpdate(controller, dt);

    if (controller && bFreecam) {
        *(BYTE*)(controller + 3880) = 0;
        *(BYTE*)(controller + 64) = 0;
        *(DWORD*)(controller + 3884) = 0;
        *(BYTE*)(controller + 3788) = 0;
    }

    VirtualProtect(FuncAddr, 14, PAGE_EXECUTE_READWRITE, &old);
    FuncAddr[0] = 0xFF;
    FuncAddr[1] = 0x25;
    *(DWORD*)(FuncAddr + 2) = 0;
    *(DWORD64*)(FuncAddr + 6) = (DWORD64)&CameraHook;
    VirtualProtect(FuncAddr, 14, old, &old);

    return ret;
}

void InputLoop() {
    bool pressed = false;
    while (true) {
        if (GetAsyncKeyState(VK_F1) & 0x8000) {
            if (!pressed) {
                bFreecam = !bFreecam;
                pressed = true;
            }
        }
        else pressed = false;

        if (bFreecam) {
            XINPUT_STATE state = {};
            if (XInputGetState(0, &state) != ERROR_SUCCESS) {
                Sleep(16);
                continue;
            }

            if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP) Speed += 0.001f;
            if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_DOWN) {
                Speed -= 0.001f;
                if (Speed < 0.01f) Speed = 0.01f;
            }
            if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT) Sensitivity += 0.0005f;
            if (state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_LEFT) {
                Sensitivity -= 0.0005f;
                if (Sensitivity < 0.001f) Sensitivity = 0.001f;
            }

            float lx = state.Gamepad.sThumbLX / 32768.f;
            float ly = state.Gamepad.sThumbLY / 32768.f;
            float rx = state.Gamepad.sThumbRX / 32768.f;
            float ry = state.Gamepad.sThumbRY / 32768.f;

            if (fabsf(lx) < 0.15f) lx = 0;
            if (fabsf(ly) < 0.15f) ly = 0;
            if (fabsf(rx) < 0.15f) rx = 0;
            if (fabsf(ry) < 0.15f) ry = 0;

            Yaw += rx * Sensitivity;
            Pitch += ry * Sensitivity;
            if (Pitch > 1.5f) Pitch = 1.5f;
            if (Pitch < -1.5f) Pitch = -1.5f;

            float fx = cosf(Pitch) * sinf(Yaw);
            float fy = sinf(Pitch);
            float fz = cosf(Pitch) * cosf(Yaw);
            float rx_vec = sinf(Yaw + 1.57f);
            float rz_vec = cosf(Yaw + 1.57f);
            float updown = 0;

            if (state.Gamepad.bRightTrigger > 30) updown += state.Gamepad.bRightTrigger / 255.f;
            if (state.Gamepad.bLeftTrigger > 30) updown -= state.Gamepad.bLeftTrigger / 255.f;

            CamX += (fx * ly + rx_vec * lx) * Speed;
            CamY += (fy * ly + updown) * Speed;
            CamZ += (fz * ly + rz_vec * lx) * Speed;
        }
        Sleep(16);
    }
}

DWORD WINAPI Setup(LPVOID) {
    HMODULE base = GetModuleHandleA(NULL);
    if (!base) return 0;

    FuncAddr = LocateCameraFunction(base);
    if (!FuncAddr) return 0;

    memcpy(OriginalBytes, FuncAddr, 14);
    OriginalUpdate = (CameraUpdate)FuncAddr;

    DWORD old;
    if (!VirtualProtect(FuncAddr, 14, PAGE_EXECUTE_READWRITE, &old)) return 0;

    FuncAddr[0] = 0xFF;
    FuncAddr[1] = 0x25;
    *(DWORD*)(FuncAddr + 2) = 0;
    *(DWORD64*)(FuncAddr + 6) = (DWORD64)&CameraHook;
    VirtualProtect(FuncAddr, 14, old, &old);

    CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)InputLoop, NULL, 0, NULL);
    return 0;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID reserved) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hModule);
        CreateThread(NULL, 0, Setup, NULL, 0, NULL);
    }
    return TRUE;
}
