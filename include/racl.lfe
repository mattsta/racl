(eval-when-compile
 ; turn anything reasonable into an atom
 (defun a
  ((c) (when (is_list c)) (list_to_atom c))
  ((c) (when (is_atom c)) c)
  ((c) (when (is_binary c)) (a (binary_to_list c))))

 ; turn anything reasonable into a list
 (defun l
  ((c) (when (is_list c)) c)
  ((c) (when (is_atom c)) (atom_to_list c))
  ((c) (when (is_binary c)) (binary_to_list c)))

 (defun mk-a (c d)
  (a (: lists flatten (cons (l c) (l d)))))

 (defun sub-acls-to-allows (redis-server acls)
  (lc ((<- acl acls)) `(allow? ',redis-server ',acl key id)))

 (defun acl-funs
  ([redis-server (acl-name . sub-acls)]
   (let* ((allow-fun-name (mk-a 'allow_ acl-name))
          (deny-fun-name (mk-a 'deny_ acl-name))
          (sub-acls (sub-acls-to-allows redis-server (cons acl-name sub-acls)))
          (get-allowed-fun-name (mk-a 'allowed_ acl-name))
          (get-denied-fun-name (mk-a 'denied_ acl-name)))
    (list
     `(defun ,acl-name (key id)
       (deny? ',redis-server ',acl-name key id)
       (orelse ,@sub-acls (read-denied-error ',acl-name key id)))
     `(defun ,get-allowed-fun-name (key)
       (allowed ',redis-server ',acl-name key))
     `(defun ,get-denied-fun-name (key)
       (denied ',redis-server ',acl-name key))
     `(defun ,allow-fun-name (key id)
       (allow ',redis-server ',acl-name key id))
     `(defun ,deny-fun-name (key id)
       (deny ',redis-server ',acl-name key id))))))

 (defun generate-sub-acl-funs
  ([redis () acc] acc)
  ([redis (prop . props) acc]
   (generate-sub-acl-funs redis props
    (++ (acl-funs redis (cons prop props)) acc)))
  ([redis single-prop acc] (when (is_atom single-prop))
   (++ (acl-funs redis (cons single-prop ())) acc)))


 (defun generate-acl-funs (redis properties)
  (: lists foldl
   (match-lambda
    ([property-group acc] (when (is_list property-group))
     (++ (generate-sub-acl-funs redis (: lists reverse property-group) ()) acc))
    ([property-group acc] (when (is_atom property-group))
     (++ (generate-sub-acl-funs redis property-group ()) acc)))
   '()
   properties))
)

(defsyntax mk-key
 ([base allow-deny permission-type]
  (: eru er_key 'permission permission-type base allow-deny)))

(defsyntax mk-allow-key
 ([base type]
  (mk-key base 'allow type)))

(defsyntax mk-deny-key
 ([base type]
  (mk-key base 'deny type)))

(defsyntax allowed
 ([redis-server permission-name key]
  (: er smembers redis-server (mk-allow-key key permission-name))))

(defsyntax denied
 ([redis-server permission-name key]
  (: er smembers redis-server (mk-deny-key key permission-name))))

(defsyntax check-permission
 ([redis-server permission-name allow-deny key requestor-id]
  (: er sismember redis-server (mk-key key allow-deny permission-name) requestor-id)))

(defsyntax allow?
 ([redis-server permission-name key id]
  (check-permission redis-server permission-name 'allow key id)))

(defsyntax read-denied-error
 ([permission key id] 'false))

(defsyntax deny?
 ([redis-server permission-name key id]
  (let* ((denied (check-permission redis-server permission-name 'deny key id)))
   (case denied
    ('true (read-denied-error permission-name key id))
    ('false 'ok)))))

(defsyntax allow
 ([redis-server permission-name key id]
  (progn
   (: er srem redis-server (mk-deny-key key permission-name) id)
   (: er sadd redis-server (mk-allow-key key permission-name) id))))

(defsyntax deny
 ([redis-server permission-name key id]
  (progn
   (: er srem redis-server (mk-allow-key key permission-name) id)
   (: er sadd redis-server (mk-deny-key key permission-name) id))))

(defmacro defacl
 ([name redis-server-name properties modifiers custom-funs]
  (let* ((acl-funs (generate-acl-funs redis-server-name properties)))
;   (: io format '"Found acl-funs: ~p~n~n" (list acl-funs))
   `(progn
     (defmodule ,name ,@modifiers)
      ,@acl-funs
      ,@custom-funs))))
