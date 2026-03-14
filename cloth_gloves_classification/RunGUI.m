%% CLOTH GLOVE DEFECT DETECTION - LAUNCHER
% Runs from cloth_gloves_classification folder

clear functions; clear all; clc; close all; rehash;

fprintf('\n========================================\n');
fprintf('  Cloth Glove Defect Detection GUI\n');
fprintf('========================================\n\n');

% Add current folder to path (this IS the cloth_gloves_classification folder)
currentFolder = fileparts(mfilename('fullpath'));
if ~contains(path, currentFolder)
    addpath(currentFolder);
end

fprintf('Launching GUI application...\n\n');

try
    GloveDefectDetectionGUI();
    fprintf('✓ GUI started successfully\n');
catch ME
    fprintf('✗ Error starting GUI:\n');
    fprintf('  %s\n', ME.message);
end
