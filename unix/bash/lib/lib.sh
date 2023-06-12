SUCCESS="..Success!"
NEW_SECTION="#########################"

# Exit with code 1.
#
# Arg 1: Text to display before exiting.
#
end_with_error()
{
	echo "ERROR: ${1:-"Unknown Error"} Exiting." 1>&2
	exit 1
}

#
# Echo the provided arg in a pretty way.
#
# Arg 1: String to echo.
#
pretty_print()
{
	echo ".....| ${1}"
}

#
# Remove any leading and trailing spaces or space like characters.
#
# Arg 1: String to trim.
#
# Return: Trimmed string
#
trim()
{
	# See https://www.linuxjournal.com/content/return-values-bash-functions
    echo "$(echo -e "${1}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
}

#
# Holds the script until the user presses a key.
#
# -n1.. read exactly one char
# -s... do not echo any input
# -r... escaping via backslash is not allowed
# -p... output the following string without a newline before reading
#
press_any_key() {
	read -n 1 -s -r -p $'Press any key to continue\n'
	echo
}

#
# Display a message and wait for the user to make a decision. Only accepts yY or nN. Loops for as long as no valid value has been entered.
#
# Arg 1: Text to display.
#
# Return: true if yY, false if nN or empty (user just hit enter).
are_you_sure() {
	while true; do
		local _yn=n
		read -p "${1} (y/[n])? " _yn
		case $_yn in
			[Yy]* ) echo true; break;;
			[Nn]* ) echo false; break;;
			""    ) echo false; break;;
		esac
	done
}

#
# rm -rf and pipe stdout and stderr to /dev/null
#
# Arg(s): File(s) to delete.
#
silentDel()
{
	rm -rf "${@}" > /dev/null 2>&1
}

#
# cp -rf and pipe stdout and stderr to /dev/null
#
# Arg(s): File(s) to copy.
#
silentCopy()
{
	cp -rf "${@}" > /dev/null 2>&1
}

#
# Restart the gpg-agent
#
# For the use of the '' see: https://dev.gnupg.org/T2024
# tl;dr; it is a bug workaround
# Not sure if using gpgconf --kill gpg-agent would be a better approach here
restart_gpg_agent()
{
	echo "${NEW_SECTION}"
	echo "Restarting gpg-agent.."
	"${YUBISET_GPG_CONNECT_AGENT}" reloadagent '' /bye
	echo "${SUCCESS}"
	echo "${NEW_SECTION}"
}

#
# Restart the scdaemon
#
restart_scdaemon()
{
	echo "${NEW_SECTION}"
	echo "Restarting Scdaemon"
	"${YUBISET_GPG_CONF}" --reload scdaemon
	echo "${SUCCESS}"
	echo "${NEW_SECTION}"
}

#
# Requests the user to remove and reinsert her Yubikey and waits between those steps for the user to finish.
#
reinsert_yubi()
{
echo
echo "${NEW_SECTION}"
echo "Please remove your Yubikey"
press_any_key
echo "Please insert your Yubikey"
press_any_key
echo "${NEW_SECTION}"
}

cleanup()
{
	silentDel "${keygen_input_copy}"
	silentDel "${yubiset_temp_dir}"
	echo
}

create_conf_backup()
{
	echo "Now making backup copies.."

	if [[ -f "${gpg_home}/gpg.conf" ]]; then
		echo "${gpg_home}/gpg.conf => ${gpg_home}/gpg.conf.backup.by.yubiset"
		cp -f "${gpg_home}/gpg.conf" "${gpg_home}/gpg.conf.backup.by.yubiset" || { cleanup; end_with_error "Creating backup of gpg.conf failed."; }
	fi

	if [[ -f "${gpg_home}/gpg-agent.conf" ]]; then
		echo "${gpg_home}/gpg-agent.conf => ${gpg_home}/gpg-agent.conf.backup.by.yubiset"
		cp -f "${gpg_home}/gpg-agent.conf" "${gpg_home}/gpg-agent.conf.backup.by.yubiset" || { cleanup; end_with_error "Creating backup of gpg-agent.conf failed."; }
	fi

	if [[ -f "${gpg_home}/scdaemon.conf" ]]; then
		echo "${gpg_home}/scdaemon.conf => ${gpg_home}/scdaemon.conf.backup.by.yubiset"
		cp -f "${gpg_home}/scdaemon.conf" "${gpg_home}/scdaemon.conf.backup.by.yubiset" || { cleanup; end_with_error "Creating backup of gpg-agent.conf failed."; }
	fi
	echo "${SUCCESS}"
	echo
	echo "Now copying yubiset's conf files.."
	
	silentCopy "${conf_dir}/gpg.conf" "${gpg_home}/gpg.conf" || { cleanup; end_with_error "Replacing gpg.conf failed."; }
	silentCopy "${conf_dir}/gpg-agent.conf" "${gpg_home}/gpg-agent.conf" || { cleanup; end_with_error "Replacing gpg-agent.conf failed."; }
	silentCopy "${conf_dir}/scdaemon.conf" "${gpg_home}/scdaemon.conf" || { cleanup; end_with_error "Replacing gpg-agent.conf failed."; }

	echo "${SUCCESS}"
}

print_init() {
	pretty_print "OpenPGP key generation and Yubikey setup script"
	pretty_print "Version: ${yubiset_version}"
	pretty_print
	pretty_print "gpg home:                ${gpg_home}"
	pretty_print "Subkey length:           ${subkey_length} bit"
	pretty_print "Yubiset tmp dir:         ${yubiset_temp_dir}"
	pretty_print "Yubiset key backups dir: ${key_backups_dir}"
	pretty_print "gpg:                     ${YUBISET_GPG_BIN}"
	pretty_print "gpg-connect-agent:       ${YUBISET_GPG_CONNECT_AGENT}"
	pretty_print "gpgconf:                 ${YUBISET_GPG_CONF}"
echo
}