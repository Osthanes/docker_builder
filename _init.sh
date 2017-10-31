#!/bin/bash

#********************************************************************************
# Copyright 2014 IBM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#********************************************************************************

#############
# Colors    #
#############
export green='\e[0;32m'
export red='\e[0;31m'
export label_color='\e[0;33m'
export no_color='\e[0m' # No Color

########################################
# default values to build server names #
########################################
# beta servers
BETA_API_PREFIX="api-ice"
BETA_REG_PREFIX="registry-ice"
# default servers
DEF_API_PREFIX="containers-api"
DEF_REG_PREFIX="registry"
export MODULE_NAME="docker-builder"

##################################################
# Simple function to only run command if DEBUG=1 # 
### ###############################################
debugme() {
  [[ $DEBUG = 1 ]] && "$@" || :
}
export -f debugme 
installwithpython27() {
    echo "Installing Python 2.7"
    sudo apt-get update &> /dev/null
    sudo apt-get -y install python2.7 &> /dev/null
    python --version 
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py &> /dev/null
    python get-pip.py --user &> /dev/null
    export PATH=$PATH:~/.local/bin
    if [ -f icecli-3.0.zip ]; then 
        debugme echo "there was an existing icecli.zip"
        debugme ls -la 
        rm -f icecli-3.0.zip
    fi 
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip &> /dev/null
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}
installwithpython34() {
    curl -kL http://xrl.us/pythonbrewinstall | bash
    source $HOME/.pythonbrew/etc/bashrc
    sudo apt-get install zlib1g-dev libexpat1-dev libdb4.8-dev libncurses5-dev libreadline6-dev
    sudo apt-get update &> /dev/null
    debugme pythonbrew list -k
    echo "Installing Python 3.4.1"
    pythonbrew install 3.4.1 &> /dev/null
    debugme cat /home/jenkins/.pythonbrew/log/build.log 
    pythonbrew switch 3.4.1
    python --version 
    echo "Installing pip"
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py &> /dev/null
    python get-pip.py --user
    export PATH=$PATH:~/.local/bin
    which pip 
    echo "Installing ice cli"
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip &> /dev/null
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}

installwithpython277() {
    pushd . 
    cd $EXT_DIR
    echo "Installing Python 2.7.7"
    curl -kL http://xrl.us/pythonbrewinstall | bash
    source $HOME/.pythonbrew/etc/bashrc

    sudo apt-get update &> /dev/null
    sudo apt-get build-dep python2.7
    sudo apt-get install zlib1g-dev
    debugme pythonbrew list -k
    echo "Installing Python 2.7.7"
    pythonbrew install 2.7.7 --no-setuptools &> /dev/null
    debugme cat /home/jenkins/.pythonbrew/log/build.log 
    pythonbrew switch 2.7.7
    python --version 
    echo "Installing pip"
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py &> /dev/null
    python get-pip.py --user &> /dev/null
    debugme pwd 
    debugme ls 
    popd 
    pip remove requests
    pip install --user -U requests 
    pip install --user -U pip
    export PATH=$PATH:~/.local/bin
    which pip 
    echo "Installing ice cli"
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip &> /dev/null
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}
installwithpython3() {

    sudo apt-get update &> /dev/null
    sudo apt-get upgrade &> /dev/null 
    sudo apt-get -y install python3 &> /dev/null
    python3 --version 
    echo "installing pip"
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py 
    python3 get-pip.py --user &> /dev/null
    export PATH=$PATH:~/.local/bin
    which pip 
    echo "installing ice cli"

    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}

if [[ $DEBUG = 1 ]]; then 
    export ICE_ARGS="--verbose"
else
    export ICE_ARGS=""
fi 

set +e
set +x 

###############################
# Configure extension PATH    #
###############################
if [ -n $EXT_DIR ]; then 
    export PATH=$EXT_DIR:$PATH
fi 

#########################################
# Configure log file to store errors  #
#########################################
if [ -z "$ERROR_LOG_FILE" ]; then
    ERROR_LOG_FILE="${EXT_DIR}/errors.log"
    export ERROR_LOG_FILE
fi

#################################
# Source git_util file          #
#################################
source ${EXT_DIR}/git_util.sh

################################
# get the extensions utilities #
################################
pushd . >/dev/null
cd $EXT_DIR 
if [ -n "${OVERRIDE_UTILITIES_BRANCH}" ]; then
    git_retry clone https://github.com/Osthanes/utilities.git -b "${OVERRIDE_UTILITIES_BRANCH}" utilities
else
    git_retry clone https://github.com/Osthanes/utilities.git utilities
fi
popd >/dev/null

#################################
# Source utilities sh files     #
#################################
source ${EXT_DIR}/utilities/ice_utils.sh
source ${EXT_DIR}/utilities/logging_utils.sh

#################################
# Show deprecated message       #
#################################
log_and_echo "$ERROR" "ATTENTION: This job type has been DEPRECATED. Please use the 'Container Registry' build type instead."

########################################################################
# Fix timestamps so that caching will be leveraged on the remove host  #
########################################################################
if [ -z "${USE_CACHED_LAYERS}" ]; then 
    export USE_CACHED_LAYERS="true"
fi 
if [ "${USE_CACHED_LAYERS}" == "true" ] && [ -d .git ]; then 
    if [ "${MAX_CACHING_TIME}x" == "x" ]; then
        MAX_CACHING_TIME=300
    fi
    if [ "${MAX_CACHING_TIME_LEFT}x" == "x" ]; then
        MAX_CACHING_TIME_LEFT=120
    fi
    log_and_echo "$INFO" "Adjusting timestamps for files to allow cached layers"
    tsadj_start_time=$(date +"%s")

    update_file_timestamp() {
        local file_time=$(git log --pretty=format:%cd -n 1 --date=iso $1)
        touch -d "$file_time" "$1"
    }

    old_ifs=$IFS
    IFS=$'\n' 
    FILE_COUNTER=0
    all_file_count=`git ls-files | wc | awk '{print $1}'`
    eta_total=0
    eta_remaining=0
    for file in $(git ls-files)
    do
        update_file_timestamp "${file}"
        FILE_COUNTER=$((FILE_COUNTER+1));
        if ! ((FILE_COUNTER % 50)); then
            # check if we're timeboxed
            if [ $MAX_CACHING_TIME -gt 0 ]; then
                # calculate roughly how much time left
                tsadj_end_time=$(date +"%s")
                tsadj_diff=$(($tsadj_end_time-$tsadj_start_time))
                (( eta_total = all_file_count * tsadj_diff / FILE_COUNTER ));
                (( eta_remaining = eta_total - tsadj_diff ));
                if [ $eta_total -gt $MAX_CACHING_TIME ] && [ $eta_remaining -gt $MAX_CACHING_TIME_LEFT ]; then
                    log_and_echo "$DEBUGGING" "$FILE_COUNTER files processed in `date -u -d @"$tsadj_diff" +'%-Mm %-Ss'`"
                    log_and_echo "$DEBUGGING" "eta total ( `date -u -d @"$eta_total" +'%-Mm %-Ss'` ) and remaining ( `date -u -d @"$eta_remaining" +'%-Mm %-Ss'` )"
                    log_and_echo "$DEBUGGING" "Would take too much time to adjust timestamps, skipping"
                    eta_total=-1
                    break;
                fi 
            fi
            echo -n "."
        fi
        if ! ((FILE_COUNTER % 1000)); then
            tsadj_end_time=$(date +"%s")
            tsadj_diff=$(($tsadj_end_time-$tsadj_start_time))
            log_and_echo "$INFO" "$FILE_COUNTER files processed in `date -u -d @"$tsadj_diff" +'%-Mm %-Ss'`"
        fi
    done
    IFS=$old_ifs
    if [ $eta_total -ge 0 ]; then
        if ((FILE_COUNTER % 1000)); then
            tsadj_end_time=$(date +"%s")
            tsadj_diff=$(($tsadj_end_time-$tsadj_start_time))
            log_and_echo "$INFO" "$FILE_COUNTER files processed in `date -u -d @"$tsadj_diff" +'%-Mm %-Ss'`"
        fi
    fi
    log_and_echo "$INFO" "Timestamps adjusted"
fi 

################################
# Application Name and Version #
################################
# The build number for the builder is used for the version in the image tag 
# For deployers this information is stored in the $BUILD_SELECTOR variable and can be pulled out
if [ -z "$APPLICATION_VERSION" ]; then
    export SELECTED_BUILD=$(grep -Eo '[0-9]{1,100}' <<< "${BUILD_SELECTOR}")
    if [ -z $SELECTED_BUILD ]
    then 
        if [ -z $BUILD_NUMBER ]
        then 
            export APPLICATION_VERSION=$(date +%s)
        else 
            export APPLICATION_VERSION=$BUILD_NUMBER    
        fi
    else
        export APPLICATION_VERSION=$SELECTED_BUILD
    fi 
fi 

if [ -n "$BUILD_OFFSET" ]; then 
    log_and_echo "$INFO" "Using BUILD_OFFSET of $BUILD_OFFSET"
    export APPLICATION_VERSION=$((APPLICATION_VERSION + BUILD_OFFSET))
    export BUILD_NUMBER=$((BUILD_NUMBER + BUILD_OFFSET))
fi

log_and_echo "$INFO" "APPLICATION_VERSION: $APPLICATION_VERSION"

if [ -z $IMAGE_NAME ]; then 
    log_and_echo "$ERROR" "Please set IMAGE_NAME in the environment to desired name"
    export IMAGE_NAME="defaultimagename"
fi 

if [ -f ${EXT_DIR}/builder_utilities.sh ]; then
    source ${EXT_DIR}/builder_utilities.sh 
    log_and_echo "$DEBUGGING" "Validating image name"
    pipeline_validate_full ${IMAGE_NAME} >validate.log 2>&1 
    VALID_NAME=$?
    if [ ${VALID_NAME} -ne 0 ]; then     
        log_and_echo "$ERROR" "${IMAGE_NAME} is not a valid image name for Docker"
        cat validate.log 
        ${EXT_DIR}/print_help.sh
        ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Invalid image name. $(get_error_info)"
        exit ${VALID_NAME}
    else 
        debugme cat validate.log 
    fi 
else 
    log_and_echo "$ERROR" "Warning could not find utilities in ${EXT_DIR}"
    ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to get builder_utilities.sh. $(get_error_info)"
fi 

################################
# Setup archive information    #
################################
if [ -z $WORKSPACE ]; then 
    log_and_echo "$ERROR" "Please set WORKSPACE in the environment"
    ${EXT_DIR}/print_help.sh
    ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to discover namespace. $(get_error_info)"
    exit 1
fi 

if [ -z $ARCHIVE_DIR ]; then
    log_and_echo "$LABEL" "ARCHIVE_DIR was not set, setting to WORKSPACE ${WORKSPACE}"
    export ARCHIVE_DIR="${WORKSPACE}"
fi

if [ "$ARCHIVE_DIR" == "./" ]; then
    log_and_echo "$LABEL" "ARCHIVE_DIR set relative, adjusting to current dir absolute"
    export ARCHIVE_DIR=`pwd`
fi

if [ -d $ARCHIVE_DIR ]; then
  log_and_echo "$INFO" "Archiving to $ARCHIVE_DIR"
else 
  log_and_echo "$INFO" "Creating archive directory $ARCHIVE_DIR"
  mkdir $ARCHIVE_DIR 
fi 
export LOG_DIR=$ARCHIVE_DIR

#############################
# Install Cloud Foundry CLI #
#############################
CF_VER=$(cf -v)
log_and_echo "$INFO" "Existing Cloud Foundry CLI ${CF_VER}"
log_and_echo "$INFO" "Installing Cloud Foundry CLI"
pushd $EXT_DIR >/dev/null
gunzip cf-linux-amd64.tgz &> /dev/null
tar -xvf cf-linux-amd64.tar  &> /dev/null
cf help &> /dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
    log_and_echo "$ERROR" "Could not install the Cloud Foundry CLI"
    ${EXT_DIR}/print_help.sh
    ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to install Cloud Foundry CLI. $(get_error_info)"
    exit $RESULT
fi
CF_VER=$(cf -v)
popd >/dev/null
log_and_echo "$LABEL" "Successfully installed Cloud Foundry CLI ${CF_VER}"

#####################################
# Install IBM Container Service CLI #
#####################################
# Install ICE CLI
log_and_echo "$INFO" "Installing IBM Container Service CLI"
ice help &> /dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
#    installwithpython3
    installwithpython27
#    installwithpython277
#    installwithpython34
    ice help &> /dev/null
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        log_and_echo "$ERROR" "Failed to install IBM Container Service CLI"
        debugme python --version
        if [ "$USE_ICE_CLI" = "1" ]; then
            ${EXT_DIR}/print_help.sh
            ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to install IBM Container Service CLI. $(get_error_info)"
            exit $RESULT
        fi
    else
        log_and_echo "$LABEL" "Successfully installed IBM Container Service CLI"
    fi
fi 

#############################################
# Install the IBM Containers plug-in (cf ic) #
#############################################
if [ "$USE_ICE_CLI" != "1" ]; then
    export IC_COMMAND="${EXT_DIR}/cf ic"
    install_cf_ic
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        exit $RESULT
    fi 
else
    export IC_COMMAND="ice"
fi

##########################################
# setup bluemix env
##########################################
# attempt to  target env automatically
if [ -n "$BLUEMIX_TARGET" ]; then
    # cf not setup yet, try manual setup
    if [ "$BLUEMIX_TARGET" == "staging" ]; then 
        export BLUEMIX_API_HOST="api.stage1.ng.bluemix.net"
    elif [ "$BLUEMIX_TARGET" == "prod" ]; then 
        export BLUEMIX_API_HOST="api.ng.bluemix.net"
    else 
        log_and_echo "$ERROR" "Unknown Bluemix environment specified: ${BLUEMIX_TARGET}, Defaulting to production"
        export BLUEMIX_TARGET="prod"
        export BLUEMIX_API_HOST="api.ng.bluemix.net"
    fi 
else
    CF_API=$(${EXT_DIR}/cf api)
    RESULT=$?
    debugme echo "CF_API: ${CF_API}"
    if [ $RESULT -eq 0 ]; then
        # find the bluemix api host
        export BLUEMIX_API_HOST=`echo $CF_API  | awk '{print $3}' | sed '0,/.*\/\//s///'`
        echo $BLUEMIX_API_HOST | grep 'stage1'
        if [ $? -eq 0 ]; then
            # on staging, make sure bm target is set for staging
            export BLUEMIX_TARGET="staging"
        else
            # on prod, make sure bm target is set for prod
            export BLUEMIX_TARGET="prod"
        fi
    else 
        export BLUEMIX_TARGET="prod"
        export BLUEMIX_API_HOST="api.ng.bluemix.net"
    fi
fi
log_and_echo "$INFO" "Bluemix host is '${BLUEMIX_API_HOST}'"
log_and_echo "$INFO" "Bluemix target is '${BLUEMIX_TARGET}'"
# strip off the hostname to get full domain
CF_TARGET=`echo $BLUEMIX_API_HOST | sed 's/[^\.]*//'`
if [ -z "$API_PREFIX" ]; then
    API_PREFIX=$DEF_API_PREFIX
fi
if [ -z "$REG_PREFIX" ]; then
    REG_PREFIX=$DEF_REG_PREFIX
fi
# build api server hostname
export CCS_API_HOST="${API_PREFIX}${CF_TARGET}"
# build registry server hostname
export CCS_REGISTRY_HOST="${REG_PREFIX}${CF_TARGET}"
# set up the ice cfg
sed -i "s/ccs_host =.*/ccs_host = $CCS_API_HOST/g" $EXT_DIR/ice-cfg.ini
sed -i "s/reg_host =.*/reg_host = $CCS_REGISTRY_HOST/g" $EXT_DIR/ice-cfg.ini
sed -i "s/cf_api_url =.*/cf_api_url = $BLUEMIX_API_HOST/g" $EXT_DIR/ice-cfg.ini
export ICE_CFG="ice-cfg.ini"

################################
# Login to Container Service   #
################################
login_to_container_service
RESULT=$?
if [ $RESULT -ne 0 ] && [ "$USE_ICE_CLI" = "1" ]; then
    exit $RESULT
fi

############################
# enable logging to logmet #
############################
setup_met_logging "${BLUEMIX_USER}" "${BLUEMIX_PASSWORD}"
RESULT=$?
if [ $RESULT -ne 0 ]; then
    log_and_echo "$WARN" "LOGMET setup failed with return code ${RESULT}"
fi

################################
# Get the namespace            #
################################
get_name_space
RESULT=$?
if [ $RESULT -ne 0 ]; then
    exit $RESULT
fi 

log_and_echo "$LABEL" "Users namespace is $NAMESPACE"
export REGISTRY_URL=${CCS_REGISTRY_HOST}/${NAMESPACE}
export FULL_REPOSITORY_NAME=${REGISTRY_URL}/${IMAGE_NAME}:${APPLICATION_VERSION}
log_and_echo "$LABEL" "The desired image repository name will be ${FULL_REPOSITORY_NAME}"

log_and_echo "$DEBUGGING" "Validating full repository name"
pipeline_validate_full  ${FULL_REPOSITORY_NAME} >validate.log 2>&1 
VALID_NAME=$?
if [ ${VALID_NAME} -ne 0 ]; then    
    log_and_echo "$ERROR" " ${FULL_REPOSITORY_NAME} is not a valid repository name"
    log_and_echo `cat validate.log` 
    ${EXT_DIR}/print_help.sh
    ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Invalid repository name. $(get_error_info)"
    exit ${VALID_NAME}
else 
    debugme cat validate.log 
fi 

log_and_echo "$LABEL" "Initialization complete"

# run image cleanup if necessary
. $EXT_DIR/image_utilities.sh
