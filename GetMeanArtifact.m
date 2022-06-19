function [mean_artifact] = GetMeanArtifact(ref, data, fs)

locs = FindRPeaks(data, [], (length(ref)-10)/fs, fs);
RtoR = floor(length(ref)-1)/2;
locs(locs <= RtoR) = [];
locs(locs > length(data)-RtoR) = [];
artifacts = zeros(length(locs), length(ref));
r = zeros(1,length(locs));
for j = 1:length(locs)
    artifacts(j,:) = data(locs(j)-RtoR : locs(j)+RtoR);
    [r(j), ~] = corr(ref', artifacts(j,:)');
end
mean_artifact = mean(artifacts(r >= 0.7,:));


   