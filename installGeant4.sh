#!/bin/bash
#---------------------------------------library check part------------------------------
Distributor=`lsb_release -i`
Distributor=${Distributor##*:}
Release=`lsb_release -r`
Release=${Release##*:}
if [ ${Distributor} != "Ubuntu" ];
then
        printf "sorry,this file can not support $Distributor now."
	exit 0
fi
if [ ${Release} == "20.04" ];
then
	dependentPackage=("build-essential" "cmake" \
                                        "expat" "libexpat1" "libexpat1-dev" \
                                        "libxerces-c-dev" "libgl1-mesa-dev" \
                                        "libglu1-mesa-dev" "libgl2ps-dev" \
                                        "opticalraytracer" "libxt-dev" \
                                        "libxmu-dev" "libxi-dev" "qt5-default"\
                                         "libpythia8-dev" "pythia8-doc-html" \
                                         "pythia8-doc-worksheet" "pythia8-examples")
fi
if [ ${Release} == "22.04" ];
then
        dependentPackage=("build-essential" "cmake" \
                                        "expat" "libexpat1" "libexpat1-dev" \
                                        "libxerces-c-dev" "libgl1-mesa-dev" \
                                        "libglu1-mesa-dev" "libgl2ps-dev" \
                                        "opticalraytracer" "libxt-dev" \
                                        "libxmu-dev" "libxi-dev" \
					"qtbase5-dev" "qtchooser" "qt5-qmake" "qtbase5-dev-tools")
fi
printf "\033[36;1m===========check dependent package===========\033[0m\n"

uninstallNumber=0

index=0
while(($index<${#dependentPackage[*]}))
do
	printf "%s " ${dependentPackage[$index]}
	p_check=`dpkg -l | grep ${dependentPackage[$index]}`
	if [ "$p_check"x == ""x ]
	then
		printf "\033[33m[uninstalled]\033[0m\n"
		uninstallIdx[$uninstallNumber]=$index
		let "uninstallNumber++"
	else
		printf "\033[32m[installed]\033[0m\n"
	fi
	let "index++"
done

sleep 2
clear

idx=0
while(($idx<$uninstallNumber))
do
	printf "\033[36;1m===========install dependent package===========\033[0m\n"
	# print which is installing now
	index=0
	while(($index<${#dependentPackage[*]}))
	do
		# check which should be installed now
		if [ $index == ${uninstallIdx[idx]} ]
		then
			printf "\033[45;5m%s\033[0m " ${dependentPackage[$index]}
		else
			printf "%s " ${dependentPackage[$index]}
		fi

		p_check=`dpkg -l | grep ${dependentPackage[$index]}`
		if [ "$p_check"x == ""x ]
		then
			printf "\033[33m[uninstalled]\033[0m\n"
			
		else
			printf "\033[32m[installed]\033[0m\n"
		fi
		let "index++"
	done
	printf "=============================================\n"
	sleep 1
	# install 
	sudo apt install -y ${dependentPackage[${uninstallIdx[idx]}]}
	sleep 1
	clear
	let "idx++"
done

# show install part result
printf "\033[36;1m===========check dependent package===========\033[0m\n"
index=0
check=0
while(($index<${#dependentPackage[*]}))
do
	printf "%s " ${dependentPackage[$index]}
	p_check=`dpkg -l | grep ${dependentPackage[$index]}`
	if [ "$p_check"x == ""x ]
	then
		printf "\033[33m[uninstalled]\033[0m\n"
		check=1
	else
		printf "\033[32m[installed]\033[0m\n"
	fi
	let "index++"
done
if [ $check == 1 ]
then
	printf "\033[31mE:con't install those package totally, please install those by yourself\033[0m\n"
	exit
else
	sleep 1
fi




#--------------------------------------------------------------file check part-----------------------------------------------------
printf "\033[36;1m=================check source file=================\033[0m\n" 
if [ $# == 1 ]  
then
	echo $#
	file=$1
else
	printf "install geant4 from internet\n"
	p_check=`dpkg -l | grep 'wget'`
	if [ "$p_check"x == ""x ]
	then
		sudo apt install -y wget
	fi
	file="geant4-v11.0.3.tar.gz"
	wget https://geant4-data.web.cern.ch/releases/$file
fi
suffix=${file:0-6}
if [ "$suffix"x == "tar.gz"x ]
then
	if [ -f $file ]
	then
		printf "file %s exists\n" $file
		tar -xzvf $file
		printf "\033[36;1m===============check sourc file end================\033[0m\n"
		sleep 1
		clear
	else
		printf "\033[31m E:file %s doesn't exist! \033[0m\n" $file
		exit
	fi
else
	printf "\033[31m E:suffix error \033[0m\n"
	exit
fi

#-----------------------------------------make the directories---------------------------
#check the directories
tl=${#file}
let "tl=tl-7"
sourcefile=${file:0:$tl}
if test -e $sourcefile
then
	printf "source file(%s) exist\n" $sourcefile
else
	printf "\033[31mE:con't find source file(%s)\n" $sourcefile
	exit
fi

if test -e ./build_geant4
then
	sudo rm -rf ./build_geant4 > /dev/null
fi
mkdir build_geant4

if test -e ./install_geant4
then
	sudo rm -rf ./install_geant4 > /dev/null
fi
mkdir install_geant4

if test -e ./source_geant4
then 
	sudo rm -rf ./source_geant4 > /dev/null
fi
mkdir source_geant4

cp -r $sourcefile/* ./source_geant4
#----------------------------------------build it-------------------------------------------
cd ./build_geant4 >> /dev/null
printf "\033[36;1m======================cmake========================\033[0m\n"
sleep 1
cmake -DCMAKE_INSTALL_PREFIX=../install_geant4 \
		-DGEANT4_INSTALL_DATA=ON \
		-DGEANT4_BUILD_MULTITHREADED=ON \
		-DGEANT4_USE_GDML=ON \
		-DGEANT4_USE_OPENGL_X11=ON \
		-DGEANT4_USE_RAYTRACER_X11=ON \
		-DGEANT4_USE_SYSTEM_EXPAT=ON \
		-DGEANT4_USE_QT=ON \
		-DQT_QMAKE_EXECUTABLE=/usr/bin/qmake \
		../source_geant4
sleep 1
clear
cpus=`lscpu | grep "^CPU(s):"`
cpus=${cpus:0-3}
printf "\033[36;1m======================make using %s core========================\033[0m\n" $cpus
sleep 1
make -j$cpus

make install -j$cpus

# add path
cd ../install_geant4/bin/
installPath=`pwd`

echo "#Geant4 env" >> ~/.bashrc
echo "source $installPath/geant4.sh" >> ~/.bashrc
source ~/.bashrc

