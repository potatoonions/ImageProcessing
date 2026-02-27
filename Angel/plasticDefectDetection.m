% for plastic glove defect detection, which are burn, frosting and discolouration

function overlay = plasticDefectDetection(img)
%PLASTICDEFECTDETECTION  simple burn detector for plastic gloves
%   overlay = plasticDefectDetection(img) returns an RGBA overlay image of
%   the same size as the input where rectangles and text mark burn
%   locations that lie inside an oven/glove contour.  This is a Matlab
%   translation of the Python OvenBurnDetector class used in the original
%   project.
%
%   The routine depends on two helper routines which locate the glove
%   outline (oven contour) and the burn candidates.  Stubs are provided
%   below; the caller should replace them with the appropriate
%   implementations for your data.

% make sure the image is in uint8 form
if ~isa(img,'uint8')
    img = im2uint8(img);
end

% obtain contours of the oven/glove and of potential burn regions
ovenContours = findOvenContours(img);
burnContours = findBurnContours(img);

% create empty overlay with alpha channel
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');

% nothing to draw if no burns were found
if isempty(burnContours)
    return;
end

message = 'Burn';

for i = 1:numel(ovenContours)
    glove = ovenContours{i};           % N×2 array of [x y] points

    for j = 1:numel(burnContours)
        contour = burnContours{j};     % M×2 array of [x y] points

        % centroid of the burn contour
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));

        % bounding rectangle for the contour
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;

        % test whether the centroid lies inside the glove polygon
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            % draw a red rectangle in the overlay
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [0 0 255 255], 2);
            % add text above the box if insertText is available
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', 'red', 'BoxOpacity', 0);
            catch
                % insertText not available; ignore
            end
        end
    end
end
end


% example usage (uncomment when ready)
% img = imread('../img/burn_3.png');
% img = imresize(img, [500 500]);
% overlay = plasticDefectDetection(img);
% imshow(overlay);



%% helper functions (replace with your own implementations)

function contours = findOvenContours(img)
%FINDOVENCONTOURS  return cell array of polygon points for each glove
%   contour in the image.  Each element is an N-by-2 array containing the
%   [x y] coordinates of the polygon.
%
%   This is a placeholder implementation that simply returns an empty
%   cell array; plug in the actual contour‑finding code for your
%   application.

contours = {};

% example stub (uncomment and adapt):
% bw = someThresholding(img);
% B = bwboundaries(bw);
% contours = cellfun(@(b) fliplr(b), B, 'UniformOutput', false);

end

function contours = findBurnContours(img)
%FINDBURNCONTOURS  locate candidate burn regions in the image.  The
%   output format mirrors findOvenContours.

contours = {};

% stub example:
% gray = rgb2gray(img);
% thresh = gray < 50;            % dark spots
% B = bwboundaries(thresh);
% contours = cellfun(@(b) fliplr(b), B, 'UniformOutput', false);

end

function overlay = drawRectangle(overlay, x, y, w, h, color, thickness)
%DRAWRECTANGLE  draw a rectangle on an RGBA overlay image.
%   color is a 1x4 uint8 [R G B A] vector; thickness is an integer.

[r,c,~] = size(overlay);

% clip coordinates
x = max(1, min(x, c));
y = max(1, min(y, r));

for t = 0:thickness-1
    % top edge
    overlay(y+t, x:x+w, 1:4) = repmat(reshape(color,1,1,4), 1, w+1);
    % bottom edge
    overlay(min(r,y+h+t), x:x+w, 1:4) = repmat(reshape(color,1,1,4), 1, w+1);
    % left edge
    overlay(y:y+h, x+t, 1:4) = repmat(reshape(color,1,1,4), h+1, 1);
    % right edge
    overlay(y:y+h, min(c,x+w+t), 1:4) = repmat(reshape(color,1,1,4), h+1, 1);
end
end


% --- frosting detector --------------------------------------------------
function overlay = plasticFrostingDetection(img)
%PLASTICFROSTINGDETECTION  simple frosting detector for plastic gloves
%   Works just like plasticDefectDetection but draws lavender boxes and the
%   label "Frosting".  The algorithm is identical except it calls
%   findFrostingContours instead of findBurnContours.

if ~isa(img,'uint8')
    img = im2uint8(img);
end
ovenContours = findOvenContours(img);
frostingContours = findFrostingContours(img);
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');
if isempty(frostingContours)
    return;
end
message = 'Frosting';

for i = 1:numel(ovenContours)
    glove = ovenContours{i};
    for j = 1:numel(frostingContours)
        contour = frostingContours{j};
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [180 105 255 255], 2);
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', [180 105 255], 'BoxOpacity', 0);
            catch
                % ignore if insertText unavailable
            end
        end
    end
end
end

function contours = findFrostingContours(img)
%FINDFROSTINGCONTOURS  stub for locating frosting regions.
%   Same output format as other contour helpers.
contours = {};
% example stub:
% gray = rgb2gray(img);
% thresh = gray > 200;        % bright spots
% B = bwboundaries(thresh);
% contours = cellfun(@(b) fliplr(b), B, 'UniformOutput', false);
end


% --- discolouration detector -------------------------------------------
function overlay = plasticDiscolourationDetection(img)
%PLASTICDISCOLOURATIONDETECTION  detect colour changes on plastic gloves
%   Similar to the other detectors but labels regions as "Discolouration"
%   using an orange box.  This follows the same flow; swap in your own
%   contour finder via findDiscolourationContours.

if ~isa(img,'uint8')
    img = im2uint8(img);
end
ovenContours = findOvenContours(img);
discContours = findDiscolourationContours(img);
overlay = zeros(size(img,1), size(img,2), 4, 'uint8');
if isempty(discContours)
    return;
end
message = 'Discolouration';

for i = 1:numel(ovenContours)
    glove = ovenContours{i};
    for j = 1:numel(discContours)
        contour = discContours{j};
        cx = mean(contour(:,1));
        cy = mean(contour(:,2));
        xMin = floor(min(contour(:,1)));
        yMin = floor(min(contour(:,2)));
        xMax = ceil(max(contour(:,1)));
        yMax = ceil(max(contour(:,2)));
        w = xMax - xMin;
        h = yMax - yMin;
        if inpolygon(cx, cy, glove(:,1), glove(:,2))
            overlay = drawRectangle(overlay, xMin, yMin, w, h, [255 165 0 255], 2);
            try
                overlay = insertText(overlay, [xMin, yMin-10], message, ...
                    'FontSize', 10, 'TextColor', [255 165 0], 'BoxOpacity', 0);
            catch
                % ignore if insertText unavailable
            end
        end
    end
end
end

function contours = findDiscolourationContours(img)
%FINDDISCOLOURATIONCONTOURS  stub for locating discolouration regions.
%   Output format consistent with other contour helpers.
contours = {};
% example stub:
% gray = rgb2gray(img);
% % threshold range could be mid-intensity variations, adjust as needed
% thresh = (gray > 80) & (gray < 180);
% B = bwboundaries(thresh);
% contours = cellfun(@(b) fliplr(b), B, 'UniformOutput', false);
end

