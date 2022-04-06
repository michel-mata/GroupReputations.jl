#!/bin/bash
#SBATCH --job-name=adaptive-dynamics-grp
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --mail-type=all
#SBATCH --mail-user=sm75@princeton.edu
#SBATCH --array=2101-2400
#SBATCH --output=out/%A-%a.out

echo "My SLURM_ARRAY_JOB_ID is $SLURM_ARRAY_JOB_ID."
echo "My SLURM_ARRAY_TASK_ID is $SLURM_ARRAY_TASK_ID"
echo "Executing on the machine:" $(hostname)

module purge
module load julia/1.6.1
module list

julia adaptive-dynamics.jl
