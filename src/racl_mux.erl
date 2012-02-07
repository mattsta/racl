-module(racl_mux).

-compile(export_all).

access(Namespace, Access, Area, Uid) ->
  case Namespace of
    content -> acl_content:Access(Area, Uid);
       user -> acl_userlevel:Access(Area, Uid)
  end.
