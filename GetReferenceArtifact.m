function [ref, elec] = GetReferenceArtifact(data, ECG, fs)

locs = [];
elec = 1;
if isempty(ECG)
    ECG = 0;
end
while isempty(locs)   
    if elec > size(data,1)
        disp('Could not find R-peaks in current data segment.')
        dec = input('Enter 1 to search again or 2 to use the reference artifact from the previous segment (if this is the first segment, you must enter 1): ');
        if dec == 1
            elec = 1;
        else
            ref = [];
            locs = NaN;
            elec = [];
            break
        end
    end
    if elec == ECG
        elec = elec+1; 
    else 
        plot(data(elec,1*fs+1:end-1*fs)); xlim([1 size(data,2)-2*fs]); box off; ylabel('Amplitude (uV)'); xlabel('Time (datapoints)'); title(sprintf('Electrode number %i: select any two CONSECUTIVE and CLEARLY DISCERNIBLE R-peaks', elec));
        points = datacursormode;
        disp('Manually select two consecutive and clear R peaks (if any), otherwise press enter to try the next electrode')
        disp('Press enter to continue')
        val = input('Press 1 to move onto next electrode, press 2 to go back to previous electrode, or press enter if you have selected two peaks: ');
        manual_pnts = getCursorInfo(points);
        for i = 1:size(manual_pnts,2)
            locs(1,i) = manual_pnts(i).Position(1);
        end
        if ~isempty(locs)
            locs(1,:) = sort(locs(1,:));
            if locs(2) - locs(1) < 0 || length(locs) ~= 2
                locs = [];
                disp('Invalid peaks selected. Please try again.')
            end
        elseif val == 1
            elec = elec+1;
        elseif isempty(val)
            elec = elec;
        elseif val == 2 && elec-1 == ECG
            elec = elec-2;
        elseif val == 2
            elec = elec-1;
            if elec < 1
                elec = 1;
            end
        end
    end
end
cla reset
if ~isnan(locs)
    locs = locs+1*fs; % as we labelled the locations one second into the data segment, we must account for this by adding 1 second on
    RtoR = locs(2) - locs(1);
    artifacts(1,:) = data(elec,locs(1)-floor(RtoR/2) : locs(1)+floor(RtoR/2));
    artifacts(2,:) = data(elec,locs(2)-floor(RtoR/2) : locs(2)+floor(RtoR/2));
    ref = mean(artifacts - mean(artifacts,2));%baseline correct each artifact and take the mean
end