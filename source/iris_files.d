import std.conv;
import std.file;
import std.format;

import config;

class IrisFiles {
  static string[] check_file_permissions(Config config) {
    string[] errors = [];

    if (!check_file_permissions(config.message_file_name, std.conv.octal!644)) {
      errors ~= permissions_error(
          config.message_file_name,
          "message",
          "-rw-r--r--",
          "644",
          "Leaving your file with incorrect permissions could allow unauthorized edits!"
          );
    }
    if (!check_file_permissions(config.history_file_name, std.conv.octal!644)) {
      errors ~= permissions_error(
          config.history_file_name,
          "history",
          "-rw-r--r--",
          "644",
          "Leaving your file with incorrect permissions could allow corruption of your history file."
          );
    }
    if (!check_file_permissions(config.executable_file_name, std.conv.octal!755)) {
        errors ~= permissions_error(
            config.executable_file_name,
            "Iris",
            "-rwxr-xr-x",
            "755",
            "If this file has the wrong permissions the program may be tampered with!"
            );

    }

    return errors;
  }

  static bool check_file_permissions(string filename, uint expected_permission) {
    auto stat_attrs = getAttributes(filename);

    // Bitmask attributes to pull only permissions
    auto permissions = stat_attrs & std.conv.octal!777;

    return permissions == expected_permission;
  }

  static string permissions_error(string filename, string file_description, string permission_string, string mode_string, string consequences) {
    auto message = "Your %s file has incorrect permissions!  Should be \"%s\".\nYou can change this from the command line with:\n  chmod %s %s\n%s";
    return message.format(file_description, permission_string, mode_string, filename, consequences);
  }
}
