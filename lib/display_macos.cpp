
#ifdef __APPLE__
#include <CoreGraphics/CoreGraphics.h>

#define EXPORT __attribute__((visibility("default")))

extern "C" {

/**
 * @brief Retrieves the number of active displays on macOS.
 *
 * This function uses the `CGGetActiveDisplayList` call to count
 * all currently active (online) displays in the system.
 *
 * @return The total number of active displays on success, or 0 if no displays
 * are found.
 */
EXPORT int get_display_count() {
  uint32_t displayCount = 0;
  // Request the number of active displays, ignoring the actual display list.
  CGGetActiveDisplayList(0, nullptr, &displayCount);
  return static_cast<int>(displayCount);
}

/**
 * @brief Obtains the width and height of a specific display.
 *
 * Given a display index, this function retrieves the corresponding
 * `CGDirectDisplayID` and extracts its width and height (in points).
 * If the index is out of bounds, it sets both width and height to -1.
 *
 * @param[in]  displayIndex  The index of the target display (0-based).
 * @param[out] width         Pointer to an integer that receives the display
 * width.
 * @param[out] height        Pointer to an integer that receives the display
 * height.
 *
 * @note macOS uses a coordinate space in points; some scaling modes may affect
 * the reported values.
 */
EXPORT void get_display_resolution(int displayIndex, int *width, int *height) {
  uint32_t displayCount = 0;
  CGDirectDisplayID displays[32];

  // Fetch up to 32 active displays (an arbitrary limit).
  CGGetActiveDisplayList(32, displays, &displayCount);

  // Verify the displayIndex is valid; otherwise return -1 for width/height.
  if (static_cast<uint32_t>(displayIndex) < displayCount) {
    CGSize size = CGDisplayBounds(displays[displayIndex]).size;
    *width = static_cast<int>(size.width);
    *height = static_cast<int>(size.height);
  } else {
    *width = -1;
    *height = -1;
  }
}

/**
 * @brief Determines the display index on which the mouse cursor currently
 * resides.
 *
 * This function captures the current cursor location via a CGEvent,
 * iterates through all active displays, and checks which display's
 * bounding rectangle contains the cursor. Returns that display's index.
 *
 * @return The 0-based index of the display containing the cursor, or -1 if not
 * found.
 *
 * @note If there are overlapping displays, the first matching display in the
 * list is returned.
 */
EXPORT int get_terminal_display() {
  // Get the current cursor position in global screen coordinates.
  CGPoint cursorPos = CGEventGetLocation(CGEventCreate(nullptr));

  uint32_t displayCount = 0;
  CGDirectDisplayID displays[32];
  CGGetActiveDisplayList(32, displays, &displayCount);

  // Check each display's bounding rectangle to see if the cursor lies within
  // it.
  for (uint32_t i = 0; i < displayCount; i++) {
    CGRect bounds = CGDisplayBounds(displays[i]);
    if (cursorPos.x >= bounds.origin.x &&
        cursorPos.x < bounds.origin.x + bounds.size.width &&
        cursorPos.y >= bounds.origin.y &&
        cursorPos.y < bounds.origin.y + bounds.size.height) {
      return static_cast<int>(i);
    }
  }

  // Return -1 if no display was found containing the cursor.
  return -1;
}

} // extern "C"
#endif
