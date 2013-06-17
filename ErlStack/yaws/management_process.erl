-module(management_process).
-compile(export_all).
-include("records.hrl").
-description("This module is used to implement main manager for Erlang Stack (ErlStack). "
	     "All base agent hosts on start-up register with this manager.  The yaws web interface "
	     "sends requests to this manager for managing the cloud.").


%%% This function should be called to start the manager.  In
%%% current version only one manager can be run at a time as
%%% the manager registers itself with name cloud_manager.
%%%
%%% @spec () -> Pid
%%%
start() ->
	Manager1=#manager{host_agent_info=[]},	
	P=spawn(fun() -> cloud_manager(Manager1) end),
	global:register_name(cloud_manager,P),
	P.


%%% This is the main loop for cloud manager process
cloud_manager(Manager1) ->
    receive
	{stop_manager} ->
	    log(warn, "Stopping manager process"),
	    cloud_manager(Manager1);


	{register_base_agent,Hostname, Pid} ->
	    %% Get current host_agent_info
	    Host_list1=Manager1#manager.host_agent_info,

	    %% Check if another agent is already registered for same hostname,
	    %% If another agent is registered remove its registration to get
	    %% Host_list2 without any information for given Hostname
	    case lists:keyfind(Hostname, 2, Host_list1) of
		false ->
		    Host_list2=Host_list1;
		Tuple1 ->
		    Host_list2=Host_list1 -- [Tuple1]
	    end,

	    %% Add received Pid, Hostname to Host_list2
	    Host_list3=Host_list2 ++ [{Pid, Hostname}],

	    %% Create a new manager record with updated host_list
	    Manager2=Manager1#manager{host_agent_info=Host_list3},
	    Message1=lists:flatten(io_lib:format("~p registered with Pid: ~p.",[Hostname,Pid])),
	    log(info,Message1),
	    cloud_manager(Manager2);


	%% To retrieve the container list from the base agent whose pid is = Pid and Pid1 is the pid of the web server .
	{get_container_list, Sender, Base_host_pid, Request_id1} ->
	    Base_host_pid !  {get_container_list, self(), Request_id1},
	    receive 
		{Request_id1, Container_list} ->  
		    Sender ! {Request_id1, Container_list}
	    after 2000 ->
		    Sender ! {Request_id1, {error, "No reply received from corresponding base machine,"}}
	    end,
	    cloud_manager(Manager1);

	%% To retrieve full information about the conatiners whether the containers are stopped or running .
	{get_number_containers,Sender,Base_host_pid,Request_id1} ->
	    io:format("In get_number_container, args are ~p ~p ~p~n",[Sender,Base_host_pid,Request_id1]),
	    Base_host_pid !  {get_num_containers, self(), Request_id1},
	    receive
	    	{Request_id1,Message}->
		    io:format("error reported is ~p~n",[Message]),
		    Sender ! {Request_id1,{error,Message}};
		{Request_id1,Total_number_of_containers,Running_containers,Stopped_containers}->
		    Sender !{ Request_id1,Total_number_of_containers,Running_containers,Stopped_containers}
	    after 2000 ->
		    Sender ! {Request_id1, {error, "No reply received from corresponding base machine,"}}
	    end,
	    cloud_manager(Manager1);

	%% To retrieve the container list from the base agent whose Pid is =Base_pid .
	{get_vm_list,Base_pid,Sender} ->
	    Base_pid !  {get_vm_list, self(),101},
	    receive 
		{Request_id,Vm_list} ->  
		    Sender ! {vm_list,Vm_list}
	    after 2000 ->
		    Sender ! error
	    end,		
	    cloud_manager(Manager1);
	
	%Gets the pid when given a Hostname. Returns the pid if successful, and false if failure.
	{get_pid_of_host,Sender,Hostname,Request_id}->
	    io:format("Cloudman: Hostname received as ~p~n",[Hostname]),
	    HostList=Manager1#manager.host_agent_info,
	    Tuple=lists:keyfind(Hostname,2,HostList),
	    io:format("Tuple generated is ~p~n",[Tuple]),
	    case erlang:is_tuple(Tuple) of
		true->
		    Sender!{Request_id,Tuple};
		false ->
		    Sender!{Request_id,{error,error}}
	    end,
	    cloud_manager(Manager1);


	{get_host_list,Sender} ->	
	    Sender ! {Manager1#manager.host_agent_info} ,
	    io:format("Received at the cloud manager ~p~n",[Sender]),
	    io:format("Received at the cloud manager ~p~n",[Manager1#manager.host_agent_info]),
						%		Pid ! ok ,
	    cloud_manager(Manager1);

	Any1 ->  
	    Message1=lists:flatten(io_lib:format("Unknown message ~p received at manager.", [Any1])),
	    log(info, Message1),
	    cloud_manager(Manager1)

    end.

log(Type,Message) ->
    io:format("~p ~p~n",[Type,Message]).
