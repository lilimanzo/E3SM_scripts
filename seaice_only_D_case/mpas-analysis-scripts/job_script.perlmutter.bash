#!/bin/bash
#SBATCH --account=m4572
#SBATCH --nodes=2
#SBATCH --exclusive
#SBATCH --time=00:30:00
#SBATCH --qos=debug
#SBATCH --constraint=cpu
#SBATCH --job-name=mpas_analysis
#SBATCH --output=log-mpas-analysis.o%j
#SBATCH --error=log-mpas-analysis.e%j

export OMP_NUM_THREADS=1

source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

export HDF5_USE_FILE_LOCKING=FALSE

#run_config_file="example.cfg"
#run_config_file="baseline.cfg"
#run_config_file="snow-conductivity.cfg"
#run_config_file="snow-shortwave.cfg"
#run_config_file="ocean-drag.cfg"

#run_config_file="baseline_vs_snow-conductivity.cfg"
#run_config_file="baseline_vs_snow-shortwave.cfg"
run_config_file="baseline_vs_ocean-drag.cfg"


mpas_analysis --verbose $run_config_file --purge

