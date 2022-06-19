function [EEG, onsets, trigger_type] = GSArtifactDetect(EEG, num_volumes, num_slices_per_vol, TR, ECG, dummy_scans)

%% Detect the onsets of the GS artefact from the EEG data 
% The onsets can be each slice or each volume, depending on the nature of the artefact as it appears in the EEG.
% Input 1: EEG data structure
% Input 2: number of volumes
% Input 3: number of slices per volume
% Input 4: TR
% Input 5: ECG channel number (if present, else [])
% Input 6: number of dummy scans (if any, else 0)
% Output 1: EEG structure with detected GS artefact onsets (labelled in EEG.events as 'MR')
% Output 2: detected onsets of the slice/volume GS artifact
% Output 3: whether the onsets relate to slice artifact peaks or volume artifact peaks

narginchk(6,6);
n = length(findobj('type','figure'));
disp('No MR triggers present in data. Proceeding with automatic slice artifact onset detection')
num = 1:size(EEG.data,1);
if ~isempty(ECG)
    num(num==ECG)=[];
end
[onsets, elec_trig_detect, trigger_type, manual] = thresh_trigger_auto(EEG.data(num,:), num_slices_per_vol, num_volumes, TR*EEG.srate);
if manual == 1 %just in case autodetect doesn't work, backup manual option also available
    elec_trig_detect = input('Choose an electrode number from which to correct the triggers: ');
    figure(n+1);
    plot(EEG.data(elec_trig_detect,:));
    hold on
    threshold = input('Enter an appropriate amplitude threshold for gradient artefact detection: ');
    onsets = thresh_trigger(EEG.data(elec_trig_detect,:),threshold,0);
    trigger_type = input('Enter 1 for slice triggers and 0 for volume triggers: ');
    close(figure(n+1));
end
if trigger_type == 1
    correct_num_trigs = num_volumes* num_slices_per_vol;
elseif trigger_type == 0
    correct_num_trigs = num_volumes;
end
assert(exist('trigger_type','var'));

onsets(1:dummy_scans) = [];
if length(onsets) ~= correct_num_trigs
    disp('WARNING: The number of triggers does not match the expected number of triggers.')
    if ~exist('elec_trig_detect','var')
        elec_trig_detect = input('Choose an electrode number from which to correct the triggers: ');
    end
    [onsets] = CorrectWrongOnsets(EEG.data(elec_trig_detect,:), onsets, correct_num_trigs);
end
if length(onsets) ~= correct_num_trigs
    figure(n+1); plot(EEG.data(elec_trig_detect,:)); hold on; plot(onsets, EEG.data(elec_trig_detect,onsets), 'xr', 'MarkerSize',12)
    disp('FINAL WARNING: The number of estimated triggers does not match the expected number of triggers.')
    disp('Gradient artifact correction may be inaccurate. Inspect the plotted artifact onsets for any false labels. Press any key if you wish to continue with these onsets, else exit and fix the onsets');
    pause
    close(figure(n+1));
else
    disp('Artifact peaks successfully identified!')
end
if numel(unique(diff(onsets)))>1
    disp('Drift detected')
end
for i=1:length(onsets)
    n_events=length(EEG.event);
    EEG.event(n_events+1).type = 'MR';
    EEG.event(n_events+1).code = 'Response';
    EEG.event(n_events+1).duration = 1;
    EEG.event(n_events+1).channel = 0;
    EEG.event(n_events+1).latency = (onsets(i));
    EEG.event(n_events+1).urevent = n_events+1;
    EEG.event(n_events+1).bvmknum = n_events+1;
end

if trigger_type == 1
    trigger_type = 'slice';
else
    trigger_type = 'volume';
end

