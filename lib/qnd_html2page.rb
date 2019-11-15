#!/usr/bin/env ruby

# file: qnd_html2page.rb

require 'rexle'
require 'ferrum'
require 'tempfile'
require 'rxfhelper'



class QndHtml2Page

  attr_reader :to_pages

  def initialize(html, debug: false, pg_height: 676)

    @html, @height, @debug = html, pg_height, debug
    @to_pages = scan(RXFHelper.read(@html).first)

  end

  private

  def scan(html)

    # add the span tag after every element in the body

    doc = Rexle.new(html)
    body = doc.root.element('body')
  
    count = 0
    body.each_recursive do |e|

      puts 'e: ' + e.name if @debug
      ignore_list = %w(span b li tr td dt dd em strong i a)
      next if ignore_list.include? e.name
      span = Rexle::Element.new('span').add_text(count.to_s)
      span.attributes[:class] = 'qndhtml2pg'
      e.insert_after span
      count += 1

    end

    # Fetch the y coordinate of every span tag to determine the 
    # elements that can fit into each page.

    tmpfile = Tempfile.new('browser')
    File.write tmpfile.path + '.html', doc.root.xml

    browser = Ferrum::Browser.new
    browser.goto('file://' + tmpfile.path + '.html')
    span_list = browser.xpath('//span')
    a = span_list.map {|x| [x.text, x.find_position.last] }

    offset = 0

    a2 = a.inject([[]]) do |r,x|

      puts 'r: ' + x.inspect if @debug
      puts 'x: ' + x.inspect if @debug
      x.last < offset + @height ? (r.last << x) : (offset = x.last; r << [x])
      r

    end


    elements = doc.root.element('body').elements.to_a
    puts 'elements.length: ' + elements.length.inspect if @debug
    offset = 0

    puts 'a2: ' + a2.inspect if @debug

    pages = a2.map do |x|

      id = x.last.first

      puts 'id: ' + id.inspect if @debug
      puts 'offset: ' + offset.inspect if @debug

      a3 = elements[offset..-1].take_while do |e| 
        puts 'e.text: ' + e.text.inspect
        e.text != id
      end

      offset = a3.length 
      div = Rexle::Element.new 'div'
      a3.reject! {|e| e.name == 'span' and e.attributes[:class] == 'qndhtml2pg' }
      a3.each {|e| div.add e}
      div
    end

    @to_pages = pages

  end

end
