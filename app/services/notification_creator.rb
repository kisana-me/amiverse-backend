class NotificationCreator
  def self.call(actor:, recipient:, action:, notifiable: nil, content: nil)
    new(actor, recipient, action, notifiable, content).perform
  end

  def initialize(actor, recipient, action, notifiable, content)
    @actor = actor
    @recipient = recipient
    @action = action
    @notifiable = notifiable
    @content = content
  end

  def perform
    # 1. バリデーション: 自分自身へのアクションなら通知しない
    return if self_action?

    # 1.5. actorが存在し、statusがnormal以外なら通知しない
    return if actor_restricted?

    # 2. 設定チェック: 受信者が通知を拒否していたら作成しない
    return unless notification_allowed?

    # 3. 重複チェック: 「未読」の同じ通知が既にある場合は、新規作成せずに日時だけ更新する（スパム防止）
    # 例: 何度もいいね/解除を繰り返した場合など
    existing_notification = find_duplicate

    if existing_notification
      existing_notification.touch # update_atを更新して一覧の一番上に持ってくる
    else
      create_notification
    end
  end

  private

  attr_reader :actor, :recipient, :action, :notifiable, :content

  def self_action?
    actor.present? && actor.id == recipient.id
  end

  def actor_restricted?
    actor.present? && !actor.normal?
  end

  def notification_allowed?
    # システム通知は設定に関係なく常に許可
    return true if action.to_s == "system"

    # 設定を取得
    setting = recipient.notification_setting

    # action名（例: :reaction）と同じ名前の設定カラム（reaction）をチェック
    # カラムがない場合(signinなど)は通知する前提、または個別にハンドリング
    if setting.respond_to?(action)
      setting.public_send(action)
    else
      true # 設定項目がないアクション種別はデフォルト許可とする
    end
  end

  def webpush_allowed?(notification)
    # システム通知は設定に関係なく常に許可
    return true if notification.action == "system"

    setting = recipient.notification_setting
    column_name = "wp_#{notification.action}"

    if setting.respond_to?(column_name)
      setting.public_send(column_name)
    else
      true # 設定項目がないアクション種別はデフォルト許可とする
    end
  end

  def find_duplicate
    # 同一Actor、同一Notifiable、同一Action、かつ「未読」のものが既にあるか？
    Notification.unread.find_by(
      account: recipient,
      actor: actor,
      action: action,
      notifiable: notifiable
    )
  end

  def create_notification
    notification = Notification.create!(
      account: recipient,
      actor: actor,
      action: action,
      notifiable: notifiable,
      content: content
    )
    send_webpush(notification)
    notification
  end

  def send_webpush(notification)
    # WebPush設定をチェック
    return unless webpush_allowed?(notification)

    message = build_webpush_message(notification)
    return unless message

    recipient.webpush_subscriptions.find_each do |subscription|
      begin
        WebPush.payload_send(
          message: JSON.generate(message),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh,
          auth: subscription.auth_key,
          vapid: {
            subject: "mailto:kisana@amiverse.net",
            public_key: Rails.configuration.x.vapid_public_key,
            private_key: Rails.configuration.x.vapid_private_key
          }
        )
      rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription
        subscription.destroy
      rescue => e
        Rails.logger.error("WebPush Error: #{e.message}")
      end
    end
  end

  def build_webpush_message(notification)
    title = "Amiverse "
    body = "新しい通知があります"
    icon = "/static-assets/images/amiverse-logo-400.webp"
    image = nil# '/static-assets/images/amiverse-1.webp'
    tag = "new-notification"
    timestamp = notification.created_at.to_i * 1000
    url = "/notifications"
    actions = []
    action_urls = {}

    case notification.action
    when "reaction"
      title += "❤️"
      body = "#{notification.actor.name}さんがあなたの投稿にリアクションしました"
      icon = notification.actor.icon_url
      set_post_actions(notification, tag, actions, action_urls)
    when "diffuse"
      title += "🔁"
      body = "#{notification.actor.name}さんがあなたの投稿を拡散しました"
      icon = notification.actor.icon_url
      set_post_actions(notification, tag, actions, action_urls)
    when "reply"
      title += "💬"
      body = "#{notification.actor.name}さんがあなたの投稿に返信しました"
      icon = notification.actor.icon_url
      set_post_actions(notification, tag, actions, action_urls)
    when "quote"
      title += "✒️"
      body = "#{notification.actor.name}さんがあなたの投稿を引用しました"
      icon = notification.actor.icon_url
      set_post_actions(notification, tag, actions, action_urls)
    when "follow"
      title += "👤"
      body = "#{notification.actor.name}さんがあなたをフォローしました"
      icon = notification.actor.icon_url
      tag.replace("follow")
      actions.push({ action: "view_account", title: "アカウントを見る", icon: notification.actor.icon_url })
      action_urls["view_account"] = "/@#{notification.actor.name_id}"
    when "mention"
      title += "📢"
      body = "#{notification.actor.name}さんがあなたをメンションしました"
      icon = notification.actor.icon_url
      tag.replace("mention")
      set_post_actions(notification, tag, actions, action_urls)
    when "signin"
      title += "🔑"
      body = "新しい端末からサインインがありました"
      tag.replace("signin")
      actions.push({ action: "open_settings", title: "設定を開く" })
      action_urls["open_settings"] = "/settings"
    when "system"
      title += "🔔"
      body = notification.content
      tag.replace("system")
    else
      title += "❔"
    end

    {
      title: title,
      options: {
        body: body,
        icon: icon,
        image: image,
        tag: tag,
        timestamp: timestamp,
        data: {
          url: url,
          action_urls: action_urls
        },
        actions: actions
      }
    }
  end

  def set_post_actions(notification, tag, actions, action_urls)
    return unless notification.notifiable&.is_a?(Post)

    tag.replace("post-#{notification.notifiable.aid}")
    actions.push(
      { action: "view_account", title: "アカウントを見る", icon: notification.actor.icon_url },
      { action: "view_post", title: "投稿を見る", icon: notification.account.icon_url }
    )
    action_urls["view_account"] = "/@#{notification.actor.name_id}"
    action_urls["view_post"] = "/posts/#{notification.notifiable.aid}"
  end
end
