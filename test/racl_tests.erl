-module(racl_tests).
-include_lib("eunit/include/eunit.hrl").

-define(E(A, B), ?assertEqual(A, B)).
-define(_E(A, B), ?_assertEqual(A, B)).

redis_setup_clean() ->
  Cxn = 
  case whereis(racl) of
    undefined -> {ok, C} = er_pool:start_link(racl, "127.0.0.1", 9961),
                 C;
        Found -> Found
  end,
  ok = er:flushall(Cxn),
  Cxn.

racl_basic_commands_test_() ->
  {setup,
    fun redis_setup_clean/0,
    fun(C) -> 
      [
        % Test access with no permission and default throw behavior
        ?_assertThrow({acl_deny,read,<<"bob">>,<<"12">>},
          acl_content:read(C, <<"bob">>, <<"12">>)),
        % Add user
        ?_E(true,  acl_content:allow_read(C, <<"bob">>, <<"12">>)),
        % Test permission
        ?_E(true,  acl_content:read(C, <<"bob">>, <<"12">>)),
        % Check allowed users
        ?_E([<<"12">>], acl_content:allowed_read(C, <<"bob">>)),
        % Remove user
        ?_E(true,  acl_content:deny_read(C, <<"bob">>, <<"12">>)),
        % Check denied users
        ?_E([<<"12">>], acl_content:denied_read(C, <<"bob">>)),
        % Check user was removed from allowed
        ?_E([], acl_content:allowed_read(C, <<"bob">>)),
        % Test permission again
        ?_assertThrow({acl_deny,read,<<"bob">>,<<"12">>},
          acl_content:read(C, <<"bob">>, <<"12">>))
      ]
    end
  }.
