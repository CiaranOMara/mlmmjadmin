#!/usr/bin/env bash

# Purpose: Upgrade mlmmjadmin from old release.

# USAGE:
#
#   Run commands below as root user:
#
#       # bash upgrade_mlmmjadmin.sh
#

export SYS_USER_MLMMJ='mlmmj'
export SYS_GROUP_MLMMJ='mlmmj'
export SYS_USER_ROOT='root'

# iRedAdmin directory and config file.
export MA_ROOT_DIR='/opt/mlmmjadmin'
export MA_PARENT_DIR="$(dirname ${MA_ROOT_DIR})"
export MA_CONF="${MA_ROOT_DIR}/settings.py"
export MA_CUSTOM_CONF="${MA_ROOT_DIR}/custom_settings.py"

# Path to some programs.
export PYTHON_BIN='/usr/bin/python3'

# Check OS to detect some necessary info.
export KERNEL_NAME="$(uname -s | tr '[a-z]' '[A-Z]')"

if [ X"${KERNEL_NAME}" == X'LINUX' ]; then
    if [ -f /etc/redhat-release ]; then
        # RHEL/CentOS
        export DISTRO='RHEL'

        # Get distribution version
        if grep '\ 7' /etc/redhat-release &>/dev/null; then
            export DISTRO_VERSION='7'
            export PYTHON_VER='36'
        elif grep '\ 6' /etc/redhat-release &>/dev/null; then
            export DISTRO_VERSION='6'
            export PYTHON_VER='34'
        else
            echo "Unsupported RHEL/CentOS release, abort." && exit 255
        fi
    elif [ -f /etc/lsb-release ]; then
        # Ubuntu
        export DISTRO='UBUNTU'
    elif [ -f /etc/debian_version ]; then
        # Debian
        export DISTRO='DEBIAN'
    elif [ -f /etc/SuSE-release ]; then
        # openSUSE
        export DISTRO='SUSE'
    else
        echo "<<< ERROR >>> Cannot detect Linux distribution name. Exit."
        echo "Please contact support@iredmail.org to solve it."
        exit 255
    fi
elif [ X"${KERNEL_NAME}" == X'FREEBSD' ]; then
    export DISTRO='FREEBSD'
    export PYTHON_BIN='/usr/local/bin/python3'
elif [ X"${KERNEL_NAME}" == X'OPENBSD' ]; then
    export DISTRO='OPENBSD'
    export PYTHON_BIN='/usr/local/bin/python3'
else
    echo "Cannot detect Linux/BSD distribution. Exit."
    echo "Please contact author iRedMail team <support@iredmail.org> to solve it."
    exit 255
fi

if [[ -d /etc/postfix/mysql ]] || [[ -d /usr/local/etc/postfix/mysql ]]; then
    export IREDMAIL_BACKEND='MYSQL'
elif [[ -d /etc/postfix/pgsql ]] || [[ -d /usr/local/etc/postfix/pgsql ]]; then
    export IREDMAIL_BACKEND='PGSQL'
elif [[ -d /etc/postfix/ldap ]] || [[ -d /usr/local/etc/postfix/ldap ]]; then
    export IREDMAIL_BACKEND='LDAP'
else
    echo "Can not detect iRedMail backend (MySQL, PostgreSQL, OpenLDAP). Abort."
fi

install_pkg()
{
    echo "Install package: $@"

    if [ X"${DISTRO}" == X'RHEL' ]; then
        yum -y install $@
    elif [ X"${DISTRO}" == X'DEBIAN' -o X"${DISTRO}" == X'UBUNTU' ]; then
        apt-get install -y --force-yes $@
    elif [ X"${DISTRO}" == X'FREEBSD' ]; then
        cd /usr/ports/$@ && make install clean
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        pkg_add -r $@
    else
        echo "<< ERROR >> Please install package(s) manually: $@"
    fi
}

install_py3()
{
    if [[ -x ${PYTHON_BIN} ]]; then
        echo "* Python-3: ${PYTHON_BIN}."
    else
        echo "* Python-3 is not installed. Installing..."

        [ X"${DISTRO}" == X'RHEL' ]     && install_pkg python${PYTHON_VER}
        [ X"${DISTRO}" == X'DEBIAN' ]   && install_pkg python3
        [ X"${DISTRO}" == X'UBUNTU' ]   && install_pkg python3
        [ X"${DISTRO}" == X'FREEBSD' ]  && install_pkg lang/python37
        [ X"${DISTRO}" == X'OPENBSD' ]  && install_pkg python%3
    fi
}

install_py3_modules()
{
    #
    # Check dependent packages. Prompt to install missed ones manually.
    #
    py_mods=""

    if [[ X"${DISTRO}" == X"RHEL" ]]; then
        [[ X"${IREDMAIL_BACKEND}" == X'MYSQL' ]] && \
            python3 -c "import MySQLdb" &>/dev/null || py_mods="${py_mods} python${PYTHON_VER}-mysql"

        [[ X"${IREDMAIL_BACKEND}" == X'PGSQL' ]] && \
            python3 -c "import psycopg2" &>/dev/null || py_mods="${py_mods} python${PYTHON_VER}-psycopg2"

        [[ X"${IREDMAIL_BACKEND}" == X'LDAP' ]] && \
            python3 -c "import ldap" &>/dev/null || py_mods="${py_mods} python${PYTHON_VER}-ldap3"

        python3 -c "import requests" &>/dev/null || py_mods="${py_mods} python${PYTHON_VER}-ldap3"
    elif [[ X"${DISTRO}" == X"DEBIAN" ]] || [[ X"${DISTRO}" == X"UBUNTU" ]]; then
        [[ X"${IREDMAIL_BACKEND}" == X'MYSQL' ]] && \
            python3 -c "import MySQLdb" &>/dev/null || py_mods="${py_mods} python3-mysql"

        [[ X"${IREDMAIL_BACKEND}" == X'PGSQL' ]] && \
            python3 -c "import psycopg2" &>/dev/null || py_mods="${py_mods} python3-psycopg2"

        [[ X"${IREDMAIL_BACKEND}" == X'LDAP' ]] && \
            python3 -c "import ldap" &>/dev/null || py_mods="${py_mods} python3-ldap"

        python3 -c "import requests" &>/dev/null || py_mods="${py_mods} python3-requests"
    elif [[ X"${DISTRO}" == X"FREEBSD" ]]; then
        [[ X"${IREDMAIL_BACKEND}" == X'MYSQL' ]] && \
            python3 -c "import MySQLdb" &>/dev/null || py_mods="${py_mods} python3-mysql"

        [[ X"${IREDMAIL_BACKEND}" == X'PGSQL' ]] && \
            python3 -c "import psycopg2" &>/dev/null || py_mods="${py_mods} python3-psycopg2"

        [[ X"${IREDMAIL_BACKEND}" == X'LDAP' ]] && \
            python3 -c "import ldap" &>/dev/null || py_mods="${py_mods} python3-ldap"

        python3 -c "import requests" &>/dev/null || py_mods="${py_mods} python3-requests"
    elif [[ X"${DISTRO}" == X"OPENBSD" ]]; then
        [[ X"${IREDMAIL_BACKEND}" == X'MYSQL' ]] && \
            python3 -c "import MySQLdb" &>/dev/null || py_mods="${py_mods} py3-mysqlclient"

        [[ X"${IREDMAIL_BACKEND}" == X'PGSQL' ]] && \
            python3 -c "import psycopg2" &>/dev/null || py_mods="${py_mods} py3-psycopg2"

        [[ X"${IREDMAIL_BACKEND}" == X'LDAP' ]] && \
            python3 -c "import ldap" &>/dev/null || py_mods="${py_mods} python3-ldap"

        python3 -c "import requests" &>/dev/null || py_mods="${py_mods} python3-requests"
    fi

    if [[ X"${py_mods}" != X'' ]]; then
        echo "Install required Python-3 modules: ${py_mods}"
        install_pkg ${py_mods}

        if [[ X"$?" != X'0' ]]; then
            echo "Installation failed. Please try to fix it manually, or post this"
            echo "issue to iRedMail forum to get help: https://forum.iredmail.org/"
            exit 255
        fi
    fi
}

restart_mlmmjadmin()
{
    echo "* Restarting service: mlmmjadmin."
    if [ X"${KERNEL_NAME}" == X'LINUX' -o X"${KERNEL_NAME}" == X'FREEBSD' ]; then
        service mlmmjadmin restart
    elif [ X"${KERNEL_NAME}" == X'OPENBSD' ]; then
        rcctl restart mlmmjadmin
    fi

    if [ X"$?" != X'0' ]; then
        echo "Failed, please restart service 'mlmmjadmin' manually."
    fi
}

echo "* Detected Linux/BSD distribution: ${DISTRO}"

install_py3
install_py3_modules

if [ -L ${MA_ROOT_DIR} ]; then
    export MA_ROOT_REAL_DIR="$(readlink ${MA_ROOT_DIR})"
    echo "* Found mlmmjadmin: ${MA_ROOT_DIR}, symbol link of ${MA_ROOT_REAL_DIR}"
else
    echo "<<< ERROR >>> Directory (${MA_ROOT_DIR}) is not a symbol link created by iRedMail. Exit."
    exit 255
fi

# Copy config file
if [ -f ${MA_CONF} ]; then
    echo "* Found old config file: ${MA_CONF}"
else
    echo "<<< ERROR >>> No old config file found ${MA_CONF}, exit."
    exit 255
fi

# Copy current directory to /opt
dir_new_version="$(dirname ${PWD})"
name_new_version="$(basename ${dir_new_version})"
NEW_MA_ROOT_DIR="${MA_PARENT_DIR}/${name_new_version}"
NEW_MA_CONF="${NEW_MA_ROOT_DIR}/settings.py"
if [ -d ${NEW_MA_ROOT_DIR} ]; then
    COPY_FILES="${dir_new_version}/*"
    COPY_DEST_DIR="${NEW_MA_ROOT_DIR}"
else
    COPY_FILES="${dir_new_version}"
    COPY_DEST_DIR="${MA_PARENT_DIR}"
fi

echo "* Copying new version to ${NEW_MA_ROOT_DIR}"
cp -rf ${COPY_FILES} ${COPY_DEST_DIR}

# Copy old config files
echo "* Copy ${MA_CONF}."
cp -p ${MA_CONF} ${NEW_MA_ROOT_DIR}/

if [ -f ${MA_CUSTOM_CONF} ]; then
    echo "* Copy ${MA_CUSTOM_CONF}."
    cp -p ${MA_CUSTOM_CONF} ${NEW_MA_ROOT_DIR}
fi

# Set owner and permission.
chown -R ${SYS_USER_MLMMJ}:${SYS_GROUP_MLMMJ} ${NEW_MA_ROOT_DIR}
chmod -R 0755 ${NEW_MA_ROOT_DIR}
chmod 0400 ${NEW_MA_CONF}

echo "* Removing old symbol link ${MA_ROOT_DIR}"
rm -f ${MA_ROOT_DIR}

echo "* Creating symbol link: ${NEW_MA_ROOT_DIR} -> ${MA_ROOT_DIR}"
cd ${MA_PARENT_DIR}
ln -s ${NEW_MA_ROOT_DIR} ${MA_ROOT_DIR}

echo "* mlmmjadmin has been successfully upgraded."
restart_mlmmjadmin

# Clean up.
cd ${NEW_MA_ROOT_DIR}/
rm -f settings.py{c,o} tools/settings.py{,c,o}

echo "* Upgrading completed."

cat <<EOF
<<< NOTE >>> If mlmmjadmin doesn't work as expected, please post your issue in
<<< NOTE >>> our online support forum: http://www.iredmail.org/forum/
EOF
