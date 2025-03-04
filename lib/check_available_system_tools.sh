#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# shellcheck disable=SC2034

###############################################################################
# Check tools available on the target system. Also, checks for which parameters
# are supported by find tool.
# Globals:
#   MOUNT_POINT
#   OPERATING_SYSTEM
#   UAC_DIR
# Requires:
#   None
# Arguments:
#   None
# Outputs:
#   Set the value for the following global vars:
#     FIND_ATIME_SUPPORT
#     FIND_CTIME_SUPPORT
#     FIND_MAXDEPTH_SUPPORT
#     FIND_MTIME_SUPPORT
#     FIND_OPERATORS_SUPPORT
#     FIND_PATH_SUPPORT
#     FIND_PERM_SUPPORT
#     FIND_SIZE_SUPPORT
#     GZIP_TOOL_AVAILABLE
#     MD5_HASHING_TOOL
#     PERL_TOOL_AVAILABLE
#     PROCSTAT_TOOL_AVAILABLE
#     SHA1_HASHING_TOOL
#     SHA256_HASHING_TOOL
#     STATX_TOOL_AVAILABLE
#     STAT_BTIME_SUPPORT
#     STAT_TOOL_AVAILABLE
#     TAR_TOOL_AVAILABLE
#     XARGS_REPLACE_STRING_SUPPORT
# Exit Status:
#   Last command exit status code.
###############################################################################
check_available_system_tools()
{

  FIND_ATIME_SUPPORT=false
  FIND_CTIME_SUPPORT=false
  FIND_MAXDEPTH_SUPPORT=false
  FIND_MTIME_SUPPORT=false
  FIND_OPERATORS_SUPPORT=false
  FIND_PATH_SUPPORT=false
  FIND_PERM_SUPPORT=false
  FIND_SIZE_SUPPORT=false
  FIND_TYPE_SUPPORT=false
  GZIP_TOOL_AVAILABLE=false
  MD5_HASHING_TOOL=""
  PERL_TOOL_AVAILABLE=false
  PROCSTAT_TOOL_AVAILABLE=false
  SHA1_HASHING_TOOL=""
  SHA256_HASHING_TOOL=""
  STATX_TOOL_AVAILABLE=false
  STAT_BTIME_SUPPORT=false
  STAT_TOOL_AVAILABLE=false
  TAR_TOOL_AVAILABLE=false
  XARGS_REPLACE_STRING_SUPPORT=false

  # each command needs to be tested individually as some systems do not have
  # 'type' or 'which' tool

  # check if 'gzip' tool is available
  if eval "echo \"uac\" | gzip"; then
    GZIP_TOOL_AVAILABLE=true
  fi
  
  # check if 'perl' is available
  if eval "perl -e 'print \"uac\"'"; then
    PERL_TOOL_AVAILABLE=true
  fi

  # check if 'procstat' is available
  if eval "procstat $$"; then
    PROCSTAT_TOOL_AVAILABLE=true
  fi

  # check if 'stat' is available
  if eval "stat \"${MOUNT_POINT}\""; then
    STAT_TOOL_AVAILABLE=true
    # check if birth time is collected by 'stat'
    case "${OPERATING_SYSTEM}" in
      "freebsd"|"macos"|"netbsd"|"netscaler"|"openbsd")
        if eval "stat -f \"0|%N%SY|%i|%Sp|%u|%g|%z|%a|%m|%c|%B\" \"${MOUNT_POINT}\" \
             | grep -q -E \"\|[0-9]{2,}$\""; then
          STAT_BTIME_SUPPORT=true
        fi
      ;;
      "android"|"esxi"|"linux"|"solaris")
        if eval "stat -c \"0|%N|%i|%A|%u|%g|%s|%X|%Y|%Z|%W\" \"${MOUNT_POINT}\" \
             | grep -q -E \"\|[0-9]{2,}$\""; then
          STAT_BTIME_SUPPORT=true
        fi
      ;;
    esac
  fi

  # check if 'statx' is available for the current system architecture
  if [ "${OPERATING_SYSTEM}" = "esxi" ] \
    || [ "${OPERATING_SYSTEM}" = "linux" ]; then
    ca_arch=""
    case "${SYSTEM_ARCH}" in
      armv5*|armv6*|armv7*)
        ca_arch="arm"
        ;;
      aarch64*|armv8*)
        ca_arch="arm64"
        ;;
      "i386"|"i686")
        ca_arch="i686"
        ;;
      "mips")
        ca_arch="mips"
        ;;
      "mips64")
        ca_arch="mips64"
        ;;
      "ppc")
        ca_arch="ppc"
        ;;
      "ppc64")
        ca_arch="ppc64"
        ;;
      "ppc64le")
        ca_arch="ppc64le"
        ;;
      s390*)
        ca_arch="s390"
        ;;  
      sparc*)
        ca_arch="sparc"
        ;;
      "x86_64")
        ca_arch="x86_64"
        ;;   
    esac
    if [ -n "${ca_arch}" ] \
      && eval "\"${UAC_DIR}/tools/statx/bin/linux/${ca_arch}/statx\" \
      \"${MOUNT_POINT}\""; then
      PATH="${UAC_DIR}/tools/statx/bin/linux/${ca_arch}:${PATH}"
        export PATH
        STATX_TOOL_AVAILABLE=true
    fi
  fi

  # check if 'tar' tool is available
  if eval "tar -cf - \"${UAC_DIR}/uac\""; then
    TAR_TOOL_AVAILABLE=true
  fi  

  # check if 'xargs' supports -I{} parameter
  if eval "echo \"uac\" | xargs -I{}"; then
    # check if 'xargs' removes the backslash character from escaped quotes
    if eval "echo \"uac\'uac\" | xargs -I{} echo \"{}\" | grep \"uac'uac\""; then
      XARGS_REPLACE_STRING_SUPPORT=true
    fi
  fi

  # check which options are supported by the find tool
  if eval "find \"${UAC_DIR}\" \\( -name \"uac.conf\" -o -name \"uac.conf\" \\) -print"; then
    FIND_OPERATORS_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}\" -path \"${UAC_DIR}\" -print"; then
    FIND_PATH_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}/uac\" -size +1c -print"; then
    FIND_SIZE_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}/uac\" -maxdepth 1 -print"; then
    FIND_MAXDEPTH_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}/uac\" -perm -0000 -print"; then
    FIND_PERM_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}/uac\" -type f -print"; then
    FIND_TYPE_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}/uac\" -atime +1 -print"; then
    FIND_ATIME_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}/uac\" -mtime +1 -print"; then
    FIND_MTIME_SUPPORT=true
  fi

  if eval "find \"${UAC_DIR}/uac\" -ctime +1 -print"; then
    FIND_CTIME_SUPPORT=true
  fi

  # check for available MD5 hashing tools
  if eval "echo \"uac\" | md5sum"; then
    MD5_HASHING_TOOL="md5sum"
  elif eval "echo \"uac\" | md5"; then
    MD5_HASHING_TOOL="md5"
  elif eval "echo \"uac\" | digest -v -a md5"; then
    MD5_HASHING_TOOL="digest -v -a md5"
  elif eval "csum -h MD5 \"${UAC_DIR}/uac\""; then
    MD5_HASHING_TOOL="csum -h MD5"
  elif eval "echo \"uac\" | openssl dgst -md5"; then
    MD5_HASHING_TOOL="openssl dgst -md5"
  fi

  # check for available SHA1 hashing tools
  if eval "echo \"uac\" | sha1sum"; then
    SHA1_HASHING_TOOL="sha1sum"
  elif eval "echo \"uac\" | shasum -a 1"; then
    SHA1_HASHING_TOOL="shasum -a 1"
  elif eval "echo \"uac\" | sha1"; then
    SHA1_HASHING_TOOL="sha1"
  elif eval "echo \"uac\" | digest -v -a sha1"; then
    SHA1_HASHING_TOOL="digest -v -a sha1"
  elif eval "csum -h SHA1 \"${UAC_DIR}/uac\""; then
    SHA1_HASHING_TOOL="csum -h SHA1"
  elif eval "echo \"uac\" | openssl dgst -sha1"; then
    SHA1_HASHING_TOOL="openssl dgst -sha1"
  fi

  # check for available SHA256 hashing tools
  if eval "echo \"uac\" | sha256sum"; then
    SHA256_HASHING_TOOL="sha256sum"
  elif eval "echo \"uac\" | shasum -a 256"; then
    SHA256_HASHING_TOOL="shasum -a 256"
  elif eval "echo \"uac\" | sha256"; then
    SHA256_HASHING_TOOL="sha256"
  elif eval "echo \"uac\" | digest -v -a sha256"; then
    SHA256_HASHING_TOOL="digest -v -a sha256"
  elif eval "csum -h SHA256 \"${UAC_DIR}/uac\""; then
    SHA256_HASHING_TOOL="csum -h SHA256"
  elif eval "echo \"uac\" | openssl dgst -sha256"; then
    SHA256_HASHING_TOOL="openssl dgst -sha256"
  fi

}