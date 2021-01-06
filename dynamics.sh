#!/bin/bash
 
#Execution parameters: terminal inputs
input_file=$1
output_dir=$2

#Paths of each archives
current_abs_dir=$(pwd)
input_filename=$(basename -- "$input_file")
input_filename="${input_filename%.*}"
input_dir="$current_abs_dir/$(dirname $input_file)"
processed_filename="$(echo $input_filename)_processed.gro"
processed_file="$current_abs_dir/$output_dir/$processed_filename"  
newbox_filename="$(echo $input_filename)_newbox.gro"
newbox_file="$current_abs_dir/$output_dir/$newbox_filename" 
solv_filename="$(echo $input_filename)_solv.gro"
solv_file="$current_abs_dir/$output_dir/$solv_filename" 
solv_ions_filename="$(echo $input_filename)_solv_ions.gro"
solv_ions_file="$current_abs_dir/$output_dir/$solv_ions_filename" 

#Changes to output directory
cd $output_dir

#Gromacs commands
echo "15" | gmx pdb2gmx -f $current_abs_dir/$input_file -o $processed_file -water spce 
gmx editconf -f $processed_file -o $newbox_filename -c -d 1.0 -bt cubic
gmx solvate -cp $newbox_filename -cs spc216.gro -o $solv_filename -p topol.top
gmx grompp -f $input_dir/ions.mdp -c $solv_filename -p topol.top -o $current_abs_dir/$output_dir/ions.tpr
echo "13" | gmx genion -s $current_abs_dir/$output_dir/ions.tpr -o $solv_ions_filename -p topol.top -pname NA -nname CL -neutral
gmx grompp -f $input_dir/minim.mdp -c $solv_ions_filename -p topol.top -o $current_abs_dir/$output_dir/em.tpr
gmx mdrun -v -deffnm em
echo "10 0" | gmx energy -f $current_abs_dir/$output_dir/em.edr -o $current_abs_dir/$output_dir/potential.xvg
gmx grompp -f $input_dir/nvt.mdp -c em.gro -r em.gro -p topol.top -o $current_abs_dir/$output_dir/nvt.tpr
gmx mdrun -v -deffnm nvt
echo "16 0" | gmx energy -f $input_dir/nvt.edr -o $current_abs_dir/$output_dir/temperature.xvg
gmx grompp -f $input_dir/npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o $current_abs_dir/$output_dir/npt.tpr
gmx mdrun -v -deffnm npt
echo "18 0" | gmx energy -f $input_dir/npt.edr -o $current_abs_dir/$output_dir/pressure.xvg
echo "24 0" | gmx energy -f $input_dir/npt.edr -o $current_abs_dir/$output_dir/density.xvg
gmx grompp -f $input_dir/md.mdp -c npt.gro -t npt.cpt -p topol.top -o $current_abs_dir/$output_dir/md_0_1.tpr
gmx mdrun -v -deffnm md_0_1

cd -
