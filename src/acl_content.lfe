(include-file "include/racl.lfe")

; properties are from largest to smallest
; properties inherit to the left
; owner -> delete -> write/edit/save -> flag/vote -> read
; each element includes all elements to its right
; think of "owner can (delete can (merge can (write can 
;           (copy can (append can (read))))))"

(defacl acl_content  ; module name
 redis_acl_content   ; registered name of an er_pool to talk to redis
 content             ; name used in redis keys to allow multiple racl namespaces
                     ; to exist on one redis server/cluster/global namespace
 ((owner delete merge write copy append downvote upvote flag read)) ; levels
 ((export all)) ; module stuff
 ()) ; additional functions you may want to bundle with your module
