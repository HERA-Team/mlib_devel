%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://www.kat.ac.za                                                      %
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

function bus_delay_init(blk, varargin)
  log_group = 'bus_delay_init_debug';

  clog('entering bus_delay_init', {log_group, 'trace'});
  defaults = { ...
    'n_bits', [8 8], ...
    'cmplx', 'off', ...
    'enable', 'on', ...
    'csp_latency', 1, ...
    'misc', 'off', ...
    'reg_retiming', 'on'};
  
  check_mask_type(blk, 'bus_delay');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  xpos = 50; xinc = 80;
  ypos = 50; yinc = 50;

  port_w = 30; port_d = 14;
  bus_expand_w = 50;
  bus_compress_w = 50;
  reg_w = 50; reg_d = 60;
  del_w = 30; del_d = 20;

  enable        = get_var('enable', 'defaults', defaults, varargin{:});
  cmplx         = get_var('cmplx', 'defaults', defaults, varargin{:});
  n_bits        = get_var('n_bits', 'defaults', defaults, varargin{:});
  misc          = get_var('misc', 'defaults', defaults, varargin{:});
  latency       = get_var('csp_latency', 'defaults', defaults, varargin{:});
  reg_retiming  = get_var('reg_retiming', 'defaults', defaults, varargin{:});
  len     = length(n_bits);

  delete_lines(blk);

  %default state, do nothing 
  if latency == -1,
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values
    clog('exiting bus_delay_init', {log_group, 'trace'});
    return;
  end

  if strcmp(cmplx,'on'), n_bits = 2*n_bits; end

  %input ports
  port_no = 1;
  ypos_tmp = ypos + reg_d*len/2;
  reuse_block(blk, 'din', 'built-in/inport', ...
    'Port', num2str(port_no), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc + reg_d*len;
  port_no = port_no + 1;

  if strcmp(enable, 'on'),
    reuse_block(blk, 'en', 'built-in/inport', ...
      'Port', num2str(port_no), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + yinc + reg_d*len;
    port_no = port_no + 1;
  end

  if strcmp(misc, 'on'),
    reuse_block(blk, 'misci', 'built-in/inport', ...
      'Port', num2str(port_no), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  end

  xpos = xpos + xinc + port_w/2;  
  ypos_tmp = ypos + reg_d*len/2; %reset ypos

  %data bus expand
  reuse_block(blk, 'din_expand', 'casper_library_flow_control/bus_expand', ...
    'mode', 'divisions of arbitrary size', ...
    'outputWidth', ['[',num2str(n_bits),']'], ...
    'outputBinaryPt', ['[',num2str(zeros(1, length(n_bits))),']'], ...
    'outputArithmeticType', ['[',num2str(zeros(1, length(n_bits))),']'], ...
    'show_format', 'on', 'outputToWorkspace', 'off', ...
    'variablePrefix', '', 'outputToModelAsWell', 'on', ...
    'Position', [xpos-bus_expand_w/2 ypos_tmp-reg_d*len/2 xpos+bus_expand_w/2 ypos_tmp+reg_d*len/2]);
  add_line(blk, 'din/1', 'din_expand/1');
  ypos_tmp = ypos_tmp + reg_d*len + yinc;

  %enable bus expand
  if strcmp(enable, 'on'),
    reuse_block(blk, 'en_expand', 'casper_library_flow_control/bus_expand', ...
      'mode', 'divisions of equal size', ...
      'outputNum', num2str(length(n_bits)), ...
      'outputWidth', '1', 'outputBinaryPt', '0', ...
      'outputArithmeticType', '2', 'show_format', 'on', ...
      'outputToWorkspace', 'off', 'variablePrefix', '', ...
      'outputToModelAsWell', 'on', ...
      'Position', [xpos-bus_expand_w/2 ypos_tmp-reg_d*len/2 xpos+bus_expand_w/2 ypos_tmp+reg_d*len/2]);
    add_line(blk, 'en/1', 'en_expand/1');
  end

  xpos = xpos + xinc + bus_expand_w/2;

  %delay layer
  ypos_tmp = ypos; %reset ypos 

  for index = 1:len,
    delay_name = ['del',num2str(index)];
    %data
    reuse_block(blk, delay_name, 'xbsIndex_r4/Delay', ...
      'en', enable, 'reg_retiming', reg_retiming, 'latency', num2str(latency), ...
      'Position', [xpos-reg_w/2 ypos_tmp xpos+reg_w/2 ypos_tmp+reg_d-20]);
    ypos_tmp = ypos_tmp + reg_d;

    add_line(blk, ['din_expand/',num2str(index)], [delay_name,'/1']);
    port_index = 2;
    if strcmp(enable, 'on'), add_line(blk, ['en_expand/', num2str(index)],  [delay_name, '/', num2str(port_index)]); end
  end
 
  if strcmp(misc, 'on'),
    reuse_block(blk, 'dmisc', 'xbsIndex_r4/Delay', ...
      'latency', num2str(latency), 'reg_retiming', 'on', ...
      'Position', [xpos-del_w/2 ypos+(((port_no-1)+1/2)*reg_d*len)-del_d/2+(port_no-1)*yinc xpos+del_w/2 ypos+(((port_no-1)+1/2)*reg_d*len)+(port_no-1)*yinc+del_d/2]);
    add_line(blk, 'misci/1', 'dmisc/1');
    ypos_tmp = ypos_tmp + reg_d;
  end
 
  %create bus again
  ypos_tmp = ypos + reg_d*len/2;
  xpos = xpos + xinc + bus_expand_w/2;

  reuse_block(blk, 'dout_compress', 'casper_library_flow_control/bus_create', ...
    'inputNum', num2str(len), ...
    'Position', [xpos-bus_compress_w/2 ypos_tmp-reg_d*len/2 xpos+bus_compress_w/2 ypos_tmp+reg_d*len/2]);
  
  for index = 1:len,
    add_line(blk, ['del',num2str(index),'/1'], ['dout_compress/',num2str(index)]);
  end

  %output port/s
  ypos_tmp = ypos + reg_d*len/2;
  xpos = xpos + xinc + bus_compress_w/2;
  reuse_block(blk, 'dout', 'built-in/outport', ...
    'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  add_line(blk, ['dout_compress/1'], ['dout/1']);
  ypos_tmp = ypos_tmp + yinc + port_d/2;  

  if strcmp(misc, 'on'),
    reuse_block(blk, 'misco', 'built-in/outport', ...
      'Port', '2', ... 
      'Position', [xpos-port_w/2 ypos+(((port_no-1)+1/2)*reg_d*len)+((port_no-1)*yinc)-port_d/2 xpos+port_w/2 ypos+(((port_no-1)+1/2)*reg_d*len)+((port_no-1)*yinc)+port_d/2]);

    add_line(blk, 'dmisc/1', 'misco/1');
  end

  % When finished drawing blocks and lines, remove all unused blocks.
  clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  clog('exiting bus_delay_init', {log_group, 'trace'});

end %function bus_delay_init


