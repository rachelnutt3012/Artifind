function qrs_onsets = FindRPeaks(data, prominence, distance, fs)

narginchk(4,4);
    if isempty(prominence)
        prominence = 2*std(data); %default
    end
    if isempty(distance)
        distance = 0.67; %default - you can tweek this value if your subjects were likely to have a lower/higher minimum cardiac cycle duration e.g. under anesthesia
    end
    [~,qrs_onsets] = findpeaks(data,'MinPeakProminence',prominence,'MinPeakDistance',distance*fs);
end