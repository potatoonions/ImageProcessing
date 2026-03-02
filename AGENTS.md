# Project Overview
This is a group assignment for CT036-3-IPPR (Image Processing, Computer Vision & Pattern Recognition) at a university.

## Assignment Goal
Develop a Glove Defect Detection (GDD) system that:
- Detects gloves in images
- Segments and recognizes defects in the gloves
- Supports at least 3 types of gloves
- Identifies minimum 3 defects per group member
- Includes a GUI to display defect types

## Important Constraints
- System must NOT be sensitive to environmental changes
- Prohibited methods: Haar Cascade, TensorFlow, and pattern matching

## Deliverables
1. **Prototype Application**
   - Individual screencam demonstration (10-15 minutes each)
   - Well-commented source code
   - Test images

2. **Project Report** (2500-3000 words)
   - Table of contents, contribution matrix, acknowledgement
   - Abstract (200-300 words)
   - Introduction, methodology, experimental results
   - Critical analysis, conclusion, references (APA format)

## Assessment Criteria
- Description and justification of algorithms (10%)
- Experimental Results & Critical analysis (50%)
- Prototype (Demo and Presentation) (40%)

## Development Tools
- MATLAB

## Group Specific
- member 3 tasks
  - glove type: nitrile
  - defect: inside out, improper roll, not worn
  - dataset: logs/gloves_dataset/
  - code: nitrile_gloves_classification/
  - command to run:
    - GUI: matlab -batch "cd nitrile_gloves_classification; NitrileDefectDetectionGUI"
    - Batch (full): matlab -batch "cd nitrile_gloves_classification; addpath(pwd); member3_nitrile_defect_analysis; exit;"
    - Batch (subset): matlab -batch "cd nitrile_gloves_classification; addpath(pwd); member3_nitrile_defect_analysis(5); exit;"

## Instructions for Agents
When working on this project, always:
1. Read this AGENTS.md file first to understand the project context
2. Ask the user which member they are, what are their assigned tasks, and only work on those.
3. Refer to the assignment.md for complete requirements
4. Check existing code in the repository before implementing new features
5. Follow the constraints (no Haar Cascade, TensorFlow, or pattern matching)
6. Ensure the GUI component is properly integrated
