class Product
  attr_reader :id
  attr_accessor :data

  def initialize(attrs)
    @id, @data = attrs.values_at(:id, :data)
  end
end

class Products < ROM::Relation[:memory]
  def by_id(id)
    restrict(id: id)
  end
end

class ProductMapper < ROM::Mapper
  relation :products
  register_as :entity

  model Product

  attribute :id
  attribute :data
end

class CreateProduct < ROM::Commands::Create[:memory]
  register_as :create
  relation :products
  result :one
end

class UpdateProduct < ROM::Commands::Update[:memory]
  register_as :update
  relation :products
  result :one
end
