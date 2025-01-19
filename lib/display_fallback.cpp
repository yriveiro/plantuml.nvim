#if !defined(_WIN32) && !defined(__APPLE__) && !defined(__linux__)

#define EXPORT

extern "C" {

EXPORT int get_display_count() { return -1; }

EXPORT void get_display_resolution(int displayIndex, int *width, int *height) {
  *width = -1;
  *height = -1;
}

EXPORT int get_terminal_display() { return -1; }

} // extern "C"
#endif
