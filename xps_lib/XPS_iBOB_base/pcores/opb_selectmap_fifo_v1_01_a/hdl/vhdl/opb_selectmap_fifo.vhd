------------------------------------------------------------------------------
-- opb_selectmap_fifo.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2005 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ** YOU MAY COPY AND MODIFY THESE FILES FOR YOUR OWN INTERNAL USE SOLELY  **
-- ** WITH XILINX PROGRAMMABLE LOGIC DEVICES AND XILINX EDK SYSTEM OR       **
-- ** CREATE IP MODULES SOLELY FOR XILINX PROGRAMMABLE LOGIC DEVICES AND    **
-- ** XILINX EDK SYSTEM. NO RIGHTS ARE GRANTED TO DISTRIBUTE ANY FILES      **
-- ** UNLESS THEY ARE DISTRIBUTED IN XILINX PROGRAMMABLE LOGIC DEVICES.     **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          opb_selectmap_fifo.vhd
-- Version:           1.00.a
-- Description:       Top level design, instantiates IPIF and user logic.
-- Date:              Tue Nov  8 14:11:03 2005 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;
use proc_common_v2_00_a.ipif_pkg.all;
library opb_ipif_v3_01_a;
use opb_ipif_v3_01_a.all;

library opb_selectmap_fifo_v1_01_a;
use opb_selectmap_fifo_v1_01_a.all;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_BASEADDR                   -- User logic base address
--   C_HIGHADDR                   -- User logic high address
--   C_OPB_AWIDTH                 -- OPB address bus width
--   C_OPB_DWIDTH                 -- OPB data bus width
--   C_FAMILY                     -- Target FPGA architecture
--
-- Definition of Ports:
--   OPB_Clk                      -- OPB Clock
--   OPB_Rst                      -- OPB Reset
--   Sl_DBus                      -- Slave data bus
--   Sl_errAck                    -- Slave error acknowledge
--   Sl_retry                     -- Slave retry
--   Sl_toutSup                   -- Slave timeout suppress
--   Sl_xferAck                   -- Slave transfer acknowledge
--   OPB_ABus                     -- OPB address bus
--   OPB_BE                       -- OPB byte enable
--   OPB_DBus                     -- OPB data bus
--   OPB_RNW                      -- OPB read/not write
--   OPB_select                   -- OPB select
--   OPB_seqAddr                  -- OPB sequential address
--   IP2INTC_Irpt                 -- Interrupt output to processor
------------------------------------------------------------------------------

entity opb_selectmap_fifo is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    C_INTR_THRESH                  : integer              := 0;
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_BASEADDR                     : std_logic_vector     := X"00000000";
    C_HIGHADDR                     : std_logic_vector     := X"0000FFFF";
    C_OPB_AWIDTH                   : integer              := 32;
    C_OPB_DWIDTH                   : integer              := 32;
    C_FAMILY                       : string               := "virtex2p"
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    D_I                            : in    std_logic_vector(0 to 7);
    D_O                            : out   std_logic_vector(0 to 7);
    D_T                            : out   std_logic_vector(0 to 7);
    RDWR_B                         : in    std_logic;
    CS_B                           : in    std_logic;
    INIT_B                         : out   std_logic;
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    OPB_Clk                        : in  std_logic;
    OPB_Rst                        : in  std_logic;
    Sl_DBus                        : out std_logic_vector(0 to C_OPB_DWIDTH-1);
    Sl_errAck                      : out std_logic;
    Sl_retry                       : out std_logic;
    Sl_toutSup                     : out std_logic;
    Sl_xferAck                     : out std_logic;
    OPB_ABus                       : in  std_logic_vector(0 to C_OPB_AWIDTH-1);
    OPB_BE                         : in  std_logic_vector(0 to C_OPB_DWIDTH/8-1);
    OPB_DBus                       : in  std_logic_vector(0 to C_OPB_DWIDTH-1);
    OPB_RNW                        : in  std_logic;
    OPB_select                     : in  std_logic;
    OPB_seqAddr                    : in  std_logic;
    IP2INTC_Irpt                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute SIGIS : string;
  attribute SIGIS of OPB_Clk       : signal is "Clk";
  attribute SIGIS of OPB_Rst       : signal is "Rst";
  attribute SIGIS of IP2INTC_Irpt  : signal is "INTR_LEVEL_HIGH";

end entity opb_selectmap_fifo;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of opb_selectmap_fifo is

  ------------------------------------------
  -- Constant: array of address range identifiers
  ------------------------------------------
  constant ARD_ID_ARRAY                   : INTEGER_ARRAY_TYPE   := 
    (
      0  => USER_00,                          -- user logic S/W register address space
      1  => IPIF_INTR                         -- include IPIF Interrupt service
    );

  ------------------------------------------
  -- Constant: array of address pairs for each address range
  ------------------------------------------
  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 64-C_OPB_AWIDTH-1) := (others => '0');

  constant USER_BASEADDR                  : std_logic_vector     := C_BASEADDR or X"00000000";
  constant USER_HIGHADDR                  : std_logic_vector     := C_BASEADDR or X"000000FF";

  constant INTR_BASEADDR                  : std_logic_vector     := C_BASEADDR or X"00000100";
  constant INTR_HIGHADDR                  : std_logic_vector     := C_BASEADDR or X"000001FF";

  constant ARD_ADDR_RANGE_ARRAY           : SLV64_ARRAY_TYPE     := 
    (
      ZERO_ADDR_PAD & USER_BASEADDR,              -- user logic base address
      ZERO_ADDR_PAD & USER_HIGHADDR,              -- user logic high address
      ZERO_ADDR_PAD & INTR_BASEADDR,              -- interrupt register base address
      ZERO_ADDR_PAD & INTR_HIGHADDR               -- interrupt register high address
    );

  ------------------------------------------
  -- Constant: array of data widths for each target address range
  ------------------------------------------
  constant USER_DWIDTH                    : integer              := 32;

  constant ARD_DWIDTH_ARRAY               : INTEGER_ARRAY_TYPE   := 
    (
      0  => USER_DWIDTH,                      -- user logic data width
      1  => C_OPB_DWIDTH                      -- interrupt register data width
    );

  ------------------------------------------
  -- Constant: array of desired number of chip enables for each address range
  ------------------------------------------
  constant USER_NUM_CE                    : integer              := 2;

  constant ARD_NUM_CE_ARRAY               : INTEGER_ARRAY_TYPE   := 
    (
      0  => pad_power2(USER_NUM_CE),          -- user logic number of CEs
      1  => 16                                -- interrupt register - 16 CEs
    );

  ------------------------------------------
  -- Constant: array of unique properties for each address range
  ------------------------------------------
  constant USER_INCLUDE_DEV_ISC           : boolean              := false;

  constant USER_INCLUDE_DEV_PENCODER      : boolean              := false;

  constant ARD_DEPENDENT_PROPS_ARRAY      : DEPENDENT_PROPS_ARRAY_TYPE := 
    (
      0  => (others => 0),                    -- user logic slave space dependent properties (none defined)
      1  => (                                 -- IPIF interrupt dependent properties
        EXCLUDE_DEV_ISC      => 1-boolean'pos(USER_INCLUDE_DEV_ISC),
        INCLUDE_DEV_PENCODER => boolean'pos(USER_INCLUDE_DEV_PENCODER),
        others => 0) 
    );

  ------------------------------------------
  -- Constant: pipeline mode
  -- 1 = include OPB-In pipeline registers
  -- 2 = include IP pipeline registers
  -- 3 = include OPB-In and IP pipeline registers
  -- 4 = include OPB-Out pipeline registers
  -- 5 = include OPB-In and OPB-Out pipeline registers
  -- 6 = include IP and OPB-Out pipeline registers
  -- 7 = include OPB-In, IP, and OPB-Out pipeline registers
  -- Note:
  -- only mode 4, 5, 7 are supported for this release
  ------------------------------------------
  constant PIPELINE_MODEL                 : integer              := 5;

  ------------------------------------------
  -- Constant: user core ID code
  ------------------------------------------
  constant DEV_BLK_ID                     : integer              := 0;

  ------------------------------------------
  -- Constant: enable MIR/Reset register
  ------------------------------------------
  constant DEV_MIR_ENABLE                 : integer              := 0;

  ------------------------------------------
  -- Constant: array of IP interrupt mode
  -- 1 = Active-high interrupt condition
  -- 2 = Active-low interrupt condition
  -- 3 = Active-high pulse interrupt event
  -- 4 = Active-low pulse interrupt event
  -- 5 = Positive-edge interrupt event
  -- 6 = Negative-edge interrupt event
  ------------------------------------------
  constant USER_IP_INTR_NUM               : integer              := 1;

  constant IP_INTR_MODE_ARRAY             : INTEGER_ARRAY_TYPE   := 
    (
      0  => 1 
    );

  ------------------------------------------
  -- Constant: enable device burst
  ------------------------------------------
  constant DEV_BURST_ENABLE               : integer              := 0;

  ------------------------------------------
  -- Constant: include address counter for burst transfers
  ------------------------------------------
  constant INCLUDE_ADDR_CNTR              : integer              := 0;

  ------------------------------------------
  -- Constant: include write buffer that decouples OPB and IPIC write transactions
  ------------------------------------------
  constant INCLUDE_WR_BUF                 : integer              := 0;

  ------------------------------------------
  -- Constant: index for CS/CE
  ------------------------------------------
  constant USER00_CS_INDEX                : integer              := get_id_index(ARD_ID_ARRAY, USER_00);

  constant USER00_CE_INDEX                : integer              := calc_start_ce_index(ARD_NUM_CE_ARRAY, USER00_CS_INDEX);

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations -- do not delete
  -- prefix 'i' stands for IPIF while prefix 'u' stands for user logic
  -- typically user logic will be hooked up to IPIF directly via i<sig>
  -- unless signal slicing and muxing are needed via u<sig>
  ------------------------------------------
  signal iBus2IP_RdCE                   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
  signal iBus2IP_WrCE                   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
  signal iBus2IP_Data                   : std_logic_vector(0 to C_OPB_DWIDTH-1);
  signal iBus2IP_BE                     : std_logic_vector(0 to C_OPB_DWIDTH/8-1);
  signal iIP2Bus_Data                   : std_logic_vector(0 to C_OPB_DWIDTH-1)   := (others => '0');
  signal iIP2Bus_Ack                    : std_logic   := '0';
  signal iIP2Bus_Error                  : std_logic   := '0';
  signal iIP2Bus_Retry                  : std_logic   := '0';
  signal iIP2Bus_ToutSup                : std_logic   := '0';
  signal iIP2Bus_PostedWrInh            : std_logic_vector(0 to ARD_ID_ARRAY'length-1)   := (others => '0');
  signal ZERO_IP2RFIFO_Data             : std_logic_vector(0 to ARD_DWIDTH_ARRAY(get_id_index_iboe(ARD_ID_ARRAY, IPIF_RDFIFO_DATA))-1)   := (others => '0'); -- work around for XST not taking (others => '0') in port mapping
  signal ZERO_WFIFO2IP_Data             : std_logic_vector(0 to ARD_DWIDTH_ARRAY(get_id_index_iboe(ARD_ID_ARRAY, IPIF_WRFIFO_DATA))-1)   := (others => '0'); -- work around for XST not taking (others => '0') in port mapping
  signal iIP2Bus_IntrEvent              : std_logic_vector(0 to IP_INTR_MODE_ARRAY'length-1)   := (others => '0');
  signal iBus2IP_Clk                    : std_logic;
  signal iBus2IP_Reset                  : std_logic;
  signal uBus2IP_Data                   : std_logic_vector(0 to USER_DWIDTH-1);
  signal uBus2IP_BE                     : std_logic_vector(0 to USER_DWIDTH/8-1);
  signal uBus2IP_RdCE                   : std_logic_vector(0 to USER_NUM_CE-1);
  signal uBus2IP_WrCE                   : std_logic_vector(0 to USER_NUM_CE-1);
  signal uIP2Bus_Data                   : std_logic_vector(0 to USER_DWIDTH-1);
  signal uIP2Bus_PostedWrInh            : std_logic;

  ------------------------------------------
  -- Component declaration for verilog user logic
  ------------------------------------------
  component user_logic is
    generic
    (
      -- ADD USER GENERICS BELOW THIS LINE ---------------
      C_INTR_THRESH                  : integer              := 0;
      -- ADD USER GENERICS ABOVE THIS LINE ---------------

      -- DO NOT EDIT BELOW THIS LINE ---------------------
      -- Bus protocol parameters, do not add to or delete
      C_DWIDTH                       : integer              := 32;
      C_NUM_CE                       : integer              := 2;
      C_IP_INTR_NUM                  : integer              := 1
      -- DO NOT EDIT ABOVE THIS LINE ---------------------
    );
    port
    (
      -- ADD USER PORTS BELOW THIS LINE ------------------
      D_I                            : in    std_logic_vector(0 to 7);
      D_O                            : out   std_logic_vector(0 to 7);
      D_T                            : out   std_logic_vector(0 to 7);
      RDWR_B                         : in    std_logic;
      CS_B                           : in    std_logic;
      INIT_B                         : out   std_logic;
      -- ADD USER PORTS ABOVE THIS LINE ------------------

      -- DO NOT EDIT BELOW THIS LINE ---------------------
      -- Bus protocol ports, do not add to or delete
      Bus2IP_Clk                     : in  std_logic;
      Bus2IP_Reset                   : in  std_logic;
      IP2Bus_IntrEvent               : out std_logic_vector(0 to C_IP_INTR_NUM-1);
      Bus2IP_Data                    : in  std_logic_vector(0 to C_DWIDTH-1);
      Bus2IP_BE                      : in  std_logic_vector(0 to C_DWIDTH/8-1);
      Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_CE-1);
      Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_CE-1);
      IP2Bus_Data                    : out std_logic_vector(0 to C_DWIDTH-1);
      IP2Bus_Ack                     : out std_logic;
      IP2Bus_Retry                   : out std_logic;
      IP2Bus_Error                   : out std_logic;
      IP2Bus_ToutSup                 : out std_logic;
      IP2Bus_PostedWrInh             : out std_logic
      -- DO NOT EDIT ABOVE THIS LINE ---------------------
    );
  end component user_logic;

begin

  ------------------------------------------
  -- instantiate the OPB IPIF
  ------------------------------------------
  OPB_IPIF_I : entity opb_ipif_v3_01_a.opb_ipif
    generic map
    (
      C_ARD_ID_ARRAY                 => ARD_ID_ARRAY,
      C_ARD_ADDR_RANGE_ARRAY         => ARD_ADDR_RANGE_ARRAY,
      C_ARD_DWIDTH_ARRAY             => ARD_DWIDTH_ARRAY,
      C_ARD_NUM_CE_ARRAY             => ARD_NUM_CE_ARRAY,
      C_ARD_DEPENDENT_PROPS_ARRAY    => ARD_DEPENDENT_PROPS_ARRAY,
      C_PIPELINE_MODEL               => PIPELINE_MODEL,
      C_DEV_BLK_ID                   => DEV_BLK_ID,
      C_DEV_MIR_ENABLE               => DEV_MIR_ENABLE,
      C_OPB_AWIDTH                   => C_OPB_AWIDTH,
      C_OPB_DWIDTH                   => C_OPB_DWIDTH,
      C_FAMILY                       => C_FAMILY,
      C_IP_INTR_MODE_ARRAY           => IP_INTR_MODE_ARRAY,
      C_DEV_BURST_ENABLE             => DEV_BURST_ENABLE,
      C_INCLUDE_ADDR_CNTR            => INCLUDE_ADDR_CNTR,
      C_INCLUDE_WR_BUF               => INCLUDE_WR_BUF
    )
    port map
    (
      OPB_select                     => OPB_select,
      OPB_DBus                       => OPB_DBus,
      OPB_ABus                       => OPB_ABus,
      OPB_BE                         => OPB_BE,
      OPB_RNW                        => OPB_RNW,
      OPB_seqAddr                    => OPB_seqAddr,
      Sln_DBus                       => Sl_DBus,
      Sln_xferAck                    => Sl_xferAck,
      Sln_errAck                     => Sl_errAck,
      Sln_retry                      => Sl_retry,
      Sln_toutSup                    => Sl_toutSup,
      Bus2IP_CS                      => open,
      Bus2IP_CE                      => open,
      Bus2IP_RdCE                    => iBus2IP_RdCE,
      Bus2IP_WrCE                    => iBus2IP_WrCE,
      Bus2IP_Data                    => iBus2IP_Data,
      Bus2IP_Addr                    => open,
      Bus2IP_AddrValid               => open,
      Bus2IP_BE                      => iBus2IP_BE,
      Bus2IP_RNW                     => open,
      Bus2IP_Burst                   => open,
      IP2Bus_Data                    => iIP2Bus_Data,
      IP2Bus_Ack                     => iIP2Bus_Ack,
      IP2Bus_AddrAck                 => '0',
      IP2Bus_Error                   => iIP2Bus_Error,
      IP2Bus_Retry                   => iIP2Bus_Retry,
      IP2Bus_ToutSup                 => iIP2Bus_ToutSup,
      IP2Bus_PostedWrInh             => iIP2Bus_PostedWrInh,
      IP2RFIFO_Data                  => ZERO_IP2RFIFO_Data,
      IP2RFIFO_WrMark                => '0',
      IP2RFIFO_WrRelease             => '0',
      IP2RFIFO_WrReq                 => '0',
      IP2RFIFO_WrRestore             => '0',
      RFIFO2IP_AlmostFull            => open,
      RFIFO2IP_Full                  => open,
      RFIFO2IP_Vacancy               => open,
      RFIFO2IP_WrAck                 => open,
      IP2WFIFO_RdMark                => '0',
      IP2WFIFO_RdRelease             => '0',
      IP2WFIFO_RdReq                 => '0',
      IP2WFIFO_RdRestore             => '0',
      WFIFO2IP_AlmostEmpty           => open,
      WFIFO2IP_Data                  => ZERO_WFIFO2IP_Data,
      WFIFO2IP_Empty                 => open,
      WFIFO2IP_Occupancy             => open,
      WFIFO2IP_RdAck                 => open,
      IP2Bus_IntrEvent               => iIP2Bus_IntrEvent,
      IP2INTC_Irpt                   => IP2INTC_Irpt,
      Freeze                         => '0',
      Bus2IP_Freeze                  => open,
      OPB_Clk                        => OPB_Clk,
      Bus2IP_Clk                     => iBus2IP_Clk,
      IP2Bus_Clk                     => '0',
      Reset                          => OPB_Rst,
      Bus2IP_Reset                   => iBus2IP_Reset
    );

  ------------------------------------------
  -- instantiate the User Logic
  ------------------------------------------
  USER_LOGIC_I : component user_logic
    generic map
    (
      -- MAP USER GENERICS BELOW THIS LINE ---------------
      C_INTR_THRESH                  => C_INTR_THRESH,
      -- MAP USER GENERICS ABOVE THIS LINE ---------------

      C_DWIDTH                       => USER_DWIDTH,
      C_NUM_CE                       => USER_NUM_CE,
      C_IP_INTR_NUM                  => USER_IP_INTR_NUM
    )
    port map
    (
      -- MAP USER PORTS BELOW THIS LINE ------------------
      D_I                            => D_I,
      D_O                            => D_O,
      D_T                            => D_T,            
      RDWR_B                         => RDWR_B,
      CS_B                           => CS_B,
      INIT_B                         => INIT_B,
      -- MAP USER PORTS ABOVE THIS LINE ------------------

      Bus2IP_Clk                     => iBus2IP_Clk,
      Bus2IP_Reset                   => iBus2IP_Reset,
      IP2Bus_IntrEvent               => iIP2Bus_IntrEvent,
      Bus2IP_Data                    => uBus2IP_Data,
      Bus2IP_BE                      => uBus2IP_BE,
      Bus2IP_RdCE                    => uBus2IP_RdCE,
      Bus2IP_WrCE                    => uBus2IP_WrCE,
      IP2Bus_Data                    => uIP2Bus_Data,
      IP2Bus_Ack                     => iIP2Bus_Ack,
      IP2Bus_Retry                   => iIP2Bus_Retry,
      IP2Bus_Error                   => iIP2Bus_Error,
      IP2Bus_ToutSup                 => iIP2Bus_ToutSup,
      IP2Bus_PostedWrInh             => uIP2Bus_PostedWrInh
    );

  ------------------------------------------
  -- hooking up signal slicing
  ------------------------------------------
  uBus2IP_BE <= iBus2IP_BE(0 to USER_DWIDTH/8-1);
  uBus2IP_Data <= iBus2IP_Data(0 to USER_DWIDTH-1);
  uBus2IP_RdCE <= iBus2IP_RdCE(USER00_CE_INDEX to USER00_CE_INDEX+USER_NUM_CE-1);
  uBus2IP_WrCE <= iBus2IP_WrCE(USER00_CE_INDEX to USER00_CE_INDEX+USER_NUM_CE-1);
  iIP2Bus_PostedWrInh <= (others => uIP2Bus_PostedWrInh);
  iIP2Bus_Data(0 to USER_DWIDTH-1) <= uIP2Bus_Data;

end IMP;
