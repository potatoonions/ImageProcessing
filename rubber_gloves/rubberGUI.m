%% RUBBER GLOVE DEFECT DETECTION - LAUNCHER

clear functions; clear all; clc; close all; rehash;

fprintf('\n========================================\n');
fprintf('  Rubber Glove Defect Detection GUI\n');
fprintf('  (Rubber Material)\n');
fprintf('========================================\n\n');

rubberPath = pwd; % Current folder is rubber_gloves

% Add rubber_gloves folder to path
if isfolder(rubberPath)
    addpath(rubberPath);
else
    error('rubber_gloves folder not found in current directory');
end

fprintf('Launching rubber glove GUI application...\n');
fprintf('Added path: %s\n\n', rubberPath);

try
    rubberDefectDetectionGUI();
    fprintf('\u2713 GUI started successfully\n');
catch ME
    fprintf('\u2717 Error starting GUI:\n');
    fprintf('  %s\n', ME.message);
end
