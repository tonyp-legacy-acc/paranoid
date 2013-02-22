#!/bin/bash

# get current path
reldir=`dirname $0`
cd $reldir
DIR=`pwd`

# Colorize and add text parameters
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
cya=$(tput setaf 6)             #  cyan
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
bldcya=${txtbld}$(tput setaf 6) #  cyan
txtrst=$(tput sgr0)             # Reset

THREADS="16"
DEVICE="$1"
EXTRAS="$2"

# get current version
MAJOR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'PA_VERSION_MAJOR = *' | sed  's/PA_VERSION_MAJOR = //g')
MINOR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'PA_VERSION_MINOR = *' | sed  's/PA_VERSION_MINOR = //g')
TONYP_BUILD_NR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'TONYP_BUILD_NR = *' | sed  's/TONYP_BUILD_NR = //g')
BLVERSION=$(cat $DIR/device/lge/p990/system.prop | grep 'ro.tonyp.bl=*' | sed  's/ro.tonyp.bl=//g')
VERSION=$MAJOR.$MINOR-$TONYP_BUILD_NR-$BLVERSION

# if we have not extras, reduce parameter index by 1
if [ "$EXTRAS" == "true" ] || [ "$EXTRAS" == "false" ]
then
   SYNC="$2"
   UPLOAD="$3"
else
   SYNC="$3"
   UPLOAD="$4"
fi

# get time of startup
res1=$(date +%s.%N)

# Remove previous build info
echo "Removing previous build.prop"
rm out/target/product/p990/system/build.prop;

# we don't allow scrollback buffer
echo -e '\0033\0143'
clear

echo -e "${cya}Building ${bldcya}ParanoidAndroid v$VERSION ${txtrst}";

echo -e "${cya}"
./vendor/pa/tools/getdevicetree.py $DEVICE
echo -e "${txtrst}"

# decide what command to execute
case "$EXTRAS" in
   threads)
       echo -e "${bldblu}Please write desired threads followed by [ENTER] ${txtrst}"
       read threads
       THREADS=$threads;;
   clean)
       echo -e ""
       echo -e "${bldblu}Cleaning intermediates and output files ${txtrst}"
       make clean > /dev/null;;
esac

# download prebuilt files
echo -e ""
echo -e "${bldblu}Downloading prebuilts ${txtrst}"
cd vendor/cm
./get-prebuilts
cd ./../..

# sync with latest sources
echo -e ""
if [ "$SYNC" == "true" ]
then
   echo -e "${bldblu}Fetching latest sources ${txtrst}"
   repo sync -j"$THREADS"
   ./generate_changelog.sh
   ./apply_linaro.sh
   echo -e ""
   MAJOR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'PA_VERSION_MAJOR = *' | sed  's/PA_VERSION_MAJOR = //g')
   MINOR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'PA_VERSION_MINOR = *' | sed  's/PA_VERSION_MINOR = //g')
   TONYP_BUILD_NR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'TONYP_BUILD_NR = *' | sed  's/TONYP_BUILD_NR = //g')
   BLVERSION=$(cat $DIR/device/lge/p990/system.prop | grep 'ro.tonyp.bl=*' | sed  's/ro.tonyp.bl=//g')
   VERSION=$MAJOR.$MINOR-$TONYP_BUILD_NR-$BLVERSION
fi

# setup environment
echo -e "${bldblu}Setting up environment ${txtrst}"
. build/envsetup.sh

# lunch device
echo -e ""
echo -e "${bldblu}Lunching device ${txtrst}"
lunch "pa_$DEVICE-eng";

echo -e ""
echo -e "${bldblu}Starting compilation ${txtrst}"

# start compilation
time mka bacon
echo -e ""

# push build
chmod 644 $DIR/out/target/product/p990/pa_p990-${VERSION}-tonyp.zip

echo "build ready - push to goo.im? (y/n)"
read -n 1 we_push
if [ "$we_push" == "y" ]; then
scp -p2222 $DIR/out/target/product/p990/pa_p990-${VERSION}-tonyp.zip tonyp@upload.goo.im:~/public_html/ParanoidAndroid-P990/${BLVERSION}/
fi
echo ""
echo "scp -p2222 $DIR/out/target/product/p990/pa_p990-${VERSION}-tonyp.zip tonyp@upload.goo.im:~/public_html/ParanoidAndroid-P990/${BLVERSION}/"
