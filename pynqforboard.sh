#!/bin/bash
set -e

ARGCNT=$#
#Eclypse-Z7
BOARDS=$1
#Architecture (This could be read from petalinux project I think)
ARCH=$2 
#workdirectory
WDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#PYNQ branch for 2019.1
BRANCH="v2.5.1"

init(){

if [ "${ARGCNT}" -ne 2 ]; then
    echo "Useage:"
    echo "./pynqforboard.sh <boardname> <pynqbranch> <arch>"
    echo "./pynqforboard.sh Eclypse-Z7 arm"
    exit -1
fi

if [ ! -d "${WDIR}/${BOARDS}" ] 
then
	#Need to check petalinux version
	git clone https://github.com/Digilent/${BOARDS} --recursive -b master
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
	if [ -z "$PETALINUX" || -z "$XILINX_VIVADO"]
	then
	      echo "Please source Petalinux and Vivado!"
	      exit -1
	fi
	echo 'DL_DIR = "'${WDIR}'/petalinux_cache/'${BOARDS}'/downloads/"' >> ${BOARDS}/os/project-spec/meta-user/conf/petalinuxbsp.conf
	echo 'SSTATE_DIR = "'${WDIR}'/petalinux_cache/'${BOARDS}'/sstate/arm/"' >> ${BOARDS}/os/project-spec/meta-user/conf/petalinuxbsp.conf
	petalinux-package --bsp -p ${WDIR}/${BOARDS}/os/ -o ${WDIR}/${BOARDS}.bsp --force
	mkdir ${WDIR}/PYNQ/boards/${BOARDS}
	echo ARCH_${BOARDS} := ${ARCH} > ${WDIR}/PYNQ/boards/${BOARDS}/${BOARDS}.spec
	echo BSP_${BOARDS} := ${BOARDS}.bsp  >> ${WDIR}/PYNQ/boards/${BOARDS}/${BOARDS}.spec
	#You can find packages in PYNQ/sdbuild/PACKAGES and in 2020.1 xrt!
	echo STAGE4_PACKAGES_${BOARDS} := pynq ethernet  >> ${WDIR}/PYNQ/boards/${BOARDS}/${BOARDS}.spec
	cp ${WDIR}/${BOARDS}.bsp ${WDIR}/PYNQ/boards/${BOARDS}/
fi

}

buildBoard(){
file="${WDIR}/PYNQ/boards/zcu104/xilinx-zcu104-v2019.1-final.bsp"
if [ ! -e "$file" ]; then
    	echo "Please copy xilinx-zcu104-v2019.1-final.bsp to PYNQ/boards/zcu104 folder!"
	echo "Build could fail because lack of necessary license for some IP-cores"
  	exit -1 
fi 
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
