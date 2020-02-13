%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://seti.ssl.berkeley.edu/casper/                                      %
%   Copyright (C) 2006 David MacMahon, Aaron Parsons                          %
%                                                                             %
%   MeerKAT Radio Telescope Project                                           %
%   www.kat.ac.za                                                             %
%   Copyright (C) 2013 Andrew Martens (meerKAT)                               %
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

function fir_dbl_tap_async_init(blk)
    clog('entering fir_dbl_tap_async_init', 'trace');
    varargin = make_varargin(blk);
    defaults = {};
    check_mask_type(blk, 'fir_tap_async');
    if same_state(blk, 'defaults', defaults, varargin{:}), return, end
    clog('fir_dbl_tap_async_init post same_state', 'trace');
    munge_block(blk, varargin{:});

%     factor          = get_var('factor','defaults', defaults, varargin{:});
%     add_latency     = get_var('latency','defaults', defaults, varargin{:});
%     mult_latency    = get_var('latency','defaults', defaults, varargin{:});
    coeff_bit_width = get_var('coeff_bit_width','defaults', defaults, varargin{:});
%     coeff_bin_pt    = get_var('coeff_bin_pt','defaults', defaults, varargin{:});
    async_ops = strcmp('on', get_var('async','defaults', defaults, varargin{:}));
    double_blk = strcmp('on', get_var('dbl','defaults', defaults, varargin{:}));

    if ~double_blk,
        error('This script should only be called on a doubled-up tap block.');
    end

    delete_lines(blk);

    %default state in library
    if coeff_bit_width == 0,
        clean_blocks(blk);
        save_state(blk, 'defaults', defaults, varargin{:});  
        return; 
    end

    reuse_block(blk, 'a', 'built-in/Inport');
    set_param([blk,'/a'], ...
        'Port', '1', ...
        'Position', '[25 33 55 47]');
    reuse_block(blk, 'b', 'built-in/Inport');
    set_param([blk,'/b'], ...
        'Port', '2', ...
        'Position', '[25 123 55 137]');
    reuse_block(blk, 'c', 'built-in/Inport');
    set_param([blk,'/c'], ...
        'Port', '3', ...
        'Position', '[25 213 55 227]');
    reuse_block(blk, 'd', 'built-in/Inport');
    set_param([blk,'/d'], ...
        'Port', '4', ...
        'Position', '[25 303 55 317]');
    if async_ops,
        reuse_block(blk, 'dv_in', 'built-in/Inport', 'Port', '5', ...
            'Position', '[205 0 235 14]');
    end
    
reuse_block(blk, 'Register0', 'xbsIndex_r4/Register');
set_param([blk,'/Register0'], ...
'Position', '[315 16 360 64]');

reuse_block(blk, 'Register1', 'xbsIndex_r4/Register');
set_param([blk,'/Register1'], ...
'Position', '[315 106 360 154]');

reuse_block(blk, 'Register2', 'xbsIndex_r4/Register');
set_param([blk,'/Register2'], ...
'Position', '[315 196 360 244]');

reuse_block(blk, 'Register3', 'xbsIndex_r4/Register');
set_param([blk,'/Register3'], ...
'Position', '[315 286 360 334]');

    reuse_block(blk, 'coefficient', 'xbsIndex_r4/Constant');
    set_param([blk,'/coefficient'], ...
        'const', 'factor', ...
        'n_bits', 'coeff_bit_width', ...
        'bin_pt', 'coeff_bin_pt', ...
        'explicit_period', 'on', ...
        'Position', '[165 354 285 386]');
    
    reuse_block(blk, 'AddSub0', 'xbsIndex_r4/AddSub');
    set_param([blk,'/AddSub0'], ...
        'latency', 'add_latency', ...
        'arith_type', 'Signed  (2''s comp)', ...
        'n_bits', '18', ...
        'bin_pt', '16', ...
        'use_behavioral_HDL', 'on', ...
        'use_rpm', 'on', ...
        'Position', '[180 412 230 463]');

    reuse_block(blk, 'Mult0', 'xbsIndex_r4/Mult');
        set_param([blk,'/Mult0'], ...
        'n_bits', '18', ...
        'bin_pt', '17', ...
        'latency', 'mult_latency', ...
        'use_behavioral_HDL', 'on', ...
        'use_rpm', 'off', ...
        'placement_style', 'Rectangular shape', ...
        'Position', '[315 402 365 453]');

    reuse_block(blk, 'AddSub1', 'xbsIndex_r4/AddSub');
        set_param([blk,'/AddSub1'], ...
        'latency', 'add_latency', ...
        'arith_type', 'Signed  (2''s comp)', ...
        'n_bits', '18', ...
        'bin_pt', '16', ...
        'use_behavioral_HDL', 'on', ...
        'use_rpm', 'on', ...
        'Position', '[180 497 230 548]');

    reuse_block(blk, 'Mult1', 'xbsIndex_r4/Mult');
        set_param([blk,'/Mult1'], ...
        'n_bits', '18', ...
        'bin_pt', '17', ...
        'latency', 'mult_latency', ...
        'use_behavioral_HDL', 'on', ...
        'use_rpm', 'off', ...
        'placement_style', 'Rectangular shape', ...
        'Position', '[315 487 365 538]');

    reuse_block(blk, 'a_out', 'built-in/Outport');
        set_param([blk,'/a_out'], ...
        'Port', '1', ...
        'Position', '[390 33 420 47]');

    reuse_block(blk, 'b_out', 'built-in/Outport');
        set_param([blk,'/b_out'], ...
        'Port', '2', ...
        'Position', '[390 123 420 137]');

    reuse_block(blk, 'c_out', 'built-in/Outport');
        set_param([blk,'/c_out'], ...
        'Port', '3', ...
        'Position', '[390 213 420 227]');

    reuse_block(blk, 'd_out', 'built-in/Outport');
        set_param([blk,'/d_out'], ...
        'Port', '4', ...
        'Position', '[390 303 420 317]');

    reuse_block(blk, 'real', 'built-in/Outport');
        set_param([blk,'/real'], ...
        'Port', '5', ...
        'Position', '[390 423 420 437]');

    reuse_block(blk, 'imag', 'built-in/Outport');
        set_param([blk,'/imag'], ...
        'Port', '6', ...
        'Position', '[390 508 420 522]');
    
    
    if async_ops,
        set_param([blk, '/Register0'], 'en', 'on');
        set_param([blk, '/Register1'], 'en', 'on');
        set_param([blk, '/Register2'], 'en', 'on');
        set_param([blk, '/Register3'], 'en', 'on');
        set_param([blk, '/Mult0'], 'en', 'on');        
        set_param([blk, '/Mult1'], 'en', 'on');
    else
        set_param([blk, '/Register0'], 'en', 'off');
        set_param([blk, '/Register1'], 'en', 'off');
        set_param([blk, '/Register2'], 'en', 'off');
        set_param([blk, '/Register3'], 'en', 'off');
        set_param([blk, '/Mult0'], 'en', 'off');        
        set_param([blk, '/Mult1'], 'en', 'off'); 
    end
    
    if async_ops,
        set_param([blk, '/AddSub0'], 'en', 'on');        
        set_param([blk, '/AddSub1'], 'en', 'on');
    else
        set_param([blk, '/AddSub0'], 'en', 'off');        
        set_param([blk, '/AddSub1'], 'en', 'off');      
    end
    
    if async_ops,
        add_line(blk, 'dv_in/1', 'Register0/2', 'autorouting', 'on');
        add_line(blk, 'dv_in/1', 'Register1/2', 'autorouting', 'on');
        add_line(blk, 'dv_in/1', 'Register2/2', 'autorouting', 'on');
        add_line(blk, 'dv_in/1', 'Register3/2', 'autorouting', 'on');
        add_line(blk, 'dv_in/1', 'Mult0/3', 'autorouting', 'on');
        add_line(blk, 'dv_in/1', 'Mult1/3', 'autorouting', 'on');  
        add_line(blk, 'dv_in/1', 'AddSub0/3', 'autorouting', 'on');
        add_line(blk, 'dv_in/1', 'AddSub1/3', 'autorouting', 'on'); 
    end
    add_line(blk,'d/1','AddSub1/2', 'autorouting', 'on');
    add_line(blk,'d/1','Register3/1', 'autorouting', 'on');
    add_line(blk,'c/1','AddSub0/2', 'autorouting', 'on');
    add_line(blk,'c/1','Register2/1', 'autorouting', 'on');
    add_line(blk,'b/1','AddSub1/1', 'autorouting', 'on');
    add_line(blk,'b/1','Register1/1', 'autorouting', 'on');
    add_line(blk,'a/1','AddSub0/1', 'autorouting', 'on');
    add_line(blk,'a/1','Register0/1', 'autorouting', 'on');
    add_line(blk,'Register0/1','a_out/1', 'autorouting', 'on');
    add_line(blk,'Register1/1','b_out/1', 'autorouting', 'on');
    add_line(blk,'Register2/1','c_out/1', 'autorouting', 'on');
    add_line(blk,'coefficient/1','Mult0/1', 'autorouting', 'on');
    add_line(blk,'coefficient/1','Mult1/1', 'autorouting', 'on');
    add_line(blk,'Register3/1','d_out/1', 'autorouting', 'on');
    add_line(blk,'AddSub0/1','Mult0/2', 'autorouting', 'on');
    add_line(blk,'Mult0/1','real/1', 'autorouting', 'on');
    add_line(blk,'AddSub1/1','Mult1/2', 'autorouting', 'on');
    add_line(blk,'Mult1/1','imag/1', 'autorouting', 'on');

    % When finished drawing blocks and lines, remove all unused blocks.
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});
    clog('exiting fir_dbl_tap_async_init', 'trace');

end % fir_dbl_tap_init

