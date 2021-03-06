function adc5g_init(blk, varargin)
% Initialize and configure the ASIA 5 GSps ADC

% Declare defaults to be used throughout
defaults = {...
    'input_mode', 'Two-channel -- A&C',...
    'demux', '1:1',...
    'adc_clk_rate', 450,...
    'adc_bit_width', 8,...
    'adc_brd', 'ZDOK 0',...
    'using_ctrl', 'on',...
    'test_ramp', 'off'};

% Check to see if mask parameters have changed
if same_state(blk, 'gcb', gcb, 'defaults', defaults, varargin{:}), return, end
check_mask_type(blk, 'adc5g');
munge_block(blk, varargin{:});

% Get all the mask parameters and form the needed derivatives
input_mode = get_var('input_mode', 'defaults', defaults, varargin{:});
demux = get_var('demux', 'defaults', defaults, varargin{:});
adc_clk_rate = get_var('adc_clk_rate', 'defaults', defaults, varargin{:});
adc_bit_width = get_var('adc_bit_width', 'defaults', defaults, varargin{:});
adc_brd = get_var('adc_brd', 'defaults', defaults, varargin{:});
using_ctrl = get_var('using_ctrl', 'defaults', defaults, varargin{:});

% Determine proper input names
if strcmp(input_mode, 'One-channel -- A'),
    inputs = {'a'};
elseif strcmp(input_mode, 'One-channel -- C'),
    inputs = {'c'};
elseif strcmp(input_mode, 'Two-channel -- A&C'),
    inputs = {'a', 'c'};
else 
    error(['Unsupported input mode: ',input_mode]);
end
port_names = {...
    'user_data_i0',...
    'user_data_i1',...
    'user_data_i2',...
    'user_data_i3',...
    'user_data_i4',...
    'user_data_i5',...
    'user_data_i6',...
    'user_data_i7',...
    'user_data_q0',...
    'user_data_q1',...
    'user_data_q2',...
    'user_data_q3',...
    'user_data_q4',...
    'user_data_q5',...
    'user_data_q6',...
    'user_data_q7'};
samples = length(port_names)/length(inputs);
sample_sep = 60;

% Remove all lines, will be redrawn later
delete_lines(blk);

% Load the need libraries (just in case)
%load_system('simulink');
%load_system('simulink/Discrete');
%load_system('dspsigops');

% First, loop over the inputs
for i=0:length(inputs)-1
    
    curr_x = 30;
    % Draw the input with appropriate name
    reuse_block(blk, [...
        'sim_', inputs{i+1}],...
        'built-in/inport',...
        'Position', [curr_x 100+i*sample_sep*samples,...
                     curr_x+30 116+i*sample_sep*samples],...
        'Port', num2str(i+1));
    
    curr_x = curr_x + 60;
    % Set the input gains and connect to inports
    reuse_block(blk, [...
        'gain_', inputs{i+1}], ...
        'built-in/Gain',...
        'Position', [curr_x 100+i*sample_sep*samples,...
                     curr_x+30 116+i*sample_sep*samples],...
        'Gain', num2str(2^(adc_bit_width-1)));
    add_line(blk, ['sim_', inputs{i+1}, '/1'],...
                  ['gain_', inputs{i+1}, '/1']);
              
    curr_x = curr_x + 60;
    % Add the bias blocks and connect to the gains
    reuse_block(blk, [...
        'bias_', inputs{i+1}], ...
        'built-in/Bias',...
        'Position', [curr_x 100+i*sample_sep*samples,...
                     curr_x+30 116+i*sample_sep*samples],...
        'Bias', num2str(2^(adc_bit_width-1)));
    add_line(blk, ['gain_', inputs{i+1}, '/1'],...
                  ['bias_', inputs{i+1}, '/1']);
    
    % Now, loop over the sample streams
    for j=0:samples-1
        
        curr_x = curr_x + 120;
        try
            use_downsample = 1;
            % Add downsample blocks
            reuse_block(blk, [...
                'downsample_', inputs{i+1}, num2str(j)], ...
                'dspsigops/Downsample',...
                'Position', [curr_x 100+i*sample_sep*samples+j*sample_sep,...
                             curr_x+30 116+i*sample_sep*samples+j*sample_sep],...
                'N', num2str(samples),...
                'phase', num2str(j),...
                'ic', '0');

            % Try to set options required for Downsample block of newer DSP blockset
            % versions, but not available in older versions.
            try
              set_param([blk, '/downsample_', inputs{i+1}, num2str(j)], ...
                'InputProcessing', 'Elements as channels (sample based)', ...
                'RateOptions', 'Allow multirate processing');
            catch
            end;

            add_line(blk, ['bias_', inputs{i+1}, '/1'],...
                          ['downsample_', inputs{i+1}, num2str(j), '/1']);
                  
            curr_x = curr_x + 80;
            % Add delay blocks to align the samples
            if j==0
                delay = 2;
            else
                delay = 1;
            end
            reuse_block(blk, [...
                'delay_', inputs{i+1}, num2str(j)], ...
                'simulink/Discrete/Integer Delay',...
                'Position', [curr_x 100+i*sample_sep*samples+j*sample_sep,...
                             curr_x+30 116+i*sample_sep*samples+j*sample_sep],...
                'NumDelays', num2str(delay),...
                'vinit', '0');
            add_line(blk, ['downsample_', inputs{i+1}, num2str(j), '/1'],...
                          ['delay_', inputs{i+1}, num2str(j), '/1']);
        catch err
            warning('Failed to add Downsample blocks to ADC5G. This could be because you are missing the DSP toolbox.')
            use_downsample = 0;
        end
            
        curr_x = curr_x + 80;
        % Add the gateway-in ports, should match the netlist port names
        port_name = clear_name([gcb, '_', port_names{i*samples + j + 1}]);
        reuse_block(blk,...
            port_name,...
            'xbsIndex_r4/Gateway In',...
            'Position', [curr_x 100+i*sample_sep*samples+j*sample_sep,...
                         curr_x+80 116+i*sample_sep*samples+j*sample_sep],...
            'arith_type', 'Unsigned',...
            'n_bits', num2str(adc_bit_width),...
            'bin_pt', '0',...
            'overflow', 'Wrap',...
            'quantization', 'Truncate');
        if use_downsample
            add_line(blk, ['delay_', inputs{i+1}, num2str(j), '/1'],...
                          [port_name, '/1']);
        else
            add_line(blk, ['bias_', inputs{i+1}, '/1'],...
                          [port_name, '/1']);
        end
        
        curr_x = curr_x + 160;
        % Now, let's do the output ports!
        reuse_block(blk,...
            [inputs{i+1}, num2str(j)],...
            'built-in/outport',...
            'Position', [curr_x 100+i*sample_sep*samples+j*sample_sep,...
                         curr_x+30 116+i*sample_sep*samples+j*sample_sep],...
            'Port', num2str(i*samples + j + 1));
        add_line(blk, [port_name, '/1'],...
                      [inputs{i+1}, num2str(j), '/1']);
    
        curr_x = curr_x - 440; % undo all x changes
        
    end
    
end

curr_x = 30;
% Finally, let's do the sync stream
% First, the input port
reuse_block(blk,...
    'sim_sync',...
    'built-in/inport',...
    'Position', [curr_x 160+i*sample_sep*samples+j*sample_sep,...
                 curr_x+30 176+i*sample_sep*samples+j*sample_sep],...
    'Port', num2str(i+2));

curr_x = curr_x + 60;
% Now the gateway-in for the sync
sync_name = clear_name([gcb, '_', 'sync']);
reuse_block(blk,...
	sync_name,...
    'xbsIndex_r4/Gateway In',...
    'Position', [curr_x 160+i*sample_sep*samples+j*sample_sep,...
                 curr_x+80 176+i*sample_sep*samples+j*sample_sep],...
    'arith_type', 'Boolean');
add_line(blk, 'sim_sync/1', [sync_name, '/1']);

curr_x = curr_x + 160;
% And lastly the output port
reuse_block(blk,...
    'sync_out',...
    'built-in/outport',...
    'Position', [curr_x 160+i*sample_sep*samples+j*sample_sep,...
                 curr_x+30 176+i*sample_sep*samples+j*sample_sep],...
    'Port', num2str(i*samples + j + 2));
add_line(blk, [sync_name, '/1'], 'sync_out/1');

clean_blocks(blk);
save_state(blk, 'gcb', gcb, 'defaults', defaults, varargin{:});
