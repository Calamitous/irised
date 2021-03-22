import std.algorithm.iteration;
import std.array;
import std.digest.crc;
import std.format;
import std.json;
import std.stdio;

JSONValue starter_data() {
  JSONValue jj = ["messages" : "none"];
  return jj;
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

  void assign_required(JSONValue hash, ref string prop, string key) {
    if (!(key in hash) || hash[key].isNull) {
      prop = "";
      auto error = key ~ " must be provided";
      errors ~= error;
    } else {
      prop = hash[key].str;
    }
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

  void assign_optional(JSONValue hash, ref string prop, string key) {
    if (!(key in hash) || hash[key].isNull) {
      prop = "";
    } else {
      prop = hash[key].str;
    }
  }

  this(JSONValue message_json) {
    writeln("BEEP!");
    assign_required(message_json["data"], message, "message");
    assign_required(message_json["data"], author, "author");
    assign_required(message_json["data"], timestamp, "timestamp");

    assign_optional(message_json["data"], parent_hash, "parent");
    assign_optional(message_json, edit_hash, "edit_hash");

    // if (("is_deleted" in message_json) !is null && !message_json["is_deleted"].isNull) {
    //   switch(message_json["is_deleted"].str) {
    //     case "false":
    //       is_deleted = false;
    //       break;
    //     case "true":
    //       is_deleted = true;
    //       break;
    //     default:
    //       is_deleted = false;
    //       errors ~= "`is_deleted` must be one of: `true`, `false`";
    //       break;
    //   }
    // }

  }

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

