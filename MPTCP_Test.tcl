set PATH 2;
set N $PATH;
set B 100;
set K 65;
set RTT 0.0001;

set MINRTT 0;
set RR 1;

set simulationTime 1.0;

set inputRate 2Gb
set lineRate 1.0Gb
set bnkRate 0.1Gb
set packetSize 1460

set FLOW_SIZE [expr 150*1460]; #5*1024*1460

set traceSamplingInterval 0.0001
set throughputSamplingInterval 0.01
set enableNAM 1;
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
Classifier/MultiPath set perflow_ 1
Classifier/MultiPath set checkpathid_ 1

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

set sndr [$ns node]
$sndr color blue
set rcvr [$ns node]
$rcvr color blue

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
$ns simplex-link $s_tor $n(0) $lineRate [expr $RTT/8] DropTail;
$ns simplex-link $n(0) $s_tor $lineRate [expr $RTT/8] DropTail;

$ns simplex-link $n(0) $r_tor $lineRate [expr $RTT/8] DropTail;
$ns simplex-link $r_tor $n(0) $lineRate [expr $RTT/8] DropTail;

$ns queue-limit $s_tor $n(0) $B;
$ns queue-limit $n(0) $s_tor $B;
$ns queue-limit $n(0) $r_tor $B;
$ns queue-limit $r_tor $n(0) $B;

$ns duplex-link-op $s_tor $n(0) queuePos 0.25;
$ns duplex-link-op $n(0) $r_tor queuePos 0.25;

#--------another path----------
$ns simplex-link $s_tor $n(1) $lineRate [expr $RTT/8] DropTail;	#[expr 2*$RTT]
$ns simplex-link $n(1) $s_tor $lineRate [expr $RTT/8] DropTail;

$ns simplex-link $n(1) $r_tor $lineRate [expr $RTT/8] DropTail;	#[expr 2*$RTT]
$ns simplex-link $r_tor $n(1) $lineRate [expr $RTT/8] DropTail;

$ns queue-limit $s_tor $n(1) $B;
$ns queue-limit $n(1) $s_tor $B;
$ns queue-limit $n(1) $r_tor $B;
$ns queue-limit $r_tor $n(1) $B;

$ns duplex-link-op $s_tor $n(1) queuePos 0.25;
$ns duplex-link-op $n(1) $r_tor queuePos 0.25;
#--------path set--------

$ns simplex-link $sndr $s_tor $inputRate [expr $RTT/8] DropTail;
$ns simplex-link $s_tor $sndr $inputRate [expr $RTT/8] DropTail;
$ns queue-limit $sndr $s_tor $B;
$ns queue-limit $s_tor $sndr $B;
$ns duplex-link-op $sndr $s_tor queuePos 0.25;

$ns simplex-link $rcvr $r_tor $inputRate [expr $RTT/8] DropTail;
$ns simplex-link $r_tor $rcvr $inputRate [expr $RTT/8] DropTail;
$ns queue-limit $rcvr $r_tor $B;
$ns queue-limit $r_tor $rcvr $B;
$ns duplex-link-op $rcvr $r_tor queuePos 0.25;

#Multipath configuration
$ns rtproto DV
Agent/rtProto/DV set advertInterval 16

set mptcp [new Mptcp];
$mptcp set-id 1;
$mptcp max_tcp_num_ $N;
$mptcp scheduler_ $MINRTT;
$mptcp length_ 10;

for {set i 0} {$i < $N} {incr i} {

	set tcp($i) [new Agent/TCP/Newreno];
	set sink($i) [new Agent/TCPSink];
	
	$ns attach-agent $sndr $tcp($i);
	$ns attach-agent $rcvr $sink($i);

	$ns connect $tcp($i) $sink($i);
	$mptcp attach-tcp $tcp($i);
}

$ns at 0.01 "$mptcp send $FLOW_SIZE";

#$ns at 0.07 "$ns simplex-link $s_tor $n(0) $bnkRate [expr $RTT] DropTail"
#$ns at 0.07 "$ns simplex-link $s_tor $n(1) $lineRate [expr $RTT/8] DropTail"

set ru [new RandomVariable/Uniform]
$ru set min_ 0
$ru set max_ 1.0

$ns at $simulationTime "finish"

$ns run

