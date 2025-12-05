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

  def notification_allowed?
    # システム通知は設定に関係なく常に許可
    return true if action.to_s == 'system'

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
    send_web_push(notification)
    notification
  end

  def send_web_push(notification)
    message = build_push_message(notification)
    return unless message

    recipient.push_subscriptions.find_each do |subscription|
      begin
        WebPush.payload_send(
          message: JSON.generate(message),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh,
          auth: subscription.auth_key,
          vapid: {
            subject: 'mailto:admin@amiverse.net',
            public_key: Rails.configuration.x.vapid_public_key,
            private_key: Rails.configuration.x.vapid_private_key
          }
        )
      rescue WebPush::InvalidSubscription
        subscription.destroy
      rescue => e
        Rails.logger.error("WebPush Error: #{e.message}")
      end
    end
  end

  def build_push_message(notification)
    title = "Amiverse"
    body = ""
    url = "/notifications"

    case notification.action
    when 'reaction'
      body = "#{notification.actor.name}さんがあなたの投稿にリアクションしました"
      url = "/posts/#{notification.notifiable.aid}" if notification.notifiable
    when 'diffuse'
      body = "#{notification.actor.name}さんがあなたの投稿を拡散しました"
      url = "/posts/#{notification.notifiable.aid}" if notification.notifiable
    when 'reply'
      body = "#{notification.actor.name}さんが返信しました"
      url = "/posts/#{notification.notifiable.aid}" if notification.notifiable
    when 'follow'
      body = "#{notification.actor.name}さんにフォローされました"
      url = "/accounts/#{notification.actor.aid}"
    when 'mention'
      body = "#{notification.actor.name}さんがあなたについて言及しました"
      url = "/posts/#{notification.notifiable.aid}" if notification.notifiable
    when 'system'
      body = notification.content
    else
      return nil
    end

    {
      title: title,
      body: body,
      url: url
    }
  end
end
