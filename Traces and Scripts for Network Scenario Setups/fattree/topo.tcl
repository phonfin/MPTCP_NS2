#command line help
if { $argc != 2 } {
	puts "Usage: ./ns <tcl-script> <#pod> <#.ti file>"
	puts "E.g.: ./ns fatdc.tcl 04 04"
	exit 1
}
#-----mptcp parameters-----
set NUM_SUB 2;
set MINRTT 0;
set SCHED $MINRTT;	# set up one scheduler for MPTCP, mptcp by default
set RR 1;
set R_WIN 10;

set startTime 1;
set endTime 3;
set trace_all_name "./mptcp_trace_all_[lindex $argv 0].ta";
set nam_file "./mptcp_nam_[lindex $argv 0].nam";

set pod [lindex $argv 1];
set pod [expr $pod];
#set host_per_pod [lindex $argv 2];
#set host_per_pod [expr $host_per_pod];

#puts "POD: $pod; HOST_PER_POD:$host_per_pod"

set packetSize 1460;
set RTT 0.0001;
set line_latency [expr $RTT];
set BUFFER 100;
set FLOW_NUM 0;
set enableNAM 0;
set enableTraceAll 0;
set ToR_lineRate 1Gb;
set ToR_lineRate_down 1Gb;
set ToR_lineRate_up 2Gb;
set corelineRate 10Gb;

set switchAlg DropTail

set ns [new Simulator]
# multipath configuration
Node set multiPath_ 1
#Classifier/MultiPath set perflow_ 1
#Classifier/MultiPath set checkpathid_ 1

Agent/TCP set packetSize_ $packetSize
Agent/TCP set window_ 2000;	# advise window

Queue set limit_ 1000;

if {$enableTraceAll != 0} {
	set traceall [open $trace_all_name w];
	$ns trace-all $traceall;
}

if {$enableNAM != 0} {
	set namfile [open $nam_file w];
	$ns namtrace-all $nam_file;
}

proc finish {} {
	global ns traceall nam_file enableTraceAll enableNAM
	$ns flush-trace

	if {$enableTraceAll != 0} {
	close $traceall;
	}

	if {$enableNAM != 0} {
	close $nam_file
	#exec nam $nam_file &
	}
	exit 0
}

#----------------------topology generation-------------------

# loop variables: p: pod, s: switch, i: host
# generating hosts
for {set p 0} {$p < $pod} {incr p} {
	for {set s 0} {$s < $pod/2} {incr s} {
		for {set i 0} {$i < $pod/2} {incr i} {
			set hosts($p,$s,$i) [$ns node]
			# puts "p:$p, s:$s, i:$i"
		}
	}
}

# generating edge switches (es) level 1
for {set p 0} {$p < $pod} {incr p} {
	for {set s 0} {$s < $pod/2} {incr s} {
		set es($p,$s) [$ns node]
		$es($p,$s) color green
		$es($p,$s) shape box
	}
}

# generating aggregation switches (as)  level 2
for {set p 0} {$p < $pod} {incr p} {
	for {set s 0} {$s < $pod/2} {incr s} {
		set as($p,$s) [$ns node]
		$as($p,$s) color blue
		$as($p,$s) shape box
	}
}
# generating core switches (cs)  level 3
for {set p 0} {$p < $pod/2} {incr p} {
	for {set s 0} {$s < $pod/2} {incr s} {
		set cs($p,$s) [$ns node]
		$cs($p,$s) color red
		$cs($p,$s) shape box
	}
}


# generating links between hosts and es
for {set p 0} {$p < $pod} {incr p} {
	for {set s 0} {$s < $pod/2} {incr s} {
		for {set i 0} {$i < $pod/2} {incr i} {

			$ns simplex-link $hosts($p,$s,$i) $es($p,$s) $ToR_lineRate_up [expr $RTT] DropTail
			$ns simplex-link $es($p,$s) $hosts($p,$s,$i) $ToR_lineRate_down [expr $RTT] $switchAlg

			$ns queue-limit $es($p,$s) $hosts($p,$s,$i) $BUFFER

			$ns duplex-link-op $hosts($p,$s,$i) $es($p,$s) queuePos 0.25
		}
	}
}


# generating links between es and as
for {set p 0} {$p < $pod} {incr p} {
	for {set s 0} {$s < $pod/2} {incr s} {
		for {set i 0} {$i < $pod/2} {incr i} {

			$ns duplex-link $es($p,$i) $as($p,$s) $corelineRate [expr $RTT] $switchAlg
			$ns queue-limit $es($p,$i) $as($p,$s) $BUFFER
			$ns queue-limit $as($p,$s) $es($p,$i) $BUFFER

			$ns duplex-link-op $es($p,$i) $as($p,$s) queuePos 0.25
		}
	}
}



# generating links between as and cs
for {set p 0} {$p < $pod} {incr p} {
	for {set s 0} {$s < $pod/2} {incr s} {
		for {set c 0} {$c < $pod/2} {incr c} {
			$ns duplex-link $as($p,$s) $cs($c,$s) $corelineRate [expr $RTT] $switchAlg
			$ns queue-limit $as($p,$s) $cs($c,$s) $BUFFER
			$ns queue-limit $cs($c,$s) $as($p,$s) $BUFFER

			$ns duplex-link-op $as($p,$s) $cs($c,$s) queuePos 0.25

		}
	}
}
#--------------------------------------------------------------
#Multipath configuration
#$ns rtproto DV
#Agent/rtProto/DV set advertInterval 16
$ns rtproto Session
