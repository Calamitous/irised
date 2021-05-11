import std.algorithm.iteration;
import std.array;
import std.conv;
import std.file;
import std.json;
import std.stdio;

import message;

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

  static Message[] load_file(DirEntry filename) {
    string unparsed_json = readText(filename);
    JSONValue parsed_json = parseJSON(unparsed_json);

    Message[] messages;
    foreach(message_json; parsed_json.array) {
      Message message = new Message(message_json);
      // writefln("%d", message);
      messages ~= message;
    }

    return messages;
  }

  this(string home_root) {
    Message[] all_user_messages;

    foreach(file; find_message_files(home_root)) {
      all_user_messages ~= load_file(file);
    }
  }
}


