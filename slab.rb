require 'roda'
require 'tilt/erubis'
require './models'

class Slab < Roda
  plugin :render, :escape=>true
  plugin :symbol_views
  plugin :symbol_matchers

  route do |r|
    r.root  do
      r.redirect '/upload'
    end
    
    r.get "documents" do
      @docs = Document.select(:id, :path).all
      :documents
    end

    r.get "search" do
      @title = 'Search Results'
      @docs = Document.select(:id, :path).full_text_search(:text, r['q']).all
      :documents
    end

    r.on "document/:d" do |doc_id|
      @doc = Document.with_pk!(doc_id)

      r.get true do
        :document
      end

      r.get 'image' do
        response['Content-Type'] = @doc.content_type
        unless @doc.viewable?
          response['Content-Disposition'] = "attachment; filename=#{@doc.path.inspect}"
        end
        @doc.image
      end
    end

    r.is "upload" do
      r.get do
        :upload
      end

      r.post do
        image = r['image']
        d = Document.create(:image=>image[:tempfile].read, :path=>image[:filename])
        DB.notify('ocr', :payload=>d.id)
        r.redirect
      end
    end
  end
end
