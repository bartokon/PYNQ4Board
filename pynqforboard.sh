#!/bin/bash
set -e

ARGCNT=${#}
#Eclypse-Z7
BOARDS=$1
#v2.5.1
BRANCH=$2 
#Architecture (This could be read from petalinux project I think)
ARCH=$3
#workdirectory
WDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

init(){

if [ "${ARGCNT}" -ne 3 ]; then
    echo "Useage:"
    echo "./pynqforboard.sh <boardname> <pynqbranch> <arch>"
    echo "./pynqforboard.sh Eclypse-Z7 v2.5.1 arm"
    exit -1
fi

if [ ! -d "${WDIR}/${BOARDS}" ] 
then
	#Need to check petalinux version
	git clone https://github.com/Digilent/${BOARDS} --recursive -b master
	echo 'DL_DIR = "'${WDIR}'/petalinux_cache/'${BOARDS}'/downloads/"' >> ${BOARDS}/os/project-spec/meta-user/conf/petalinuxbsp.conf
	echo 'SSTATE_DIR = "'${WDIR}'/petalinux_cache/'${BOARDS}'/sstate/arm/"' >> ${BOARDS}/os/project-spec/meta-user/conf/petalinuxbsp.conf
	petalinux-package --bsp -p ${WDIR}/${BOARDS}/os/ -o ${WDIR}/${BOARDS}.bsp --force
fi

if [ ! -d "${WDIR}/PYNQ" ] 
then
	git clone https://github.com/Xilinx/PYNQ.git -b ${BRANCH}
	cd ${WDIR}/PYNQ/sdbuild/scripts/
	./setup_host.sh
fi
}

createBoardDirectoryForPynq(){
if [ ! -d "${WDIR}/PYNQ/boards/${BOARDS}" ] 
then
	mkdir ${WDIR}/PYNQ/boards/${BOARDS}
	echo ARCH_${BOARDS} := ${ARCH} > ${WDIR}/PYNQ/boards/${BOARDS}/${BOARDS}.spec
	echo BSP_${BOARDS} := ${BOARDS}.bsp  >> ${WDIR}/PYNQ/boards/${BOARDS}/${BOARDS}.spec
	#You can find packages in PYNQ/sdbuild/PACKAGES and in 2020.1 xrt!
	echo STAGE4_PACKAGES_${BOARDS} := pynq ethernet  >> ${WDIR}/PYNQ/boards/${BOARDS}/${BOARDS}.spec
	cp ${WDIR}/${BOARDS}.bsp ${WDIR}/PYNQ/boards/${BOARDS}/
fi

}

buildBoard(){
	cd ${WDIR}/PYNQ/sdbuild/
	make BOARDS=${BOARDS}	
}

exitMsg(){
	echo "Your image should be in PYNQ/sdbuilt/output/"
}

init
createBoardDirectoryForPynq
buildBoard
exitMsg
