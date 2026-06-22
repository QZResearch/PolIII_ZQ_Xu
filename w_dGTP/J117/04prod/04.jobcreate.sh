#!/bin/bash


for i in {1..20}
do

let nxt=i+1
	if [ $i -eq 1 ]; then
cat > run.prod.$i<<-COF1
#!/bin/bash

#PBS -l walltime=24:00:00
#PBS -l mem=5000MB
#PBS -q gpuvolta
#PBS -l ngpus=1
#PBS -l ncpus=12
#PBS -l software=amber
#PBS -l storage=gdata/eh83+scratch/eh83
#PBS -l wd
#PBS -P eh83

# Running production steps
module load cuda/12.0.0
module load amber/22

mpirun -np \$PBS_NGPUS pmemd.cuda.MPI -O -i npt.prod.mdin \\
				-o 04.prod.npt.${i}.mdout \\
				-p ../J117_total_hmass.prmtop \\
				-c ../03npt/03.equal.npt.1.rst \\
				-x 04.prod.npt.${i}.crd \\
				-r 04.prod.npt.${i}.rst \\
				-inf 04.prod.npt.${i}.info

qsub run.prod.$nxt
COF1
	else
let prev=i-1
cat > run.prod.$i<<-COF2
#!/bin/bash

#PBS -l walltime=24:00:00
#PBS -l mem=5000MB
#PBS -q gpuvolta
#PBS -l ngpus=1
#PBS -l ncpus=12
#PBS -l software=amber
#PBS -l storage=gdata/eh83+scratch/eh83
#PBS -l wd
#PBS -P eh83

# Running production steps
module load cuda/12.0.0
module load amber/22

mpirun -np \$PBS_NGPUS pmemd.cuda.MPI -O -i npt.prod.mdin \\
				-o 04.prod.npt.${i}.mdout \\
				-p ../J117_total_hmass.prmtop \\
				-c 04.prod.npt.${prev}.rst \\
				-x 04.prod.npt.${i}.crd \\
				-r 04.prod.npt.${i}.rst \\
				-inf 04.prod.npt.${i}.info
qsub run.prod.$nxt
COF2
	fi
done
