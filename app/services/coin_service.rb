class CoinService
  LOGIN_BONUS_AMOUNT = 10

  class << self
    def grant(account, amount, kind: :grant, memo: nil)
      raise ArgumentError, "amount must be positive" unless amount.positive?

      apply(account, amount.abs, kind: kind, memo: memo)
    end

    def spend(account, amount, kind: :spend, memo: nil)
      raise ArgumentError, "amount must be positive" unless amount.positive?

      apply(account, -amount.abs, kind: kind, memo: memo, require_balance: true)
    end

    private

    def apply(account, delta, kind:, memo:, require_balance: false)
      account.with_lock do
        return false if require_balance && account.coin_balance + delta < 0

        account.update!(coin_balance: account.coin_balance + delta)
        account.coin_transactions.create!(
          amount: delta,
          balance_after: account.coin_balance,
          kind: kind,
          memo: memo
        )
      end
    end
  end
end
