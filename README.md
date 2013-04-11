racl: redis-backed access control lists
=======================================

Status
------
`racl` stores explicit access permissions in
redis.  You can query who has which access levels
as well as do blind checks for allowed/deny on
specific features you specify.

Usage
-----
  1. Determine the types of properties you want to control
     e.g. user can be granted read, write, send, flag, moderate permissions
  2. Add those permissions to a module.  See src/racl_content.lfe for an example.
     - Basically, you use a macro that defines a module for you.
       (defacl my_racl_module_name (property1 property2 property3)
        ((export all))
        ((defun extra_functions () 'hi) (defun more_functions () 'there)))
  3. Compile. (rebar compile)
  4. Your new module has five functions defined per property.
     For example, if your module is named "racl_forum" with a property named
     "flag", your functions are:
     - racl_forum:flag(ErServerName, RedisKey, IdOfUserForRequestedAccess)
       - Verifies the IdOfUserForRequestedAccess is authorized for the
         'flag' property of RedisKey
     - racl_forum:is_flag(ErServerName, RedisKey)
       - Returns a list of user ids granted 'flag' access
     - racl_forum:allowed_flag(ErServerName, RedisKey)
       - Returns a list of user ids granted 'flag' access
     - racl_forum:denied_flag(ErServerName, RedisKey)
       - Returns a list of user ids denied 'flag' access
     - racl_forum:add_flag(ErServerName, RedisKey, UserIdToAllow)
       - Enable UserIdToAllow 'flag' access on RedisKey
     - racl_forum:remove_flag(ErServerName, RedisKey, UserIdToDeny)
       - Deny UserIdToDeny 'flag' access on RedisKey

Building
--------
        rebar get-deps
        rebar compile

Testing
-------
The tests here are mostly symbolic and kinda useless.

        rebar eunit skip_deps=true suite=racl

Next Steps
----------
Create better examples of usage.
