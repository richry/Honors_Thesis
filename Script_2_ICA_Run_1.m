% Made by Ryan R. Rich in Partial Fulfillment of the Requirements for the 
% Degree of Bachelor of Arts with Honors in Psychology from the University of Michigan, 2021

% Mentor: Thad Polk, Graduate Student Mentor: Pia Lalwani, Additional
% thanks: Nathan Brown

% Contact Ryan: ryrich@umich.edu

%% Start er up, pre-load and whatnot

%***Note***
% a line of stars (**********) indicates that the command beneith it will
% need to be updated with the proper information from each new/different
% dataset - does not include names and paths

clear
clc

%we have got to use this way of starting EEGLab (with the GUI) otherwise it
%keeps the history of the last thing that was processed with tht GUI, as in
%it doesn't empty ALLEEG, and if you run eegh, it prints off the last
%history
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

name = '_N170_Prepped_for_ICA';

% start up the big boy loop
%*************************************************************************
for i = 1:40    
    number = int2str(i);
    file_name = strcat('1_',number,name,'.set');
    file_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number);
    EEG = pop_loadset('filename',file_name,'filepath',file_path);
    % I can't put it into words but this index needs to be 1 not 0
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 1 );
    
    load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    load(load_name);
    
    %% Run ICA
    
    %**********************************************************************
    %we skip the last 3 because they will always be the EOG channels -
    %will need to change for each dataset accordingly
    EEG = pop_runica(EEG, 'icatype', 'runica','chanind',[1:EEG.nbchan-3],'extended',1,'interrupt','on');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);   
    EEG = pop_iclabel(EEG, 'default');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    %% Pull out ICA information before it dissapears
    
    %The EEG and ALLEEG structures will only hold the indicies of the
    %components they are about to reject between these two lines of code,
    %so we have to pull them out and save them exactly here, otherwise tehy
    %will dissapear and there is no way to retreive them.
    length = size(EEG.reject.gcompreject);
    index_rejected = find(EEG.reject.gcompreject==1);
    
    %report_card = {};
    report_card{6,1}='ICA Run 1 Total Components';
    report_card{6,2}= length(1,1);

    report_card{7,1}='ICA Run 1 Rejected Components Indicies';
    report_card{7,2}= index_rejected;
    
    %% Save dataset version with ICA computed to save butt in future
    
    %we will save the set here before rejecting the ICA components so we
    %can go back and look (if we don't like it or need to see what
    %happened) and not have to re-run ICA - I saved it here so it will have
    %pre-marked which componets it is about to reject
    save_name = strcat('2_',number,'_N170_ICA_Run_1_Computed');
    save_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\');
    EEG = pop_saveset( EEG, 'filename',save_name,'filepath',save_path);
    
    %% Remove rejected components
    
    %intentionally left empty, that way it automatically removes components marked by icflag
    EEG = pop_subcomp( EEG, [], 0); 
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','ICA_pruned_once','overwrite','on','gui','off'); 
    
    %% Save all the things
    
    %this set will have ICA removed and is ready to continue processing
    save_name = strcat('3_',number,'_N170_ICA_Run_1_Components_Removed');
    save_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\');
    EEG = pop_saveset( EEG, 'filename',save_name,'filepath',save_path);
    report_card_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    save(report_card_save_name,'report_card');
end

eeglab redraw;
erplab redraw;