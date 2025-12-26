module ActivityPub
  module WellKnown
    class NodeinfoController < ApplicationController
      include ApplicationHelper

      def index
        render json: {
          links: [
            {
              rel: 'http://nodeinfo.diaspora.software/ns/schema/2.1',
              href: full_front_url('/nodeinfo/2.1')
            }
          ]
        }, content_type: 'application/json; charset=utf-8'
      end

      def show
        users_count = Account.is_normal.is_opened.count
        posts_count = Post.from_normal_account.is_normal.is_opened.count

        render json: {
          version: '2.1',
          software: {
            name: 'Amiverse',
            version: '0.0.0',
            repository: 'https://github.com/kisana-me/amiverse',
            homepage: 'https://kisana.me/works/amiverse'
          },
          protocols: [
            'activitypub'
          ],
          services: {
            inbound: [],
            outbound: []
          },
          openRegistrations: true,
          usage: {
            users: {
              total: users_count
            },
            localPosts: posts_count
          },
          metadata: {
            nodeName: 'Amiverse.net',
            nodeDescription: 'Amiverse instance',
            nodeAdmins: [
              {
                name: 'kisana',
                email: 'kisana@kisana.me'
              }
            ],
            maintainer: {
              name: 'kisana',
              email: 'kisana@kisana.me'
            },
            langs: ['ja'],
            tosUrl: full_front_url('/terms-of-service'),
            privacyPolicyUrl: full_front_url('/privacy-policy'),
            inquiryUrl: 'https://anyur.com/inquiries/new',
            impressumUrl: nil,
            repositoryUrl: 'https://github.com/kisana-me/amiverse',
            feedbackUrl: 'https://github.com/kisana-me/amiverse/issues/new',
            disableRegistration: false,
            disableLocalTimeline: false,
            disableGlobalTimeline: false,
            emailRequiredForSignup: false,
            enableHcaptcha: false,
            enableRecaptcha: false,
            enableMcaptcha: false,
            enableTurnstile: true,
            maxNoteTextLength: 500,
            enableEmail: true,
            enableServiceWorker: true,
            proxyAccountName: "proxy",
            themeColor: "#6ef744"
          }
        }, content_type: 'application/json; charset=utf-8'
      end
    end
  end
end
