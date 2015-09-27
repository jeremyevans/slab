require 'roda'
require 'tilt/erubis'
require 'tilt/opal'
require 'opal/browser'
require './models'

class Slab < Roda
  use Rack::Session::Cookie, :key => '_slab_session',
    :secret=>(ENV['SLAB_SECRET'] ||= SecureRandom.base64(20))
  plugin :csrf, :skip => ['POST:/slabup/\d+_[^/]+']
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

  plugin :websockets, :ping=>45

  plugin :error_handler do |e|
    puts e
    puts e.backtrace
    "Oops!"
  end

  builder = Opal::Builder.new(:stubs=>['opal'])
  builder.append_paths('assets/js')
  builder.use_gem('opal-browser')
  plugin :assets, :js=>%w'slab.rb', :js_opts=>{:builder=>builder}

  class Listener
    MUTEX = Mutex.new
    LISTENERS = {}

    attr_reader :account_id
    attr_reader :websocket

    def self.sync(&block)
      MUTEX.synchronize(&block)
    end

    def self.notify(account_id, doc_id, path)
      sync do
        if listeners = LISTENERS[account_id.to_i] 
          listeners.each do |listener|
            listener.websocket.send("#{doc_id}-#{path}")
          end
        end
      end
    end

    def initialize(account_id, ws)
      @account_id = account_id
      @websocket = ws
      sync{(LISTENERS[account_id] ||=  []) << self}
    end

    def close
      sync do
        listeners = LISTENERS[@account_id] 
        listeners.delete(self)
        LISTENERS.delete(@account_id) if listeners.empty?
      end
    end

    private

    def sync(&block)
      self.class.sync(&block)
    end
  end

  Thread.new do
    DB.listen('ocr', :loop=>true) do |_, _, data|
      Listener.notify(*data.split('-', 3))
    end
  end

  route do |r|
    r.assets

    r.on 'auth' do
      r.rodauth
    end

    r.post 'slabup/:token' do |token|
      account_id, token = token.split('_', 2)
      unless Account.where(:id=>account_id.to_i, :token=>token).empty?
        handle_upload(account_id.to_i).id.to_s
      end
    end

    r.redirect '/auth/login' unless rodauth.logged_in?
    ds = Document.where(:account_id=>rodauth.session_value)

    r.root  do
      r.redirect '/upload'
    end
    
    r.get "documents" do
      r.websocket do |ws|
        listener = Listener.new(rodauth.session_value, ws)

        ws.on(:close) do |event|
          listener.close
        end
      end

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
        handle_upload(rodauth.session_value)
        r.redirect
      end
    end
  end

  def handle_upload(account_id)
    image = request['image']
    d = Document.create(:account_id=>account_id, :image=>image[:tempfile].read, :path=>image[:filename])
    DB.notify('ocr', :payload=>"#{account_id}-#{d.id}-#{d.path}")
    d
  end
end
