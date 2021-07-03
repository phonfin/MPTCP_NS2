set file_name "./[lindex $argv 0].ti";
set index_ 14999;
set TEST false;

# if {$TEST} {

# 	set flow_num 15000;
# } else {

# 	set flow_num [expr $TASK_NO*$FLOW_NO];
# }

Class Flow

# the meaning of parameters
#t:	task id
#f:	flow id
#sn:send node id
#rn:receive node id
#s:	flow size
#a:	arrival time
Flow instproc init { t f sn rn s a } {

	$self instvar tid_;
	$self instvar fid_;
	$self instvar snid_;
	$self instvar rnid_;
	$self instvar flow_size_;
	$self instvar arrival_time_;

	set tid_ $t;
	set fid_ $f;
	set snid_ $sn;
	set rnid_ $rn;
	set flow_size_ $s;
	set arrival_time_ $a;
}

Flow instproc getTid {} {

	$self instvar tid_;
	return $tid_;
}

Flow instproc getFid {} {

	$self instvar fid_;
	return $fid_;
}

Flow instproc getSNid {} {

	$self instvar snid_;
	return $snid_;
}

Flow instproc getRNid {} {

	$self instvar rnid_;
	return $rnid_;
}

Flow instproc getFS {} {

	$self instvar flow_size_;
	return $flow_size_;
}

Flow instproc getAT {} {

	$self instvar arrival_time_;
	return $arrival_time_;
}

proc ReadFile_SINGLE { file_name counter} {

	set f [open $file_name r];
	set cc 0;

	while { [gets $f line]} {

		# puts "cc=$cc";
		if {$cc<$counter} {

			set cc [expr $cc+1];
			continue;
		} else {

			if { $cc==$counter} {

				set result [split $line];
				set flow [new Flow [lindex $result 0] [lindex $result 1] [lindex $result 2] [lindex $result 3] [lindex $result 4] [lindex $result 5]];
				break;
			} else {

				break;
			}
			set cc [expr $cc+1];
		}
	}

	close $f;
	return $flow;
}

proc ReadFile_ALL { file_name } {

	global flows FLOW_NUM;
	set f [open $file_name r];
	set cc 0;

	while { [gets $f line] != -1} {
	
		# puts "----$cc finished----";	
		set result [split $line];
		set flows($cc) [new Flow [lindex $result 0] [lindex $result 1] [lindex $result 2] [lindex $result 3] [lindex $result 4] [lindex $result 5]];
		set cc [expr $cc+1];
		incr FLOW_NUM;
	}

#	puts "#.ti file load finished..."
	close $f;
}

if {$TEST} {

	set f(0) [ReadFile_SINGLE $file_name $index_];
	set f(1) [ReadFile_SINGLE $file_name [expr $index_-1]];
	puts "$index_:[$f(0) getTid] & [expr $index_-1]:[$f(1) getTid]";
	puts "$index_:[$f(0) getFid] & [expr $index_-1]:[$f(1) getFid]";
	puts "$index_:[$f(0) getNid] & [expr $index_-1]:[$f(1) getNid]";
	puts "$index_:[$f(0) getFS] & [expr $index_-1]:[$f(1) getFS]";
	puts "$index_:[$f(0) getAT] & [expr $index_-1]:[$f(1) getAT]";
	puts "----------single test finished----------"
}

ReadFile_ALL $file_name;

if {$TEST} {

	#ReadFile_ALL $file_name;
	puts "0:[$flows(0) getTid] & 1:[$flows(1) getTid]";
	puts "0:[$flows(0) getFid] & 1:[$flows(1) getFid]";
	puts "0:[$flows(0) getNid] & 1:[$flows(1) getNid]";
	puts "0:[$flows(0) getFS] & 1:[$flows(1) getFS]";
	puts "0:[$flows(0) getAT] & 1:[$flows(1) getAT]";	
	puts "---load test finished---";	
	# for {set i 0} {$i<$flow_num} {incr i} {

	# 	puts "[$flows($i) getTid]";
	# 	puts "[$flows($i) getFid]";
	# 	puts "[$flows($i) getNid]";
	# 	puts "[$flows($i) getFS]";
	# 	puts "[$flows($i) getAT]";
	# 	puts "-------$i finished--------";
	# }
}
