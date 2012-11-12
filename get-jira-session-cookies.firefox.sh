#!/bin/bash

# Store JIRA session cookies of your Firefox profile for the Git-JIRA suite 
# This is the Firefox adapter.
# It will examine your sessionstore.js for session cookies.
#
# Author Thomas Lehmann (thomas.lehmann@stueckseln.de) 2012
#
#
# Configuration options
#	FIREFOX_PROFILE		Path to the Firefox profile to use
#	CROWD_PATH			Crowd path (defaults to /)
#	JIRA_URL			Full JIRA URL including http[s]:// and path 
#

BDIR="`dirname ${0}`"

. ${BDIR}/utils.inc.sh

# load config
#
_FIREFOX_PROFILE="`getConfig "FIREFOX_PROFILE"`"

if [ $? -ne 0 ]; then
	echo "No Firefox profile path configured. Define FIREFOX_PROFILE in your ${GIT_JIRA_CONFIG_FILE_PATH} config in your home directory or through the environment variable GIT_JIRA_FIREFOX_PROFILE or through your Git config as git-jira.firefox-profile config. "
	exit 1
fi 

_CROWD_PATH="`getConfig "CROWD_PATH"`"

# if not configured, use / by default
#
if [ -z "${_CROWD_PATH}" ]; then
	_CROWD_PATH="/"
fi

_JIRA_URL="`getConfig "JIRA_URL"`"

if [ $? -ne 0 ]; then
	echo "No JIRA URL configured. Define JIRA_URL in your ${GIT_JIRA_CONFIG_FILE_PATH} config in your home directory or through the environment variable GIT_JIRA_JIRA_URL or through your Git config as git-jira.jira-url config. "
	exit 1
fi 

#
# check and prepare configs ...
#

# TODO validate JIRA URL

_JIRA_HOST="`echo ${_JIRA_URL} | sed 's+^https\{0,1\}://\([^/]*\)\(/.*\)$+\1+g'`"

# TODO check if the host name has valid format
#

if [ -d "${_FIREFOX_PROFILE}" ] && [ -f "${_FIREFOX_PROFILE}/sessionstore.js" ]; then
	# Commented out as the cookie is printed out to stdout. This would pollute the 
	# output. There might be a an option "--verbose" or "--debug". 
	#
	# echo "Using configured profile ${_FIREFOX_PROFILE}"
	_SESSIONSTORE_JS_FILE="${_FIREFOX_PROFILE}/sessionstore.js"
else
	echo "No Firefox profile directory found. Exit."
	exit 1
fi



# Cookies are stored in 
# 	windows[0].cookies
#
# They provide
# 	["host|name|path|value"]

_SESSION_COOKIE_JSON_PARSER="$(cat <<EOS
	var json = eval('('+ readline() +')'),
		cookies, i, c, s = '';
		
	try {
		cookies = json.windows[0].cookies
			
		for (i = 0; i < cookies.length; i++) {
			c = cookies[i];
			
			if (c.host === '${_JIRA_HOST}' && (c.path == '${_CROWD_PATH}' && c.name == 'crowd.token_key')) {
				s += c.name + '=' + c.value;
				
				break;
			}
		}
		
		if (s === '') {
			quit(10);
		}
		
		print(s);
	} catch(e) {
		quit(12);
	}
EOS
)"

_COOKIES="`cat ${_SESSIONSTORE_JS_FILE} | ${JS_INTERPRETER_BIN} -e "${_SESSION_COOKIE_JSON_PARSER}"`"

if [ $? -eq 10 ] || [ -z "${_COOKIES}" ]; then
	echo "No Crowd token cookie found in the current Firefox instance."
	echo "Check if Firefox is running and that you are logged in in JIRA."
	exit 1
elif [ $? -eq 12 ]; then
	echo "Error while getting session cookie from Firefox."
	echo "Check if Firefox is running."
	exit 2
fi


echo "${_COOKIES}"
