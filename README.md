# py_canister

Utility shell-script for small python script project. 
Setup the python script template with sub-directory structure for module install locally. 
Same script works for python module install with pip locally. 
It also work as wrapper to call python script with the setting to use python modules installed locally.

## Requirement

- Bash
- Python
- Optional: GNU realpath (in GNU coreutils)
- grep
- sed
- awk

## Usage

This script has three modes of operation.

1. Setup/Initialize mode (`init-mode`)

When the script `py_canister.sh` is invoked with `--manage` as the **first** option and `init` as the sub-command, this script works as `init-mode`. 
The following is most simple example to prepare the directory structure under `/somewhere/pyworktool` and to make the python script template with the name, `pywork`, under the prepared directories. 

If `-r` option is given in `init-mode`, the template of `README.md` is also made. Title of `README.md` can be specified with `-t` option. 

If `-g` option is given in `init-mode`, the template for the `Git` related files such as `.gitignore` is also made.




```
% ./py_canister.sh --manage -p /somewhere/pyworktool -3 init pywork
% (cd /somewhere/ ; find pyworktool -ls )
 drwxr-xr-x   ...... pyworktool
 drwxr-xr-x   ...... pyworktool/bin
 -rwxr-xr-x   ...... pyworktool/bin/py_canister.sh
 lrwxr-xr-x   ...... pyworktool/bin/mng_pyenv -> py_canister.sh
 lrwxr-xr-x   ...... pyworktool/bin/mng_pyenv2 -> py_canister.sh
 lrwxr-xr-x   ...... pyworktool/bin/mng_pyenv3 -> py_canister.sh
 lrwxr-xr-x   ...... pyworktool/bin/pywork -> py_canister.sh
 lrwxr-xr-x   ...... pyworktool/bin/pywork3 -> py_canister.sh
 drwxr-xr-x   ...... pyworktool/lib
 drwxr-xr-x   ...... pyworktool/lib/python
 drwxr-xr-x   ...... pyworktool/lib/python/site-packages
 -rw-r--r--   ...... pyworktool/lib/python/pywork3.py
 lrwxr-xr-x   ...... pyworktool/lib/python/pywork.py -> pywork3.py
```

2. Management mode (`manage-mode`)

`mng_pyenv` and `mng_pyenv[23]` made by `py_canister.sh` with `init-mode` is symbolic link to `bin/py_canister.sh`. Invoking `mng_pyenv` is equivalent to invoke `py_canister.sh --manage`. (Invoking `mng_pyenv2` and `mng_pyenv3` are equivalent to invoke `py_canister.sh --manage -2` and `py_canister.sh --manage -3`, respectively.) In this mode, other sub-commands are also available. If it is invoked with sub-command `install` and python module name(s) in following arguments, the specified python modules are installed under the local directory structure.

```
% /somewhere/pyworktool/bin/mng_pyenv3 install pytz tzlocal
Collecting install
  Downloading install-1.3.5-py3-none-any.whl (3.2 kB)
Collecting pytz
  Using cached pytz-2022.7.1-py2.py3-none-any.whl (499 kB)
Collecting tzlocal
  Using cached tzlocal-4.2-py3-none-any.whl (19 kB)
.....
Installing collected packages: install, pytz, tzdata, backports.zoneinfo, pytz-deprecation-shim, tzlocal
Successfully installed backports.zoneinfo-0.2.1 install-1.3.5 pytz-2022.7.1 pytz-deprecation-shim-0.1.0.post0 tzdata-2022.7 tzlocal-4.2

% ls  /somewhere/pyworktool/lib/python/site-packages/3.8/
backports                           install                  pytz                     pytz_deprecation_shim                        tzdata                   tzlocal
backports.zoneinfo-0.2.1.dist-info  install-1.3.5.dist-info  pytz-2022.7.1.dist-info  pytz_deprecation_shim-0.1.0.post0.dist-info  tzdata-2022.7.dist-info  tzlocal-4.2.dist-info
```

3. Run mode (`run-mode`)

If the symbolic link to this script(`py_canister.sh`) with the name other than `mng_pyenv{,2,3}` is invoked, the python script, `lib/python/{symbolic_link_name}.py`, is invoked with setting environmental variable `PYTHONPATH` to use python modules installed locally. If `py_canister.sh` is invoked with first argument other than `--manage`, the python script, `lib/python/{first_arguments}.py` or `{first_arguments}` is invoked with setting `PYTHONPATH`.

```
% ~/tmp/pyworktool/bin/pywork3
Hello, World!
Python : 3.8.9 (/Applications/Xcode.app/Contents/Developer/usr/bin/python3)
....

% /somewhere/pyworktool/bin/py_canister.sh pywork3 Japan
Hello, Japan!
Python : 3.8.9 (/Applications/Xcode.app/Contents/Developer/usr/bin/python3)
....

% /somewhere/pyworktool/bin/py_canister.sh  /somewhere/pyworktool/lib/python/pywork3.py  Japan
Hello, Japan!
Python : 3.8.9 (/Applications/Xcode.app/Contents/Developer/usr/bin/python3)
....
```

## Other options / examples

1. Installing python modules in `init-mode`.

If the python module name is given with `-m` option in `init-mode`, the python module is installed. (Multiple `-m` options can be accepted.) Multiple names for python template are also accepted.

```
% ./py_canister.sh --manage -p /somewhere/pyworktool -g -r -t 'Worktool by Python' -3 -m pytz -m tzlocal init prepwork mainwork
Collecting pytz
  Using cached pytz-2022.7.1-py2.py3-none-any.whl (499 kB)
Collecting tzlocal
  Using cached tzlocal-4.2-py3-none-any.whl (19 kB)
......
Installing collected packages: pytz, tzdata, backports.zoneinfo, pytz-deprecation-shim, tzlocal
Successfully installed backports.zoneinfo-0.2.1 pytz-2022.7.1 pytz-deprecation-shim-0.1.0.post0 tzdata-2022.7 tzlocal-4.2

% ( cd /somewhere ; find pyworktool -ls ) 
...... pyworktool
...... pyworktool/README.md
...... pyworktool/.gitignore
...... pyworktool/bin
...... pyworktool/bin/py_canister.sh
...... pyworktool/bin/mng_pyenv -> py_canister.sh
...... pyworktool/bin/mng_pyenv2 -> py_canister.sh
...... pyworktool/bin/mng_pyenv3 -> py_canister.sh
...... pyworktool/bin/prepwork -> py_canister.sh
...... pyworktool/bin/prepwork3 -> py_canister.sh
...... pyworktool/bin/mainwork -> py_canister.sh
...... pyworktool/bin/mainwork3 -> py_canister.sh
...... pyworktool/lib
...... pyworktool/lib/python
...... pyworktool/lib/python/mainwork.py -> mainwork3.py
...... pyworktool/lib/python/mainwork3.py
...... pyworktool/lib/python/prepwork.py -> prepwork3.py
...... pyworktool/lib/python/prepwork3.py
...... pyworktool/lib/python/site-packages
...... pyworktool/lib/python/site-packages/.gitkeep
...... pyworktool/lib/python/site-packages/3.8
...... pyworktool/lib/python/site-packages/3.8/tzlocal-4.2.dist-info
......
% cat /somewhere/pyworktool/README.md 
#
# Worktool by Python
#

Skeleton for small portable tools by python script

- Contents:

  1.  README.md:                         This file
  2.  bin/mng_pyenv:                     Symblic link to 'py_canister.sh' for installing Python modules by pip locally.
  2a. bin/mng_pyenv2:                    Same as above using pip2 as default
  2b. bin/mng_pyenv3:                    Same as above using pip3 as default

  3.  bin/py_canister.sh:                      Wrapper bash script to invoke Python script. (Entity)

  4.  lib/python/site-packages:          Directory where python modules are stored

  5.  lib/python/prepwork.py:            Example Python script that use modules
  5a. lib/python/prepwork3.py:           Same as above using python3 as default

  6.  bin/prepwork:                      Symbolic link to 'py_canister.sh' to invoke prepwork.py.
  6a. bin/prepwork3:                     Same as above using python3 as default

  7.  lib/python/mainwork.py:            Example Python script that use modules
  7a. lib/python/mainwork3.py:           Same as above using python3 as default

  8.  bin/mainwork:                      Symbolic link to 'py_canister.sh' to invoke mainwork.py.
  8a. bin/mainwork3:                     Same as above using python3 as default

  9.  .gitignore:                        Git-related file
  10. lib/python/site-packages/.gitkeep: Git-related file to keep modules directory in repository.
....
```

2. Adding python script template in `manage-mode`.

`add` sub-command in `manage-mode` can be used to add the new python script template, the symbolic link to `bin/py_canister.sh` with corresponding name, and to update `README.md` when `-r` option is given.

```
% /somewhere/pyworktool/bin/mng_pyenv -r add postwork
% ( cd /somewhere ; find pyworktool -ls ) ...... 
...... pyworktool/bin/postwork3 -> py_canister.sh
...... pyworktool/bin/postwork -> py_canister.sh
...... 
...... pyworktool/lib/python/postwork3.py
...... pyworktool/lib/python/postwork.py -> postwork3.py
...... 
% cat /somewhere/pyworktool/README.md
......
  11.  lib/python/postwork.py:            Example Python script that use modules
  11a. lib/python/postwork3.py:           Same as above using python3 as default

  12.  bin/postwork:                      Symbolic link to 'py_canister.sh' to invoke postwork.py.
  12a. bin/postwork3:                     Same as above using python3 as default
......
```

## Application

### Changing the python template

`py_canister.sh` is making python templates is embedded in itself at the lines from  `########## __py_template_start__ ##########` to ``########## __py_template_end__ ##########` with replacing the keyword, `## __py_shebang_pattern__ ##`, by the relevant python location using `sed`.  (`python` location is looked for by the following order; 1. command line option: `-P`, 2. environmental variable: `PYTHON`, 3, python in `PATH`).  Therefore, you can change the python script template by editing this part of `py_canister.sh`. 

### Usage for python script distribution

Yet another usage is to take a python script created in one environment and use it in another environment, or to distribute the custom python script file for others to use. As mentioned above, this script changes its behavior depending on whether the file entity is invoked directly or invoked by the symbolic link, but the entity file name itself (`py_canister.sh`) is not used to determine the mode of operation, so it can be changed as you like.

The following is the example when the python script `tool.py`, which is often used in hostA, is brought to another environment hostB. (It is useful when you do not have the privileges to install python module in hostB system by `pip`.) It is possible to change the template of `README.md` and `.gitignore` in similar way. Note that the keyword substitution for these template is performed by `sed`.

```
UserA@HostA % cp -ai 'py_canister.sh' '/somewhere/tool-dist'
UserA@HostA % emacs /somewhere/tool-dist # Edit python template part with the contents of tool.py
UserA@HostA % scp /somewhere/tool-dist UserB@HostB:/tmp/tool-dist

UserB@HostB % /tmp/tool-dist --manage -p /destination/util -g -r -t 'Tool by UserA@HostA' -3 -m pytz -m tzlocal -m other-python-module init tool
UserB@HostB % /destination/util/bin/tool # Executable
```

### Mutilple python script template

The python script can be named, and multiple python templete can be contained. 

When the script name given as an argument of `init` sub-command or `add` sub-command is `{scriptname}`, and this script contains the line started with `########## __{scriptname}_template_start__ ##########` and the line started with `########## __{scriptname}_template_end__ ##########`, the interval between these two lines are used for the python script template. This functionality is useful to distribute multiple python scripts at once in one script file.

```
UserA@HostA % cp -ai 'py_canister.sh' '/somewhere/tool-dist'
UserA@HostA % emacs /somewhere/tool-dist # Add the following contents to the end of script.
UserA@HostA % cat /somewhere/tool-dist
....
########## __scriptA_template_start__ ##########
## __py_shebang_pattern__ ##
# -*- coding: utf-8 -*-

... (Contents of scriptA)

########## __scriptA_template_end__ ##########
########## __scriptB_template_start__ ##########
## __py_shebang_pattern__ ##
# -*- coding: utf-8 -*-

... (Contents of scriptB)

########## __scriptB_template_end__ ##########UserA@HostA % scp /somewhere/tool-dist UserB@HostB:/tmp/tool-dist

UserB@HostB % /tmp/tool-dist --manage -p /destination/util -g -r -t 'Tool by UserA@HostA' -3 -m pytz -m tzlocal init scriptA scriptB
UserB@HostB % /destination/util/bin/scriptA # Executable
UserB@HostB % /destination/util/bin/scriptB # Executable
```

## Command-line help

Command line help can be shown with `-h` option in `manage-mode`.

```
% ./py_canister.sh --manage -h
[Usage]        % mng_pyenv{,2,3}   [options] sub-command [arguments]
               % py_canister.sh --manage [options] sub-command [arguments]
[sub-commands] 
               % py_canister.sh --manage [options] init [scriptnames] ... setup directory tree,
                                                                        and prepare templates if arguments are given.
               % py_canister.sh --manage [options] add script_names   ... prepare python script templates.
               % py_canister.sh --manage install  module_names        ... Install python module with pip locally.
               % py_canister.sh --manage download module_names        ... Download python module with pip locally.
               % py_canister.sh --manage clean                        ... Delete local python module for corresponding python version.
               % py_canister.sh --manage distclean/cleanall/allclean  ... Delete local python module for all python version.
               % py_canister.sh --manage info                         ... Show information.
[Options]
               -h     : Show this message
               -P arg : specify python command / path
               -v     : Show verbose messages
               -q     : Supress verbose messages (default)
               -n     : Dry-run mode.
               -2     : Prioritize Python2 than Python3
               -3     : Prioritize Python3 than Python2
[Options for sub-command: setup/init ]
               -p     : prefix of the directory tree. (Default: Grandparent directory if the name of parent directory of 
                        py_canister.sh is bin, otherwise current working directory.)
               -M     : moving this script body into instead of copying
               -g     : setup files for git
               -G     : do not setup files for git (default)
               -r     : setup/update README.md
               -R     : do not setup/update README.md (default)
               -k     : keep backup file of README.md when it is updated.
               -K     : do not keep backup file of README.md when it is updated. (default)
               -t arg : Project title
[Options for sub-command: install/download ]
               -i arg : specify pip command
```
  
## Author
    Nanigashi Uji (53845049+nanigashi-uji@users.noreply.github.com)
