(include-file "include/racl.lfe")

(defacl racl_userlevel
 redis_racl_userlevel
 userlevel
 ((superadmin admin moderator important paid registered anonymous))
 ((export all))
 ())
