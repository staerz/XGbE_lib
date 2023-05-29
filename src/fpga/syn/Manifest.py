# This BSP is enabled by G_BSP_NONE:
# - it selects no device
# - it doesn't define any pin constraints, i.e. runs on no particular hardware
# - it does suppress any complaints on unassigned pins

from hdlmake.util import PyStr

# Compilation tool
syn_tool = 'quartus'
syn_tool_version = 'auto'

if action == 'simulation':
# Default simulation tool:
  sim_tool = 'modelsim'
  g_vcom_opt = '-2008 +cover=bcefs'
  g_vsim_opt = '-voptargs=+acc -multisource_delay latest -t ps +typdelays -coverage'
