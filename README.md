# kobo-markings.el

Exports highlights and notes from a Kobo e-reader into an Org mode file. It reads directly from the `KoboReader.sqlite` database that Kobo maintains on the device, so no third-party export step is needed. Each marking becomes an Org heading of the form `Author - Book Title`, with the highlighted passage in a `#+begin_quote` block and any written annotation below it in italics.

Requires Emacs 29 or later (built-in `sqlite` support).

---

## Installation

### Clone the repository

```sh
git clone https://github.com/yourname/kobo-notes.git
```

Then load the file in your init:

```elisp
(load "/path/to/kobo-notes/kobo-markings.el")
```

### use-package with `:vc`

Available in Emacs 30+:

```elisp
(use-package kobo-read
  :vc (:url "https://github.com/yourname/kobo-notes"
       :rev :newest))
```

---

## Configuration

Two variables control where the database is read from and where the output goes:

| Variable | Default |
|---|---|
| `kobo-db-path` | `~/path/to/kobo-database/KoboReader.sqlite` |
| `kobo-output-file` | `~/path/to/output-file/kobo-highlights.org` |

Set them before loading or via `M-x customize-group RET kobo`:

```elisp
(setq kobo-db-path    "~/mnt/kobo/KoboReader.sqlite"
      kobo-output-file "~/org/kobo.org")
```

---

## Usage

Copy `KoboReader.sqlite` from the Kobo device (it is in the root of the device when mounted over USB) to the path in `kobo-db-path`. Then run:

```
M-x kobo-export
```

This writes the Org file to `kobo-output-file` and opens it. Running it again overwrites the file, so it is safe to re-run after syncing a newer database from the device.

### Output format

```org
#+TITLE: Kobo Highlights
#+DATE: 2026-06-21

* Author - Book Title
#+begin_quote
Contents of marked text
#+end_quote
```

Highlights are ordered by book title, then by position within the book. If a book has multiple authors listed in the database, only the first is used in the heading.

### Notes on .kepub files

Kobo's own store sells books in `.kepub` format. These are stored in the database with a UUID as the content ID rather than a file path, and the `BookTitle` field is left empty. `kobo-read.el` reads the title from the correct column regardless of format, so `.kepub` and standard `.epub` files are handled the same way.

Page numbers are not available for either format — Kobo does not record them because the text reflows based on font size and screen orientation.
