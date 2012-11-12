# Git-JIRA tool suite

This is a shell script based tool suite to retrieve JIRA issues and used them in Git commit messages. It provides tools to retrieve issue summary for a issue key or query issue keys and summaries by Atlassian's "JQL". The prepare-commit-msg script uses this to retrieve the any open issues.

# Intention

Even if I use Eclipse and NetBeans for development and even though Eclipse has a very good Git integration (for example compared to Netbeans) I prefer to use the command line because it's fast(er) and transparent.

But when using the command line you do not have such goodies as Mylyn to integrate your issue tracker into your workflow.

# Technology 

It uses curl to query the JIRA API REST interface, a Spidermonkey Javascript interpreter to parse the response data (in JSON format) and "pluggable" authentication providers to authenticate the API request. For now there's one authentication provider that examines a running Firefox profile's sessionstore.js to get a crowd-token.

The prepare-commit-msg uses these script to retrieve the issue information for the current commit.

## How does the prepare-commit-msg hook know the issue key?

In my case feature branches always have the format e.g. *dev/ISSUE-KEY*. So the prepare commit message hook can examine the current branch name, extract the issue key and use it to query JIRA. 

## Why not using the JIRA CLI?

The main reason is the way one authenticates herself/himself with the CLI tool. The other reason is the speed. The intention was to use this tool suite to prepare a commit message with JIRA issue summaries and for that, the tool needs to be fast. Starting the Java VM adds too much time starting the tool.  

## Why curl?

Because it's fast. Sure, parsing the JSON through the Spidermonkey interpreter is a bit dirty, but it works fine. I've used this before in Nagios checks to monitor APIs.

## Why using e.g. Firefox's session data for authentication 

In my (the authors) case, I run my IDE on KDE and have Firefox open to see and manage my JIRA issues. So, I've already been authenticated. When I wrote the first implementation if these scripts I've used a authentication script that authenticates against Crowd and stores the cookie data in a file. But then I thought that there must be already the authentication data being generated in Firefox. 

## Configuration

The tools can be graduating configured in these ways:

1. Environment variables
2. The Git config (so it is possible to configure per-repository data)
3. A configuration file

Which means that environment variables take precedence over the Git configuration and the Git config takes precedence over the configuration file.

### Options

* **FIREFOX_PROFILE**	The absolute path to your Firefox profile directory 
* **CROWD_PATH**	The crow path (used for cookie examination) (usually /)
* **JIRA_URL**		The JIRA URL (e.g. http://project.acme.com/jira)
* **CURL_OPTS**		Optionally: additional curl options (some options will be overrided)
* **COOKIE_PROVIDER**	The authentication provider (for now, there's only "firefox") 

### Enrivonment variables

Export your configuration option through GIT_JIRA_**\<OPTION NAME IN UPPER CASE WITH UNDERSCORES\>**

### Git

Configure Git this way:

```
$ git config --local "git-jira.*<option name in lower case with hyphens>*" "<VALUE>"
```

```
[git-jira]
	**<option name in lower case with hyphens>** = <VALUE>
``` 

### Configuration file

Create a configuration file:

```
$ vi ~/.git-jira/config
```

Use this style (without quotation):

```
*<OPTION NAME IN UPPER CASE WITH UNDERSCORES>*=<VALUE>
``` 

# Requirements

This scripts have three major requirements:

* Mozillas Spidermonkey or any compatible Javascript interpreter (smjs on Debian-compatible, "js" on RedHat-compatible)
* curl
* JIRA and Crowd (it is quite possible to extend the authentication provider to use Standalone-JIRA authentication data)

# How to use

* Install all requirements
* Place all these scripts in a directory of your choice (for example into $HOME/bin)
* Symlink the prepare-commit-msg into your Git repository's .git/hooks directory or call it subsequently in your custom Git hook script
* Configure your setup (see the configuration section above) 

# ToDo and other ideas

## Major
* Write other authentication providers for Chrome, Safari and maybe Opera (an for those who got Internet Explorer running under Linux or Mac, IE as well)
* Extend configuration mechanism to make issue querying configurable  

## Minor
* Use alternative JSON/XML parser tools to process the returned data or add support for the NodeJs Platform as alternative Javascript interpreter  
* Separate tool suite into an alternate JIRA CLI and scripts that filter the data for use in the Git hooks
* Write an interactive authentication provider

This tool suite might also be implemtented with NodeJs in the future.

# License 

This code is licensed under the MIT license.
