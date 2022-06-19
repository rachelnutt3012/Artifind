function [EEG, qrs] = CBArtifactDetect(EEG, ECGchan, seglength)

%% Detect the onsets of the CB artefact from the EEG data 
% As an example, the final block of code (lines 72:end) can be used to
% correct for the CB artefact using the found onsets via the fmrib toolbox (requires installation)
% Input 1: EEG data structure
% Input 2: ECG channel number (if present in the data (albeit unuseable), else [])
% Input 3: Segment length for detecting the CB artefact peaks. This is a
% tradeoff. A bigger segment length means quicker artefact detection but
% less accountability for temporal variability in artefact shape. A smaller
% segment length means slower detection but better accountability for
% temporal variability. If you have noisy data (e.g. lots of motion),
% smaller segment lengths (e.g. 20 seconds) are preferred.
% Output 1: EEG structure with detected CB artefact onsets (labelled in EEG.events as 'qrs')
% Output 2: detected onsets of the CB artifact

narginchk(3,3);
disp('Finding peaks of the CB artefact across the dataset...');
qrs = [];
elec_per_onset = [];
all_elec_sites = cell(1,EEG.nbchan);
for i = 1:EEG.nbchan
    all_elec_sites{i} = EEG.chanlocs(i).labels;
end

df = 1; 
order = round(5 / (df / EEG.srate)); 
datastruct_1Hzhp = pop_eegfiltnew(EEG, [],1.5,order,true,[],0);
counter = 1:seglength*datastruct_1Hzhp.srate:size(datastruct_1Hzhp.data,2); 
if size(datastruct_1Hzhp.data,2) - counter(end) < 5*datastruct_1Hzhp.srate
    counter(end) = [];
end
all_motherwaves = cell(length(counter)-1,1);
all_chosen_elecs = zeros(length(counter)-1,1);
time_segment = 1;
n = length(findobj('type','figure'));
figure(n+1);
while time_segment <= length(counter)
    fprintf('Segment %i/%i\n', time_segment, length(counter));
    if time_segment == length(counter)
        seg_data = datastruct_1Hzhp.data(:,counter(time_segment):size(datastruct_1Hzhp.data,2));
    else
        seg_data = datastruct_1Hzhp.data(:,counter(time_segment):counter(time_segment+1));
    end
    [motherwave, elec] = GetReferenceArtifact(seg_data, ECGchan, datastruct_1Hzhp.srate);
    if isempty(motherwave)
        motherwave = all_motherwaves{time_segment-1};
        elec = all_chosen_elecs(time_segment-1);
    end
    all_motherwaves(time_segment) = {motherwave};
    all_chosen_elecs(time_segment) = elec;
    convkern = GetMeanArtifact(motherwave, seg_data(elec,:), datastruct_1Hzhp.srate); %motherwave;
    if size(convkern,2) > 1
        convkern = convkern';
    end
    convkern = flipud(convkern);
    convolved = conv(seg_data(elec,:), convkern, 'same');
    minlength = length(convkern)*0.8/datastruct_1Hzhp.srate;
    segment_qrs = FindRPeaks(convolved, [], minlength, datastruct_1Hzhp.srate);
    segment_qrs = segment_qrs + counter(time_segment)-1;
    elec_identifier = repelem(elec, length(segment_qrs));
    qrs = cat(2,qrs,segment_qrs);
    elec_per_onset = cat(2,elec_per_onset,elec_identifier);
    time_segment = time_segment +1;
end
close(figure(n+1));
[qrs, ~, ~] = AlignOnsetsNew(datastruct_1Hzhp.data, qrs, elec_per_onset);
for i=1:length(qrs)
    n_events=length(EEG.event);
    EEG.event(n_events+1).type = 'qrs';
    EEG.event(n_events+1).code = 'Response';
    EEG.event(n_events+1).duration = 1;
    EEG.event(n_events+1).channel = 0;
    EEG.event(n_events+1).latency = (qrs(i));
    EEG.event(n_events+1).urevent = n_events+1;
    EEG.event(n_events+1).bvmknum = n_events+1;
end


