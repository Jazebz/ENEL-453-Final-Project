transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+Lab7_Top_Level  -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.Lab7_Top_Level xil_defaultlib.glbl

do {Lab7_Top_Level.udo}

run 1000ns

endsim

quit -force
