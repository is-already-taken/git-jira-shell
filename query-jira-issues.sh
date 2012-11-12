#!/bin/bash

# Query JIRA issues by JQL 
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
_COOKIE="`${_COOKIE_PROVIDER}`"

# check if the session is still valid
# curl: (22) The requested URL returned error: 404
if [[ `curl ${_CURL_OPTS} -f --cookie "${_COOKIE}" -X GET -H "Content-Type: application/json" ${_JIRA_URL}/api/2/status 2>&1` =~ ^.*401$ ]]; then
	echo "You are not authorized to access JIRA with the current session cookie. "
	exit 1
fi

# TODO query the config for 
#


if [ $# -eq 0 ]; then 
	echo "Expected at least JQL query."
	exit 1
fi


MAX_RESULTS=10

if [ $# -ge 2 ]; then
	MAX_RESULTS=${2}
fi


_POST_JQL_JSON="{
	\"jql\": \"${1}\",
	\"maxResults\": ${MAX_RESULTS}
"

if [ $# -ge 3 ]; then
	# shift away JQL and max-results
	shift
	shift

	# build JSON array of passed paramters
	FIELDS=""

	while [ $# -gt 0 ]; do
		FIELDS="${FIELDS}\"${1}\""

		# if it's not the last...
		if [ $# -gt 1 ]; then
			FIELDS="${FIELDS},"
		fi

		shift
	done
	
	_POST_JQL_JSON="${_POST_JQL_JSON},
 \"fields\": [${FIELDS}]"
fi

_POST_JQL_JSON="${_POST_JQL_JSON} }"

_JSON="`curl ${_CURL_OPTS} -s --cookie "${_COOKIE}" -X POST -d "${_POST_JQL_JSON}" -H "Content-Type: application/json" ${_JIRA_URL}/rest/api/2/search`"

_JIRA_ISSUES_JSON_PARSER="$(cat <<EOS
	var json, i, issue;
	
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
		
		for (i = 0; i < json.issues.length; i++) {
			issue = json.issues[i];
			
			print(issue.key + " " + issue.fields.summary);
		}
	} catch (e) {
		print("Exception while parsing server output ("+ e +")");
		quit(12);
	}
EOS
)"

echo "${_JSON}" | $JS_INTERPRETER_BIN -e "${_JIRA_ISSUES_JSON_PARSER}"

if [ $? -eq 0 ]; then
	echo "${JSON}"
fi

