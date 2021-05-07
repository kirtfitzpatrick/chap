# chap

Utility methods for writing scripts for humans. 

- Display messages and commands to the user color coded to various levels of 
  importance to the user.
- Auto echo the command to be executed for quick manual debugging when needed.
- Confirm command with skip, auto-confirm, and execution time features
- Evaluate commands with truncated output so you can get a brief idea of what 
  a command is doing without having to dump a wall of text.
- Automatically checks for links and displays their target along side them
- Readable functions to force iteration over lines
- A basic header


# Requirements
- bash 4 or greater

# Install

Available as a [bpkg](http://www.bpkg.sh/)
```sh
bpkg install [-g] kirtfitzpatrick/chap
```

# Usage
```
Usage:
  chap [-hV]
Options:
  -h|--help      Print this help dialogue and exit
  -V|--version   Print the current version and exit

Logging:
  info_msg           MESSAGE
  nominal_msg        MESSAGE
  attention_msg      MESSAGE
  warning_msg        MESSAGE
  modification_msg   MESSAGE

Evaluate command:
  info_cmd           COMMAND [ MESSAGE ]
  nominal_cmd        COMMAND [ MESSAGE ]
  attention_cmd      COMMAND [ MESSAGE ]
  warning_cmd        COMMAND [ MESSAGE ]
  modification_cmd   COMMAND [ MESSAGE ]

Internal:
  echo_cmd           COMMAND
  display_link       FILE_LINK_OR_DIR_PATH
  brief_echo         OUTPUT_BUFFER
  brief_eval         COMMAND

Iterate by line:
  begin_line_looping # PREV_IFS=$(chap begin_line_looping)
  end_line_looping   # chap end_line_looping "${PREV_IFS}"

Special purpose:
  print_header       "$0 $*"
  verify_line_count  LABEL COMPARISON_OP VALUE COMMAND
  confirm_cmd        COMMAND [MESSAGE]
  confirm_reset      # Reset auto-confirm to force confirmation again
```

# Demo

The actual output is much more colorful. You'll have to trust me.
```
$ chap info_msg "Hello, world."
Info: Hello, world. 


$ chap info_cmd 'find deps' "All the files installed with chap."
Info: All the files installed with chap. 
find deps
deps
deps/bin
deps/bin/chap -> ../chap/chap.sh
deps/chap
deps/chap/chap.sh
deps/chap/package.json


$ chap verify_line_count "scripts" "-eq" 1 "find deps -name '*.sh'"
Nominal: 1 scripts found. 
find deps -name '*.sh'
deps/chap/chap.sh


$ chap confirm_cmd "chap attention_cmd 'find .' 'This is all the things.'" "Confirm all the things."
Info: Confirm all the things. 
chap attention_cmd 'find .' 'This is all the things.'
Execute (a=all, s=skip): 
Initiated at: 14:00:39
Attention: This is all the things. 
find .
.
./.DS_Store
./demo.sh
./one-more.empty
./deps
./deps/.DS_Store
./deps/bin
./deps/bin/chap -> ../chap/chap.sh
./deps/chap
./deps/chap/chap.sh
 ... [ 1 more lines ]
Completed at: 14:00:39
```