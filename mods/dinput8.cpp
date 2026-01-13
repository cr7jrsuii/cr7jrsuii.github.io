#include <windows.h>
#include <stdio.h>
#include <time.h>

HMODULE hOriginal = nullptr;

typedef HRESULT(WINAPI* DI8Create)(HINSTANCE, DWORD, REFIID, LPVOID*, LPUNKNOWN);
DI8Create pDI8Create = nullptr;

extern "C" __declspec(dllexport) HRESULT WINAPI DirectInput8Create(
    HINSTANCE hinst, DWORD ver, REFIID riid, LPVOID* out, LPUNKNOWN unk)
{
    if (!pDI8Create) return E_FAIL;
    return pDI8Create(hinst, ver, riid, out, unk);
}

void LoadInjected()
{
    wchar_t basePath[MAX_PATH];
    if (!GetModuleFileNameW(nullptr, basePath, MAX_PATH)) return;

    wchar_t* last = wcsrchr(basePath, L'\\');
    if (!last) return;
    last[1] = 0;

    wchar_t injectedPath[MAX_PATH] = { 0 };
    wcscpy_s(injectedPath, basePath);
    wcscat_s(injectedPath, L"injected");

    DWORD attr = GetFileAttributesW(injectedPath);
    if (attr == INVALID_FILE_ATTRIBUTES || !(attr & FILE_ATTRIBUTE_DIRECTORY)) {
        MessageBoxW(nullptr, L"No injected folder found", L"Proxy", MB_OK | MB_ICONWARNING);
        return;
    }

    wchar_t logPath[MAX_PATH] = { 0 };
    wcscpy_s(logPath, basePath);
    wcscat_s(logPath, L"proxylog.txt");

    FILE* log = nullptr;
    _wfopen_s(&log, logPath, L"a");

    if (log) {
        time_t now = time(nullptr);
        char timeStr[64];
        struct tm timeInfo;
        localtime_s(&timeInfo, &now);
        strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", &timeInfo);
        fprintf(log, "%s\n", timeStr);
    }

    wchar_t searchPath[MAX_PATH] = { 0 };
    wcscpy_s(searchPath, injectedPath);
    wcscat_s(searchPath, L"\\*.dll");

    WIN32_FIND_DATAW fd;
    HANDLE h = FindFirstFileW(searchPath, &fd);

    int loaded = 0;
    int failed = 0;

    if (h == INVALID_HANDLE_VALUE) {
        if (log) {
            fprintf(log, "0 loaded, 0 failed\n");
            fclose(log);
        }
        return;
    }

    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;

        wchar_t fullPath[MAX_PATH] = { 0 };
        wcscpy_s(fullPath, injectedPath);
        wcscat_s(fullPath, L"\\");
        wcscat_s(fullPath, fd.cFileName);

        HMODULE hMod = LoadLibraryW(fullPath);

        if (hMod) loaded++;
        else failed++;

        if (log) {
            if (hMod)
                fwprintf(log, L"[OK] %s\n", fd.cFileName);
            else
                fwprintf(log, L"[FAIL] %s\n", fd.cFileName);
        }
    } while (FindNextFileW(h, &fd));

    if (log) {
        fprintf(log, "%d loaded, %d failed\n", loaded, failed);
        fclose(log);
    }

    FindClose(h);
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID reserved)
{
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hModule);

        wchar_t sys[MAX_PATH];
        if (!GetSystemDirectoryW(sys, MAX_PATH)) return FALSE;
        wcscat_s(sys, L"\\dinput8.dll");

        hOriginal = LoadLibraryW(sys);
        if (!hOriginal) return FALSE;

        pDI8Create = (DI8Create)GetProcAddress(hOriginal, "DirectInput8Create");
        if (!pDI8Create) return FALSE;

        LoadInjected();
    }
    return TRUE;
}
