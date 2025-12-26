module ActivityPub
  module WellKnown
    class HostMetaController < ApplicationController
      include ApplicationHelper

      def show
        render xml: <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
            <Link rel="lrdd" type="application/xrd+xml" template="#{full_front_url('/.well-known/webfinger?resource={uri}')}"/>
          </XRD>
        XML
      end
    end
  end
end
