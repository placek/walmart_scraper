require "sinatra"
require "rom"
require "haml"
ROM.setup(:memory)
require './app/product'
require './app/walmart'

rom = ROM.finalize.env

get '/' do
  @products = rom.relation(:products).as(:entity).to_a
  puts @products
  haml :index
end

post '/' do
  product_id = Walmart::IDExtractor.new(params[:url]).extract
  begin
    rom.relation(:products).by_id(product_id.to_i).as(:entity).one!

  rescue
    rom.command(:products).create.call(id: product_id, data: [])
  end
  redirect "/#{product_id}"
end

get '/:id' do |product_id|
  begin
    @product = rom.relation(:products).by_id(product_id.to_i).as(:entity).one!
  rescue
    return "404"
  end
  haml :product
end

__END__


@@ layout
%html
  %body
    = yield

@@ index
%h3 Products

%form{ action: "/", method: "post" }
  %input{ type: "text", name: "url" }
  %input{ type: "submit", value: "scrap" }

%ul
  - @products.each do |product|
    %li
      %a{ href: "/#{product.id}" }= "Product ##{product.id}"

@@product
%h3= "Product#{@product.id}"

%dl
  - @product.data.each do |rating|
    %dt= "Rated: #{rating[1]} at #{rating[0]}"
    %dd= rating[2]
