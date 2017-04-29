transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/Aluno/Downloads/LabAOC2-master/LabAOC2-master/LabAOC2-master/TP2 {C:/Users/Aluno/Downloads/LabAOC2-master/LabAOC2-master/LabAOC2-master/TP2/Tp2.v}
vlog -vlog01compat -work work +incdir+C:/Users/Aluno/Downloads/LabAOC2-master/LabAOC2-master/LabAOC2-master/TP2 {C:/Users/Aluno/Downloads/LabAOC2-master/LabAOC2-master/LabAOC2-master/TP2/inst_mem.v}

