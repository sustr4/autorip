#!/bin/bash

DVD_DEVICE="/dev/sr0"
LENGTH_THRESH=240 # rip titles longer than 240 seconds
TMPDIR="/tmp"
TARGETDIR="/mnt/orangeusb/dvdbackup"

DATE=`date +%Y-%m-%d`

# Read an array of titles and their lengths
mplayer -identify -frames 0 -ao null -vo null -vc null -dvd-device ${DVD_DEVICE} dvd:// 2>/dev/null > ${TMPDIR}/autorip-$$-identify.out

TITLES_LIST=`cat ${TMPDIR}/autorip-$$-identify.out | egrep 'TITLE_[0-9]*_LENGTH' | awk -F'[_=]' -v thresh="${LENGTH_THRESH}" '{ if ($6 > thresh) { print $4 } }' | sort -n`

#TITLES_LIST="1" #TODO remove debug opt.

if [ "$1" == "" ]; then
	VOLUME_ID=`grep ID_DVD_VOLUME_ID ${TMPDIR}/autorip-$$-identify.out | sed s/.*=// | sed 's/\s/-/g'`
else
	VOLUME_ID=`echo "$1" | sed 's/\s/-/g'`
fi

ALANG_LIST=`egrep 'ID_AID_[0-9]*_LANG' ${TMPDIR}/autorip-$$-identify.out | sed s/.*=// | sort | egrep 'cs|en'`

SLANG_LIST=`egrep 'ID_SID_[0-9]*_LANG' ${TMPDIR}/autorip-$$-identify.out | sed s/.*=// | sort`



printf "Getting ready to rip titles "
for TITLE in $TITLES_LIST; do printf "$TITLE, "; done
printf "disk title ${VOLUME_ID}\n"

printf "Audio languages found: "
for LANG in $ALANG_LIST; do printf "$LANG, "; done
printf "\n"

printf "Subtitle languages found: "
for LANG in $SLANG_LIST; do printf "$LANG, "; done
printf "\n"


WRKD="${TMPDIR}/autorip.$$.${VOLUME_ID}"
mkdir -p "${WRKD}"

EPNUM=0
for TITLE in $TITLES_LIST; do
echo Start title $TITLE

	#Episode Number (does not increment on skipped tracks)
	EPNUM=$((EPNUM+1))

	#Set Working file prefix
	WRKF=`echo "${WRKD}/${VOLUME_ID}-E$(printf %02d $EPNUM)" | sed 's/\s/-/g'`

	handbrake-cli -i /dev/sr0 -t $TITLE -o "${WRKF}.mkv" -f av_mkv --no-optimize --audio-lang-list ces,eng --all-audio --subtitle-lang-list ces,eng --all-subtitles 2> "${WRKD}/.handbrake-t${TITLE}-e${EPNUM}.log"

echo End title $TITLE
done


# Move result to workdir
if [ -d "${TARGETDIR}/${VOLUME_ID}" ]; then
	# Use plain DVD name in case its unused
	TARGETFINAL="${TARGETDIR}/${VOLUME_ID}"
else
	# Add suffix to distinguish from previous rips
	TARGETFINAL="${TARGETDIR}/${VOLUME_ID}.${DATE}"
fi

mv "${TMPDIR}/autorip.$$.${VOLUME_ID}" "${TARGETFINAL}"
mv ${TMPDIR}/autorip-$$-identify.out "${TARGETFINAL}/.autorip-identify-${DATE}.log"

#All done. Open tray to indicate.
eject "${DVD_DEVICE}"
