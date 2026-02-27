%% GLOVE DEFECT DETECTION - LAUNCHER

clear functions; clear all; clc; close all; rehash;

fprintf('\n========================================\n');
fprintf('  Glove Defect Detection GUI\n');
fprintf('========================================\n\n');

clothGlovesPath = fullfile(pwd, 'cloth_gloves_classification');
if isfolder(clothGlovesPath)
    addpath(clothGlovesPath);
else
    error('cloth_gloves_classification folder not found in current directory');
end

fprintf('Launching GUI application...\n\n');

try
    GloveDefectDetectionGUI();
    fprintf('✓ GUI started successfully\n');
catch ME
    fprintf('✗ Error starting GUI:\n');
    fprintf('  %s\n', ME.message);
end
