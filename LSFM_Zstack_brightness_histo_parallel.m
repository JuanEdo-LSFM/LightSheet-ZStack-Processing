%% Parallel light-sheet TIFF Z-stack brightness and histogram processing
% MATLAB R2026a
%
% This version uses parallel processing for the computationally expensive
% per-slice operations.


clear; clc; close all;

%% 00 Start parallel pool

useParallel = true;

if useParallel
    try
        if isempty(gcp('nocreate'))
            parpool;
        end
        disp('Parallel pool started.');
    catch
        warning('Parallel pool could not be started. Continuing without parallel processing.');
        useParallel = false;
    end
end

%% 01 Select input folder

inputFolder = uigetdir(pwd, '01 Select folder containing TIFF z-stack');

if inputFolder == 0
    error('No folder selected.');
end

[~, folderName] = fileparts(inputFolder);
outputFolder = fullfile(fileparts(inputFolder), [folderName '_processed']);

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% 02 Find TIFF files

files = dir(fullfile(inputFolder, '*.tif'));

if isempty(files)
    files = dir(fullfile(inputFolder, '*.tiff'));
end

if isempty(files)
    error('No TIFF files found in selected folder.');
end

[~, idx] = sort({files.name});
files = files(idx);

nImages = numel(files);
fprintf('Found %d TIFF images.\n', nImages);

%% 03 Load raw Z-stack

disp('Opening the raw Z-stack for visualization...');

info = imfinfo(fullfile(inputFolder, files(1).name));
imgHeight = info.Height;
imgWidth  = info.Width;

stack = zeros(imgHeight, imgWidth, nImages, 'uint16');

for i = 1:nImages
    stack(:,:,i) = imread(fullfile(inputFolder, files(i).name));
end

figure('Name', 'Raw Z-stack');
sliceViewer(stack);

disp('Inspect the raw Z-stack, then choose a representative reference slice.');

%% 04 Select reference slice

refIndex = input(sprintf('Enter reference slice number between 1 and %d: ', nImages));

if refIndex < 1 || refIndex > nImages
    error('Invalid reference slice number.');
end

refImage = stack(:,:,refIndex);

%% 05 Brightness adjustment - interactive preview

brightnessAccepted = false;

while ~brightnessAccepted

    figure('Name', 'Reference image - raw');
    imshow(refImage, []);
    title('Reference image - raw');

    disp('Enter brightness limits as raw 16-bit intensity values.');
    disp('Example: lower = 100, upper = 5000');

    lowerLimit = input('Lower brightness limit: ');
    upperLimit = input('Upper brightness limit: ');

    if lowerLimit < 0 || upperLimit > 65535 || lowerLimit >= upperLimit
        warning('Invalid brightness limits. Please try again.');
        continue;
    end

    refAdjusted = mat2gray(refImage, [lowerLimit upperLimit]);
    refAdjusted = im2uint16(refAdjusted);

    figure('Name', 'Brightness adjustment preview');

    subplot(1,2,1);
    imshow(refImage, []);
    title('Original reference image');

    subplot(1,2,2);
    imshow(refAdjusted, []);
    title(sprintf('Adjusted: [%d %d]', lowerLimit, upperLimit));

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

%% 06 Apply brightness limits to whole stack

brightnessStack = zeros(size(stack), 'uint16');

if useParallel
    parfor i = 1:nImages
        img = stack(:,:,i);
        imgScaled = mat2gray(img, [lowerLimit upperLimit]);
        brightnessStack(:,:,i) = im2uint16(imgScaled);
    end
else
    for i = 1:nImages
        img = stack(:,:,i);
        imgScaled = mat2gray(img, [lowerLimit upperLimit]);
        brightnessStack(:,:,i) = im2uint16(imgScaled);
    end
end

figure('Name', 'Brightness-adjusted Z-stack');
sliceViewer(brightnessStack);

disp('Brightness-adjusted Z-stack displayed.');

%% 07 Optional save of brightness-adjusted stack

saveBrightness = questdlg( ...
    'Do you want to save the brightness-adjusted stack?', ...
    'Save brightness-adjusted stack', ...
    'Yes', 'No', 'Yes');

if strcmp(saveBrightness, 'Yes')

    brightnessFolder = fullfile( ...
        fileparts(inputFolder), ...
        [folderName '_brightAdj']);

    if ~exist(brightnessFolder, 'dir')
        mkdir(brightnessFolder);
    end

    fprintf('\nSaving brightness-adjusted stack...\n');

    for i = 1:nImages

        [~, imageName, ext] = fileparts(files(i).name);

        outputName = fullfile( ...
            brightnessFolder, ...
            [imageName '_brightAdj' ext]);

        imwrite(brightnessStack(:,:,i), outputName, 'tif');

        fprintf('Saved %d/%d\n', i, nImages);
    end

    fprintf('Brightness-adjusted stack saved in:\n%s\n', brightnessFolder);

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

%% 08 Optional histogram processing

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

        refAdjusted = brightnessStack(:,:,refIndex);

        if useParallel
            parfor i = 1:nImages
                processedStack(:,:,i) = imhistmatch( ...
                    brightnessStack(:,:,i), refAdjusted);
            end
        else
            for i = 1:nImages
                processedStack(:,:,i) = imhistmatch( ...
                    brightnessStack(:,:,i), refAdjusted);
            end
        end

        disp('Histogram matching applied using the selected reference slice.');

    case 'Adapthisteq'

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

        if useParallel
            parfor i = 1:nImages
                processedStack(:,:,i) = adapthisteq( ...
                    brightnessStack(:,:,i), ...
                    'NumTiles', numTiles, ...
                    'ClipLimit', clipLimit);
            end
        else
            for i = 1:nImages
                processedStack(:,:,i) = adapthisteq( ...
                    brightnessStack(:,:,i), ...
                    'NumTiles', numTiles, ...
                    'ClipLimit', clipLimit);

                fprintf('Adapthisteq processed %d / %d\n', i, nImages);
            end
        end

        disp('Adaptive histogram equalization applied.');

    case 'No'

        disp('No additional histogram processing applied.');
end

%% 09 Display final processed Z-stack

figure('Name', 'Final processed Z-stack');
sliceViewer(processedStack);

%% 10 Confirm saving final processed images

saveChoice = questdlg( ...
    'Do you want to save the processed images?', ...
    'Save images', ...
    'Yes', 'No', 'Yes');

if ~strcmp(saveChoice, 'Yes')
    disp('Images were not saved.');
    return;
end

%% 11 Save final processed images

fprintf('\nSaving final processed stack...\n');

for i = 1:nImages

    [~, imageName, ext] = fileparts(files(i).name);

    outputName = fullfile(outputFolder, ...
        [imageName '_processed' ext]);

    imwrite(processedStack(:,:,i), outputName, 'tif');

    fprintf('Saved %d / %d: %s\n', i, nImages, outputName);
end

disp('Processing complete.');
disp(['Saved in: ' outputFolder]);