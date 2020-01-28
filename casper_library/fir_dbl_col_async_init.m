% fir_dbl_col_init(blk, varargin)
%
% blk = The block to initialize.
% varargin = {'varname', 'value', ...} pairs
%
% Valid varnames for this block are:
% n_inputs = The number of parallel input samples.
% coeff = The FIR coefficients, top-to-bottom.
% add_latency = The latency of adders.
% mult_latency = The latency of multipliers.
% coeff_bit_width = The number of bits used for coefficients
% coeff_bin_pt = The number of fractional bits in the coefficients
% first_stage_hdl = Whether to implement the first stage in adder trees
%   as behavioral HDL so that adders are absorbed into DSP slices used for
%   multipliers where this is possible.
% adder_imp = adder implementation (Fabric, behavioral HDL, DSP48)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://seti.ssl.berkeley.edu/casper/                                      %
%   Copyright (C) 2006 David MacMahon, Aaron Parsons                          %
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

function fir_dbl_col_async_init(blk, varargin)
clog('entering fir_dbl_col_async_init', 'trace');

showname = 'on';
sizey_goto = 15;
 
% varargin = make_varargin(blk);
% 
% % declare any default values for arguments you might like.
% defaults = {'n_inputs', 0, 'coeff', 0.1, 'add_latency', 2, ...
%     'mult_latency', 3, 'coeff_bit_width', 25, 'coeff_bin_pt', 24, ...
%     'first_stage_hdl', 'off', 'adder_imp', 'Fabric', 'async', 'off', ...
%     'bus_input', 'off', 'dbl', 'off', 'input_width', 16, ...
%     'input_bp', 0, 'input_type', 'Unsigned'};
% 
% check_mask_type(blk, 'fir_col_async');
% if same_state(blk, 'defaults', defaults, varargin{:}), return, end
% clog('fir_dbl_col_async_init post same_state', 'trace');
% munge_block(blk, varargin{:});

% n_inputs =          get_var('n_inputs', 'defaults', defaults, varargin{:});
% coeff =             get_var('coeff', 'defaults', defaults, varargin{:});
% add_latency =       get_var('add_latency', 'defaults', defaults, varargin{:});
% mult_latency =      get_var('mult_latency', 'defaults', defaults, varargin{:});
% coeff_bit_width =   get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
% coeff_bin_pt =      get_var('coeff_bin_pt', 'defaults', defaults, varargin{:});
% first_stage_hdl =   get_var('first_stage_hdl', 'defaults', defaults, varargin{:});
% adder_imp =         get_var('adder_imp', 'defaults', defaults, varargin{:});
% async_ops =         strcmp('on', get_var('async', 'defaults', defaults, varargin{:}));
% bus_input =         strcmp('on', get_var('bus_input', 'defaults', defaults, varargin{:}));
% double_blk =        strcmp('on', get_var('dbl', 'defaults', defaults, varargin{:}));

n_inputs =          get_var('n_inputs', varargin{:});
coeff =             get_var('coeff', varargin{:});
add_latency =       get_var('add_latency', varargin{:});
mult_latency =      get_var('mult_latency', varargin{:});
coeff_bit_width =   get_var('coeff_bit_width', varargin{:});
coeff_bin_pt =      get_var('coeff_bin_pt', varargin{:});
first_stage_hdl =   get_var('first_stage_hdl', varargin{:});
adder_imp =         get_var('adder_imp', varargin{:});
async_ops =         strcmp('on', get_var('async', varargin{:}));
bus_input =         strcmp('on', get_var('bus_input', varargin{:}));
double_blk =        strcmp('on', get_var('dbl', varargin{:}));

% async_ops = false;
% bus_input = false;
% double_blk = false;

% this should be a double block
if ~double_blk,
    error('This script should only be called on a doubled-up tap block.');
end

if bus_input,
    input_width = get_var('input_width',varargin{:});
    input_bp = get_var('input_bp',varargin{:});
    input_type = get_var('input_type',varargin{:});
    if strcmp(input_type, 'Signed'),
        input_type_num = 1;
    else
        input_type_num = 0;
    end
end

delete_lines(blk);

% % default library state
% if n_inputs == 0,
%     clog('fir_dbl_col_async_init no inputs', 'trace');
%     clean_blocks(blk);
%     save_state(blk, 'defaults', defaults, varargin{:});
%     clog('exiting fir_dbl_col_async_init', 'trace');
%     return;
% end

if length(coeff) ~= n_inputs,
    clog('number of coefficients must be the same as the number of inputs', {'fir_dbl_col_async_init_debug', 'error'});
    error('number of coefficients must be the same as the number of inputs');
end

% draw the inputs differently depending on whether we're taking a bus input or not
if bus_input,
    reuse_block(blk, 'dbus_in', 'built-in/inport', 'Position', [0 30 30 46], 'Port', '1');
    reuse_block(blk, 'inbus', 'casper_library_flow_control/bus_expand', ...
        'Position', [80 30 150 30+(n_inputs*sizey_goto*3)]);
    set_param([blk, '/inbus'], ...
        'mode', 'divisions of equal size', ...
        'outputNum', num2str(2*n_inputs), ...
        'outputWidth', num2str(input_width), ...
        'outputBinaryPt', num2str(input_bp), ...
        'outputArithmeticType', num2str(input_type_num), ...
        'show_format', 'off', ...
        'outputToWorkspace', 'off');
    add_line(blk, 'dbus_in/1', 'inbus/1');
    reuse_block(blk, 'dbus_back_in', 'built-in/inport', 'Position', [0 500 30 516], 'Port', '2');
    reuse_block(blk, 'inbus_back', 'casper_library_flow_control/bus_expand', ...
        'Position', [80 500 150 500+(n_inputs*sizey_goto*3)]);
    set_param([blk, '/inbus_back'], ...
        'mode', 'divisions of equal size', ...
        'outputNum', num2str(2*n_inputs), ...
        'outputWidth', num2str(input_width), ...
        'outputBinaryPt', num2str(input_bp), ...
        'outputArithmeticType', num2str(input_type_num), ...
        'show_format', 'off', ...
        'outputToWorkspace', 'off');
    add_line(blk, 'dbus_back_in/1', 'inbus_back/1');
    port_num = 3;
else
    port_num = 1;
    for ctr = 1 : n_inputs,
        ctrstr = num2str(ctr);
        reuse_block(blk, ['real', ctrstr], 'built-in/inport', ...
            'Position', [30 ctr*80 60 15+80*ctr], ...
            'Port', num2str(port_num));
        reuse_block(blk, ['imag', ctrstr], 'built-in/inport', ...
            'Position', [30 ctr*80+30 60 45+80*ctr], ...
            'Port', num2str(port_num+1));
        port_num = port_num + 2;
    end
    offset = n_inputs*50*2;
    for ctr = 1 : n_inputs,
        ctrstr = num2str(ctr);
        reuse_block(blk, ['real_back', ctrstr], 'built-in/inport', ...
            'Position', [30 offset+ctr*80 60 offset+15+80*ctr], ...
            'Port', num2str(port_num));
        reuse_block(blk, ['imag_back', ctrstr], 'built-in/inport', ...
            'Position', [30 offset+ctr*80+30 60 offset+45+80*ctr], ...
            'Port', num2str(port_num+1));
        port_num = port_num + 2;
    end
end
if async_ops,
    reuse_block(blk, 'dv', 'built-in/inport', 'Position', [0 0 30 16]);
    set_param([blk, '/dv'], 'Port', num2str(port_num));
    reuse_block(blk, 'dv_in', 'built-in/goto', ...
        'GotoTag', 'dv_in', 'showname', showname, ...
        'Position', [50 0 120 16]);
    add_line(blk, 'dv/1', 'dv_in/1');
end

% tap blocks and connections to the inputs
for ctr = 1 : n_inputs,
    ctrstr = num2str(ctr);
    blkname = ['fir_tap', ctrstr];
    full_blkname = [blk, '/', blkname];
    tap_ypos = ctr*160 - 160;
    reuse_block(blk, blkname, 'casper_library_downconverter/fir_tap_async', ...
        'Position', [400 tap_ypos 470 tap_ypos+120], ...
        'add_latency', num2str(add_latency), ...
        'mult_latency', num2str(mult_latency), ...
        'factor', num2str(coeff(ctr)), ...
        'coeff_bit_width', num2str(coeff_bit_width), ...
        'coeff_bin_pt', num2str(coeff_bin_pt), 'dbl', 'on');
    if async_ops,
        set_param(full_blkname, 'async', 'on');
    else
        set_param(full_blkname, 'async', 'off');
    end
    % connection to inputs
    if async_ops,
        reuse_block(blk, ['dv_in', ctrstr], 'built-in/from', 'GotoTag', 'dv_in', 'showname', showname, 'Position', [280 tap_ypos+104 360 tap_ypos+120]);
        if double_blk,
            add_line(blk, ['dv_in', ctrstr, '/1'], [blkname, '/5']);
        else
            add_line(blk, ['dv_in', ctrstr, '/1'], [blkname, '/3']);
        end
    end
    if bus_input,
        pos = ((ctr-1)*2)+1;
        add_line(blk, ['inbus/', num2str(pos+0)], [blkname, '/1']);
        add_line(blk, ['inbus/', num2str(pos+1)], [blkname, '/2']);
        add_line(blk, ['inbus_back/', num2str(n_inputs*2-pos)], [blkname, '/3']);
        add_line(blk, ['inbus_back/', num2str(n_inputs*2-pos+1)], [blkname, '/4']);
    else
        add_line(blk, ['real', ctrstr, '/1'], [blkname, '/1']);
        add_line(blk, ['imag', ctrstr, '/1'], [blkname, '/2']);
        add_line(blk, ['real_back', num2str(n_inputs-ctr+1), '/1'], [blkname, '/3']);
        add_line(blk, ['imag_back', num2str(n_inputs-ctr+1), '/1'], [blkname, '/4']);
    end
end

% output ports
if bus_input,
    reuse_block(blk, 'outbus', 'casper_library_flow_control/bus_create', ...
        'inputNum', num2str(n_inputs*2), ...
        'Position', [600 30 650 30+(n_inputs*sizey_goto*3)]);
    reuse_block(blk, 'dbus_out', 'built-in/outport', 'Position', [700 30 730 46], 'Port', '1');
    add_line(blk, 'outbus/1', 'dbus_out/1');
    reuse_block(blk, 'outbus_back', 'casper_library_flow_control/bus_create', ...
        'inputNum', num2str(n_inputs*2), ...
        'Position', [600 500 650 500+(n_inputs*sizey_goto*3)]);
    reuse_block(blk, 'dbus_back_out', 'built-in/outport', 'Position', [700 500 730 516], 'Port', '2');
    add_line(blk, 'outbus_back/1', 'dbus_back_out/1');
    for ctr = 1 : n_inputs,
        ctrstr = num2str(ctr);
        tapname = ['fir_tap', ctrstr];
        pos = ((ctr-1)*2)+1;
        add_line(blk, [tapname, '/1'], ['outbus/', num2str(pos+0)]);
        add_line(blk, [tapname, '/2'], ['outbus/', num2str(pos+1)]);
        add_line(blk, [tapname, '/3'], ['outbus_back/', num2str(n_inputs*2-pos)]);
        add_line(blk, [tapname, '/4'], ['outbus_back/', num2str(n_inputs*2-pos+1)]);
    end
else
    for ctr = 1 : n_inputs,
        ctrstr = num2str(ctr);
        reuse_block(blk, ['real_out', ctrstr], 'built-in/outport', 'Position', [550 ctr*80 580 15+80*ctr], 'Port', num2str(ctr*2-1));
        reuse_block(blk, ['imag_out', ctrstr], 'built-in/outport', 'Position', [550 ctr*80+30 580 45+80*ctr], 'Port', num2str(ctr*2));
    end
    offset = n_inputs*50*2;
    for ctr = 1 : n_inputs,
        ctrstr = num2str(ctr);
        reuse_block(blk, ['real_back_out', ctrstr], 'built-in/outport', 'Position', [550 offset+ctr*80 580 offset+15+80*ctr], 'Port', num2str(ctr*2-1+n_inputs*2));
        reuse_block(blk, ['imag_back_out', ctrstr], 'built-in/outport', 'Position', [550 offset+ctr*80+30 580 offset+45+80*ctr], 'Port', num2str(ctr*2+n_inputs*2));
    end
    for ctr = 1 : n_inputs,
        ctrstr = num2str(ctr);
        blkname = ['fir_tap', ctrstr];
        add_line(blk, [blkname, '/1'], ['real_out', ctrstr,'/1']);
        add_line(blk, [blkname, '/2'], ['imag_out', ctrstr,'/1']);
        add_line(blk, [blkname, '/3'], ['real_back_out', num2str(n_inputs+1-ctr),'/1']);
        add_line(blk, [blkname, '/4'], ['imag_back_out', num2str(n_inputs+1-ctr),'/1']);
    end
end

% the output sum blocks
if bus_input,
    reuse_block(blk, 'real_sum', 'built-in/outport', 'Position', [900 100+20*n_inputs 930 116+20*n_inputs], 'Port', '3');
    reuse_block(blk, 'imag_sum', 'built-in/outport', 'Position', [900 200+20*n_inputs 930 216+20*n_inputs], 'Port', '4');
else
    reuse_block(blk, 'real_sum', 'built-in/outport', 'Position', [900 100+20*n_inputs 930 116+20*n_inputs], 'Port', num2str(n_inputs*4+1));
    reuse_block(blk, 'imag_sum', 'built-in/outport', 'Position', [900 200+20*n_inputs 930 216+20*n_inputs], 'Port', num2str(n_inputs*4+2));
end

% the adder trees
if n_inputs > 1,
    reuse_block(blk, 'adder_tree1', 'casper_library_misc/adder_tree', ...
        'Position', [800 100 850 100+20*n_inputs], 'n_inputs', num2str(n_inputs),...
        'csp_latency', num2str(add_latency), 'first_stage_hdl', first_stage_hdl, 'adder_imp', adder_imp);
    reuse_block(blk, 'adder_tree2', 'casper_library_misc/adder_tree', ...
        'Position', [800 200+20*n_inputs 850 200+20*n_inputs+20*n_inputs], 'n_inputs', num2str(n_inputs),...
        'csp_latency', num2str(add_latency), 'first_stage_hdl', first_stage_hdl, 'adder_imp', adder_imp);
    reuse_block(blk, 'c1', 'xbsIndex_r4/Constant', ...
        'explicit_period', 'on', 'Position', [750 100 780 110]);
    reuse_block(blk, 'c2', 'xbsIndex_r4/Constant', ...
        'explicit_period', 'on', 'Position', [750 200+20*n_inputs 780 210+20*n_inputs]);
    reuse_block(blk, 'term1','built-in/Terminator', 'Position', [1000 100 1015 115]);	
    add_line(blk, 'adder_tree1/1', 'term1/1');
    reuse_block(blk, 'term2','built-in/Terminator', 'Position', [1000 200+20*n_inputs 1015 215+20*n_inputs]);	
    add_line(blk, 'adder_tree2/1', 'term2/1');
    add_line(blk, 'c1/1', 'adder_tree1/1');
    add_line(blk, 'c2/1', 'adder_tree2/1');
    add_line(blk,'adder_tree1/2','real_sum/1');
    add_line(blk,'adder_tree2/2','imag_sum/1');
    for ctr=1:n_inputs,
        add_line(blk, ['fir_tap', num2str(ctr), '/5'], ['adder_tree1/', num2str(ctr+1)]);
        add_line(blk, ['fir_tap', num2str(ctr), '/6'], ['adder_tree2/', num2str(ctr+1)]);
    end
else
    add_line(blk, 'fir_tap1/5', 'real_sum/1');
    add_line(blk, 'fir_tap1/6', 'imag_sum/1');
end

% When finished drawing blocks and lines, remove all unused blocks.
% clean_blocks(blk);
% save_state(blk, 'defaults', defaults, varargin{:});

clog('exiting fir_dbl_col_async_init', 'trace');
