%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://seti.ssl.berkeley.edu/casper/                                      %
%   Copyright (C) 2013 David MacMahon
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

% This function updates oldblk using the most recent library version.
% Mask parameters are copied over whenever possible.
function update_casper_block(oldblk)

  % Clear last dumped exception to ensure that all exceptions are shown.
  dump_exception([]);

  % Check link status
  link_status = get_param(oldblk, 'StaticLinkStatus');

  % Inactive link (link disabled but not broken) so get AncestorBlock
  if strcmp(link_status, 'inactive')
    srcblk = get_param(oldblk, 'AncestorBlock');

  % Resolved link (link in place) so get ReferenceBlock
  elseif strcmp(link_status, 'resolved')
    srcblk = get_param(oldblk, 'ReferenceBlock');

  % Unresolved link (bad link) so get SourceBlock
  elseif strcmp(link_status, 'unresolved')
    srcblk = get_param(oldblk, 'SourceBlock');

  % Else, not supported
  else
    fprintf('%s is not a linked library block\n', oldblk);
    return;
  end

  % Map srcblk through casper_library_forwarding_table in case it's a really
  % old name.
  srcblk = casper_library_forwarding_table(srcblk);
  % Special case handling
  switch srcblk
  % Special handling for deprecated "edge" blocks
  case {'casper_library_misc/edge', ...
        'casper_library_misc/negedge', ...
        'casper_library_misc/posedge'}
    % Get mask params for edge_detect block
    switch srcblk
    case 'casper_library_misc/edge'
      params = {'edge', 'Both', 'polarity', 'Active High'};
    case 'casper_library_misc/negedge'
      params = {'edge', 'Falling', 'polarity', 'Active High'};
    case 'casper_library_misc/posedge'
      params = {'edge', 'Rising', 'polarity', 'Active High'};
    end
    % Make sure casper_library_misc block diagram is loaded
    if ~bdIsLoaded('casper_library_misc')
      fprintf('loading library casper_library_misc\n');
      load_system('casper_library_misc');
    end
    % Get position and orientation of oldblk
    p = get_param(oldblk, 'position');
    o = get_param(oldblk, 'orientation');
    % Delete oldblk
    delete_block(oldblk);
    % Add edge detect block using oldblk's name
    add_block('casper_library_misc/edge_detect', oldblk, ...
        'orientation', o, ...
        'position', p, ...
        params{:});
    % Done!
    return
  case {'xps_library/XSG core config', ...
        'xps_library/XSG_core_config', ...
        'xps_library/xsg_core_config'}
    % Get hw_sys parameter to handle SNAP/SNAP2/VCU118 platforms
    hw_sys = get_param(oldblk, 'hw_sys');
    platform = split(hw_sys, ':');
    srcblk = ['xps_library/Platforms/' char(platform(1))];

  case 'xps_library/IO/gpio'
    % set the real io_group parameter, now named 'io_group_real'
    % this is a hack in order to deprecate the old io_group parameters that had
    % platform names in the parameter like ROACH:led, so that a user's model
    % will hold its parameter when updating to the new xps_library
    cursys = oldblk;
    % check to see if the io_group params have already been forwarded
    if (strcmp(get_param(cursys, 'io_group_params_forwarded'), 'off'))
      io_group_string = get_param(cursys, 'io_group');
      switch io_group_string
        case {'ROACH:led', 'ROACH2:led'}
            set_param(cursys, 'io_group_real', 'led');
        case {'ROACH:gpioa', 'ROACH:gpioa_oe_n', 'ROACH:gpiob', ...
              'ROACH:gpiob_oe_n', 'ROACH2:gpio'}
            set_param(cursys, 'io_group_real', 'gpio');
        case 'ROACH2:sync_in'
            set_param(cursys, 'io_group_real', 'sync_in');
        case 'ROACH2:sync_out'
            set_param(cursys, 'io_group_real', 'sync_out');
        case {'ROACH:zdok0', 'ROACH2:zdok0'}
            set_param(cursys, 'io_group_real', 'zdok0');
        case {'ROACH:zdok1', 'ROACH2:zdok1'}
            set_param(cursys, 'io_group_real', 'zdok1');
        case {'ROACH:aux0_clk' 'ROACH:aux1_clk' 'ROACH2:aux_clk'}
            set_param(cursys, 'io_group_real', 'aux_clk_diff');
        case 'custom:custom'
            set_param(cursys, 'io_group_real', 'custom');
        otherwise
            % strip off parameter and insert to custom io_group param
            set_param(cursys, 'io_group_real', 'custom');
            customValue = strsplit(io_group_string, ':');
            set_param(cursys, 'io_group_custom', char(customValue(2)));
      end
      % update hidden checkbox to indicate the io_group_params have now been forwarded
      set_param(cursys, 'io_group_params_forwarded', 'on');
    end
  end % special deprecated handling

  % Make sure srcblk's block diagram is loaded
  srcblk_bd = regexprep(srcblk, '/.*', '');
  if ~bdIsLoaded(srcblk_bd)
    fprintf('loading library %s\n', srcblk_bd);
    load_system(srcblk_bd);
  end
  
  % Get old and new mask names
  oldblk_mask_names = get_param(oldblk, 'MaskNames');
  newblk_mask_names = get_param(srcblk, 'MaskNames');

  % Save warning backtrace state then disable backtrace
  bt_state = warning('query', 'backtrace');
  warning off backtrace;

  % Try to populate newblk's mask parameters from oldblk
  newblk_params = {};
  for k = 1:length(newblk_mask_names)
    % If oldblk has the same mask parameter name
    if find(strcmp(oldblk_mask_names, newblk_mask_names{k}))
      % Add to new block parameters
      newblk_params{end+1} = newblk_mask_names{k};
      newblk_params{end+1} = get_param(oldblk, newblk_mask_names{k});
    elseif(strcmp(newblk_mask_names{k},'csp_latency'))
      %Handle renaming latency mask parameter to csp_latency. This was put
      %in to handle update from R2016 to R2018b
      newblk_params{end+1} = 'csp_latency';
      mask = Simulink.Mask.get(oldblk);
      latParam = mask.getParameter('latency');
      newblk_params{end+1} = latParam.Value;  
    else
      type = get_param(oldblk, 'MaskType');
      if ~isempty(type)
        type = [type ' '];
      end
      link = sprintf('<a href="matlab:hilite_system(''%s'')">%s</a>', ...
          oldblk, oldblk);
      warning('old %sblock %s did not have mask parameter %s', ...
          type, link, newblk_mask_names{k});
    end
  end

  % Restore warning backtrace state
  warning(bt_state);

  % In addition to copying the mask parameters, we also copy the UserData
  % parameter, if it looks like it was set by save_state.  We clear the state
  % field to ensure that the block gets re-initialized by the mask init script.
  ud = get_param(oldblk, 'UserData');
  if isstruct(ud) && isfield(ud, 'state') && isfield(ud, 'parameters')
    ud.state = [];
    newblk_params{end+1} = 'UserData';
    newblk_params{end+1} = ud;
  end

  % Get position and orientation of oldblk.
  p = get_param(oldblk, 'position');
  o = get_param(oldblk, 'orientation');

  % The new block must be added directly to the same parent subsystem since
  % some of its mask parameter values might use variable names that only exist
  % in the scope of the parent subsystem's mask.  Adding a block to the parent
  % subsystem can cause the parent subsystem's mask initialization code to run
  % which may call "clean_blocks" which would see the block we're adding as
  % unconnected and delete it!  To avoid this, we temporarily set the parent
  % subsystem's mask initialization parameter to an empty string, then restore
  % the original setting after adding the block.
  parent_mask_init = '';
  parent = get_param(oldblk, 'Parent');
  % If parent is a block (i.e. NOT a block diagram)
  if strcmp(get_param(parent, 'Type'), 'block')
    try
      parent_mask_init = get_param(parent, 'MaskInitialization');
      set_param(parent, 'MaskInitialization', '');
    end
  end

  % Delete old block
  delete_block(oldblk);

  % Add source block using new params.  Note that we position the new block at
  % (0,0) with size of (0,0) to minimize the possibility of it connecting to
  % stray unconnected lines before the mask init script runs (which may change
  % the number of ports).
  add_block(srcblk, oldblk, ...
      'position', [0,0,0,0], ...
      'orientation', o, ...
      newblk_params{:});

  % Move block into position.  Some blocks (e.g.  software register blocks) need
  % to be resized to get port spacing correct and sometimes the block needs a
  % little nudge one way or the other to connect to existing lines.  That's why
  % we set the position multiple times.
  set_param(oldblk, ...
      'position', p, ...
      'position', p + [-1,  0,  0,  0], ...
      'position', p, ...
      'position', p + [ 1,  0,  0,  0], ...
      'position', p, ...
      'position', p + [ 0, -1,  0,  0], ...
      'position', p, ...
      'position', p + [ 0,  1,  0,  0], ...
      'position', p, ...
      'position', p + [-1, -1,  2,  2], ...
      'position', p);

  % Restore parent's mask init setting

  if ~isempty(parent_mask_init)
    %if(strcmp(srcblk,'casper_library_bus/bus_addsub'))
    %    parent_mask_init = strrep(parent_mask_init,'''latency'',','''csp_latency'',');
    %    set_param(parent, 'MaskInitialization', parent_mask_init);
    %end
    if(~strcmp(srcblk,'casper_library_bus/bus_convert') && ~strcmp(srcblk,'casper_library_bus/bus_addsub'))
        set_param(parent, 'MaskInitialization', parent_mask_init);
    end
  end
end
