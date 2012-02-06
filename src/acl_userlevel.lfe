(include-file "include/racl.lfe")

(defacl acl_userlevel
 redis_acl_userlevel
 ((superadmin admin moderator important paid registered anonymous))
 ((export all))
 ())
