#!/bin/bash
# -*- mode: shell-script ; -*-
#
# update_template: Update template part of file.
#

if [ "$0" != "${BASH_SOURCE:-$0}" ]; then
    __update_template_bk__="$(declare -f update_template)"
    __undef_update_template_bk__="$(declare -f undef_update_template)"

    if declare -F which_source 1>/dev/null 2>&1 ; then
        __update_template_location__="$(which_source "${BASH_SOURCE}")"
    else
        for ___i in "which_source" "$(dirname "${BASH_SOURCE}")/which_source.sh" "which_source.sh" "${REALPATH:-realpath}" "grealpath" ; do
            which -s "${___i}" && {  __update_template_location__="$("${___i}" "${BASH_SOURCE}")" ; break ; }
        done
        unset ___i
    fi
    if [ -z "${__update_template_location__}" ]; then
        ___i="$(dirname "${BASH_SOURCE}")"
        ___adir="$(cd "${___i}" 2>/dev/null && pwd -L || echo "${___i}")"
        __update_template_location__="${_adir%/}/${BASH_SOURCE##*/}"
        unset ___i ___adir
    fi
fi

function update_template () {
    # Description
    local desc="Update template part of file"

    local funcstatus=0 tmpfiles=() tmpdirs=()
    local echo_usage_bk="$(declare -f echo_usage)"
    local cleanup_bk="$(declare -f cleanup)"

    function  echo_usage () {
        if [ "$0" == "${BASH_SOURCE:-$0}" ]; then
            local this="$0"
        else
            local this="${FUNCNAME[1]}"
        fi
        echo "[Usage] % $(basename ${this}) options"                       1>&2
        echo "    ---- ${desc}"                                            1>&2
        echo "[Options]"                                                   1>&2
        echo "           -b path   : Directory to store backup files"      1>&2
        echo "           -i path   : Directory for input template files"   1>&2
        echo "           -o path   : Set output file (default input file)" 1>&2
        echo "           -v        : Show verbose messages"                1>&2
        echo "           -h        : Show Help (this message)"             1>&2
        return
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
        
        # remove temporary files and directories
        [ ${#tmpfiles} -gt 0 ] &&  rm -f "${tmpfiles[@]}"
        [ ${#tmpdirs}  -gt 0 ] &&  rm -rf "${tmpdirs[@]}"

        # Restore  signal handler
        [ -n "${hndlrhup_bk}"  ] && eval "${hndlrhup_bk}"  || trap --  1
        [ -n "${hndlrint_bk}"  ] && eval "${hndlrint_bk}"  || trap --  2
        [ -n "${hndlrquit_bk}" ] && eval "${hndlrquit_bk}" || trap --  3
        [ -n "${hndlrterm_bk}" ] && eval "${hndlrterm_bk}" || trap -- 15

        # Restore alias and functions

        unset echo_usage
        [ -n "${echo_usage_bk}" ] && { local echo_usage_bk="${echo_usage_bk%\}}"' \\; }'; eval "${echo_usage_bk//\; : \}/\; : \; \}}" ; }
        unset cleanup
        [ -n "${cleanup_bk}"    ] && { local cleanup_bk="${cleanup_bk%\}}"' \\; }'      ; eval "${cleanup_bk//\; : \}/\; : \; \}}"    ; }

        return
        :
    }

    # Analyze command line options
    local OPT OPTARG OPTIND
    local backupdir="backup"
    local inputdir="input"
    local python_cmd="${PYTHON:-python3}"
    local verbose=0
    local py_template_shebang='#### ____py_shebang_pattern____ ####'

    while getopts "b:i:P:vh" OPT;  do
        case ${OPT} in
            b) local backupdir="${OPTARG}" ;;
            i) local inputdir="${OPTARG}" ;;
            p) local python_cmd="${OPTARG}" ;;
            v) local verbose=1 ;;
            h)  echo_usage ; cleanup ; return 0 ;;
            \?) echo_usage ; cleanup ; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    
    local scriptpath="${BASH_SOURCE:-$0}"
    local scriptdir="$(dirname "${scriptpath}")"
    if [ "$0" == "${BASH_SOURCE:-$0}" ]; then
        local this="$(basename "${scriptpath}")"
    else
        local this="${FUNCNAME[0]}"
    fi

    #local tmpdir0="$("${MKTEMP:-mktemp}" -d "${this}.tmp.XXXXXX" )"
    #local tmpdirs=( "${tmpdirs[@]}" "${tmpdir0}" )
    #local tmpfile0="$("${MKTEMP:-mktemp}"   "${this}.tmp.XXXXXX" )"
    #local tmpfiles=( "${tmpfiles[@]}" "${tmpfile0}" )

    "${MKDIR:-mkdir}" -p "${backupdir}"
    "${MKDIR:-mkdir}" -p "${inputdir}"

    local target=
    for target in "$@"; do
        [ -f "${target}" ] || continue
        
        local backupdir_path="${backupdir}/${target}"
        local inputdir_path="${inputdir}/${target}"

        "${MKDIR:-mkdir}" -p "${backupdir_path}"
        "${MKDIR:-mkdir}" -p "${inputdir_path}"

        local in_tmstmp="$( ${DATE:-date} -r "${target}" "+%Y%m%d%H%M.%S" )"
        local in_tmstmp_ext="$( ${DATE:-date} -r "${target}" "+%Y%m%d%H%M%S" )"
        local in_mtime="$( ${DATE:-date} -r "${target}" "+%s")"
        local in_perm="$("${STAT:-stat}" -L -f "%0p" "${target}" )"
        # echo "${target}" "${in_tmstmp}"

        local tgt_snm="${target##*/}"
        if [ -z "${tgt_snm%.*}" -o -z "${tgt_snm##*.}" ]; then
            local tgt_snm_b="${tgt_snm}"
            local tgt_snm_e=""
        else
            local tgt_snm_b="${tgt_snm%.*}"
            if [ "${tgt_snm_b}" == "${tgt_snm}" ]; then
                local tgt_snm_e=""
            else
                local tgt_snm_e=".${tgt_snm##*.}"
            fi
        fi

        local bkup_name="${tgt_snm_b}.${in_tmstmp_ext}${tgt_snm_e}"
        local bkup_path="${backupdir}/${bkup_name}"
        if [ -f "${bkup_path}" ]; then
            if "${DIFF:-diff}" -q "${bkup_path}" "${target}" 1>/dev/null 2>&1 ; then
                if [ ${verbose:-0} -ne 0 ]; then
                    echo "Backup file for ${target}: already exist and same contents (${bkup_path}) : skip" 1>&2 
                fi
            else
                local _idx=0 _flg=0
                for ((_idx=0;_idx<1000;++_idx)); do
                    local bkup_name="${tgt_snm_b}.${in_tmstmp_ext}-${_idx}${tgt_snm_e}"
                    local bkup_path="${backupdir}/${bkup_name}"
                    if [ -f "${bkup_path}" ] ; then
                        if "${DIFF:-diff}" -q "${bkup_path}" "${target}" 1>/dev/null 2>&1 ; then
                            if [ ${verbose:-0} -ne 0 ]; then
                                echo "Backup file for ${target}: already exist and same contents (${bkup_path}) : skip" 1>&2 
                            fi
                            break
                        fi
                    else
                        "${CP:-cp}" -ai "${target}" "${bkup_path}"
                        break
                    fi
                done
            fi
        else
            "${CP:-cp}" -ai  "${target}" "${bkup_path}"
        fi

        local py_shebang_pattern="$("${SED:-sed}" -nE -e '/^ *(local *)?py_shebang_pattern=.*/ s/^ *(local *)?py_shebang_pattern=["'"'"'](.*)["'"'"'] *$/\2/gp' "${target}")"

        local start_markers="$("${SED:-sed}" -E -n -e '/^ *#{1,} *_{3,}.*_template_start_{3,} *#{1,}/ s/^ *#{1,} *_{3,}(.*)_template_start_{3,} *#{1,}.*$/\1/pg' "${target}" | tr "\n" " ")"
        local chkd_markers=() mrkr= mout=
        for mrkr in ${start_markers[@]}; do 
            local mout="$("${SED:-sed}" -n -E -e \
                          '/^ *#{1,} *_{3,}'"${mrkr}"'_template_end_{3,} *#{1,}/ s/^ *#{1,} *_{3,}('"${mrkr}"')_template_end_{3,} *#{1,}.*$/\1/pg' \
                          "${target}" | tr "\n" " ")"
            [ -n "${mout}" ] && local chkd_markers=( "${chkd_markers[@]}" "${mout}" )
        done
        #echo "${chkd_markers[@]}"

        local py_shebang_str='#!/usr/bin/env '"$(basename "${python_cmd}")"
        local template_name=
        for template_name in ${chkd_markers[@]}; do
            # echo "${template_name}"
            local head_mrkr='^ *#{1,} *_{3,}'"${template_name}"'_template_start_{3,} *#{1,}'
            local tail_mrkr='^ *#{1,} *_{3,}'"${template_name}"'_template_end_{3,} *#{1,}'

            local tmpfile0="$("${MKTEMP:-mktemp}" "${this}.tmp.XXXXXX" )"
            local tmpfiles=( "${tmpfiles[@]}" "${tmpfile0}" )

            local template_ext=
            local latest_backup=

	        "${SED:-sed}" -nE -e "/${head_mrkr}/,/${tail_mrkr}/ {/${head_mrkr}/ n; /${tail_mrkr}/ q ; p ; }"  "${target}" > "${tmpfile0}"
            { head -1 "${tmpfile0}" | "${GREP:-grep}" -q -E -e "${py_shebang_pattern}" -e '^#!.*python' ; } && local template_ext=".py" \
                    || local template_ext="$( "${SED:-sed}" -nE -e '1 { s=^#!/.*/(.*sh)[ ].*$/=.\1=pg ; q ; }' "${tmpfile0}")"
            local backup_path="${backupdir_path}/${template_name}.${in_tmstmp_ext}${template_ext}"
            local backup_files=()
            local backup_files=( $("${LS:-ls}" -t "${backupdir_path}/${template_name}."*"${template_ext}" 2> /dev/null ) ) 2> /dev/null
            if [ -f "${backup_path}" ]; then
                local latest_backup="${backup_files[0]}"
            else
                "${SED:-sed}" -E -e "1 s=${py_shebang_pattern}=${py_shebang_str}=g" "${tmpfile0}" > "${backup_path}"
                touch -t "${in_tmstmp}" "${backup_path}"
                if [ -n "${template_ext}" ]; then
                    "${CHMOD:-chmod}" "${in_perm:2}" "${backup_path}"
                fi
                if [ ${#backup_files[@]} -gt 0 ] ; then
                    # "${DIFF:-diff}" "${backup_files[0]}" "${backup_path}" && echo same 
                    if "${DIFF:-diff}" -q "${backup_files[0]}" "${backup_path}" 1>/dev/null  2>&1 ; then
                        rm "${backup_path}"
                        local latest_backup="${backup_files[0]}"
                    else
                        local latest_backup="${backup_path}"
                    fi
                else
                    local latest_backup="${backup_path}"
                fi
            fi

            local input_path="${inputdir_path}/${template_name}${template_ext}"
            if [ -f "${input_path}" ]; then
                local in_t_mtime="$( ${DATE:-date} -r "${input_path}" "+%s")"
                if "${DIFF:-diff}" -q "${latest_backup}" "${input_path}" ; then
                    # latest backup is same 
                    :
                elif [ "${in_mtime}" -gt "${in_t_mtime}" ]; then
                    local in_t_tmstmp_ext="$( ${DATE:-date} -r "${input_path}" "+%Y%m%d%H%M%S" )"
                    local backup_input_path="${backupdir_path}/${template_name}.${in_t_tmstmp_ext}${template_ext}"
                    if [ ${verbose:-0} -ne 0 ]; then
                        echo "Warning: Existing template file: ${input_path} is old and different from the template in ${target}" 1>&2 
                        echo "If you want to update the input file with the template in ${target}, try as follows"  1>&2 
                        echo "mv -i '""${input_path}""' '""${backup_input_path}""'; cp -ai '""${latest_backup}""' '""${input_path}""'"
                    fi
                fi
            else
                # making local template input file
                "${SED:-sed}" -E -e "1 s=${py_shebang_pattern}=${py_shebang_str}=g" "${tmpfile0}" > "${input_path}"
                touch -t "${in_tmstmp}" "${input_path}"
                if [ -n "${template_ext}" ]; then
                    "${CHMOD:-chmod}" "${in_perm:2}" "${backup_path}"
                fi
            fi

        done # template file loop

        local _in=
        local _n_mtime="${in_mtime}"

        for _in in "${inputdir_path}"/* ; do
            [ -f "${_in}" ] || continue
            local _bn="${_in##*/}" 
            [[ ${_bn} =~ .*~  ]] && continue
            [[ ${_bn} =~ \#.* ]] && continue
            if [ "${#_bn}" -gt 4 -a "x${_bn##*.}" == "xpy" ]; then
                local template_nm="${_bn%.py}"
                local template_et=".py"
            else
                local template_nm="${_bn}"
                local template_et=""
            fi

            # echo "${template_nm}" "${_in}"
            local backup_files=( $("${LS:-ls}" -t "${backupdir_path}/${template_nm}."*"${template_et}" 2> /dev/null ) ) 2> /dev/null
            
            if [ "${#backup_files[@]}" -gt 0 ] ; then
                # ls -l "${backup_files[0]}" "${_in}"
                if "${DIFF:-diff}" -q "${backup_files[0]}"  "${_in}" 1>/dev/null  2>&1 ; then
                    if [ ${verbose:-0} -ne 0 ]; then
                        echo "${_in} is same as  ${backup_files[0]}: skip" 1>&2 
                    fi
                    continue 
                fi
            fi

            local template_exist=0 _tn=
            # echo "${template_nm} : ${chkd_markers[@]}"
            for _tn in ${chkd_markers[@]}; do
                if [ "x${_tn}" == "x${template_nm}" ]; then
                    local template_exist=1
                    break
                fi
            done


            local _t_mtime="$( ${DATE:-date} -r "${_in}" "+%s")"
            if [ ${_t_mtime:-0} -gt ${_n_mtime:-0} ]; then
                local _n_mtime=${_t_mtime:-0}
            fi

            local tmpfile1="$("${MKTEMP:-mktemp}" "${this}.tmp.XXXXXX" )"
            local tmpfiles=( "${tmpfiles[@]}" "${tmpfile1}" )
                
            local tmplt_prt_l_hdr="########## ____${template_nm}_template_start____ ##########"
            local tmplt_prt_l_ftr="########## ____${template_nm}_template_end____ ##########"

            local tmplt_prt_hdr='^ *#{1,} *_{3,}'"${template_nm}"'_template_start_{3,} *#{1,}'
            local tmplt_prt_ftr='^ *#{1,} *_{3,}'"${template_nm}"'_template_end_{3,} *#{1,}'

            "${GREP:-grep}" -q -E -e "${tmplt_prt_hdr}" "${_in}" 1>/dev/null 2>&1 && local _in_with_hdr=1 || local _in_with_hdr=0
            "${GREP:-grep}" -q -E -e "${tmplt_prt_ftr}" "${_in}" 1>/dev/null 2>&1 && local _in_with_ftr=1 || local _in_with_ftr=0
                
            if [ ${_in_with_hdr:-0} -ne 0 ]; then
                local tmplt_prt_l_hdr="$("${GREP:-grep}" -E -e "${tmplt_prt_hdr}" "${_in}" | head -1)"
                if [ ${_in_with_ftr:-0} -ne 0 ]; then
                    local tmplt_prt_l_ftr="$("${GREP:-grep}" -E -e "${tmplt_prt_ftr}" "${_in}" | head -1)"
                    "${SED:-sed}" -n -E -e '/'"${tmplt_prt_hdr}"'/,/'"${tmplt_prt_ftr}"'/ { /'"${tmplt_prt_hdr}"'/ n ;  /'"${tmplt_prt_ftr}"'/q ; /'"${tmplt_prt_ftr}"'/! p ; } ' "${_in}" > "${tmpfile1}"
                else
                    "${SED:-sed}" -n -E -e '/'"${tmplt_prt_hdr}"'/,$ { /'"${tmplt_prt_hdr}"'/ n ;  p ; }' "${_in}" > "${tmpfile1}"
                fi
            else
                if [ ${_in_with_ftr:-0} -ne 0 ]; then
                    local tmplt_prt_l_ftr="$("${GREP:-grep}" -E -e "${tmplt_prt_ftr}" "${_in}" | head -1)"
                    "${SED:-sed}" -n -E -e '1,/'"${tmplt_prt_ftr}"'/ {/'"${tmplt_prt_ftr}"'/! p ; } ' "${_in}" > "${tmpfile1}"
                else
                    "${CP:-cp}" -a "${_in}" "${tmpfile1}"
                fi
            fi

            local contents_file="${tmpfile1}"
            if [ "x${template_et}" == "x.py" ]; then
                local tmpfile2="$("${MKTEMP:-mktemp}" "${this}.tmp.XXXXXX" )"
                local tmpfiles=( "${tmpfiles[@]}" "${tmpfile2}" )
                "${SED:-sed}" -E -e '1 s=^.*$='"${py_template_shebang}"'=' "${tmpfile1}" > "${tmpfile2}"
                local contents_file="${tmpfile2}"
            fi

            if [ ${template_exist:-0} -ne 0 ]; then
                local tmpfile3="$("${MKTEMP:-mktemp}" "${this}.tmp.XXXXXX" )"
                local tmpfiles=( "${tmpfiles[@]}" "${tmpfile3}" )
                ${MV:-mv} -f "${target}" "${tmpfile3}" && 
                    "${CAT:-cat}" "${tmpfile3}" |\
                        "${SED:-sed}" -E -e '/'"${tmplt_prt_hdr}"'/,/'"${tmplt_prt_ftr}"'/ { /'"${tmplt_prt_hdr}"'/ n; /'"${tmplt_prt_ftr}"'/! d; }' |\
                        "${SED:-sed}" -E -e '/'"${tmplt_prt_hdr}"'/r '"${contents_file}" > "${target}"
            else
                echo ""                          >> "${target}"
                echo "${tmplt_prt_l_hdr}"        >> "${target}"
                "${CAT:-cat}" "${contents_file}" >> "${target}"
                echo ""                          >> "${target}"
                echo "${tmplt_prt_l_ftr}"        >> "${target}"
            fi
            "${CHMOD:-chmod}" "${in_perm}" "${target}"
            if [ "${_n_mtime:-0}" -gt "${in_mtime:-0}" ]; then
                touch -t "${_n_mtime}" "${target}"
            fi

        done

    done # targe file loop
    # clean up 
    cleanup
    return ${funcstatus}
    :
}

if [ "$0" == "${BASH_SOURCE:-$0}" ]; then
    # Invoked by command
    _runas="${0##*/}"
    declare -F "${_runas%.sh}" 1>/dev/null 2>&1 && { "${_runas%.sh}" "$@" ; __status=$? ; }
    unset _runas
    trap "unset __status" EXIT
    exit ${__status:-1}
else

    function undef_update_template () {

        unset update_template
        [ -n "${__update_template_bk__}" ] \
            &&  { local __update_template_bk__="${__update_template_bk__%\}}"' \\; }'; \
                  eval "${__update_template_bk__//\; : \}/\; : \; \}}"  ; }
        unset undef_update_template
        [ -n "${__undef_update_template_bk__}" ] \
            && { local __undef_update_template_bk__="${__undef_update_template_bk__%\}}"' \\; }'; \
                 eval "${__undef_update_template_bk__//\; : \}/\; : \; \}}"  ; }
        
        unset __update_template_location__
        unset __update_template_bk__ __undef_update_template_bk__

        return
        :
    }
    return
fi

# Contents below will be ignored. 

# bash_script_skeleton
Template of shell script without side effect for "source".

## Features

- This script can be called as a standalone script file or as a
  function loaded by `source`.

- Internal shell variables are defined with `local`, and `env` command
  is used to set the environmental variables for sub-commands.

- Sample of the internal function/alias definisions with
  back-up/restore procedure of the global function/alias with the same
  name, except for main function `update_template`.

- Sample of the interrupt handlers with back-up/restore procedure of
  the global definition and calling the global interrupt handler after
  its procecdures. The sample code is one of the most popular case,
  temporaly files/directory removeing.

## Usage

1. Rename `update_template` (Two places) with proper name as new
   commands.

2. Update help messages in `echo_usage`.

3. Implement the treatment of command line arguments by `getopts`.

4. Implement commands itself, it starts after the temporaly
   file/directory definstions until before the last clean-up
   procedure.

5. Update `cleanup` functions, if necessary. (For example, adding the
   restore procedure if addtional sub-function/alias are defined.

6. Update signal handlers if necessary.
