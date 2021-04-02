% Made by Ryan R. Rich in Partial Fulfillment of the Requirements for the 
% Degree of Bachelor of Arts with Honors in Psychology from the University of Michigan, 2021

% Mentor: Thad Polk, Graduate Student Mentor: Pia Lalwani, Additional
% thanks: Nathan Brown

% Contact Ryan: ryrich@umich.edu
%%

clear
clc

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

name = '_N170_Post_ICA_Final_Prep';

% in this case, we have as close to 50ms windows as we can get at 512hz (so
% about 48.83ms
start_samples = [358, 383, 408, 433, 458, 483, 508, 533, 558, 583, 608, 633, 658, 683];
end_samples = [383, 408, 433, 458, 483, 508, 533, 558, 583, 608, 633, 658, 683, 708];

start_helper = 0;
end_helper = (25*(1000/512));

% note, the axis timestamps get rounded to the nearest whole number (will
% never be rounded more than 1ms before or after)
shifting_matrix = {}; % 14 48.83ms windows
growing_matrix = {}; % 14 windows which grow by 48.83ms each iteration

% make the axis with time windows
for p = 1:length(start_samples)    
    shifting_matrix{1,p+1} = strcat(int2str(start_helper),'-',int2str(end_helper),'ms');
    growing_matrix{1,p+1} = strcat('0-', int2str(end_helper),'ms');
    start_helper = start_helper + (25*(1000/512));
    end_helper = end_helper + (25*(1000/512));
end

%start the big boy loop - starts as normal
for l = 1:40    
    number = int2str(l);
    file_name = strcat('6_',number,name,'.set');
    file_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number);
    EEG = pop_loadset('filename',file_name,'filepath',file_path);
    % I can't put it into words but this index needs to be 1 not 0
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 1 );
    
    load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    load(load_name);

    %% Pull info
    new_data = EEG.data ;
    
    % Things to remember
    % - EEG.data is a channel by time by trial matrix (chan, time, trial)
    % - Trials will be varriable
    % - time is not in ms, it is in your sampling rate, and includes the
    %   whole epoch, before and after stim presentation
    % - EEG lab sticks interpolated channels on at the end, so the EOG
    %   chans are no longer the last chans in the list
     
    %**********************************************************************
    % This is where things change, we will do 14 iterations for each
    % subject for each type of temporal feature extraction - each of these
    % will be a "w" loop as seen below
    
    %% "w" loop 1: shifting 50ms (48.83ms) windows
    for w = 1:length(start_samples)
        
        % Only take all the data associated the shifting ~50ms window
        whatiwant = new_data(:, start_samples(w):end_samples(w), :);
        
        
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
            if event_type <= 40
                % lable them ones
                labels_array(size(labels_array) + 1) = 1;
                filtered_data(:, :, size(filtered_data, 3) + 1) = whatiwant(:, :, data_event_index);
                % add the data we want (from whatiwant) to the third dimension of
                % filtered_data
            elseif event_type <= 80
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

        %% Seperate data and Train the standard SVM Classfier

        %So we are going to do the in depth approach and divide the full dataset
        %into train and test, we will then:

        % 1.build the standard model on all of train, 
        % 2.we will then crossvalidate on all of train which will give us our
        %better accuracy metric(s) and all of our evaluation metrics, 
        %3.we will then use these to pick the best model and then 
        %4.we will use that model on the test section. 

        % Note: There are multiple methods to cross-validate, see notes in that
        % section for rational behind my choice


        % holdout M% (to test) using crossvalind - aka, seperate out train and test
        % it's a wee bit confusing wecause we are seperating things out using a
        % function called "corssvalind" and with the "holdout" method, but this is
        % seperate from our crossvalidation and is not a method of crossvalidation
        [train,test] = crossvalind('Holdout',labels_array,.1);

        %train the standard (not corss-validated) SVM Classifier (currently binary)
        standard_mdl = fitcsvm(two_d_data, labels_array); %fitcsvm(two_d_data(train,:),labels_array(train));

        %% Cross-Validation(s)

        % There are a few ways to corss-validate ML Classifiers, you can set it up
        % before building your model, you can specify parameters of
        % cross-validation with name-value pairs in your model function, or you can
        % feed the "standard" model into a cross-validation function. I chose to
        % pass the "standard" model into "crossval" for a few reasons. 
        % A. I wanted to understand all of the steps involved. 
        % B. I think it makes things easier to follow and understand. 
        % C. I can do multiple methods from the same "standard" model to compare 
        % them directly. 
        % But it seems pretty inconsequential

        cross_val_kfold_mdl = crossval((standard_mdl),'KFold',20);

        %lower loss indicates a better predictive model
        kfold_loss_average = kfoldLoss((cross_val_kfold_mdl),'Mode','average');
        
        %% Add Data to Shifting Matrix
        
        shifting_matrix{l+1,1} = strcat('Sub_',int2str(l));
        shifting_matrix{l+1,1+w} = kfold_loss_average;
    end
    %% "w" loop 2 - growing window matrix - 50ms (48.83ms)
    
    for w = 1:length(start_samples)
        
        % Only take all the data associated the shifting growing matrix
        whatiwant = new_data(:, 358:end_samples(w), :);
        
        
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
            if event_type <= 40
                % lable them ones
                labels_array(size(labels_array) + 1) = 1;
                filtered_data(:, :, size(filtered_data, 3) + 1) = whatiwant(:, :, data_event_index);
                % add the data we want (from whatiwant) to the third dimension of
                % filtered_data
            elseif event_type <= 80
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

        %% Seperate data and Train the standard SVM Classfier

        %So we are going to do the in depth approach and divide the full dataset
        %into train and test, we will then:

        % 1.build the standard model on all of train, 
        % 2.we will then crossvalidate on all of train which will give us our
        %better accuracy metric(s) and all of our evaluation metrics, 
        %3.we will then use these to pick the best model and then 
        %4.we will use that model on the test section. 

        % Note: There are multiple methods to cross-validate, see notes in that
        % section for rational behind my choice


        % holdout M% (to test) using crossvalind - aka, seperate out train and test
        % it's a wee bit confusing wecause we are seperating things out using a
        % function called "corssvalind" and with the "holdout" method, but this is
        % seperate from our crossvalidation and is not a method of crossvalidation
        [train,test] = crossvalind('Holdout',labels_array,.1);

        %train the standard (not corss-validated) SVM Classifier (currently binary)
        standard_mdl = fitcsvm(two_d_data,labels_array); %fitcsvm(two_d_data(train,:),labels_array(train));

        %% Cross-Validation(s)

        % There are a few ways to corss-validate ML Classifiers, you can set it up
        % before building your model, you can specify parameters of
        % cross-validation with name-value pairs in your model function, or you can
        % feed the "standard" model into a cross-validation function. I chose to
        % pass the "standard" model into "crossval" for a few reasons. 
        % A. I wanted to understand all of the steps involved. 
        % B. I think it makes things easier to follow and understand. 
        % C. I can do multiple methods from the same "standard" model to compare 
        % them directly. 
        % But it seems pretty inconsequential

        cross_val_kfold_mdl = crossval((standard_mdl),'KFold',20);

        %lower loss indicates a better predictive model
        kfold_loss_average = kfoldLoss((cross_val_kfold_mdl),'Mode','average');
        
        %% Add Data to Shifting Matrix
        
        growing_matrix{l+1,1} = strcat('Sub_',int2str(l));
        growing_matrix{l+1,1+w} = kfold_loss_average;
    end
end

%% Don't forget to save kids - note, these masters have not deleted exclusions yet

shifting_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','Temporal_Shifting_50ms_Master_All.mat');
save(shifting_save_name,'shifting_matrix'); 

growing_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\','Temporal_Growing_50ms_Master_All.mat');
save(growing_save_name,'growing_matrix');


    
    
    
    
    