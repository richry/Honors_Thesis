% Made by Ryan R. Rich in Partial Fulfillment of the Requirements for the 
% Degree of Bachelor of Arts with Honors in Psychology from the University of Michigan, 2021

% Mentor: Thad Polk, Graduate Student Mentor: Pia Lalwani, Additional
% thanks: Nathan Brown

% Contact Ryan: ryrich@umich.edu

%% All the fun pre-opening and such

clear
clc

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

name = '_N170_Post_ICA_Final_Prep';

%start the big boy loop
for l = 1:40    
    number = int2str(l);
    file_name = strcat('6_',number,name,'.set');
    file_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number);
    EEG = pop_loadset('filename',file_name,'filepath',file_path);
    % I can't put it into words but this index needs to be 1 not 0
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 1 );
    
    load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    load(load_name);
    model_load_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_SVM_Model.mat');
    load(model_load_name);

    %% Pull info
    new_data = EEG.data ;
    
    % Things to remember
    % - EEG.data is a channel by time by trial matrix (chan, time, trial)
    % - Trials will be varriable
    % - time is not in ms, it is in your sampling rate, and includes the
    %   whole epoch, before and after stim presentation
    % - EEG lab sticks interpolated channels on at the end, so the EOG
    %   chans are no longer the last chans in the list
    
    
    % Only take all the data associated with the timepoints after stim
    % presentation
    whatiwant = new_data(:, 358:end, :);

    % Get rid of the EOG channels - they aren't brain activity
    % remember that EEGLab throws interpreted channels on at the end
    num_interp_chans = report_card{2,2};
    range_of_EOG_chans = ((33-(2+num_interp_chans)):(33-num_interp_chans));
    
    if range_of_EOG_chans(1) ~= 31
        
        whatiwant_pt_1 = whatiwant(1:range_of_EOG_chans(1)-1,:,:);
        whatiwant_pt_2 = whatiwant(range_of_EOG_chans(3)+1:end,:,:);
        
        for i = 1:size(whatiwant_pt_2, 1)
            whatiwant_pt_1(size(whatiwant_pt_1, 1) + 1, :, :) = whatiwant_pt_2(i, :, :);
        end
        whatiwant = whatiwant_pt_1;
    else
        whatiwant = whatiwant(1:end-3,:,:);
    end
    

    %% Filter events
    data_event_index = 1; % this is the third dimension of the data
    
    labels_array = []; 
    
    filtered_data = ones(size(whatiwant, 1), size(whatiwant, 2)); % init this to some dummy 2D matrix so we can add more 2d matrix "slices" of data to it
    % filtered_data holds all the data we care about and none of the data we
    % don't care about. We will discard the dummy matrix of all ones later.
    for i = 1:length(EEG.event)
        event_type = getfield(EEG.event(i), 'type');
        if event_type == 201 || event_type == 202 || event_type == -99
            continue; % we don't have data for these event types
        end
        if event_type >= 140
            % lable them ones
            labels_array(size(labels_array) + 1) = 1;
            filtered_data(:, :, size(filtered_data, 3) + 1) = whatiwant(:, :, data_event_index);
            % add the data we want (from whatiwant) to the third dimension of
            % filtered_data
        elseif event_type >= 101
            % lable them twos
            labels_array(size(labels_array) + 1) = 2;
            filtered_data(:, :, size(filtered_data, 3) + 1) = whatiwant(:, :, data_event_index);
        end
        data_event_index = data_event_index + 1; % have data, maybe I used it, maybe I didn't
    end

    %% Make Final Outputs
    
    filtered_data = filtered_data(:, :, 2:end); % this is where we throw away that matrix of all ones
    dimensions = size(filtered_data);
    r = dimensions(1)*dimensions(2);
    y = dimensions(3);
    two_d_data = reshape(filtered_data,[r,y]); %smush the 3D into 2D, preserving the events dimension
    two_d_data = two_d_data.'; % transpose so each event has its own row
    labels_array = labels_array'; % transpose so each event label is on a row
    
    %% Predict
    
    Predictions_standard = predict(standard_mdl,two_d_data(:,:));

    for i = 1:length(Predictions_standard)
        if Predictions_standard(i) == labels_array(i)
            Predictions_standard(i) = 1;
        else
            Predictions_standard(i) = 0;
        end
    end

    correct = sum(Predictions_standard(:) == 1);
    Accuracy_standard = correct/length(Predictions_standard);
    
    %% Report Card Stuff
    
    report_card{35,1} = 'Sanity Check: Accuracy';
    report_card{35,2} = Accuracy_standard;
    
    report_card{36,1} = 'Sanity Check: Pass?';
    if report_card{35,2} < .55
        report_card{36,2} = 'Yes';
    else
        report_card{36,2} = 'No';
    end
    
    report_card{38,1} = '%Diff in accuracy: kfold-sanity';
    report_card{38,2} = (1 - report_card{27,2}) - report_card{35,2};
    
    report_card{39,1} = '%Diff in accuracy: Novel-sanity';
    report_card{39,2} = (report_card{32,2}) - report_card{35,2};
    
    report_card_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    save(report_card_save_name,'report_card');
    
    %% Graph 
    
end

   