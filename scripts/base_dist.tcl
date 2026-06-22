#!/bin/tclsh

if {1} {
	set num_frames_total 0
	set output [open "dist_angle.dat" "w"]
}

proc distance {v1 v2} {
	set vector [vecsub $v1 $v2]
	set vecl   [veclength $vector]
	return $vecl
}

proc norm_ang {v1 v2} {
    set v1_len [veclength $v1]
    set v2_len [veclength $v2]
    set v1dotv2 [vecdot $v1 $v2]
    set angle [expr acos($v1dotv2/($v1_len * $v2_len))/3.1415926*180]
    return $angle
}



foreach filename ${argv} {
	animate delete all
	mol addfile ${filename} type netcdf waitfor all

	set num_frames [molinfo top get numframes]

	for {set i 0} {${i} < ${num_frames}} {incr i 1} {
		set frame [expr ${num_frames_total} + ${i} +1]

		# section for hbond distance analysis between dgt and the nucleotide at the junction of ds and ssDNA
		set sel1_O2 [atomselect top "resid 1061 and name O2"]
		set sel1_N3 [atomselect top "resid 1061 and name N3"]
		set sel1_N4 [atomselect top "resid 1061 and name N4"]

		set sel2_N2 [atomselect top "resname dgt and name N2"]
		set sel2_H1 [atomselect top "resname dgt and name H1"]
		set sel2_O6 [atomselect top "resname dgt and name O6"]
	
		# section for norm vec formed using three points within a plate
		set selP_plate_CG [atomselect top "protein and resid 1844 and name CG"]
		set selP_plate_CE1 [atomselect top "protein and resid 1844 and name CE1"]
		set selP_plate_CE2 [atomselect top "protein and resid 1844 and name CE2"]

		set selN_plate_N9 [atomselect top "resname dgt and name N9"]
		set selN_plate_C2 [atomselect top "resname dgt and name C2"]
		set selN_plate_C5 [atomselect top "resname dgt and name C5"]

		# section for base selection for calculating the distance between them
		set selP754 [atomselect top "resid 1844 and name CD1 CE1 CZ CE2 CD2 CG"]
		set selNdgt [atomselect top "resname dgt and name N1 C2 N2 N3 C4 C5 C6 O6 N7 C8 N9"]


		$sel1_O2 frame $i
		$sel1_N3 frame $i
		$sel1_N4 frame $i

		$sel2_N2 frame $i
		$sel2_H1 frame $i
		$sel2_O6 frame $i

		$selP_plate_CG frame $i
		$selP_plate_CE1 frame $i
		$selP_plate_CE2 frame $i

		$selN_plate_N9 frame $i
		$selN_plate_C2 frame $i
		$selN_plate_C5 frame $i

		$selP754 frame $i
		$selNdgt frame $i

		set xyzP_CG [lindex [$selP_plate_CG get {x y z}] 0]
		set xyzP_CE1 [lindex [$selP_plate_CE1 get {x y z}] 0]
		set xyzP_CE2 [lindex [$selP_plate_CE2 get {x y z}] 0]

		set xyzN_N9 [lindex [$selN_plate_N9 get {x y z}] 0]
		set xyzN_C2 [lindex [$selN_plate_C2 get {x y z}] 0]
		set xyzN_C5 [lindex [$selN_plate_C5 get {x y z}] 0]

		set vecP_CG_CE1 [vecsub $xyzP_CE1 $xyzP_CG]
		set vecP_CG_CE2 [vecsub $xyzP_CE2 $xyzP_CG]
		set normP       [veccross $vecP_CG_CE1 $vecP_CG_CE2]

		set vecN_N9_C2 [vecsub $xyzN_C2 $xyzN_N9]
		set vecN_N9_C5 [vecsub $xyzN_C5 $xyzN_N9]
		set normN      [vecsub $vecN_N9_C2 $vecN_N9_C5]

		set normAng    [norm_ang $normP $normN]

		set comP        [measure center $selP754 weight mass]
		set comN        [measure center $selNdgt weight mass]

		set xyz1_O2 [lindex [$sel1_O2 get {x y z}] 0]
		set xyz1_N3 [lindex [$sel1_N3 get {x y z}] 0]
		set xyz1_N4 [lindex [$sel1_N4 get {x y z}] 0]

		set xyz2_N2 [lindex [$sel2_N2 get {x y z}] 0]
		set xyz2_H1 [lindex [$sel2_H1 get {x y z}] 0]
		set xyz2_O6 [lindex [$sel2_O6 get {x y z}] 0]

		set d1 [distance $xyz1_O2 $xyz2_N2]
		set d2 [distance $xyz1_N3 $xyz2_H1]
		set d3 [distance $xyz1_N4 $xyz2_O6]

		set dPN [distance $comP $comN]

		puts -nonewline ${output} [format "%10d " $frame]
		puts -nonewline ${output} [format "%10.5f " $d1]
		puts -nonewline ${output} [format "%10.5f " $d2]
		puts -nonewline ${output} [format "%10.5f " $d3]
		puts -nonewline ${output} [format "%10.5f " $normAng]
		puts ${output} [format "%10.5f " $dPN]
		

		$sel1_O2 delete
		$sel1_N3 delete
		$sel1_N4 delete
		$sel2_N2 delete
		$sel2_H1 delete
		$sel2_O6 delete

		$selP_plate_CG delete
		$selP_plate_CE1 delete
		$selP_plate_CE2 delete
		$selN_plate_N9 delete
		$selN_plate_C2 delete
		$selN_plate_C5 delete

		$selP754 delete
		$selNdgt delete
		
	}
	set num_frames_total [expr ${num_frames_total} + ${num_frames}]
}

quit
