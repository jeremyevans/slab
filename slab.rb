require 'roda'

class Slab < Roda
  route do |r|
    r.root  do
      'Hello World'
    end
  end
end
