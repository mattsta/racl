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

 (defun sub-acls-to-allows (redis-server full-name acls)
  (lc ((<- acl acls)) `(allow? ',redis-server ',acl ',full-name key id)))

 (defun acl-funs
  ([redis-server full-name (acl-name . sub-acls)]
   (let* ((allow-fun-name (mk-a 'add_ acl-name))
          (deny-fun-name (mk-a 'remove_ acl-name))
          (sub-acls (sub-acls-to-allows redis-server full-name
                     (cons acl-name sub-acls)))
          (get-allowed-fun-name (mk-a 'allowed_ acl-name))
          (get-is-fun-name (mk-a 'is_ acl-name))
          (get-denied-fun-name (mk-a 'denied_ acl-name)))
    (list
     `(defun ,acl-name (key id)
       (case (deny? ',redis-server ',acl-name ',full-name key id)
        ('ok (orelse
              ,@sub-acls
              (read-denied-error ',acl-name ',full-name key id)))
        ('false 'false)))
     `(defun ,get-is-fun-name (key id) ; an explicit naming of (acl-name key id)
       (,acl-name key id))
     `(defun ,get-allowed-fun-name (key)
       (allowed ',redis-server ',acl-name ',full-name key))
     `(defun ,get-denied-fun-name (key)
       (denied ',redis-server ',acl-name ',full-name key))
     `(defun ,allow-fun-name (key id)
       (allow ',redis-server ',acl-name ',full-name key id))
     `(defun ,deny-fun-name (key id)
       (deny ',redis-server ',acl-name ',full-name key id))))))

 (defun generate-sub-acl-funs
  ([redis full-name () acc] acc)
  ([redis full-name (prop . props) acc]
   (generate-sub-acl-funs redis full-name props
    (++ (acl-funs redis full-name (cons prop props)) acc)))
  ([redis full-name single-prop acc] (when (is_atom single-prop))
   (++ (acl-funs redis full-name (cons single-prop ())) acc)))


 (defun generate-acl-funs (redis full-name properties)
  (: lists foldl
   (match-lambda
    ([property-group acc] (when (is_list property-group))
     (++ (generate-sub-acl-funs redis full-name
      (: lists reverse property-group) ()) acc))
    ([property-group acc] (when (is_atom property-group))
     (++ (generate-sub-acl-funs redis full-name property-group ()) acc)))
   '()
   properties))
)

(defsyntax mk-key
 ([full-name base allow-deny permission-type]
  (: eru er_key 'racl full-name permission-type base allow-deny)))

(defsyntax mk-allow-key
 ([full-name base type]
  (mk-key full-name base 'allow type)))

(defsyntax mk-deny-key
 ([full-name base type]
  (mk-key full-name base 'deny type)))

(defsyntax allowed
 ([redis-server permission-name full-name key]
  (: er smembers redis-server (mk-allow-key full-name key permission-name))))

(defsyntax denied
 ([redis-server permission-name full-name key]
  (: er smembers redis-server (mk-deny-key full-name key permission-name))))

(defsyntax check-permission
 ([redis-server permission-name full-name allow-deny key requestor-id]
  (: er sismember redis-server
   (mk-key full-name key allow-deny permission-name) requestor-id)))

(defsyntax allow?
 ([redis-server permission-name full-name key id]
  (check-permission redis-server permission-name full-name 'allow key id)))

(defsyntax read-denied-error
 ([permission full-name key id] 'false))

(defsyntax deny?
 ([redis-server permission-name full-name key id]
  (let* ((denied (check-permission redis-server
                  permission-name full-name 'deny key id)))
   (case denied
    ('true (read-denied-error permission-name full-name key id))
    ('false 'ok)))))

(defsyntax allow
 ([redis-server permission-name full-name key id]
  (progn
   (: er srem redis-server (mk-deny-key full-name key permission-name) id)
   (: er sadd redis-server (mk-allow-key full-name key permission-name) id))))

(defsyntax deny
 ([redis-server permission-name full-name key id]
  (progn
   (: er srem redis-server (mk-allow-key full-name key permission-name) id)
   (: er sadd redis-server (mk-deny-key full-name key permission-name) id))))

(defmacro defacl
 ([name redis-server-name full-name properties modifiers custom-funs]
  (let* ((acl-funs (generate-acl-funs redis-server-name full-name properties)))
;   (: io format '"Found acl-funs: ~p~n~n" (list acl-funs))
   `(progn
     (defmodule ,name ,@modifiers)
      ,@acl-funs
      ,@custom-funs))))
