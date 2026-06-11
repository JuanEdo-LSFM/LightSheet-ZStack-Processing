%% Light-Sheet Z-Stack Brightness and Histogram Processing Tool
%
%
% Author: Juan Eduardo Rodriguez
%
% Functional Neuroconnectomics Workgroup
% Institute of Experimental Epileptology and Cognition Research (IEECR)
% University Hospital Bonn
%
% GitHub:
% https://github.com/JuanEdo-LSFM/LightSheet-ZStack-Processing
%
% DOI:
% https://doi.org/10.5281/zenodo.20645469
%
% License:
% MIT License
%
% Version:
% v1.0
%
%
% Interactive MATLAB workflow for processing 16-bit TIFF image series.
%
% Features:
% - Load and visualize TIFF Z-stacks.
% - Select a reference slice.
% - Interactive brightness normalization using user-defined intensity limits.
% - Optional saving of brightness-adjusted image series.
% - Optional histogram matching to a reference slice.
% - Optional adaptive histogram equalization (CLAHE/adapthisteq).
% - Interactive parameter preview before stack-wide processing.
% - Saving of processing parameters for reproducibility.
% - Optional parallel processing support for large datasets.
%
% Intended for visualization and presentation of light-sheet microscopy
% datasets stored as individual TIFF slices.
%
% Developed for MATLAB R2026a.

clear; clc; close all;

%% 01 Select input folder

% Ask the user to select the folder containing the TIFF image series
inputFolder = uigetdir(pwd, '01 Select folder containing TIFF z-stack');

if inputFolder == 0
    error('No folder selected.');
end

% Get the folder name and define the output folder for final processed images
[~, folderName] = fileparts(inputFolder);
outputFolder = fullfile(fileparts(inputFolder), [folderName '_processed']);

% Create output folder if it does not already exist
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Find TIFF files

% Look for .tif files first
files = dir(fullfile(inputFolder, '*.tif'));

% If no .tif files are found, look for .tiff files
if isempty(files)
    files = dir(fullfile(inputFolder, '*.tiff'));
end

if isempty(files)
    error('No TIFF files found in selected folder.');
end

% Sort files alphabetically to preserve z-stack order
[~, idx] = sort({files.name});
files = files(idx);

nImages = numel(files);
fprintf('Found %d TIFF images.\n', nImages);

%% 02 Load raw Z-stack

disp('Opening the raw Z-stack for visualization...');

% Read image size from the first TIFF file
info = imfinfo(fullfile(inputFolder, files(1).name));
imgHeight = info.Height;
imgWidth  = info.Width;

% Preallocate memory for the 3D stack as 16-bit images
stack = zeros(imgHeight, imgWidth, nImages, 'uint16');

% Load each TIFF image into the stack
for i = 1:nImages
    stack(:,:,i) = imread(fullfile(inputFolder, files(i).name));
end

% Display the raw Z-stack using MATLAB sliceViewer
figure('Name', 'Raw Z-stack');
sliceViewer(stack);

disp('Inspect the raw Z-stack, then choose a representative reference slice.');

%% 03 Select reference slice

% The reference slice is used to define brightness and optional histogram settings
refIndex = input(sprintf('Enter reference slice number between 1 and %d: ', nImages));

if refIndex < 1 || refIndex > nImages
    error('Invalid reference slice number.');
end

refImage = stack(:,:,refIndex);

%% 04 Brightness adjustment - interactive preview

% The user can repeatedly test lower/upper brightness limits
% until the reference image looks appropriate.
brightnessAccepted = false;

while ~brightnessAccepted

    figure('Name', 'Reference image - raw');
    imshow(refImage, []);
    title('Reference image - raw');

    disp('Enter brightness limits as raw 16-bit intensity values.');
    disp('Example: lower = 100, upper = 5000');

    lowerLimit = input('Lower brightness limit: ');
    upperLimit = input('Upper brightness limit: ');

    % Check that the selected limits are valid for 16-bit images
    if lowerLimit < 0 || upperLimit > 65535 || lowerLimit >= upperLimit
        warning('Invalid brightness limits. Please try again.');
        continue;
    end

    % Rescale the reference image using the selected intensity range
    % Intensities below lowerLimit become black.
    % Intensities above upperLimit become saturated.
    refAdjusted = mat2gray(refImage, [lowerLimit upperLimit]);
    refAdjusted = im2uint16(refAdjusted);

    % Show original and brightness-adjusted image side by side
    figure('Name', 'Brightness adjustment preview');

    subplot(1,2,1);
    imshow(refImage, []);
    title('Original reference image');

    subplot(1,2,2);
    imshow(refAdjusted, []);
    title(sprintf('Adjusted: [%d %d]', lowerLimit, upperLimit));

    % Ask whether the selected brightness limits should be accepted
    answer = questdlg( ...
        'Are these brightness values correct?', ...
        'Confirm brightness adjustment', ...
        'Yes, continue', ...
        'No, redefine', ...
        'Cancel', ...
        'Yes, continue');

    switch answer
        case 'Yes, continue'
            brightnessAccepted = true;

        case 'No, redefine'
            close(gcf);
            disp('Redefine brightness values.');

        case 'Cancel'
            error('Processing cancelled by user.');

        otherwise
            error('Processing cancelled by user.');
    end
end

%% 05 Apply brightness limits to the whole stack

% Apply the same brightness limits to every image in the stack.
% This ensures consistent visualization across the entire Z-stack.
brightnessStack = zeros(size(stack), 'uint16');

for i = 1:nImages
    img = stack(:,:,i);

    imgScaled = mat2gray(img, [lowerLimit upperLimit]);
    brightnessStack(:,:,i) = im2uint16(imgScaled);
end

% Display brightness-adjusted Z-stack
figure('Name', 'Brightness-adjusted Z-stack');
sliceViewer(brightnessStack);

disp('Brightness-adjusted Z-stack displayed.');
uiwait(msgbox( ...
    {'Inspect the brightness-adjusted stack.' ...
     'Click OK when you are ready to continue.'}, ...
    'Review Brightness Adjustment'));
%% 06 Optional save of brightness-adjusted stack

saveBrightness = questdlg( ...
    'Do you want to save the brightness-adjusted stack?', ...
    'Save brightness-adjusted stack', ...
    'Yes', 'No', 'Yes');

if strcmp(saveBrightness, 'Yes')

    % Create separate folder for brightness-adjusted images
    brightnessFolder = fullfile( ...
        fileparts(inputFolder), ...
        [folderName '_brightAdj']);

    if ~exist(brightnessFolder, 'dir')
        mkdir(brightnessFolder);
    end

    fprintf('\nSaving brightness-adjusted stack...\n');

    % Save each brightness-adjusted image
    for i = 1:nImages

        [~, imageName, ext] = fileparts(files(i).name);

        outputName = fullfile( ...
            brightnessFolder, ...
            [imageName '_brightAdj' ext]);

        imwrite(brightnessStack(:,:,i), outputName, 'tif');

        fprintf('Saved %d/%d\n', i, nImages);
    end

    fprintf('Brightness-adjusted stack saved in:\n%s\n', brightnessFolder);

    %% Save brightness adjustment parameters

    % Save a text file documenting the processing parameters
    paramFile = fullfile(brightnessFolder, 'brightness_parameters.txt');

    fid = fopen(paramFile, 'w');

    if fid == -1
        warning('Could not create brightness parameter file.');
    else
        fprintf(fid, 'Brightness adjustment parameters\n');
        fprintf(fid, '===============================\n\n');
        fprintf(fid, 'Input folder: %s\n', inputFolder);
        fprintf(fid, 'Output folder: %s\n', brightnessFolder);
        fprintf(fid, 'Number of images: %d\n', nImages);
        fprintf(fid, 'Reference slice: %d\n', refIndex);
        fprintf(fid, 'Reference image: %s\n', files(refIndex).name);
        fprintf(fid, 'Lower brightness limit: %d\n', lowerLimit);
        fprintf(fid, 'Upper brightness limit: %d\n', upperLimit);
        fprintf(fid, 'Processing date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fprintf(fid, '\nProcessing description:\n');
        fprintf(fid, 'Each 16-bit TIFF image was rescaled using:\n');
        fprintf(fid, 'mat2gray(img, [lowerLimit upperLimit]) followed by im2uint16().\n');

        fclose(fid);

        fprintf('Brightness parameters saved in:\n%s\n', paramFile);
    end
end

%% 07 Optional histogram processing

% At this point the stack has already been brightness-adjusted.
% The user can now optionally apply:
% - Histogram matching: makes all slices resemble the reference slice histogram.
% - Adapthisteq: enhances local contrast using CLAHE.
% - No: keeps only the brightness-adjusted stack.
choice = questdlg( ...
    'Do you want to apply additional histogram processing?', ...
    'Histogram processing', ...
    'Histogram matching', ...
    'Adapthisteq', ...
    'No', ...
    'No');

processedStack = brightnessStack;

switch choice

    case 'Histogram matching'

        % Use the brightness-adjusted reference slice as histogram target
        refAdjusted = brightnessStack(:,:,refIndex);

        for i = 1:nImages
            processedStack(:,:,i) = imhistmatch( ...
                brightnessStack(:,:,i), refAdjusted);
        end

        disp('Histogram matching applied using the selected reference slice.');

    case 'Adapthisteq'

        % Interactive preview of CLAHE parameters before applying to stack
        adapthisteqAccepted = false;
        refBright = brightnessStack(:,:,refIndex);

        while ~adapthisteqAccepted

            disp('Enter adapthisteq parameters.');
            disp('Example: NumTiles = [8 8] or [16 16], ClipLimit = 0.01');

            numTiles = input('NumTiles, e.g. [8 8]: ');
            clipLimit = input('ClipLimit, e.g. 0.01: ');

            if numel(numTiles) ~= 2 || any(numTiles <= 0)
                warning('Invalid NumTiles. Please enter something like [8 8].');
                continue;
            end

            if clipLimit <= 0 || clipLimit > 1
                warning('Invalid ClipLimit. Please enter a value between 0 and 1.');
                continue;
            end

            % Apply adapthisteq only to the reference image for preview
            refAdapthisteq = adapthisteq( ...
                refBright, ...
                'NumTiles', numTiles, ...
                'ClipLimit', clipLimit);

            figure('Name', 'Adapthisteq preview');

            subplot(1,2,1);
            imshow(refBright, []);
            title('Brightness-adjusted reference');

            subplot(1,2,2);
            imshow(refAdapthisteq, []);
            title(sprintf('Adapthisteq: [%d %d], ClipLimit %.4f', ...
                numTiles(1), numTiles(2), clipLimit));

            answer = questdlg( ...
                'Are these adapthisteq parameters correct?', ...
                'Confirm adapthisteq settings', ...
                'Yes, apply to stack', ...
                'No, redefine', ...
                'Cancel', ...
                'Yes, apply to stack');

            switch answer
                case 'Yes, apply to stack'
                    adapthisteqAccepted = true;

                case 'No, redefine'
                    close(gcf);
                    disp('Redefine adapthisteq parameters.');

                case 'Cancel'
                    error('Processing cancelled by user.');

                otherwise
                    error('Processing cancelled by user.');
            end
        end

        % Apply final adapthisteq parameters to all slices
        for i = 1:nImages
            processedStack(:,:,i) = adapthisteq( ...
                brightnessStack(:,:,i), ...
                'NumTiles', numTiles, ...
                'ClipLimit', clipLimit);

            fprintf('Adapthisteq processed %d / %d\n', i, nImages);
        end

        disp('Adaptive histogram equalization applied.');

    case 'No'

        disp('No additional histogram processing applied.');
end

%% 08 Display final processed Z-stack

figure('Name', 'Final processed Z-stack');
sliceViewer(processedStack);
uiwait(msgbox( ...
    {'Inspect the histogram-adjusted stack.' ...
    'Click OK when you are ready to continue.'}, ...
    'Review Histogram Adjustment'));
%% 09 Confirm saving final processed images

saveChoice = questdlg( ...
    'Do you want to save the processed images?', ...
    'Save images', ...
    'Yes', 'No', 'Yes');

if ~strcmp(saveChoice, 'Yes')
    disp('Images were not saved.');
    return;
end

%% 10 Save final processed images

% Save the final processed images in folderName_processed
for i = 1:nImages

    [~, imageName, ext] = fileparts(files(i).name);

    outputName = fullfile(outputFolder, ...
        [imageName '_processed' ext]);

    imwrite(processedStack(:,:,i), outputName, 'tif');

    fprintf('Saved %d / %d: %s\n', i, nImages, outputName);
end

disp('Processing complete.');
disp(['Saved in: ' outputFolder]);