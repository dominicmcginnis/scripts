#!/bin/bash

# Configure defaults
export environment="INT"
export appToTest="TPO"
export baseOsbUrl="https://my.osb.url.com/v2"
export siteUrl="http://my.app.url/tpo"
export jenkinslink=""
export credentials="{ Password: 'foobar', Realm: '1234BFG', SiteURL: 'https://my.site.com', UserName: 'my.user@user.com'}"
export REALM="BE11158783"

validStatus=["200","201","300","301"]

serviceDown="false"
sessionId=""
statusOutLog=""

#Setup input options
while test $# -gt 0; do
    case "$1" in
            -h|--help)
                    echo "Script for executing service checks"
                    echo " "
                    echo "Usage of the script looks like the following:"
                    echo "     serverCheck.sh -e <env> -a <app> -ou <osbUrl> -au <appUrl> -j <jenkinsJobUrl>"
                    echo " "
                    echo "options:"
                    echo "-h, --help                show brief help" 
                    echo "-e, --env=ENVIRONMENT     Specify Environment running against, mainly used in reporting. (Default: INT)"
                    echo "-a, --app=APPLICATION     Specify Application running against, mainly used in reporting. (Default: TPO"
                    echo "-ou, --osbUrl=URL     	Specify URL for OSB service. (Default: https://my.osb.url.com/v2)"
                    echo "-au, --appUrl=URL     	Specify Application URL. (Default: http://my.app.url/tpo)"
                    echo "-j,  --jenkins=JENKINS_JOB_LINK     	Specify the link back to the jenkins job.  (Default: empty)"
                    echo "-c, --credentials 		Credentials used for the check{ Password: '', Realm: '', SiteURL: '', UserName: ''}"
                    echo "-r, --realm 				Realm used for the Directory Services check"
                    exit 0
                    ;;
            -e)
                    shift
                    if test $# -gt 0; then
                            export environment=$1
                    else
                            echo "no env specified"
                            exit 1
                    fi
                    shift
                    ;;
            --env*)
                    export environment=`echo $1 | sed -e 's/^[^=]*=//g'`
                    shift
                    ;;
            -a)
                    shift
                    if test $# -gt 0; then
                            export appToTest=$1
                    else
                            echo "no app specified"
                            exit 1
                    fi
                    shift
                    ;;
            --app*)
                    export appToTest=`echo $1 | sed -e 's/^[^=]*=//g'`
                    shift
                    ;;
            -ou)
                    shift
                    if test $# -gt 0; then
                            export baseOsbUrl=$1
                    else
                            echo "no osb url specified"
                            exit 1
                    fi
                    shift
                    ;;
            --baseOsbUrl*)
                    export baseOsbUrl=`echo $1 | sed -e 's/^[^=]*=//g'`
                    shift
                    ;;
            -au)
                    shift
                    if test $# -gt 0; then
                            export siteUrl=$1
                    else
                            echo "no app URL specified"
                            exit 1
                    fi
                    shift
                    ;;
            --appUrl*)
                    export siteUrl=`echo $1 | sed -e 's/^[^=]*=//g'`
                    shift
                    ;;
            -j)
                    shift
                    if test $# -gt 0; then
                            export jenkinslink=$1
                    else
                            echo "no jenkins link specified"
                            exit 1
                    fi
                    shift
                    ;;
            --jenkins*)
                    export jenkinslink=`echo $1 | sed -e 's/^[^=]*=//g'`
                    shift
                    ;;
            -c)
                    shift
                    if test $# -gt 0; then
                            export credentials=$1
                    else
                            echo "no credentials specified"
                            exit 1
                    fi
                    shift
                    ;;
            --credentials*)
                    export credentials=`echo $1 | sed -e 's/^[^=]*=//g'`
                    shift
                    ;;
            -r)
                    shift
                    if test $# -gt 0; then
                            export REALM=$1
                    else
                            echo "no realm specified"
                            exit 1
                    fi
                    shift
                    ;;
            --realm*)
                    export REALM=`echo $1 | sed -e 's/^[^=]*=//g'`
                    shift
                    ;;
            *)
                    break
                    ;;
    esac
done

# Every config must have a getSessionId in order to establish a session for executing APIs
# Take special note of the JSON in the data arrays, it is not a standard format given the parsing 
# engine is python, the way the Key/Val/{}/[] are quoted must be enforced.
export jsonConfig=$(< <(cat <<EOF
{
	"getSessionId" : {
		"name" : "Create Session",
		"url" : "${baseOsbUrl}/auth/temp/sessions/",
		"data" : "${credentials}",
		"headers" : [],
		"method" : "POST",
		"jsonResponsePath" : "('TPOLoginResponse' 'SecurityContext' 'SessionId')"
	},
	"OSBLoginCheck" : {
		"name" : "Login Service (deprecated soon)",
		"url" : "${baseOsbUrl}/auth/temp/sessions/",
		"data" : "${credentials}",
		"headers" : [],
		"method" : "POST",
		"jsonResponsePath" : ""
	},
	"TPOSiteCheck" : {
		"name" : "TPO Site",
		"url" : "${siteUrl}",
		"data" : "",
		"headers" : [],
		"method" : "GET",
		"jsonResponsePath" : ""
	},
	"MediaSvcs_IdentitySvcsCheck" : {
		"name" : "Media_Identity Srvcs",
		"url" : "${baseOsbUrl}/mediaserver",
		"data" : "",
		"headers" : ["OperationName:SaveFile", "TokenCreator:encompass", "TokenExpiration:1484384"],
		"method" : "GET",
		"jsonResponsePath" : ""
	},
	"getOSBTPOSessionId" : {
		"name" : "Create Session",
		"url" : "${baseOsbUrl}/auth/sessions/",
		"data" : "${credentials}",
		"headers" : [],
		"method" : "POST",
		"jsonResponsePath" : ""
	},
	"OSBDirectoryServiceCheck" : {
		"name" : "Directory Service",
		"url" : "${baseOsbUrl}/directory/host?InstanceID=${REALM}",
		"data" : "",
		"headers" : [],
		"method" : "GET",
		"jsonResponsePath" : ""
	},
	"PipelineServicecheck" : {
		"name" : "Pipeline Service",
		"url" : "${baseOsbUrl}/loan/pipeline/cursors",
		"data" : "{ }",
		"headers" : [],
		"method" : "POST",
		"jsonResponsePath" : ""
	},
	"EVP_User_Setting_Check" : {
		"name" : "EVP User Setting API",
		"url" : "${baseOsbUrl}/vendor/transactions",
		"data" : "{ KEY: 'value', KEY2: 'value2' }",
		"headers" : [],
		"method" : "POST",
		"jsonResponsePath" : ""
	},
	"EVP_Pricing_Check" : {
		"name" : "EVP Pricing API",
		"url" : "${baseOsbUrl}/vendor/transactions",
		"data" : "{ KEY: 'value', KEY2: [{ key: 'val', key: 'val'}], KEY3: { key: 'val' }}",
		"headers" : [],
		"method" : "POST",
		"jsonResponsePath" : ""
	}
}
EOF
))

export chatConfig=$(< <(cat <<EOF
{
	"INT": {
		"room": "ROOM_ID",
		"authToken": "AUTH_TOKEN"
	},
	"PEGL": {
		"room": "ROOM_ID",
		"authToken": "AUTH_TOKEN"
	}
}
EOF
))

log() {
	echo -e $1 >&2
}

# Use python to parse our Json Config string based on the check and it's key
parseJsonConfig() {
	export check=$1
	export checkKey=$2

	local value=$(echo ${jsonConfig} | python -c 'import os, sys, json; mycheck = os.getenv("check"); mycheckKey = os.getenv("checkKey"); print json.load(sys.stdin)[mycheck][mycheckKey]')
	echo "${value}"
}

# Use python to parse our Chat Config string based on the environment and it's key
parseChatConfig() {
	export envName=$1
	export envKey=$2

	local value=$(echo ${chatConfig} | python -c 'import os, sys, json; myenvName = os.getenv("envName"); myenvKey = os.getenv("envKey"); print json.load(sys.stdin)[myenvName][myenvKey]')
	echo "${value}"
}

# Utilize an array to walk the required JSON path to get the value to return from the response
# Using python for the json parsing
getJsonResponseValue() {
	export myJsonVal=$1
	declare -a getResponseValJsonPath=$2

	for i in "${getResponseValJsonPath[@]}"; do
		export key=$i
		export myJsonVal=$(echo ${myJsonVal} | python -c 'import os, sys, json; myKey = os.getenv("key"); print json.dumps(json.load(sys.stdin)[myKey])')
	done
	echo ${myJsonVal}
}

# Execute the health check
runHealthCheck() {
	local check=$1

	# Establish all of the curl params from the check config json object
	local url=$(parseJsonConfig ${check} "url")
	local method=$(parseJsonConfig ${check} "method")
	local dataArgs=$(parseJsonConfig ${check} "data")
	local headers="$(parseJsonConfig ${check} "headers")"
	local getResponseValJsonPath=$(parseJsonConfig ${check} "jsonResponsePath")
	local getHttpCode=""

	local curlCommand="curl --connect-timeout 30 --max-time 60 -s -X ${method}"
	# Ignore the response body, just capture the HTTP CODE
	if [[ "${getResponseValJsonPath}" == "" ]]; then
		getHttpCode="-i -o /dev/null -w %{http_code}"
	fi

	if [[ "${headers}" == "[]" ]]; then
		headers=$(echo -e  -H 'Content-Type:application/json' -H 'elli-session:'${sessionId} | perl -pe 's/"//g')
	else
		# The perl script here attempts to format the python "dict" value from the json object into bash friendly stirngs for CURL
		headers=$(echo -e  -H 'Content-Type:application/json' -H 'elli-session:'${sessionId} -H ${headers} | perl -pe 's/\[u//; s/\]//; s/, u/ -H /g; s/'\''//g; s/ -H / -H /g; s/: /:/g; s/"//g')
	fi

	# execute the curl command capturing the response
	local response=""
	if [[ "${dataArgs}" == "" ]]; then
		curlCommand=$(echo -e ${curlCommand} ${getHttpCode} ${headers} \"${url}\")
		log "Executing curl command: ${curlCommand}"
		response=$(curl --connect-timeout 30 --max-time 60 -s -X ${method} ${getHttpCode} ${headers} "${url}")
	else
		curlCommand=$(echo -e ${curlCommand} ${getHttpCode} ${headers} \"${url}\" -d \"${dataArgs}\")
		log "Executing curl command: ${curlCommand}"
		response=$(curl --connect-timeout 30 --max-time 60 -s -X ${method} ${getHttpCode} ${headers} "${url}" -d "${dataArgs}")
	fi 

	# If our response is not being ignored, then we need to parse it for our value
	if [[ ! "${getResponseValJsonPath}" == "" ]]; then
		response=$(getJsonResponseValue ${response} "${getResponseValJsonPath}")
	fi

	# echo out the response value or http code for capture
	echo ${response}

	# Return an exit code indicating check pass/fail
	if [[ "${getResponseValJsonPath}" == "" ]]; then
		local valid=0
		if [[ "${validStatus[@]}" =~ "${response}" ]]; then
			valid=1
		fi	
		return ${valid}
	fi
}

## Begin Execute Checks
executeChecks() {
	# Get the checks to execute as an arry (the perl command will format the python dict json value into a bash array variable)
	declare -a checks=$(echo ${jsonConfig} | python -c 'import sys, json; print json.load(sys.stdin).keys()' | perl -pe 's/\[u/(/; s/\]/)/; s/, u/ /g')

	log "Getting SessionId..."
	# Get a valid session
	export sessionId=$(runHealthCheck "getSessionId")
	if [[ "${sessionId}" == "" ]]; then
		log "Get session failed!"
		serviceDown="true"
	fi

	# Get the count of checks, not including getSessionId to be used in the TAP results
	checkTotal=`expr ${#checks[@]} - 1`
	$(echo "1..${checkTotal}" > serviceChecks.tap)

	# Loop through the checks building our TAP results and Console Output strings
	outputLog=""
	count=0
	for i in "${checks[@]}"; do
		export check=$i
		if [[ ! "${check}" == "getSessionId" ]]; then
			count=`expr ${count} + 1`
			log "Running check: ${check}..."
			local checkName=$(parseJsonConfig ${check} "name")

			checkReturnVal=$(runHealthCheck "${check}")
			if [[ $? -eq 0 ]]; then 
				log "${check} failed!"
				serviceDown="true"
				$(echo "${tapResults}not ok ${count} - ${checkName} failed: ${checkReturnVal}" >> serviceChecks.tap)
				outputLog="${outputLog}${checkName} response code: ${checkReturnVal} \n"
			else
				log "${check} passed."
				$(echo "${tapResults}ok ${count} - ${checkName} passed: ${checkReturnVal}" >> serviceChecks.tap)
			fi
			statusOutLog="${statusOutLog}${checkName} response code: ${checkReturnVal} \n"
		fi
	done
	echo ${outputLog}
	if [[ "${serviceDown}" == "true" ]]; then
		return 0
	else 
		return 1
	fi
}

# Send out email notifications
sendEmailNotification() {
	local output=$1
	mail -s "A Service for ${appToTest} on ${environment} is down" foo.bar@company.com <<< ${output}
}

sendHipChatNotification() {
	local MESSAGE=$1
	local ROOM_ID=$(parseChatConfig ${environment} "room")
	local AUTH_TOKEN=$(parseChatConfig ${environment} "authToken")

	local dataArgs=$(echo -e "{\"color\": \"red\", \"message_format\": \"text\", \"message\": \"${MESSAGE}\"}")

	log "Sending ServiceChecks hipchat notification..."
	log 'curl --connect-timeout 30 --max-time 60 -s -H "Content-Type: application/json" \
	     -X POST \
	     -d' "${dataArgs}"' \
	     https://api.hipchat.com/v2/room/2704310/notification?auth_token=ig5J9PFybM0C9TgRa8hxRh2Q6ASt5t1aly19JRD9
	    '
	#Send to ServiceChecks room
	curl --connect-timeout 30 --max-time 60 -s -H "Content-Type: application/json" \
	     -X POST \
	     -d "${dataArgs}" \
	     https://api.hipchat.com/v2/room/2704310/notification?auth_token=Z1z8slcRlKROWOvNxzo9xK5gHLmeKWHlbCF61Ea7

	log "Sending ServiceChecks hipchat notification..."
	log 'curl --connect-timeout 30 --max-time 60 -s -H "Content-Type: application/json" \
	     -X POST \
	     -d' "${dataArgs}"' \
	     https://api.hipchat.com/v2/room/${ROOM_ID}/notification?auth_token=${AUTH_TOKEN}
	    '
	#Send to AppToTest specified room
	curl --connect-timeout 30 --max-time 60 -s -H "Content-Type: application/json" \
	     -X POST \
	     -d "${dataArgs}" \
	     https://api.hipchat.com/v2/room/${ROOM_ID}/notification?auth_token=${AUTH_TOKEN}

}

sendTestHipChatNotification() {
	local MESSAGE=$1

	local dataArgs=$(echo -e "{\"color\": \"red\", \"message_format\": \"text\", \"message\": \"${MESSAGE}\"}")

	log "Sending test hipchat notification..."
	log 'curl --connect-timeout 30 --max-time 60 -s -H "Content-Type: application/json" \
	     -X POST \
	     -d' "${dataArgs}"' \
	     https://api.hipchat.com/v2/room/<TEST_ROOM>/notification?auth_token=<AUTH_TOKEN>
	    '
	#Send to Test room
	curl --connect-timeout 30 --max-time 60 -s -H "Content-Type: application/json" \
	     -X POST \
	     -d "${dataArgs}" \
	     https://api.hipchat.com/v2/room/<TEST_ROOM>/notification?auth_token=<AUTH_TOKEN>

}

# Run the body of the script
returnVal=0
output=$(executeChecks)
if [[ $? -eq 0 ]]; then
	MESSAGE="$(echo -e "@all A Service for ${appToTest} on ${environment} is down! ${output}" | perl -pe "s/ \n/; /g; s/u'//g; s/\r//g; s/\"//g; s/}/ /g; s/{/ /g; ")"
	if [[ "${buildNumber}" != "" ]]; then
		MESSAGE="${MESSAGE} CheckLink: ${jenkinslink}"
	fi
	echo -e "${MESSAGE}"
	# Disabled as box running on doesn't support "mail"
	#sendEmailNotification "${output}"
	if [[ "${environment}" == "TEST" ]]; then
		sendTestHipChatNotification "${MESSAGE}"
	else
		sendHipChatNotification "${MESSAGE}"
	fi
	returnVal=-1
else
	log "${statusOutLog}"
fi
exit ${returnVal}
