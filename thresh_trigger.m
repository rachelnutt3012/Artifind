function spikes = thresh_trigger(data, thresh1, thresh2)

rising  = find((data(1:end-1) <  thresh1) & (data(2:end) >= thresh1)); %find points in data where the next datapoint is larger 
falling = find((data(1:end-1) >= thresh2) & (data(2:end) <  thresh2));%find points in data where the next datapoint is smaller 

falling(falling < rising(1))  = []; %remove any 'falls' before the first rise
rising(rising > falling(end)) = []; %remove any 'rises' after the final fall

spikes = [];
while ~isempty(rising)
    r = rising(1);

    falling(falling < r) = []; %remove indexes before the first rise
    f = falling(1); %identify the index of the first falling, now necessarily after the first rise

    rising(rising < f) = []; %remove any peaks before the first 'falling',deleting our first peak (now held in r variable) leaving us our first peak and our first fall thereafter

    [~, idx] = max(data(r:f)); %look for peak data sample between the first rise and the first fall
    idx = idx + r - 1;
    spikes(end + 1) = idx;
end
