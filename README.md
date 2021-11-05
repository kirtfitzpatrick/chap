# chap

Utility scripting methods for humans. 

- Display messages and commands to the user color coded to various levels of 
  importance.
- Auto echo the command to be executed for quick manual debugging when needed.
- Confirm command with skip, auto-confirm, and execution time features
- Evaluate commands with truncated output so you can get a brief idea of what 
  a command is doing without having to dump a wall of text.
- Automatically checks for links and displays their target along side them
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
  mod_msg            MESSAGE

Evaluation:
  info_cmd           COMMAND [ MESSAGE ]
  nominal_cmd        COMMAND [ MESSAGE ]
  attention_cmd      COMMAND [ MESSAGE ]
  warning_cmd        COMMAND [ MESSAGE ]
  mod_cmd            COMMAND [ MESSAGE ]

Internal:
  echo_cmd           COMMAND
  display_link       FILE_LINK_OR_DIR_PATH
  brief_echo         OUTPUT_BUFFER
  brief_eval         COMMAND

Special purpose:
  print_header       "$0 $*"
  verify_line_count  LABEL COMPARISON_OP VALUE COMMAND
  confirm_cmd        COMMAND [ MESSAGE ]
  confirm_reset      # Reset auto-confirm
  prompt_var         MESSAGE VAR_TO_SET DEFAULT
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


$ chap confirm_cmd "echo 'A command that requires caution.'" "Run this command that requires caution?"
Info: Run this command that requires caution? 
echo 'A command that requires caution.'
Execute (a=all, s=skip): 
Initiated at: 08:41:38
A command that requires caution.
Completed at: 08:41:38
```