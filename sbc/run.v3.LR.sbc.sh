#!/bin/bash -fe

# E3SM Coupled Model Group run_e3sm script template.
#
# Bash coding style inspired by:
# http://kfirlavi.herokuapp.com/blog/2012/11/14/defensive-bash-programming

main() {

# For debugging, uncomment line below
#set -x

# --- Configuration flags ----

# Machine and project
readonly MACHINE=pm-cpu
readonly PROJECT="e3sm"

# Simulation
readonly COMPSET="WCYCL1850"
readonly RESOLUTION="ne30pg2_r05_IcoswISC30E3r5"
readonly CASE_NAME="v3.LR.sbc.test1012"
# If this is part of a simulation campaign, ask your group lead about using a case_group label
# otherwise, comment out
#readonly CASE_GROUP="v3.LR"

# Code and compilation
readonly CHECKOUT="20240305"
readonly BRANCH="v3.0.0"  # master as of 2024-03-04 399d4301138617088dd93214123d6c025e061302
readonly CHERRY=( )
readonly DEBUG_COMPILE=false

# Run options
readonly MODEL_START_TYPE="hybrid"  # 'initial', 'continue', 'branch', 'hybrid'
readonly START_DATE="0001-01-01"

# Additional options for 'branch' and 'hybrid'
readonly GET_REFCASE=TRUE
readonly RUN_REFDIR="/pscratch/sd/j/jtolento/LANL/chrysalis_rst/"
readonly RUN_REFCASE="20231209.v3.LR.piControl-spinup.chrysalis"
readonly RUN_REFDATE="2001-01-01"
#readonly RUN_REFDIR="/lcrc/group/e3sm2/ac.golaz/E3SMv3/v3.LR.piControl/init/2001-01-01-00000"
#readonly RUN_REFCASE="20231209.v3.LR.piControl-spinup.chrysalis"
#readonly RUN_REFDATE="2001-01-01"

# Set paths
readonly CODE_ROOT="/${HOME}/E3SMv3.0.0"
readonly CASE_ROOT="/pscratch/sd/l/${USER}/sbc/${CASE_NAME}"

# Sub-directories
readonly CASE_BUILD_DIR=${CASE_ROOT}/build
readonly CASE_ARCHIVE_DIR=${CASE_ROOT}/archive

#readonly JOB_QUEUE="debug"

# Define type of run
#  short tests: 'XS_1x10_ndays', 'XS_2x5_ndays', 'S_1x10_ndays', 'M_1x10_ndays', 'L_1x10_ndays'
#  or 'production' for full simulation

#readonly run='L_1x10_ndays'  # build with this to ensure non-threading
readonly run='S_2x1_ndays'
#readonly run='custom-21_2x1_nmonths'
#readonly run='S_2x5_ndays'
#readonly run='M_1x1_nmonths'

#readonly run='production'

if [[ "${run}" != "production" ]]; then
  echo "setting up Short test simulations: ${run}"
  # Short test simulations
  tmp=($(echo $run | tr "_" " "))
  layout=${tmp[0]}
  units=${tmp[2]}
  resubmit=$(( ${tmp[1]%%x*} -1 ))
  length=${tmp[1]##*x}

  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/tests/${run}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/tests/${run}/run
  readonly PELAYOUT=${layout}
  readonly WALLTIME="00:20:00"
  readonly STOP_OPTION=${units}
  readonly STOP_N=${length}
  readonly REST_OPTION=${STOP_OPTION}
  readonly REST_N=${STOP_N}
  readonly RESUBMIT=${resubmit}
  readonly DO_SHORT_TERM_ARCHIVING=false

else
  echo "setting up ${run}"
  # Production simulation
  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/run
  readonly PELAYOUT="L"
  readonly WALLTIME="48:00:00"
  readonly STOP_OPTION="nyears"
  readonly STOP_N="50"
  readonly REST_OPTION="nyears"
  readonly REST_N="1"
  readonly RESUBMIT="9"
  readonly DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler history 
readonly HIST_OPTION="nsteps"
readonly HIST_N="1"

# Leave empty (unless you understand what it does)
readonly OLD_EXECUTABLE=""

# --- Toggle flags for what to do ----
do_fetch_code=false
do_create_newcase=true
do_case_setup=true
do_case_build=true
do_case_submit=true

# --- Now, do the work ---

# Make directories created by this script world-readable
umask 022

# Fetch code from Github
fetch_code

# Create case
create_newcase

# Custom PE layout
custom_pelayout

# Setup
case_setup

# Build
case_build

# Configure runtime options
runtime_options

# Copy script into case_script directory for provenance
copy_script

# Submit
case_submit

# All done
echo $'\n----- All done -----\n'

}

# =======================
# Custom user_nl settings
# =======================

user_nl() {

cat << EOF >> user_nl_eam
 cosp_lite = .true.

 empty_htapes = .true.

 avgflag_pertape = 'A','I'
 nhtfrq = 0,-1
 mfilt  = 12,365

 fincl1 = 'CLDLOW','CLDMED','CLDHGH','CLDTOT',
          'FLDS','FLNS','FLNSC','FLNT','FLDSC',
          'FLUTC','FSDS','FSDSC','FSNS','FSNSC','FSNT','FSNTOA','FSNTOAC','FSNTC',
          'ICEFRAC','LANDFRAC','LWCF','OCNFRAC','PRECC','PRECL','PRECSC','PRECSL','PRECT','PS','PSL','Q',
          'QFLX','QREFHT','RELHUM','SHFLX','SOLIN','SWCF','T','TAUX','TAUY','TOZ',
          'TGCLDLWP','TMQ','TREFHT','TS','U','U10','V',
          'LHFLX','CO_SRF','TROP_P','SFDMS',
          'EXTINCT','AODABS','CLDICE','CLDLIQ','FLNTC',
          'PHIS','CLOUD','TGCLDIWP','TGCLDCWP','AREL',
	  'FLUT','FUL','FDL','QRL','U200','V200','U850','V850',
          'TCO','SCO','TREFHTMN','TREFHTMX','TREFHT','QREFHT',
 	  'T1000','T975','T950','T925','T900','T850',
	  'RH1000','RH975','RH950','RH925','RH900','RH850',
	  'U1000','U975','U950','U925','U900','U850',
	  'V1000','V975','V950','V925','V900','V850',
	  'Z1000','Z975','Z950','Z925','Z900','Z850',
	  'OMEGA1000','OMEGA975','OMEGA950','OMEGA925','OMEGA900','OMEGA850',
	  'PS','TUQ','TVQ','UBOT','VBOT','TBOT'
 fincl2 = 'FLNS', 'FLDS'

 ! -- chemUCI settings ------------------
 history_chemdyg_summary = .false.
 history_gaschmbudget_2D = .false.
 history_gaschmbudget_2D_levels = .false.
 history_gaschmbudget_num = 6 !! no impact if  history_gaschmbudget_2D = .false.

 ! -- MAM5 settings ------------------    
 is_output_interactive_volc = .false.        

EOF

cat << EOF >> user_nl_elm
 hist_dov2xy = .true.,.true.
 hist_fexcl1 = 'AGWDNPP','ALTMAX_LASTYEAR','AVAIL_RETRANSP','AVAILC','BAF_CROP',
               'BAF_PEATF','BIOCHEM_PMIN_TO_PLANT','CH4_SURF_AERE_SAT','CH4_SURF_AERE_UNSAT','CH4_SURF_DIFF_SAT',
               'CH4_SURF_DIFF_UNSAT','CH4_SURF_EBUL_SAT','CH4_SURF_EBUL_UNSAT','CMASS_BALANCE_ERROR','cn_scalar',
               'COL_PTRUNC','CONC_CH4_SAT','CONC_CH4_UNSAT','CONC_O2_SAT','CONC_O2_UNSAT',
               'cp_scalar','CWDC_HR','CWDC_LOSS','CWDC_TO_LITR2C','CWDC_TO_LITR3C',
               'CWDC_vr','CWDN_TO_LITR2N','CWDN_TO_LITR3N','CWDN_vr','CWDP_TO_LITR2P',
               'CWDP_TO_LITR3P','CWDP_vr','DWT_CONV_CFLUX_DRIBBLED','F_CO2_SOIL','F_CO2_SOIL_vr',
               'F_DENIT_vr','F_N2O_DENIT','F_N2O_NIT','F_NIT_vr','FCH4_DFSAT',
               'FINUNDATED_LAG','FPI_P_vr','FPI_vr','FROOTC_LOSS','HR_vr',
               'LABILEP_TO_SECONDP','LABILEP_vr','LAND_UPTAKE','LEAF_MR','leaf_npimbalance',
               'LEAFC_LOSS','LEAFC_TO_LITTER','LFC2','LITR1_HR','LITR1C_TO_SOIL1C',
               'LITR1C_vr','LITR1N_TNDNCY_VERT_TRANS','LITR1N_TO_SOIL1N','LITR1N_vr','LITR1P_TNDNCY_VERT_TRANS',
               'LITR1P_TO_SOIL1P','LITR1P_vr','LITR2_HR','LITR2C_TO_SOIL2C','LITR2C_vr',
               'LITR2N_TNDNCY_VERT_TRANS','LITR2N_TO_SOIL2N','LITR2N_vr','LITR2P_TNDNCY_VERT_TRANS','LITR2P_TO_SOIL2P',
               'LITR2P_vr','LITR3_HR','LITR3C_TO_SOIL3C','LITR3C_vr','LITR3N_TNDNCY_VERT_TRANS',
               'LITR3N_TO_SOIL3N','LITR3N_vr','LITR3P_TNDNCY_VERT_TRANS','LITR3P_TO_SOIL3P','LITR3P_vr',
               'M_LITR1C_TO_LEACHING','M_LITR2C_TO_LEACHING','M_LITR3C_TO_LEACHING','M_SOIL1C_TO_LEACHING','M_SOIL2C_TO_LEACHING',
               'M_SOIL3C_TO_LEACHING','M_SOIL4C_TO_LEACHING','NDEPLOY','NEM','nlim_m',
               'o2_decomp_depth_unsat','OCCLP_vr','PDEPLOY','PLANT_CALLOC','PLANT_NDEMAND',
               'PLANT_NDEMAND_COL','PLANT_PALLOC','PLANT_PDEMAND','PLANT_PDEMAND_COL','plim_m',
               'POT_F_DENIT','POT_F_NIT','POTENTIAL_IMMOB','POTENTIAL_IMMOB_P','PRIMP_TO_LABILEP',
               'PRIMP_vr','PROD1P_LOSS','QOVER_LAG','RETRANSN_TO_NPOOL','RETRANSP_TO_PPOOL',
               'SCALARAVG_vr','SECONDP_TO_LABILEP','SECONDP_TO_OCCLP','SECONDP_vr','SMIN_NH4_vr',
               'SMIN_NO3_vr','SMINN_TO_SOIL1N_L1','SMINN_TO_SOIL2N_L2','SMINN_TO_SOIL2N_S1','SMINN_TO_SOIL3N_L3',
               'SMINN_TO_SOIL3N_S2','SMINN_TO_SOIL4N_S3','SMINP_TO_SOIL1P_L1','SMINP_TO_SOIL2P_L2','SMINP_TO_SOIL2P_S1',
               'SMINP_TO_SOIL3P_L3','SMINP_TO_SOIL3P_S2','SMINP_TO_SOIL4P_S3','SMINP_vr','SOIL1_HR','SOIL1C_TO_SOIL2C','SOIL1C_vr','SOIL1N_TNDNCY_VERT_TRANS','SOIL1N_TO_SOIL2N','SOIL1N_vr',
               'SOIL1P_TNDNCY_VERT_TRANS','SOIL1P_TO_SOIL2P','SOIL1P_vr','SOIL2_HR','SOIL2C_TO_SOIL3C',
               'SOIL2C_vr','SOIL2N_TNDNCY_VERT_TRANS','SOIL2N_TO_SOIL3N','SOIL2N_vr','SOIL2P_TNDNCY_VERT_TRANS',
               'SOIL2P_TO_SOIL3P','SOIL2P_vr','SOIL3_HR','SOIL3C_TO_SOIL4C','SOIL3C_vr',
               'SOIL3N_TNDNCY_VERT_TRANS','SOIL3N_TO_SOIL4N','SOIL3N_vr','SOIL3P_TNDNCY_VERT_TRANS','SOIL3P_TO_SOIL4P',
               'SOIL3P_vr','SOIL4_HR','SOIL4C_vr','SOIL4N_TNDNCY_VERT_TRANS','SOIL4N_TO_SMINN',
               'SOIL4N_vr','SOIL4P_TNDNCY_VERT_TRANS','SOIL4P_TO_SMINP','SOIL4P_vr','SOLUTIONP_vr',
               'TCS_MONTH_BEGIN','TCS_MONTH_END','TOTCOLCH4','water_scalar','WF',
               'wlim_m','WOODC_LOSS','WTGQ'
 hist_fincl1 = 'SNOWDP', 'ULRAD', 'LWdown', 'LWup', 'Tair', 'PSurf',
	       'H2OSNO', 'FSNO', 'QRUNOFF', 'QSNOMELT', 'FSNO_EFF', 'SNORDSL', 'SNOW', 'FSDS', 'FSR', 'FLDS', 'FIRE', 'FIRA'
 hist_mfilt = 1
 hist_nhtfrq = 0
 hist_avgflag_pertape = 'A'

EOF

cat << EOF >> user_nl_mpassi
 config_am_timeseriesstatsmonthly_compute_on_startup = true
 config_am_timeseriesstatsmonthly_enable = true
 config_am_timeseriesstatsmonthly_write_on_startup = true

 config_am_timeseriesstatsdaily_compute_on_startup = false
 config_am_timeseriesstatsdaily_enable = false
 config_am_timeseriesstatsdaily_write_on_startup = false

EOF

cat << EOF >> user_nl_mpaso
 config_am_timeseriesstatsmonthly_compute_on_startup = true
 config_am_timeseriesstatsmonthly_enable = true
 config_am_timeseriesstatsmonthly_write_on_startup = true

EOF

}

# =====================================
# Customize MPAS stream files if needed
# =====================================

patch_mpas_streams() {

echo

}

# =====================================================
# Custom PE layout: custom-N where N is number of nodes
# =====================================================

custom_pelayout(){

if [[ ${PELAYOUT} == custom-* ]];
then
    echo $'\n CUSTOMIZE PROCESSOR CONFIGURATION:'

    # Number of cores per node (machine specific)
    #if [ "${MACHINE}" == "chrysalis" ]; then
        ncore=64
        hthrd=2  # hyper-threading
    #else
    #    echo 'ERROR: MACHINE = '${MACHINE}' is not supported for current custom PE layout setting.'
    #    exit 400
    #fi

    # Extract number of nodes
    tmp=($(echo ${PELAYOUT} | tr "-" " "))
    nnodes=${tmp[1]}

    # Applicable to all custom layouts
    pushd ${CASE_SCRIPTS_DIR}
    ./xmlchange NTASKS=1
    ./xmlchange NTHRDS=1
    ./xmlchange ROOTPE=0
    ./xmlchange MAX_MPITASKS_PER_NODE=128  # $ncore LM changed after test1 first submission
    ./xmlchange MAX_TASKS_PER_NODE=256 # $(( $ncore * $hthrd)) LM changed after test1 first submission

    # Layout-specific customization
    if [ "${nnodes}" == "104" ]; then

       echo Using custom 104 nodes layout

       ### Current defaults for L
      ./xmlchange CPL_NTASKS=5440
      ./xmlchange ATM_NTASKS=5440
      ./xmlchange OCN_NTASKS=1216
      ./xmlchange OCN_ROOTPE=5440

      ./xmlchange LND_NTASKS=1088
      ./xmlchange ROF_NTASKS=1088
      ./xmlchange ICE_NTASKS=4352
      ./xmlchange LND_ROOTPE=4352
      ./xmlchange ROF_ROOTPE=4352

    elif [ "${nnodes}" == "52" ]; then

       echo Using custom 52 nodes layout

      ./xmlchange CPL_NTASKS=2720
      ./xmlchange ATM_NTASKS=2720
      ./xmlchange OCN_NTASKS=608
      ./xmlchange OCN_ROOTPE=2720

      ./xmlchange LND_NTASKS=544
      ./xmlchange ROF_NTASKS=544
      ./xmlchange ICE_NTASKS=2176
      ./xmlchange LND_ROOTPE=2176
      ./xmlchange ROF_ROOTPE=2176

    elif [ "${nnodes}" == "21" ]; then

       echo Using Juans custom 21 nodes layout

      # orig
      #./xmlchange CPL_NTASKS=704
      #./xmlchange ATM_NTASKS=675
      #./xmlchange OCN_NTASKS=128
      #./xmlchange LND_NTASKS=128
      #./xmlchange ROF_NTASKS=128
      #./xmlchange ICE_NTASKS=576
      
      #./xmlchange OCN_ROOTPE=704
      #./xmlchange LND_ROOTPE=576
      #./xmlchange ROF_ROOTPE=576
      #./xmlchange ATM_ROOTPE=0
      #./xmlchange CPL_ROOTPE=0
      #./xmlchange ICE_ROOTPE=0

      export NPROCS_ATM=1800
      export NPROCS_LND=768
      export NPROCS_ROF=768
      export NPROCS_ICE=1152
      export NPROCS_OCN=768
      export NPROCS_CPL=1920
      export NPROCS_WAV=1
      export NPROCS_GLC=1
      export NPROCS_ESP=1
      export NPROCS_IAC=1

      ./xmlchange --file env_mach_pes.xml  --id PSTRID_CPL  --val 1
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_CPL  --val $NPROCS_CPL
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_ATM  --val $NPROCS_ATM
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_LND  --val $NPROCS_LND
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_ROF  --val $NPROCS_ROF
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_ICE  --val $NPROCS_ICE
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_OCN  --val $NPROCS_OCN
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_GLC  --val $NPROCS_GLC
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_WAV  --val $NPROCS_WAV
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_ESP  --val $NPROCS_ESP
      ./xmlchange --file env_mach_pes.xml  --id NTASKS_IAC  --val $NPROCS_IAC

      ./xmlchange LND_ROOTPE=1152
      ./xmlchange ROF_ROOTPE=1152
      ./xmlchange OCN_ROOTPE=1920

    else

       echo 'ERROR: unsupported layout '${PELAYOUT}
       exit 401

    fi

    popd

fi

}
######################################################
### Most users won't need to change anything below ###
######################################################

#-----------------------------------------------------
fetch_code() {

    if [ "${do_fetch_code,,}" != "true" ]; then
        echo $'\n----- Skipping fetch_code -----\n'
        return
    fi

    echo $'\n----- Starting fetch_code -----\n'
    local path=${CODE_ROOT}
    local repo=E3SM

    echo "Cloning $repo repository branch $BRANCH under $path"
    if [ -d "${path}" ]; then
        echo "ERROR: Directory already exists. Not overwriting"
        exit 20
    fi
    mkdir -p ${path}
    pushd ${path}

    # This will put repository, with all code
    git clone git@github.com:E3SM-Project/${repo}.git .

    # Check out desired branch
    git checkout ${BRANCH}

    # Custom addition
    if [ "${CHERRY}" != "" ]; then
        echo ----- WARNING: adding git cherry-pick -----
        for commit in "${CHERRY[@]}"
        do
            echo ${commit}
            git cherry-pick ${commit}
        done
        echo -------------------------------------------
    fi

    # Bring in all submodule components
    git submodule update --init --recursive

    popd
}

#-----------------------------------------------------
create_newcase() {

    if [ "${do_create_newcase,,}" != "true" ]; then
        echo $'\n----- Skipping create_newcase -----\n'
        return
    fi

    echo $'\n----- Starting create_newcase -----\n'

    if [[ ${PELAYOUT} == custom-* ]];
    then
        layout="M" # temporary placeholder for create_newcase
    else
        layout=${PELAYOUT}

    fi

    # Base arguments
    args=" --case ${CASE_NAME} \
        --output-root ${CASE_ROOT} \
        --script-root ${CASE_SCRIPTS_DIR} \
        --handle-preexisting-dirs u \
        --compset ${COMPSET} \
        --res ${RESOLUTION} \
        --machine ${MACHINE} \
        --walltime ${WALLTIME} \
        --pecount ${PELAYOUT}"

    # Oprional arguments
    if [ ! -z "${PROJECT}" ]; then
      args="${args} --project ${PROJECT}"
    fi
    if [ ! -z "${CASE_GROUP}" ]; then
      args="${args} --case-group ${CASE_GROUP}"
    fi
    if [ ! -z "${QUEUE}" ]; then
      args="${args} --queue ${QUEUE}"
    fi

    ${CODE_ROOT}/cime/scripts/create_newcase ${args}

    if [ $? != 0 ]; then
      echo $'\nNote: if create_newcase failed because sub-directory already exists:'
      echo $'  * delete old case_script sub-directory'
      echo $'  * or set do_newcase=false\n'
      exit 35
    fi

}

#-----------------------------------------------------
case_setup() {

    if [ "${do_case_setup,,}" != "true" ]; then
        echo $'\n----- Skipping case_setup -----\n'
        return
    fi

    echo $'\n----- Starting case_setup -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Setup some CIME directories
    ./xmlchange EXEROOT=${CASE_BUILD_DIR}
    ./xmlchange RUNDIR=${CASE_RUN_DIR}

    # Short term archiving
    ./xmlchange DOUT_S=${DO_SHORT_TERM_ARCHIVING^^}
    ./xmlchange DOUT_S_ROOT=${CASE_ARCHIVE_DIR}

    # LM change to RASM2
    ./xmlchange --file env_run.xml --id CPL_SEQ_OPTION --val "RASM_OPTION1"

    # Build with COSP, except for a data atmosphere (datm)
    if [ `./xmlquery --value COMP_ATM` == "datm"  ]; then 
      echo $'\nThe specified configuration uses a data atmosphere, so cannot activate COSP simulator\n'
    else
      echo $'\nConfiguring E3SM to use the COSP simulator\n'
      ./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp'
    fi

    # Extracts input_data_dir in case it is needed for user edits to the namelist later
    local input_data_dir=`./xmlquery DIN_LOC_ROOT --value`

    # Custom user_nl
    user_nl

    # Finally, run CIME case.setup
    ./case.setup --reset

    popd
}

#-----------------------------------------------------
case_build() {

    pushd ${CASE_SCRIPTS_DIR}

    # do_case_build = false
    if [ "${do_case_build,,}" != "true" ]; then

        echo $'\n----- case_build -----\n'

        if [ "${OLD_EXECUTABLE}" == "" ]; then
            # Ues previously built executable, make sure it exists
            if [ -x ${CASE_BUILD_DIR}/e3sm.exe ]; then
                echo 'Skipping build because $do_case_build = '${do_case_build}
            else
                echo 'ERROR: $do_case_build = '${do_case_build}' but no executable exists for this case.'
                exit 297
            fi
        else
            # If absolute pathname exists and is executable, reuse pre-exiting executable
            if [ -x ${OLD_EXECUTABLE} ]; then
                echo 'Using $OLD_EXECUTABLE = '${OLD_EXECUTABLE}
                cp -fp ${OLD_EXECUTABLE} ${CASE_BUILD_DIR}/
            else
                echo 'ERROR: $OLD_EXECUTABLE = '$OLD_EXECUTABLE' does not exist or is not an executable file.'
                exit 297
            fi
        fi
        echo 'WARNING: Setting BUILD_COMPLETE = TRUE.  This is a little risky, but trusting the user.'
        ./xmlchange BUILD_COMPLETE=TRUE

    # do_case_build = true
    else

        echo $'\n----- Starting case_build -----\n'

        # Turn on debug compilation option if requested
        if [ "${DEBUG_COMPILE^^}" == "TRUE" ]; then
            ./xmlchange DEBUG=${DEBUG_COMPILE^^}
        fi

        # Run CIME case.build
        ./case.build

    fi

    # Some user_nl settings won't be updated to *_in files under the run directory
    # Call preview_namelists to make sure *_in and user_nl files are consistent.
    echo $'\n----- Preview namelists -----\n'
    ./preview_namelists

    popd
}

#-----------------------------------------------------
runtime_options() {

    echo $'\n----- Starting runtime_options -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Set simulation start date
    ./xmlchange RUN_STARTDATE=${START_DATE}

    # Segment length
    ./xmlchange STOP_OPTION=${STOP_OPTION,,},STOP_N=${STOP_N}

    # Restart frequency
    ./xmlchange REST_OPTION=${REST_OPTION,,},REST_N=${REST_N}

    # Coupler history
    ./xmlchange HIST_OPTION=${HIST_OPTION,,},HIST_N=${HIST_N}

    # Coupler budgets (always on)
    ./xmlchange BUDGETS=TRUE

    # Set resubmissions
    if (( RESUBMIT > 0 )); then
        ./xmlchange RESUBMIT=${RESUBMIT}
    fi

    # Run type
    # Start from default of user-specified initial conditions
    if [ "${MODEL_START_TYPE,,}" == "initial" ]; then
        ./xmlchange RUN_TYPE="startup"
        ./xmlchange CONTINUE_RUN="FALSE"

    # Continue existing run
    elif [ "${MODEL_START_TYPE,,}" == "continue" ]; then
        ./xmlchange CONTINUE_RUN="TRUE"
	echo "Prepare the restart files - copy restart-point files over to ../run for the relocated case"

    elif [ "${MODEL_START_TYPE,,}" == "branch" ] || [ "${MODEL_START_TYPE,,}" == "hybrid" ]; then
        ./xmlchange RUN_TYPE=${MODEL_START_TYPE,,}
        ./xmlchange GET_REFCASE=${GET_REFCASE}
        ./xmlchange RUN_REFDIR=${RUN_REFDIR}
        ./xmlchange RUN_REFCASE=${RUN_REFCASE}
        ./xmlchange RUN_REFDATE=${RUN_REFDATE}
        echo 'Warning: $MODEL_START_TYPE = '${MODEL_START_TYPE} 
        echo '$RUN_REFDIR = '${RUN_REFDIR}
        echo '$RUN_REFCASE = '${RUN_REFCASE}
        echo '$RUN_REFDATE = '${START_DATE}
    else
        echo 'ERROR: $MODEL_START_TYPE = '${MODEL_START_TYPE}' is unrecognized. Exiting.'
        exit 380
    fi

    # Patch mpas streams files
    patch_mpas_streams

    popd
}

#-----------------------------------------------------
case_submit() {

    if [ "${do_case_submit,,}" != "true" ]; then
        echo $'\n----- Skipping case_submit -----\n'
        return
    fi

    echo $'\n----- Starting case_submit -----\n'
    pushd ${CASE_SCRIPTS_DIR}
    
    # Run CIME case.submit
    ./case.submit

    popd
}

#-----------------------------------------------------
copy_script() {

    echo $'\n----- Saving run script for provenance -----\n'

    local script_provenance_dir=${CASE_SCRIPTS_DIR}/run_script_provenance
    mkdir -p ${script_provenance_dir}
    local this_script_name=`basename $0`
    local script_provenance_name=${this_script_name}.`date +%Y%m%d-%H%M%S`
    cp -vp ${this_script_name} ${script_provenance_dir}/${script_provenance_name}

}

#-----------------------------------------------------
# Silent versions of popd and pushd
pushd() {
    command pushd "$@" > /dev/null
}
popd() {
    command popd "$@" > /dev/null
}

# Now, actually run the script
#-----------------------------------------------------
main

