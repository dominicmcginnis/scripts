#!/bin/bash

# Configure defaults
export environment="FOO"
export appToTest="BAR"
export baseOsbUrl="https://www.google.com"
export siteUrl="http://www.google.com"
export jenkinslink=""

#Setup input options
while test $# -gt 0; do
    case "$1" in
            -h|--help)
                    echo "Script for executing service checks"
                    echo " "
                    echo "Usage of the script looks like the following:"
                    echo "     serverCheck.sh <env> <app> <osbUrl> <appUrl> <jenkinsJobUrl>"
                    echo " "
                    echo "options:"
                    echo "-h, --help                show brief help" 
                    echo "-e, --env=ENVIRONMENT     Specify Environment running against, mainly used in reporting. (Default: INT)"
                    echo "-a, --app=APPLICATION     Specify Application running against, mainly used in reporting. (Default: TPO"
                    echo "-ou, --osbUrl=URL     	Specify URL for OSB service. (Default: https://encompass-int-api.elliemae.com/v2)"
                    echo "-au, --appUrl=URL     	Specify Application URL. (Default: http://tpo-int.dco.elmae/tpo)"
                    echo "-j,  --jenkins=JENKINS_JOB_LINK     	Specify the link back to the jenkins job.  (Default: empty)"
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
            *)
                    break
                    ;;
    esac
done
