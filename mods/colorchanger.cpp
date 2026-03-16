#include <windows.h>
#include <cstdio>
#include <cmath>

typedef void(__fastcall* Text3DFunc)(
    const char*, float, float, float, float, float, float, int,
    unsigned char, unsigned char, unsigned char, unsigned char);

Text3DFunc oText3D = nullptr;
uintptr_t hookAddr = 0;
BYTE* trampoline = nullptr;
HMODULE hThisDll = nullptr;

struct Settings {
    bool rainbow = false;
    float speed = 1.0f, hue = 0.0f;
    int red = 255, green = 0, blue = 0;
    DWORD lastUpdate = 0;
} settings;

void HSVtoRGB(float h, float s, float v, int& r, int& g, int& b) {
    float c = v * s, x = c * (1 - fabsf(fmodf(h / 60.0f, 2) - 1)), m = v - c;
    float rf, gf, bf;
    if (h < 60) { rf = c; gf = x; bf = 0; }
    else if (h < 120) { rf = x; gf = c; bf = 0; }
    else if (h < 180) { rf = 0; gf = c; bf = x; }
    else if (h < 240) { rf = 0; gf = x; bf = c; }
    else if (h < 300) { rf = x; gf = 0; bf = c; }
    else { rf = c; gf = 0; bf = x; }
    r = (int)((rf + m) * 255);
    g = (int)((gf + m) * 255);
    b = (int)((bf + m) * 255);
}

void LoadConfig() {
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(hThisDll, path, MAX_PATH);
    wchar_t* last = wcsrchr(path, L'\\');
    if (last) last[1] = 0;
    wcscat_s(path, L"color.json");

    FILE* f = nullptr;
    _wfopen_s(&f, path, L"r");
    if (!f) { MessageBoxW(nullptr, L"No color.json found", L"Color Changer", MB_OK | MB_ICONERROR); return; }

    char buf[1024];
    size_t len = fread(buf, 1, sizeof(buf) - 1, f);
    buf[len] = 0;
    fclose(f);

    auto skipToValue = [&](const char* key) -> const char* {
        const char* p = strstr(buf, key);
        if (!p) return nullptr;
        p += strlen(key);
        while (*p == ' ' || *p == ':' || *p == '\t' || *p == '\n' || *p == '\r') p++;
        return p;
        };

    const char* p;
    if ((p = skipToValue("\"rainbow\""))) settings.rainbow = strncmp(p, "true", 4) == 0;
    if ((p = skipToValue("\"speed\"")))   settings.speed = (float)atof(p);
    if ((p = skipToValue("\"red\"")))     settings.red = atoi(p);
    if ((p = skipToValue("\"green\"")))   settings.green = atoi(p);
    if ((p = skipToValue("\"blue\"")))    settings.blue = atoi(p);
}

void __fastcall hkText3D(
    const char* text, float x, float y, float z,
    float scaleX, float scaleY, float scaleZ, int alignment,
    unsigned char r, unsigned char g, unsigned char b, unsigned char a)
{
    float br = (r + g + b) / (3.0f * 255.0f);

    if (settings.rainbow) {
        DWORD now = GetTickCount();
        settings.hue += settings.speed * ((now - settings.lastUpdate) / 1000.0f) * 60.0f;
        settings.lastUpdate = now;
        if (settings.hue >= 360.0f) settings.hue = 0.0f;
        int rn, gn, bn;
        HSVtoRGB(settings.hue, 1.0f, 1.0f, rn, gn, bn);
        r = (unsigned char)(rn * br);
        g = (unsigned char)(gn * br);
        b = (unsigned char)(bn * br);
    }
    else {
        r = (unsigned char)(settings.red * br);
        g = (unsigned char)(settings.green * br);
        b = (unsigned char)(settings.blue * br);
    }

    oText3D(text, x, y, z, scaleX, scaleY, scaleZ, alignment, r, g, b, a);
}

void InstallHook() {
    uintptr_t base = (uintptr_t)GetModuleHandle(NULL);
    hookAddr = base + 0x54C940;

    const size_t stolenBytes = 18;
    trampoline = (BYTE*)VirtualAlloc(nullptr, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!trampoline) return;

    memcpy(trampoline, (void*)hookAddr, stolenBytes);
    trampoline[stolenBytes + 0] = 0xFF; trampoline[stolenBytes + 1] = 0x25;
    trampoline[stolenBytes + 2] = 0x00; trampoline[stolenBytes + 3] = 0x00;
    trampoline[stolenBytes + 4] = 0x00; trampoline[stolenBytes + 5] = 0x00;
    *(uintptr_t*)(trampoline + stolenBytes + 6) = hookAddr + stolenBytes;
    oText3D = (Text3DFunc)trampoline;

    DWORD old;
    VirtualProtect((void*)hookAddr, stolenBytes, PAGE_EXECUTE_READWRITE, &old);
    BYTE* dst = (BYTE*)hookAddr;
    dst[0] = 0xFF; dst[1] = 0x25;
    dst[2] = dst[3] = dst[4] = dst[5] = 0x00;
    *(uintptr_t*)(dst + 6) = (uintptr_t)hkText3D;
    dst[14] = dst[15] = dst[16] = dst[17] = 0x90;
    VirtualProtect((void*)hookAddr, stolenBytes, old, &old);
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        hThisDll = hModule;
        DisableThreadLibraryCalls(hModule);
        LoadConfig();
        settings.lastUpdate = GetTickCount();
        InstallHook();
    }
    else if (reason == DLL_PROCESS_DETACH) {
        if (hookAddr && trampoline) {
            DWORD old;
            VirtualProtect((void*)hookAddr, 18, PAGE_EXECUTE_READWRITE, &old);
            memcpy((void*)hookAddr, trampoline, 18);
            VirtualProtect((void*)hookAddr, 18, old, &old);
        }
        if (trampoline) VirtualFree(trampoline, 0, MEM_RELEASE);
    }
    return TRUE;
}