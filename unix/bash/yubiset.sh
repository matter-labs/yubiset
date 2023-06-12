#!/bin/bash

declare -r lib_dir=lib
. "${lib_dir}"/bootstrap.sh
. "${lib_dir}"/lib.sh
# Always make sure that this is declared after bootstrap.sh is sourced in order to make sure, temp dir handling is done correctly.
declare -r yubiset_main_script_runs=true

declare -r keyattr_input="${input_dir}/keyattr.input"
declare -r keygen_input="${input_dir}"/keygen.input
declare -r keygen_input_copy="${yubiset_temp_dir}"/keygen.input.copy
declare -r ondevice_keygen_template="${input_dir}/ondevicekeygen.input.template"
declare -r ondevice_keygen_input="${input_dir}/ondevicekeygen.input"

declare -r subkey_length=4096
declare -r subkeys_input="${input_dir}"/subkeys.input


declare -r revoke_input="${input_dir}"/revoke.input

print_init

press_any_key


#
# GPG CONF SECTION
#
echo "Should your gpg.conf, gpg-agent.conf, and scdaemon.conf files be replaced by the ones provided by Yubiset?"
echo "If you don't know what this is about, it is safe to say 'y' here. Backup copies of the originals will be created first."
if $(are_you_sure "Replace files") ; then create_conf_backup; fi

#
# GPG AGENT RESTART
#
echo
restart_gpg_agent || { cleanup; end_with_error "Could not restart gpg-agent."; }

#
# GPG KEY GENERATION SECTION
#
echo 
pretty_print "We are now about to generate PGP keys."
echo
echo "First, we need a little information from you."
read -p "Please enter your full name: " user_name
read -p "Please enter your full e-mail address: " user_email
echo


sed "s/FULL_NAME/${user_name}/g" "${ondevice_keygen_template}" > "${ondevice_keygen_input}"
sed -i "" "s/EMAIL/${user_email}/g" "${ondevice_keygen_input}"


#
# YUBIKEY SECTION
#
echo "${NEW_SECTION}"
echo "Checking if we can access your Yubikey.."
(. ./findyubi.sh) || { cleanup; end_with_error "Could not communicate with your Yubikey." ; }
echo "Ok, Yubikey communication is working!"
echo "${NEW_SECTION}"

#
# RESET YUBIKEY
#
echo
echo "${NEW_SECTION}"
echo "Now we must reset the OpenPGP module of your Yubikey.."
(. ./resetyubi.sh) || { cleanup; end_with_error "Resetting YubiKey ran into an error." ; }
echo "${NEW_SECTION}"

#
# YUBIKEY SETUP AND KEYTOCARD
#
echo
echo "${NEW_SECTION}"
echo "Now we need to setup your Yubikey and move the generated subkeys to it.."
(. ./setupyubi.sh) || { cleanup; end_with_error "Setting up your Yubikey ran into an error." ; }
echo "${NEW_SECTION}"

pretty_print "All done! Exiting now."

cleanup
