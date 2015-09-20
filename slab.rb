require 'roda'
require 'tilt/erubis'
require './models'

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

      r.post do
        image = r['image']
        Document.create(:image=>image[:tempfile].read, :path=>image[:filename])
        r.redirect
      end
    end
  end
end
