#ifdef __linux__
#include <X11/Xlib.h>

#define EXPORT __attribute__((visibility("default")))

extern "C" {

EXPORT int get_display_count() {
  Display *display = XOpenDisplay(nullptr);
  if (!display)
    return -1;
  int screenCount = ScreenCount(display);
  XCloseDisplay(display);
  return screenCount;
}

EXPORT void get_display_resolution(int displayIndex, int *width, int *height) {
  Display *display = XOpenDisplay(nullptr);
  if (!display) {
    *width = -1;
    *height = -1;
    return;
  }
  if (displayIndex < ScreenCount(display)) {
    Screen *screen = ScreenOfDisplay(display, displayIndex);
    *width = screen->width;
    *height = screen->height;
  } else {
    *width = -1;
    *height = -1;
  }
  XCloseDisplay(display);
}

EXPORT int get_terminal_display() {
  Display *display = XOpenDisplay(nullptr);
  if (!display)
    return -1;

  Window root = DefaultRootWindow(display);
  int rootX, rootY;
  unsigned int mask;
  Window child, rootReturn;
  XQueryPointer(display, root, &rootReturn, &child, &rootX, &rootY, &rootX,
                &rootY, &mask);

  for (int i = 0; i < ScreenCount(display); i++) {
    Screen *screen = ScreenOfDisplay(display, i);
    // Check if cursor is within this screen's geometry.
    // Use screen->width/height carefully. For multi-screen setups,
    // you often need extended geometry, but this is the basic approach:
    if (rootX >= 0 && rootX < screen->width && rootY >= 0 &&
        rootY < screen->height) {
      XCloseDisplay(display);
      return i;
    }
  }

  XCloseDisplay(display);
  return -1;
}

} // extern "C"
#endif
