#!/usr/bin/env bash

DIR=$(pwd)

# GLOBAL CORE VARIABLES
MAJOR=""
PLATFORM=""
VERSION_NAME=""
VERSION_NUMBER=""

# GLOBAL OPTIONAL VARIABLES
COMMIT_ID=""

function show_help(){
    echo
    echo "  -p | --platform = ex. (ios|huawei|google) - required"
    echo "  -v | --version  = ex. 1.0.0 - required"
    echo "  -n | --number   = ex. 1000000, for ios max length 7 and for other platforms max length 9"
    echo "  -c | --commit   = commit long id - optional"
    echo "  -m | --major    = default: 1, Major version number"
    echo
    exit 0
}

if [[ $# -eq 0 ]]; then
    show_help
fi

# BEGIN
function check_and_set_platform(){
    if [[ $1 =~ ^(google|huawei|ios)$ ]]; then
        PLATFORM=$1
    else
        echo "Platform is not valid - must be [ios,google,huawei]"
        exit 1
    fi
}

function check_and_set_version_name(){
    if [[ $1 =~ ^[0-9]{1,2}.[0-9]{1,2}.[0-9]{1,2}$ ]]; then
        VERSION_NAME=$1
    else
        echo "Version is not valid"
        exit 1
    fi
    
}

while (( $# )); do
    case $1 in
        -p|--platform) check_and_set_platform $2 ;;
        -v|--version)  check_and_set_version_name $2 ;;
        -c|--commmit)  COMMIT_ID=$2 ;;
        -n|--number)   VERSION_NUMBER=$2 ;;
        -m|--major)    MAJOR=$2 ;;
        -h|--help)     show_help ;;
        -*) echo "Unknown flag $1"
            show_help
    esac
    shift
done

if [[ -z $MAJOR ]]; then
    MAJOR=${VERSION_NAME:0:1}
fi

if [ -z $VERSION_NUMBER ]; then
    if [[ $PLATFORM == "ios" ]]; then
        VERSION_NUMBER=$MAJOR$(date +%y%m%d)
    else
        VERSION_NUMBER=$MAJOR$(date +%y%m%d%H)
        
        if [ ! -z "$COMMIT_ID" ]; then
            VERSION_NAME="$VERSION_NAME-${COMMIT_ID:0:7}"
        fi
    fi
fi

# IOS FILE WRITER
function write_ios_plist_files(){
    local IS_LINE_VERSION_NAME=false
    local IS_LINE_VERSION_NUMBER=false;
    
    echo -n "" > $2
    
    while IFS= read -r line || [ -n "$line" ]; do
        if $IS_LINE_VERSION_NUMBER; then
            IS_LINE_VERSION_NUMBER=false
            echo "	<string>$VERSION_NUMBER</string>" >> $2
            elif $IS_LINE_VERSION_NAME; then
            IS_LINE_VERSION_NAME=false
            echo "	<string>$VERSION_NAME</string>" >> $2
        else
            echo "$line" >> $2
        fi
        
        if [[ $line == *"CFBundleVersion"* ]]; then
            IS_LINE_VERSION_NUMBER=true
            elif [[ $line == *"CFBundleShortVersionString"* ]]; then
            IS_LINE_VERSION_NAME=true
        fi
    done < $1
}

# YAML FILE WRITER
function write_yaml_file(){
    local YAML_FILE="pubspec.yaml"
    local YAML_FILE_TEMP="new_$YAML_FILE"
    
    echo -n "" > $YAML_FILE_TEMP
    
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ $line =~ ^version: ]]; then
            echo "version: $VERSION_NAME+$VERSION_NUMBER" >> $YAML_FILE_TEMP
        else
            echo "$line" >> $YAML_FILE_TEMP
        fi
    done < $YAML_FILE
    
    mv -f $YAML_FILE_TEMP $YAML_FILE
    
}

# FILE READ AND UPDATE
case $PLATFORM in
    ios)
        IOS_PROJECT_BASE=$DIR/ios
        IOS_PROJECT_BASE_PLIST_FILE=$IOS_PROJECT_BASE/Runner/Info.plist
        IOS_PROJECT_NOTIFICATION_PLIST_FILE=$IOS_PROJECT_BASE/OneSignalNotificationServiceExtension/Info.plist
        
        write_ios_plist_files $IOS_PROJECT_BASE_PLIST_FILE base.plist
        write_ios_plist_files $IOS_PROJECT_NOTIFICATION_PLIST_FILE notification.plist
        
        # Move files
        mv -f base.plist $IOS_PROJECT_BASE_PLIST_FILE
        mv -f notification.plist $IOS_PROJECT_NOTIFICATION_PLIST_FILE
    ;;
    
    google)
        # no-op
    ;;
    
    huawei)
        # no-op
    ;;
    
esac

#Update YAML FILE
write_yaml_file

echo "------------------------------------------------------"
echo
echo " Platform          : $PLATFORM"
echo " Version Name      : $VERSION_NAME"
echo " Version Code      : $VERSION_NUMBER"
echo " Commit ID         : $COMMIT_ID"
echo
echo "------------------------------------------------------"
