# Introducing the qnd_html2page gem


## Usage

    require 'qnd_html2page'

    h2p = QndHtml2Page.new '/tmp/index.html', debug: true
    pages = h2p.to_pages
    #=> [<div> ... </>, <div> ... </>] 

Note: The default page height is 676 and can be changed from *initialize* using the named keyword *pg_height*.


## Resources

* qnd_html2page https://rubygems.org/gems/qnd_html2page

page pages html qndhtml2page gem

