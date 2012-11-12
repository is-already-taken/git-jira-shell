#!/bin/bash

# Get JIRA issues 
#
#
# Author Thomas Lehmann (thomas.lehmann@stueckseln.de) 2012
#

BDIR="`dirname ${0}`"

. ${BDIR}/utils.inc.sh

# get configuration
_JIRA_URL="`getConfig "JIRA_URL"`"

if [ $? -ne 0 ]; then
	echo "No JIRA URL configured. Define JIRA_URL in your ${GIT_JIRA_CONFIG_FILE_PATH} config in your home directory or through the environment variable GIT_JIRA_JIRA_URL or through your Git config as git-jira.jira-url config. "
	exit 1
fi

_CURL_OPTS="`getConfig "CURL_OPTS"`"

_COOKIE_PROVIDER="`getCookieProvider`"

if [ $? -ne 0 ]; then
	echo "No cookie provider configured. Exit."
	exit 1
fi

# call provider to get cookie
#
_COOKIE="`${_COOKIE_PROVIDER}`"

# check if the session is still valid
# curl: (22) The requested URL returned error: 404
if [[ `curl ${_CURL_OPTS} -f --cookie "${_COOKIE}" -X GET -H "Content-Type: application/json" ${_JIRA_URL}/rest/api/2/status 2>&1` =~ ^.*401$ ]]; then
	echo "You are not authorized to access JIRA with the current session cookie. "
	exit 1
fi


if ! [[ $1 =~ ^[A-Z]{2,10}-[0-9]{1,5}$ ]]; then
	echo "Not the correct issue format SSSSSSSS-NNNN (e.g. JENKINS-361)"
	exit 1
fi

_JSON="`curl ${_CURL_OPTS} -s --cookie "${_COOKIE}" -X GET -H "Content-Type: application/json" ${_JIRA_URL}/rest/api/2/issue/${1}`"


_JIRA_ISSUES_JSON_PARSER="$(cat <<EOS
	var json;
	
	try {
		json = eval('('+ readline() +')');	
	} catch (e) {
		print("Output not parsable");
		quit(11);
	}
	
	try {
		if (json.errorMessages) {
			// Server returned error
			print("Server answered with error \"" + json.errorMessages[0] + "\"");
			quit(10);
		}
		
		if (!json.fields) {
			// unknown error, fields missing
			print("Fields attribute missing in output"); 
			quit(13);
		}
		
		print(json.fields.summary);
	} catch (e) {
		print("Exception while parsing server output ("+ e +")");
		quit(12);
	}
EOS
)"

echo "${_JSON}" | $JS_INTERPRETER_BIN -e "${_JIRA_ISSUES_JSON_PARSER}"
