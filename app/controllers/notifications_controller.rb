class NotificationsController < ApplicationController
  before_action :require_signin
  before_action :require_admin

  def new
  end

  def create
    content = params[:content].to_s.strip
    target_type = params[:target_type].to_s
    aids_text = params[:account_aids].to_s

    if content.blank?
      flash[:alert] = "通知内容を入力してください。"
      return redirect_to new_notification_path
    end

    recipients, error_message = target_accounts(target_type, aids_text)
    if error_message.present?
      flash[:alert] = error_message
      return redirect_to new_notification_path
    end

    delivered_count = 0

    begin
      each_target_account(recipients) do |account|
        NotificationCreator.call(
          actor: nil,
          recipient: account,
          action: :system,
          content: content
        )
        delivered_count += 1
      end

      flash[:notice] = "#{delivered_count}件のシステム通知配信を完了しました。"
    rescue ActiveRecord::RecordInvalid => e
      flash[:alert] = "通知作成中にエラーが発生しました: #{e.record.errors.full_messages.to_sentence}"
    end

    redirect_to new_notification_path
  end

  private

  def target_accounts(target_type, aids_text)
    case target_type.presence || "all"
    when "all"
      [ Account.is_normal, nil ]
    when "specific"
      aids = parse_aids(aids_text)

      if aids.empty?
        return [ nil, "個別配信を選択した場合は account aid を入力してください。" ]
      end

      accounts_by_aid = Account.is_normal.where(aid: aids).index_by { |account| account.aid.to_s }
      missing_aids = aids - accounts_by_aid.keys

      if missing_aids.any?
        return [ nil, "存在しない account aid があります: #{missing_aids.join(', ')}" ]
      end

      [ aids.map { |aid| accounts_by_aid[aid] }, nil ]
    else
      [ nil, "配信対象の指定が不正です。" ]
    end
  end

  def parse_aids(aids_text)
    aids_text
      .tr("、", ",")
      .split(",")
      .map(&:strip)
      .reject(&:blank?)
      .uniq
  end

  def each_target_account(recipients, &block)
    if recipients.is_a?(ActiveRecord::Relation)
      recipients.find_each(&block)
    else
      recipients.each(&block)
    end
  end
end
