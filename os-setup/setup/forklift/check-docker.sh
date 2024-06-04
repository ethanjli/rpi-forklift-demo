#!/usr/bin/env sh
set -e

EXITCODE=0

# bits of this were adapted from lxc-checkconfig
# see also https://github.com/lxc/lxc/blob/lxc-1.0.2/src/lxc/lxc-checkconfig.in

possibleConfigs="
	/proc/config.gz
	/boot/config-$(uname -r)
	/usr/src/linux-$(uname -r)/.config
	/usr/src/linux/.config
"

useColor=true
if [ "$NO_COLOR" = "1" ] || [ ! -t 1 ]; then
	useColor=false
fi
kernelVersion="$(uname -r)"
kernelMajor="${kernelVersion%%.*}"
kernelMinor="${kernelVersion#$kernelMajor.}"
kernelMinor="${kernelMinor%%.*}"

color() {
	# if stdout is not a terminal, then don't do color codes.
	if [ "$useColor" = "false" ]; then
		return 0
	fi
	codes=
	if [ "$1" = 'bold' ]; then
		codes='1'
		shift
	fi
	if [ "$#" -gt 0 ]; then
		code=
		case "$1" in
			# see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
			black) code=30 ;;
			red) code=31 ;;
			green) code=32 ;;
			yellow) code=33 ;;
			blue) code=34 ;;
			magenta) code=35 ;;
			cyan) code=36 ;;
			white) code=37 ;;
		esac
		if [ "$code" ]; then
			codes="${codes:+$codes;}$code"
		fi
	fi
	printf '\033[%sm' "$codes"
}
wrap_color() {
	text="$1"
	shift
	color "$@"
	printf '%s' "$text"
	color reset
	echo
}

wrap_good() {
	echo "$(wrap_color "$1" white): $(wrap_color "$2" green)"
}
wrap_bad() {
	echo "$(wrap_color "$1" bold): $(wrap_color "$2" bold red)"
}
wrap_warning() {
	wrap_color >&2 "$*" red
}

check_command() {
	if command -v "$1" > /dev/null 2>&1; then
		wrap_good "$1 command" 'available'
	else
		wrap_bad "$1 command" 'missing'
		EXITCODE=1
	fi
}

check_device() {
	if [ -c "$1" ]; then
		wrap_good "$1" 'present'
	else
		wrap_bad "$1" 'missing'
		EXITCODE=1
	fi
}

check_distro_userns() {
	if [ ! -e /etc/os-release ]; then
		return
	fi
	. /etc/os-release 2> /dev/null || /bin/true
	case "$ID" in
		centos | rhel)
			case "$VERSION_ID" in
				7*)
					# this is a CentOS7 or RHEL7 system
					grep -q 'user_namespace.enable=1' /proc/cmdline || {
						# no user namespace support enabled
						wrap_bad "  (RHEL7/CentOS7" "User namespaces disabled; add 'user_namespace.enable=1' to boot command line)"
						EXITCODE=1
					}
					;;
			esac
			;;
	esac
}

echo 'Generally Necessary:'

printf -- '- '
if [ "$(stat -f -c %t /sys/fs/cgroup 2> /dev/null)" = '63677270' ]; then
	wrap_good 'cgroup hierarchy' 'cgroupv2'
	cgroupv2ControllerFile='/sys/fs/cgroup/cgroup.controllers'
	if [ -f "$cgroupv2ControllerFile" ]; then
		echo '  Controllers:'
		for controller in cpu cpuset io memory pids; do
			if grep -qE '(^| )'"$controller"'($| )' "$cgroupv2ControllerFile"; then
				echo "  - $(wrap_good "$controller" 'available')"
			else
				echo "  - $(wrap_bad "$controller" 'missing')"
			fi
		done
	else
		wrap_bad "$cgroupv2ControllerFile" 'nonexistent??'
	fi
	# TODO find an efficient way to check if cgroup.freeze exists in subdir
else
	cgroupSubsystemDir="$(sed -rne '/^[^ ]+ ([^ ]+) cgroup ([^ ]*,)?(cpu|cpuacct|cpuset|devices|freezer|memory)[, ].*$/ { s//\1/p; q }' /proc/mounts)"
	cgroupDir="$(dirname "$cgroupSubsystemDir")"
	if [ -d "$cgroupDir/cpu" ] || [ -d "$cgroupDir/cpuacct" ] || [ -d "$cgroupDir/cpuset" ] || [ -d "$cgroupDir/devices" ] || [ -d "$cgroupDir/freezer" ] || [ -d "$cgroupDir/memory" ]; then
		echo "$(wrap_good 'cgroup hierarchy' 'properly mounted') [$cgroupDir]"
	else
		if [ "$cgroupSubsystemDir" ]; then
			echo "$(wrap_bad 'cgroup hierarchy' 'single mountpoint!') [$cgroupSubsystemDir]"
		else
			wrap_bad 'cgroup hierarchy' 'nonexistent??'
		fi
		EXITCODE=1
		echo "    $(wrap_color '(see https://github.com/tianon/cgroupfs-mount)' yellow)"
	fi
fi

if [ "$(cat /sys/module/apparmor/parameters/enabled 2> /dev/null)" = 'Y' ]; then
	printf -- '- '
	if command -v apparmor_parser > /dev/null 2>&1; then
		wrap_good 'apparmor' 'enabled and tools installed'
	else
		wrap_bad 'apparmor' 'enabled, but apparmor_parser missing'
		printf '    '
		if command -v apt-get > /dev/null 2>&1; then
			wrap_color '(use "apt-get install apparmor" to fix this)'
		elif command -v yum > /dev/null 2>&1; then
			wrap_color '(your best bet is "yum install apparmor-parser")'
		else
			wrap_color '(look for an "apparmor" package for your distribution)'
		fi
		EXITCODE=1
	fi
fi

echo

echo 'Optional Features:'
{
	check_distro_userns
}

echo

check_limit_over() {
	if [ "$(cat "$1")" -le "$2" ]; then
		wrap_bad "- $1" "$(cat "$1")"
		wrap_color "    This should be set to at least $2, for example set: sysctl -w kernel/keys/root_maxkeys=1000000" bold black
		EXITCODE=1
	else
		wrap_good "- $1" "$(cat "$1")"
	fi
}

echo 'Limits:'
check_limit_over /proc/sys/kernel/keys/root_maxkeys 10000
echo

exit $EXITCODE
