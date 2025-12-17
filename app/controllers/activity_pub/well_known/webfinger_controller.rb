module ActivityPub
  module WellKnown
    class WebfingerController < ApplicationController
      def show
        resource = params[:resource]

        if resource.blank?
          render json: { error: 'Bad Request' }, status: :bad_request
          return
        end

        acct = resource.gsub(/^acct:/, '')
        acct = acct.gsub(/^@/, '')

        parts = acct.split('@')
        username = parts[0]
        domain = parts[1]

        front_uri = URI.parse(ENV.fetch('FRONT_URL'))
        if domain.present?
          if domain != front_uri.host
            render json: { error: 'Not Found' }, status: :not_found
            return
          end
        end

        account = Account
          .is_normal
          .is_opened
          .find_by(name_id: username)

        if account.nil? || account.remote? || account.activity_pub_profile.nil?
          render json: { error: 'Not Found' }, status: :not_found
          return
        end

        render json: {
          subject: resource,
          links: [
            {
              rel: 'self',
              type: 'application/activity+json',
              href: account.activity_pub_profile.uri
            },
            {
              rel: 'http://webfinger.net/rel/profile-page',
              type: 'text/html',
              href: "https://#{front_uri.host}/@#{account.name_id}"
            }
          ]
        }, content_type: 'application/jrd+json'
      end
    end
  end
end
