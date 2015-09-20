require 'roda'
require 'tilt/erubis'

class Slab < Roda
  plugin :render, :escape=>true
  plugin :symbol_views

  route do |r|
    r.root  do
      r.redirect '/upload'
    end
    
    r.is "upload" do
      r.get do
        :upload
      end
    end
  end
end
