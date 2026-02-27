function ThresholdTuner()
% Interactive Threshold Tuner for Cloth Glove Detection

    fig = figure('Name', 'Cloth Glove - Threshold Tuner', 'NumberTitle', 'off', ...
        'Position', [100 100 1200 800], 'Color', [0.94 0.94 0.94]);
    
    appData = struct();
    appData.img = [];
    appData.gray = [];
    
    topPanel = uipanel(fig, 'Position', [0.02 0.90 0.96 0.08], ...
        'BorderType', 'line', 'BackgroundColor', [0.94 0.94 0.94]);
    
    uicontrol(topPanel, 'Style', 'pushbutton', 'String', 'Load Image', ...
        'Position', [10 10 100 30], 'Callback', @(s,e) loadImage(fig));
    
    appData.imgLabel = uicontrol(topPanel, 'Style', 'text', ...
        'String', 'No image loaded', 'Position', [120 10 400 30], ...
        'HorizontalAlignment', 'left', 'FontSize', 11, 'BackgroundColor', [0.94 0.94 0.94]);
    
    % Display area
    displayPanel = uipanel(fig, 'Position', [0.02 0.40 0.68 0.48], ...
        'BorderType', 'line', 'Title', 'Image Preview');
    
    appData.displayAx = axes(displayPanel, 'Position', [0.05 0.05 0.90 0.90]);
    axis(appData.displayAx, 'off');
    
    ctrlPanel = uipanel(fig, 'Position', [0.72 0.40 0.26 0.48], ...
        'BorderType', 'line', 'Title', 'Detection Thresholds');
    
    sliderY = 0.85;
    sliderHeight = 0.08;
    spacing = 0.01;
    
    uicontrol(ctrlPanel, 'Style', 'text', 'String', 'Main Color Min:', ...
        'Position', [10 sliderY*350 130 20], 'BackgroundColor', [0.96 0.96 0.96]);
    appData.colorMinSlider = uicontrol(ctrlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 255, 'Value', 150, ...
        'Position', [10 (sliderY-0.05)*350 130 15], ...
        'Callback', @(s,e) updatePreview(fig));
    appData.colorMinLabel = uicontrol(ctrlPanel, 'Style', 'text', 'String', '150', ...
        'Position', [145 (sliderY-0.02)*350 30 20], 'BackgroundColor', [0.96 0.96 0.96]);
    
    sliderY = sliderY - sliderHeight - spacing;
    
    uicontrol(ctrlPanel, 'Style', 'text', 'String', 'Main Color Max:', ...
        'Position', [10 sliderY*350 130 20], 'BackgroundColor', [0.96 0.96 0.96]);
    appData.colorMaxSlider = uicontrol(ctrlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 255, 'Value', 255, ...
        'Position', [10 (sliderY-0.05)*350 130 15], ...
        'Callback', @(s,e) updatePreview(fig));
    appData.colorMaxLabel = uicontrol(ctrlPanel, 'Style', 'text', 'String', '255', ...
        'Position', [145 (sliderY-0.02)*350 30 20], 'BackgroundColor', [0.96 0.96 0.96]);
    
    sliderY = sliderY - sliderHeight - spacing;
    
    uicontrol(ctrlPanel, 'Style', 'text', 'String', 'Hole Threshold:', ...
        'Position', [10 sliderY*350 130 20], 'BackgroundColor', [0.96 0.96 0.96]);
    appData.holeSlider = uicontrol(ctrlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 100, 'Value', 30, ...
        'Position', [10 (sliderY-0.05)*350 130 15], ...
        'Callback', @(s,e) updatePreview(fig));
    appData.holeLabel = uicontrol(ctrlPanel, 'Style', 'text', 'String', '30', ...
        'Position', [145 (sliderY-0.02)*350 30 20], 'BackgroundColor', [0.96 0.96 0.96]);
    
    sliderY = sliderY - sliderHeight - spacing;
    
    uicontrol(ctrlPanel, 'Style', 'text', 'String', 'Snag Upper:', ...
        'Position', [10 sliderY*350 130 20], 'BackgroundColor', [0.96 0.96 0.96]);
    appData.snagUpperSlider = uicontrol(ctrlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 100, 'Value', 50, ...
        'Position', [10 (sliderY-0.05)*350 130 15], ...
        'Callback', @(s,e) updatePreview(fig));
    appData.snagUpperLabel = uicontrol(ctrlPanel, 'Style', 'text', 'String', '50', ...
        'Position', [145 (sliderY-0.02)*350 30 20], 'BackgroundColor', [0.96 0.96 0.96]);
    
    sliderY = sliderY - sliderHeight - spacing;
    
    uicontrol(ctrlPanel, 'Style', 'text', 'String', 'Snag Lower:', ...
        'Position', [10 sliderY*350 130 20], 'BackgroundColor', [0.96 0.96 0.96]);
    appData.snagLowerSlider = uicontrol(ctrlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 100, 'Value', 10, ...
        'Position', [10 (sliderY-0.05)*350 130 15], ...
        'Callback', @(s,e) updatePreview(fig));
    appData.snagLowerLabel = uicontrol(ctrlPanel, 'Style', 'text', 'String', '10', ...
        'Position', [145 (sliderY-0.02)*350 30 20], 'BackgroundColor', [0.96 0.96 0.96]);
    
    sliderY = sliderY - sliderHeight - spacing;
    
    uicontrol(ctrlPanel, 'Style', 'text', 'String', 'Stain Upper:', ...
        'Position', [10 sliderY*350 130 20], 'BackgroundColor', [0.96 0.96 0.96]);
    appData.stainUpperSlider = uicontrol(ctrlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 100, 'Value', 50, ...
        'Position', [10 (sliderY-0.05)*350 130 15], ...
        'Callback', @(s,e) updatePreview(fig));
    appData.stainUpperLabel = uicontrol(ctrlPanel, 'Style', 'text', 'String', '50', ...
        'Position', [145 (sliderY-0.02)*350 30 20], 'BackgroundColor', [0.96 0.96 0.96]);
    
    sliderY = sliderY - sliderHeight - spacing;
    
    uicontrol(ctrlPanel, 'Style', 'text', 'String', 'Stain Lower:', ...
        'Position', [10 sliderY*350 130 20], 'BackgroundColor', [0.96 0.96 0.96]);
    appData.stainLowerSlider = uicontrol(ctrlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 100, 'Value', 10, ...
        'Position', [10 (sliderY-0.05)*350 130 15], ...
        'Callback', @(s,e) updatePreview(fig));
    appData.stainLowerLabel = uicontrol(ctrlPanel, 'Style', 'text', 'String', '10', ...
        'Position', [145 (sliderY-0.02)*350 30 20], 'BackgroundColor', [0.96 0.96 0.96]);
    
    bottomPanel = uipanel(fig, 'Position', [0.02 0.02 0.96 0.35], ...
        'BorderType', 'line', 'Title', 'Detection Mode');
    
    appData.modeGroup = uibuttongroup(bottomPanel, 'Position', [0.02 0.85 0.96 0.12], ...
        'SelectionChangedFcn', @(s,e) updatePreview(fig));
    
    uicontrol(appData.modeGroup, 'Style', 'radiobutton', 'String', 'Glove Mask', ...
        'Position', [10 5 100 25]);
    uicontrol(appData.modeGroup, 'Style', 'radiobutton', 'String', 'Holes', ...
        'Position', [120 5 100 25]);
    uicontrol(appData.modeGroup, 'Style', 'radiobutton', 'String', 'Snags', ...
        'Position', [230 5 100 25]);
    uicontrol(appData.modeGroup, 'Style', 'radiobutton', 'String', 'Stains', ...
        'Position', [340 5 100 25]);
    
    set(appData.modeGroup, 'SelectedObject', findobj(appData.modeGroup, 'String', 'Glove Mask'));
    
    appData.maskAx = axes(bottomPanel, 'Position', [0.05 0.05 0.90 0.75]);
    axis(appData.maskAx, 'off');
    
    uicontrol(bottomPanel, 'Style', 'pushbutton', 'String', 'Save Thresholds', ...
        'Position', [10 395 120 30], 'Callback', @(s,e) saveThresholds(fig));
    
    guidata(fig, appData);
end

function loadImage(fig)
    appData = guidata(fig);
    
    [filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp', 'Image Files'}, ...
        'Select Cloth Glove Image');
    
    if filename == 0, return; end
    
    fullpath = fullfile(pathname, filename);
    img = imread(fullpath);
    
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
    
    img = imresize(img, [500 500]);
    appData.img = img;
    appData.gray = rgb2gray(img);
    
    set(appData.imgLabel, 'String', sprintf('Loaded: %s', filename));
    guidata(fig, appData);
    updatePreview(fig);
end

function updatePreview(fig)
    appData = guidata(fig);
    
    if isempty(appData.img)
        return;
    end
    
    % Get slider values
    colorMin = get(appData.colorMinSlider, 'Value');
    colorMax = get(appData.colorMaxSlider, 'Value');
    holeThresh = get(appData.holeSlider, 'Value');
    snagUpper = get(appData.snagUpperSlider, 'Value');
    snagLower = get(appData.snagLowerSlider, 'Value');
    stainUpper = get(appData.stainUpperSlider, 'Value');
    stainLower = get(appData.stainLowerSlider, 'Value');
    
    % Update labels
    set(appData.colorMinLabel, 'String', sprintf('%.0f', colorMin));
    set(appData.colorMaxLabel, 'String', sprintf('%.0f', colorMax));
    set(appData.holeLabel, 'String', sprintf('%.0f', holeThresh));
    set(appData.snagUpperLabel, 'String', sprintf('%.0f', snagUpper));
    set(appData.snagLowerLabel, 'String', sprintf('%.0f', snagLower));
    set(appData.stainUpperLabel, 'String', sprintf('%.0f', stainUpper));
    set(appData.stainLowerLabel, 'String', sprintf('%.0f', stainLower));
    
    gray = appData.gray;
    
    % Create glove mask
    mask = (gray >= colorMin) & (gray <= colorMax);
    mask = imclose(mask, strel('disk', 3));
    mask = imopen(mask, strel('disk', 2));
    
    % Get main color
    glovePixels = gray(mask);
    if isempty(glovePixels)
        mainIntensity = 200;
    else
        mainIntensity = mean(glovePixels);
    end
    
    % Get selected mode
    mode = get(get(appData.modeGroup, 'SelectedObject'), 'String');
    
    % Display results
    switch mode
        case 'Glove Mask'
            imshow(mask, 'Parent', appData.maskAx);
            title(appData.maskAx, 'Glove Mask');
        case 'Holes'
            holePixels = (gray < (mainIntensity - holeThresh)) & mask;
            imshow(holePixels, 'Parent', appData.maskAx);
            title(appData.maskAx, sprintf('Holes (threshold: -%d)', holeThresh));
        case 'Snags'
            snagPixels = ((gray >= (mainIntensity - snagUpper)) & ...
                         (gray <= (mainIntensity - snagLower))) & mask;
            imshow(snagPixels, 'Parent', appData.maskAx);
            title(appData.maskAx, sprintf('Snags (range: -%d to -%d)', snagUpper, snagLower));
        case 'Stains'
            stainPixels = ((gray >= (mainIntensity + stainLower)) & ...
                          (gray <= (mainIntensity + stainUpper))) & mask;
            imshow(stainPixels, 'Parent', appData.maskAx);
            title(appData.maskAx, sprintf('Stains (range: +%d to +%d)', stainLower, stainUpper));
    end
    
    % Show original in display
    imshow(appData.gray, 'Parent', appData.displayAx);
    hold(appData.displayAx, 'on');
    
    % Overlay contour
    contours = bwboundaries(mask);
    if ~isempty(contours)
        for k = 1:length(contours)
            boundary = contours{k};
            plot(appData.displayAx, boundary(:,2), boundary(:,1), 'g-', 'LineWidth', 2);
        end
    end
    
    hold(appData.displayAx, 'off');
    title(appData.displayAx, sprintf('Main Color: %.0f', mainIntensity));
end

function saveThresholds(fig)
    appData = guidata(fig);
    
    colorMin = get(appData.colorMinSlider, 'Value');
    colorMax = get(appData.colorMaxSlider, 'Value');
    holeThresh = get(appData.holeSlider, 'Value');
    snagUpper = get(appData.snagUpperSlider, 'Value');
    snagLower = get(appData.snagLowerSlider, 'Value');
    stainUpper = get(appData.stainUpperSlider, 'Value');
    stainLower = get(appData.stainLowerSlider, 'Value');
    
    % Create output text
    output = sprintf(['TUNED THRESHOLDS FOR GLOOVEDEFECTIONGUI.m\n' ...
        '========================================\n\n' ...
        'Glove Mask Thresholds:\n' ...
        '  Color Min: %.0f\n' ...
        '  Color Max: %.0f\n\n' ...
        'Defect Thresholds (offsets from main color):\n' ...
        '  Hole Threshold: %.0f\n' ...
        '  Snag Range: %.0f to %.0f\n' ...
        '  Stain Range: %.0f to %.0f\n'], ...
        colorMin, colorMax, holeThresh, snagLower, snagUpper, stainLower, stainUpper);
    
    fprintf('\n%s\n', output);
    msgbox(output, 'Tuned Thresholds Saved to Console');
end
