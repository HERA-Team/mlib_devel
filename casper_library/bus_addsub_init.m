%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://www.kat.ac.za                                                      %
%   Copyright (C) 2013 Andrew Martens (andrew@ska.ac.za)                      %
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

function bus_addsub_init(blk, varargin)

  clog('entering bus_addsub_init', {'trace', 'bus_addsub_init_debug'});
  
  defaults = { ...
    'opmode', [0], ...
    'n_bits_a', [8] ,  'bin_pt_a',     [3],   'type_a',   1, ...
    'n_bits_b', [4 ]  ,  'bin_pt_b',     [3],   'type_b',   [1], ...
    'n_bits_out', 8 ,     'bin_pt_out',   [3],   'type_out', [1], ...
    'pipeline_en', 'off', ...
    'pipeline_latency', 0, ...
    'floating_point', 'off', 'float_type', 'single', 'exp_width', 6, 'frac_width', 19, ...  
    'overflow', [1], 'quantization', [0], 'add_implementation', 'fabric core', ...
    'csp_latency', 1, 'async', 'off', 'cmplx', 'on', 'misc', 'on'
  };  
  
  check_mask_type(blk, 'bus_addsub');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  xpos = 50; xinc = 80;
  ypos = 50; yinc = 50;

  port_w = 30; port_d = 14;
  bus_expand_w = 50;
  bus_create_w = 50;
  add_w = 50; add_d = 60;
  del_w = 30; del_d = 20;

  opmode       = get_var('opmode', 'defaults', defaults, varargin{:});
  n_bits_a     = get_var('n_bits_a', 'defaults', defaults, varargin{:});
  bin_pt_a     = get_var('bin_pt_a', 'defaults', defaults, varargin{:});
  type_a       = get_var('type_a', 'defaults', defaults, varargin{:});
  n_bits_b     = get_var('n_bits_b', 'defaults', defaults, varargin{:});
  bin_pt_b     = get_var('bin_pt_b', 'defaults', defaults, varargin{:});
  type_b       = get_var('type_b', 'defaults', defaults, varargin{:});
  n_bits_out   = get_var('n_bits_out', 'defaults', defaults, varargin{:});
  bin_pt_out   = get_var('bin_pt_out', 'defaults', defaults, varargin{:});
  type_out     = get_var('type_out', 'defaults', defaults, varargin{:});
  floating_point    = get_var('floating_point', 'defaults', defaults, varargin{:});
  float_type        = get_var('float_type', 'defaults', defaults, varargin{:});
  exp_width         = get_var('exp_width', 'defaults', defaults, varargin{:});
  frac_width        = get_var('frac_width', 'defaults', defaults, varargin{:});   
  overflow              = get_var('overflow', 'defaults', defaults, varargin{:});
  quantization          = get_var('quantization', 'defaults', defaults, varargin{:});
  add_implementation    = get_var('add_implementation', 'defaults', defaults, varargin{:});
  latency               = get_var('csp_latency', 'defaults', defaults, varargin{:});
  pipeline_en    = get_var('pipeline_en', 'defaults', defaults, varargin{:});
  pipeline_latency      = get_var('pipeline_latency', 'defaults', defaults, varargin{:});
  misc         = get_var('misc', 'defaults', defaults, varargin{:});
  cmplx        = get_var('cmplx', 'defaults', defaults, varargin{:});
  async        = get_var('async', 'defaults', defaults, varargin{:});
 
  delete_lines(blk);
  
  % sanity check for old block that has not been updated for floating point
  if (strcmp(floating_point, 'on')|floating_point == 1)
    floating_point = 1;
  else
    floating_point = 0;
  end
  
  if (strcmp(pipeline_en, 'on'))|(pipeline_en == 1)
    pipeline_en = 'on';
  else
    pipeline_en = 'off';
  end
  
    % Check for floating point
  if floating_point == 1
      float_en = 'on';
      
      if float_type == 2
          float_type_sel = 'custom';

      else
          float_type_sel = 'single';
      end
  else
      float_en = 'off';  
      float_type_sel = 'single';
      exp_width = 8;
      frac_width = 24;
  end
  
  
  
  
  
  % Check if floating point is selected. If so, set the bit widths
  % accordingly. Note: A reinterpret block follows the 
  if floating_point == 1
        preci_type = 'Full';
        
        switch float_type
            case 1
                % Set frac width and exp width for single precision
                frac_width = 24;
                exp_width = 8;
                n_bits_a = repmat((frac_width + exp_width), 1, length(n_bits_a));
                bin_pt_a = 0;
                type_a = 0;
                n_bits_b = repmat((frac_width + exp_width), 1, length(n_bits_b));
                bin_pt_b = 0;
                type_b = 0;
                n_bits_out = repmat((frac_width + exp_width), 1, length(n_bits_out));
                bin_pt_out = 0;
                type_out = 0;
            case 2
                n_bits_a = repmat((frac_width + exp_width), 1, length(n_bits_a));
                bin_pt_a = 0;
                type_a = 0;
                n_bits_b = repmat((frac_width + exp_width), 1, length(n_bits_b));
                bin_pt_b = 0;
                type_b = 0;
                n_bits_out = repmat((frac_width + exp_width), 1, length(n_bits_out));
                bin_pt_out = 0;
                type_out = 0;
        end

  else
        preci_type = 'User defined';
  end  
  
  %default state, do nothing 
  if ((n_bits_a == 0) | (n_bits_b == 0)) & (~floating_point)
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values
    clog('exiting bus_add_init',{'trace', 'bus_addsub_init_debug'});
    return;
  end
 
  lenba = length(n_bits_a); lenpa = length(bin_pt_a); lenta = length(type_a);
  a = [lenba, lenpa, lenta];  

  lenbb = length(n_bits_b); lenpb = length(bin_pt_b); lentb = length(type_b);
  b = [lenbb, lenpb, lentb];  

  lenbo = length(n_bits_out); lenpo = length(bin_pt_out); lento = length(type_out); 
  lenm = length(opmode); lenq = length(quantization); leno = length(overflow);
  o = [lenbo, lenpo, lento, lenm, lenq, leno];

  comps = unique([a, b, o]);
  %if have more than 2 unique components or have two but one isn't 1
  if ((length(comps) > 2) | (length(comps) == 2 && comps(1) ~= 1)),
    clog('conflicting component sizes',{'bus_addsub_init_debug', 'error'});
    return;
  end

  %determine number of components from clues   
  compa = max(a); compb = max(b); compo = max(o); comp = max(compa, compb);

  %need to specify at least one set of input components
  if compo > comp,
    clog('more output components than inputs',{'bus_addsub_init_debug','error'});
    return;
  end

  %replicate items if needed for a input
  n_bits_a    = repmat(n_bits_a, 1, compa/lenba);
  bin_pt_a    = repmat(bin_pt_a, 1, compa/lenpa);
  type_a      = repmat(type_a, 1, compa/lenta);
  
  %replicate items if needed for b input
  n_bits_b    = repmat(n_bits_b, 1, compb/lenbb);
  bin_pt_b    = repmat(bin_pt_b, 1, compb/lenpb);
  type_b      = repmat(type_b, 1, compb/lentb);

  %need to pad output if need more than one
  n_bits_out    = repmat(n_bits_out, 1, comp/lenbo);
  bin_pt_out    = repmat(bin_pt_out, 1, comp/lenpo);
  type_o        = repmat(type_out, 1, comp/lento);
  overflow      = repmat(overflow, 1, comp/leno);
  opmode        = repmat(opmode, 1, comp/lenm);
  quantization  = repmat(quantization, 1, comp/leno);

  %if complex we need to double down on some of these
  if strcmp(cmplx, 'on'),
    compa       = compa*2;
    n_bits_a    = reshape([n_bits_a; n_bits_a], 1, compa);
    bin_pt_a    = reshape([bin_pt_a; bin_pt_a], 1, compa);
    type_a      = reshape([type_a; type_a], 1, compa);
    
    compb       = compb*2;
    n_bits_b    = reshape([n_bits_b; n_bits_b], 1, compb);
    bin_pt_b    = reshape([bin_pt_b; bin_pt_b], 1, compb);
    type_b      = reshape([type_b; type_b], 1, compb);

    comp          = comp*2;
    n_bits_out    = reshape([n_bits_out; n_bits_out], 1, comp);
    bin_pt_out    = reshape([bin_pt_out; bin_pt_out], 1, comp);
    type_o        = reshape([type_o; type_o], 1, comp);
    overflow      = reshape([overflow; overflow], 1, comp);
    opmode        = reshape([opmode; opmode], 1, comp);
    quantization  = reshape([quantization; quantization], 1, comp);
  end

  %input ports
  ypos_tmp = ypos + add_d*compa/2;
  reuse_block(blk, 'a', 'built-in/inport', ...
    'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc + add_d*(compa/2 + compb/2);
  
  reuse_block(blk, 'b', 'built-in/inport', ...
    'Port', '2', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc + add_d*compb/2;

  port_no = 3;
  if strcmp(misc, 'on'),
    reuse_block(blk, 'misci', 'built-in/inport', ...
      'Port', num2str(port_no), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    port_no = port_no+1;
  end
  ypos_tmp = ypos_tmp + yinc;

  xpos = xpos + xinc + port_w/2;  

  if strcmp(async, 'on'),
    xpos = xpos + xinc + port_w/2;  
    reuse_block(blk, 'en', 'built-in/inport', ...
      'Port', num2str(port_no), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  end

  % bus expand
  ypos_tmp = ypos + add_d*compa/2; %reset ypos
  
  if (strcmp(pipeline_en, 'on'))
     
      pipe_a_in_name = 'pipe_a_in'; 
      reuse_block(blk, pipe_a_in_name, 'casper_library_delays/pipeline', ...
        'Position', [95 115 145 135], ...
        'ShowName', 'off', ...
        'csp_latency', num2str(pipeline_latency));
      add_line(blk, 'a/1', [pipe_a_in_name,'/1']); 
      
      reuse_block(blk, 'a_debus', 'casper_library_flow_control/bus_expand', ...
        'mode', 'divisions of arbitrary size', ...
        'outputWidth', ['[',num2str(n_bits_a),']'], ...
        'outputBinaryPt', ['[',num2str(bin_pt_a),']'], ...
        'outputArithmeticType', ['[',num2str(type_a),']'], ...
        'show_format', 'on', 'outputToWorkspace', 'off', ...
        'variablePrefix', '', 'outputToModelAsWell', 'on', ...
        'Position', [xpos-bus_expand_w/2 ypos_tmp-add_d*compa/2 xpos+bus_expand_w/2 ypos_tmp+add_d*compa/2]);
      add_line(blk, [pipe_a_in_name,'/1'], 'a_debus/1'); 
      
      ypos_tmp = ypos_tmp + add_d*(compa/2+compb/2) + yinc;

      pipe_b_in_name = 'pipe_b_in'; 
      reuse_block(blk, pipe_b_in_name, 'casper_library_delays/pipeline', ...
        'Position', [95 115 145 135], ...
        'ShowName', 'off', ...
        'csp_latency', num2str(pipeline_latency));
      add_line(blk, 'b/1', [pipe_b_in_name,'/1']); 
      
      reuse_block(blk, 'b_debus', 'casper_library_flow_control/bus_expand', ...
        'mode', 'divisions of arbitrary size', ...
        'outputWidth', ['[',num2str(n_bits_b),']'], ...
        'outputBinaryPt', ['[',num2str(bin_pt_b),']'], ...
        'outputArithmeticType', ['[',num2str(type_b),']'], ...
        'show_format', 'on', 'outputToWorkspace', 'off', ...
        'variablePrefix', '', 'outputToModelAsWell', 'on', ...
        'Position', [xpos-bus_expand_w/2 ypos_tmp-add_d*compb/2 xpos+bus_expand_w/2 ypos_tmp+add_d*compb/2]);
      add_line(blk, [pipe_b_in_name,'/1'], 'b_debus/1');    
      
      
  else
      reuse_block(blk, 'a_debus', 'casper_library_flow_control/bus_expand', ...
        'mode', 'divisions of arbitrary size', ...
        'outputWidth', ['[',num2str(n_bits_a),']'], ...
        'outputBinaryPt', ['[',num2str(bin_pt_a),']'], ...
        'outputArithmeticType', ['[',num2str(type_a),']'], ...
        'show_format', 'on', 'outputToWorkspace', 'off', ...
        'variablePrefix', '', 'outputToModelAsWell', 'on', ...
        'Position', [xpos-bus_expand_w/2 ypos_tmp-add_d*compa/2 xpos+bus_expand_w/2 ypos_tmp+add_d*compa/2]);
      add_line(blk, 'a/1', 'a_debus/1');
      ypos_tmp = ypos_tmp + add_d*(compa/2+compb/2) + yinc;

      reuse_block(blk, 'b_debus', 'casper_library_flow_control/bus_expand', ...
        'mode', 'divisions of arbitrary size', ...
        'outputWidth', ['[',num2str(n_bits_b),']'], ...
        'outputBinaryPt', ['[',num2str(bin_pt_b),']'], ...
        'outputArithmeticType', ['[',num2str(type_b),']'], ...
        'show_format', 'on', 'outputToWorkspace', 'off', ...
        'variablePrefix', '', 'outputToModelAsWell', 'on', ...
        'Position', [xpos-bus_expand_w/2 ypos_tmp-add_d*compb/2 xpos+bus_expand_w/2 ypos_tmp+add_d*compb/2]);
      add_line(blk, 'b/1', 'b_debus/1');      
  end
  
  ypos_tmp = ypos_tmp + add_d*compa + yinc;

  
  %addsub
  xpos = xpos + xinc + add_w/2;  
  ypos_tmp = ypos; %reset ypos 

  %need addsub per component
  a_src = repmat([1:compa], 1, comp/compa);
  b_src = repmat([1:compb], 1, comp/compb);

  clog(['making ',num2str(comp),' AddSubs'],{'bus_addsub_init_debug'});

 
  for index = 1:comp
    switch type_o(index),
      case 0,
        arith_type = 'Unsigned';
      case 1,
        arith_type = 'Signed';
    end
    switch quantization(index),
      case 0,
        quant = 'Truncate';
      case 1,
        quant = 'Round  (unbiased: +/- Inf)';
    end  
    switch overflow(index),
      case 0,
        of = 'Wrap';
      case 1,
        of = 'Saturate';
      case 2,
        of = 'Flag as error';
    end  
    switch opmode(index),
      case 0,
        m = 'Addition';
        symbol = '+';
      case 1,
        m = 'Subtraction';  
        symbol = '-';
    end  
        
    clog(['output ',num2str(index),': ', ... 
      ' a[',num2str(a_src(index)),'] ',symbol,' b[',num2str(b_src(index)),'] = ', ...
      '(',num2str(n_bits_out(index)), ' ', num2str(bin_pt_out(index)),') ' ...
      ,arith_type,' ',quant,' ', of], ...
      {'bus_addsub_init_debug'}); 

    if strcmp(add_implementation, 'behavioral HDL'),
      use_behavioral_HDL = 'on';
      hw_selection = 'Fabric';
    elseif strcmp(add_implementation, 'fabric core'),
      use_behavioral_HDL = 'off';
      hw_selection = 'Fabric';
    elseif strcmp(add_implementation, 'DSP48 core'),
      use_behavioral_HDL = 'off';
      hw_selection = 'DSP48';
    end

    add_name = ['addsub',num2str(index)]; 
    reuse_block(blk, add_name, 'xbsIndex_r4/AddSub', ...
      'mode', m, 'latency', num2str(latency), ...
      'en', async, 'precision', preci_type, ...
      'n_bits', num2str(n_bits_out(index)), 'bin_pt', num2str(bin_pt_out(index)), ...  
      'arith_type', arith_type, 'quantization', quant, 'overflow', of, ... 
      'pipelined', 'on', 'use_behavioral_HDL', use_behavioral_HDL, 'hw_selection', hw_selection, ... 
      'Position', [xpos-add_w/2 ypos_tmp xpos+add_w/2 ypos_tmp+add_d-20]);
    ypos_tmp = ypos_tmp + add_d;
  
    reintp_a_name = ['reintp_a',num2str(index)]; 
    reintp_b_name = ['reintp_b',num2str(index)]; 
    
    reuse_block(blk, reintp_a_name, 'xbsIndex_r4/Reinterpret', ...
      'force_arith_type', 'on', ...
      'arith_type', 'Floating-point', ...
      'force_bin_pt', 'on', ...
      'bin_pt',num2str(frac_width), ...
      'Position', [xpos-add_w/2 ypos_tmp xpos+add_w/2 ypos_tmp+add_d-20]);
  
  
    reuse_block(blk, reintp_b_name, 'xbsIndex_r4/Reinterpret', ...
      'force_arith_type', 'on', ...
      'arith_type', 'Floating-point', ...
      'force_bin_pt', 'on', ...
      'bin_pt',num2str(frac_width), ...
      'Position', [xpos-add_w/2 ypos_tmp xpos+add_w/2 ypos_tmp+add_d-20]);
    ypos_tmp = ypos_tmp + add_d;
    
    if floating_point
        
        add_line(blk, ['a_debus/',num2str(a_src(index))], [reintp_a_name,'/1']);
        add_line(blk, ['b_debus/',num2str(b_src(index))], [reintp_b_name,'/1']);
        
%        if (strcmp(pipeline_intfce_en, 'on'))
%             pipe_a_in_name = ['pipe_a_in',num2str(index)]; 
%             pipe_b_in_name = ['pipe_b_in',num2str(index)]; 
%             
%             reuse_block(blk, pipe_a_in_name, 'casper_library_delays/pipeline', ...
%             'Position', [95 115 145 135], ...
%             'ShowName', 'off', ...
%             'latency', num2str(pipeline_latency));
%             add_line(blk, [reintp_a_name,'/1'], [pipe_a_in_name,'/1']); 
%             add_line(blk, [pipe_a_in_name,'/1'], [add_name,'/1']);            
% 
%             reuse_block(blk, pipe_b_in_name, 'casper_library_delays/pipeline', ...
%             'Position', [95 115 145 135], ...
%             'ShowName', 'off', ...
%             'latency', num2str(pipeline_latency));
%             add_line(blk, [reintp_b_name,'/1'], [pipe_b_in_name,'/1']);
%             add_line(blk, [pipe_b_in_name,'/1'], [add_name,'/2']);
%        else
            %add_line(blk, ['a_debus/',num2str(a_src(index))], [reintp_a_name,'/1']);
            %add_line(blk, ['b_debus/',num2str(b_src(index))], [reintp_b_name,'/1']);   
            add_line(blk, [reintp_a_name,'/1'], [add_name,'/1']);
            add_line(blk, [reintp_b_name,'/1'], [add_name,'/2']);     
%        end
        
    else
        add_line(blk, ['a_debus/',num2str(a_src(index))], [add_name,'/1']);
        add_line(blk, ['b_debus/',num2str(b_src(index))], [add_name,'/2']);        
    end
    
    if strcmp(async, 'on')
      add_line(blk, 'en/1', [add_name,'/3']);
    end

  end %for

  ypos_tmp = ypos + add_d*(compb+compa) + 2*yinc;
  if strcmp(misc, 'on'),
    reuse_block(blk, 'dmisc', 'xbsIndex_r4/Delay', ...
      'latency', num2str(latency), ...
      'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
    add_line(blk, 'misci/1', 'dmisc/1');
  end
  ypos_tmp = ypos_tmp + yinc;
  
  if strcmp(async, 'on'),
    reuse_block(blk, 'den', 'xbsIndex_r4/Delay', ...
      'latency', num2str(latency), ...
      'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
    add_line(blk, 'en/1', 'den/1');
  end

  xpos = xpos + xinc + add_d/2;

  %bus create 
  ypos_tmp = ypos + add_d*comp/2; %reset ypos
 
  reuse_block(blk, 'op_bussify', 'casper_library_flow_control/bus_create', ...
    'inputNum', num2str(comp), ...
    'Position', [xpos-bus_create_w/2 ypos_tmp-add_d*comp/2 xpos+bus_create_w/2 ypos_tmp+add_d*comp/2]);
  
    if floating_point
      for idx = 1:comp,
        reintp_out_name = ['reintp_out',num2str(idx)]; 
        
        reuse_block(blk, reintp_out_name, 'xbsIndex_r4/Reinterpret', ...
          'force_arith_type', 'on', ...
          'arith_type', 'Unsigned', ...
          'force_bin_pt', 'on', ...
          'bin_pt',num2str(0), ...
          'Position', [xpos-add_w/2 ypos_tmp xpos+add_w/2 ypos_tmp+add_d-20]);
        add_line(blk, ['addsub',num2str(idx),'/1'], [reintp_out_name,'/1']);  
        
%         if (strcmp(pipeline_intfce_en, 'on'))
%            pipe_name = ['pipeline',num2str(idx)]; 
%            
%            reuse_block(blk, pipe_name, 'casper_library_delays/pipeline', ...
%            'Position', [95 115 145 135], ...
%            'ShowName', 'off', ...
%            'csp_latency', num2str(pipeline_latency));
%            add_line(blk, [reintp_out_name,'/1'], [pipe_name,'/1']);  
%            add_line(blk, [pipe_name,'/1'], ['op_bussify/',num2str(idx)]);
%         else
            add_line(blk, [reintp_out_name,'/1'], ['op_bussify/',num2str(idx)]);
%         end
        


        
      end
    else
      for idx = 1:comp,
        add_line(blk, ['addsub',num2str(idx),'/1'], ['op_bussify/',num2str(idx)]);
      end
    end
    

  %output port/s
  ypos_tmp = ypos + add_d*comp/2;
  xpos = xpos + xinc + bus_create_w/2;
  
  if (strcmp(pipeline_en, 'on'))
    pipe_name = 'pipeline_out';
    reuse_block(blk, pipe_name, 'casper_library_delays/pipeline', ...
       'Position', [95 115 145 135], ...
       'ShowName', 'off', ...
       'csp_latency', num2str(pipeline_latency));
    add_line(blk, ['op_bussify/1'], [pipe_name,'/1']); 
    
    reuse_block(blk, 'dout', 'built-in/outport', ...
        'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    add_line(blk, [pipe_name,'/1'], ['dout/1']);
      
  else
      reuse_block(blk, 'dout', 'built-in/outport', ...
        'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
      add_line(blk, ['op_bussify/1'], ['dout/1']);      
  end
  
  ypos_tmp = ypos_tmp + yinc + port_d;  

  ypos_tmp = ypos + add_d*(compb+compa) + 2*yinc;
  port_no = 2;
  if strcmp(misc, 'on'),
    reuse_block(blk, 'misco', 'built-in/outport', ...
      'Port', num2str(port_no), ... 
      'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);

    add_line(blk, 'dmisc/1', 'misco/1');
    port_no = port_no+1;
  end
  ypos_tmp = ypos_tmp + yinc;
  
  if strcmp(async, 'on'),
    reuse_block(blk, 'dvalid', 'built-in/outport', ...
      'Port', num2str(port_no), ... 
      'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);

    add_line(blk, 'den/1', 'dvalid/1');
  end
  
  % When finished drawing blocks and lines, remove all unused blocks.
  clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  clog('exiting bus_addsub_init', {'bus_addsub_init_debug', 'trace'});

end %function bus_addsub_init

