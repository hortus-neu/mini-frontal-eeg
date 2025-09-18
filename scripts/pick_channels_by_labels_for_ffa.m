function idx = pick_channels_by_labels_for_ffa(EEG, wantedLabels)
    % in this task:
    % wanted labels : {'F3', 'F4', 'Fz', 'AFz'}
    labels = string({EEG.chanlocs.labels});
    % normalize the input
    labels = strtrim(upper(labels));
    wanted = upper(strtrim(string(wantedLabels)));
    % to store the col idx of wanted channels
    idx = nan(size(wanted));
    for k = 1:numel(wanted)
        hit = find(labels == wanted(k), 1);
        if ~isempty(hit)
            idx(k) = hit;
        end
    end
end



