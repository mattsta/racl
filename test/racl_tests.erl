-module(racl_tests).
-include_lib("eunit/include/eunit.hrl").

-define(E(A, B), ?assertEqual(A, B)).
-define(_E(A, B), ?_assertEqual(A, B)).

redis_setup_clean() ->
  {ok, Cxn} = er_pool:start_link(redis_acl_content, "127.0.0.1", 9961),
  er:flushall(redis_acl_content),
  Cxn.

racl_basic_commands_test_() ->
  {setup,
    fun redis_setup_clean/0,
    fun(C) -> 
      [
        % Test access with no permission
        ?_E(false, acl_content:read(<<"bob">>, <<"12">>)),
        % Add user
        ?_E(true,  acl_content:allow_read(<<"bob">>, <<"12">>)),
        % Test permission
        ?_E(true,  acl_content:read(<<"bob">>, <<"12">>)),
        % Check allowed users
        ?_E([<<"12">>], acl_content:allowed_read(<<"bob">>)),
        % Remove user
        ?_E(true,  acl_content:deny_read(<<"bob">>, <<"12">>)),
        % Check denied users
        ?_E([<<"12">>], acl_content:denied_read(<<"bob">>)),
        % Check user was removed from allowed
        ?_E([], acl_content:allowed_read(<<"bob">>)),
        % Test permission again
        ?_E(false, acl_content:read(<<"bob">>, <<"12">>))
      ]
    end
  }.
