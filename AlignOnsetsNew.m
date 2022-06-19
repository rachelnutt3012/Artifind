function [est_onsets, elec_id, premanual_onsets] = AlignOnsetsNew(data, est_onsets, elec_id)

%% realign each onset to local maximum/minimum

% look around each onset (i) for the closest local maximum/minimum
%if chosen_elecs(i) is even numbered, then we need to look for local max
% if odd numbered, then we need to look for local min

for i = 1:length(est_onsets)
    if est_onsets(i)-150 < 1
        artifact_segment = data(elec_id(i),1:est_onsets(i)+150);
        val = est_onsets(i);
    elseif est_onsets(i)+150 > size(data,2)
        artifact_segment = data(elec_id(i),est_onsets(i)-150:size(data,2));
        val = 150;
    else
        artifact_segment = data(elec_id(i),est_onsets(i)-150:est_onsets(i)+150);
        val = 150;
    end
    [~,locs] = findpeaks(artifact_segment,'MinPeakProminence',0.5);
    if isempty(locs) %if there are no local maxima, then this isn't a valid onset
        est_onsets(i) = NaN;
    else
        [~,idx] = min(abs(locs-val)); %find the peak closest to original onset location
        est_onsets(i) = est_onsets(i)+(locs(idx)-val);
    end
end
elec_id(isnan(est_onsets)) = [];
est_onsets(isnan(est_onsets)) = [];
%% auto identify onsets that are way too short
errors_short = find(diff(est_onsets) < (mean(diff(est_onsets)) - std(diff(est_onsets))*2.5)); %greater than 3 std below the mean
while ~isempty(errors_short)
    elec_id(errors_short(1)+1) = [];
    est_onsets(errors_short(1)+1) = []; %add the one as the diff function gives the diff between 1 and 2 in cell 1, when value 2 will be the problem
    errors_short = find(diff(est_onsets) < (mean(diff(est_onsets)) - std(diff(est_onsets))*2.5));
end
%% auto identify missing onsets
errors_long = find(diff(est_onsets) > (mean(diff(est_onsets)) + std(diff(est_onsets))*2.5));
new_onsets = zeros(1,length(errors_long));
for i = 1:length(errors_long)
    new_onsets(i) = round(est_onsets(errors_long(i)) + mean(diff(est_onsets)));
end
new_elec_id = zeros(1,length(new_onsets));
for i = 1:length(new_onsets)
    [~,loc] = min(abs(est_onsets - new_onsets(i)));
    new_elec_id(i) = elec_id(loc);
end
elec_id = [elec_id new_elec_id];
est_onsets = [est_onsets new_onsets];
[est_onsets,order] = sort(est_onsets);
elec_id = elec_id(order);
%% rerun alignment as above
for i = 1:length(est_onsets)
    if est_onsets(i)-150 < 1
        artifact_segment = data(elec_id(i),1:est_onsets(i)+150);
        val = est_onsets(i);
    elseif est_onsets(i)+150 > size(data,2)
        artifact_segment = data(elec_id(i),est_onsets(i)-150:size(data,2));
        val = 150;
    else
        artifact_segment = data(elec_id(i),est_onsets(i)-150:est_onsets(i)+150);
        val = 150;
    end
    [~,locs] = findpeaks(artifact_segment,'MinPeakProminence',0.5);
    if isempty(locs) %if there are no local maxima, then this isn't a valid onset
        est_onsets(i) = NaN;
    else
        [~,idx] = min(abs(locs-val));
        est_onsets(i) = est_onsets(i)+(locs(idx)-val);
    end
end
elec_id(isnan(est_onsets)) = [];
est_onsets(isnan(est_onsets)) = [];
[est_onsets,order] = sort(est_onsets);
elec_id = elec_id(order);
premanual_onsets = est_onsets;

%% optional manual correction
val = input('Would you like to scroll manually through your data and look for missing onsets? 1 = Yes; 0 = No: ');
if val == 1
    n = length(findobj('type','figure'));
    figure(n+1);
    final_onset_id = length(est_onsets);
    elec_changed = find(diff(elec_id) ~= 0);
    for segment = 1:length(elec_changed)+1
        fprintf('Segment %i/%i\n', segment, length(elec_changed)+1);
        if  isempty(elec_changed)
            segment_start = 1;
            segment_end = final_onset_id;
        elseif segment == 1
            segment_start = 1;
            segment_end = elec_changed(segment);
        elseif segment == length(elec_changed)+1
            segment_start = elec_changed(segment-1)+1;
            segment_end = final_onset_id;
        else
            segment_start = elec_changed(segment-1)+1;
            segment_end = elec_changed(segment);
        end
        segment_onsets = est_onsets(segment_start:segment_end);
        cla reset
        plot(data(unique(elec_id(segment_start:segment_end)),:)); hold on; plot(segment_onsets, data(unique(elec_id(segment_start:segment_end)),segment_onsets),'xr','MarkerSize',12);
        xlim([segment_onsets(1) segment_onsets(end)]);
        points = datacursormode;
        disp('Select all missing onsets from the window in view then press enter to continue');
        pause
        manual_pnts = getCursorInfo(points);
        locs = [];
        for i = 1:size(manual_pnts,2)
            locs(1,i) = manual_pnts(i).Position(1);
        end
        est_onsets = [est_onsets locs];
        elec_id = [elec_id repelem(unique(elec_id(segment_start:segment_end)),length(locs))];
    end
    [est_onsets,order] = sort(est_onsets);
    elec_id = elec_id(order);
    close(figure(n+1));
end
val = input('Would you like to scroll manually through your data and look for false onsets? 1 = Yes; 0 = No: ');
if val == 1
    n = length(findobj('type','figure'));
    figure(n+1);
    final_onset_id = length(est_onsets);
    false_peak = [];
    elec_changed = find(diff(elec_id) ~= 0);
    for segment = 1:length(elec_changed)+1
        fprintf('Segment %i/%i\n', segment, length(elec_changed)+1);
        if  isempty(elec_changed)
            segment_start = 1;
            segment_end = final_onset_id;
        elseif segment == 1
            segment_start = 1;
            segment_end = elec_changed(segment);
        elseif segment == length(elec_changed)+1
            segment_start = elec_changed(segment-1)+1;
            segment_end = final_onset_id;
        else
            segment_start = elec_changed(segment-1)+1;
            segment_end = elec_changed(segment);
        end
        segment_onsets = est_onsets(segment_start:segment_end);
        cla reset
        plot(data(unique(elec_id(segment_start:segment_end)),:)); hold on; plot(segment_onsets, data(unique(elec_id(segment_start:segment_end)),segment_onsets),'xr','MarkerSize',12);
        xlim([segment_onsets(1) segment_onsets(end)]);
        title('Choose any wrong onsets for deletion');
        points = datacursormode;
        disp('Manually select any wrongly labelled peaks as accurately as possible. Hold shift to select multiple peaks')
        disp('Press enter when finished')
        pause
        manual_pnts = getCursorInfo(points);
        locs = [];
        for i = 1:size(manual_pnts,2)
            locs(1,i) = manual_pnts(i).Position(1);
        end
        for i = 1:length(locs)
            [~,false_peak(end+1)] = min(abs(est_onsets - locs(i)));
            
        end
    end
    est_onsets(false_peak) = [];
    elec_id(false_peak) = [];
    close(figure(n+1));
    [est_onsets,order] = sort(est_onsets);
    elec_id = elec_id(order);
end


