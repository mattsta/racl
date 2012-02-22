-module(racl_tests).
-include_lib("eunit/include/eunit.hrl").

-define(E(A, B), ?assertEqual(A, B)).
-define(_E(A, B), ?_assertEqual(A, B)).

redis_setup_clean() ->
  {ok, Cxn} = er_pool:start_link(redis_racl_content, "127.0.0.1", 9961),
  er:flushall(redis_racl_content),
  Cxn.

racl_basic_commands_test_() ->
  {setup,
    fun redis_setup_clean/0,
    fun(_) -> 
      [
        % Test access with no permission
        ?_E(false, racl_content:read(<<"bob">>, <<"12">>)),
        % Add user
        ?_E(true,  racl_content:add_read(<<"bob">>, <<"12">>)),
        % Test permission
        ?_E(true,  racl_content:read(<<"bob">>, <<"12">>)),
        % Check allowed users
        ?_E([<<"12">>], racl_content:is_read(<<"bob">>)),
        % Check allowed users
        ?_E([<<"12">>], racl_content:allowed_read(<<"bob">>)),
        % Remove user
        ?_E(true,  racl_content:remove_read(<<"bob">>, <<"12">>)),
        % Check denied users
        ?_E([<<"12">>], racl_content:denied_read(<<"bob">>)),
        % Check user was removed from allowed
        ?_E([], racl_content:allowed_read(<<"bob">>)),
        % Test permission again
        ?_E(false, racl_content:read(<<"bob">>, <<"12">>))
      ]
    end
  }.
