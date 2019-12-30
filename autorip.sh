#!/bin/bash

DVD_DEVICE="/dev/sr0"
LENGTH_THRESH=240 # rip titles longer than 240 seconds
TMPDIR="/tmp"
TARGETDIR="/tmp"

# Read an array of titles and their lengths
mplayer -identify -frames 0 -ao null -vo null -vc null -dvd-device ${DVD_DEVICE} dvd:// 2>/dev/null > ${TMPDIR}/autorip-$$-identify.out

TITLES_LIST=`cat ${TMPDIR}/autorip-$$-identify.out | egrep 'TITLE_[0-9]*_LENGTH' | awk -F'[_=]' -v thresh="${LENGTH_THRESH}" '{ if ($6 > thresh) { print $4 } }' | sort -n`

#TITLES_LIST="1" #TODO remove debug opt.

VOLUME_ID=`grep ID_DVD_VOLUME_ID ${TMPDIR}/autorip-$$-identify.out | sed s/.*=// | sed 's/\s/-/g'`

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

for TITLE in $TITLES_LIST; do
echo Start title $TITLE

	#Set Working file prefix
	WRKF=`echo "${WRKD}/${VOLUME_ID}-E$(printf %02d $TITLE)" | sed 's/\s/-/g'`

	handbrake-cli -i /dev/sr0 -t $TITLE -o "${WRKF}.mkv" -f av_mkv --no-optimize --audio-lang-list ces,eng --all-audio --subtitle-lang-list ces,eng --all-subtitles

#	mkdir -p "${WRKF}-dvdbackup"
#	dvdbackup -i ${DVD_DEVICE} -t "${TITLE}" -o "${WRKF}-dvdbackup" -p
#	for ALANG in $ALANG_LIST; do
#		echo mencoder here
#	done
	

echo End title $TITLE
done


#rm -rf ${WRKF}-dvdbackup
mv "${TMPDIR}/autorip.$$.${VOLUME_ID}" "${TARGETDIR}/${VOLUME_ID}"
rm ${TMPDIR}/autorip-$$-identify.out

