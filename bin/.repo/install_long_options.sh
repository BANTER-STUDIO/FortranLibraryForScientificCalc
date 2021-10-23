#!/bin/bash
NAME=SCIFOR
UNAME=`echo $NAME |tr [:lower:] [:upper:]`
LNAME=`echo $NAME |tr [:upper:] [:lower:]`
LIBNAME=lib$LNAME.a
LOG=install.log
>$LOG
exec >  >(tee -a $LOG)
exec 2> >(tee -a $LOG >&2)


#>>> USAGE FUNCTION
usage(){
    echo ""
    echo "usage:"
    echo ""
#    echo "$0  -p,--plat=FC_PLAT  [ -o,--opt-lib=OPT_LIB  -c,--clean  -w,--wdmftt  -d,--debug  -h,--help ]"
    echo "$0  -p,--plat=FC_PLAT  [ --prefix=PREFIX_DIR  -o,--opt-lib=OPT_LIB  -q,--quiet -c,--clean  -w,--wdmftt  -d,--debug  -h,--help ]"
    echo ""
    echo "    -p,--plat   : specifies the actual platform/compiler to use [intel,gnu]"
    echo "    --prefix    : specifies the target directory [default: FC_PLAT]"
    echo "    -o,--opt-lib: to install a single 3rd party lib [arpack blas fftpack lapack minpack quadpack dmftt]. "
    echo "    -q,--quiet  : assume Y to all questions."
    echo "    -c,--clean  : clean out the former compilation."
    echo "    -w,--wdmftt : complete SciFor with DMFT_TOOLS library."
    echo "    -d,--debug  : debug flag"
    echo "    -h,--help   : this help"
    echo ""
    exit
}


#>>> GET Nth TIMES PARENT DIRECTORY
nparent_dir(){
    local DIR=$1
    local N=$2
    for i in `seq 1 $N`;
    do 
	DIR=$(dirname $DIR)
    done
    echo $DIR
}

#>>> GET THE ENTIRE LIST OF ARGUMENTS PASSED TO STDIN
LIST_ARGS=$*


#>>> GET LONG & SHORT OPTIONS
params="$(getopt -n "$0" --options p:o:qcwdh --longoptions plat:,prefix:,opt-lib:,quiet,clean,wdmftt,debug,help -- "$@")"
if [ $? -ne 0 ];then
    usage
fi
eval set -- "$params"
unset params

#>>> CHECK THE NUMBER OF ARGUMENTS. IF NONE ARE PASSED, PRINT HELP AND EXIT.
NUMARGS=$#
if [ $NUMARGS -eq 0 ]; then
    usage
fi


#>>> SET SOME DEFAULTS VARIABLES AND OTHER ONES
DEBUG=1
OPT=
QUIET=0
VERSION=$(git describe --tags 2>/dev/null)
WRK_INSTALL=$(pwd)
PREFIX=$HOME/opt/scifor
BIN_INSTALL=$WRK_INSTALL/bin
ETC_INSTALL=$WRK_INSTALL/etc
OPT_INSTALL=$WRK_INSTALL/opt
ENVMOD_INSTALL=$ETC_INSTALL/environment_modules
SRC_INSTALL=$WRK_INSTALL/src

#>>> A COUPLE OF LISTS OF ALLOWED OPTIONS
LIST_FC="gnu intel"
LIST_OPT="arpack blas fftpack lapack minpack quadpack"


#>>> GO THROUGH THE INPUT ARGUMENTS. FOR EACH ONE IF REQUIRED TAKE ACTION BY SETTING VARIABLES.
while true
do
    case $1 in
	-p|--plat)
	    PLAT=$2
	    shift 2
	    [[ ! $LIST_FC =~ (^|[[:space:]])"$PLAT"($|[[:space:]]) ]] && {
		echo "Incorrect Fortran PLAT: $PLAT";
		echo " available values are: $LIST_FC"
		exit 1
	    }
	    ;;
	--prefix)
	    PREFIX=$2;
	    shift 2
	    ;;
	-o|--opt-lib)
	    OPT=$2;
	    shift 2
	     [[ ! "$LIST_OPT" =~ (^|[[:space:]])"$OPT"($|[[:space:]]) ]] && {
		 echo "Incorrect OPTional Library: $OPT";
		 echo " available choices are: $LIST_OPT";
		 exit 1
	     }
	     ;;
	-q|--quiet) QUIET=1;shift ;;
	-c|--clean) OPT=clean;shift ;;
	-w|--wdmftt) OPT=wdmftt;shift ;;
	-d|--debug) DEBUG=0;shift ;;
        -h|--help) usage ;;
        --) shift; break ;;
        *) usage ;;
    esac
done

#>>> CHECK THAT THE MANDATORY OPTION -p,-plat IS PRESENT:
[[ $LIST_ARGS =~ "-p" ]] || usage
[[ $LIST_ARGS =~ "--plat" ]] || usage


#RENAME WITH DEBUG IF NECESSARY 
if [ $DEBUG == 0 ];then 
    PLAT=${PLAT}_debug;
fi

#>>> SET STANDARD NAMES FOR THE TARGET DIRECTORY
DIR_TARGET=$PREFIX/$PLAT
BIN_TARGET=$DIR_TARGET/bin
ETC_TARGET=$DIR_TARGET/etc
LIB_TARGET=$DIR_TARGET/lib
INC_TARGET=$DIR_TARGET/include

if [ $QUIET == 0 ];then
    _DIR=Y
    echo -n "Installing in $DIR_TARGET. Continue [Y/n]: "
    read _DIR;
    _DIR=`echo $_DIR |tr [:lower:] [:upper:]`
    [[ $_DIR == Y ]] || exit 1
fi

#>>> TEST MPI
FMPI=mpif90
which $FMPI >/dev/null 2>&1
WMPI=$?

if [ $WMPI == 0 ];then
    _MPI=Y
    echo "Using the following MPI compiler:"
    sleep 1
    mpif90 -show
    sleep 1
    echo "On platform: $PLAT"
    sleep 3
    if [ $QUIET == 0 ];then
	echo -n "Continue (this will install P-Arpack) [Y/n]: "
	read _MPI;
	_MPI=`echo $_MPI |tr [:lower:] [:upper:]`
	[[ $_MPI == Y ]] || exit 1
    fi
fi

exit

#>>> CREATE THE MAKE.INC IN THE FOLLOWING FUNCTION
create_makeinc(){
    local PLAT=$1
    cd $WRK_INSTALL
    echo "Creating directories:" >&2
    mkdir -pv $DIR_TARGET
    mkdir -pv $BIN_TARGET
    mkdir -pv $ETC_TARGET/modules/$LNAME
    mkdir -pv $LIB_TARGET
    mkdir -pv $INC_TARGET
    case $PLAT in
	intel)
	    FC=ifort
	    FFLAGS="-O2 -static-intel"
	    MOPT="-module "
	    ;;
	gnu)
	    FC=gfortran
	    FFLAGS="-O2 -static"
	    MOPT=-J
	    ;;
	intel_debug)
	    FC=ifort
	    FFLAGS="-p -O0 -g -debug -fpe0 -traceback -check all,noarg_temp_created -static-intel"
	    MOPT="-module "
	    ;;
	gnu_debug)
	    FC=gfortran
	    FFLAGS="-O0 -p -g -Wall -fPIC -fmax-errors=1 -g -fcheck=all -fbacktrace -static"
	    MOPT=-J
	    ;;
	ibm)
	    FC=xlf90
	    FFLAGS="-O2 -qarch=qp -qtune=qp"
	    MOPT="-qmoddir="
	    ;;
	*)
	    usage
	    ;;
    esac
    
    cat << EOF > make.inc
FC=$FC
FFLAGS=$FFLAGS
MOPT=$MOPT
PLAT=$PLAT
INC_TARGET=$INC_TARGET
LIB_SCIFOR=$LIB_TARGET/$LIBNAME
EOF

    echo "Copying init script for $UNAME" >&2
    cp -fv $BIN_INSTALL/scifor_completion.sh  $BIN_TARGET/scifor_completion.sh
    cp -fv $BIN_INSTALL/configvars.sh $BIN_TARGET/configvars.sh
    cat <<EOF >> $BIN_TARGET/configvars.sh
add_library_to_system ${PREFIX}/${PLAT}
EOF
    echo "" >&2

    echo "Generating environment module file for $UNAME" >&2
    cat <<EOF > $ETC_TARGET/modules/$LNAME/$PLAT
#%Modules
set	root	$PREFIX
set	plat	$PLAT
set	version	"$VERSION ($PLAT)"
EOF
    cat $ENVMOD_INSTALL/module >> $ETC_TARGET/modules/${LNAME}/$PLAT
    echo "" >&2
    echo "Compiling $UNAME library on platform $PLAT:">&2
    echo "" >&2
}


#>>>>>>>>>>>>>>>>> WORK STARTS HERE <<<<<<<<<<<<<<<<<<<<<<#

#>>> GET THE ACTUAL DIRECTORY
HERE=$(pwd)

#INSTALL A SINGLE OPTIONAL LIB IF REQUIRED:
case $OPT in
    arpack)
	if [ $WMPI == 1 ];then
	    cd $OPT_INSTALL/arpack
	    ./install.sh $PLAT
	    exit
	else
	    cd $OPT_INSTALL/parpack
	    ./install.sh $PLAT
	    exit
	fi
	;;
    blas)
	cd $OPT_INSTALL/blas
	./install.sh $PLAT
	exit
	;;
    dmftt)
	cd $OPT_INSTALL/dmft_tools
	./install.sh $PLAT
	exit
	;;
    fftpack)
	cd $OPT_INSTALL/fftpack
	./install.sh $PLAT
	exit
	;;
    lapack)
	cd $OPT_INSTALL/lapack
	./install.sh $PLAT
	exit
	;;
    minpack)
	cd $OPT_INSTALL/minpack
	./install.sh $PLAT
	exit
	;;
    quadpack)
	cd $OPT_INSTALL/quadpack
	./install.sh $LIST_ARGS
	exit
	;;
    clean)
	echo "Cleaning the .o files in all OPT libraries for platform $PLAT: " >&2
	cd $OPT_INSTALL
	for dir in *;do
	    cd $dir/
	    ./install.sh $PLAT clean
	    cd ../
	done
	exit 1
	;;
esac
cd $HERE


#CHECK THAT EACH OPT LIBRARY IS PRESENT IN THE INSTALLATION. IF NOT INSTALL IT
for LIB in $LIST_OPT;do
    case $LIB in
	arpack)
	    if [ $WMPI == 1 ];then
		if [ ! -e $LIB_TARGET/libarpack.a ];then
		    cd $OPT_INSTALL/arpack
		    ./install.sh $PLAT
		else
		    echo "$LIB_TARGET/libarpack.a exists. skip" >&2
		    continue
		fi
	    else
		if [ ! -e $LIB_TARGET/libparpack.a ] ;then
		    cd $OPT_INSTALL/parpack
		    ./install.sh $PLAT
		else
		    echo "$LIB_TARGET/libarpack.a exists. skip" >&2
		    echo "$LIB_TARGET/libparpack.a exists. skip" >&2
		    continue
		fi
	    fi
            ;;
	blas)
	    if [ ! -e $LIB_TARGET/libblas.a ];then
		cd $OPT_INSTALL/$LIB
		./install.sh $PLAT
	    else
		echo "$LIB_TARGET/libblas.a exists. skip" >&2
	    fi
	    ;;
	fftpack)
	    if [ ! -e $LIB_TARGET/libfftpack.a ];then
		cd $OPT_INSTALL/$LIB
		./install.sh $PLAT
	    else
		echo "$LIB_TARGET/libfftpack.a exists. skip" >&2
	    fi
	    ;;
	lapack)
	    if [ ! -e $LIB_TARGET/liblapack.a ];then
		cd $OPT_INSTALL/$LIB
		./install.sh $PLAT
	    else
		echo "$LIB_TARGET/liblapack.a exists. skip" >&2
	    fi
	    ;;
	minpack)
	    if [ ! -e $LIB_TARGET/libminpack.a ];then
		cd $OPT_INSTALL/$LIB
		./install.sh $PLAT
	    else
		echo "$LIB_TARGET/libminpack.a exists. skip" >&2
	    fi
	    ;;
	quadpack)
	    if [ ! -e $LIB_TARGET/libquadpack.a ];then
		cd $OPT_INSTALL/$LIB
		./install.sh $PLAT
	    else
		echo "$LIB_TARGET/libquadpack.a exists. skip" >&2
	    fi
	    ;;
    esac	
done
cd $HERE


#CREATING THE SCIFOR LIBRARY:
rm -fv $LIB_TARGET/$LIBNAME
create_makeinc $PLAT
make all
if [ $? == 0 ];then
    make clean
    mv -vf $WRK_INSTALL/make.inc $ETC_TARGET/make.inc.scifor
else
    echo "Error from Makefile. STOP here."
    exit 1
fi


#IF REQUIRED IT GENERATES THE DMFT_TOOLS LIBRARY
if [ ! -z $2 ] && [ "$OPT" == "wdmftt" ];then
    HERE=$(pwd)
    echo "Generating the DMFT_TOOLS library for $PLAT" >&2
    cd $OPT_INSTALL/dmft_tools
    ./install.sh $PLAT
    cd $HERE
fi


#LAST TOUCH COPY THE CONFIGVARS AND CREATE THE USER MODULES FILE. PRINT USAGE DETAILS.
CONFIGFILE=$PREFIX/$PLAT/bin/configvars.sh
MODULEFILE=$PREFIX/$PLAT/etc/modules/$LNAME/$PLAT
mkdir -pv $HOME/.modules.d/$LNAME
cp -vf $MODULEFILE $HOME/.modules.d/$LNAME/$PLAT
echo "" >&2
echo "USAGE:" >&2
echo "" >&2
echo " To add SciFor (and other libraries) to your system:" >&2
echo "   $ source $CONFIGFILE" >&2
echo " (or copy this line into your bash profile [e.g. .bashrc])" >&2
echo "">&2
module avail >/dev/null 2>&1 
if [ $? == 0 ];then
echo " or load the $UNAME modules:" >&2
echo "   $ module use $HOME/.modules.d/applications" >&2
echo "   $ module load $LNAME/$PLAT" >&2
echo "(or copy these lines into your bash profile [e.g. .bashrc])" >&2
echo "">&2
fi
echo "">&2
echo "Enjoy... (for info: adriano.amaricciATgmail.com)">&2
echo "">&2
