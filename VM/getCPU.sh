#!/bin/bash
echo $(cat <(/bin/grep 'cpu ' /proc/stat) <(sleep 0.5 && grep 'cpu ' /proc/stat) | awk -v RS= '{print (($13+$14+$15+$18+$19+$20)-($2+$3+$4+$7+$8+$9))*100/(($13+$14+$15+$16+$17+$18+$19+$20)-($2+$3+$4+$5+$6+$7+$8+$9))}')
#tail -1 "$(/bin/date +%Y%m%d)_res_util" | awk '{print $1}'
