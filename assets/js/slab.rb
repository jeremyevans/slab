require 'opal'
require 'browser'
require 'browser/location'
require 'browser/socket'

doc = $document
loc = $window.location
doc.ready do
  case loc.path
  when "/documents"
    Browser::Socket.new("ws://#{loc.host}/documents") do
      on :message do |e|
        id, path = e.data.split("-", 2)
        DOM do
          li do
            a(path, :href=>"/document/#{id}")
          end
        end.append_to(doc['#document-image-list'])
      end
    end
  end
end
