%% POLYETHENE PLASTIC GLOVE DEFECT DETECTION - LAUNCHER

clear functions; clear all; clc; close all; rehash;

fprintf('\n========================================\n');
fprintf('  Plastic Glove Defect Detection GUI\n');
fprintf('  (Polyethene Material)\n');
fprintf('========================================\n\n');

angelPath = pwd; % Current folder is Angel
if isfolder(angelPath)
    addpath(angelPath);
else
    error('Angel folder not found in current directory');
end

fprintf('Launching plastic glove GUI application...\n\n');

try
    PlasticDefectDetectionGUI();
    fprintf('✓ GUI started successfully\n');
catch ME
    fprintf('✗ Error starting GUI:\n');
    fprintf('  %s\n', ME.message);
end