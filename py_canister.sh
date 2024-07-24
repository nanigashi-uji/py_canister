#!/bin/bash
# -*- mode: shell-script ; -*-
#
# py_canister(.sh): Shell script for providing Portable "Contained"
#                   Python environment.
#
#   - Locate python modules by PIP under single user directory.
#   - Invoke the python script with environmental variable for local
#     python modulels.
#   - Prepare the python script template and symblic link to wrapper
#     bash script
#

if [ "$0" != "${BASH_SOURCE:-$0}" ]; then
    # In case loaded by source.
    
    py_canister_bk="$(declare -f py_canister)"
    undef_py_canister_bk="$(declare -f undef_py_canister)"

    which_source_bk="$(declare -f which_source)"
    function which_source () {
        local _arg="$@"
        if [[ "${_arg}" == / ]] ; then
            if which -s "${REALPATH:-realpath}" ; then
                "${REALPATH:-realpath}" "${_arg}"
            elif which -s grealpath ; then
                grealpath "${_arg}"
            else
                local _argdir="$(dirname "${_arg}")"
                local _adir="$(cd "${_argdir}" 2>/dev/null && pwd -L || echo "${_argdir}")"
                echo "${_adir%/}/${_arg##*/}"
            fi
        fi
        local _seekpath=
        shopt -q sourcepath          && local _seekpath="${_seekpath}${_seekpath:+:}${PATH}"
        test -z "${POSIXLY_CORRECT}" && local _seekpath="${_seekpath}${_seekpath:+:}${PWD}"
        local _scriptpath=
        local IFS=':'
        local _i=
        for _i in ${_seekpath}; do
            local _fp="${_i%/}/${_arg##*/}"
            if [ -f "${_fp}" ]; then
                local _scriptpath="${_fp}"
                break
            fi
        done
        echo "${_scriptpath}"
        return
        :
    }

    py_canister_location="$(which_source "${BASH_SOURCE:-$0}")"

    unset which_source
    test -n "${which_source_bk}" \
        &&  { local which_source_bk="${which_source_bk%\}}"' \\; }'; \
              eval "${which_source_bk//\; : \}/\; : \; \}}" ; }
    unset which_source_bk
fi

function py_canister () {
    # Description
    local desc="Shell script for providing Portable 'Contained' Python environment"
    local invokemode=0
    if [ "$0" == "${BASH_SOURCE:-$0}" ]; then
        # Invoked as script directly
        local scriptpath="${BASH_SOURCE:-$0}"
        local this="$(basename "${scriptpath}")"
        local runas="${this}"
        local invokemode=0
    else
        # Invoked as script indirectly
        local scriptpath="${py_canister_location:-${BASH_SOURCE:-$0}}"
        local this="${FUNCNAME[0]}"
        if [ "x${FUNCNAME[1]:-main}" == "xmain" ] ; then
            local runas="${this}"
            local invokemode=1
        else
            local runas="${FUNCNAME[1]}"
            local invokemode=2
        fi
    fi

    # Python version when it is not automatically identified
    #local python_major_version_default=${python_major_version_default:-2}
    local python_major_version_default=${python_major_version_default:-3}
    #
    local bin_subdir="${bin_subdir:-bin}"
    local script_subdir="${script_subdir:-lib/python}"
    local module_subdir="${module_subdir:-site-packages}"
    local module_manage_name="${module_manage_name:-mng_pyenv}"
    local readme_name="${readme_name:-README.md}"
    local gitdummyfile="${gitdummyfile:-.gitkeep}"
    local managemodeoptarg="${managemodeoptarg:---manage}"

    local funcstatus=0
    local chk_python_arg_bk="$(declare -f chk_python_arg)"
    local seek_python_version_bk="$(declare -f seek_python_version)"
    local pyrealpath_bk="$(declare -f pyrealpath)"
    local chk_opts_bk="$(declare -f chk_opts)"
    local echo_usage_bk="$(declare -f echo_usage)"
    local guess_name_bk="$(declare -f guess_name)"
    local guess_email_bk="$(declare -f guess_email)"
    local cleanup_bk="$(declare -f cleanup)"
    local tmpfiles=()
    local tmpdirs=()

    function chk_python_arg () {
        local python_cmd="${PYTHON}"
        while [ $# -gt 1 ] ; do
            if [ "$1" == "-P" ] ; then
                local python_cmd="$2"
                break
            fi
            shift
        done
        echo "${python_cmd}"
        return $?
        : 
    }

    function seek_python_version () {
        local chk_pymjrver="${1:-3}"
        local cmd_name="${2:-python}"
        local oldIFS="${IFS}" ; local IFS=':'; local _path=(${PATH}) ; local IFS="${oldIFS}"
        "${FIND:-find}" "${_path[@]}" -maxdepth 1 \( -type f -o -type l \) \
                        \( -name "${cmd_name}${chk_pymjrver}*" -o -name "${cmd_name}-${chk_pymjrver}*"  \) \( -not -name "*config" -a -not -name "*m" \) 2> /dev/null \
            | "${SED:-sed}" -Ee 's/^.*\///' | "${SORT:-sort}" -r -V | "${UNIQ:-uniq}"
        return $?
        :
    }

    local hndlrhup_bk="$(trap -p SIGHUP)"
    local hndlrint_bk="$(trap -p SIGINT)"
    local hndlrquit_bk="$(trap -p SIGQUIT)"
    local hndlrterm_bk="$(trap -p SIGTERM)"

    trap -- 'cleanup ; kill -1  $$' SIGHUP
    trap -- 'cleanup ; kill -2  $$' SIGINT
    trap -- 'cleanup ; kill -3  $$' SIGQUIT
    trap -- 'cleanup ; kill -15 $$' SIGTERM
    
    function cleanup () {
        
        # removr temporary files and directories
        if [ ${#tmpfiles} -gt 0 ]; then
            rm -f "${tmpfiles[@]}"
        fi
        if [ ${#tmpdirs} -gt 0 ]; then
            rm -rf "${tmpdirs[@]}"
        fi

        # Restore  signal handler
        if [ -n "${hndlrhup_bk}"  ] ; then eval "${hndlrhup_bk}"  ;  else trap --  1 ; fi
        if [ -n "${hndlrint_bk}"  ] ; then eval "${hndlrint_bk}"  ;  else trap --  2 ; fi
        if [ -n "${hndlrquit_bk}" ] ; then eval "${hndlrquit_bk}" ;  else trap --  3 ; fi
        if [ -n "${hndlrterm_bk}" ] ; then eval "${hndlrterm_bk}" ;  else trap -- 15 ; fi

        # Restore alias and functions

        unset chk_python_arg
        test -n "${chk_python_arg_bk}" \
            &&  { local chk_python_arg_bk="${chk_python_arg_bk%\}}"' \\; }';\
                  eval "${chk_python_arg_bk//\; : \}/\; : \; \}}"  ; }

        unset seek_python_version
        test -n "${seek_python_version_bk}" \
            &&  { local seek_python_version_bk="${seek_python_version_bk%\}}"' \\; }';\
                  eval "${seek_python_version_bk//\; : \}/\; : \; \}}"  ; }

        unset pyrealpath
        test -n "${pyrealpath_bk}" \
            &&  { local pyrealpath_bk="${pyrealpath_bk%\}}"' \\; }';\
                  eval "${pyrealpath_bk//\; : \}/\; : \; \}}"  ; }

        unset chk_opts
        test -n "${chk_opts_bk}" \
            &&  { local chk_opts_bk="${chk_opts_bk%\}}"' \\; }';\
                  eval "${chk_opts_bk//\; : \}/\; : \; \}}"  ; }

        unset echo_usage
        test -n "${echo_usage_bk}" \
            &&  { local echo_usage_bk="${echo_usage_bk%\}}"' \\; }'; \
                  eval "${echo_usage_bk//\; : \}/\; : \; \}}"  ; }

        unset guess_name
        test -n "${guess_name_bk}" \
            &&  { local guess_name_bk="${guess_name_bk%\}}"' \\; }'; \
                  eval "${guess_name_bk//\; : \}/\; : \; \}}"  ; }

        unset guess_email
        test -n "${guess_email_bk}" \
            &&  { local guess_email_bk="${guess_email_bk%\}}"' \\; }'; \
                  eval "${guess_email_bk//\; : \}/\; : \; \}}"  ; }

        unset cleanup
        test -n "${cleanup_bk}"\
            && { local cleanup_bk="${cleanup_bk%\}}"' \\; }'; \
                 eval "${cleanup_bk//\; : \}/\; : \; \}}"  ; }
        return
        :
    }


    local cmdopt_pyver=
    local runas_pyver=
    if [ "${runas: -1:1}" == "2" -o "${runas: -1:1}" == "3" ]; then
        local runas_pyver="${runas: -1:1}"
    fi
    local runmode=0
    local python_cmd="${PYTHON}"
    case "${runas}" in
        ${module_manage_name}|${module_manage_name}[23])
            local runmode=1
            local python_cmd="$(chk_python_arg "$@")"
            local _i=
            for _i in "$@"; do
                if [ "${_i}" == "-2" -o "${_i}" == "-3" ]; then
                    local cmdopt_pyver="${_i: -1:1}"
                fi
            done
            ;;
        *)
            :
    esac
    
    if [ -z "${python_cmd}" ]; then
        local chk_pymjrver="${runas_pyver:-${cmdopt_pyver:-${python_major_version_default}}}"
        local _i=
        for _i in "python${chk_pymjrver}" "$(seek_python_version "${chk_pymjrver}")" "python" ; do
            if command -v "${_i}" 1> /dev/null 2>&1 ; then
                local python_cmd="${_i}"
                break
            fi
        done
        if [ -z "${python_cmd}" ]; then
            echo "[Error] ${this} : Can not find avaiable python" 1>&2
            cleanup 
            return 1
        fi
    fi
    
    if [ -f "${python_cmd}" -a -x  "${python_cmd}" ]; then
        local python_path="${python_cmd}"
    else
        local python_path="$(command -v "${python_cmd}")" \
            || { echo "[Error] ${this} : Can not find ${python_cmd} in PATH." 1>&2 ;
                 cleanup ; return 1 ; }
    fi

    local py_mjrver="$("${python_path}" -c 'import sys; print(sys.version_info[0])')"
    
    #
    # Check realpath
    #
    # Assuming GNU realpath (coreutils) is installed as "grealpath" in OSX (by macports, etc).
    #
    if command -v "realpath" 1>/dev/null 2>&1 ; then
        local _realpathcmd="realpath"
    elif command -v "grealpath"  1>/dev/null 2>&1 ; then
        local _realpathcmd="grealpath"
    else
        local _realpathcmd="pyrealpath"
        function pyrealpath () {
            "${python_cmd}" -c "import os.path;print(os.path.realpath('""$1""'))"
            return $?
            :
        }
    fi

    case ${invokemode:-0} in
        1) # function as "py_canister"
            if [ "${1:-x}" == "${managemodeoptarg}" ]; then
                local runmode=1
                local managemodeopt="${1}"
                shift
            else
                local managemodeopt=""
            fi
            local this_path="$(pwd)/${this##*/}"
            
            local this_loc_path="$(dirname "${this_path}")"
            local this_loc_dir="$(basename "${this_loc_path%/}")"

            local rp_this="${py_canister_location:-${BASH_SOURCE}}"

            if [ "x${this_loc_dir}" == "x${bin_subdir}" ]; then
                local flg_inplace=1
                local prefix="$(dirname "${this_loc_path%/}")"
            else
                local flg_inplace=0
                local prefix="$(pwd)"
            fi

            ;;
        2) # function as "cascade"
            local flgslnk=1
            local this_path="$(pwd)/${runas##*/}"
            local this_loc_path="$(dirname "${this_path}")"
            local this_loc_dir="$(basename "${this_loc_path%/}")"
            local rp_this="${py_canister_location:-${BASH_SOURCE}}"
            
            if [ "x${this_loc_dir}" == "x${bin_subdir}" ]; then
                local flg_inplace=1
                local prefix="$(dirname "${this_loc_path%/}")"
            else
                local flg_inplace=0
                local prefix="$(pwd)"
            fi

            ;;
        *) # script 
            local rp_this="$("${_realpathcmd}" "${scriptpath}")"
            if [ -L "${scriptpath}" -a "x${rp_this##*/}" != "x${runas}" ]; then
                local flgslnk=1
            fi
            if [ "x${rp_this##*/}" == "x${runas}" -a "${1:-x}" == "${managemodeoptarg}" ]; then
                local runmode=1
                local managemodeopt="${1}"
                shift
            else
                local managemodeopt=""
            fi
            local this_path="${rp_this}"

            local this_loc_path="$(dirname "${this_path}")"
            local this_loc_dir="$(basename "${this_loc_path%/}")"

            if [ "x${this_loc_dir}" == "x${bin_subdir}" ]; then
                local flg_inplace=1
                local prefix="$(dirname "${this_loc_path%/}")"
            else
                local flg_inplace=0
                local prefix="$(pwd)"
            fi
            ;;
    esac

    if [ ${runmode:-0} -eq 1 ]; then
        
        local opt_help=0
        local opt_move=0
        local subcmd=""
        local opt_verbose=0
        local opt_dryrun=0
        local subcmd_args=
        local pip_cmd="${PIP}"
        local opt_git=0
        local opt_modreadme=0
        local opt_keepreadmebak=0
        local opt_projtitle=""
        local opt_pyopt_ver="${python_major_version_default:-3}"
        local opt_module_install=()
        local opt_script_install=()

        local opt_scripts_standard=( "pkg_structure" "pkg_cache" )

        function chk_opts () {
            local OPT=""
            local OPTARG=""
            local OPTIND=""
            if [ "${runas: -1:1}" != "2" -a "${runas: -1:1}" != "3" ]; then
                local optchoice="p:i:gGMrRnvqht:kKm:Ss:23"
            else
                local optchoice="p:i:gGMrRnvqht:kKm:Ss:"
            fi

            local check_dup=
            while getopts "${optchoice}" OPT ; do
                case ${OPT} in
                    p) prefix="${OPTARG}"
                       local rp_prefix="$("${_realpathcmd}" "${prefix}")"
                       if [ "${rp_prefix%/}/bin" == "${this_loc_path%/}" ]; then
                           flg_inplace=1
                       else
                           flg_inplace=0
                       fi
                       ;;
                    i) pip_cmd="${OPTARG}"
                       ;;
                    t) opt_projtitle="${OPTARG}"
                       ;;
                    h) opt_help=1
                       ;;
                    M) opt_move=1
                       ;;
                    v) opt_verbose=1
                       ;;
                    q) opt_verbose=0
                       ;;
                    n) opt_dryrun=1
                       ;;
                    g) opt_git=1
                       ;;
                    G) opt_git=0
                       ;;
                    r) opt_modreadme=1
                       ;;
                    R) opt_modreadme=0
                       ;;
                    k) opt_keepreadmebak=1
                       ;;
                    K) opt_keepreadmebak=0
                       ;;
                    m) opt_module_install=( "${opt_module_install[@]}" "${OPTARG}" )
                       ;;
                    s) local _check_dup=0 
                       local _i=
                       for _i in "${opt_script_install[@]}"; do
                           if [ x"${_i}" == x"${OPTARG}" ]; then
                               local _check_dup=1
                           fi
                       done
                       if [ ${_check_dup:-0} -eq 0 ]; then
                           opt_script_install=( "${opt_script_install[@]}" "${OPTARG}" )
                       fi
                       ;;
                    S) local _s= _i= _check_dup=0 
                       for _s in "${opt_scripts_standard[@]}"; do 
                           local _check_dup=0 _i=
                           for _i in "${opt_script_install[@]}"; do
                               if [ x"${_i}" == x"${_s}" ]; then
                                   local _check_dup=1
                               fi
                           done
                           if [ ${_check_dup:-0} -eq 0 ]; then
                               opt_script_install=( "${opt_script_install[@]}" "${_s}" )
                           fi
                       done
                       ;;
                    2) if [ "${runas: -1:1}" != "2" -a "${runas: -1:1}" != "3" ]; then
                           opt_pyopt_ver=2
                       fi
                       ;;
                    3) if [ "${runas: -1:1}" != "2" -a "${runas: -1:1}" != "3" ]; then
                           opt_pyopt_ver=3
                       fi
                       ;;
                    \?)
                        ::
                        ;;
                esac
            done
            shift $((OPTIND - 1))
            subcmd="${1}"
            shift
            subcmd_args=("$@")
            return $?
            :
        }
        #
        chk_opts "$@"

        function echo_usage () {
            if [ "$0" == "${BASH_SOURCE:-$0}" ]; then
                local this=$0
            else
                local this="${FUNCNAME[1]}"
            fi
            echo ""
            echo "               % ${runas} ${managemodeoptarg} [options] sub-command [arguments]"                                                             1>&2
            echo "    ---- ${desc}"                                                                                                                            1>&2
            echo "[sub-commands] "                                                                                                                             1>&2
            echo "               % ${runas} ${managemodeopt} [options] init [scriptnames]    ... setup directory tree,"                                        1>&2
            echo "                                                                           and prepare templates if arguments are given."                    1>&2
            echo "               % ${runas} ${managemodeopt} [options] add script_names      ... prepare python script templates."                             1>&2
            echo "               % ${runas} ${managemodeopt} [options] addlib [script_names] ... prepare python script templates."                             1>&2
            echo "               % ${runas} ${managemodeopt} install  module_names           ... Install python module with pip locally."                      1>&2
            echo "               % ${runas} ${managemodeopt} download module_names           ... Download python module with pip locally."                     1>&2
            echo "               % ${runas} ${managemodeopt} clean                           ... Delete local python module for corresponding python version." 1>&2
            echo "               % ${runas} ${managemodeopt} distclean/cleanall/allclean     ... Delete local python module for all python version."           1>&2
            echo "               % ${runas} ${managemodeopt} info                            ... Show information."                                            1>&2

            echo "[Options]"                                                  1>&2
            echo "               -h     : Show this message"                  1>&2
            echo "               -P arg : specify python command / path"      1>&2
            echo "               -v     : Show verbose messages"              1>&2
            echo "               -q     : Supress verbose messages (default)" 1>&2
            echo "               -n     : Dry-run mode."                      1>&2
            if [ "${runas: -1:1}" != "2" -a "${runas: -1:1}" != "3" ]; then
                echo "               -2     : Prioritize Python2 than Python3" 1>&2
                echo "               -3     : Prioritize Python3 than Python2" 1>&2
            fi
            echo "[Options for sub-command: setup/init ]"                                                                                    1>&2
            echo "               -p     : prefix of the directory tree. (Default: Grandparent directory if the name of parent directory of " 1>&2
            echo "                        ${runas} is ${bin_subdir}, otherwise current working directory.)"                                  1>&2
            echo "               -M     : moving this script body into instead of copying"                                                   1>&2
            echo "               -g     : setup files for git"                                                                               1>&2
            echo "               -G     : do not setup files for git (default)"                                                              1>&2
            echo "               -r     : setup/update ${readme_name:-README.md}"                                                            1>&2
            echo "               -R     : do not setup/update ${readme_name:-README.md} (default)"                                           1>&2
            echo "               -k     : keep backup file of ${readme_name:-README.md} when it is updated."                                 1>&2
            echo "               -K     : do not keep backup file of ${readme_name:-README.md} when it is updated. (default)"                1>&2
            echo "               -t arg : Project title"                                                                                     1>&2
            echo "               -m arg : install module by pip"                                                                             1>&2
            echo "               -s arg : install library script from template."                                                             1>&2
            echo "               -S     : install standard library scripts. (equivalent to '${opt_scripts_standard[@]/#/-s }')"              1>&2
            echo "[Options for sub-command: install/download ]"                                                                              1>&2
            echo "               -i arg : specify pip command"                                                                               1>&2
            echo "rp_this == ${rp_this}"
            return
            :
        }

        if [ ${opt_help:-0} -ne 0 ]; then
            echo_usage
            cleanup
            return 0
        fi

        local bindir="${prefix%/}/${bin_subdir%/}"
        local script_dir="${prefix%/}/${script_subdir%/}"
        local module_dir="${script_dir%/}/${module_subdir%/}"
        
        #
        # Checking pip_cmd
        #
        if [ -z "${pip_cmd}" ]; then
            local chk_pymjrver="${runas_pyver:-${cmdopt_pyver:-${python_major_version_default}}}"
            for _i in "pip${chk_pymjrver}" "$(seek_python_version "${chk_pymjrver}" "pip")" "pip" ; do
                if command -v "${_i}" 1>/dev/null 2>&1 ; then
                    local pip_cmd="${_i}"
                    break
                fi
            done
            if [ -z "${pip_cmd}" ]; then
                echo "[Error] ${this} : Can not find avaiable pip" 1>&2
                cleanup
                return 1
            fi
        fi

        if [ -f "${pip_cmd}" -a -x  "${pip_cmd}" ]; then
            local pip_path="${pip_cmd}"
        else
            local pip_path="$(command -v "${pip_cmd}")" \
                || { echo "[Error] ${this} : Can not find ${pip_cmd} in PATH." 1>&2 ; \
                     cleanup ; return 1 ; }
        fi
        local pip_pyver="$("${pip_path}" -V)"
        local pip_pyver="${pip_pyver#*(python }"
        local pip_pyver="${pip_pyver%)}"

        case "${subcmd}" in
            init|setup|add|addlib)
                if [ "${subcmd}" == "init" -o "${subcmd}" == "setup" ]; then
                    local dest_this_script="${bindir%/}/$(basename "${rp_this}")"
                    if [ ${opt_verbose:-0} -ne 0 ]; then
                        echo "Initialize working directory : ${prefix}"
                        echo "mkdir -p ${bindir}"
                        echo "mkdir -p ${script_dir}"
                        echo "mkdir -p ${module_dir}"
                        echo "if [ -e \"${dest_this_script}\" ]; then"
                        echo "    if diff -q \"${dest_this_script}\" \"${rp_this}\" 1>/dev/null; then"
                        echo "        echo \"File already exist(skipped): ${dest_this_script}\""
                        echo "    else"
                        echo "        mv -i \"${dest_this_script}\" \"${dest_this_script}.\$(date -r \"${dest_this_script}\" +\"%Y%m%d_%H%M%S\"\).bak\""
                        echo "        if [ ${opt_move:-0} -ne 0 ]; then"
                        echo "            mv -i \"${rp_this}\" \"${dest_this_script}\""
                        echo "        else"
                        echo "            cp -ai \"${rp_this}\" \"${dest_this_script}\""
                        echo "        fi"
                        echo "    fi"
                        echo "elif [ ${flg_inplace:-0} -eq 0 ]; then"
                        echo "    if [ ${opt_move:-0} -ne 0 ]; then"
                        echo "        mv -i \"${rp_this}\" \"${dest_this_script}\""
                        echo "    else"
                        echo "        cp -ai \"${rp_this}\" \"${dest_this_script}\""
                        echo "    fi"
                        echo "fi"
                        echo "for _i in \"${module_manage_name}\" \"${module_manage_name}\"{2,3}; do"
                        echo "    if [ -e \"${bindir%/}/\${_i}\" ]; then"
                        echo "        :"
                        echo "    else"
                        echo "        (cd \"${bindir%/}\" && ln -is $(basename "${dest_this_script}") \"\${_i}\")"
                        echo "    fi"
                        echo "done"
                        echo "if [ ${opt_git:-0} -ne 0 ]; then"
                        echo "    if [ ! -e \"${prefix}/.gitignore\" ]; then"
                        echo "        gitignore_template_header='^ *#{1,} *_{3,}gitignore_template_start_{3,} *#{1,}.*$'"
                        echo "        gitignore_template_footer='^ *#{1,} *_{3,}gitignore_template_end_{3,} *#{1,}.*$'"
                        echo "        \"${SED:-sed}\" -nE -e '/'\"\${gitignore_template_header}\"'/,/'\"\${gitignore_template_footer}\"'/ {/('\"\${gitignore_template_header}\"'|'\"\${gitignore_template_footer}\"')/ d; s/____GIT_DUMMYNAME____/${gitdummyfile}/g; p; }' \"${rp_this}\" 1> \"${prefix}/.gitignore\""
                        echo "    fi"
                        echo "    if [ ! -e \"${module_dir}${gitdummyfile}\" ]; then"
                        echo "        touch \"${module_dir}${gitdummyfile}\""
                        echo "    fi"
                        echo "fi"
                    fi
                    if [ ${opt_dryrun:-0} -eq 0 ]; then
                        mkdir -p "${bindir}"
                        mkdir -p "${script_dir}"
                        mkdir -p "${module_dir}"
                        if [ ${flg_inplace:-0} -eq 0 -a -e "${dest_this_script}" ]; then
                            if diff -q "${dest_this_script}" "${rp_this}" 1>/dev/null; then
                                echo "File already exist: ${dest_this_script}"
                            else
                                mv -i "${dest_this_script}" "${dest_this_script}.$(date -r "${dest_this_script}" +"%Y%m%d_%H%M%S").bak"
                                if [ ${opt_move:-0} -ne 0 ]; then
                                    mv -i "${rp_this}" "${dest_this_script}"
                                else
                                    cp -ai "${rp_this}" "${dest_this_script}"
                                    chmod guo+rX "${dest_this_script}"
                                fi
                                #                            if [ "${OSTYPE:-unknown}" == "darwin" ]; then
                                #                                "${dest_this_script}" --manage -h  1>/dev/null
                                #                            fi
                            fi
                        elif [ ${flg_inplace:-0} -eq 0 ]; then
                            if [ ${opt_move:-0} -ne 0 ]; then
                                mv -i "${rp_this}" "${dest_this_script}"
                            else
                                cp -ai "${rp_this}" "${dest_this_script}"
                                chmod guo+rX "${dest_this_script}"
                            fi
                            #                        if [ "${OSTYPE:-unknown}" == "darwin" ]; then
                            #                            "${dest_this_script}" --manage -h 1> /dev/null
                            #                        fi
                        fi

                        for _i in "${module_manage_name}" "${module_manage_name}"{2,3}; do
                            if [ -e "${bindir%/}/${_i}" ]; then
                                :
                            else
                                (cd "${bindir%/}" && ln -is "$(basename "${dest_this_script}")" "${_i}")
                            fi
                        done
                        
                        if [ ${opt_git:-0} -ne 0 ]; then
                            local gitignore_template_header='^ *#{1,} *_{3,}gitignore_template_start_{3,} *#{1,}.*$'
                            local gitignore_template_footer='^ *#{1,} *_{3,}gitignore_template_end_{3,} *#{1,}.*$'
                            if [ ! -e "${prefix}/.gitignore" ]; then
                                "${SED:-sed}" -nE -e '/'"${gitignore_template_header}"'/,/'"${gitignore_template_footer}"'/ {/('"${gitignore_template_header}"'|'"${gitignore_template_footer}"')/ d; s/____GIT_DUMMYNAME____/'"${gitdummyfile}"'/g; p; }' "${rp_this}" 1> "${prefix}/.gitignore"
                            else
                                "${SED:-sed}" -nE -e '/'"${gitignore_template_header}"'/,/'"${gitignore_template_footer}"'/ {/('"${gitignore_template_header}"'|'"${gitignore_template_footer}"')/ d; s/____GIT_DUMMYNAME____/'"${gitdummyfile}"'/g; p; }' "${rp_this}" 1>> "${prefix}/.gitignore"
                            fi
                            if [ ! -e "${module_dir}/${gitdummyfile}" ]; then
                                touch "${module_dir}/${gitdummyfile}"
                            fi
                        fi
                        
                        if [ ${opt_modreadme:-0} -ne 0 ]; then
                            if [ ! -e "${prefix}/${readme_name}" ] ; then 
                                local author=
                                function guess_name () {
                                    local _gitname=$("${GIT:-git}" config --local --get user.name  2>/dev/null || "${GIT:-git}" config --global --get user.name 2>/dev/null)
                                    author="${_gitname:-${USER}}"
                                    return $?
                                    :
                                }
                                local address=
                                function guess_email () {
                                    local _gitemail=$("${GIT:-git}" config --local --get user.email  2>/dev/null || "${GIT:-git}" config --global --get user.email 2>/dev/null)
                                    address="${_gitemail:-${USER}@$(hostname -f)}"
                                    return $?
                                    :
                                }
                                guess_name
                                guess_email
                                
                                local readme_template_header='^ *#{1,} *_{3,}readme_template_start_{3,} *#{1,}.*$'
                                local readme_template_footer='^ *#{1,} *_{3,}readme_template_end_{3,} *#{1,}.*$'

                                local awkcmd_add=
                                if [ "${#subcmd_args[@]}" -gt 0 ]; then
                                    local _i=
                                    for _i in "${subcmd_args[@]}"; do
                                        # echo "${_i}" "----------------------"
                                        local script_bn="${_i%.py}"
                                        if [ "x${script_bn: -1:1}" == "x${py_mjrver}" ]; then
                                            local script_bn_wver="${script_bn}"
                                            local script_bn_wover="${script_bn%${py_mjrver}}"
                                        else
                                            local script_bn_wver="${script_bn}${py_mjrver}"
                                            local script_bn_wover="${script_bn}"
                                        fi
                                        local awkcmd_add="${awkcmd_add} printf(\"  %d.  %-36s Example Python script that use modules\n\", ++fidx,\"${script_subdir%/}/${script_bn_wover}.py:\") ;"
                                        local awkcmd_add="${awkcmd_add} printf(\"  %da. %-36s Same as above using python${py_mjrver} as default\n\n\", fidx, \"${script_subdir%/}/${script_bn_wver}.py:\") ;"
                                        local awkcmd_add="${awkcmd_add} printf(\"  %d.  %-36s Symbolic link to '${rp_this##*/}' to invoke ${script_bn_wover}.py.\n\", ++fidx, \"${bin_subdir%/}/${script_bn_wover}:\") ;"
                                        local awkcmd_add="${awkcmd_add} printf(\"  %da. %-36s Same as above using python${py_mjrver} as default\n\n\", fidx, \"${bin_subdir%/}/${script_bn_wver}:\") ;"
                                    done
                                fi

                                if [ "${#opt_script_install[@]}" -gt 0 ]; then
                                    local _i=
                                    for _i in "${opt_script_install[@]}"; do
                                        local script_bn="${_i%.py}"
                                        local awkcmd_add="${awkcmd_add} printf(\"  %d.  %-36s Python Library script used in this package\n\n\", ++fidx,\"${script_subdir%/}/${script_bn}.py:\") ;"
                                    done
                                fi
                                
                                # selecting readme template & header/footer remove
                                local sed_expression='/'"${readme_template_header}"'/,/'"${readme_template_footer}"'/ { /('"${readme_template_header}"'|'"${readme_template_footer}"')/ d; /^([^@]|$)/ { '
                                local sed_expression="${sed_expression}"' s/____TITLE____/'"${opt_projtitle:-""$(basename "${prefix}")""}"'/g ;'
                                local sed_expression="${sed_expression}"' s/____README_NAME____/'"${readme_name:-README.md}"'/g ;'
                                local sed_expression="${sed_expression}"' s/____AUTHOR_NAME____/'"${author}"'/g;' 
                                local sed_expression="${sed_expression}"' s/____AUTHOR_EMAIL____/'"${address}"'/g;'
                                local sed_expression="${sed_expression}"' s/____MNGSCRIPT_NAME____/'"${module_manage_name}"'/g;'
                                local sed_expression="${sed_expression}"' s/____SHSCRIPT_ENTITY_NAME____/'"$(basename "${rp_this}")"'/g;'
                                local sed_expression="${sed_expression}"' /^.*____SCRIPTNAME____.*$/ d;'
                                if [ ${opt_git:-0} -eq 0 ]; then
                                    local sed_expression="${sed_expression}"' /^.*.gitignore.*$/ d;'
                                    local sed_expression="${sed_expression}"' /^.*____GITDUMMYFILE____.*$/ d;'
                                else
                                    local sed_expression="${sed_expression}"' s/____GITDUMMYFILE____/'"${gitdummyfile}"'/g;'
                                fi
                                # output contents and closing readme template selection
                                local sed_expression="${sed_expression}"' p; } ; } ;'
                                
                                local awkcmd1_header='^ *#{1,} *_{3,}readme_renumbering_awk_start_{3,} *#{1,}.*$'
                                local awkcmd1_footer='^ *#{1,} *_{3,}readme_renumbering_awk_end_{3,} *#{1,}.*$'

                                local awk_add_cmd="BEGIN { fidx=0 ; flg_add=0           ; }
/^ *- *Contents:/,/^ *- *Usage.*:/ { if ( (/.gitignore/ || /^ *- *Usage.*:/ ) && flg_add==0 ) { ${awkcmd_add} flg_add=1 ;} ; if ( /^ +[0-9]+\. / ) { ++fidx; } ; sub(/[0-9]+/, fidx);}
{print \$0;}
END {}"
                                "${SED:-sed}" -nE -e "${sed_expression}" "${rp_this}" \
                                    | "${AWK:-awk}" -f <(echo "${awk_add_cmd}" 2> /dev/null) 2> /dev/null \
                                    | "${AWK:-awk}" -f <("${SED:-sed}" -nE -e '/'"${awkcmd1_header}"'/,/'"${awkcmd1_footer}"'/ {/('"${awkcmd1_header}"'|'"${awkcmd1_footer}"')/ d; p; }' "${rp_this}" 2> /dev/null) \
                                                    1> "${prefix}/${readme_name}"  2> /dev/null
                                
                            fi
                        fi
                    fi
                else

                    if [ "${subcmd}" == "add" -a "${#subcmd_args[@]}" -lt 1 ]; then
                        echo "${runas} add: insufficient subcommand arguments" 1>&2
                        echo_usage
                        return 1
                    fi

                    if [ "${subcmd}" == "addlib" ]; then
                        local _x=
                        local _i=
                        for _x in "${subcmd_args[@]}" ; do
                            for _i in "${opt_script_install[@]}"; do
                                if [ x"${_i}" == x"${_x}" ]; then
                                    local check_dup=1
                                fi
                            done
                            if [ ${check_dup:-0} -eq 0 ]; then
                                local opt_script_install=( "${opt_script_install[@]}" "${_x}" )
                            fi
                        done
                        local subcmd_args=()
                        if [ "${#opt_script_install[@]}" -lt 1 ]; then
                            echo "${runas} addlib: insufficient subcommand arguments. Give scriptname by '-s' option or by arguments" 1>&2
                            echo_usage
                            return 1
                        fi
                    fi
                fi

                if [ "${#subcmd_args[@]}" -gt 0 ]; then

                    local py_shebang_pattern='^#{2,} *_{3,}py_shebang_pattern_{3,} *#{2,}.*$'
                    local py_shebang_str='#!/usr/bin/env '"$(basename "${python_cmd}")"

                    for _i in "${subcmd_args[@]}" ; do

                        local lmtch="$("${GREP:-grep}" -c -Ee '^ *#{1,} *_{3,}'"${_i%.py}"'_template_(start|end)_{3,} *#{1,}.*$' "${rp_this}")"
                        if [ ${lmtch:-0} -gt 1 ]; then
                            local py_main_template_header='^ *#{1,} *_{3,}'"${_i%.py}"'_template_start_{3,} *#{1,}.*$'
                            local py_main_template_footer='^ *#{1,} *_{3,}'"${_i%.py}"'_template_end_{3,} *#{1,}.*$'
                        else
                            local py_main_template_header='^ *#{1,} *_{3,}py_main_template_start_{3,} *#{1,}.*$'
                            local py_main_template_footer='^ *#{1,} *_{3,}py_main_template_end_{3,} *#{1,}.*$'
                        fi
                        
                        local script_bn="${_i%.py}"
                        if [ "x${script_bn: -1:1}" == "x${py_mjrver}" ]; then
                            local script_bn_wver="${script_bn}"
                            local script_bn_wover="${script_bn%${py_mjrver}}"
                        else
                            local script_bn_wver="${script_bn}${py_mjrver}"
                            local script_bn_wover="${script_bn}"
                        fi
                        if [ ${py_mjrver:-3} -eq 3 ]; then
                            local script_bn_file="${script_bn_wver}"
                            local script_bn_link="${script_bn_wover}"
                        else
                            local script_bn_file="${script_bn_wover}"
                            local script_bn_link="${script_bn_wver}"
                        fi
                        
                        local script_out="${script_bn_file}.py"
                        if [ ${opt_verbose:-0} -ne 0 ]; then
                            echo "Making ${script_dir}/${script_out} from template."
                            echo "${SED:-sed}" -nE -e '/'"${py_main_template_header}"'/,/'"${py_main_template_footer}"'/ {/('"${py_main_template_header}"'|'"${py_main_template_footer}"')/ d; s:'"${py_shebang_pattern}"':'"${py_shebang_str}"':g; s:____@@NAME@@____:'"${_i%.py}"':g; p; }' "${rp_this} 1> \"${script_dir}/${script_out}\""
                            echo 'if [ \!'" -f \"$(dirname "${script_dir}/${script_out}")/${script_bn_link}.py\" ] ; then"
                            echo "    (cd \"$(dirname "${script_dir}/${script_out}")\"; ln -s \"$(basename "${script_dir}/${script_out}")\" \"${script_bn_link}.py\")"
                            echo "fi"
                            echo "(cd \"${bindir%/}\" && ln -is \"$(basename "${rp_this}")\" \"${script_bn_wver}\" )"
                            echo 'if [ ${py_mjrver:-3} -eq 3 -a \!'" -f "${bindir%/}/${script_bn_link}" ]; then"
                            echo "    (cd \"${bindir%/}\" && ln -s \"$(basename "${rp_this}")\" \"${script_bn_link}\" )"
                            echo "fi"
                        fi
                        if [ ${opt_dryrun:-0} -eq 0 ]; then
                            "${SED:-sed}" -nE -e '/'"${py_main_template_header}"'/,/'"${py_main_template_footer}"'/ {/('"${py_main_template_header}"'|'"${py_main_template_footer}"')/ d; s:'"${py_shebang_pattern}"':'"${py_shebang_str}"':g;  s:____@@NAME@@____:'"${_i%.py}"':g; p; }' "${rp_this}" 1> "${script_dir%/}/${script_out}"
                            if [ ! -f "$(dirname "${script_dir}/${script_out}")/${script_bn_link}.py" ] ; then
                                (cd "$(dirname "${script_dir}/${script_out}")"; ln -s "$(basename "${script_dir}/${script_out}")" "${script_bn_link}.py")
                            fi
                            (cd "${bindir%/}" && ln -is "$(basename "${rp_this}")" "${script_bn_wver}" )
                            if [ ${py_mjrver:-3} -eq 3 -a ! -f "${bindir%/}/${script_bn_link}" ]; then
                                (cd "${bindir%/}" && ln -is "$(basename "${rp_this}")" "${script_bn_link}" )
                            fi
                        fi
                    done
                fi

                if [ "${#opt_script_install[@]}" -gt 0 ]; then
                    local bn_libscript=
                    for bn_libscript in "${opt_script_install[@]}" ; do
                        local lmtch="$("${GREP:-grep}" -c -Ee '^ *#{1,} *_{3,}'"${bn_libscript%.py}"'_template_(start|end)_{3,} *#{1,}.*$' "${rp_this}")"
                        if [ ${lmtch:-0} -gt 1 ]; then
                            local libscr_template_header='^ *#{1,} *_{3,}'"${bn_libscript%.py}"'_template_start_{3,} *#{1,}.*$'
                            local libscr_template_footer='^ *#{1,} *_{3,}'"${bn_libscript%.py}"'_template_end_{3,} *#{1,}.*$'
                        else
                            local libscr_template_header='^ *#{1,} *_{3,}py_lib_script_template_start_{3,} *#{1,}.*$'
                            local libscr_template_footer='^ *#{1,} *_{3,}py_lib_script_template_end_{3,} *#{1,}.*$'
                        fi

                        local fn_libscript="${bn_libscript%.py}.py"
                        if [ ${opt_verbose:-0} -ne 0 ]; then
                            echo "install script : ${bn_libscript}"
                            echo "Making ${script_dir}/${fn_libscript} from template."
                            echo 'if [ -e "'"${script_dir%/}/${fn_libscript}"'" ]; then'
                            echo     'mv -i "'"${script_dir%/}/${fn_libscript}"'" "'"${script_dir%/}/${fn_libscript%.py}"'.$(date -r "'"${script_dir%/}/${fn_libscript}"'" "++%Y%m%d_%H%M%S").py"'
                            echo "fi"
                            echo "${SED:-sed}" -nE -e '/'"${libscr_template_header}"'/,/'"${libscr_template_footer}"'/ {/('"${libscr_template_header}"'|'"${libscr_template_footer}"')/ d; s:'"${py_shebang_pattern}"':'"${py_shebang_str}"':g; s:____@@NAME@@____:'"${_i%.py}"':g; p; }' "${rp_this} 1> \"${script_dir}/${fn_libscript}\""
                        fi
                        if [ ${opt_dryrun:-0} -eq 0 ]; then
                            if [ -e "${script_dir%/}/${fn_libscript}" ]; then
                                mv -i "${script_dir%/}/${fn_libscript}" "${script_dir%/}/${fn_libscript%.py}.$(date -r "${script_dir%/}/${fn_libscript}" "++%Y%m%d_%H%M%S").py"
                            fi
                            "${SED:-sed}" -nE -e '/'"${libscr_template_header}"'/,/'"${libscr_template_footer}"'/ {/('"${libscr_template_header}"'|'"${libscr_template_footer}"')/ d; s:'"${py_shebang_pattern}"':'"${py_shebang_str}"':g; s:____@@NAME@@____:'"${_i%.py}"':g; p; }' "${rp_this}" 1> "${script_dir%/}/${fn_libscript}"
                        fi
                    done
                fi

                if [ "${#subcmd_args[@]}" -gt 0 -o "${#opt_script_install[@]}" -gt 0 ]; then

                    if [  "${subcmd}" != "init" -a "${subcmd}" != "setup" -a ${opt_modreadme:-0} -ne 0 -a -e "${prefix}/${readme_name}" ] ; then 

                        local sedupdatecmd=""
                        local bin_sbdr="${bin_subdir%/}"
                        local scr_sbdr="${script_subdir%/}"

                        local bin_sbdr_esq1="${bin_sbdr//\//\\/}"
                        local scr_sbdr_esq1="${scr_sbdr//\//\\/}"

                        local bin_sbdr_esq2="${bin_sbdr//\//\\\\\\/}"
                        local scr_sbdr_esq2="${scr_sbdr//\//\\\\\\/}"

                        local _i=
                        for _i in "${subcmd_args[@]}" ; do
                            local _v="${py_mjrver}"
                            local rp_this_spath="$(basename "${rp_this}")"

                            local readme_update_awkcmd="BEGIN {
    idx=0; bmtch=0; bmtchx=0; smtch=0; smtchx=0;
}
/- Contents:/,/- Usage.*:/ {
    if ( \$0 ~ /^ *[0-9]+\. +/ ){  ++idx; } ;

    if ( \$0 ~ /^ *[0-9]+[a-z]+\. +${bin_sbdr_esq1}\/${_i}${_v} *:/ ) { bmtchx=-10; }
    else if ( \$0 ~ /^ *[0-9]+[a-z]+\. +${bin_sbdr_esq1}\/${_i}[0-9]+ *:/ ) { ++bmtchx; } ;

    if ( \$0 ~  /^ *[0-9]+\. +${bin_sbdr_esq1}\/${_i} *:/ ){ bmtch=-10; };

    if ( \$0 ~ /^ *[0-9]+[a-z]+\. +${scr_sbdr_esq1}\/${_i}${_v}.py *:/ ) { smtchx=-10; }
    else if ( \$0 ~ /^ *[0-9]+[a-z]+\. +${scr_sbdr_esq1}\/${_i}[0-9]+.py *:/ ) { ++smtchx; } ;

    if ( \$0 ~  /^ *[0-9]+\. +${scr_sbdr_esq1}\/${_i}.py *:.*\$/ ){  smtch=-10; };

}
END {
    if ( bmtchx > 0) {
        printf(\"/^( +)([0-9]+)([a-z])(\\\\\\. +)(${bin_sbdr_esq2}\\\\/)(${_i})([0-9]+) *:/ { h; x ; s/^( +)([0-9]+)([a-z])(\\\\\\. +)(${bin_sbdr_esq2}\\\\/)(${_i})([0-9]+)( *:)/\\\\1\\\\2%x\\\\4\\\\5${_i}${_v}\\\\8/g; s/(python)[0-9]/\\\\1${_v}/ig; x; G; } ; \" , bmtchx+9+1);
    } else if ( bmtchx == 0 ) {
        if ( bmtch == 0 ) {
            printf(\"/- +Usage.*:/ { G; s/^(.*)(\\\\n)(.*)\\\$/  %d.  %-36s Symbolic link to '${rp_this_spath}' to invoke ${_i}.py.\\\\2  %da. %-36s Same as above using python${_v} as default\\\\2\\\\2\\\\1/g ; } ; \", ++idx, \"${bin_sbdr_esq2}\\\\/${_i}:\", idx, \"${bin_sbdr_esq2}\\\\/${_i}${_v}:\" ) ;
        } else {
            printf(\"/^ *[0-9]+\\\\\\. +${bin_sbdr_esq2}\\\\/${_i} *:/ { G; s/^( *)([0-9]+)(\\\\\\..*)(\\\\n)(.*)\\\$/\\\\1\\\\2\\\\3\\\\4\\\\5\\\\4  \\\\2a. %-36s Same as above using python${_v} as default\\\\4/g ; }; \", \"${bin_sbdr_esq2}\\\\/${_i}${_v}:\") ;
        }
    } else if ( bmtch == 0 ) {
        printf(\"/^ *[0-9]+[a-z]+\\\\\\. +${bin_sbdr_esq2}\\\\/${_i}${_v} *:/ {G; s/^( *)([0-9]+)([a-z]+\\\\\\..*)(\\\\n)(.*)\\\$/\\\\4  \\\\2. %-36s Symbolic link to '${rp_this_spath}' to invoke ${_i}.py.\\\\4\\\\1\\\\2\\\\3\\\\4\\\\5/g ; } ; \", \"${bin_sbdr_esq2}\\\\/${_i}:\")
    }   

    if ( smtchx > 0) {
        printf(\"/^( +)([0-9]+)([a-z])(\\\\\\. +)(${scr_sbdr_esq2}\\\\/)(${_i})([0-9]+).py *:/ { h; x; s/^( +)([0-9]+)([a-z])(\\\\\\. +)(${scr_sbdr_esq2}\\\\/)(${_i})([0-9]+).py( *:)/\\\\1\\\\2%x\\\\4\\\\5${_i}${_v}.py\\\\8/g; s/(python)[0-9]/\\\\1${_v}/ig; x; G;} ; \" , smtchx+9+1);
    } else if ( smtchx == 0 ) {
        if ( smtch == 0 ) {
            printf(\"/- +Usage.*:/ { G; s/^(.*)(\\\\n)(.*)\\\$/  %d.  %-36s  Example Python script that use modules\\\\2  %da. %-36s  Same as above using python${_v} as default\\\\2\\\\2\\\\1/g ; } ; \", ++idx, \"${scr_sbdr_esq2}\\\\/${_i}.py:\", idx, \"${scr_sbdr_esq2}\\\\/${_i}${_v}.py:\") ;
        } else {
            printf(\"/^ *[0-9]+\\\\\\. +${scr_sbdr_esq2}\\\\/${_i} *:/ { G; s/^( *)([0-9]+)(\\\\\\..*)(\\\\n)(.*)\\\$/\\\\1\\\\2\\\\3\\\\4\\\\5\\\\4  \\\\2a. %-36s  Same as above using python${_v} as default\\\\4/g ; } ; \", \"${scr_sbdr_esq2}\\\\/${_i}${_v}.py:\") ;
        }
    } else if ( smtch == 0 ) {
        printf(\"/^ *[0-9]+[a-z]+\\\\\\. +${scr_sbdr_esq2}\\\\/${_i}${_v} *:/ {G; s/^( *)([0-9]+)([a-z]+\\\\\\..*)(\\\\n)(.*)\\\$/\\\\4  \\\\2. %-36s  Example Python script that use modules\\\\4\\\\1\\\\2\\\\3\\\\4\\\\5/g ; } ; \", \"${scr_sbdr_esq2}\\\\/${_i}.py:\")
    }   
}"
                            local sedupdatecmd="${sedupdatecmd}$("${AWK:-awk}" -f <(echo "${readme_update_awkcmd}")  "${prefix}/${readme_name}" 2> /dev/null)"
                        done

                        local _i=
                        for _i in "${opt_script_install[@]}" ; do
                            local readme_update_awkcmd="BEGIN {
    idx=0; bmtch=0; bmtchx=0; smtch=0; smtchx=0;
}
/- Contents:/,/- Usage.*:/ {
    if ( \$0 ~ /^ *[0-9]+\. +/ ){  ++idx; } ;
    if ( \$0 ~  /^ *[0-9]+\. +${scr_sbdr_esq1}\/${_i%.py}.py *:.*\$/ ){  smtch=-10; };
}
END {
    if ( smtch == 0 ) {
        printf(\"/- +Usage.*:/ { G; s/^(.*)(\\\\n)(.*)\\\$/  %d.  %-36s  Example Library Python script used in this package\\\\2\\\\2\\\\1/g ; } ; \", ++idx, \"${scr_sbdr_esq2}\\\\/${_i%.py}.py:\") ;
    }
}"
                            local sedupdatecmd="${sedupdatecmd}$("${AWK:-awk}" -f <(echo "${readme_update_awkcmd}")  "${prefix}/${readme_name}" 2> /dev/null)"
                        done

                        local awkcmd1_header='^ *#{1,} *_{3,}readme_renumbering_awk_start_{3,} *#{1,}.*$'
                        local awkcmd1_footer='^ *#{1,} *_{3,}readme_renumbering_awk_end_{3,} *#{1,}.*$'
                        local readme_name_bak="${readme_name%.*}.$("${DATE:-date}" -r "${prefix}/${readme_name}" "+%Y%m%d_%H%M%S").${readme_name##*.}"
                        mv -i "${prefix}/${readme_name}" "${prefix}/${readme_name_bak}"
                        "${SED:-sed}" -E -e "/^- *Contents:/,/^- *Usage.*:/ { /^ *$/ {s/^ *$//g; x; s/^.*$//g ; x; h; }; ${sedupdatecmd} }" "${prefix}/${readme_name_bak}" \
                            | "${AWK:-awk}" -f <("${SED:-sed}" -nE -e '/'"${awkcmd1_header}"'/,/'"${awkcmd1_footer}"'/ {/('"${awkcmd1_header}"'|'"${awkcmd1_footer}"')/ d; p; }' "${rp_this}" 2>/dev/null) \
                                            1> "${prefix}/${readme_name}"  2> /dev/null
                        if [ ${opt_keepreadmebak:-0} -eq 0 ]; then
                            rm "${prefix}/${readme_name_bak}"
                        fi
                    fi
                fi

                local pipopt="--target ${module_dir%/}/${pip_pyver}"
                if [ "${#opt_module_install[@]}" -gt 0 ]; then
                    if [ ${opt_verbose:-0} -ne 0 ]; then
                        echo "install module : ${opt_module_install[@]}"
                        echo "${pip_path} install ${pipopt}" "${opt_module_install[@]}"
                    fi
                    if [ ${opt_dryrun:-0} -eq 0 ]; then
                        "${pip_path}" install ${pipopt} "${opt_module_install[@]}"
                    fi
                fi
                ;;
            install|download)
                if [ "${subcmd}" == "install" ]; then
                    local pipopt="--target ${module_dir%/}/${pip_pyver}"
                else
                    local pipopt="--dest ${module_dir%/}/${pip_pyver}"
                fi
                if [ ${opt_verbose:-0} -ne 0 ]; then
                    echo "${subcmd} module : ${subcmd_args[@]}"
                    echo "${pip_path} ${subcmd} ${pipopt} ${subcmd_args[@]}"
                fi
                if [ ${opt_dryrun:-0} -eq 0 ]; then
                    "${pip_path}" ${subcmd} ${pipopt} "${subcmd_args[@]}"
                fi
                cleanup
                return
                ;;
            clean)
                if [ ${opt_verbose:-0} -ne 0 ]; then
                    echo "Clean"
                    echo "exec rm -rf \"${subcmd_args[@]}\" \"${module_dir%/}/${pip_pyver%/}\""
                fi
                if [ ${opt_dryrun:-0} -eq 0 ]; then
                    rm -rf "${subcmd_args[@]}" "${module_dir%/}/${pip_pyver%/}"
                    cleanup
                    return 0
                fi
                ;;
            distclean|allclean|cleanall)
                if [ ${opt_verbose:-0} -ne 0 ]; then
                    echo "Distclean"
                    echo "exec rm -rf \"${subcmd_args[@]}\" \"${module_dir}\"/\*"
                fi
                if [ ${opt_dryrun:-0} -eq 0 ]; then
                    rm -rf "${subcmd_args[@]}" "${module_dir}"/*
                    cleanup
                    return
                fi
                ;;

            info)
                echo "Python command         : " ${python_cmd}
                echo "Python full path       : " ${python_path}
                echo "Top of work directory  : " ${prefix}
                echo "bin directory          : " ${bindir}
                echo "script directory       : " ${script_dir}
                echo "python moule directory : " ${module_dir}
                echo "PIP command            : " ${pip_cmd}
                echo "PIP full path          : " ${pip_path}
                ;;
            *)
                echo "Unknown sub-command: ${subcommand}"
                echo_usage
                return 1
                ;;
        esac
        cleanup
        return
    else

        local bindir="${prefix%/}/${bin_subdir%/}"
        local script_dir="${prefix%/}/${script_subdir%/}"
        local module_dir="${script_dir%/}/${module_subdir%/}"

        local script_path=
        if [ ${flgslnk:-0} -ne 0 ]; then
            # Script name is symboric name
            for script in "${runas%.py}".py "${runas}" ; do
                local script_path="${script_dir}/${script}"
                if [ -f "${script_path}" ]; then
                    break
                fi
                local script_path=
            done
            if [ -z "${script_path}" ]; then
                echo "[Error] ${this} : File not found. (${runas%.py}\{.py\} is not in ${script_dir})" 1>&2
                cleanup
                return 1
            fi
        elif [ $# -gt 0 ]; then
            local script="$(basename "${1%.py}" 2>/dev/null).py" || { local script="${1##*/}" ; local script="${script%.py}.py" ; }
            shift
            if [ -f "${script}" ]; then
                local script_path="${script}"
            elif [ "x${script:0:1}" != "x/" -a -f "${script_dir}/${script}" ]; then
                local script_path="${script_dir}/${script}"
            else
                echo "[Error] ${this} : File not found. (${script} is not in ${script_dir})" 1>&2
                cleanup
                return
            fi
        else
            echo "[Usage] % ${runas} python_script [arguments ... ]" 1>&2
            cleanup
            return
        fi

        #
        # Check shebang
        #
        local py_script=$("${SED:-sed}" -nE -e '1 {/^#\!/ s/^#\!((\/usr)?(\/bin\/)?env  *)?((.*)python(-?([0-9\.][0-9\.]*))?)(  *[^ ].*)?$/\4/gp;};q' "${script_path}")
        local py_scrver=$("${SED:-sed}" -nE -e '1 {/^#\!/ s/^#\!((\/usr)?(\/bin\/)?env  *)?((.*)python(-?([0-9\.][0-9\.]*))?)(  *[^ ].*)?$/\7/gp;};q' "${script_path}")

        if [ -z "${py_scrver}" ] ; then
            local py_mjrver=${python_major_version_default:-3}
        elif [ "${py_scrver%%.*}" -eq 3 ]; then
            local py_mjrver=3
        elif [ "${py_scrver%%.*}" -eq 2 ]; then
            local py_mjrver=2
        else
            local py_mjrver=${python_major_version_default:-3}
        fi

        if [ -n "${py_mjrver}" ] && command -v "${PYTHON:-${py_script:-python${py_mjrver}}}" 1>/dev/null 2>&1 ; then
            local python_path="$(command -v  "${PYTHON:-${py_script:-python${py_mjrver}}}")"
            local python_pyver="$("${python_path}" -c "import sys;print('%d.%d' % sys.version_info[0:2])")"
        elif command -v "${PYTHON:-${py_script:-python}}"  1>/dev/null 2>&1 ; then
            local python_path="$(command -v  "${PYTHON:-${py_script:-python}}")"
            local python_pyver="$("${python_path}" -c "import sys;print('%d.%d' % sys.version_info[0:2])")"
        else
            echo "[Error] ${this}: Can not find ${PYTHON:-${py_script:-python${py_mjrver}}} installed"
            cleanup
            return
        fi

        if [ -n "${py_scrver}" ] && [ "${py_scrver%%.*}" -ne "${python_pyver%%.*}" ]; then
            echo "Warning: Python version (${python_pyver}) mismatch?  (Version ${py_scrver%%.*}) is expexted by ${script_path})" 2>&1
        fi

        env PATH="${script_dir%/}/${python_pyver}:${script_dir%/}:${module_dir%/}/${python_pyver}/bin:${bin_dir}:${PATH}" \
            PYTHONPATH="${script_dir%/}/${python_pyver}:${script_dir%/}:${module_dir%/}/${python_pyver}:${PYTHONPATH}" \
            "${python_path}" "${script_path}" "${@}"
        cleanup
        return
    fi

    # clean up 
    cleanup
    return ${funcstatus}
    :
}

if [ "$0" == "${BASH_SOURCE:-$0}" ]; then
    # Invoked by command
    _runas="${0##*/}"

    # Define the wrapper function for py_canister
    # function name should be the default value of "${module_manage_name}"{,2,3}
    #
    function mng_pyenv() {
        py_canister "$@"
        return $?
    }
    
    function mng_pyenv2() {
        py_canister "$@"
        return $?
    }
    
    function mng_pyenv3() {
        py_canister "$@"
        return $?
    }

    if declare -F "${_runas%.sh}" 1>/dev/null 2>&1 ;  then
        "${_runas%.sh}" "$@"
        __status=$?
    else
        py_canister "$@"
        __status=$?
    fi
    unset _runas
    trap "unset __status" EXIT
    exit ${__status:-1}
else
    function undef_py_canister () {
        unset py_canister
        test -n "${py_canister_bk}" \
            &&  { local py_canister_bk="${py_canister_bk%\}}"' \\; }'; \
                  eval "${py_canister_bk//\; : \}/\; : \; \}}"  ; }

        unset mng_pyenv
        test -n "${mng_pyenv_bk}" \
            &&  { local mng_pyenv_bk="${mng_pyenv_bk%\}}"' \\; }'; \
                  eval "${mng_pyenv_bk//\; : \}/\; : \; \}}"  ; }

        unset mng_pyenv2
        test -n "${mng_pyenv2_bk}" \
            &&  { local mng_pyenv2_bk="${mng_pyenv2_bk%\}}"' \\; }'; \
                  eval "${mng_pyenv2_bk//\; : \}/\; : \; \}}"  ; }

        unset mng_pyenv3
        test -n "${mng_pyenv3_bk}" \
            &&  { local mng_pyenv3_bk="${mng_pyenv3_bk%\}}"' \\; }'; \
                  eval "${mng_pyenv3_bk//\; : \}/\; : \; \}}"  ; }

        unset undef_py_canister
        test -n "${undef_py_canister_bk}" \
            && { local undef_py_canister_bk="${undef_py_canister_bk%\}}"' \\; }'; \
                 eval "${undef_py_canister_bk//\; : \}/\; : \; \}}"  ; }

        unset py_canister_location
        unset py_canister_bk undef_py_canister_bk
        unset mng_pyenv_bk mng_pyenv2_bk mng_pyenv3_bk 

        return
        :
    }
    return
fi

# Contents below will be ignored. 

########## ____readme_renumbering_awk_start____ ##########
function idx2str ( idx0 ) {
    base=26 ; chr_offset=97 ;
    offset=0 ; factor=1 ; ostr="" ;
    do {
        digit = ((idx0-offset)/factor) % base ;
        ostr=sprintf("%c%s", digit+chr_offset,ostr) ;
        offset+=factor*base ;
        factor*=base ;
    } while ( idx0 >= offset )
    return ostr;
}
BEGIN {
    wn=0; wi=0; ln=0; idx=0; sidx=0;
}
/^ *- *Contents:/,/^ *- *Usage.*:/ {
    if ( $0 ~ /^ *[0-9]+\. +/       ) {
        ++idx ;
        sidx=0 ;
        sub("[0-9]+\.", sprintf("%d.", idx), $0) ;
    }
    if ( $0 ~ /^ *[0-9]+[a-z]+\. +/ ) { 
        sub("[0-9]+[a-z]+\.", sprintf("%d%s.", idx, idx2str(sidx)), $0);
        ++sidx ;
    }
    if ( match($0, /^ *[0-9]+[a-z]*\. *[^ ].*: */) ) {
        l_dsc_tail = length($0);
        l_dsc = l_dsc_tail-RLENGTH
        match($0, /^ *[0-9]+[a-z]*\. *[^ ].*:/);
        l_itm_tail=RLENGTH;
        match($0, /^ *[0-9]+[a-z]*\. */)
        l_itm = l_itm_tail-RLENGTH
        match($0, /^ *[0-9]+[a-z]*\./);
        l_idx_tail=RLENGTH;
        match($0, /^ */);
        l_idx=l_idx_tail-RLENGTH
        if ( l_idx > wn ) {
            wn = l_idx
        }
        if ( l_itm > wi ) {
            wi = l_itm
        } 
    }
} 
{ buf[ln++] = $0 ; }
END {
    roi=0;
    for(i=0;i<ln;++i){
        if (match(buf[i], /^ *- *Contents:/ ) ){
            roi=1;
        } else if ( match(buf[i], /^ *- *Usage.*:/  ) ){
            roi=0;
        } else if ( roi!=0 && match(buf[i], /^ *[0-9]+[a-z]*\. *[^ ].*: */) ) {
            l_dsc_tail = length(buf[i]);
            l_dsc = l_dsc_tail-RLENGTH
            dsc=sprintf("%s", substr(buf[i], RLENGTH+1, l_dsc));
            match(buf[i], /^ *[0-9]+[a-z]*\. *[^ ].*:/);
            l_itm_tail=RLENGTH;
            match(buf[i], /^ *[0-9]+[a-z]*\. */)
            l_itm = l_itm_tail-RLENGTH
            itm=sprintf("%s", substr(buf[i], RLENGTH+1, l_itm));
            match(buf[i], /^ *[0-9]+[a-z]*\./);
            l_idx_tail=RLENGTH;
            match(buf[i], /^ */);
            l_idx=l_idx_tail-RLENGTH
            idx=sprintf("%s", substr(buf[i], RLENGTH+1, l_idx));
            sub(/[^ ].*$/, sprintf("%-*s %-*s %s", wn, idx, wi, itm, dsc), buf[i]);
        }
        print buf[i];
    }
}
########## ____readme_renumbering_awk_end____ ##########

########## ____readme_template_start____ ##########
#
# ____TITLE____
#

Skeleton for small portable tools by python script

- Contents:

  1.  ____README_NAME____:                           This file
  2.  bin/____MNGSCRIPT_NAME____:                       Symblic link to '____SHSCRIPT_ENTITY_NAME____' for installing Python modules by pip locally.
  2a. bin/____MNGSCRIPT_NAME____2:                      Same as above using pip2 as default
  2b. bin/____MNGSCRIPT_NAME____3:                      Same as above using pip3 as default

  3.  bin/____SHSCRIPT_ENTITY_NAME____:                    Wrapper bash script to invoke Python script. (Entity)

  4.  lib/python/site-packages:            Directory where python modules are stored

  5.  lib/python/____SCRIPTNAME____.py:         Example Python script that use modules
  5a. lib/python/____SCRIPTNAME____2.py:        Same as above using python2 as default
  5b. lib/python/____SCRIPTNAME____3.py:        Same as above using python3 as default
@
  6.  bin/____SCRIPTNAME____:                   Symbolic link to '____SHSCRIPT_ENTITY_NAME____' to invoke ____SCRIPTNAME____.py.
  6a. bin/____SCRIPTNAME____2:                  Same as above using python2 as default
  6b. bin/____SCRIPTNAME____3:                  Same as above using python3 as default
@
  7.  .gitignore:                          Git-related file
  8.  lib/python/site-packages/____GITDUMMYFILE____:   Git-related file to keep modules directory in repository.
  
- Usage (Procedure for adding new script):

  1. Put new script under 'lib/python'.

     Example: 'lib/python/{newscriptname}.py'

  2. Make symbolic link to 'bin/____SHSCRIPT_ENTITY_NAME____' with same basename as the
     basename of new script.

      Example: 'bin/{newscriptname}' --> ____SHSCRIPT_ENTITY_NAME____

  3. Download external python module by './bin/____MNGSCRIPT_NAME____'

      Example: 'lib/python/{newscriptname}.py' uses modules, pytz and tzlocal.

      % ./bin/____MNGSCRIPT_NAME____ pytz tzlocal

      To install python module by specifying python/pip version,
      invoke '____MNGSCRIPT_NAME____2' or '____MNGSCRIPT_NAME____3'.

  4. Invoke the symbolic link made in step.2 for execute the script.

      % ./bin/{newscriptname}

- Caution:

  - Do not put python scripts/modules that are not managed by pip
    under 'lib/python/site-packages'.

    Otherwise those scripts/modules will be removed by
    `./bin/____MNGSCRIPT_NAME____ distclean`

- Note:

  - Python executable is seeked by the following order.

    1. Environmental variable: PYTHON
    2. Shebang in called python script
    3. python3 in PATH
    4. python  in PATH

    If you want to use python2 in prior instead of python3,
    change the value of shell variable \$\{python_major_version_default\}
    at the beginning of "____SHSCRIPT_ENTITY_NAME____"

    In other examples ({newscriptname}2.py, {newscriptname}3.py) are
    specifying the python version at the shebang (1st-line).
    It can be override by Environmental variable: PYTHON.

  - pip command is seeked by the following order.

    1. Environmental variable: PIP
    2. pip2 in PATH for "____MNGSCRIPT_NAME____2"
       pip3 in PATH for "____MNGSCRIPT_NAME____3"
    3. pip3 in PATH
    4. pip  in PATH

    If you want to use pip2 in prior instead of pip3 by "____MNGSCRIPT_NAME____",
    change the value of shell variable ${python_major_version_default}
    at the beginning of "____SHSCRIPT_ENTITY_NAME____"

- Requirements (Tools used in "____SHSCRIPT_ENTITY_NAME____")

  - bash
  - grep
  - sed
  - awk
  - GNU realpath (in GNU coreutils)
  - Python, PIP

- Author

  - ____AUTHOR_NAME____ (____AUTHOR_EMAIL____)

########## ____readme_template_end____ ##########

########## ____gitignore_template_start____ ##########
# .gitignore
*.py[cod]
*$py.class
# For emacs backup file
*~
lib/python/site-packages/*
!____GIT_DUMMYNAME____
########## ____gitignore_template_end____ ##########

######################################################################
#                                                                    #
#           Main python script template                              #
#                                                                    #
######################################################################

########## ____py_main_template_start____ ##########
#### ____py_shebang_pattern____ ####
# -*- coding: utf-8 -*-

import argparse
import datetime
import sys

import pytz
import tzlocal

#import pkg_structure

def main():
    """
    ____@@NAME@@____
    Example code skeleton: Just greeting
    """
    argpsr = argparse.ArgumentParser(description='Example: showing greeting words')
    argpsr.add_argument('name', nargs='*', type=str, default=['World'],  help='your name')
    argpsr.add_argument('-d', '--date', action='store_true', help='Show current date & time')
    args = argpsr.parse_args()
    if args.date:
        tz_local = tzlocal.get_localzone()
        datestr  = datetime.datetime.now(tz=tz_local).strftime(" It is \"%c.\"")
    else:
        datestr = ''

    print("Hello, %s!%s" % (' '.join(args.name), datestr))
    print("Python : %d.%d.%d " % sys.version_info[0:3]+ "(%s)" % sys.executable)
    hdr_str = "Python path: "
    for i,p in enumerate(sys.path):
        print("%-2d : %s" % (i+1, p))
        hdr_str = ""

    #pkg_info   = pkg_structure.PkgStructure(script_path=sys.argv[0])
    #pkg_info.dump(relpath=False, with_seperator=True)

if __name__ == '__main__':
    main()

########## ____py_main_template_end____ ##########

######################################################################
#                                                                    #
#           Library python script template                           #
#                                                                    #
######################################################################

########## ____py_lib_script_template_start____ ##########
#### ____py_shebang_pattern____ ####
# -*- coding: utf-8 -*-

import json

class ____@@NAME@@____(object):
    """
    ____@@NAME@@____
    Example class code skeleton: 
    """
    def __init__(self):
        self.contents = {}  

    def __repr__(self):
        return json.dumps(self.contents, ensure_ascii=False, indent=4, sort_keys=True)

    def __str__(self):
        return json.dumps(self.contents, ensure_ascii=False, indent=4, sort_keys=True)

if __name__ == '__main__':
    help(____@@NAME@@____)

########## ____py_lib_script_template_end____ ##########

######################################################################
#                                                                    #
#            Script python script template                           #
#                                                                    #
######################################################################

########## ____pkg_structure_template_start____ ##########
#### ____py_shebang_pattern____ ####
# -*- coding: utf-8 -*-

import os
import sys
import copy
import pathlib
import platform
import re
import json
import getpass

class PkgStructure(object):
    """
    Infer the directory structure of the software package from script path.
    """
    NONDIR_KEYS = ['pkg_name', 'exec_user',  
                   'base_script', 'script_mnemonic', 'script_path', 'script_basename']
    BASE_KEYS   = NONDIR_KEYS + ['pkg_path', 'script_location', 'prefix']

    def __init__(self, script_path=None, env_input=None, prefix=None, pkg_name=None,
                 flg_realpath=False, remove_tail_digits=True, remove_head_dots=True,
                 mimic_home=True, unnecessary_exts=['.sh', '.py', '.tar.gz'], **args):
        self.pkg_info = {}
        if isinstance(env_input, PkgStructure):
            self.pkg_info.update(env_input.pkg_info)
        elif isinstance(env_input, dict):
            self.pkg_info.update(env_input)
        else:
            PkgStructure.set_info(data=self.pkg_info, script_path=script_path, prefix=prefix, pkg_name=pkg_name,
                                  flg_realpath=flg_realpath, remove_tail_digits=remove_tail_digits, mimic_home=mimic_home,
                                  remove_head_dots=remove_head_dots, unnecessary_exts=unnecessary_exts, **args)

    def is_keyword(self, query):
        return query in self.pkg_info.keys()

    def is_dir_keyword(self, query):
        return ( ( query in self.pkg_info.keys() )
                 and ( not query in PkgStructure.NONDIR_KEYS ) )

    def make_subdirs(self, key, permission=0o755, exist_ok=True, *args):
        _path=self.concat_path(key, *args)
        os.makedirs(_path, mode=permission, exist_ok=exist_ok)
        return _path

    def concat_path(self, key, *args,
                    make_parents=False, dir_permission=0o755, exist_ok=True,
                    touch=False, permission=0o644, return_pathobj=False):

        if ( key in PkgStructure.BASE_KEYS ) or ( self.pkg_info.get(key) is None):
            raise ValueError("Invalid key %s PkgStructure::concat_path() accepts valid variable name except for PkgStructure.BASE_KEYS : %s" 
                             % (str(key), str(PkgStructure.BASE_KEYS)))

        _path = os.path.join(self.pkg_info[key], *args)

        if make_parents:
            os.makedirs(os.path.dirname(_path), mode=dir_permission, exist_ok=exist_ok)

        if touch:
            pathlib.Path(_path).touch(mode=permission, exist_ok=exist_ok)

        return pathlib.Path(_path) if return_pathobj else _path

    @classmethod
    def guess_pkgtop(cls, script_path, flg_realpath=False):
        _loc, _bn = cls.ana_script_location(script_path=script_path, flg_realpath=flg_realpath)
        _locpath = pathlib.Path(_loc)
        if _locpath.parts[-2:]==('lib', 'python'):
            _top=_locpath.parents[1]
        elif _locpath.parts[-1:]==('bin',):
            _top=_locpath.parents[0]
        else:
            _top=_locpath
        return _top

    @classmethod
    def guess_pkgname(cls, script_path, script_top, remove_tail_digits=True, remove_head_dots=True,
                      unnecessary_exts=['.sh', '.py', '.tar.gz']):
        _top_abs=pathlib.Path(os.path.abspath(script_top))
        _pkg_name = script_top.name
        if _pkg_name in [ '.', '..', '', '/',
                          'usr', 'local', 'opt', 'tmp', 'var', 'etc',
                          'User' if platform.system() == "Darwin" else 'home', None]:
            _pkg_name = cls.strip_aux_modifier(pathlib.Path(script_path).stem,
                                               remove_tail_digits=remove_tail_digits,
                                               remove_head_dots=remove_head_dots,
                                               unnecessary_exts=unnecessary_exts)
        return _pkg_name

    @classmethod
    def guess_pkg_info(cls, script_path, flg_realpath=False, remove_tail_digits=True, remove_head_dots=True):
        _pkg_top  = cls.guess_pkgtop(script_path=script_path, flg_realpath=flg_realpath)
        _pkg_name = cls.guess_pkgname(script_path=script_path, script_top=_pkg_top,
                                      remove_tail_digits=remove_tail_digits, remove_head_dots=remove_head_dots)
        if isinstance(_pkg_name, str) and len(_pkg_name)<1:
            _pkg_name = None

        return (_pkg_name, _pkg_top)

    @classmethod
    def ana_script_location(cls, script_path, flg_realpath=False):
        _scr_path = os.path.normpath(os.path.realpath(script_path) if flg_realpath else script_path)
        _loc,_bn  = os.path.split(_scr_path)
        return (_loc, _bn)

    @classmethod
    def strip_aux_modifier(cls, filename, remove_tail_digits=True, remove_head_dots=True,
                           unnecessary_exts=['.sh', '.py', '.tar.gz']):
        stripped=filename
        for ext in unnecessary_exts:
            if filename.endswith(ext):
                _m = filename[:-len(ext)]
                if len(_m)>0:
                    stripped=_m
                    break

        if remove_head_dots and stripped.startswith('.'):
            _m = stripped.lstrip('.')
            if len(_m)>0:
                stripped=_m

        if remove_tail_digits:
            _m = stripped.rstrip('0123456789.-_')
            if len(_m)>0:
                stripped=_m
        return stripped

    @classmethod
    def guess_script_info(cls, script_path, flg_realpath=False, remove_tail_digits=True,
                          remove_head_dots=True, unnecessary_exts=['.sh', '.py', '.tar.gz']):
        _loc, _bn     = cls.ana_script_location(script_path=script_path, flg_realpath=flg_realpath)
        _scr_mnemonic = cls.strip_aux_modifier(_bn, remove_tail_digits=remove_tail_digits,
                                               remove_head_dots=remove_head_dots,
                                               unnecessary_exts=unnecessary_exts)
        return (_bn, _loc, _scr_mnemonic)



    @classmethod
    def set_info(cls, data={}, script_path=None, prefix=None, pkg_name=None,
                 flg_realpath=False, remove_tail_digits=True, mimic_home=True,
                 remove_head_dots=True, unnecessary_exts=['.sh', '.py', '.tar.gz'], **args):

        _scr_path= ( str(script_path) if ( script_path is not None ) else 
                     ( sys.argv[0] if os.path.exists(sys.argv[0]) else  __file__ ))
        
        data['base_script']   = _scr_path
        _bn, _loc, _scr_mnemonic = cls.guess_script_info(script_path,
                                                         flg_realpath=flg_realpath, remove_tail_digits=remove_tail_digits,
                                                         remove_head_dots=remove_head_dots, unnecessary_exts=unnecessary_exts)

        data['script_path']     = os.path.realpath(script_path) if flg_realpath else script_path
        data['script_mnemonic'] = _scr_mnemonic
        data['script_location'] = _loc
        data['script_basename'] = _bn

        _pkg_name, _pkg_top = cls.guess_pkg_info(_scr_path, flg_realpath=flg_realpath,
                                                 remove_tail_digits=remove_tail_digits, remove_head_dots=remove_head_dots)

        data['pkg_path'] = str(_pkg_top)
        data['prefix']   = prefix   if isinstance(prefix, str)   else str(_pkg_top)
        data['pkg_name'] = pkg_name if isinstance(pkg_name, str) else _pkg_name

        # 

        data['exec_user'] = getpass.getuser()

        # Variables :  GNU Coding Standards + FHS inspired
        data['exec_prefix']    = data['prefix']
        data['bindir']         = os.path.join(data['prefix'], 'bin')
        data['datarootdir']    = os.path.join(data['prefix'], 'share')
        data['datadir']        = data['datarootdir']
        data['sysconfdir']     = os.path.join(data['prefix'], 'etc')
        data['sharedstatedir'] = os.path.join(data['prefix'], 'com')
        data['localstatedir']  = os.path.join(data['prefix'], 'var')
        data['include']        = os.path.join(data['prefix'], 'include')
        data['libdir']         = os.path.join(data['prefix'], 'lib')
        data['srcdir']         = os.path.join(data['prefix'], 'src')
        data['infodir']        = os.path.join(data['datarootdir'], 'info')
        data['runstatedir']    = os.path.join(data['localstatedir'], 'run')
        data['localedir']      = os.path.join(data['datarootdir'], 'locale')
        data['lispdir']        = os.path.join(data['prefix'], 'emacs', 'lisp')
        #
        if len(data['pkg_name'])>0:
            data['docdir']         = os.path.join(data['prefix'], 'doc', data['pkg_name'])
        else:
            data['docdir']         = os.path.join(data['prefix'], 'doc')
        data['htmldir']        = data['docdir']
        data['dvidir']         = data['docdir']
        data['pdfdir']         = data['docdir']
        data['psdir']          = data['docdir']
        #
        data['mandir']         = os.path.join(data['datarootdir'], 'man')
        for _i in range(10):
            data["man%ddir" % (_i)] = os.path.join(data['mandir'], "man%d" % (_i))
        data["manndir"] = os.path.join(data['mandir'], "mann")
        #
        data['sbindir']        = os.path.join(data['prefix'], 'sbin')
        data['bootdir']        = os.path.join(data['prefix'], 'boot')
        data['devdir']         = os.path.join(data['prefix'], 'dev')
        data['mediadir']       = os.path.join(data['prefix'], 'media')
        data['mntdir']         = os.path.join(data['prefix'], 'mnt')
        data['optdir']         = os.path.join(data['prefix'], 'opt')
        data['tmpdir']         = os.path.join(data['prefix'], 'tmp')

        data['xmldir']         = os.path.join(data['sysconfdir'], 'xml')
        data['etcoptdir']      = os.path.join(data['sysconfdir'], 'opt')

        data['cachedir']       = os.path.join(data['localstatedir'], 'cache')
        data['statedatadir']   = os.path.join(data['localstatedir'], 'lib')
        data['lockdir']        = os.path.join(data['localstatedir'], 'lock')
        data['logdir']         = os.path.join(data['localstatedir'], 'log')
        data['spooldir']       = os.path.join(data['localstatedir'], 'spool')
        data['statetmpdir']    = os.path.join(data['localstatedir'], 'tmp')

        #
        if mimic_home:
            pathobj_home    = pathlib.Path.home()
            path_home_parts = pathobj_home.relative_to(pathobj_home.anchor).parts
            data['user_home'] = os.path.join(data['prefix'], *path_home_parts)
        else:
            data['user_home'] = pathlib.Path.home()
        data['home']    = data['user_home']
        data['homedir'] = os.path.dirname(data['user_home'])
        #
        _pkg_subdir_keys = ['datadir', 'sysconfdir', 'runstatedir', 'include', 'libdir', 'srcdir',
                            'tmpdir', 'xmldir', 'cachedir', 'statedatadir', 'lockdir', 'logdir', 'spooldir', 'statetmpdir']
        if len(data['pkg_name'])>0:
            for k in _pkg_subdir_keys:
                data['pkg_'+k] = os.path.join(data[k], data['pkg_name'])
        else:
            for k in _pkg_subdir_keys:
                data['pkg_'+k] = data[k]

        for k,val in args.items():
            data[k] = val

        return data

    @property
    def base_script(self):
        return data.get('base_script',    _scr_path)

    @property
    def script_path(self):
        return self.pkg_info['script_path']

    @property
    def script_mnemonic(self):
        return self.pkg_info['script_mnemonic']

    @property
    def script_location(self):
        return self.pkg_info['script_location']

    @property
    def script_basename(self):
        return self.pkg_info['script_basename']

    @property
    def pkg_path(self):
        return self.pkg_info['pkg_path']

    @property
    def prefix(self):
        return self.pkg_info['prefix']

    @property
    def pkg_name(self):
        return self.pkg_info['pkg_name']

    @property
    def exec_prefix(self):
        return self.pkg_info.get('exec_prefix', self.pkg_info['prefix'])

    @property
    def bindir(self):
        return self.pkg_info.get('bindir', os.path.join(self.pkg_info['prefix'], 'bin'))

    @property
    def datarootdir(self):
        return self.pkg_info.get('datarootdir', os.path.join(self.pkg_info['prefix'], 'share'))

    @property
    def datadir(self):
        return self.pkg_info.get('datadir', self.datarootdir)

    @property
    def sysconfdir(self):
        return self.pkg_info.get('sysconfdir', os.path.join(self.pkg_info['prefix'], 'etc'))

    @property
    def sharedstatedir(self):
        return self.pkg_info.get('sharedstatedir', os.path.join(self.pkg_info['prefix'], 'com'))

    @property
    def localstatedir(self):
        return self.pkg_info.get('localstatedir', os.path.join(self.pkg_info['prefix'], 'var'))

    @property
    def include(self):
        return self.pkg_info.get('include', os.path.join(self.pkg_info['prefix'], 'include'))

    @property
    def libdir(self):
        return self.pkg_info.get('libdir', os.path.join(self.pkg_info['prefix'], 'lib'))

    @property
    def srcdir(self):
        return self.pkg_info.get('srcdir', os.path.join(self.pkg_info['prefix'], 'src'))

    @property
    def infodir(self):
        return self.pkg_info.get('infodir', os.path.join(self.datarootdir, 'info'))

    @property
    def runstatedir(self):
        return self.pkg_info.get('runstatedir', os.path.join(self.localstatedir, 'run'))

    @property
    def localedir(self):
        return self.pkg_info.get('localedir', os.path.join(self.datarootdir, 'locale'))

    @property
    def lispdir(self):
        return self.pkg_info.get('lispdir', os.path.join(self.pkg_info['prefix'], 'emacs', 'lisp'))

    @property
    def docdir(self):
        return self.pkg_info.get('docdir',
                                 os.path.join(self.pkg_info['prefix'], 'doc', self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else
                                 os.path.join(self.pkg_info['prefix'], 'doc'))
    @property
    def htmldir(self):
        return self.pkg_info.get('htmldir', self.docdir)

    @property
    def dvidir(self):
        return self.pkg_info.get('dvidir', self.docdir)

    @property
    def pdfdir(self):
        return self.pkg_info.get('pdfdir', self.docdir)

    @property
    def psdir(self):
        return self.pkg_info.get('psdir', self.docdir)

    @property
    def mandir(self):
        return self.pkg_info.get('mandir', os.path.join(self.datarootdir, 'man'))

    @property
    def man1dir(self):
        return self.pkg_info.get('man1dir',  os.path.join(self.mandir, 'man1'))

    @property
    def man2dir(self):
        return self.pkg_info.get('man2dir',  os.path.join(self.mandir, 'man2'))

    @property
    def man3dir(self):
        return self.pkg_info.get('man3dir',  os.path.join(self.mandir, 'man3'))

    @property
    def man4dir(self):
        return self.pkg_info.get('man4dir',  os.path.join(self.mandir, 'man4'))

    @property
    def man5dir(self):
        return self.pkg_info.get('man5dir',  os.path.join(self.mandir, 'man5'))

    @property
    def man6dir(self):
        return self.pkg_info.get('man6dir',  os.path.join(self.mandir, 'man6'))

    @property
    def man7dir(self):
        return self.pkg_info.get('man7dir',  os.path.join(self.mandir, 'man7'))

    @property
    def man8dir(self):
        return self.pkg_info.get('man8dir',  os.path.join(self.mandir, 'man8'))

    @property
    def man9dir(self):
        return self.pkg_info.get('man9dir',  os.path.join(self.mandir, 'man9'))

    @property
    def manndir(self):
        return self.pkg_info.get('manndir',  os.path.join(self.mandir, 'mann'))

    @property
    def sbindir(self):
        return self.pkg_info.get('sbindir', os.path.join(self.prefix, 'sbin'))

    @property
    def bootdir(self):
        return self.pkg_info.get('bootdir', os.path.join(self.prefix, 'boot'))

    @property
    def devdir(self):
        return self.pkg_info.get('devdir', os.path.join(self.prefix, 'dev'))

    @property
    def homedir(self):
        return self.pkg_info.get('homedir', os.path.join(self.prefix, 'home'))

    @property
    def mediadir(self):
        return self.pkg_info.get('mediadir', os.path.join(self.prefix, 'media'))

    @property
    def mntdir(self):
        return self.pkg_info.get('mntdir', os.path.join(self.prefix, 'mnt'))

    @property
    def optdir(self):
        return self.pkg_info.get('optdir', os.path.join(self.prefix, 'opt'))

    @property
    def tmpdir(self):
        return self.pkg_info.get('tmpdir', os.path.join(self.prefix, 'tmp'))

    @property
    def xmldir(self):
        return self.pkg_info.get('xmldir', os.path.join(self.sysconfdir, 'xml'))

    @property
    def cachedir(self):
        return self.pkg_info.get('cachedir', os.path.join(self.localstatedir, 'cache'))

    @property
    def statedatadir(self):
        return self.pkg_info.get('statedatadir', os.path.join(self.localstatedir, 'lib'))

    @property
    def lockdir(self):
        return self.pkg_info.get('lockdir', os.path.join(self.localstatedir, 'lock'))

    @property
    def logdir(self):
        return self.pkg_info.get('logdir', os.path.join(self.localstatedir, 'log'))

    @property
    def spooldir(self):
        return self.pkg_info.get('spooldir', os.path.join(self.localstatedir, 'spool'))

    @property
    def statetmpdir(self):
        return self.pkg_info.get('statetmpdir', os.path.join(self.localstatedir, 'tmp'))

    @property
    def pkg_datadir(self):
        return self.pkg_info.get('pkg_datadir',
                                 os.path.join(self.datadir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.datadir)

    @property
    def pkg_sysconfdir(self):
        return self.pkg_info.get('pkg_sysconfdir',
                                 os.path.join(self.sysconfdir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.sysconfdir)

    @property
    def pkg_runstatedir(self):
        return self.pkg_info.get('pkg_runstatedir',
                                 os.path.join(self.runstatedir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.runstatedir)

    @property
    def pkg_include(self):
        return self.pkg_info.get('pkg_include',
                                 os.path.join(self.include, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.include)

    @property
    def pkg_libdir(self):
        return self.pkg_info.get('pkg_libdir',
                                 os.path.join(self.libdir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.libdir)

    @property
    def pkg_srcdir(self):
        return self.pkg_info.get('pkg_srcdir',
                                 os.path.join(self.srcdir, self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.srcdir)
    @property
    def pkg_sbindir(self):
        return self.pkg_info.get('pkg_sbindir',
                                 os.path.join(self.sbindir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.sbindir)

    @property
    def pkg_tmpdir(self):
        return self.pkg_info.get('pkg_tmpdir',
                                 os.path.join(self.tmpdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.tmpdir)

    @property
    def pkg_xmldir(self):
        return self.pkg_info.get('pkg_xmldir',
                                 os.path.join(self.xmldir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.xmldir)

    @property
    def pkg_cachedir(self):
        return self.pkg_info.get('pkg_cachedir',
                                 os.path.join(self.cachedir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.cachedir)

    @property
    def pkg_statedatadir(self):
        return self.pkg_info.get('pkg_statedatadir',
                                 os.path.join(self.statedatadir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.statedatadir)

    @property
    def pkg_lockdir(self):
        return self.pkg_info.get('pkg_lockdir',
                                 os.path.join(self.lockdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.lockdir)

    @property
    def pkg_logdir(self):
        return self.pkg_info.get('pkg_logdir',
                                 os.path.join(self.logdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.logdir)

    @property
    def pkg_spooldir(self):
        return self.pkg_info.get('pkg_spooldir',
                                 os.path.join(self.spooldir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.spooldir)

    @property
    def pkg_statetmpdir(self):
        return self.pkg_info.get('pkg_statetmpdir',
                                 os.path.join(self.statetmpdir,self.pkg_info['pkg_name'])
                                 if len(self.pkg_info['pkg_name'])>0 else self.statetmpdir)

    def __repr__(self):
        return json.dumps(self.pkg_info, ensure_ascii=False, indent=4, sort_keys=True)

    def __str__(self):
        return json.dumps(self.pkg_info, ensure_ascii=False, indent=4, sort_keys=True)

    def dump(self, relpath=True, with_seperator=True):
        base_info = ['pkg_name', 'pkg_path', '', 'base_script', '',
                     'script_mnemonic', 'script_path', 'script_location', 'script_basename', '', 'prefix', '', 'exec_user', '']
        tlmax = max([len(i) for i in base_info])
        seperator = '-'*70
        for k in base_info:
            if len(k)>0:
                print ( "%-*s %s" % (tlmax+4, "'"+k+"'"':', self.pkg_info[k]))
            elif with_seperator:
                print (seperator)

        # dlist1 = list(set(self.pkg_info.keys()) - set(base_info))
        dlist0 = [ k for k in self.pkg_info.keys() if not k in base_info ]
        dlist1 = [ k for k in dlist0 if not k.startswith('pkg_')]
        dlist2 = [ k for k in dlist0 if     k.startswith('pkg_')]
        tlmax = max([len(i) for i in dlist0])

        for k in dlist1+['']+dlist2+['']:
            if len(k)<1:
                if with_seperator:
                    print (seperator)
                continue
            if relpath:
                try:
                    _path = pathlib.Path(self.pkg_info[k]).relative_to(self.pkg_info['prefix'])
                    if len(str(_path))>0 and (not str(_path) == '.' ):
                        _path = os.path.join("'${prefix}'", _path)
                    else:
                        _path = "'${prefix}'"
                except ValueError:
                    _path = self.pkg_info[k]
            else:
                _path = self.pkg_info[k]
            print ( "%-*s %s" % (tlmax+4, "'"+k+"'"':', _path))

if __name__ == '__main__':
    import sys
    import argparse
    argpsr = argparse.ArgumentParser(description='Assigning the package directory structure/names',
                                     epilog='Directory structure/names are inspired by GNU Coding Standards and FHS')
    argpsr.add_argument('-H', '-C', '--class-help', action='store_true', help='show class help')
    argpsr.add_argument('-r', '--relative-path', action='store_true', help='show with relative path (default)')
    argpsr.add_argument('-a', '--absolute-path', action='store_true', help='show with absolute path')
    argpsr.add_argument('-S', '--without-separator', action='store_true', help='show without seperators')
    argpsr.add_argument('-s', '--with-separator',    action='store_true', help='show with seperators (default)')
    argpsr.add_argument('-j', '--json',              action='store_true', help='Show with JSON format')
    argpsr.add_argument('-N', '--non-mimic-home',    action='store_true', help='Not mimic home')

    argpsr.add_argument('filenames', nargs='*')
    args=argpsr.parse_args()
    if args.class_help:
        help(PkgStructure)
    else:
        for __f in args.filenames if len(args.filenames)>1 else sys.argv[:1]:
            __pkg_info=PkgStructure(script_path=__f, prefix=None, pkg_name=None,
                                    flg_realpath=False, remove_tail_digits=True,
                                    mimic_home=(not args.non_mimic_home),
                                    remove_head_dots=True, unnecessary_exts=['.sh', '.py', '.tar.gz'])
            if args.json:
                print(json.dumps(__pkg_info.pkg_info, ensure_ascii=False, indent=4, sort_keys=True))
            else:
                __pkg_info.dump(relpath=(not args.absolute_path), with_seperator=(not args.without_separator))


########## ____pkg_structure_template_end____ ##########

#######################################################################
##
## Optional python template;
##     Example of named template to contain multiple python tamplate.
##
##   If there is the line with '########## ____{scriptname}_template_start____ ##########'
## and the line with '########## ____{scriptname}_template_end____ ##########'
## where '{scriptname}' is arguments for 'init' or 'add' sub-command,
## the interval of these lines is used for the script template.
##
## This can be used to distribute multiple python scripts at once as follows.
##
## % py_canister --manage -p /destination -g -r -t 'Project name' -3 -m pytz -m tzlocal init py_scriptA py_scriptB
##
########## ____py_scriptA_template_start____ ##########
#### ____py_shebang_pattern____ ####
## -*- coding: utf-8 -*-
#import datetime
#import sys
#
#import pytz
#import tzlocal
#
#def main():
#    """
#    Example code skeleton: Script-A
#    """
#    tz_local = tzlocal.get_localzone()
#    datestr  = datetime.datetime.now(tz=tz_local).strftime(" It is \"%c.\"")
#    print("Hello, This is Script-A : %s" % (datestr))
#    print("Python : %d.%d.%d " % sys.version_info[0:3]+ "(%s)" % sys.executable)
#    hdr_str = "Python path: "
#    for i,p in enumerate(sys.path):
#        print("%-2d : %s" % (i+1, p))
#        hdr_str = ""
#if __name__ == '__main__':
#    main()
########## ____py_scriptA_template_end____ ##########
#
########## ____py_scriptB_template_start____ ##########
#### ____py_shebang_pattern____ ####
## -*- coding: utf-8 -*-
#import datetime
#import sys
#
#import pytz
#import tzlocal
#
#def main():
#    """
#    Example code skeleton: Script-B
#    """
#    tz_local = tzlocal.get_localzone()
#    datestr  = datetime.datetime.now(tz=tz_local).strftime(" It is \"%c.\"")
#    print("Hello, This is Script-B : %s" % (datestr))
#    print("Python : %d.%d.%d " % sys.version_info[0:3]+ "(%s)" % sys.executable)
#    hdr_str = "Python path: "
#    for i,p in enumerate(sys.path):
#        print("%-2d : %s" % (i+1, p))
#        hdr_str = ""
#if __name__ == '__main__':
#    main()
########## ____py_scriptB_template_end____ ##########

########## ____pkg_cache_template_start____ ##########
#### ____py_shebang_pattern____ ####
# -*- coding: utf-8 -*-
import gzip
import bz2
import re
import os
import sys
import json
import filecmp

import yaml

import intrinsic_format
import pkg_structure

class PkgCache(pkg_structure.PkgStructure):
    """
    Class for Data cache for packaged directory
    """
    def __init__(self, subdirkey='pkg_cachedir', subdir=None, 
                 dir_perm=0o755, perm=0o644, keep_oldfile=False, backup_ext='.bak',
                 timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True,
                 script_path=None, env_input=None, prefix=None, pkg_name=None,
                 flg_realpath=False, remove_tail_digits=True, remove_head_dots=True, 
                 basename=None, tzinfo=None, unnecessary_exts=['.sh', '.py', '.tar.gz'],
                 namespece=globals(), yaml_register=True, **args):

        super().__init__(script_path=script_path, env_input=env_input, prefix=prefix, pkg_name=pkg_name,
                         flg_realpath=flg_realpath, remove_tail_digits=remove_tail_digits, remove_head_dots=remove_head_dots, 
                         unnecessary_exts=unnecessary_exts, **args)

        self.config = { 'dir_perm':                 dir_perm,
                        'perm':                     perm,
                        'keep_oldfile':             keep_oldfile,
                        'backup_ext':               backup_ext,
                        'timestampformat':          timestampformat,
                        'avoid_duplicate':          avoid_duplicate
                        'json:skipkeys':            False,
                        'json:ensure_ascii':        False, # True,
                        'json:check_circular':      True, 
                        'json:allow_nan':           True,
                        'json:indent':              4, # None,
                        'json:separators':          None,
                        'json:default':             None,
                        'json:sort_keys':           True, # False,
                        'json:parse_float':         None,
                        'json:parse_int':           None,
                        'json:parse_constant':      None,
                        'json:object_pairs_hook':   None,
                        'yaml:stream':              None,
                        'yaml:default_style':       None,
                        'yaml:default_flow_style':  None,
                        'yaml:encoding':            None,
                        'yaml:explicit_start':      True, # None,
                        'yaml:explicit_end':        True, # None,
                        'yaml:version':             None,
                        'yaml:tags':                None,
                        'yaml:canonical':           True, # None,
                        'yaml:indent':              4, # None,
                        'yaml:width':               None,
                        'yaml:allow_unicode':       None,
                        'yaml:line_break':          None
                       }

        if isinstance(subdir,list) or isinstance(subdir,tuple):
            _subdir = [ str(sd) for sd in subdir]
            self.cache_dir = self.concat_path(skey, *_subdir)
        elif subdir is not None:
            self.cache_dir = self.concat_path(skey, str(subdir))
        else:
            self.cache_dir = self.concat_path(skey)

        self.intrinsic_formatter = intrinsic_format.intrinsic_formatter(namespace=namespace,
                                                                        register=yaml_register)

    def read(self, fname, default=''):
        return self.read_cache(fname, default='', directory=self.cache_dir)

    def save(self, fname, data):
        return self.save_cache(fname, data, directory=self.cache_dir, **self.config)

    @classmethod
    def save_cache(cls, fname, data, directory='./cache', dir_perm=0o755,
                   keep_oldfile=False, backup_ext='.bak', 
                   timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True):
        """ function to save data to cache file
        fname     : filename
        data      : Data to be stored
        directory : directory where the cache is stored. (default: './cache')
    
        Return value : file path of cache file
                       None when fail to make cache file
        """
        data_empty = True if (((isinstance(data, str) or isinstance(data, bytes) or
                                isinstance(data, dict) or isinstance(data, list) or
                                isinstance(data, tuple) ) and len(data)==0)
                              or isinstance(data, NoneType) ) else False
        if data_empty:
            return None
        if not os.path.isdir(directory):
            os.makedirs(directory, mode=dir_perm, exist_ok=True)
        o_path = os.path.join(directory, fname)
        ext1, ext2, fobj = cls.open_autoassess(o_path, 'w',
                                               keep_oldfile=keep_oldfile,
                                               backup_ext=backup_ext, 
                                               timestampformat=timestampformat,
                                               avoid_duplicate=avoid_duplicate)
        if fobj is None:
            return None

        if ext2 == 'yaml':
            #f.write(yaml.dump(data))
            f.write(self.intrinsic_formatter.dump_json(data, 
                                                       skipkeys=self.config['json:skipkeys'],
                                                       ensure_ascii=self.config['json:ensure_ascii'],
                                                       check_circular=self.config['json:check_circular'],
                                                       allow_nan=self.config['json:allow_nan'],
                                                       indent=self.config['json:indent'],
                                                       separators=self.config['json:separators'],
                                                       default=self.config['json:default'],
                                                       sort_keys=self.config['json:sort_keys']))
        elif ext2 == 'json':
            #f.write(json.dumps(data, ensure_ascii=False))
            f.write(self.intrinsic_formatter.dump_yaml(data,
                                                       stream=self.config['yaml:stream'],
                                                       default_style=self.config['yaml:default_style'],
                                                       default_flow_style=self.config['yaml:default_flow_style'],
                                                       encoding=self.config['yaml:encoding'],
                                                       explicit_start=self.config['yaml:explicit_start'],
                                                       explicit_end=self.config['yaml:explicit_end'],
                                                       version=self.config['yaml:version'],
                                                       tags=self.config['yaml:tags'],
                                                       canonical=self.config['yaml:canonical'],
                                                       indent=self.config['yaml:indent'],
                                                       width=self.config['yaml:width'],
                                                       allow_unicode=self.config['yaml:allow_unicode'],
                                                       line_break=self.config['yaml:line_break'])
        else:
            f.write(data)
        f.close()

        os.path.chmod(o_path, mode=perm)
        return o_path

    @classmethod
    def backup_by_rename(cls, orig_path, backup_ext='.bak',
                         timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True):
        if not os.path.lexists(orig_path):
            return
        path_base, path_ext2 = os.path.splitext(orig_path)
        if path_ext2 in ['.bz2', '.gz']:
            path_base, path_ext = os.path.splitext(path_base)
        else:
            path_ext2, path_ext = ('', path_ext2)
        if path_ext == backup_ext and len(path_base)>0:
            path_base, path_ext = os.path.splitext(path_base)
        if isinstance(timestampformat, str) and len(timestampformat)>0:
            mtime_txt = '.' + datetime.datetime.fromtimestamp(os.lstat(orig_path).st_mtime).strftime(timestampformat)
        else:
            mtime_txt = ''

        i=0
        while(True):
            idx_txt = ( ".%d" % (i) ) if i>0 else ''
            bak_path = path_base + mtime_txt + idx_txt + path_ext  + backup_ext + path_ext2
            if os.path.lexists(bak_path):
                if avoid_duplicate and filecmp.cmp(orig_path, bak_path, shallow=False):
                    os.unlink(bak_path)
                else:
                    continue
            os.rename(orig_path, bak_path)
            break

            
    @classmethod
    def open_autoassess(cls, path, mode, 
                        keep_oldfile=False, backup_ext='.bak', 
                        timestampformat="%Y%m%d_%H%M%S", avoid_duplicate=True):

        """ function to open normal file or file compressed by gzip/bzip2
            path : file path
            mode : file open mode 'r' or 'w'
    
            Return value: (1st_extension: bz2/gz/None,
                           2nd_extension: yaml/json/...,
                           opend file-io object or None)
        """
        if 'w' in mode or 'W' in mode:
            modestr = 'w'
            if keep_oldfile:
                cls.backup_by_rename(path, backup_ext=backup_ext,
                                     timestampformat=timestampformat,
                                     avoid_duplicate=avoid_duplicate)
        elif 'r' in mode  or 'R' in mode:
            modestr = 'r'
            if not os.path.isfile(path):
                return (None, None, None)
        else:
            raise ValueError("mode should be 'r' or 'w'")

        base, ext2 = os.path.splitext(path)
        if ext2 in ['.bz2', '.gz']:
            base, ext1 = os.path.splitext(path_base)
        else:
            ext1, ext2 = (ext2, '')

        if ext2 == 'bz2':
            return (ext2, ext1, bz2.BZ2File(path, modestr+'b'))
        elif ext2 == 'gz':
            return (ext2, ext1, gzip.open(path, modestr+'b'))
        return (ext2, ext1, open(path, mode))

    @classmethod
    def read_cache(cls, fname, default='', directory='./cache'):
        """ function to read data from cache file
        fname      : filename
        default   : Data when file is empty (default: empty string)
        directory : directory where the cache is stored. (default: ./cache)
    
        Return value : data    when cache file is exist and not empty,
                       default otherwise
        """
        if not os.path.isdir(directory):
            return default
        in_path = os.path.join(directory, fname)
        ext1, ext2, fobj = cls.open_autoassess(in_path, 'r')
        if fobj is None:
            return default
        f_size = os.path.getsize(in_path)

        data = default
        if ((ext1 == 'bz2' and f_size > 14) or
            (ext1 == 'gz'  and f_size > 14) or
            (ext1 != 'bz2' and ext1 != 'gz' and f_size > 0)):
            if ext2 == 'yaml' or ext2 == 'YAML':
                #data = yaml.load(fobj)
                data = self.intrinsic_formatter.load_json(fobj,
                                                          parse_float=self.config['json:parse_float'],
                                                          parse_int=self.config['json:parse_int'],
                                                          parse_constant=self.config['json:parse_constant'],
                                                          object_pairs_hook=self.config['json:object_pairs_hook'])
            elif ext2 == 'json'or ext2 == 'JSON':
                # data = json.load(fobj)
                data = self.intrinsic_formatter.load_yaml(fobj)
            else:
                data = fobj.read()
        f.close()
        return data
    

if __name__ == '__main__':
    help(__name__)


########## ____pkg_cache_template_end____ ##########
