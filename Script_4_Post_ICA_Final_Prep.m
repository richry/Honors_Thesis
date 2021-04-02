% Made by Ryan R. Rich in Partial Fulfillment of the Requirements for the 
% Degree of Bachelor of Arts with Honors in Psychology from the University of Michigan, 2021

% Mentor: Thad Polk, Graduate Student Mentor: Pia Lalwani, Additional
% thanks: Nathan Brown

% Contact Ryan: ryrich@umich.edu

%% Pre-Load and notes such

% if you load the channel locations for the file
%that you will interpolate from, it keeps them after interpolation

% here are all of the possible places to find the marked epochs: a field
% within EEG.EVENTLIST.eventinfo - but it's irritating to work with: if you
% "export marks to ICA Reject" they will show up in EEG.reject.rejglobal:
% and the easiest one that I went with: after syncronizing ERPlab and
% EEGlab they will be in EEG.reject.rejmanual


%***Note***
% a line of stars (**********) indicates that the command beneith it will
% need to be updated with the proper information from each new/different
% dataset - does not include names and paths

clear
clc

%okay, so this is going to be like the "master set" with all of the
%channels, it doesn't matter which subject it is within your dataset, just
%make sure it's the origional file wiht all the channels - it will be "set
%1" and it will stay open the whole time - no point in closing and
%re-opening it x times
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Channel_Master.set');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 5 );
EEG=pop_chanedit(EEG, 'lookup','C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\standard-10-5-cap385.elp');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


name = '_N170_ICA_Run_2_Components_Removed_If_Any';

% start the big boy loop
%*************************************************************************
for i = 1:40
    number = int2str(i);
    file_name = strcat('5_',number,name,'.set');
    file_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number);
    EEG = pop_loadset('filename',file_name,'filepath',file_path);
    % I can't put it into words but this index needs to be 1 not 0
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 1 );
    
    load_name =strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    load(load_name);
    
    %% Late Stage Pre-Processing
    %**********************************************************************
    %the baseline and number of channels will need to be updated
    EEG = pop_rmbase( EEG, [-699 0] ,[],[1:EEG.nbchan-3] );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off'); 
    EEG = eeg_checkset( EEG );

    % "artmwppth" is artifact detection moving window peak to peak threshold
    %**********************************************************************
    %The number of channels, threshold, and twindow will need to be updated
    EEG  = pop_artmwppth( EEG , 'Channel',  1:EEG.nbchan-3, 'Flag',  1, 'Threshold',  200, 'Twindow', [ -699.2 697.3], 'Windowsize',  200, 'Windowstep',  100 ); 
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off'); 
    %we used an ERPlab artifact detection command, so they are in the
    %EVENTLIST, but we need to send them back to EEGlab for this script to work
    EEG = pop_syncroartifacts(EEG,'Direction', 'erplab2eeglab'); 
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off'); 
    EEG = eeg_checkset( EEG );
    %This line just combines all rejections from all methods
    EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);

    %% Report Card Things for rejection criteria later
    
    % will almost always be slightly less than the official number of
    % trials because early stage cleaning will have probably removed at
    % least a few
    report_card{12,1} = 'Total Epochs Before Rejection';
    size_epochs = size(EEG.reject.rejmanual);
    report_card{12,2} = size_epochs(2);
    report_card{13,1} = 'Total Epochs After Rejection';
    rej_epochs = find(EEG.reject.rejmanual);
    size_rej_epochs = size(rej_epochs);
    report_card{13,2} = size_epochs(2) - size_rej_epochs(2);
    report_card{14,1} = 'Percent Total Epochs Rejected';
    report_card{14,2} = size_rej_epochs(2) / size_epochs(2);
    report_card{15,1} = 'Subject Reject?';
    if report_card{14,2} >= .30
        report_card{15,2} = 'YES';
    else
        report_card{15,2} = 'no';
    end
    
    %% Late Stage Pre-Processing Continued
    
    % okay, so the GUI produced command didn't match the documentation, so I
    % played around and created this, which matches the documentation and will
    % reject the correct channels for each iteration
    EEG = pop_rejepoch( EEG, EEG.reject.rejmanual,0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off'); 


    % so I would have done interpolation after removing the baseline, but,
    % EEGlab sticks the interpolated channels at the end of the list after the
    % EOG channels, and that would have been irritating to work around, so I
    % just threw it on last to avoid the problem
    %**********************************************************************
    % the 33 will need to be updated
    if EEG.nbchan ~= 33
        EEG = pop_interp(EEG, ALLEEG(5).chanlocs, 'spherical');
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off'); 
        EEG = eeg_checkset( EEG );

        %I'm not so sure about this reref - it only serves to include the
        %interpolated channel(s) if there are any and if there are and we include
        %them, we loose ICA weights - also, remember that the interpolated channel
        %gets tacked on at the end, so the indicies are wrong
        %*********************************************************************
        % the range of channels will need to be updated
        EEG = pop_reref( EEG, [],'exclude',[EEG.nbchan-2:EEG.nbchan] );
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off'); 
        EEG = eeg_checkset( EEG );
    end
    
    %% Save all the things
    
    save_name = strcat('6_',number,'_N170_Post_ICA_Final_Prep');
    save_path = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\');
    EEG = pop_saveset( EEG, 'filename',save_name,'filepath',save_path);
    report_card_save_name = strcat('C:\Users\ryrich\Documents\Honors Thesis\Practice_Dataset\Subject_',number,'\Subject_',number,'_Report_card.mat');
    save(report_card_save_name,'report_card');
end

eeglab redraw;
erplab redraw;

