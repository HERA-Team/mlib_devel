
#-----------------------------------------------------------
# PCS/PMA Clock period Constraints: please do not relax    -
#-----------------------------------------------------------


  # Clock period for the Txout clock
  #create_clock  -period 16.000 [get_pins -hier -filter {name =~ *pcs_pma_block_i/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gthe2_i/TXOUTCLK}]
  create_clock  -period 16.000 [get_pins -of [get_cells -hierarchical -filter {NAME =~ *pcs_pma_block_i/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gthe2_i}] -filter {REF_PIN_NAME =~ TXOUTCLK}]
  

  #-----------------------------------------------------------
  # Receive Clock period Constraint: please do not relax
  #-----------------------------------------------------------
  # Clock period for the recovered Rx clock
  #create_clock  -period 16.000 [get_pins -hier -filter { name =~ *pcs_pma_block_i/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gthe2_i/RXOUTCLK}]
  create_clock  -period 16.000 [get_pins -of [get_cells -hierarchical -filter {NAME =~ *pcs_pma_block_i/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gthe2_i}] -filter {REF_PIN_NAME =~ RXOUTCLK}]



#set_false_path  -to [get_pins -hier -filter {name =~  *core_resets_i/pma_reset_pipe_reg*/PRE}]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *core_resets_i/pma_reset_pipe_reg*}] -filter {REF_PIN_NAME =~ PRE}]
#set_false_path  -to [get_pins -hier -filter {name =~  *core_resets_i/pma_reset_pipe*[0]/D}]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *core_resets_i/pma_reset_pipe*[0]}] -filter {REF_PIN_NAME =~ D}]


#***********************************************************
# The following constraints target the Transceiver Physical*
# Interface which is instantiated in the Example Design.   *
#***********************************************************


#-----------------------------------------------------------
# PCS/PMA Clock period Constraints: please do not relax    -
#-----------------------------------------------------------





# Control Gray Code delay and skew across clock boundary
#set_max_delay -from [get_cells -hier -filter {name =~ *pcs_pma_block_i/transceiver_inst/rx_elastic_buffer_inst/wr_addr_*_reg[*]}] -to [get_pins -hier -filter { name =~ *reclock_wr_addrgray[*].sync_wr_addrgray/data_sync*/D}] 16 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *pcs_pma_block_i/transceiver_inst/rx_elastic_buffer_inst/wr_addr_*_reg[*]}] -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *reclock_wr_addrgray[*].sync_wr_addrgray/data_sync*}] -filter {REF_PIN_NAME =~ D}] 16 -datapath_only
#set_max_delay -from [get_cells -hier -filter {name =~  *pcs_pma_block_i/transceiver_inst/rx_elastic_buffer_inst/rd_addr_*_reg[*]}] -to [get_pins -hier -filter { name =~ *reclock_rd_addrgray[*].sync_rd_addrgray/data_sync*/D}] 8 -datapath_only
set_max_delay -from [get_cells -hier -filter {name =~ *pcs_pma_block_i/transceiver_inst/rx_elastic_buffer_inst/rd_addr_*_reg[*]}] -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *reclock_rd_addrgray[*].sync_rd_addrgray/data_sync*}] -filter {REF_PIN_NAME =~ D}] 8 -datapath_only

# Constrain between Distributed Memory (output data) and the 1st set of flip-flops
#set_false_path  -from [get_clocks -of [get_pins -hier -filter { name =~ *pcs_pma_block_i/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gt*e2_i/RXOUTCLK}]] -to [get_pins -hierarchical -filter { name =~ *rx_elastic_buffer_inst/rd_data_reg*/D } ]
set_false_path  -from [get_clocks -of [get_pins -of [get_cells -hierarchical -filter {NAME =~ *pcs_pma_block_i/transceiver_inst/gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gt*e2_i}] -filter {REF_PIN_NAME =~ RXOUTCLK}]] -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *rx_elastic_buffer_inst/rd_data_reg*}] -filter {REF_PIN_NAME =~ D}]
#set_false_path  -from [get_pins -hierarchical -filter { name =~  *transceiver_inst/rx_elastic_buffer_inst/initialize_ram_complete_reg/C}] -to [get_pins -hierarchical -filter { name =~ *rx_elastic_buffer_inst/sync_initialize_ram_comp/data_sync_reg*/D } ]
set_false_path  -from [get_pins -of [get_cells -hierarchical -filter {NAME =~ *transceiver_inst/rx_elastic_buffer_inst/initialize_ram_complete_reg}] -filter {REF_PIN_NAME =~ C}] -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *rx_elastic_buffer_inst/sync_initialize_ram_comp/data_sync_reg*}] -filter {REF_PIN_NAME =~ D}]


#-----------------------------------------------------------
# GT Initialization circuitry clock domain crossing
#-----------------------------------------------------------

#set_false_path -to [get_pins -hier -filter { name =~ */gtwizard_inst/*/gt0_txresetfsm_i/sync_*/*D } ]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *gtwizard_inst/*/gt0_txresetfsm_i/sync_*}] -filter {REF_PIN_NAME =~ *D}]
#set_false_path -to [get_pins -hier -filter { name =~ */gtwizard_inst/*/gt0_rxresetfsm_i/sync_*/*D } ]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *gtwizard_inst/*/gt0_rxresetfsm_i/sync_*}] -filter {REF_PIN_NAME =~ *D}]

#set_false_path -to [get_pins -hier -filter { name =~ */gtwizard_inst/*/sync_*/*D } ]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *gtwizard_inst/*/sync_*}] -filter {REF_PIN_NAME =~ *D}]

##set_false_path -to [get_pins -hier -filter { name =~ */gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gtrxreset_seq_i/sync_*/*D } ]
#set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *gtwizard_inst/*/gtwizard_i/gt0_GTWIZARD_i/gtrxreset_seq_i/sync_*}] -filter {REF_PIN_NAME =~ *D}]



# false path constraints to async inputs coming directly to synchronizer
#set_false_path -to [get_pins -hier -filter {name =~ *SYNC_*/data_sync*/D }]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *SYNC_*/data_sync*}] -filter {REF_PIN_NAME =~ D}]
#set_false_path -to [get_pins -hier -filter {name =~ *pcs_pma_block_i/transceiver_inst/sync_block_data_valid/data_sync*/D }]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *pcs_pma_block_i/transceiver_inst/sync_block_data_valid/data_sync*}] -filter {REF_PIN_NAME =~ D}]
#set_false_path -to [get_pins -hier -filter {name =~ *sync_block_tx_reset_done/data_sync*/D }]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *sync_block_tx_reset_done/data_sync*}] -filter {REF_PIN_NAME =~ D}]
#set_false_path -to [get_pins -hier -filter {name =~ *sync_block_rx_reset_done/data_sync*/D }]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *sync_block_rx_reset_done/data_sync*}] -filter {REF_PIN_NAME =~ D}]

#set_false_path -to [get_pins -hier -filter {name =~ */*sync_speed_10*/data_sync*/D }]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ */*sync_speed_10*/data_sync*}] -filter {REF_PIN_NAME =~ D}]
#set_false_path -to [get_pins -hier -filter {name =~ */*gen_sync_reset/reset_sync*/PRE }]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ */*gen_sync_reset/reset_sync*}] -filter {REF_PIN_NAME =~ PRE}]


#set_false_path -to [get_pins -hier -filter {name =~ *reset_sync*/PRE }]
set_false_path -to [get_pins -of [get_cells -hierarchical -filter {NAME =~ *reset_sync*}] -filter {REF_PIN_NAME =~ PRE}]


