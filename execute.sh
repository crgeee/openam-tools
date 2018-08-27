#!/bin/bash
cd "$(dirname "$0")"

while getopts p: option
do
    case "${option}" in
        p) PASS=${OPTARG};;
    esac
done

# Set variables
LOG_HEADER="OpenAM Config"
OPENAM_DIR=/openam-13
CONFIG_DIR=${OPENAM_DIR}/config
DATE=`date +%Y%m%d.%H%M%S`
CONFIGURATOR_TOOL="SSOConfiguratorTools-13.0.0"
SSOADMIN_TOOL="SSOAdminTools-13.0.0"

function log {
    local readonly level="$1"
    local readonly message="$2"
    echo -e "${LOG_HEADER} [$level]: $2"
}

# Configure OpenAM using Configurator tool
log "START" "Configuring OpenAM via run.sh script."

# Check if running as root
if [ "$EUID" -ne 0 ]
then 
    log "ERROR" "Please run script as sudo/root and try again."
    exit 1
fi

# Check if config folder exists
if [ ! -d "${CONFIG_DIR}" ]
then
    log "INFO" "${CONFIG_DIR} doesn't exist. Creating folder now."
    install -m 755 -g tomcat -o tomcat -d ${CONFIG_DIR}
else
    log "INFO" "${CONFIG_DIR} exists. That's a good thing."
fi

# Check if config folder is empty
if [ "$(ls -A ${CONFIG_DIR})" ]
then
    log "ERROR" "${CONFIG_DIR} is not empty. Please remove the directory and reboot this machine before trying again."
    exit 1
else
    log "INFO" "${CONFIG_DIR} is empty. That's a good thing."
fi

# Check configurator .zip exists and extract
if [ -f ${CONFIGURATOR_TOOL}.zip ]
then
    log "INFO" "${CONFIGURATOR_TOOL}.zip found. Extracting to /${CONFIGURATOR_TOOL}."
    unzip -o -qq ./${CONFIGURATOR_TOOL}.zip -d ./${CONFIGURATOR_TOOL}
else
    log "WARN" "${CONFIGURATOR_TOOL}.zip not found in this directory."
fi

# Check ssoadmin .zip exists and extract
if [ -f ./${SSOADMIN_TOOL}.zip ]
then
    log "INFO" "${SSOADMIN_TOOL}.zip found. Extracting to ./admin."
    unzip -o -qq ./${SSOADMIN_TOOL}.zip -d ./admin
else
    log "WARN" "${SSOADMIN_TOOL}.zip not found in this directory."
fi

# Check if -p flag has a value. If not, decrypt pass file and input into config.properties
if [ ! -z ${PASS} ]
then
    log "INFO" "Detected -p flag. Using provided password for the configuration."
else
    log "INFO" "Using pass file for setting admin passwords."
    if [ -f ./pass  ]
    then
        #  SET PASS FILE PASSWORD HERE
        PASS=$(openssl bf -d -a -k password1234! -in pass)
    else
        log "ERROR" "pass file was not found in this directory and -p was not passed. Please use one or the other."
        exit 1
    fi
fi

# Backup config.properties
if [ -e ./config.properties ]
then
    log "INFO" "Creating backup of config.properties file."
    cp ./config.properties ./config.properties.${DATE}.bak
else
    log "ERROR" "config.properties not found. Create this file using the OpenAM sampleconfiguration and try again."
    exit 1
fi

# Find/Replace passwords in config.properties file
sed -i "s/^ADMIN_PWD=/ADMIN_PWD=${PASS}/g" ./config.properties
sed -i "s/^USERSTORE_PASSWD=/USERSTORE_PASSWD=${PASS}/g" ./config.properties

# Run configurator tool
if [ -e ./${CONFIGURATOR_TOOL}/openam-configurator-tool-13.0.0.jar ] 
then
    log "INFO" "Running ${CONFIGURATOR_TOOL}/openam-configurator-tool-13.0.0.jar."
    # Can't use variables inside java call below so don't change/cleanup
    java -jar ./SSOConfiguratorTools-13.0.0/openam-configurator-tool-13.0.0.jar --file ./config.properties
else
    log "ERROR" "${CONFIGURATOR_TOOL}/openam-configurator-tool-13.0.0.jar not found. Copy SSOConfiguratorTools.zip into this directory and try again."
    exit 1
fi

# Check JAVA_HOME variable
if [ ! -z $JAVA_HOME ]
then
    log "INFO" "JAVA_HOME is set to $JAVA_HOME."
else
    log "WARN" "JAVA_HOME is set to \"$JAVA_HOME\" and detected as unset. This may result in issues for ssoadmin setup. Attempting to set. If this installation fails, set the JAVA_HOME variable manually and run again."
    export JAVA_HOME=/usr/lib/jvm/jre-openjdk
    log "INFO" "JAVA_HOME is set to $JAVA_HOME."
fi

# Check if ./admin exists
if [ ! -d ./admin ]
then
    log "ERROR" "./admin folder was not found and admin tools installation was skipped. Please copy ${SSOADMIN_TOOL}.zip into this directory and try again."
    exit 1
fi

# Begin admin tool setup
log "INFO" "Begin ssoadmin tools install."
cd ./admin
./setup -p "/openam-13/config" -d "/openam-13/openam-tools/admin/debug" -l "/openam-13/openam-tools/admin/log" --acceptLicense

# Validate ssoadm tool exists before creating a password
if [ -f ./openam/bin/ssoadm ]
then
    log "INFO" "ssoadmin tools install completed."
else
    log "ERROR" "ssoadm was not found in ./openam/bin/. Please check the install and try again."
    exit 1
fi

# Create temporary pass file for ssoadm commands. Can't be hashed.
log "INFO" "Creating temporary cleartext pass file in /admin directory. This will be removed at the end of the script. "
echo "${PASS}" >> ./pass

# ssoadmin requires the pass file to be 400
chmod 400 ./pass

# TODO: Run ssoadm commands here
log "INFO" "Begin ssoadm commands for global OpenAM configuration."

# IA issue #142 artf468865
./openam/bin/ssoadm set-attr-defs -u amadmin -f ./pass -s iPlanetAMAuthService -t organization -a "iplanet-am-auth-lockout-warn-user=2" "iplanet-am-auth-login-failure-lockout-mode=true" "iplanet-am-auth-login-failure-count=3" "iplanet-am-auth-login-failure-duration=15"

# IA issue #143 artf468872
./openam/bin/ssoadm set-attr-defs -u amadmin -f ./pass -s iPlanetAMAuthLDAPService -t organization -a "iplanet-am-auth-ldap-min-password-length=15"

# Ensure PASS variable is removed from memory and file deleted from ./admin folder
log "INFO" "Removing pass file from ./admin directory. If you want to continue using admin tools, you will need to recreate this pass file."
rm -rf ./pass 
unset PASS

log "COMPLETE" "OpenAM Configuration completed via run.sh script. Please remove this directory."

exit 0
