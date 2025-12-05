onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib Lab7_Top_Level_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {Lab7_Top_Level.udo}

run 1000ns

quit -force
