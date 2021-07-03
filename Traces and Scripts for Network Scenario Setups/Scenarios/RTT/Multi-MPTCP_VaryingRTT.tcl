if { $argc != 4 } {
	puts "Usage: ./ns <tcl-script> <#pod> <#host per pod>"
	puts "E.g.: ./ns fatdc.tcl 04 04"
	exit 1
}

set pod [lindex $argv 0];
set pod [expr $pod];
set host_per_pod [lindex $argv 1];
set host_per_pod [expr $host_per_pod];
set NUM_FLOWS [lindex $argv 2];
set NUM_FLOWS [expr $NUM_FLOWS];

set RTT_Ratio [lindex $argv 3];
set RTT_Ratio [expr $RTT_Ratio];

set PATH [expr $pod*$pod/2];

set NUM_SUB 2;
set MINRTT 0;
set RR 1;
set R_WIN 42;
set SCHED $MINRTT;	# set up one scheduler for MPTCP, mptcp by default

#set N [lindex $argv 0];
set N [expr $pod*$host_per_pod];
set B 100;
set K 65;
set RTT 0.0001;

set simulationTime 2.0;

set inputRate 1.0Gb
set lineRate 1.0Gb
set bnkRate 0.1Gb
set packetSize 1460

set NUM_PKTS 150; #5*1024*1460

set traceSamplingInterval 0.0001
set throughputSamplingInterval 0.01
set enableNAM 0;
set enableTraceAll 0;


set trace_all_name "./traceall.ta"
set nam_file_name "./mptcp.nam"

set ackRatio 1

set ns [new Simulator]

Agent/TCP set ecn_ 1
Agent/TCP set old_ecn_ 1
Agent/TCP set packetSize_ $packetSize
Agent/TCP/FullTcp set segsize_ $packetSize
Agent/TCP set window_ 1256
Agent/TCP set slow_start_restart_ false
Agent/TCP set tcpTick_ 0.01
Agent/TCP set minrto_ 0.2 ; # minRTO = 200ms
Agent/TCP set windowOption_ 0

Agent/TCP/FullTcp set segsperack_ $ackRatio;
Agent/TCP/FullTcp set spa_thresh_ 3000;
Agent/TCP/FullTcp set interval_ 0.04 ; #delayed ACK interval = 40ms

Queue set limit_ 1000
#DelayLink set avoidReordering_ true

# multipath configuration
Node set multiPath_ 1
#Classifier/MultiPath set perflow_ 1
#Classifier/MultiPath set checkpathid_ 1

if {$enableTraceAll != 0} {
	set traceall [open $trace_all_name w];
	$ns trace-all $traceall;
}

if {$enableNAM != 0} {
	set namfile [open $nam_file_name w];
	$ns namtrace-all $namfile;
}

proc finish {} {
	global ns traceall namfile enableTraceAll enableNAM
	$ns flush-trace
	
	if {$enableTraceAll != 0} {
		close $traceall;
	}
	
	if {$enableNAM != 0} {
		close $namfile
		#exec nam $nam_file &
	}
	exit 0
}

$ns color 0 Red
$ns color 1 Orange
$ns color 2 Yellow
$ns color 3 Green
$ns color 4 Blue
$ns color 5 Violet
$ns color 6 Brown
$ns color 7 Black

for {set i 0} {$i < $N} {incr i} {

	set sndr($i) [$ns node];
	$sndr($i) color blue;
	
	set rcvr($i) [$ns node];
	$rcvr($i) color blue;
}

set s_tor [$ns node]
$s_tor color green
set r_tor [$ns node]
$r_tor color green

for {set i 0} {$i < $PATH} {incr i} {

	set n($i) [$ns node];
	$n($i) color red
	$n($i) shape box
}


#for {set i 0} {$i < $PATH} {incr i} {
#
#	$ns simplex-link $s_tor $n($i) $lineRate [expr $RTT/8] DropTail;
#	$ns simplex-link $n($i) $s_tor $lineRate [expr $RTT/8] DropTail;
#	
#	$ns simplex-link $n($i) $r_tor $lineRate [expr $RTT/8] DropTail;
#	$ns simplex-link $r_tor $n($i) $lineRate [expr $RTT/8] DropTail;
#	
#	$ns queue-limit $s_tor $n($i) $B;
#	$ns queue-limit $n($i) $s_tor $B;
#	$ns queue-limit $n($i) $r_tor $B;
#	$ns queue-limit $r_tor $n($i) $B;
#
#	$ns duplex-link-op $s_tor $n($i) queuePos 0.25;
#	$ns duplex-link-op $n($i) $r_tor queuePos 0.25;
#}

#--------one path----------
#for {set i 0} {$i < [expr $PATH-1]} {incr i} {
for {set i 0} {$i < [expr $PATH-1]} {incr i} {

	$ns simplex-link $s_tor $n($i) $lineRate [expr $RTT/8] DropTail;
	$ns simplex-link $n($i) $s_tor $lineRate [expr $RTT/8] DropTail;
	
	$ns simplex-link $n($i) $r_tor $lineRate [expr $RTT/8] DropTail;
	$ns simplex-link $r_tor $n($i) $lineRate [expr $RTT/8] DropTail;
	
	$ns queue-limit $s_tor $n($i) $B;
	$ns queue-limit $n($i) $s_tor $B;
	$ns queue-limit $n($i) $r_tor $B;
	$ns queue-limit $r_tor $n($i) $B;
	
	$ns duplex-link-op $s_tor $n($i) queuePos 0.25;
	$ns duplex-link-op $n($i) $r_tor queuePos 0.25;
}

##--------special path----------
$ns simplex-link $s_tor $n([expr $PATH-1]) $lineRate [expr $RTT*$RTT_Ratio] DropTail;
$ns simplex-link $n([expr $PATH-1]) $s_tor $lineRate [expr $RTT/8] DropTail;

$ns simplex-link $n([expr $PATH-1]) $r_tor $lineRate [expr $RTT*$RTT_Ratio] DropTail;
$ns simplex-link $r_tor $n([expr $PATH-1]) $lineRate [expr $RTT/8] DropTail;

$ns queue-limit $s_tor $n([expr $PATH-1]) $B;
$ns queue-limit $n([expr $PATH-1]) $s_tor $B;
$ns queue-limit $n([expr $PATH-1]) $r_tor $B;
$ns queue-limit $r_tor $n([expr $PATH-1]) $B;

$ns duplex-link-op $s_tor $n([expr $PATH-1]) queuePos 0.25;
$ns duplex-link-op $n([expr $PATH-1]) $r_tor queuePos 0.25;
#--------path set--------

#$ns simplex-link $sndr $s_tor $inputRate [expr $RTT/8] DropTail;
#$ns simplex-link $s_tor $sndr $inputRate [expr $RTT/8] DropTail;
#$ns queue-limit $sndr $s_tor $B;
#$ns queue-limit $s_tor $sndr $B;
#$ns duplex-link-op $sndr $s_tor queuePos 0.25;
#
#$ns simplex-link $rcvr $r_tor $lineRate [expr $RTT/8] DropTail;
#$ns simplex-link $r_tor $rcvr $lineRate [expr $RTT/8] DropTail;
#$ns queue-limit $rcvr $r_tor $B;
#$ns queue-limit $r_tor $rcvr $B;
#$ns duplex-link-op $rcvr $r_tor queuePos 0.25;

for {set i 0} {$i < $N} {incr i} {

	$ns simplex-link $sndr($i) $s_tor $inputRate [expr $RTT/8] DropTail;
	$ns simplex-link $s_tor $sndr($i) $inputRate [expr $RTT/8] DropTail;
	$ns queue-limit $sndr($i) $s_tor $B;
	$ns queue-limit $s_tor $sndr($i) $B;
	$ns duplex-link-op $sndr($i) $s_tor queuePos 0.25;
	
	$ns simplex-link $rcvr($i) $r_tor $lineRate [expr $RTT/8] DropTail;
	$ns simplex-link $r_tor $rcvr($i) $lineRate [expr $RTT/8] DropTail;
	$ns queue-limit $rcvr($i) $r_tor $B;
	$ns queue-limit $r_tor $rcvr($i) $B;
	$ns duplex-link-op $rcvr($i) $r_tor queuePos 0.25;
}

#Multipath configuration
$ns rtproto DV
Agent/rtProto/DV set advertInterval 16

for {set i 0} {$i < $NUM_FLOWS} {incr i} {

	set mptcp($i) [new Mptcp];
	$mptcp($i) set-id [expr $i];
	$mptcp($i) max_tcp_num_ $NUM_SUB;	# $PATH
	$mptcp($i) scheduler_ $SCHED;
	$mptcp($i) length_ $R_WIN;
}

for {set i 0} {$i < $NUM_FLOWS} {incr i} {

	# $PATH->$NUM_SUB
	for {set j 0} {$j < $NUM_SUB} {incr j} {
		
		set cur [expr $NUM_SUB*$i+$j];	# $PATH
		#puts "#$cur"
		set tcp($cur) [new Agent/TCP/Newreno];
		set sink($cur) [new Agent/TCPSink];
		
		$ns attach-agent $sndr($i) $tcp($cur);
		$ns attach-agent $rcvr($i) $sink($cur);
		
		$ns connect $tcp($cur) $sink($cur);
		$mptcp($i) attach-tcp $tcp($cur);
	}
}

for {set i 0} {$i < $NUM_FLOWS} {incr i} {

	set FLOW_SIZE [expr $packetSize*$NUM_PKTS];
	$ns at 1.0 "$mptcp($i) send $FLOW_SIZE";
}
#$ns at 0.07 "$ns simplex-link $s_tor $n(0) $bnkRate [expr $RTT] DropTail"
#$ns at 0.07 "$ns simplex-link $s_tor $n(1) $lineRate [expr $RTT/8] DropTail"

set ru [new RandomVariable/Uniform]
$ru set min_ 0
$ru set max_ 1.0

$ns at $simulationTime "finish"

$ns run

