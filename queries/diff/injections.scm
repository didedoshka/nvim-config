; extends

; the code in a diff, in the language of the file it belongs to (#diff-code!, plugin/diff_code.lua):
; the new sides (context and added lines) of all the files in one language are parsed as one text,
; their old sides (context and deleted lines) as another
([(context) (addition)] @injection.content
  (#diff-code! @injection.content)
  (#set! injection.combined))

([(context) (deletion)] @injection.content
  (#diff-code! @injection.content)
  (#set! injection.combined))
