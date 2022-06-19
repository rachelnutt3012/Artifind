function [spikes, chosen_electrode, trigger, manual_switcher] = thresh_trigger_auto(data, num_slices, num_vols, vol_artifact_length)


manual_switcher = 0;
chosen_electrode = [];
spikes = [];
n = length(findobj('type','figure'));

for trigger = [0 1] %first look for volume artifact peaks - if this is unsuccessful, look for slice artifact peaks
    
    rep = 0;
    val = 100;
    stepsize = 1;
    
    if trigger == 0
        correct_artifact_length = vol_artifact_length;
        correct_artifact_num = num_vols;
    else
        correct_artifact_length = vol_artifact_length/num_slices;
        correct_artifact_num = num_vols * num_slices;
    end
    
    while mode(diff(spikes)) ~= correct_artifact_length || ~any(length(spikes) == correct_artifact_num-7: correct_artifact_num+7)
        
        if rep>0
            fprintf('Lowering threshold for peak detection: %i\n',rep)
        end
        
        reduction = val*(stepsize*rep); %amount to reduce the threshold value (ie. max amplitude value) by in attempt to find the correct number of artifact triggers again
        %start off at the maximum amplitude value minus a certain reduction amount as our threshold
        
        for electrode = 1:size(data,1)
            
            fprintf('Trying electrode %i...\n', electrode)
            %spikes = thresh_trigger(data(electrode,:),median(max(data,[],2))-reduction, 0);
            [~, spikes] = findpeaks(data(electrode,:),'MinPeakHeight', median(max(data,[],2))-reduction, 'MinPeakDistance', correct_artifact_length-2);
            spikesdiff = diff(spikes);
            
            if mode(spikesdiff) == correct_artifact_length && any(length(spikes) == correct_artifact_num-7: correct_artifact_num+7)
                
                %if numel(unique(spikesdiff)) < 4 %if the number of different spikesdiff values is less than 4, then take as chosen electrode for artifact detection. If the number is 4 or more, this might not be the best choice
                fprintf('Electrode %i chosen and artifact peaks detected\n', electrode)
                
                
                if trigger == 0
                    fprintf('Based on volume artifacts, detected number of volumes including dummy scans (and any falsely labelled points) = %i\n',length(spikes));
                else
                    fprintf('Based on slice artifacts, detected number of volumes including dummy scans (and any falsely labelled points) = %i\n',length(spikes)/num_slices);
                end
                
                
                figure(n+1);
                plot(data(electrode,:));
                hold on
                plot(spikes, data(electrode,spikes),'xr','MarkerSize',12);
                box off; xlabel('Time in sampling points'); ylabel('Amplitude (uV)');
                title('Check the quality of the detected onsets')
                
                
                decider = input('Inspect the plotted artifact onsets. Enter 1 to use these onsets or enter 0 to continue searching for a better electrode for artifact detection: ');
                close(figure(n+1))
                
                if decider == 1
                    chosen_electrode = electrode;
                    
                    break;
                end
                
            end
        end
        
        if rep >= 30 %if our threshold is now less than 5000 below the median max across all data, then the search has failed and should exit the loop, try to find volume triggers, and if all fails, admit defeat and go old-school manual
            if trigger == 1
                manual_switcher = input('Could  not find artifact peaks automatically. Enter 1 to continue with manual artifact detection: ');
            else
                disp('Could not identify volumewise artifact peaks. Switching to slice artifact peaks')
            end
            break;
            
        else
            rep = rep+1;
        end
    end
    
    if mode(diff(spikes)) == correct_artifact_length && any(length(spikes) == correct_artifact_num-7: correct_artifact_num+7)
        break;
    end
    
end

end

