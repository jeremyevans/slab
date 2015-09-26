require 'roda'
require 'tilt/erubis'
require './models'

class Slab < Roda
  use Rack::Session::Cookie, :key => '_slab_session',
    :secret=>(ENV['SLAB_SECRET'] ||= SecureRandom.base64(20))
  plugin :csrf
  plugin :render, :escape=>true
  plugin :symbol_views
  plugin :symbol_matchers
  plugin :rodauth do
    enable :login, :logout, :create_account
    prefix '/auth'
    account_password_hash_column :password_hash
    title_instance_variable :@title
    skip_status_checks? true
  end

  route do |r|
    r.on 'auth' do
      r.rodauth
    end

    r.redirect '/auth/login' unless rodauth.logged_in?
    ds = Document.where(:account_id=>rodauth.session_value)

    r.root  do
      r.redirect '/upload'
    end
    
    r.get "documents" do
      @docs = ds.select(:id, :path).all
      :documents
    end

    r.get "search" do
      @title = 'Search Results'
      @docs = ds.select(:id, :path).full_text_search(:text, r['q']).all
      :documents
    end

    r.on "document/:d" do |doc_id|
      @doc = ds.with_pk!(doc_id)

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
        d = Document.create(:account_id=>rodauth.session_value, :image=>image[:tempfile].read, :path=>image[:filename])
        DB.notify('ocr', :payload=>d.id)
        r.redirect
      end
    end
  end
end
