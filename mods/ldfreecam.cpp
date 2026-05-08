#include <orbis/libkernel.h>
#include <orbis/Pad.h>
#include <pthread.h>
#include <sys/mman.h>
#include <math.h>

static uint64_t g_base = 0;
static volatile bool frozen = false;
static float cam_x, cam_y, cam_z, pitch, yaw;
static float speed = 0.018f, sens = 0.01f;

typedef char(*tCamCopy)(int64_t, int64_t);
static tCamCopy oCamCopy = nullptr;
static uint8_t __attribute__((aligned(64))) trampoline[64];

char __attribute__((sysv_abi)) hkCamCopy(int64_t src, int64_t dst) {
    char ret = oCamCopy(src, dst);
    float* mat = (float*)(dst + 0x10);
    if (!frozen) {
        cam_x = mat[12]; cam_y = mat[13]; cam_z = mat[14];
        yaw = atan2f(mat[8], mat[10]); pitch = -asinf(mat[9]);
        return ret;
    }
    float cp = cosf(pitch), sp = sinf(pitch), cy = cosf(yaw), sy = sinf(yaw);
    mat[0]=cy;    mat[1]=0.f;  mat[2]=-sy;    mat[3]=0.f;
    mat[4]=sy*sp; mat[5]=cp;   mat[6]=cy*sp;  mat[7]=0.f;
    mat[8]=sy*cp; mat[9]=-sp;  mat[10]=cy*cp; mat[11]=0.f;
    mat[12]=cam_x; mat[13]=cam_y; mat[14]=cam_z; mat[15]=1.f;
    return ret;
}

static void write_jmp(uint8_t* dst, void* target) {
    dst[0]=0xFF; dst[1]=0x25;
    dst[2]=dst[3]=dst[4]=dst[5]=0x00;
    __builtin_memcpy(dst+6, &target, 8);
}

static uint8_t* aob_scan(uint8_t* base, size_t range, const uint8_t* pat, size_t len) {
    for (size_t i = 0; i + len <= range; i++)
        if (__builtin_memcmp(base+i, pat, len) == 0) return base+i;
    return nullptr;
}

static void hook_install(void* target) {
    uint8_t* fn = (uint8_t*)target;
    const int pagesz = 0x4000;
    uint8_t* page = (uint8_t*)((uintptr_t)fn & ~(uintptr_t)(pagesz-1));
    mprotect(page, pagesz, PROT_READ|PROT_WRITE|PROT_EXEC);
    __builtin_memcpy(trampoline, fn, 16);
    write_jmp(trampoline+16, fn+16);
    mprotect((uint8_t*)((uintptr_t)trampoline & ~(uintptr_t)(pagesz-1)), pagesz, PROT_READ|PROT_WRITE|PROT_EXEC);
    oCamCopy = (tCamCopy)trampoline;
    write_jmp(fn, (void*)hkCamCopy);
    mprotect(page, pagesz, PROT_READ|PROT_EXEC);
}

static inline float dz(float v) { return (v > -0.15f && v < 0.15f) ? 0.f : v; }

static void* pad_thread(void*) {
    int handle = -1;
    while (handle < 0) handle = scePadGetHandle(0, 0, 0);

    static const uint8_t sig[] = {
        0xC5,0xF8,0x10,0x87,0x50,0x03,0x00,0x00,
        0xC5,0xF8,0x11,0x86,0x50,0x03,0x00,0x00
    };
    uint8_t* fn = aob_scan((uint8_t*)g_base, 0x800000, sig, sizeof(sig));
    if (!fn) { sceKernelDebugOutText(0, "Signature not found\n"); return nullptr; }
    hook_install(fn);
    sceKernelDebugOutText(0, "Freecam Ready\n");

    bool combo_held = false;
    while (true) {
        OrbisPadData data{};
        scePadReadState(handle, &data);
        uint32_t btn = data.buttons;

        bool l3r3 = (btn & 0x0002) && (btn & 0x0004);
        if (l3r3 && !combo_held) {
            frozen = !frozen;
            sceKernelDebugOutText(0, frozen ? "Freecam: On\n" : "Freecam: Off\n");
            combo_held = true;
        }
        if (!l3r3) combo_held = false;

        if (frozen) {
            if (btn & 0x0010) speed += 0.001f;
            if (btn & 0x0040) { speed -= 0.001f; if (speed < 0.001f) speed = 0.001f; }
            if (btn & 0x0020) sens += 0.0001f;
            if (btn & 0x0080) { sens -= 0.0001f; if (sens < 0.0001f) sens = 0.0001f; }

            float lx = dz((data.leftStick.x  - 128.f) / 128.f);
            float ly = dz((data.leftStick.y  - 128.f) / 128.f);
            float rx = dz((data.rightStick.x - 128.f) / 128.f);
            float ry = dz((data.rightStick.y - 128.f) / 128.f);

            yaw += rx * sens; pitch += ry * sens;
            if (pitch >  1.5f) pitch =  1.5f;
            if (pitch < -1.5f) pitch = -1.5f;

            float up   = (data.analogButtons.r2 > 10) ? data.analogButtons.r2 / 255.f : 0.f;
            float down = (data.analogButtons.l2 > 10) ? data.analogButtons.l2 / 255.f : 0.f;

            cam_x += (sinf(yaw) * (-ly) + sinf(yaw + 1.5707963f) * lx) * speed;
            cam_y += (-sinf(pitch) * (-ly) + (up - down)) * speed;
            cam_z += (cosf(yaw) * (-ly) + cosf(yaw + 1.5707963f) * lx) * speed;
        }

        sceKernelUsleep(16000);
    }
    return nullptr;
}

extern "C" int32_t __wrap__init(size_t, void*) {
    OrbisKernelModuleInfo info{};
    info.size = sizeof(info);
    sceKernelGetModuleInfo(0, &info);
    g_base = (uint64_t)info.segmentInfo[0].address;
    pthread_t thread;
    pthread_create(&thread, nullptr, pad_thread, nullptr);
    return 0;
}