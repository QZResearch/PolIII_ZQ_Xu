#!/bin/bash


for i in {5..1}
do

cat > 03.equal.npt.${i}.mdin <<-EOF
	NPT Equilibrium Force ${i}
	&cntrl
	nstlim=500000,
	dt=0.004,
	ntx=5,  ! Coordinates and velocities, will be read;
	irest=1,! restart the simulation, reading coordinates and velocities
	ntpr=5000,
	ntwr=5000,
	ntwx=5000,
	
	temp0=310.0,
	ntt=3,
	gamma_ln=3.,

	ntb=2,          ! switched on constant pressure
	ntp=1,  ! isotropic position scaling
	taup=2.

	ntc=2,  ! Bonds involving hydrogen are constrained with SHAKE algorithm
	ntf=2,  ! Bonds interactions

	ntr=1,  ! Turn on restraints
	restraintmask="@CA,P", ! atoms to be restrained
	restraint_wt=${i},
	
	iwrap=1,    ! iwrap is turn on
	/
EOF
	
	if [ $i -eq 5 ]; then
let nxt=i-1
cat > run.npt.$i<<-COF1
#!/bin/bash

#PBS -l walltime=12:00:00
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

mpirun -np \${PBS_NGPUS} pmemd.cuda.MPI -O -i 03.equal.npt.${i}.mdin \\
				-o 03.equal.npt.${i}.mdout \\
				-p ../J117_total_hmass.prmtop \\
				-c ../02heat/02.heat.rst \\
				-ref ../02heat/02.heat.rst \\
				-x 03.equal.npt.${i}.crd \\
				-r 03.equal.npt.${i}.rst \\
				-inf 03.equal.npt.${i}.info

qsub run.npt.$nxt
COF1
	else
		let j=i+1
		let nxt=i-1

cat > run.npt.$i<<-COF2
#!/bin/bash

#PBS -l walltime=12:00:00
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

mpirun -np \${PBS_NGPUS} pmemd.cuda.MPI -O -i 03.equal.npt.${i}.mdin \\
				-o 03.equal.npt.${i}.mdout \\
				-p ../J117_total_hmass.prmtop \\
				-c 03.equal.npt.${j}.rst \\
				-ref 03.equal.npt.${j}.rst \\
				-x 03.equal.npt.${i}.crd \\
				-r 03.equal.npt.${i}.rst \\
				-inf 03.equal.npt.${i}.info
qsub run.npt.$nxt
COF2
	fi
done
