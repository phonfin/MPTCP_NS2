#command line help
if { $argc != 3 } {
	puts "Usage: ./ns <tcl-script> <#pod> <#host per pod>"
	puts "E.g.: ./ns fatdc.tcl 04 04"
	exit 1
}
#-----mptcp parameters-----
set NUM_SUB 2;
set MINRTT 0;
set RR 1;
set WRR 3;
set SCHED $MINRTT;	# set up one scheduler for MPTCP, mptcp by default
set R_WIN 64;

set startTime 1;
set endTime 10;
set trace_all_name "./mptcp_trace_all_[lindex $argv 0].ta";
set nam_file "./mptcp_nam_[lindex $argv 0].nam";

set pod [lindex $argv 1];
set pod [expr $pod];
set host_per_pod [lindex $argv 2];
set host_per_pod [expr $host_per_pod];

#puts "POD: $pod; HOST_PER_POD:$host_per_pod"

set packetSize 1460;
set RTT 0.0001;
set line_latency [expr $RTT];
set BUFFER 100;
set FLOW_NUM 0;
set enableNAM 0;
set enableTraceAll 0;
set ToR_lineRate 10Gb;
set corelineRate 10Gb;

set ns [new Simulator]
# multipath configuration
Node set multiPath_ 1
Classifier/MultiPath set perflow_ 1
Classifier/MultiPath set checkpathid_ 1

Agent/TCP set packetSize_ $packetSize
Agent/TCP set window_ 2000;		# advise window

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
# loop variables: p: pod, i: host
# generating hosts

for {set p 0} {$p < $pod} {incr p} {
	for {set i 0} {$i < $host_per_pod} {incr i} {
		set hosts($p,$i) [$ns node];
	}
}

# generating backgroud flow nodes
#for {set p 0} {$p < $pod} {incr p} {
#	set b_hosts($p) [$ns node]
#}

# generating ToR switches
for {set p 0} {$p < $pod} {incr p} {
	set tor_sw($p) [$ns node]
	
	$tor_sw($p) color green
	$tor_sw($p) shape box
}

# generating Core switches
for {set c 0} {$c < [expr $pod/2]} {incr c} {

	set core_sw($c) [$ns node]
	$core_sw($c) color red;
	$core_sw($c) shape box;
}


# generating links between hosts and ToR
for {set p 0} {$p < $pod} {incr p} {
		for {set i 0} {$i < $host_per_pod} {incr i} {

			$ns simplex-link $hosts($p,$i) $tor_sw($p) $ToR_lineRate [expr $line_latency] DropTail
		   	$ns simplex-link $tor_sw($p) $hosts($p,$i) $ToR_lineRate [expr $line_latency] DropTail
			
			$ns queue-limit $tor_sw($p) $hosts($p,$i) $BUFFER
			$ns duplex-link-op $hosts($p,$i) $tor_sw($p) queuePos 0.25
		}
		# link background host to ToR
#		$ns simplex-link $b_hosts($p) $tor_sw($p) $corelineRate [expr $line_latency] DropTail
#		$ns simplex-link $tor_sw($p) $b_hosts($p) $corelineRate [expr $line_latency] DropTail
#
#		$ns queue-limit $tor_sw($p) $b_hosts($p) $BUFFER
#		$ns duplex-link-op $b_hosts($p) $tor_sw($p) queuePos 0.25		
}

# generating links between ToR and Core
for {set p 0} {$p < $pod} {incr p} {
	for {set c 0} {$c < $pod/2} {incr c} {
		$ns duplex-link $tor_sw($p) $core_sw($c) $corelineRate [expr $line_latency] DropTail
		$ns queue-limit $tor_sw($p) $core_sw($c) [expr 2 * $BUFFER]
		$ns queue-limit $core_sw($c) $tor_sw($p) [expr 2 * $BUFFER]

		$ns duplex-link-op $tor_sw($p) $core_sw($c) queuePos 0.25
	}
}
#--------------------------------------------------------------

#Multipath configuration
$ns rtproto DV
Agent/rtProto/DV set advertInterval 16
