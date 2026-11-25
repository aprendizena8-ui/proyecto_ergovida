//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <camera_desktop/camera_desktop_plugin.h>
#include <desktop_tray/desktop_tray_plugin.h>
#include <file_selector_linux/file_selector_plugin.h>
#include <local_notifier/local_notifier_plugin.h>
#include <pose_detection/pose_detection_plugin.h>
#include <screen_retriever_linux/screen_retriever_linux_plugin.h>
#include <window_manager/window_manager_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) camera_desktop_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "CameraDesktopPlugin");
  camera_desktop_plugin_register_with_registrar(camera_desktop_registrar);
  g_autoptr(FlPluginRegistrar) desktop_tray_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopTrayPlugin");
  desktop_tray_plugin_register_with_registrar(desktop_tray_registrar);
  g_autoptr(FlPluginRegistrar) file_selector_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FileSelectorPlugin");
  file_selector_plugin_register_with_registrar(file_selector_linux_registrar);
  g_autoptr(FlPluginRegistrar) local_notifier_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LocalNotifierPlugin");
  local_notifier_plugin_register_with_registrar(local_notifier_registrar);
  g_autoptr(FlPluginRegistrar) pose_detection_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PoseDetectionPlugin");
  pose_detection_plugin_register_with_registrar(pose_detection_registrar);
  g_autoptr(FlPluginRegistrar) screen_retriever_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ScreenRetrieverLinuxPlugin");
  screen_retriever_linux_plugin_register_with_registrar(screen_retriever_linux_registrar);
  g_autoptr(FlPluginRegistrar) window_manager_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowManagerPlugin");
  window_manager_plugin_register_with_registrar(window_manager_registrar);
}
