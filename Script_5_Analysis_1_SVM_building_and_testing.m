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
    
    model_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_SVM_Model.mat');
    save(model_save_name,'standard_mdl');

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
    %individual is not used in final evaluations - only for exploration
    kfold_loss_individual = kfoldLoss((cross_val_kfold_mdl),'Mode','individual');

    %higher edge indicates a better predictive model
    %edge is the weighted mean of the classification margins
    kfold_edge_average = kfoldEdge((cross_val_kfold_mdl),'Mode','average');
    %individual is not used in final evaluations - only for exploration
    kfold_edge_individual = kfoldEdge((cross_val_kfold_mdl),'Mode','individual');

    %higher margins indicates a better predictive model
    %margin is not used in final evaluatios - only for exploration
    kfold_margin = kfoldMargin(cross_val_kfold_mdl);

    %% Model Choice 

    [Max_edge_value,Max_edge_Index] = max(kfold_edge_individual);
    [Min_loss_value,Min_loss_Index] = min(kfold_edge_individual);

    if Max_edge_Index == Min_loss_Index
        Final_Model_index = Max_edge_Index;
    else
        Final_Model_index = Min_loss_Index;
        Note = 'Inconsistant Model Choice Metrics'
       % ********************************************************************************************attentiongrabber
    end


    %% Testing - Testing if only for exploring, adjusting parameters, modifying, and amputing
    % cross-val metrics will be used as final metrics of accuracy

    testing_labels = labels_array(test);

    Champion_Mdl = cross_val_kfold_mdl.Trained{Final_Model_index};
    Predictions = predict(Champion_Mdl,two_d_data(test,:));

    for i = 1:length(Predictions)
        if Predictions(i) == testing_labels(i)
            Predictions(i) = 1;
        else
            Predictions(i) = 0;
        end
    end

    correct = sum(Predictions(:) == 1);
    Accuracy_cross_val = correct/length(Predictions);


    Predictions_standard = predict(standard_mdl,two_d_data(test,:));

    for i = 1:length(Predictions_standard)
        if Predictions_standard(i) == testing_labels(i)
            Predictions_standard(i) = 1;
        else
            Predictions_standard(i) = 0;
        end
    end

    correct = sum(Predictions_standard(:) == 1);
    Accuracy_standard = correct/length(Predictions_standard);

    %% Report Card Things

    report_card{19,1} = 'Intended Car Events';
    report_card{19,2} = 80;
    report_card{20,1} = 'Percent Kept Car Events';
    report_card{20,2} = (sum(labels_array(:)== 2)) / (report_card{19,2});
    report_card{21,1} = 'Subject Reject?';
    if report_card{20,2} <= .70
        report_card{21,2} = 'YES';
    else
        report_card{21,2} = 'no';
    end


    report_card{23,1} = 'Intended Face Events';
    report_card{23,2} = 80;
    report_card{24,1} = 'Percent Kept Face Events';
    report_card{24,2} = (sum(labels_array(:)== 1)) /(report_card{23,2});
    report_card{25,1} = 'Subject Reject?';
    if report_card{24,2} <= .70
        report_card{25,2} = 'YES';
    else
        report_card{25,2} = 'no';
    end

    report_card{27,1} = 'Average 20fold loss';
    report_card{27,2} = kfold_loss_average;
    
    chance = .50;
    report_card{28,1} = 'Above Chance';
    if report_card{27,2} <.5
        report_card{28,2} = 'Yes';
    else
        report_card{28,2} = 'No';
    end
    
    report_card{30,1} = 'Average 20fold Edge';
    report_card{30,2} = kfold_edge_average;
    
    report_card{32,1} = 'Novel Data Accuracy';
    report_card{32,2} = Accuracy_standard;
    
    chance = .50;
    report_card{33,1} = 'Above Chance';
    if report_card{32,2} >.5
        report_card{33,2} = 'Yes';
    else
        report_card{33,2} = 'No';
    end

    report_card_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    save(report_card_save_name,'report_card');
       
end



%% Notes and helpful hints

% These are examples of cross-validating while building your origional
% classifier
% test_mdl = fitcsvm(two_d_data(:,:),labels_array(:), 'CrossVal','on','Holdout',.15)
% test_mdl2 = fitcsvm(two_d_data(:,:),labels_array(:), 'CrossVal','on','KFold',5)


% the default kfold loss metric for fitcsvm is 'classiferror' which is the
% misclassified rate in decimal, - I noticed it doesn't add to 100 when
% added to the accuracy rate of the same function, but then I realized they
% are based on testing on diff data, so they should be close, but not perf

%I think I can plot kfoldloss to find out the optimal number of folds! -
%nope, actually I think that's for a diff type of ML classifier


% not undedrstanding kfoldPredict tbh, does it use an averaged model or
% just one of the models? - ope, it might just do it for each fold you 
% specify, so I could do this once and specify all folds - okay, update
% two, I think it is only a thing for binary, linear, classification models
% - okay wait, update three, this is binary and linear (but the next
% dataset won't be - update, I tried some stuff and got confused and
% frustrated and threw this function away (for now)


% - don't really understand kfoldfun either, I'm
% wondering if it's useing a previously crossvalidated model to
% crossvalidate a new one -- I think it might just be another function used
% to cross-validate "standard" models! hazah


















