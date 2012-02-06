(include-file "include/racl.lfe")

; properties are from largest to smallest
; properties inherit to the left
; owner -> delete -> write/edit/save -> flag/vote -> read
; each element includes all elements to its right
; think of "owner can (delete can (merge can (write can 
;           (copy can (append can (read))))))"

(defacl acl_content
 redis_acl_content
 ((owner delete merge write copy append downvote upvote flag read))
 ((export all))
 ())
