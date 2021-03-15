import std.algorithm.iteration;
import std.array;
import std.file;

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
}


