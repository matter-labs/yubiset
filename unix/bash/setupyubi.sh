#!/bin/bash

#
# Arg 1: Full name
# Arg 2: email address
#

#
# SETUP SECTION
#
if [[ -z "${lib_dir}" ]] ; then declare -r lib_dir=lib ; fi
. "${lib_dir}"/bootstrap.sh
. "${lib_dir}"/lib.sh

cleanup()
{
	remove_tmp_dir_if_standalone
}

keygen()
{
	echo
	echo "Generating Keys on Device"
	{ "${YUBISET_GPG_BIN}" --command-file="${ondevice_keygen_input}" --status-fd=1 --card-edit --expert ; } || { cleanup; end_with_error "Generating Keys Error" ; }

}

pin_setup()
{
	echo
	echo "Default User PIN is 123456 | Default Admin PIN is 12345678"
	echo
	echo "REMEMBER:"
	echo "User PIN must be AT LEAST 6 characters in Length"
	echo "Admin PIN must be AT LEAST 8 characters in length"
	echo "Also, you can use the alphabet in your PIN (e.g., Satosh1Nakam0t0)"
	echo
	press_any_key
	{ "${YUBISET_GPG_BIN}" --command-file="${pin_input}" --status-fd=1 --card-edit --expert ; } || { cleanup; end_with_error "Setting the PINs ran into an error." ; }
	echo "PIN setup successfull!"
}

personal_info()
{
	echo
	echo "First we must collect some personal info of yours.."
	read -p "Enter your language pref (e.g. en): " lang_pref

	echo "admin" >> "${pers_info_input}"
	echo "name" >> "${pers_info_input}"
	echo "${sur_name}" >> "${pers_info_input}"
	echo "${given_name}" >> "${pers_info_input}"
	echo "lang" >> "${pers_info_input}"
	echo "${lang_pref}" >> "${pers_info_input}"
	echo "login" >> "${pers_info_input}"
	echo "${user_email}" >> "${pers_info_input}"


	echo
	if $(are_you_sure "Write personal information to your Yubikey") ; then
		echo Now writing..
		{ "${YUBISET_GPG_BIN}" --command-file="${pers_info_input}" --status-fd=1 --card-edit --expert  ; } || { cleanup; end_with_error "Writing personal data to Yubikey ran into an error." ; }
		echo "${SUCCESS}"
	fi
}

enable_touch() {
	echo "Setting touch for Yubikey"
	echo "Note: Admin PIN required, and will be required to be entered into the terminal, not the pinentry UX"
	ykman openpgp keys set-touch --force sig fixed
	ykman openpgp keys set-touch --force aut fixed
	ykman openpgp keys set-touch --force enc fixed
}

keyattr() {
	echo "setting key-attr to use ECC"
	{ "${YUBISET_GPG_BIN}" --command-file="${keyattr_input}" --status-fd=1 --card-edit --expert ; } || { cleanup; end_with_error "Chaging key-attr to 4096 for yubikey." ; }
}

print_and_save_pubkey(){
	"${YUBISET_GPG_BIN}" --export -a ${user_email}
	"${YUBISET_GPG_BIN}" --export -a ${user_email} > "${user_email}.gpg.pubkey.asc.txt"
}

print_and_save_sshkey() {
	"${YUBISET_GPG_BIN}" --export-ssh-key ${user_email}
	"${YUBISET_GPG_BIN}" --export-ssh-key ${user_email} > "${user_email}.ssh.pubkey.txt"
}


if [[ -z "${yubiset_main_script_runs}" ]] ; then
	if [[ -z "${1}" ]] ; then { cleanup; end_with_error "Missing arg 1: Full name." ; } fi
	declare -r user_name="${1}"
	if [[ -z "${2}" ]] ; then { cleanup; end_with_error "Missing arg 2: Email address." ; } fi
	declare -r user_email="${2}"
fi

declare -r given_name="${user_name% *}"
declare -r sur_name="${user_name##* }"
declare -r pin_input="${input_dir}/pin.input"
declare -r pers_info_input="${yubiset_temp_dir}/pers_info.input"
declare -r keytocard_input="${input_dir}/keytocard.input"

pretty_print "Yubikey setup and key to card script"
pretty_print "Version: ${yubiset_version}"

#
# PIN SECTION
#
echo
if $(are_you_sure "Should we first setup your Yubikey's PIN and Admin PIN") ; then pin_setup ; fi

#
# PERSONAL INFO SECTION
#
echo
if $(are_you_sure "Should personal info be modified") ; then personal_info ; fi

#
# KEYATTR SECTION
#
echo
if $(are_you_sure "Should key-attr be updated to use ECC keys instead of RSA") ; then keyattr ; fi

#
# KEYTOCARD SECTION
#
echo
if $(are_you_sure "Generate Keys on Yubikey Device") ; then keygen ; fi

#
# Enforce Touch Settings
#
echo
if $(are_you_sure "Enable Touch for encrypt, sign, authenticate") ; then enable_touch ; fi

#
# Extract Pubkey
# 
echo
if $(are_you_sure "Print Public GPG key and save to disk?"); then print_and_save_pubkey ; fi

#
# Extract SSH Pubkey
#
echo
if $(are_you_sure "Print Public SSH Key and save to disk?"); then print_and_save_sshkey ; fi