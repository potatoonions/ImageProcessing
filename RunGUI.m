%% GLOVE DEFECT DETECTION - HOME PAGE LAUNCHER
% Main GUI home page for selecting which glove type to analyze

clear functions; clear all; clc; close all; rehash;

fprintf('\n========================================\n');
fprintf('  Glove Defect Detection System\n');
fprintf('  Home Page Launcher\n');
fprintf('========================================\n\n');

createHomePage();

function createHomePage()
% Main home page with buttons for each glove type
    
    % Create figure
    fig = figure('Name', 'Glove Defect Detection - Home', ...
        'NumberTitle', 'off', ...
        'Position', [200 150 900 700], ...
        'Color', [0.94 0.94 0.94], ...
        'CloseRequestFcn', @closeApp);
    
    % Main panel
    mainPanel = uipanel(fig, 'Position', [0.05 0.05 0.90 0.90], ...
        'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
    
    % Title
    uicontrol(mainPanel, 'Style', 'text', ...
        'String', 'Glove Defect Detection System', ...
        'Units', 'normalized', 'Position', [0.1 0.85 0.8 0.10], ...
        'FontSize', 32, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.2 0.4 0.6], ...
        'BackgroundColor', [0.94 0.94 0.94]);
    
    % Subtitle
    uicontrol(mainPanel, 'Style', 'text', ...
        'String', 'Select the glove type you want to analyze:', ...
        'Units', 'normalized', 'Position', [0.1 0.75 0.8 0.06], ...
        'FontSize', 14, 'FontWeight', 'normal', ...
        'ForegroundColor', [0.3 0.3 0.3], ...
        'BackgroundColor', [0.94 0.94 0.94]);
    
    % Button Panel
    buttonPanel = uipanel(mainPanel, 'Position', [0.10 0.15 0.80 0.55], ...
        'BorderType', 'line', 'BackgroundColor', [0.96 0.96 0.96]);
    
    % Button 1: Cloth Gloves (Blue)
    uicontrol(buttonPanel, 'Style', 'pushbutton', ...
        'String', sprintf('Cloth Gloves\n(Holes, Snags, Stains)'), ...
        'Units', 'normalized', 'Position', [0.05 0.55 0.40 0.40], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.6 0.9], 'ForegroundColor', [1 1 1], ...
        'Callback', @launchClothGloves);
    
    % Button 2: Rubber Gloves (Green)
    uicontrol(buttonPanel, 'Style', 'pushbutton', ...
        'String', sprintf('Rubber Gloves\n(Holes, Tears, Stains)'), ...
        'Units', 'normalized', 'Position', [0.55 0.55 0.40 0.40], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2 0.8 0.2], 'ForegroundColor', [1 1 1], ...
        'Callback', @launchRubberGloves);
    
    % Button 3: Plastic Gloves (Orange)
    uicontrol(buttonPanel, 'Style', 'pushbutton', ...
        'String', sprintf('Plastic Gloves\n(Burns, Blood, Discoloration)'), ...
        'Units', 'normalized', 'Position', [0.05 0.05 0.40 0.40], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [1 0.6 0.2], 'ForegroundColor', [1 1 1], ...
        'Callback', @launchPlasticGloves);
    
    % Button 4: Nitrile Gloves (Purple)
    uicontrol(buttonPanel, 'Style', 'pushbutton', ...
        'String', sprintf('Nitrile Gloves\n(Coming Soon)'), ...
        'Units', 'normalized', 'Position', [0.55 0.05 0.40 0.40], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.7 0.2 0.8], 'ForegroundColor', [1 1 1], ...
        'Enable', 'off');
    
    % Bottom info
    uicontrol(mainPanel, 'Style', 'text', ...
        'String', sprintf('Version 1.0 | Image Processing Assignment | Year 3 Degree'), ...
        'Units', 'normalized', 'Position', [0.1 0.02 0.8 0.05], ...
        'FontSize', 9, 'FontWeight', 'normal', ...
        'ForegroundColor', [0.6 0.6 0.6], ...
        'BackgroundColor', [0.94 0.94 0.94]);
    
    fprintf('✓ Home page GUI created successfully\n');
end

function launchClothGloves(~, ~)
% Launch Cloth Gloves detection GUI
    fprintf('\nLaunching Cloth Gloves Defect Detection...\n');
    
    clothPath = fullfile(pwd, 'cloth_gloves_classification');
    if isfolder(clothPath)
        addpath(clothPath);
        try
            GloveDefectDetectionGUI();
            fprintf('✓ Cloth Gloves GUI started successfully\n');
        catch ME
            msgbox(['Error starting Cloth Gloves GUI: ' ME.message], 'Error', 'error');
            fprintf('✗ Error: %s\n', ME.message);
        end
    else
        msgbox('cloth_gloves_classification folder not found!', 'Error', 'error');
        fprintf('✗ Folder not found: %s\n', clothPath);
    end
end

function launchRubberGloves(~, ~)
% Launch Rubber Gloves detection GUI
    fprintf('\nLaunching Rubber Gloves Defect Detection...\n');
    
    rubberPath = fullfile(pwd, 'rubber_gloves');
    if isfolder(rubberPath)
        addpath(rubberPath);
        try
            rubberDefectDetectionGUI();
            fprintf('✓ Rubber Gloves GUI started successfully\n');
        catch ME
            msgbox(['Error starting Rubber Gloves GUI: ' ME.message], 'Error', 'error');
            fprintf('✗ Error: %s\n', ME.message);
        end
    else
        msgbox('rubber_gloves folder not found!', 'Error', 'error');
        fprintf('✗ Folder not found: %s\n', rubberPath);
    end
end

function launchPlasticGloves(~, ~)
% Launch Plastic Gloves detection GUI
    fprintf('\nLaunching Plastic Gloves Defect Detection...\n');
    
    plasticPath = fullfile(pwd, 'Angel');
    if isfolder(plasticPath)
        addpath(plasticPath);
        try
            PlasticDefectDetectionGUI();
            fprintf('✓ Plastic Gloves GUI started successfully\n');
        catch ME
            msgbox(['Error starting Plastic Gloves GUI: ' ME.message], 'Error', 'error');
            fprintf('✗ Error: %s\n', ME.message);
        end
    else
        msgbox('Angel folder not found!', 'Error', 'error');
        fprintf('✗ Folder not found: %s\n', plasticPath);
    end
end

function closeApp(~, ~)
% Close application
    fprintf('\nClosing Glove Defect Detection System...\n');
    delete(gcbf);
end
