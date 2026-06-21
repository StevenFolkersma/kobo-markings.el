;;; kobo-markings.el --- Export Kobo highlights to Org mode  -*- lexical-binding: t -*-

;; Requires Emacs 29+ for built-in sqlite support.

(require 'cl-lib)

(defgroup kobo nil
  "Import Kobo e-reader highlights into Org mode."
  :group 'org)

(defcustom kobo-db-path
  (expand-file-name "~/Documents/Projects/kobo-notes/KoboReader.sqlite")
  "Path to the KoboReader.sqlite database file."
  :type 'file
  :group 'kobo)

(defcustom kobo-export-dir
  (expand-file-name "~/Documents/Projects/kobo-notes/")
  "Directory where timestamped export files are written."
  :type 'directory
  :group 'kobo)

(defconst kobo--sql
  "SELECT
     c_book.Attribution  AS author,
     c_book.Title        AS book_title,
     b.Text              AS highlight,
     b.Annotation        AS note
   FROM Bookmark b
   JOIN content c_chap ON b.ContentID = c_chap.ContentID
   JOIN content c_book ON b.VolumeID  = c_book.ContentID
   WHERE b.Type IN ('highlight', 'note')
   ORDER BY c_book.Title, c_chap.VolumeIndex, b.ChapterProgress"
  "SQL query fetching all highlights ordered by book and position.")

(defun kobo--primary-author (attribution)
  "Return the first author from a comma/slash-separated ATTRIBUTION string."
  (if (and attribution (not (string-empty-p (string-trim attribution))))
      (string-trim (car (split-string attribution "[,/]")))
    "Unknown"))

(defun kobo--format-entry (author book highlight note)
  "Return an Org entry string for one marking."
  (let* ((heading  (format "* %s\n" (or book "Unknown")))
         (byline   (format "%s - %s\n\n" author (or book "Unknown")))
         (body     (format "#+begin_quote\n%s\n#+end_quote\n"
                           (string-trim (or highlight ""))))
         (note-str (let ((n (string-trim (or note ""))))
                     (if (string-empty-p n) "" (format "\n%s\n" n)))))
    (concat heading byline body note-str)))

(defun kobo--run-query (db-path)
  "Open DB-PATH and return rows for `kobo--sql'."
  (unless (fboundp 'sqlite-open)
    (user-error "kobo-markings.el requires Emacs 29+ with built-in sqlite support"))
  (let* ((db   (sqlite-open db-path))
         (rows (sqlite-select db kobo--sql)))
    (sqlite-close db)
    rows))

;;;###autoload
(defun kobo-export ()
  "Export all Kobo highlights to a timestamped file in `kobo-export-dir'."
  (interactive)
  (let* ((db-path  (expand-file-name kobo-db-path))
         (filename (format-time-string "kobo-marking-export-%d-%m-%y.org"))
         (out-path (expand-file-name filename kobo-export-dir)))
    (unless (file-exists-p db-path)
      (user-error "Kobo database not found: %s" db-path))
    (let* ((rows  (kobo--run-query db-path))
           (count 0))
      (with-temp-buffer
        (insert "#+TITLE: Kobo Highlights\n")
        (insert (format "#+DATE: %s\n\n" (format-time-string "%Y-%m-%d")))
        (dolist (row rows)
          (cl-destructuring-bind (attribution book highlight note) row
            (insert (kobo--format-entry
                     (kobo--primary-author attribution)
                     book highlight note))
            (insert "\n")
            (cl-incf count)))
        (write-region (point-min) (point-max) out-path))
      (message "Exported %d markings → %s" count out-path)
      (find-file out-path))))

(provide 'kobo-markings)
;;; kobo-markings.el ends here
