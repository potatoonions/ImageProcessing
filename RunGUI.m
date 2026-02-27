%% GLOVE DEFECT DETECTION SYSTEM - LAUNCHER
% Run this script to start the GUI application
%
% Features:
%   - Upload cloth glove images
%   - Automatically detect defects (holes, snags, stains)
%   - Visualize processing pipeline
%   - Display detailed metrics
%   - Support for Cloth, Nitrile, and Rubber gloves

clear functions; clear all; clc; close all; rehash;

fprintf('\n========================================\n');
fprintf('  Glove Defect Detection GUI\n');
fprintf('========================================\n\n');

% Add cloth_gloves_classification folder to path
clothGlovesPath = fullfile(pwd, 'cloth_gloves_classification');
if isfolder(clothGlovesPath)
    addpath(clothGlovesPath);
else
    error('cloth_gloves_classification folder not found in current directory');
end

fprintf('Launching GUI application...\n\n');

% Launch GUI
try
    GloveDefectDetectionGUI();
    fprintf('✓ GUI started successfully\n');
catch ME
    fprintf('✗ Error starting GUI:\n');
    fprintf('  %s\n', ME.message);
end
