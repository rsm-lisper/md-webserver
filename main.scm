
(define-module (md-webserver main)
  #:use-module (web uri)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module (web server)
  #:use-module (commonmark sxml)
  #:use-module (htmlprag)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 binary-ports)
  #:use-module (ice-9 format)
  #:use-module (srfi srfi-19)
  #:export (ahref
            start-webserver))


(define (ahref url content)
  `(a (@ (href ,url)) ,content))


(define (templetize title lang charset extra-headers body-template body)
  `(*TOP*
    (*DECL* doctype html)
    (html
     ,(if lang `(@ (lang ,lang)) "")
     (head
      ,(if title `(title ,title) "")
      ,(if charset `(meta (@ (charset ,charset))) "")
      ,@(if extra-headers extra-headers '())
      (meta (@ (name "generator") (content "md-webserver"))))
     (body
      ,@(if body-template (body-template body) body)))))


(define default-conf
  `((#:lang . "en")
    (#:charset . "utf-8")
    (#:content-dir . "./")
    (#:index . "README.md")
    ;; network stuff
    (#:addr ,INADDR_LOOPBACK)
    (#:port 8080)))


(define (path-safe? path)
  (cond ([null? path] #t)
        ([string=? ".." (car path)] #f)
        (else (path-safe? (cdr path)))))


(define (file-ext fname)
  (substring fname (1+ (string-rindex fname #\.))))


(define (send-file fname mime-type)
  (values
   (build-response #:code 200
                   #:headers `((content-type . ,mime-type)))
   (call-with-input-file fname get-bytevector-all #:binary #t)))


(define (curdate-str)
  (date->string (current-date) "~4"))


(define (gen-req-handler site-conf)
  (λ (req req-body)
    (catch #t
      (λ ()
        (let* ([path-oryg (split-and-decode-uri-path (uri-path (request-uri req)))]
               [path-real (if [null? path-oryg]
                              (list (assq-ref site-conf #:index))
                              path-oryg)]
               [full-path (string-append (assq-ref site-conf #:content-dir)
                                         (string-join path-real "/"))])
          (format #t "[~a] Serving file ~s [uri: ~s]~%"
                  (curdate-str) full-path path-real)
          (cond ([and (path-safe? path-real) (file-exists? full-path)]
                 (case [string->symbol (string-downcase (file-ext full-path))]
                   ([md] (values
                          (build-response #:code 200
                                          #:headers '((content-type . (text/html))))
                          (sxml->html
                           (templetize
                            (assq-ref site-conf #:title)
                            (assq-ref site-conf #:lang)
                            (assq-ref site-conf #:charset)
                            (assq-ref site-conf #:extra-headers)
                            (assq-ref site-conf #:body-template)
                            (with-input-from-file full-path commonmark->sxml)))))
                   ([css] (values
                           (build-response #:code 200
                                           #:headers '((content-type . (text/css))))
                           (call-with-input-file full-path get-string-all)))
                   ([jpg jpeg] (send-file full-path '(image/jpeg)))
                   ([png] (send-file full-path '(image/png)))
                   ([ico] (send-file full-path '(image/x-icon)))
                   (else
                    (format (current-error-port)
                            "[~a] Warning! Unsupported Media Type: ~s~%"
                            (curdate-str) path-real)
                    (values
                     (build-response #:code 415
                                     #:headers '((content-type . (text/plain))))
                     (format #f "Unsupported Media Type: ~a"
                             (file-ext (car (last-pair path-real))))))))
                (else
                 (format (current-error-port)
                         "[~a] Warning! File Not Found: ~s~%" (curdate-str) path-real)
                 (values
                  (build-response #:code 404
                                  #:headers '((content-type . (text/plain))))
                  "404 Not Found")))))
      (λ (key . args)
        (let ([err-desc (format #f "Error! ~a: ~a. ~?~%"
                                key (car args) (cadr args) (caddr args))])
          (format (current-error-port) "[~a] ~a" (curdate-str) err-desc)
          (values
           (build-response #:code 500
                           #:headers '((content-type . (text/plain))))
           err-desc))))))


(define (start-webserver site-conf)
  (let* ([conf (append site-conf default-conf)]
         [http-args (append (assq #:addr conf) (assq #:port conf))])
    (format #t "[~a] Starting md-webserver ~s~%" (curdate-str) http-args)
    (run-server (gen-req-handler conf) 'http http-args)
    (format #t "[~a] Stopping md-webserver~%" (curdate-str))))
