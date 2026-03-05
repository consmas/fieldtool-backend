module Fuel
  class OmcWalletService
    class InsufficientBalanceError < StandardError; end

    class << self
      def credit_from_deposit!(deposit:, actor: nil)
        raise ArgumentError, "deposit must be confirmed" unless deposit.status == "confirmed"

        with_locked_balance(deposit.omc_name) do |balance|
          before = balance.balance.to_d
          amount = deposit.amount.to_d
          after = before + amount

          balance.update!(balance: after)
          FuelOmcLedgerEntry.create!(
            fuel_omc_balance: balance,
            entry_type: "credit",
            amount: amount,
            balance_before: before,
            balance_after: after,
            reference: deposit,
            actor: actor,
            note: "Fuel deposit credited",
            metadata: {
              deposit_id: deposit.id,
              reference_no: deposit.reference_no,
              payment_method: deposit.payment_method
            }
          )
        end
      end

      def debit_for_fuel_log!(fuel_log:, actor: nil)
        return unless fuel_log.funding_source == "omc_deposit"

        with_locked_balance(fuel_log.omc_name) do |balance|
          before = balance.balance.to_d
          amount = fuel_log.total_cost.to_d
          raise InsufficientBalanceError, "Insufficient OMC balance for #{fuel_log.omc_name}" if before < amount

          after = before - amount
          balance.update!(balance: after)
          FuelOmcLedgerEntry.create!(
            fuel_omc_balance: balance,
            entry_type: "debit",
            amount: amount,
            balance_before: before,
            balance_after: after,
            reference: fuel_log,
            actor: actor,
            note: "Fuel purchase deducted",
            metadata: {
              fuel_log_id: fuel_log.id,
              vehicle_id: fuel_log.vehicle_id,
              trip_id: fuel_log.trip_id
            }
          )
          fuel_log.update_column(:deducted_from_omc, true)
        end
      end

      private

      def with_locked_balance(omc_name)
        raise ArgumentError, "omc_name is required" if omc_name.blank?

        balance = FuelOmcBalance.lock.where(omc_name: omc_name).first_or_create!(currency: "GHS", balance: 0)
        yield(balance)
      end
    end
  end
end
