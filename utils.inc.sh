#!/bin/bash

_BDIR="`dirname ${0}`"

# Common utils for Git-JIRA 
#
# Author Thomas Lehmann (thomas.lehmann@stueckseln.de) 2012
#

# Path to Git-JIRA config file
#
# GIT_JIRA_CONFIG_FILE_PATH might be used in other scripts
# 
GIT_JIRA_CONFIG_FILE_PATH=".git-jira/config"
GIT_JIRA_CONFIG_FILE="${HOME}/${GIT_JIRA_CONFIG_FILE_PATH}"


if which js >/dev/null 2>&1 ; then
	JS_INTERPRETER_BIN="js"
elif which smjs >/dev/null 2>&1 ; then
	JS_INTERPRETER_BIN="smjs"
else
	echo "No Spider Monkey JS VM found. Searched for 'js' and 'smjs'."
	exit 1
fi



expandVariable(){
	eval echo "\${GIT_JIRA_${1}}"
}

envVarStyleToGitConfig(){
	echo "${1}" | awk '{print tolower($1); }' | sed 's+_+-+g'
}

getConfigFromFile(){
	cat ${GIT_JIRA_CONFIG_FILE} | grep "${1}" | sed 's+^.*=++'
}

getConfig(){
	_VALUE="$( expandVariable ${1} )"
	if [ ! -z "${_VALUE}" ]; then
		echo "${_VALUE}"
		return 0
	fi

	if git status >/dev/null 2>&1; then
		_VALUE="$( git config --get "git-jira.`envVarStyleToGitConfig ${1}`" )"

		if [ ! -z "${_VALUE}" ]; then
			echo "${_VALUE}"
			return 0
		fi
	fi

	# Ignoring missing Git as there is another chance

	if [ -f ${GIT_JIRA_CONFIG_FILE} ] ; then
		_VALUE="$( getConfigFromFile ${1} )"

		if [ ! -z "${_VALUE}" ]; then
			echo "${_VALUE}"
			return 0
		fi
	fi

	return 1
}

getCookieProvider(){
	_PROVIDER_NAME="$( getConfig "COOKIE_PROVIDER" )"
	
	if [ -z "${_PROVIDER_NAME}" ]; then
		echo "Error: no cookie provider configured!"
		
		# TODO Handle not configured provider and use default provider
		#      Implement default provider which asks you for your credentials.
		
		exit 201
	fi
	
	_PROVIDER="${_BDIR}/get-jira-session-cookies.${_PROVIDER_NAME}.sh"
	
	if [ ! -x "${_PROVIDER}" ]; then
		echo "Error: given provider '${_PROVIDER_NAME}' is not existing and executable." >/dev/stderr
		exit 202
	fi
	
	echo "${_PROVIDER}"
}
