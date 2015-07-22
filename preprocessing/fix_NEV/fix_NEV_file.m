function [NEV_codes_new, NEV_times_new, rewarded_trials, NEV_codes_old, NEV_times_old, NEV_split]=fix_NEV_file(NEV_file_name, fixing, trial_template, throw_high_byte)
%FIX_NEV_FILE_NEW fix NEV file based on Cortex file.
%   fix_time_count is a vector recording number of fixes applied to each
%   trial.
%   Yimeng Zhang, 09/17/2013
%   Pittsburgh, PA



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%read NEVfile
% NEV=readNEV_c(NEV_file_name);
% 
% sync_channel = 0;
% sync_channel_idx = NEV(:,1)==sync_channel;
% 
% NEV_codes_old=NEV(sync_channel_idx,2);
% NEV_times_old=NEV(sync_channel_idx,3);

import fix_NEV.split_trial_NEV

if nargin < 4
    throw_high_byte = true;
end

NEV_NMPK=openNEV(NEV_file_name,'nosave','nomat','noread'); % for new NPMK
NEV_codes_old=double(NEV_NMPK.Data.SerialDigitalIO.UnparsedData(1:end));%codes
NEV_times_old=double(NEV_NMPK.Data.SerialDigitalIO.TimeStampSec(1:end));%time stamps of codes

NEV_codes_old = NEV_codes_old(:);

if throw_high_byte % only read low byte
    NEV_codes_old = rem(NEV_codes_old,256);
end

NEV_times_old = NEV_times_old(:);


% if isequal(NEV_codes_old,NEVcodes(:)) && isequal(NEV_times_old,NEVtimes(:))
%     fprintf('all match!\n');
% end

%% start, stop, reward codes for splitting and getting good trials.
startcode = double(template.getStartcode());
stopcode = double(template.getStopcode());
rewardcode = double(template.getRewardcode());


NEV_split = split_trial_NEV(NEV_codes_old, startcode, stopcode);


NEV_codes_new = {};
NEV_times_new = {};
rewarded_trials = [];



for i = 1:length(NEV_split)
    fprintf('fixing trial %d...\n',i);
    % fetch next trial
    nev_trial = ... % nev_trial is a Nx2 matrix, first column code, second column time.
        [NEV_codes_old(NEV_split{i}.start:NEV_split{i}.end), ...
        NEV_times_old(NEV_split{i}.start:NEV_split{i}.end)];
    % it's a rewarded trial... let's use fix_NEV_trial_TM!
    if ismember(rewardcode, nev_trial(:,1))
        fprintf('fixing a perhaps good trial...\n');
        fixable = true; % is this indeed a good trial that can be fixed.
        if fixing
            [nev_trial_new, fixable] = fix_NEV_trial_TM(nev_trial, trial_template);
        end
       
        if fixable
            rewarded_trials(end+1) = i;
            % put them back as cells... or I need some other formats?
            if fixing % use the fixed trials.
                NEV_codes_new{end+1} = nev_trial_new(:,1);
                NEV_times_new{end+1} = nev_trial_new(:,2);
            else % just assume old trials are good enough.
                NEV_codes_new{end+1} = nev_trial(:,1);
                NEV_times_new{end+1} = nev_trial(:,2);
            end
        end
    end
end

NEV_codes_new = NEV_codes_new(:);
NEV_times_new = NEV_times_new(:);
rewarded_trials = rewarded_trials(:);

fprintf('in total, %d rewarded trials from NEV\n', length(rewarded_trials));
%pause;
end