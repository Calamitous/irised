import std.path;
import std.process;
import std.regex;

class Config {
  immutable irised_version = "0.1";
  string home_root;
  string history_file_name;
  string message_file_name;
  string user;

  this() {
    user = fetch_user();
    message_file_name = expandTilde("~/.iris.messages");
    history_file_name = expandTilde("~/.iris.history");
    home_root = fetch_home_root();
  }

  this(string file_name) {
    message_file_name = file_name;
    user = fetch_user();
    message_file_name = expandTilde(file_name);
    history_file_name = expandTilde(file_name);
    home_root = fetch_home_root();
  }

  string fetch_user() {
    return environment.get("USER", environment.get("LOGNAME", environment.get("USERNAME", "")));
  }

  string fetch_home_root() {
    string env_var_home = environment.get("HOME", "/home/");
    return matchFirst(env_var_home, regex(r"(.*)(\/)"))[1];
  }
}

