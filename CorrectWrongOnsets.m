function [onsets] = CorrectWrongOnsets(data, onsets, target)

n = length(findobj('type','figure'));
figure(n+1);

plot(data); % manually selected data segment
hold on
plot(onsets, data(onsets),'xr','MarkerSize',12);
box off; xlabel('Time in sampling points'); ylabel('Amplitude (uV)');
    
title('Choose any wrong onsets for deletion');
points = datacursormode;

disp('Manually select any wrongly labelled peaks as accurately as possible. Hold shift to select multiple peaks')
disp('Press enter when finished')
pause

manual_pnts = getCursorInfo(points);
manual_peak_locs = [];

for i = 1:size(manual_pnts,2)
    manual_peak_locs(i) = manual_pnts(i).Position(1);
end

for i = 1:length(manual_peak_locs)
    [~,false_peaks] = min(abs(onsets - manual_peak_locs(i)));
    onsets(false_peaks) = [];
end

if length(onsets) ~= target
    
    cla reset
    
    
    plot(data);
    hold on
    plot(onsets, data(onsets),'xr','MarkerSize',12);
    box off; xlabel('Time in sampling points'); ylabel('Amplitude (uV)');
    
    title('Choose any missing onsets for inclusion');
    
    points = datacursormode;
    disp('Manually select any missing peaks as accurately as possible. Hold shift to select multiple peaks')
    disp('Press enter when finished')
    pause
    manual_pnts = getCursorInfo(points);
    manual_peak_locs = [];
    
    
    for i = 1:size(manual_pnts,2)
        manual_peak_locs(i) = manual_pnts(i).Position(1);
    end
    
    onsets = [onsets manual_peak_locs];
    
end

close(figure(n+1))
onsets = sort(onsets);
