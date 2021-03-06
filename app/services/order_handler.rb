class OrderHandler

  attr_reader :pay_with_bonuses, :order, :current_user

  BONUS_PERCENT_INC = 0.04
  BONUS_PERCENT_USES_IN_PAYMENT = 0.2

  def initialize params={}
    params = params.symbolize_keys

    @pay_with_bonuses   = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(params[:pay_with_bonuses])
    @order              = Order.find_by!(id: params[:id], status: "Pending")
    @current_user       = params[:current_user]
    @certificate_tokens = params[:certificate_tokens]
  end

  def build
    bonuses_payment_amount        = 0
    amount_left_to_pay            = order.amount
    certificates_are_valid        = (@certtificate_tokens - GiftCertificate.unordered.map(&:token)).empty?

    if !certificates_are_valid
      render :exception
    end

    used_certificates = GiftCertificate.unordered.where(token: @certtificates_tokens)
    certificates_payment_amount = used_certificates.sum(:amount)

    amount_left_to_pay -= [certificates_payment_amount, amount_left_to_pay].min

    if pay_with_bonuses
      bonuses_payment_amount = [current_user.bonus_points, amount_left_to_pay * BONUS_PERCENT_USES_IN_PAYMENT].min.round
      amount_left_to_pay -= bonuses_payment_amount
    end

    if amount_left_to_pay <= current_user.balance

      current_user.decrement(:balance, amount_left_to_pay)
      current_user.bonus_points = current_user.bonus_points - bonuses_payment_amount + amount_left_to_pay * BONUS_PERCENT_INC

      order.status = Order.statuses["Accepted"]

      current_user.gift_certificates << used_certificates
      current_user.save

      order.gift_certificates = used_certificates
      order.save!
    else
      render :exception
    end
  end
end
