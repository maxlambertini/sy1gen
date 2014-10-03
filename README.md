sy1gen
======

Synth1 Patch Generator

This is current release's usage:

	-- directory, -d : sets up output directory. Default: current directory
	-- percentage, p : it's a float value between 0.0 and 1.0. Default is 0.5.
			   It represents random deviation from param's current value.
			   Ignored when -f or --full random are specified
	-- genetic, -g   : if specified, sets up 'genetic': the new value
			   of patch becomes its new default, so when generating new
			   patches the default is used as a reference. Ignored when
			   fullrandom is specified
	--impact, -i     : an integer that defines the number of parameter that must
			   be modified. Useful to trigger partial modifications. When
			   used with --genetic and a low --percentage (say 0.2) can
			   create "morphing" patchsets.
	--fullrandom, -f : create a fully randomized patchset
	--textFile, -t   : 0=windows, 1= linux. Default 0
	--help, -h       : shows this help

