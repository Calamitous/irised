import std.file;
import std.format;
import std.stdio;

import clid;

import config;
import corpus;
import message;

private struct CLIArgs {
  @Parameter("message-file")
  @Description("The file to read for the user's messages")
  string message_file;
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

  File message_file = load_message_file(config);
  // Corpus.find_message_files(config.home_root);
  Corpus corpus = new Corpus(config.home_root);
  // writeln(corpus.messages);

  auto message_details = [
    "message": "foo",
    "author": "bar",
    "timestamp": "asdfzxcv",
    "parent_hash": "46A10927",
    "is_deleted": "bad"
  ];

  Message message = new Message(message_details);
  // writefln("%d", message);
  // TODO: Fix this, even though it's handy for testing
  message.errors = [];
  // writefln("%d", message);

  writeln("!--- RAN OKAY ---!");
}

// TODO: Classify this
File load_message_file(Config config) {
  if (!config.message_file_name.exists) {
    File message_file = File(config.message_file_name, "a");
    message_file.writeln("[]");
    message_file.close();
  }

  return File(config.message_file_name, "a");
}
