function bi_real_unscr_4x_init(blk, varargin)
% Initialize and configure a bi_real_unscr_4x block.
% 
% bi_real_unscr_4x_init(blk, varargin)
% 
% blk = the block to configure
% varargin = {'varname', 'value', ...} pairs
% 
% Valid varnames:
% * FFTSize = Size of the FFT (2^FFTSize points).
% * n_bits = Data bitwidth.
% * add_latency = Latency of adders blocks.
% * conv_latency = Latency of cast blocks.
% * bram_latency = Latency of BRAM blocks.
% * bram_map = Store map in BRAM.
% * bram_delays = Implement delays in BRAM.
% * dsp48_adders = Use DSP48s for adders.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %
%   Copyright (C) 2010 William Mallard                                        %
%                                                                             %
%   SKASA                                                                     %
%   www.kat.ac.za                                                             %
%   Copyright (C) 2013 Andrew Martens                                         %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default vararg values.
% reg_retiming is not an actual parameter of this block, but it is included
% in defaults so that same_state will return false for blocks drawn prior to
% adding reg_retiming='on' to some of the underlying Delay blocks.
defaults = { ...
    'n_inputs', 1, ...
    'FFTSize', 3, ...
    'n_bits', 18, ...
    'bin_pt', 17, ...
    'floating_point', 'off', ...
    'float_type', 'single', ...
    'exp_width', 8, ...
    'frac_width', 24, ...         
    'add_latency', 1, ...
    'conv_latency', 1, ...
    'bram_latency', 2, ...
    'bram_map', 'off', ...
    'bram_delays', 'off', ...
    'dsp48_adders', 'off', ...
    'async', 'off', ...
};

% Skip init script if mask state has not changed.
if same_state(blk, 'defaults', defaults, varargin{:}), return; end

% Verify that this is the right mask for the block.
check_mask_type(blk, 'bi_real_unscr_4x');

% Disable link if state changes from default.
munge_block(blk, varargin{:});

% Retrieve values from mask fields.
n_inputs        = get_var('n_inputs', 'defaults', defaults, varargin{:});
FFTSize         = get_var('FFTSize', 'defaults', defaults, varargin{:});
n_bits          = get_var('n_bits', 'defaults', defaults, varargin{:});
bin_pt          = get_var('bin_pt', 'defaults', defaults, varargin{:});
floating_point  = get_var('floating_point', 'defaults', defaults, varargin{:});
float_type      = get_var('float_type', 'defaults', defaults, varargin{:});
exp_width       = get_var('exp_width', 'defaults', defaults, varargin{:});
frac_width      = get_var('frac_width', 'defaults', defaults, varargin{:});
add_latency     = get_var('add_latency', 'defaults', defaults, varargin{:});
conv_latency    = get_var('conv_latency', 'defaults', defaults, varargin{:});
bram_latency    = get_var('bram_latency', 'defaults', defaults, varargin{:});
bram_map        = get_var('bram_map', 'defaults', defaults, varargin{:});
bram_delays     = get_var('bram_delays', 'defaults', defaults, varargin{:});
dsp48_adders    = get_var('dsp48_adders', 'defaults', defaults, varargin{:});
async           = get_var('async', 'defaults', defaults, varargin{:});

if FFTSize == 0 | n_inputs == 0,
  delete_lines(blk);
  clean_blocks(blk);
  save_state(blk, 'defaults', defaults, varargin{:});
  return;
end

% Generate reorder maps.
map_even = bit_reverse(0:2^(FFTSize-1)-1, FFTSize-1);
map_odd = bit_reverse(2^(FFTSize-1)-1:-1:0, FFTSize-1);
map_out = 2^(FFTSize-1)-1:-1:0;

ms_input_latency = 0;
ms_negate_latency = 0;

%%%%%%%%%%%%%%%%%%
% Start drawing! %
%%%%%%%%%%%%%%%%%%

% Delete all lines.
delete_lines(blk);

if floating_point == 1
  float_en = 'on';
  n_bits = exp_width + frac_width;
  bin_pt = 0;
else
  float_en = 'off';  
end

if float_type == 2
  float_type_sel = 'custom';
else
  float_type_sel = 'single';
end


%
% Add inputs and outputs.
%

reuse_block(blk, 'sync', 'built-in/inport', ...
    'Position', [15 13 45 27], ...
    'Port', '1');
reuse_block(blk, 'even', 'built-in/inport', ...
    'Position', [15 238 45 252], ...
    'Port', '2');
reuse_block(blk, 'odd', 'built-in/inport', ...
    'Position', [15 363 45 377], ...
    'Port', '3');

reuse_block(blk, 'sync_out', 'built-in/outport', ...
    'Position', [1200 33 1230 47], ...
    'Port', '1');
reuse_block(blk, 'pol1_out', 'built-in/outport', ...
    'Position', [1200 78 1230 92], ...
    'Port', '2');
reuse_block(blk, 'pol2_out', 'built-in/outport', ...
    'Position', [1200 123 1230 137], ...
    'Port', '3');
reuse_block(blk, 'pol3_out', 'built-in/outport', ...
    'Position', [1200 168 1230 182], ...
    'Port', '4');
reuse_block(blk, 'pol4_out', 'built-in/outport', ...
    'Position', [1200 213 1230 227], ...
    'Port', '5');

if strcmp(async, 'on'),
  reuse_block(blk, 'en', 'built-in/inport', 'Position', [15 213 45 227], 'Port', '4');
  reuse_block(blk, 'dvalid', 'built-in/outport', 'Position', [1200 258 1230 272], 'Port', '6');
else,
  reuse_block(blk, 'en_even', 'xbsIndex_r4/Constant', ...
      'Position', [15 210 45 230], ...
      'ShowName', 'off', ...
      'arith_type', 'Boolean', ...
      'const', '1', ...
      'n_bits', '1', ...
      'bin_pt', '0', ...
      'explicit_period', 'on', ...
      'period', '1');

  reuse_block(blk, 'en_odd', 'xbsIndex_r4/Constant', ...
      'Position', [15 335 45 355], ...
      'ShowName', 'off', ...
      'arith_type', 'Boolean', ...
      'const', '1', ...
      'n_bits', '1', ...
      'bin_pt', '0', ...
      'explicit_period', 'on', ...
      'period', '1');
end

%
% Add reorder blocks.
%

if strcmp(bram_map, 'on'), map_latency = 3;
else map_latency = 1;
end

% if we have a 'large' buffer, add appropriate input delay
% based on a rough approximation of the number of BRAMs required from bit width and buffer depth
fanout_latency = max(0, FFTSize + ceil(log2(n_bits * n_inputs * 2)) - 15);

reuse_block(blk, 'reorder_even', 'casper_library_reorder/reorder', ...
    'Position', [100 182 175 258], ...
    'map', mat2str(map_even), ...
    'n_bits', num2str(n_bits * n_inputs * 2), ...
    'n_inputs', '1', ...
    'bram_latency', num2str(bram_latency),...
    'map_latency', num2str(map_latency), ...
    'fanout_latency', num2str(fanout_latency), ...
    'double_buffer', '0', ...
    'bram_map', bram_map);
add_line(blk, 'even/1', 'reorder_even/3');
add_line(blk, 'sync/1', 'reorder_even/1');

reuse_block(blk, 'reorder_odd', 'casper_library_reorder/reorder', ...
    'Position', [100 307 175 383], ...
    'map', mat2str(map_odd), ...
    'n_bits', num2str(n_bits * n_inputs * 2), ...
    'n_inputs', '1', ...
    'bram_latency', num2str(bram_latency), ...
    'map_latency', num2str(map_latency), ...
    'fanout_latency', num2str(fanout_latency), ...
    'double_buffer', '0', ...
    'bram_map', bram_map);
add_line(blk, 'odd/1', 'reorder_odd/3');
add_line(blk, 'sync/1', 'reorder_odd/1');



reuse_block(blk, 't0', 'built-in/Terminator', ...
  'NamePlacement', 'alternate', 'Position', [195 310 215 330]);
add_line(blk, 'reorder_odd/1', 't0/1');

reuse_block(blk, 't1', 'built-in/Terminator', 'Position', [195 335 215 355]);
add_line(blk, 'reorder_odd/2', 't1/1');

reuse_block(blk, 't2', 'built-in/Terminator', 'Position', [195 212 210 228]);
add_line(blk, 'reorder_even/2', 't2/1');

if strcmp(async,'on'),
  add_line(blk, 'en/1', 'reorder_even/2');
  add_line(blk, 'en/1', 'reorder_odd/2');

  reuse_block(blk, 'l0', 'xbsIndex_r4/Logical', ...
    'logical_function', 'AND', 'inputs', '2', 'latency', '0', ...
    'Position', [195 54 215 81]);
  add_line(blk, 'reorder_even/1', 'l0/1'); 
  add_line(blk, 'reorder_even/2', 'l0/2'); 

else,
  add_line(blk, 'en_even/1', 'reorder_even/2');
  add_line(blk, 'en_odd/1', 'reorder_odd/2');
end

%
% Add mux control logic.
%

reuse_block(blk, 'count', 'xbsIndex_r4/Counter', ...
    'Position', [235 61 265 94], ...
    'cnt_type', 'Free Running', ...
    'cnt_to', 'Inf', ...
    'operation', 'Up', ...
    'start_count', '0', ...
    'cnt_by_val', '1', ...
    'arith_type', 'Unsigned', ...
    'n_bits', 'FFTSize', ...
    'bin_pt', '0', ...
    'load_pin', 'off', ...
    'rst', 'on', ...
    'en', async, ...
    'explicit_period', 'on', ...
    'period', '1', ...
    'use_behavioral_HDL', 'on', ...
    'implementation', 'Fabric');...

reuse_block(blk, 'c0', 'xbsIndex_r4/Constant', ...
    'Position', [235 25 265 45], ...
    'arith_type', 'Unsigned', ...
    'const', '2^(FFTSize-1)', ...
    'n_bits', 'FFTSize', ...
    'bin_pt', '0', ...
    'explicit_period', 'on', ...
    'period', '1');

reuse_block(blk, 'r0', 'xbsIndex_r4/Relational', ...
    'Position', [300 20 350 70], ...
    'ShowName', 'off', ...
    'mode', 'a=b', ...
    'en', 'off', ...
    'latency', '0');
add_line(blk, 'c0/1', 'r0/1');
add_line(blk, 'count/1', 'r0/2');

reuse_block(blk, 'c1', 'xbsIndex_r4/Constant', ...
    'Position', [235 110 265 130], ...
    'arith_type', 'Unsigned', ...
    'const', '0', ...
    'n_bits', 'FFTSize', ...
    'bin_pt', '0', ...
    'explicit_period', 'on', ...
    'period', '1');

reuse_block(blk, 'r1', 'xbsIndex_r4/Relational', ...
    'Position', [300 80 350 130], ...
    'ShowName', 'off', ...
    'mode', 'a=b', ...
    'en', 'off', ...
    'latency', '0');
add_line(blk, 'c1/1', 'r1/2');
add_line(blk, 'count/1', 'r1/1');

reuse_block(blk, 'd0', 'xbsIndex_r4/Delay', ...
    'Position', [225 360 255 380], ...
    'latency', '1', ...
    'en', async, ...
    'reg_retiming', 'on');
add_line(blk, 'reorder_odd/3', 'd0/1');

if strcmp(async, 'on'),
  add_line(blk, 'l0/1', 'count/1');

  add_line(blk, 'reorder_even/2', 'count/2', 'autorouting', 'on');

  reuse_block(blk, 'd1', 'xbsIndex_r4/Delay', ...
      'Position', [470 114 500 136], ...
      'latency', '1', ...
      'reg_retiming', 'on');
  add_line(blk, 'reorder_even/2', 'd1/1');

  add_line(blk, 'reorder_odd/2', 'd0/2');
else
  add_line(blk, 'reorder_even/1', 'count/1');
end

%
% Add mux blocks.
%

if floating_point
    if strcmp(async, 'on'), latency = 'add_latency + 1 + 1';
    else, latency = 'add_latency + conv_latency + 1';
    end
else
    if strcmp(async, 'on'), latency = 'add_latency + conv_latency + 1 + 1';
    else, latency = 'add_latency + conv_latency + 1';
    end    
end


reuse_block(blk, 'd2', 'xbsIndex_r4/Delay', ...
    'Position', [470 77 675 93], ...
    'latency', latency, 'reg_retiming', 'on');
add_line(blk, 'reorder_even/1', 'd2/1');

% Was no latem
reuse_block(blk, 'mux0', 'xbsIndex_r4/Mux', ...
    'latency', '1', ...
    'Position', [475 150 500 216]);

reuse_block(blk, 'mux1', 'xbsIndex_r4/Mux',...
    'latency', '1', ... 
    'Position', [475 250 500 316]);

reuse_block(blk, 'mux2', 'xbsIndex_r4/Mux',...
    'latency', '1', ... 
    'Position', [475 350 500 416]);

reuse_block(blk, 'mux3', 'xbsIndex_r4/Mux',...
    'latency', '1', ... 
    'Position', [475 450 500 516]);

for index = 0:3,
  set_param([blk,'/mux',num2str(index)], ...
    'inputs', '2', ...
    'en', 'off', ...
    'latency', '1', ...
    'Precision', 'Full');
end

add_line(blk, 'r0/1', 'mux0/1');
add_line(blk, 'r0/1', 'mux3/1');
add_line(blk, 'r1/1', 'mux1/1');
add_line(blk, 'r1/1', 'mux2/1');

add_line(blk, 'reorder_even/3', 'mux0/2');
add_line(blk, 'reorder_even/3', 'mux1/3');
add_line(blk, 'reorder_even/3', 'mux2/2');
add_line(blk, 'reorder_even/3', 'mux3/3');

add_line(blk, 'd0/1', 'mux0/3');
add_line(blk, 'd0/1', 'mux1/2');
add_line(blk, 'd0/1', 'mux2/3');
add_line(blk, 'd0/1', 'mux3/2');

%
% Add sync_delay block.
%

sync_delay = '2^(FFTSize-1)';

% If the sync delay requires more than four slices,
% then implement it as a counter.
%
% 1 FF + 3 * (SRL16 + FF) ---> 1 + 3 * (16 + 1) = 52

if (eval(sync_delay) > 52),
  if strcmp(async, 'on'), sync_delay_src = 'sync_delay_en';
  else, sync_delay_src = 'sync_delay';
  end

  reuse_block(blk, 'sync_delay', ['casper_library_delays/',sync_delay_src], ...
        'Position', [705 53 740 117], ...
        'LinkStatus', 'inactive', ...
        'DelayLen', num2str(eval(sync_delay)));

else %use register chain
  reuse_block(blk, 'sync_delay', 'casper_library_delays/delay_srl', ...
      'Position', [705 53 740 117], ...
      'async', async, ...
      'DelayLen', num2str(eval(sync_delay)));
end
add_line(blk, 'd2/1', 'sync_delay/1');

%
% Add hilbert blocks.
%
  
reuse_block(blk, 'hilbert0', 'casper_library_ffts_internal/hilbert', 'Position', [550 200 600 250]);
reuse_block(blk, 'hilbert1', 'casper_library_ffts_internal/hilbert', 'Position', [550 400 600 450]);

for name = {'hilbert0', 'hilbert1'};      
  set_param([blk,'/', name{1}], ...
    'n_inputs', num2str(n_inputs), ...
    'BitWidth', num2str(n_bits), ...
    'bin_pt_in', num2str(bin_pt), ...
    'floating_point', float_en, ...
    'float_type', float_type_sel, ...
    'exp_width', num2str(exp_width), ...
    'frac_width', num2str(frac_width), ...     
    'add_latency', num2str(add_latency), ...
    'misc', async, ...
    'conv_latency', 'conv_latency');
end

add_line(blk, 'mux0/1', 'hilbert0/1');
add_line(blk, 'mux1/1', 'hilbert0/2');
add_line(blk, 'mux2/1', 'hilbert1/1');
add_line(blk, 'mux3/1', 'hilbert1/2');

if strcmp(async, 'on'),
  reuse_block(blk, 'l1', 'xbsIndex_r4/Logical', ...
    'inputs', '2', 'logical_function', 'AND', 'latency', '0', ...
    'Position', [770 66 795 144]);

  add_line(blk, 'sync_delay/1', 'l1/1');

  add_line(blk, 'd1/1', 'hilbert0/3');
  add_line(blk, 'd1/1', 'hilbert1/3');
end

%
% Add fanout delays 
%

if strcmp(async, 'on'),
  % en
  reuse_block(blk, 'den0', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [625 92 650 108]);
  add_line(blk, 'hilbert0/3', 'den0/1');
  add_line(blk, 'den0/1', 'sync_delay/2');
  reuse_block(blk, 'den1', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 117 675 133]);
  add_line(blk, 'hilbert0/3', 'den1/1');
  add_line(blk, 'den1/1', 'l1/2');
  reuse_block(blk, 'den2', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 207 675 223]);
  add_line(blk, 'hilbert0/3', 'den2/1');
  reuse_block(blk, 'den3', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 267 675 283]);
  add_line(blk, 'hilbert0/3', 'den3/1');
  
  reuse_block(blk, 'den4', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 402 675 418]);
  add_line(blk, 'hilbert1/3', 'den4/1');
  reuse_block(blk, 'den5', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 437 675 453]);
  add_line(blk, 'hilbert1/3', 'den5/1');

  % data
  reuse_block(blk, 'dd0', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 177 675 193]);
  add_line(blk, 'hilbert0/1', 'dd0/1');
  reuse_block(blk, 'dd1', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 237 675 253]);
  add_line(blk, 'hilbert0/2', 'dd1/1');
  reuse_block(blk, 'dd2', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 332 675 348]);
  add_line(blk, 'hilbert1/1', 'dd2/1');
  reuse_block(blk, 'dd3', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 367 675 383]);
  add_line(blk, 'hilbert1/2', 'dd3/1');
  reuse_block(blk, 'dd4', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 512 675 528]);
  add_line(blk, 'hilbert1/1', 'dd4/1');
  reuse_block(blk, 'dd5', 'xbsIndex_r4/Delay', 'latency', '1', 'reg_retiming', 'on', ...
    'Position', [650 537 675 553]);
  add_line(blk, 'hilbert1/2', 'dd5/1');
end %if

%
% Add delay blocks.
%

if strcmp(bram_delays, 'on') | eval(sync_delay) > 52 , delay_src = 'delay_bram';
else delay_src = 'delay_srl';
end

reuse_block(blk, 'delay0', ['casper_library_delays/',delay_src], 'NamePlacement', 'alternate', ...
  'Position', [705 171 740 229]);
reuse_block(blk, 'delay1', ['casper_library_delays/',delay_src], 'Position', [705 232 740 288]);

for index = 0:1,
  params = {'DelayLen', num2str(2^(FFTSize-1)), 'async', async};
  if strcmp(bram_delays, 'on'),
      params = {params{:}, 'bram_latency', num2str(bram_latency)};
  end

  set_param([blk, '/delay', num2str(index)], params{:});
end

if strcmp(async, 'on'),
  add_line(blk, 'dd0/1', 'delay0/1');
  add_line(blk, 'dd1/1', 'delay1/1');
  
  add_line(blk, 'den2/1', 'delay0/2');
  add_line(blk, 'den3/1', 'delay1/2');
  ms_position = [1050 10 1140 290];
else
  add_line(blk, 'hilbert0/1', 'delay0/1');
  add_line(blk, 'hilbert0/2', 'delay1/1');

  ms_position = [1050 18 1155 241];
end

%
% mirror_spectrum 
%

reuse_block(blk, 'mirror_spectrum', 'casper_library_ffts_internal/mirror_spectrum', ...
    'n_inputs', num2str(n_inputs), ...
    'Position', ms_position, ...
    'FFTSize', num2str(FFTSize), ...
    'input_bitwidth', num2str(n_bits), ...
    'bin_pt_in', num2str(bin_pt), ...
    'floating_point', float_en, ...
    'float_type', float_type_sel, ...
    'exp_width', num2str(exp_width), ...
    'frac_width', num2str(frac_width), ...         
    'bram_latency', num2str(bram_latency + map_latency + 2 + fanout_latency), ... 
    'async', async, ...
    'bin_pt_in', num2str('bin_pt'), ...
    'negate_mode', 'logic', ...
    'negate_latency', num2str(ms_negate_latency));

add_line(blk, 'delay0/1', 'mirror_spectrum/2');
add_line(blk, 'delay1/1', 'mirror_spectrum/4');

if strcmp(async, 'on')
  add_line(blk, 'dd2/1', 'mirror_spectrum/6');
  add_line(blk, 'dd3/1', 'mirror_spectrum/8');
else,
  add_line(blk, 'hilbert1/1', 'mirror_spectrum/6');
  add_line(blk, 'hilbert1/2', 'mirror_spectrum/8');
end

add_line(blk, 'mirror_spectrum/1', 'sync_out/1');
add_line(blk, 'mirror_spectrum/2', 'pol1_out/1');
add_line(blk, 'mirror_spectrum/3', 'pol2_out/1');
add_line(blk, 'mirror_spectrum/4', 'pol3_out/1');
add_line(blk, 'mirror_spectrum/5', 'pol4_out/1');

if strcmp(async, 'on'),
  add_line(blk, 'l1/1', 'mirror_spectrum/1');

  add_line(blk, 'den4/1', 'mirror_spectrum/10');
  add_line(blk, 'mirror_spectrum/6', 'dvalid/1');
else,
  add_line(blk, 'sync_delay/1', 'mirror_spectrum/1');
end

%
% reorder to reverse order of second half of spectrum
%

reuse_block(blk, 'reorder_out', 'casper_library_reorder/reorder', ...
    'Position', [825 400 900 560], ...
    'map', mat2str(map_out), ...
    'n_bits', num2str(n_bits * n_inputs * 2), ...
    'n_inputs', '4', ...
    'bram_latency', 'bram_latency', ...
    'map_latency', num2str(map_latency), ...
    'fanout_latency', num2str(fanout_latency), ...
    'double_buffer', '0', ...
    'bram_map', bram_map);

add_line(blk, 'delay0/1', 'reorder_out/3');
add_line(blk, 'delay1/1', 'reorder_out/4');

if strcmp(async, 'on'),
  add_line(blk, 'dd4/1', 'reorder_out/5');
  add_line(blk, 'dd5/1', 'reorder_out/6');
else,
  add_line(blk, 'hilbert1/1', 'reorder_out/5');
  add_line(blk, 'hilbert1/2', 'reorder_out/6');
end

if strcmp(async, 'on'),
  add_line(blk, 'l1/1', 'reorder_out/1');
  add_line(blk, 'den5/1', 'reorder_out/2');
else
  add_line(blk, 'sync_delay/1', 'reorder_out/1');
  reuse_block(blk, 'en_out', 'xbsIndex_r4/Constant', ...
      'Position', [725 435 750 455], ...
      'arith_type', 'Boolean', ...
      'const', '1', ...
      'n_bits', '1', ...
      'bin_pt', '0', ...
      'explicit_period', 'on', ...
      'period', '1');
  add_line(blk, 'en_out/1', 'reorder_out/2');
end

reuse_block(blk, 't3', 'built-in/Terminator', ...
  'NamePlacement', 'alternate', 'Position', [1000 409 1020 431]);
add_line(blk, 'reorder_out/1', 't3/1');
reuse_block(blk, 't4', 'built-in/Terminator', 'Position', [1000 434 1020 456]);
add_line(blk, 'reorder_out/2', 't4/1');

%
%latencies to delay second half of spectrum by 1 to align with first on the way out
%e.g data indices for 8 point FFT after reorder_out 
% top stream      -> 0 1 2 3 4
% bottom stream   ->         5 6 7
%

for index = 0:3,
  reuse_block(blk, ['d',num2str(index+3)], 'xbsIndex_r4/Delay', ...
      'Position', [995 65+(index*60) 1025 85+(index*60)], ...
      'latency', '1', 'en', async, ...
      'reg_retiming', 'on');
  add_line(blk, ['reorder_out/',num2str(3+index)], ['d',num2str(index+3),'/1']);

  if strcmp(async, 'on'), add_line(blk, 'reorder_out/2', ['d',num2str(index+3),'/2']);
  end
  
  add_line(blk, ['d',num2str(index+3),'/1'], ['mirror_spectrum/',num2str(1+((index+1)*2))]);
end

% Delete all unconnected blocks.
clean_blocks(blk);

%%%%%%%%%%%%%%%%%%%
% Finish drawing! %
%%%%%%%%%%%%%%%%%%%

% Save block state to stop repeated init script runs.
save_state(blk, 'defaults', defaults, varargin{:});

