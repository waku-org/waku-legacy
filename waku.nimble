mode = ScriptMode.Verbose

### Package
version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "Waku, Private P2P Messaging for Resource-Restricted Devices"
license       = "MIT or Apache License 2.0"
#bin           = @["build/waku"]

### Dependencies
requires "nim >= 1.6.0",
  "chronicles",
  "confutils",
  "chronos",
  "eth",
  "json_rpc",
  "libbacktrace",
  "nimcrypto",
  "stew",
  "stint",
  "metrics",
  "web3",
  "presto",
  "regex"

### Helper functions
proc buildBinary(name: string, srcDir = "./", params = "", lang = "c") =
  if not dirExists "build":
    mkDir "build"
  # allow something like "nim nimbus --verbosity:0 --hints:off nimbus.nims"
  var extra_params = params
  for i in 2..<paramCount():
    extra_params &= " " & paramStr(i)
  exec "nim " & lang & " --out:build/" & name & " " & extra_params & " " & srcDir & name & ".nim"

proc buildLibrary(name: string, srcDir = "./", params = "", `type` = "static") =
  if not dirExists "build":
    mkDir "build"
  # allow something like "nim nimbus --verbosity:0 --hints:off nimbus.nims"
  var extra_params = params
  for i in 2..<paramCount():
    extra_params &= " " & paramStr(i)
  if `type` == "static":
    exec "nim c" & " --out:build/" & name & ".a  --app:staticlib --opt:size --noMain --header " & extra_params & " " & srcDir & name & ".nim"
  else:
    exec "nim c" & " --out:build/" & name & ".so  --app:lib --opt:size --noMain --header " & extra_params & " " & srcDir & name & ".nim"

proc test(name: string, params = "-d:chronicles_log_level=DEBUG", lang = "c") =
  # XXX: When running `> NIM_PARAMS="-d:chronicles_log_level=INFO" make test2`
  # I expect compiler flag to be overridden, however it stays with whatever is
  # specified here.
  buildBinary name, "tests/", params
  exec "build/" & name

### Legacy: Whisper & Waku v1 tasks
task testwhisper, "Build & run Whisper tests":
  test "all_tests_whisper", "-d:chronicles_log_level=WARN -d:chronosStrictException"

task wakunode1, "Build Waku v1 cli node":
  buildBinary "wakunode1", "waku/node/",
    "-d:chronicles_log_level=DEBUG -d:chronosStrictException"

task sim1, "Build Waku v1 simulation tools":
  buildBinary "quicksim", "waku/node/",
    "-d:chronicles_log_level=INFO -d:chronosStrictException"
  buildBinary "start_network", "waku/node/",
    "-d:chronicles_log_level=DEBUG -d:chronosStrictException"

task example1, "Build Waku v1 example":
  buildBinary "example", "examples/",
    "-d:chronicles_log_level=DEBUG -d:chronosStrictException"

task test1, "Build & run Waku v1 tests":
  test "all_tests_waku", "-d:chronicles_log_level=WARN -d:chronosStrictException"
