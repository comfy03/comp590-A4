-module(chain_servers).
-export([start/0, serv1/1, serv2/1, serv3/1]).

%% Start the chain by spawning the servers and initiating the message loop.
start() ->
    Serv3Pid = spawn(?MODULE, serv3, [0]),  % Start serv3 with accumulator 0
    Serv2Pid = spawn(?MODULE, serv2, [Serv3Pid]),  % Start serv2 and pass serv3 PID
    Serv1Pid = spawn(?MODULE, serv1, [Serv2Pid]),  % Start serv1 and pass serv2 PID
    message_loop(Serv1Pid).

%% Loop that gets user input and sends it to serv1
message_loop(Serv1Pid) ->
    io:format("Enter a message (or 'all_done' to quit): "),
    io:format("", []),  %% Ensure the prompt is displayed immediately
    Input = io:get_line(""),
    case string:trim(Input) of
        "all_done" -> 
            io:format("Stopping...~n"), 
            io:format("", []),  %% Flush the output to make sure the message is printed
            ok;
        Message ->
            case catch erl_scan:string(Message) of
                {ok, Tokens, _} ->
                    case catch erl_parse:parse_term(Tokens) of
                        {ok, Term} ->
                            Serv1Pid ! Term,  % Send the parsed Erlang term directly
                            io:format("", []),  %% Flush output after sending the message
                            message_loop(Serv1Pid);
                        _Error ->
                            io:format("Invalid Erlang term, try again.~n"),
                            io:format("", []),  %% Flush output after error
                            message_loop(Serv1Pid)
                    end;
                _Error ->
                    io:format("Invalid input format, try again.~n"),
                    io:format("", []),  %% Flush output after error
                    message_loop(Serv1Pid)
            end
    end.

%% serv1: handles arithmetic operations and passes unhandled messages to serv2
serv1(Serv2Pid) ->
    receive
        {add, X, Y} ->
            Result = X + Y,
            io:format("(serv1) Add ~p + ~p = ~p~n", [X, Y, Result]),
            serv1(Serv2Pid);  % Do not forward after handling
        {sub, X, Y} ->
            Result = X - Y,
            io:format("(serv1) Subtract ~p - ~p = ~p~n", [X, Y, Result]),
            serv1(Serv2Pid);  % Do not forward after handling
        {mult, X, Y} ->
            Result = X * Y,
            io:format("(serv1) Multiply ~p * ~p = ~p~n", [X, Y, Result]),
            serv1(Serv2Pid);  % Do not forward after handling
        {'div', X, Y} when Y =/= 0 ->
            Result = X / Y,
            io:format("(serv1) Divide ~p / ~p = ~p~n", [X, Y, Result]),
            serv1(Serv2Pid);  % Do not forward after handling
        {neg, X} ->
            Result = -X,
            io:format("(serv1) Negate ~p = ~p~n", [X, Result]),
            serv1(Serv2Pid);  % Do not forward after handling
        {sqrt, X} when X >= 0 ->
            Result = math:sqrt(X),
            io:format("(serv1) Square root of ~p = ~p~n", [X, Result]),
            serv1(Serv2Pid);  % Do not forward after handling
        halt ->
            Serv2Pid ! halt,
            io:format("(serv1) Halting...~n");
        Other ->
            %% Add debug message to show that serv1 is forwarding the message
            io:format("(serv1) Forwarding unhandled message to serv2: ~p~n", [Other]),
            Serv2Pid ! Other,
            serv1(Serv2Pid)
    end.


%% serv2: handles lists of numbers and passes unhandled messages to serv3
serv2(Serv3Pid) ->
    receive
        [H | T] when is_integer(H) ->
            Sum = lists:sum([X || X <- [H | T], is_number(X)]),
            io:format("(serv2) Sum of list: ~p~n", [Sum]),
            serv2(Serv3Pid);
        [H | T] when is_float(H) ->
            Product = lists:foldl(fun(X, Acc) -> X * Acc end, 1, [X || X <- [H | T], is_number(X)]),
            io:format("(serv2) Product of list: ~p~n", [Product]),
            serv2(Serv3Pid);
        halt ->
            Serv3Pid ! halt,
            io:format("(serv2) Halting...~n");
        Other ->
            Serv3Pid ! Other,
            serv2(Serv3Pid)
    end.

%% serv3: handles errors and keeps track of unhandled messages
serv3(UnhandledCount) ->
    receive
        {error, Reason} ->
            io:format("(serv3) Error: ~p~n", [Reason]),
            serv3(UnhandledCount);
        halt ->
            io:format("(serv3) Halting... Total unhandled messages: ~p~n", [UnhandledCount]);
        Other ->
            io:format("(serv3) Not handled: ~p~n", [Other]),
            serv3(UnhandledCount + 1)
    end.
