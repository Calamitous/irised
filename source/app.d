import std.algorithm.iteration;
import std.array;
import std.digest.crc;
import std.file;
import std.format;
import std.json;
import std.path;
import std.process;
import std.regex;
import std.stdio;

import clid;

private struct CLIArgs {
  @Parameter("message-file")
  @Description("The file to read for the user's messages")
  string message_file;
}

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

class Message {
  string message;
  string author;
  string timestamp;

  string parent_hash;
  string edit_hash;

  bool is_deleted = false;

  string hash;
  string[] errors = [];

  void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
  {
    switch(fmt.spec)
    {
      case 'd':
        if (this.isValid()) {
          sink("\033[0;32mOK\033[0m - ");
        } else {
          sink("\033[0;91mERROR\033[0m - ");
        }
        sink("Message \"");
        sink(hash);
        sink("\"");
        if (is_deleted) {
          sink("\033[1;91m");
          sink(" (deleted)");
          sink("\033[0m");
        } else {
          sink(" (not deleted)");
        }
        sink(": [\n");

        sink("    \"message\": \"");
        sink(message);

        sink("\",\n    \"author\": \"");
        sink(author);

        sink("\",\n    \"parent_hash\": \"");
        sink(parent_hash);

        sink("\",\n    \"edit_hash\": \"");
        sink(edit_hash);

        sink("\",\n    \"timestamp\": \"");
        sink(timestamp);

        sink("\",\n    \"is_deleted\": \"");
        sink(format!"%s"(is_deleted));

        sink("\"\n]");

        if (errors.length > 0) {
          sink("\033[1;91m");
          sink("\nERRORS:\n");
          foreach(string error; errors) {
            sink("    ");
            sink(error);
            sink("\n");
          }
          sink("\033[0m");
        }
        break;
      default:
        sink("Not yet implemented");
        break;
    }
  }

  bool isValid() const {
    return errors == [];
  }

  void assign_required(string[string] hash, ref string prop, string key) {
    if ((key in hash) is null) {
      prop = "";
      auto error = key ~ " must be provided";
      errors ~= error;
    } else {
      prop = hash[key];
    }
  }

  void assign_optional(string[string] hash, ref string prop, string key) {
    if ((key in hash) is null) {
      prop = "";
    } else {
      prop = hash[key];
    }
  }

  this(JSONValue json) {}

  this(string[string] values) {
    errors = [];

    assign_required(values, message, "message");
    assign_required(values, author, "author");
    assign_required(values, timestamp, "timestamp");

    assign_optional(values, parent_hash, "parent_hash");
    assign_optional(values, edit_hash, "edit_hash");

    if (("is_deleted" in values) !is null) {
      switch(values["is_deleted"]) {
        case "false":
          is_deleted = false;
          break;
        case "true":
          is_deleted = true;
          break;
        default:
          is_deleted = false;
          errors ~= "`is_deleted` must be one of: `true`, `false`";
          break;
      }
    }

    auto message_mash = [message, author, parent_hash, edit_hash, timestamp].joiner.array;
    hash = format!"%s"(hexDigest!CRC32(message_mash));

    if (hash == parent_hash) {
      errors ~= "`hash` cannot be the same as `parent_hash`";
    }
  }
}

class Corpus {
  Message[] messages;

  static DirEntry[] find_message_files(string home_root) {
    DirIterator home_dirs = dirEntries(home_root, SpanMode.shallow);

    auto files = home_dirs
      .filter!(entry => entry.isDir)
      .map!(entry => dirEntries(entry, ".iris.messages", SpanMode.shallow))
      .joiner
      .array;

    return files;
  }
}

void main()
{
  auto cli_args = parseArguments!CLIArgs();
  Config config;

  if (cli_args.message_file.length > 0) {
    config = new Config(cli_args.message_file);
  } else {
    config = new Config();
  }

  // writeln(config.message_file_name);

  // Message[] messages = load_messages(config);

  File message_file = load_message_file(config);
  Corpus.find_message_files(config.home_root);

  auto message_details = [
    "message": "foo",
    "author": "bar",
    "timestamp": "asdfzxcv",
    "parent_hash": "46A10927",
    // "is_deleted": "bad"
  ];
  Message message = new Message(message_details);
  writefln("%d", message);
  // TODO: Fix this
  message.errors = [];
  writefln("%d", message);

  writeln("!--- RAN OKAY ---!");
}

JSONValue starter_data() {
  JSONValue jj = ["messages" : "none"];
  return jj;
}

File load_message_file(Config config) {
  if (!config.message_file_name.exists) {
    File message_file = File(config.message_file_name, "a");
    message_file.writeln("[]");
    message_file.close();
  }

  return File(config.message_file_name, "a");
}
