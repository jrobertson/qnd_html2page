#!/usr/bin/env ruby

# file: qnd_html2page.rb

require 'rexle'
require 'ferrum'
require 'tempfile'
require 'rxfhelper'


module ArraySlices

  refine Array do

      def slice_at(*indices)

        a = indices
        a << -1 if a[-1] != self[-1]
        a.unshift -1
        a.each_cons(2).map {|x1, x2| self.slice(x1+1..x2) }

      end
    
  end
end

class QndHtml2Page
  using ArraySlices
  using ColouredText

  attr_reader :to_pages

  def initialize(html, debug: false, pg_height: 770, width: '700px')

    @html, @height, @width, @debug = html, pg_height, width, debug
    @to_pages = scan(RXFHelper.read(@html).first)

  end

  private

  def scan(obj)
    
    raw_html = obj.is_a?(Rexle) ? obj.xml : obj
      
    # <br/> acts as a hard page break
    html = raw_html.gsub(/<br\s*\/>/) do |x|
      '<span class="qndhtml2pg">pagebreak' + x.object_id.to_s + '</span>'
    end
    
    # add the span tag after almost every element in the body    

    doc = Rexle.new(html)
    body = doc.root.element('body')
    body.attributes[:style] = 'width: ' + @width
  
    count = 0
    body.each_recursive do |e|

      puts ('e: ' + e.xml).debug if @debug
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
    span_list = browser.xpath('//span[@class="qndhtml2pg"]')
    
    maxheight = span_list.last.find_position.last

    a = span_list.map do |x| 
      ypos = x.text[/^pagebreak/] ? maxheight : x.find_position.last        
      [x.text, ypos] 
    end
    
    heights = ((maxheight) / @height).round.to_i.times\
        .inject([@height]) {|r, x| r << (r.last + @height)  } 
    
    puts ('heights: ' + heights.inspect).debug if @debug
    height = heights.shift

    a2 = a.inject([[]]) do |r,x|

      puts ('r: ' + x.inspect).debug if @debug
      puts ('x: ' + x.inspect).debug if @debug
      puts ('height: ' + height.inspect).debug if @debug
      
      if x.first[/^pagebreak/] then
        r << [x]
      else
        x.last < height ? (r.last << x) : (height = heights.shift; r << [x])
      end
      
      r

    end


    elements = doc.root.element('body').elements.to_a
    puts ('elements.length: ' + elements.length.inspect).debug if @debug
    offset2 = 0

    puts ('a2: ' + a2.inspect).debug if @debug
    
    # find each last record span stop using the given id
    stops = a2.map do |x|
      elements.index(elements.find {|e| e.text == x.last.first })
    end
    
    puts ('stops: ' + stops.inspect).debug if @debug
    
    pages = elements.slice_at(*stops).map do |e_list|

      div = Rexle::Element.new 'div'
      puts 'e_list: ' + e_list.inspect if @debug
      
      e_list.reject! do |e|
        r = e.name == 'span' and e.attributes[:class] == 'qndhtml2pg'
        puts 'r: ' + r.inspect
        r
      end
      
      next if e_list.empty?

      e_list.each {|e| div.add e}
      
      puts 'div: ' + div.xml.inspect if @debug
      div.xpath('//span[@class="qndhtml2pg"]').each(&:delete)
      puts 'after div: ' + div.xml.inspect if @debug      
      div
    end.compact

  end

end
