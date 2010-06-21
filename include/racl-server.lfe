(eval-when-compile

 ; turn anything reasonable into an atom
 (defun a
   ((c) (when (is_list c)) (list_to_atom c))
   ((c) (when (is_atom c)) c)
   ((c) (when (is_binary c)) (a (binary_to_list c))))

 (defun mk-a (c d)
   (a (: lists flatten (cons (l c) (l d)))))

 ; turn anything reasonable into a list
 (defun l
   ((c) (when (is_list c)) c)
   ((c) (when (is_atom c)) (atom_to_list c))
   ((c) (when (is_binary c)) (binary_to_list c)))

 ; turn anything reasonable into a binary
 (defun b
   ((c) (when (is_list c)) (list_to_binary c))
   ((c) (when (is_atom c)) (b (atom_to_list c)))
   ((c) (when (is_binary c)) c))

  (defun acl-funs (acl-name)
   (let* ((allow-fun-name (mk-a 'allow_ acl-name))
          (deny-fun-name (mk-a 'deny_ acl-name)))
    (list 
     `(defun ,acl-name (key id)
       (,acl-name redis-server key id 'false))
     `(defun ,acl-name (key id default-return)
       (deny? redis-server ',acl-name key id)
       (orelse (allow? redis-server ',acl-name key id) default-return))
     `(defun ,allow-fun-name (key id)
       (allow redis-server ',acl-name key id))
     `(defun ,deny-fun-name (key id)
       (deny redis-server ',acl-name key id)))))

  (defun generate-acl-funs (properties)
   (: lists foldl
    (lambda (property acc)
     (++ (acl-funs property) acc))
    '()
    properties))
)

(defmacro def-acl-server
 ([name properties modifiers custom-funs]
  (let* ((acl-funs (generate-acl-funs properties)))
;   (: io format '"Found acl-funs: ~p~n" (list acl-funs))
   `(progn
     (defmodule ,name ,@modifiers)
      ,@acl-funs
      ,@custom-funs))))

(defmacro redis-cmd-mk (command-name command-args wrapper-fun-name)
    (let* ((cmd (b command-name)))
     `(defun ,command-name (gen-server-name ,@command-args)
        (,wrapper-fun-name
          (: gen_server call gen-server-name
            (tuple 'cmd
              (: erldis multibulk_cmd (list ,cmd ,@command-args))))))))

(defrecord state
  (cxn 'nil)
  (module 'nil))

(defun start_link
  ([gen-server-name ip port]
    (when (is_atom gen-server-name) (is_list ip) (is_integer port))
    (: gen_server start_link
      (tuple 'local gen-server-name) 'er_server (tuple ip port) '())))

(defun start_link
  ([gen-server-name er-server-name]
    (when (is_atom gen-server-name) (is_atom er-server-name))
    (: gen_server start_link
      (tuple 'local gen-server-name) 'er_server (er-server-name) '())))

(defun init
  ([(tuple ip port)]
    (case (: erldis connect ip port)
      ((tuple 'ok connection) (tuple 'ok (make-state cxn connection)))))
  ([(er-server-name)]
    (when (is_atom er-server-name))
      (tuple 'ok (make-state cxn er-server-name))))

(defun handle_call
  ([(cmd key id) from state]
    (let* ((cxn (state-cxn state)))
           (module (state-module state)))
      (spawn (lambda ()
        (: gen_server reply from
          (: module cmd cxn key id))))
    (tuple 'noreply state)))
 
 (defun handle_cast (_request state)
   (tuple 'noreply state))
 
 (defun terminate (_reason _state)
   'ok)
 
 (defun handle_info (_request state)
   (tuple 'noreply state))

 (defun code_change (_old-version state _extra)
   (tuple 'ok state))

