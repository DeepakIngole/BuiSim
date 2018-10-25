
%% BuiSim 
% Matlab toolbox for fast developlent, simulation and deployment of
% advanced building climate controllers 

% functionality intended for automatic construction of controls and
% estimation for a given linear building model

% Main control strategies
% 1, Model Predictive Control (MPC) 
% 2, deep learning control supervised by MPC


yalmip('clear');
addpath('../Bui_Modeling/')
addpath('../Bui_Disturbances/')
addpath('../Bui_References/')
addpath('../Bui_Estimation/')
addpath('../Bui_Control/')
addpath('../Bui_Simulation/')
addpath('../Bui_Learn/')

%% MODEL   emulator + predictor
% available buildings  'Infrax',  'HollandschHuys', 'Reno', 'Old', 'RenoLight'
buildingType = 'RenoLight';  ModelOrders.range = [4, 7, 10, 15, 20, 30, 40, 100];
% buildingType = 'Infrax'; ModelOrders.range = [100, 200, 600]; 
% buildingType = 'HollandschHuys'; ModelOrders.range = [100, 200, 600]; 
% buildingType = 'Borehole';  ModelOrders.range = [10, 15, 20, 40, 100];  % orderds for borehole
% ModelOrders.choice = 100; 
ModelOrders.choice = 'full';
ModelOrders.off_free = 0;    %  augmented model
reload = 0; 

model = BuiModel(buildingType, ModelOrders, reload);

%% disturbacnes 
dist = BuiDist(buildingType, reload);

%% References 
refs = BuiRefs(model);

%%  estimator 
EstimParam.LOPP.use = 0;      %  Luenberger observer via pole placement - Not implemented
EstimParam.SKF.use = 0;    % stationary KF
EstimParam.TVKF.use = 1;   % time varying KF
EstimParam.MHE.use = 0;   % moving horizon estimation via yalmip
EstimParam.MHE.Condensing = 1;   % state condensing 
EstimParam.use = 1;

estim = BuiEstim(model, EstimParam);

%% controller 
CtrlParam.use = 1;   % 0 for precomputed u,y    1 for closed loop control
CtrlParam.MPC.use = 1;
CtrlParam.MPC.Condensing = 1;
CtrlParam.RBC.use = 0;
CtrlParam.PID.use = 0;

ctrl = BuiCtrl(model, CtrlParam);

%% Simulate - generate learning data
SimParam.run.start = 1;
% SimParam.run.end = 13; 
SimParam.run.end = 30; 
SimParam.verbose = 1;
SimParam.flagSave = 0;
SimParam.comfortTol = 1e-1;
% flag distinguishing emulation and real measurements
%  0 - measurements
%  1 - emulation
SimParam.emulate = 1;
SimParam.profile = 0;  % profiler function for CPU evaluation

PlotParam.flagPlot = 1;     % plot 0 - no 1 - yes
PlotParam.plotStates = 0;        % plot states
PlotParam.plotDist = 0;        % plot disturbances
PlotParam.plotEstim = 1;        % plot estimation
PlotParam.plotCtrl = 1;        % plot control
% PlotParam.Transitions = 1;      % pot dynamic transitions of Ax matrix
% PlotParam.reduced = 0;   %  reduced paper plots formats 0 - no 1 - yes
% PlotParam.zone = 2;     % choose zone if reduced
% PlotParam.only_zone = 0;    %  plot only zone temperatures 0 - no 1 - yes  

% %  simulation file with embedded plotting file
outdata = BuiSim(model, estim, ctrl, dist, refs, SimParam, PlotParam);

% return
%% BuiInitML
% machine learning approximations of MPC

% TODO:
% 1, structure
% 2, training data processing - outdata
% 3, selection of ML model: MLagent = BuiMLAgent(MLParam,outdata)
% 4, automated feature selection for given model via: traindata = BuiFeatures(MLagent,outdata)
% 5, automated training via MLagent = BuiLearn(MLAgent,traindata)
% 6, simulation with MLagent: outdata = BuiSim(model, estim, MLagent, dist, refs, SimParam, PlotParam);


%% ====== Machine Learning Agent ======

% pre-defined ML agent models
AgentParam.RT.use = 0;       % classical regression tree with orthogonal splits
AgentParam.regNN.use = 0;    % classical function fitting regression neural network
AgentParam.TDNN.use = 1;     % time delayed neural network for time series approximation
AgentParam.custom.use = 0;   % custom designed ML model

% initialize MLagent type and structure
MLagent = BuiMLAgent(outdata, AgentParam);



%% ====== Features Selection ======
% automated functionality
% 1, feature selection
% 2, feature transformations

FeaturesParam.time_transform = 0;  % time transformations suitable for R
% RT cross coupling of u dataset?

% parameters for feature refuction function
FeaturesParam.reduce.PCA.use = 1;
FeaturesParam.reduce.PCA.component = 0.999;   % principal component weight threshold
FeaturesParam.reduce.PCA.feature = 0.95;      % PCA features weight threshold
FeaturesParam.reduce.D_model.use = 1;
FeaturesParam.reduce.D_model.feature = 0.99;   % model features weight threshold
FeaturesParam.reduce.lincols.use = 1;
FeaturesParam.reduce.flagPlot = 1;


% TODO: verify features selection with previous implementation

% generate training data for a given agent from simulation data
[traindata, MLagent] = BuiFeatures(outdata, MLagent, FeaturesParam);


%% ====== MLagent training ======
% TrainParam ???

% train ML agent
MLagent = BuiLearn(MLagent,traindata);

% TODO: create new network construction functions based on MLAgent and
% train data params
% similar to NN_TS



%% ====== MLagent Simulation ======

% TODO: adapt BuiSim function to handle multiple controllers
% start with TDNN functions
% standalone evaluation function for each MLagent 
% automatic feature selection from measurements and d predictions 


% integrate MLagent into controller structure
ctrl.use = 1;
ctrl.MLagent = MLagent;
ctrl.MLagent.use = 1;
ctrl.MPC.use = 0;
ctrl.RBC.use = 0;
ctrl.PID.use = 0;

% TODO: nn eval FIX
% results plots
MLoutdata = BuiSim(model, estim, ctrl, dist, refs, SimParam, PlotParam);











 
 
 