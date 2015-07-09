require 'rom'
ROM.setup(:memory)

require 'sinatra'
require 'haml'
require './product'
require './walmart'

rom = ROM.finalize.env

def create_or_update_product(product_id)
  scraper = Walmart::Scraper::Product.new(product_id)
  product = rom.relation(:products).by_id(product_id).as(:entity).one! rescue nil
  if product
    rom.commands.products.update.by_id(product.id).call(data: scraper.append(product.data))
  else
    rom.command(:products).create.call(id: product_id, data: scraper.fetch)
  end
end

get '/' do
  @products = rom.relation(:products).as(:entity).to_a
  haml :index
end

post '/' do
  product_id = Walmart::IDExtractor.new(params[:url]).extract
  create_or_update_product(product_id)
  redirect "/%d" % product_id
end

get '/:id' do |product_id|
  begin
    @product = rom.relation(:products).by_id(product_id.to_i).as(:entity).one!
  rescue
    halt 404
  end
  haml :product
end

__END__


@@ layout
%html
  %body
    = yield

@@ index
%strong
  Products

%form{ action: "/", method: "post" }
  %input{ type: "text", name: "url" }
  %input{ type: "submit", value: "scrap" }

%ul
  - @products.each do |product|
    %li
      %a{ href: "/#{product.id}" }= "Product ##{product.id}"

@@product
%strong
  %a{ href: "/" } Products
  >
  = "Product ##{@product.id}"

%dl
  - @product.data[:reviews].each do |review|
    %dt= "Rated: #{review[:rating]} at #{review[:date]}"
    %dd= review[:comment]
