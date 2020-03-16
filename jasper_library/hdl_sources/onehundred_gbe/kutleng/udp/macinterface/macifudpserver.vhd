--------------------------------------------------------------------------------
-- Legal & Copyright:   (c) 2018 Kutleng Engineering Technologies (Pty) Ltd    - 
--                                                                             -
-- This program is the proprietary software of Kutleng Engineering Technologies-
-- and/or its licensors, and may only be used, duplicated, modified or         -
-- distributed pursuant to the terms and conditions of a separate, written     -
-- license agreement executed between you and Kutleng (an "Authorized License")-
-- Except as set forth in an Authorized License, Kutleng grants no license     -
-- (express or implied), right to use, or waiver of any kind with respect to   -
-- the Software, and Kutleng expressly reserves all rights in and to the       -
-- Software and all intellectual property rights therein.  IF YOU HAVE NO      -
-- AUTHORIZED LICENSE, THEN YOU HAVE NO RIGHT TO USE THIS SOFTWARE IN ANY WAY, -
-- AND SHOULD IMMEDIATELY NOTIFY KUTLENG AND DISCONTINUE ALL USE OF THE        -
-- SOFTWARE.                                                                   -
--                                                                             -
-- Except as expressly set forth in the Authorized License,                    -
--                                                                             -
-- 1.     This program, including its structure, sequence and organization,    -
-- constitutes the valuable trade secrets of Kutleng, and you shall use all    -
-- reasonable efforts to protect the confidentiality thereof,and to use this   -
-- information only in connection with South African Radio Astronomy           -
-- Observatory (SARAO) products.                                               -
--                                                                             -
-- 2.     TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE SOFTWARE IS PROVIDED     -
-- "AS IS" AND WITH ALL FAULTS AND KUTLENG MAKES NO PROMISES, REPRESENTATIONS  -
-- OR WARRANTIES, EITHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, WITH       -
-- RESPECT TO THE SOFTWARE.  KUTLENG SPECIFICALLY DISCLAIMS ANY AND ALL IMPLIED-
-- WARRANTIES OF TITLE, MERCHANTABILITY, NONINFRINGEMENT, FITNESS FOR A        -
-- PARTICULAR PURPOSE, LACK OF VIRUSES, ACCURACY OR COMPLETENESS, QUIET        -
-- ENJOYMENT, QUIET POSSESSION OR CORRESPONDENCE TO DESCRIPTION. YOU ASSUME THE-
-- ENJOYMENT, QUIET POSSESSION USE OR PERFORMANCE OF THE SOFTWARE.             -
--                                                                             -
-- 3.     TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL KUTLENG OR -
-- ITS LICENSORS BE LIABLE FOR (i) CONSEQUENTIAL, INCIDENTAL, SPECIAL, INDIRECT-
-- , OR EXEMPLARY DAMAGES WHATSOEVER ARISING OUT OF OR IN ANY WAY RELATING TO  -
-- YOUR USE OF OR INABILITY TO USE THE SOFTWARE EVEN IF KUTLENG HAS BEEN       -
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGES; OR (ii) ANY AMOUNT IN EXCESS OF -
-- THE AMOUNT ACTUALLY PAID FOR THE SOFTWARE ITSELF OR ZAR R1, WHICHEVER IS    -
-- GREATER. THESE LIMITATIONS SHALL APPLY NOTWITHSTANDING ANY FAILURE OF       -
-- ESSENTIAL PURPOSE OF ANY LIMITED REMEDY.                                    -
-- --------------------------------------------------------------------------- -
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS                    -
-- PART OF THIS FILE AT ALL TIMES.                                             -
--=============================================================================-
-- Company          : Kutleng Dynamic Electronics Systems (Pty) Ltd            -
-- Engineer         : Benjamin Hector Hlophe                                   -
--                                                                             -
-- Design Name      : CASPER BSP                                               -
-- Module Name      : macifudpserver - rtl                                     -
-- Project Name     : SKARAB2                                                  -
-- Target Devices   : N/A                                                      -
-- Tool Versions    : N/A                                                      -
-- Description      : The macifudpsender module receives and send UDP/IP data  -
--                    streams, it also saves the streams on a packetringbuffer.-
--                    Also the data is fetched from a packetringbuffer.        -
--                    TODO                                                     -
--                    Improve handling and framing of UDP data,without needing -
--                    to mirror the UDP data settings.                         -
--                                                                             -
-- Dependencies     : macifudpsender,macifudpreceiver                          -
-- Revision History : V1.0 - Initial design                                    -
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity macifudpserver is
    generic(
        G_SLOT_WIDTH      : natural                          := 4;
        -- The address width is log2(2048/(512/8))=5 bits wide
        G_ADDR_WIDTH      : natural                          := 5
    );
    port(
        axis_clk                       : in  STD_LOGIC;
        axis_app_clk                   : in  STD_LOGIC;
        axis_reset                     : in  STD_LOGIC;
        -- Setup information
        ServerMACAddress               : in  STD_LOGIC_VECTOR(47 downto 0);
        ServerIPAddress                : in  STD_LOGIC_VECTOR(31 downto 0);
        ServerUDPPort                  : in  STD_LOGIC_VECTOR(15 downto 0);
        -- MAC Statistics
        RXOverFlowCount                : out STD_LOGIC_VECTOR(31 downto 0);
        RXAlmostFullCount              : out STD_LOGIC_VECTOR(31 downto 0);
    
        -- Packet Readout in addressed bus format
        RecvRingBufferSlotID           : in  STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
        RecvRingBufferSlotClear        : in  STD_LOGIC;
        RecvRingBufferSlotStatus       : out STD_LOGIC;
        RecvRingBufferSlotTypeStatus   : out STD_LOGIC;
        RecvRingBufferSlotsFilled      : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
        RecvRingBufferDataRead         : in  STD_LOGIC;
        -- Enable[0] is a special bit (we assume always 1 when packet is valid)
        -- we use it to save TLAST
        RecvRingBufferDataEnable       : out STD_LOGIC_VECTOR(63 downto 0);
        RecvRingBufferDataOut          : out STD_LOGIC_VECTOR(511 downto 0);
        RecvRingBufferAddress          : in  STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
        -- Packet Readout in addressed bus format
        SenderRingBufferSlotID         : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
        SenderRingBufferSlotClear      : out STD_LOGIC;
        SenderRingBufferSlotStatus     : in  STD_LOGIC;
        SenderRingBufferSlotTypeStatus : in  STD_LOGIC;
        SenderRingBufferSlotsFilled    : in  STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
        SenderRingBufferDataRead       : out STD_LOGIC;
        -- Enable[0] is a special bit (we assume always 1 when packet is valid)
        -- we use it to save TLAST
        SenderRingBufferDataEnable     : in  STD_LOGIC_VECTOR(63 downto 0);
        SenderRingBufferDataIn         : in  STD_LOGIC_VECTOR(511 downto 0);
        SenderRingBufferAddress        : out STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
        --Inputs from AXIS bus of the MAC side
        --Outputs to AXIS bus MAC side 
        axis_tx_tpriority              : out STD_LOGIC_VECTOR(3 downto 0);
        axis_tx_tdata                  : out STD_LOGIC_VECTOR(511 downto 0);
        axis_tx_tvalid                 : out STD_LOGIC;
        axis_tx_tready                 : in  STD_LOGIC;
        axis_tx_tkeep                  : out STD_LOGIC_VECTOR(63 downto 0);
        axis_tx_tlast                  : out STD_LOGIC;
        --Inputs from AXIS bus of the MAC side
        axis_rx_tdata                  : in  STD_LOGIC_VECTOR(511 downto 0);
        axis_rx_tvalid                 : in  STD_LOGIC;
        axis_rx_tuser                  : in  STD_LOGIC;
        axis_rx_tkeep                  : in  STD_LOGIC_VECTOR(63 downto 0);
        axis_rx_tlast                  : in  STD_LOGIC
    );
end entity macifudpserver;

architecture rtl of macifudpserver is
    component macifudpsender is
        generic(
            G_SLOT_WIDTH : natural := 4;
            --G_UDP_SERVER_PORT : natural range 0 to ((2**16) - 1) := 5;
            -- The address width is log2(2048/(512/8))=5 bits wide
            G_ADDR_WIDTH : natural := 5
        );
        port(
            axis_clk                 : in  STD_LOGIC;
            axis_reset               : in  STD_LOGIC;
            -- Setup information
            --SenderMACAddress         : in  STD_LOGIC_VECTOR(47 downto 0);
            --SenderIPAddress          : in  STD_LOGIC_VECTOR(31 downto 0);
            -- Packet Write in addressed bus format
            -- Packet Readout in addressed bus format
            RingBufferSlotID         : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            RingBufferSlotClear      : out STD_LOGIC;
            RingBufferSlotStatus     : in  STD_LOGIC;
            RingBufferSlotTypeStatus : in  STD_LOGIC;
            RingBufferSlotsFilled    : in  STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            RingBufferDataRead       : out STD_LOGIC;
            -- Enable[0] is a special bit (we assume always 1 when packet is valid)
            -- we use it to save TLAST
            RingBufferDataEnable     : in  STD_LOGIC_VECTOR(63 downto 0);
            RingBufferDataIn         : in  STD_LOGIC_VECTOR(511 downto 0);
            RingBufferAddress        : out STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
            --Inputs from AXIS bus of the MAC side
            --Outputs to AXIS bus MAC side 
            axis_tx_tpriority        : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            axis_tx_tdata            : out STD_LOGIC_VECTOR(511 downto 0);
            axis_tx_tvalid           : out STD_LOGIC;
            axis_tx_tready           : in  STD_LOGIC;
            axis_tx_tkeep            : out STD_LOGIC_VECTOR(63 downto 0);
            axis_tx_tlast            : out STD_LOGIC
        );
    end component macifudpsender;

    component macifudpreceiver is
        generic(
            G_SLOT_WIDTH      : natural                          := 4;
            -- The address width is log2(2048/(512/8))=5 bits wide
            G_ADDR_WIDTH      : natural                          := 5
        );
        port(
            axis_clk                 : in  STD_LOGIC;
            axis_app_clk             : in  STD_LOGIC;
            axis_reset               : in  STD_LOGIC;
            -- Setup information
            ReceiverMACAddress       : in  STD_LOGIC_VECTOR(47 downto 0);
            ReceiverIPAddress        : in  STD_LOGIC_VECTOR(31 downto 0);
            ReceiverUDPPort          : in  STD_LOGIC_VECTOR(15 downto 0);
            -- MAC Statistics
            RXOverFlowCount          : out STD_LOGIC_VECTOR(31 downto 0);
            RXAlmostFullCount        : out STD_LOGIC_VECTOR(31 downto 0);                  
            -- Packet Readout in addressed bus format
            RingBufferSlotID         : in  STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            RingBufferSlotClear      : in  STD_LOGIC;
            RingBufferSlotStatus     : out STD_LOGIC;
            RingBufferSlotTypeStatus : out STD_LOGIC;
            RingBufferSlotsFilled    : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            RingBufferDataRead       : in  STD_LOGIC;
            -- Enable[0] is a special bit (we assume always 1 when packet is valid)
            -- we use it to save TLAST
            RingBufferDataEnable     : out STD_LOGIC_VECTOR(63 downto 0);
            RingBufferDataOut        : out STD_LOGIC_VECTOR(511 downto 0);
            RingBufferAddress        : in  STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
            --Inputs from AXIS bus of the MAC side
            axis_rx_tdata            : in  STD_LOGIC_VECTOR(511 downto 0);
            axis_rx_tvalid           : in  STD_LOGIC;
            axis_rx_tuser            : in  STD_LOGIC;
            axis_rx_tkeep            : in  STD_LOGIC_VECTOR(63 downto 0);
            axis_rx_tlast            : in  STD_LOGIC
        );
    end component macifudpreceiver;

begin

    UDPSender_i : macifudpsender
        generic map(
            G_SLOT_WIDTH => G_SLOT_WIDTH,
            G_ADDR_WIDTH => G_ADDR_WIDTH
        )
        port map(
            axis_clk                 => axis_clk,
            axis_reset               => axis_reset,
            RingBufferSlotID         => SenderRingBufferSlotID,
            RingBufferSlotClear      => SenderRingBufferSlotClear,
            RingBufferSlotStatus     => SenderRingBufferSlotStatus,
            RingBufferSlotTypeStatus => SenderRingBufferSlotTypeStatus,
            RingBufferSlotsFilled    => SenderRingBufferSlotsFilled,
            RingBufferDataRead       => SenderRingBufferDataRead,
            RingBufferDataEnable     => SenderRingBufferDataEnable,
            RingBufferDataIn         => SenderRingBufferDataIn,
            RingBufferAddress        => SenderRingBufferAddress,
            axis_tx_tpriority        => axis_tx_tpriority,
            axis_tx_tdata            => axis_tx_tdata,
            axis_tx_tvalid           => axis_tx_tvalid,
            axis_tx_tready           => axis_tx_tready,
            axis_tx_tkeep            => axis_tx_tkeep,
            axis_tx_tlast            => axis_tx_tlast
        );

    UDPReceiver_i : macifudpreceiver
        generic map(
            G_SLOT_WIDTH      => G_SLOT_WIDTH,
            G_ADDR_WIDTH      => G_ADDR_WIDTH
        )
        port map(
            axis_clk                 => axis_clk,
            axis_app_clk             => axis_app_clk,
            axis_reset               => axis_reset,
            ReceiverMACAddress       => ServerMACAddress,
            ReceiverIPAddress        => ServerIPAddress,
            ReceiverUDPPort          => ServerUDPPort,
            RXOverFlowCount          => RXOverFlowCount,
            RXAlmostFullCount        => RXAlmostFullCount,                        
            RingBufferSlotID         => RecvRingBufferSlotID,
            RingBufferSlotClear      => RecvRingBufferSlotClear,
            RingBufferSlotStatus     => RecvRingBufferSlotStatus,
            RingBufferSlotTypeStatus => RecvRingBufferSlotTypeStatus,
            RingBufferSlotsFilled    => RecvRingBufferSlotsFilled,
            RingBufferDataRead       => RecvRingBufferDataRead,
            RingBufferDataEnable     => RecvRingBufferDataEnable,
            RingBufferDataOut        => RecvRingBufferDataOut,
            RingBufferAddress        => RecvRingBufferAddress,
            axis_rx_tdata            => axis_rx_tdata,
            axis_rx_tvalid           => axis_rx_tvalid,
            axis_rx_tuser            => axis_rx_tuser,
            axis_rx_tkeep            => axis_rx_tkeep,
            axis_rx_tlast            => axis_rx_tlast
        );
end architecture rtl;
