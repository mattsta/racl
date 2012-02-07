racl: Redis Access Control Lists

How to use
==========
  1. Determine the types of properties you want to control
     e.g. user can be granted read, write, send, flag, moderate permissions
  2. Add those permissions to a module.  See src/acl_content.lfe for an example.
     - Basically, you use a macro that defines a module for you.
       (defacl my_acl_module_name (property1 property2 property3)
        ((export all))
        ((defun extra_functions () 'hi) (defun more_functions () 'there)))
  3. Compile. (rebar compile)
  4. Your new module has five functions defined per property.
     For example, if your module is named "acl_forum" with a property named
     "flag", your functions are:
     - acl_forum:flag(ErServerName, RedisKey, IdOfUserForRequestedAccess)
       - Verifies the IdOfUserForRequestedAccess is authorized for the
         'flag' property of RedisKey
     - acl_forum:allowed_flag(ErServerName, RedisKey)
       - Returns a list of user ids granted 'flag' access
     - acl_forum:denied_flag(ErServerName, RedisKey)
       - Returns a list of user ids denied 'flag' access
     - acl_forum:add_flag(ErServerName, RedisKey, UserIdToAllow)
       - Enable UserIdToAllow 'flag' access on RedisKey
     - acl_forum:remove_flag(ErServerName, RedisKey, UserIdToDeny)
       - Deny UserIdToDeny 'flag' access on RedisKey

Testing
=======

    rebar eunit skip_deps=true
