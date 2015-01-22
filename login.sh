#! /bin/bash

#####
#
#		Created By	:	w0lf
#		Project Page:	https://github.com/w0lfschild/DarkBoot		
#		Last Edited	:	Jan / 22 / 2015			
#			
#####

pashua_run() {

	# Write config file
	pashua_configfile=`/usr/bin/mktemp /tmp/pashua_XXXXXXXXX`
	echo "$1" > $pashua_configfile

	# Find Pashua binary. We do search both . and dirname "$0"
	# , as in a doubleclickable application, cwd is /
	bundlepath="Pashua.app/Contents/MacOS/Pashua"
	if [ "$3" = "" ]
	then
		mypath=$(dirname "$0")
		for searchpath in "$mypath/Pashua" "$mypath/$bundlepath" "./$bundlepath" \
						  "/Applications/$bundlepath" "$HOME/Applications/$bundlepath"
		do
			if [ -f "$searchpath" -a -x "$searchpath" ]
			then
				pashuapath=$searchpath
				break
			fi
		done
	else
		# Directory given as argument
		pashuapath="$3/$bundlepath"
	fi

	if [ ! "$pashuapath" ]
	then
		echo "Error: Pashua could not be found"
		exit 1
	fi

	# Manage encoding
	if [ "$2" = "" ]
	then
		encoding=""
	else
		encoding="-e $2"
	fi

	# Get result
	result=$("$pashuapath" $encoding $pashua_configfile | perl -pe 's/ /;;;/g;')

	# Remove config file
	rm $pashua_configfile

	# Parse result
	for line in $result
	do
		key=$(echo $line | sed 's/^\([^=]*\)=.*$/\1/')
		value=$(echo $line | sed 's/^[^=]*=\(.*\)$/\1/' | sed 's/;;;/ /g')
		varname=$key
		varvalue="$value"
		eval $varname='$varvalue'
	done

}

# root needed to bless and create /dboot
ask_pass() {
	pass_window="$pass_window
				*.title = Dark Boot - 1.1
				*.floating = 1
				*.transparency = 1.00
				*.autosavekey = dBoot"
	
	pass_window="$pass_window
				pw0.type = password
				pw0.label = Enter your password to continue:
				pw0.mandatory = 1
				pw0.width = 100
				pw0.x = -10
				pw0.y = 4"
	
	pashua_run "$pass_window" 'utf8' "$pashua_directory"
	pass_window=""
	echo "$pw0" | sudo -Sv
	if [[ $pw0 = "" ]]; then echo -e "No password entered, quitting..."; exit; else pw0=""; fi
}

# Check what is currently blessed and then bless proper efi
check_bless() {
	blessed=$(bless --info / | grep efi)
	blessed='/'${blessed#*/}
	if [[ $1 = default ]]; then
		if [[ "$blessed" != /System/Library/CoreServices/boot.efi ]]; then bless_efi /System/Library/CoreServices boot.efi; fi
	else
		if [[ "$blessed" != /dboot/$1_boot.efi ]]; then bless_efi /dboot $1_boot.efi; fi
	fi
}

# Bless any efi $1 = Directory $2 = Efi name
bless_efi() {
	ask_pass
	echo -e "$1/$2 blessed"
	pushd "$1" 1>/dev/null
	sudo bless --folder . --file "$2" --labelfile .disk_label
	popd 1>/dev/null
}

scriptDirectory=$(cd "${0%/*}" && echo $PWD)
pashua_directory="$scriptDirectory"
for i in {1..3}; do pashua_directory=$(dirname "$pashua_directory"); done
my_color=$(defaults read org.w0lf.dBoot color || echo -n "default")
check_bless $my_color

# End