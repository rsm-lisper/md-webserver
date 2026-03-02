![alt text](resources/md-webserver-logo.png)

# md-webserver
md-webserver is a minimalist [Markdown](https://daringfireball.net/projects/markdown/)/[CommonMark](https://commonmark.org/) web server written in GNU Guile (Scheme).

## Requirements
- [GNU Guile](https://www.gnu.org/software/guile) >= 3.0
- [(guile-commonmark)](https://github.com/OrangeShark/guile-commonmark) - for converting Markdown/CommonMark files to sxml format
- [(htmlprag)](https://www.nongnu.org/guile-lib/doc/ref/htmlprag/) - for converting sxml data to html

## Usage Examples
### Minimal
```shell
guile -c "(use-modules (md-webserver main)) (start-webserver '())"
```

### Typical
(todo)

## License
GPLv3 or later. See LICENSE.
