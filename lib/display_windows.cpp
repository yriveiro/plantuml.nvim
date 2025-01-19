#ifdef _WIN32
#include <windows.h>

#define EXPORT __declspec(dllexport)

extern "C" {

EXPORT int get_display_count() { return GetSystemMetrics(SM_CMONITORS); }

EXPORT void get_display_resolution(int displayIndex, int *width, int *height) {
  DISPLAY_DEVICE dd = {sizeof(dd)};
  if (EnumDisplayDevices(nullptr, displayIndex, &dd, 0)) {
    DEVMODE dm = {sizeof(dm)};
    if (EnumDisplaySettings(dd.DeviceName, ENUM_CURRENT_SETTINGS, &dm)) {
      *width = dm.dmPelsWidth;
      *height = dm.dmPelsHeight;
      return;
    }
  }
  *width = -1;
  *height = -1;
}

EXPORT int get_terminal_display() {
  POINT pt;
  GetCursorPos(&pt);
  HMONITOR monitor = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(mi)};
  if (GetMonitorInfo(monitor, &mi)) {
    DISPLAY_DEVICE dd = {sizeof(dd)};
    for (int i = 0; EnumDisplayDevices(nullptr, i, &dd, 0); i++) {
      if (dd.StateFlags & DISPLAY_DEVICE_ACTIVE) {
        DEVMODE dm = {sizeof(dm)};
        if (EnumDisplaySettings(dd.DeviceName, ENUM_CURRENT_SETTINGS, &dm)) {
          if (pt.x >= mi.rcMonitor.left && pt.x < mi.rcMonitor.right &&
              pt.y >= mi.rcMonitor.top && pt.y < mi.rcMonitor.bottom) {
            return i;
          }
        }
      }
    }
  }
  return -1;
}

} // extern "C"
#endif
